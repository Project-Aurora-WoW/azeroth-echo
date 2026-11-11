import struct, zlib, os, sys

# ---------- MPQ primitives ----------
def build_table(n=0x500):
    t=[0]*n; seed=0x00100001
    for i in range(0x100):
        idx=i
        for _ in range(5):
            seed=(seed*125+3)%0x2AAAAB
            t1=(seed&0xFFFF)<<0x10
            seed=(seed*125+3)%0x2AAAAB
            t2=seed&0xFFFF
            t[idx]=(t1|t2)&0xFFFFFFFF
            idx+=0x100
    return t
T=build_table()

def hstr(name, kind):
    if kind==2: s=name.upper().replace("/","\\")
    elif kind==3: s=name.lower().replace("/","\\")
    else: s=name.replace("/","\\")
    s1,s2=0x7FED7FED,0xEEEEEEEE
    for ch in s.encode("ascii"):
        s1=(T[0x100+ch] ^ ((s1+s2)&0xFFFFFFFF))&0xFFFFFFFF
        s2=(ch+s1+s2+((s2<<5)&0xFFFFFFFF)+3)&0xFFFFFFFF
    return s1 if kind in (0,1) else s2

def enc(data,key):
    key&=0xFFFFFFFF; seed=0xEEEEEEEE; out=bytearray()
    for i in range(0,len(data),4):
        seed=(seed+T[0x400+(key&0xFF)])&0xFFFFFFFF
        ch=struct.unpack_from("<I",data,i)[0]; plain=ch
        ch=(ch+(key+seed))&0xFFFFFFFF
        sh=seed&0x1F
        if sh: ch=((ch<<sh)|(ch>>(32-sh)))&0xFFFFFFFF
        key=((((~key)&0xFFFFFFFF)<<0x15)+0x11111111 | (key>>0x0B))&0xFFFFFFFF
        seed=(plain+seed+((seed<<5)&0xFFFFFFFF)+3)&0xFFFFFFFF
        out.extend(struct.pack("<I",ch))
    return bytes(out)

def dec(data,key):
    key&=0xFFFFFFFF; seed=0xEEEEEEEE; out=bytearray()
    for i in range(0,len(data),4):
        seed=(seed+T[0x400+(key&0xFF)])&0xFFFFFFFF
        ch=struct.unpack_from("<I",data,i)[0]
        sh=seed&0x1F
        if sh: ch=((ch>>sh)|(ch<<(32-sh)))&0xFFFFFFFF
        ch=(ch-(key+seed))&0xFFFFFFFF
        key=((((~key)&0xFFFFFFFF)<<0x15)+0x11111111 | (key>>0x0B))&0xFFFFFFFF
        seed=(ch+seed+((seed<<5)&0xFFFFFFFF)+3)&0xFFFFFFFF
        out.extend(struct.pack("<I",ch))
    return bytes(out)

MPQ_COMPRESSION_ZLIB = 0x02
MPQ_FILE_IMPLODE     = 0x00000100
MPQ_FILE_COMPRESS    = 0x00000200
MPQ_FILE_ENCRYPTED   = 0x00010000
MPQ_FILE_EXISTS      = 0x80000000
HASH_ENTRY_DELETED   = 0xFFFFFFFE
HASH_ENTRY_EMPTY     = 0xFFFFFFFF

HASH_TABLE_SIZE = 1024
SECTOR_SIZE = 4096

def build_mpq(out_path, files):
    """files: list of (name_in_archive, bytes)"""
    # --- prepare data blocks (one per file) ---
    blocks = []   # dict(start, csize, fsize, flags)
    payload = bytearray()

    # 1) data sectors
    data_start = 0
    for name, raw in files:
        n = len(raw)
        if n == 0:
            blocks.append(dict(start=len(payload), csize=0, fsize=0,
                               flags=MPQ_FILE_EXISTS|MPQ_FILE_COMPRESS))
            continue
        # split into sectors, compress each independently
        chunks = []
        for off in range(0, n, SECTOR_SIZE):
            chunks.append(raw[off:off+SECTOR_SIZE])
        comp = [zlib.compress(c, 9) for c in chunks]
        use_comp = all(len(c) < len(o) for c,o in zip(comp, chunks))
        sector_offsets = []
        body = bytearray()
        if use_comp:
            for c in comp: body.extend(c)
        else:
            body.extend(raw)
        # sector offset table (n+1 entries) then body
        rel = len(payload)
        tab = bytearray()
        acc = 4*(len(chunks)+1)
        for c in (comp if use_comp else chunks):
            tab.extend(struct.pack("<I", acc))
            acc += len(c)
        tab.extend(struct.pack("<I", acc))
        payload.extend(tab)
        payload.extend(body)
        # if compressed, block starts at offset table (which is encrypted separately)
        key = hstr(os.path.basename(name).replace("/","\\"), 3) if False else hstr(name, 3)
        start = rel
        csize = len(tab)+len(body)
        blocks.append(dict(start=start, csize=csize, fsize=n,
                           flags=MPQ_FILE_EXISTS | (MPQ_FILE_COMPRESS if use_comp else 0)))
        print("  file:", name, "fsize", n, "csize", csize, "compressed", use_comp)

    # 2) listfile
    listfile = ("\r\n".join(f[0] for f in files) + "\r\n").encode("ascii")
    files_count = len(blocks)
    lf_start = len(payload)
    payload.extend(listfile)
    lf_idx = files_count
    blocks.append(dict(start=lf_start, csize=len(listfile), fsize=len(listfile),
                       flags=MPQ_FILE_EXISTS))
    print("  listfile:", len(listfile), "bytes at", lf_start)

    # --- component offsets (aligned) ---
    def align(x): return (x + 512 - 1) // 512 * 512
    header_size = 32
    ptr = header_size
    off_htab = align(ptr); ptr = off_htab + HASH_TABLE_SIZE*16
    off_btab = align(ptr); ptr = off_btab + len(blocks)*16
    off_data = align(ptr)
    # shift block starts
    for b in blocks: b["start"] += off_data

    # block table = len(blocks) entries, each with an index (fsize etc.)
    # Hash table
    htab = bytearray(HASH_TABLE_SIZE*16)
    for i in range(HASH_TABLE_SIZE):
        struct.pack_into("<IIII", htab, i*16, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF)
    for idx, (name, raw) in enumerate(files):
        h = hstr(name, 0)
        pos = h & (HASH_TABLE_SIZE-1)
        while struct.unpack_from("<I", htab, pos*16)[0] != 0xFFFFFFFF:
            pos = (pos+1) & (HASH_TABLE_SIZE-1)
        struct.pack_into("<IIII", htab, pos*16,
                         hstr(name,1), hstr(name,2), 0xFFFFFFFF, idx)
    # listfile entry
    lname = "(listfile)"
    hl = hstr(lname,0); pos = hl & (HASH_TABLE_SIZE-1)
    while struct.unpack_from("<I", htab, pos*16)[0] != 0xFFFFFFFF:
        pos = (pos+1) & (HASH_TABLE_SIZE-1)
    struct.pack_into("<IIII", htab, pos*16, hstr(lname,1), hstr(lname,2), 0xFFFFFFFF, lf_idx)

    htab = enc(bytes(htab), hstr("(hash table)", 3))

    # Block table
    btab = bytearray()
    for b in blocks:
        btab.extend(struct.pack("<IIII", b["start"], b["csize"], b["fsize"], b["flags"]))
    btab = enc(bytes(btab), hstr("(block table)", 3))

    # --- header (v3) ---
    filesize = off_data + len(payload)
    hdr = bytearray()
    hdr.extend(struct.pack("<4sIIHHIIII", b"MPQ\x1A",
                           off_data, filesize, 3, 3, 0x00000200,
                           HASH_TABLE_SIZE, off_htab, off_btab))
    assert len(hdr) == 32, len(hdr)
    hdr.extend(struct.pack("<Q", 0x1189))  # ext header? -> mono? no

    out = bytearray()
    out.extend(struct.pack("<4sIIHHIIII", b"MPQ\x1A",
                           off_data, filesize, 3, 3, 0x00000200,
                           HASH_TABLE_SIZE, off_htab, off_btab))
    out.extend(b"\x00"*(off_htab-32))
    out.extend(htab)
    out.extend(b"\x00"*(off_btab-len(out)))
    out.extend(btab)
    out.extend(b"\x00"*(off_data-len(out)))
    out.extend(payload)
    open(out_path,"wb").write(out)
    print("OK:", out_path, len(out), "bytes | data@", off_data, "htab@", off_htab, "btab@", off_btab)
    return out_path

if __name__ == "__main__":
    base = r"C:\Users\Orel\AppData\Local\Temp\gigatool\patch-x-build"
    src  = os.path.join(base, "client_dbc")
    files = []
    for fn in ("CharTitles.dbc", "Spell.dbc"):
        p = os.path.join(src, fn)
        data = open(p,"rb").read()
        files.append(("DBFilesClient\\" + fn, data))
        print("input:", fn, len(data), "bytes")
    build_mpq(os.path.join(base, "patch-x.mpq"), files)

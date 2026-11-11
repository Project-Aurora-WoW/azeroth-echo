import struct, zlib, os

def build_table(n=0x500):
    t=[0]*n; seed=0x00100001
    for i in range(0x100):
        idx=i
        for _ in range(5):
            seed=(seed*125+3)%0x2AAAAB; t1=(seed&0xFFFF)<<0x10
            seed=(seed*125+3)%0x2AAAAB; t2=seed&0xFFFF
            t[idx]=(t1|t2)&0xFFFFFFFF; idx+=0x100
    return t
T=build_table()

def hstr(name, kind):
    if kind==2: s=name.upper().replace("/","\\")
    elif kind==3: s=name.lower().replace("/","\\")
    else: s=name.replace("/","\\")
    s1,s2=0x7FED7FED,0xEEEEEEEE
    for ch in s.encode("ascii"):
        s1=(T[0x100+ch]^((s1+s2)&0xFFFFFFFF))&0xFFFFFFFF
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
        key=((((~key)&0xFFFFFFFF)<<0x15)+0x11111111|(key>>0x0B))&0xFFFFFFFF
        seed=(plain+seed+((seed<<5)&0xFFFFFFFF)+3)&0xFFFFFFFF
        out.extend(struct.pack("<I",ch))
    return bytes(out)

MPQ_FILE_EXISTS=0x80000000
MPQ_FILE_COMPRESS=0x00000200
HT=1024
SEC=4096

def build(out_path, files):
    payload=bytearray(); blocks=[]
    for name, raw in files:
        n=len(raw)
        chunks=[raw[o:o+SEC] for o in range(0,n,SEC)] or [b""]
        comp=[zlib.compress(c,9) for c in chunks]
        use=all(len(c)<len(o) for c,o in zip(comp,chunks)) and n>0
        src=comp if use else chunks
        tab=bytearray(); acc=4*(len(chunks)+1)
        for c in src:
            tab.extend(struct.pack("<I",acc)); acc+=len(c)
        tab.extend(struct.pack("<I",acc))
        body=bytearray(tab)
        for c in src: body.extend(c)
        blocks.append(dict(name=name,start=len(payload),csize=len(body),fsize=n,
                           flags=MPQ_FILE_EXISTS|(MPQ_FILE_COMPRESS if use else 0)))
        payload.extend(body)
        print(f"  {name}: fsize={n} csize={len(body)} comp={use}")
    lf=("\r\n".join(f[0] for f in files)+"\r\n").encode("ascii")
    blocks.append(dict(name="(listfile)",start=len(payload),csize=len(lf),fsize=len(lf),flags=MPQ_FILE_EXISTS))
    payload.extend(lf)

    def align(x): return (x+511)//512*512
    off_h=align(32); off_b=align(off_h+HT*16); off_d=align(off_b+len(blocks)*16)
    for b in blocks: b["start"]+=off_d

    htab=bytearray(b"\xff"*(HT*16))
    for i,b in enumerate(blocks):
        h=hstr(b["name"],0)&(HT-1)
        while struct.unpack_from("<I",htab,h*16)[0]!=0xFFFFFFFF: h=(h+1)&(HT-1)
        struct.pack_into("<IIII",htab,h*16,hstr(b["name"],1),hstr(b["name"],2),0xFFFFFFFF,i)
    htab=enc(bytes(htab),hstr("(hash table)",3))

    btab=bytearray()
    for b in blocks: btab.extend(struct.pack("<IIII",b["start"],b["csize"],b["fsize"],b["flags"]))
    btab=enc(bytes(btab),hstr("(block table)",3))

    total=off_d+len(payload)
    out=bytearray(struct.pack("<4sIIHHIIII",b"MPQ\x1a",32,total,1,12,0,HT,off_h,off_b))
    out.extend(b"\x00"*(off_h-len(out))); out.extend(htab)
    out.extend(b"\x00"*(off_b-len(out))); out.extend(btab)
    out.extend(b"\x00"*(off_d-len(out))); out.extend(payload)
    open(out_path,"wb").write(out)
    print(f"OK {out_path}: {len(out)} bytes, {len(files)} files + listfile")

base=r"C:\Users\Orel\Downloads\mod-custom-realm\client\custom maps"
out=r"C:\Users\Orel\AppData\Local\Temp\gigatool\patch-x-build\patch-Z.mpq"
files=[("DBFilesClient\\Map.dbc", open(os.path.join(base,"DBFilesClient","Map.dbc"),"rb").read())]
wdir=os.path.join(base,"World","Maps","CustomMaps")
files.append(("World\\Maps\\CustomMaps\\CustomMaps.wdt", open(os.path.join(wdir,"CustomMaps.wdt"),"rb").read()))
for fn in sorted(os.listdir(wdir)):
    if fn.endswith(".adt"):
        files.append(("World\\Maps\\CustomMaps\\"+fn, open(os.path.join(wdir,fn),"rb").read()))
print("файлов всего:", len(files))
build(out, files)

"""Проверка MPQ: распаковывает блоки и сверяет их с исходными DBC.

Не доказывает, что клиент примет файл, — проверяет только целостность
контейнера и совпадение распакованного содержимого с источниками.

Использование:
    python tools/dbc/verify_mpq.py <patch.mpq> <каталог с DBC>
"""

import struct
import zlib
import sys
import os
import hashlib

MPQ_FILE_COMPRESS = 0x00000200


def build_table(n=0x500):
    t = [0] * n
    seed = 0x00100001
    for i in range(0x100):
        idx = i
        for _ in range(5):
            seed = (seed * 125 + 3) % 0x2AAAAB
            t1 = (seed & 0xFFFF) << 0x10
            seed = (seed * 125 + 3) % 0x2AAAAB
            t2 = seed & 0xFFFF
            t[idx] = (t1 | t2) & 0xFFFFFFFF
            idx += 0x100
    return t


T = build_table()


def hstr(name, kind):
    if kind == 2:
        s = name.upper().replace("/", "\\")
    elif kind == 3:
        s = name.lower().replace("/", "\\")
    else:
        s = name.replace("/", "\\")
    s1, s2 = 0x7FED7FED, 0xEEEEEEEE
    for ch in s.encode("ascii"):
        s1 = (T[0x100 + ch] ^ ((s1 + s2) & 0xFFFFFFFF)) & 0xFFFFFFFF
        s2 = (ch + s1 + s2 + ((s2 << 5) & 0xFFFFFFFF) + 3) & 0xFFFFFFFF
    return s1 if kind in (0, 1) else s2


def dec(data, key):
    key &= 0xFFFFFFFF
    seed = 0xEEEEEEEE
    out = bytearray()
    for i in range(0, len(data), 4):
        seed = (seed + T[0x400 + (key & 0xFF)]) & 0xFFFFFFFF
        ch = struct.unpack_from("<I", data, i)[0]
        sh = seed & 0x1F
        if sh:
            ch = ((ch >> sh) | (ch << (32 - sh))) & 0xFFFFFFFF
        ch = (ch - (key + seed)) & 0xFFFFFFFF
        key = ((((~key) & 0xFFFFFFFF) << 0x15) + 0x11111111 | (key >> 0x0B)) & 0xFFFFFFFF
        seed = (ch + seed + ((seed << 5) & 0xFFFFFFFF) + 3) & 0xFFFFFFFF
        out.extend(struct.pack("<I", ch))
    return bytes(out)


def main():
    mpq_path = sys.argv[1]
    src_dir = sys.argv[2] if len(sys.argv) > 2 else os.path.dirname(mpq_path)

    d = open(mpq_path, "rb").read()
    (sig, hdrsize, arcsize, ver, sector_shift,
     hash_pos, block_pos, hash_size, block_count) = struct.unpack_from("<4sIIHHIIII", d, 0)
    print("hdr: sig=%r size=%d arc=%d ver=%d shift=%d hashPos=%d blockPos=%d "
          "hashSize=%d blocks=%d len=%d"
          % (sig, hdrsize, arcsize, ver, sector_shift, hash_pos, block_pos,
             hash_size, block_count, len(d)))
    assert sig == b"MPQ\x1a", "не MPQ"
    assert hdrsize == 32 and arcsize == len(d), "размер архива в заголовке не совпадает с файлом"
    assert sector_shift == 12, "ожидается сектор 4096 (shift 12), получено %d" % sector_shift

    htab = dec(d[hash_pos:hash_pos + hash_size * 16], hstr("(hash table)", 3))
    btab = dec(d[block_pos:block_pos + 16 * block_count], hstr("(block table)", 3))

    entries = []
    for i in range(hash_size):
        h1, h2, loc, bi = struct.unpack_from("<IIII", htab, i * 16)
        if h1 != 0xFFFFFFFF and loc == 0xFFFFFFFF:
            entries.append(bi)
    n_blocks = block_count if block_count else (max(entries) + 1 if entries else 0)
    blocks = [struct.unpack_from("<IIII", btab, i * 16) for i in range(n_blocks)]
    print("блоков: %d" % n_blocks)

    def extract(idx, sector_size):
        start, csize, fsize, flags = blocks[idx]
        raw = d[start:start + csize]
        if flags & MPQ_FILE_COMPRESS:
            ntab = fsize // sector_size + 1
            tab = [struct.unpack_from("<I", raw, i * 4)[0] for i in range(ntab + 1)]
            out = bytearray()
            for k in range(ntab):
                a, b = tab[k], tab[k + 1]
                out.extend(zlib.decompress(raw[a:b]))
            return bytes(out)
        return raw

    ok = True
    for idx in range(n_blocks):
        data = extract(idx, 4096)
        fsize = blocks[idx][2]
        same = len(data) == fsize
        ok = ok and same
        print("  блок %d: %d байт, fsize %d, совпадает: %s"
              % (idx, len(data), fsize, same))

    # сверка с источниками, если они рядом
    for fn in ("CharTitles.dbc", "Spell.dbc"):
        path = os.path.join(src_dir, fn)
        if not os.path.exists(path):
            continue
        src = open(path, "rb").read()
        for idx in range(n_blocks):
            if blocks[idx][2] == len(src) and extract(idx, 4096) == src:
                print("  %s: byte-identical (блок %d, sha %s)"
                      % (fn, idx, hashlib.sha256(src).hexdigest()[:16]))
                break
        else:
            print("  %s: НЕ найден идентичный блок (источник %d байт)" % (fn, len(src)))
            ok = False

    lf_start, lf_size = blocks[-1][0], blocks[-1][1]
    print("listfile:", d[lf_start:lf_start + lf_size])
    print("ИТОГ:", "OK" if ok else "ЕСТЬ РАСХОЖДЕНИЯ")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())

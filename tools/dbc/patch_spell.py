import struct, os

SRC   = r"E:\b2\bin\RelWithDebInfo\data\dbc\Spell.dbc"
OUT   = r"C:\Users\Orel\AppData\Local\Temp\gigatool\patch-x-build\client_dbc\Spell.dbc"
NEW_ID = 70010
TEMPLATE_ID = 45991
NAME_EN = "Summon: Voidrest Pegasus"
NAME_RU = "\u041f\u0440\u0438\u0437\u044b\u0432: \u0411\u0435\u0437\u0434\u043d\u0430-\u041f\u0435\u0433\u0430\u0441"
NAME_FIELD = 136

d = bytearray(open(SRC, "rb").read())
sig, recs, fields, rsize, sb_size = struct.unpack_from("<4sIIII", d, 0)
assert sig == b"WDBC"
off = 20
assert off + recs*rsize + sb_size == len(d)

ids = [struct.unpack_from("<I", d, off+i*rsize)[0] for i in range(recs)]
assert ids == sorted(ids), "IDs not sorted"
assert NEW_ID not in ids, "70010 already exists"

src_row = None
for i in range(recs):
    if ids[i] == TEMPLATE_ID:
        src_row = bytearray(d[off+i*rsize: off+(i+1)*rsize]); break
assert src_row is not None

sb = bytearray(d[len(d)-sb_size:])
if sb and sb[-1] != 0:
    sb.append(0)

def add_str(s):
    b = s.encode("utf-8") + b"\x00"
    o = len(sb); sb.extend(b); return o

off_en = add_str(NAME_EN)
off_ru = add_str(NAME_RU)

new_row = bytearray(src_row)
struct.pack_into("<I", new_row, 0, NEW_ID)
struct.pack_into("<I", new_row, NAME_FIELD*4, off_en)
print("enUS ->", off_en, "| ruRU ->", off_ru, "(ruRU-слот в Spell.dbc не выделен, см. отчёт)")

# вставляем запись в отсортированное место
import bisect
pos = bisect.bisect_left(ids, NEW_ID)
recs_block = bytearray()
for i in range(recs+1):
    if i == pos:
        recs_block.extend(new_row)
    else:
        j = i if i < pos else i-1
        recs_block.extend(d[off+j*rsize: off+(j+1)*rsize])

buf = bytearray(struct.pack("<4sIIII", b"WDBC", recs+1, fields, rsize, len(sb)))
buf.extend(recs_block)
buf.extend(sb)
open(OUT, "wb").write(buf)
print("written", OUT, len(buf), "bytes | records", recs+1, "| inserted at", pos)

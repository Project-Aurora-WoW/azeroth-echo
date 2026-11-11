import struct, io, os, shutil

SRC = r"E:\b2\bin\RelWithDebInfo\data\dbc\ruRU\CharTitles.dbc"
OUT = r"C:\Users\Orel\AppData\Local\Temp\gigatool\patch-x-build\client_dbc\CharTitles.dbc"

NAME_RU = "Хранитель Эха %s"
NAME_FEM_RU = "Хранительница Эха %s"
NAME_EN = "Echo Keeper %s"
NAME_FEM_EN = "Echo Keeper %s"

d = bytearray(open(SRC, "rb").read())
sig, recs, fields, rsize, sb_size = struct.unpack_from("<4sIIII", d, 0)
assert sig == b"WDBC", sig
assert fields == 37 and rsize == 148, (fields, rsize)
off = 20
sb_off = len(d) - sb_size
sb = bytes(d[sb_off:])
rows = [struct.unpack_from("<%dI" % fields, d, off + i*rsize) for i in range(recs)]

# занятые ID
used_ids = {r[0] for r in rows}
NEW_ID = 178
assert NEW_ID not in used_ids, "ID 178 уже занят!"

# берём шаблон от ID 47 (обычный титул, не служебный)
tmpl = None
for i, r in enumerate(rows):
    if r[0] == 47:
        tmpl = r
        break
assert tmpl is not None
print("шаблон ID47:", [x for x in tmpl if x])

# 1) дописываем строки в конец string block
new_sb = bytearray(sb)
if new_sb and new_sb[-1] != 0:
    new_sb.append(0)

def add_string(s):
    b = s.encode("utf-8") + b"\x00"
    o = len(new_sb)
    new_sb.extend(b)
    return o

off_ru_m   = add_string(NAME_RU)
off_ru_f   = add_string(NAME_FEM_RU)
off_en_m   = add_string(NAME_EN)
off_en_f   = add_string(NAME_FEM_EN)

# 2) собираем запись 178 по шаблону
rec = list(tmpl)
rec[0]  = NEW_ID      # ID
rec[1]  = off_ru_m    # Name (основное, ruRU-клиент)
rec[2]  = off_ru_f    # NameFemale (ruRU)
rec[10] = 0           # TitleMask_int1 -> заполним ниже
rec[11] = 0           # TitleMask_int2
rec[27] = off_ru_m    # ruRU Name_lang
rec[36] = 0           # NextTitle

# enUS-слоты: индексы 18..26 соответствуют enUS..itIT в полном шаблоне,
# но в реальном файле enUS-строки лежат в idx 19 (Name_lang enUS для enUS-клиента).
# Основные enUS поля у ruRU-файла пустые — заполняем idx 19 и idx 35 не будем,
# чтобы не сломать клиент: ruRU-клиент берёт idx 1/27.

# TitleMask: ID 178 -> бит 178 по логике 2^(N+17): вне 64 бит, недостижимо.
# Практически маска = step-индекс (idx 10). Берём следующий свободный step после максимума.
max_step = max(r[10] for r in rows)
new_step = max(max_step + 1, NEW_ID + 1)
rec[10] = new_step

print("новый step:", new_step, "| offset ru:", off_ru_m, off_ru_f)

rows.append(tuple(rec))
recs_new = len(rows)

# 3) пишем файл заново
buf = bytearray()
buf.extend(struct.pack("<4sIIII", b"WDBC", recs_new, fields, rsize, len(new_sb)))
flat = b"".join(struct.pack("<%dI" % fields, *r) for r in rows)
buf.extend(flat)
buf.extend(new_sb)

os.makedirs(os.path.dirname(OUT), exist_ok=True)
open(OUT, "wb").write(buf)
print("записано:", OUT, len(buf), "байт | записей:", recs_new)

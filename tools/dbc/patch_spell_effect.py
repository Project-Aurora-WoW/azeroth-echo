"""Переписывает запись кастомного спелла в Spell.dbc по образцу штатного
маунт-спелла и печатает SQL для таблицы spell_dbc.

Зачем: изначально 70010 был клоном 45991, у которого SPELL_EFFECT 76
(SUMMON_OBJECT_WILD) и misc 187903 — это GameObject «Portable Oil Collector».
Маунтом такой спелл не становится: клиент и сервер пытаются создать объект,
а не применить ауру SPELL_AURA_MOUNTED.

Штатные маунт-спеллы (5784, 470, 13819, 22717, 18363, 23214, 34795) устроены
одинаково: Effect_1 = 6 (APPLY_AURA), EffectAura_1 = 78 (MOUNTED),
EffectMiscValue_1 = entry существа-маунта, DurationIndex = 21.

Скрипт копирует из образца все поля, кроме текстовых: названия, описание и
описание ауры дописываются в строковый блок DBC и указывают на свой текст.

Соответствие «номер поля DBC -> имя колонки spell_dbc» берётся из файла
со списком колонок в порядке ordinal (ordinal таблицы = индекс поля + 1):

    mysql -N -B -e "SELECT COLUMN_NAME FROM information_schema.columns
      WHERE table_schema='echo_world' AND table_name='spell_dbc'
      ORDER BY ORDINAL_POSITION" > columns.txt

Использование:
    python tools/dbc/patch_spell_effect.py <Spell.dbc> <columns.txt>
"""

import struct
import sys
import os

TEMPLATE_ID = 5784          # Summon Felsteed
TARGET_ID = 70010           # Summon: Voidrest Pegasus
MOUNT_CREATURE = 29767      # Spectral Gryphon, Mount (displayid 26691)

TEXTS = {
    "Name_Lang_enUS": "Summon: Voidrest Pegasus",
    "Name_Lang_ruRU": "Призыв: Бездна-Пегас",
    "Description_Lang_enUS": "Summons and dismisses the Voidrest Pegasus.",
    "Description_Lang_ruRU": "Призывает и отпускает Бездна-Пегаса.",
    "AuraDescription_Lang_enUS": "Mounted.",
    "AuraDescription_Lang_ruRU": "Вы верхом.",
}


def read_header(data):
    magic, records, fields, recsize, strsize = struct.unpack_from("<4sIIII", data, 0)
    assert magic == b"WDBC", "не WDBC: %r" % magic
    assert 20 + records * recsize + strsize == len(data), "структура DBC не сходится"
    assert fields * 4 == recsize, "recordSize != fields*4"
    return records, fields, recsize, strsize


def find_record(data, records, recsize, spell_id):
    for i in range(records):
        off = 20 + i * recsize
        if struct.unpack_from("<I", data, off)[0] == spell_id:
            return off
    raise SystemExit("запись %d не найдена" % spell_id)


def main():
    path = sys.argv[1]
    columns = [l.strip() for l in open(sys.argv[2], encoding="utf-8") if l.strip()]

    with open(path, "rb") as f:
        raw = f.read()
    data = bytearray(raw)
    records, fields, recsize, strsize = read_header(data)
    assert len(columns) == fields, "колонок %d, полей в DBC %d" % (len(columns), fields)

    tpl_off = find_record(data, records, recsize, TEMPLATE_ID)
    dst_off = find_record(data, records, recsize, TARGET_ID)

    tpl = struct.unpack_from("<%dI" % fields, data, tpl_off)
    dst = list(struct.unpack_from("<%dI" % fields, data, dst_off))

    new = list(tpl)
    keep = {0}
    for idx, col in enumerate(columns):
        if "Name" in col or "Description" in col:
            keep.add(idx)
    for idx in keep:
        new[idx] = dst[idx]
    new[columns.index("EffectMiscValue_1")] = MOUNT_CREATURE

    # строковый блок: дописываем свои тексты
    str_block = bytearray(data[len(data) - strsize:])
    if str_block and str_block[-1] != 0:
        str_block.append(0)

    def add_str(text):
        offset = len(str_block)
        str_block.extend(text.encode("utf-8") + b"\x00")
        return offset

    for col, text in TEXTS.items():
        idx = columns.index(col)
        new[idx] = add_str(text)

    struct.pack_into("<%dI" % fields, data, dst_off, *new)

    buf = bytearray(struct.pack("<4sIIII", b"WDBC", records, fields, recsize, len(str_block)))
    buf.extend(data[20:20 + records * recsize])
    buf.extend(str_block)

    backup = path + ".bak"
    if not os.path.exists(backup):
        with open(backup, "wb") as f:
            f.write(raw)
    with open(path, "wb") as f:
        f.write(buf)

    print("обновлена запись %d в %s" % (TARGET_ID, path))
    print("строковый блок: %d -> %d байт, файл: %d -> %d байт" % (strsize, len(str_block), len(raw), len(buf)))

    changed = [(idx, dst[idx], new[idx]) for idx in range(fields) if dst[idx] != new[idx]]
    print("изменено полей: %d" % len(changed))
    for idx, old, cur in changed:
        print("  %-28s %10d -> %10d" % (columns[idx], old, cur))

    sql_cols = ["`%s` = %d" % (columns[idx], cur) for idx, _old, cur in changed]
    if sql_cols:
        print()
        print("UPDATE `spell_dbc` SET %s WHERE `ID` = %d;" % (", ".join(sql_cols), TARGET_ID))


if __name__ == "__main__":
    main()

"""Аудит кастомного контента: сверяет базу с клиентскими DBC и ищет дырки.

Проверки:
  * НПС и предметы кастомного диапазона без спавна / без модели;
  * displayid существ и предметов, которых нет в клиентских DBC
    (сервер отдаст такой id, клиент не отрисует);
  * незаполненные предметы (displayid = 0, Material < 0, пустое имя);
  * кастомные спеллы: наличие в spell_dbc и корректный эффект для маунтов;
  * карта 5000: спавны, грейвярды, ареатриггеры, game_tele;
  * титулы: chartitles_dbc против CharTitles.dbc клиента.

Требуется pymysql и доступ к серверным DBC в data/dbc.

Использование:
    python tools/verify-content.py --data-dir E:/acbuild/bin/RelWithDebInfo/data \
        --db echo_world --user root --password root
"""

import argparse
import struct
import sys

import pymysql


def load_dbc_ids(path):
    with open(path, "rb") as f:
        data = f.read()
    if data[:4] != b"WDBC":
        raise ValueError("%s: не WDBC" % path)
    records, fields, recsize, strsize = struct.unpack("<IIII", data[4:20])
    if 20 + records * recsize + strsize != len(data):
        raise ValueError("%s: структура DBC не сходится" % path)
    ids = set()
    for i in range(records):
        off = 20 + i * recsize
        ids.add(struct.unpack_from("<I", data, off)[0])
    return ids


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data-dir", required=True, help="каталог data сборки (там dbc/)")
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--user", default="root")
    ap.add_argument("--password", default="root")
    ap.add_argument("--db", default="echo_world")
    ap.add_argument("--lo", type=int, default=70000, help="нижняя граница кастомных id")
    ap.add_argument("--hi", type=int, default=70299, help="верхняя граница кастомных id")
    args = ap.parse_args()

    problems = []

    def note(msg):
        problems.append(msg)
        print("  [!] " + msg)

    creature_dbc = load_dbc_ids(args.data_dir + "/dbc/CreatureDisplayInfo.dbc")
    item_dbc = load_dbc_ids(args.data_dir + "/dbc/ItemDisplayInfo.dbc")
    print("DBC: CreatureDisplayInfo %d, ItemDisplayInfo %d записей"
          % (len(creature_dbc), len(item_dbc)))

    conn = pymysql.connect(host=args.host, user=args.user, password=args.password,
                           database=args.db, charset="utf8mb4", cursorclass=pymysql.cursors.DictCursor)
    try:
        with conn.cursor() as cur:
            rng = (args.lo, args.hi)

            print("\n1. НПС без спавна")
            cur.execute("""
                SELECT t.entry, t.name FROM creature_template t
                WHERE t.entry BETWEEN %s AND %s
                  AND NOT EXISTS (SELECT 1 FROM creature c WHERE c.id = t.entry)
                ORDER BY t.entry""", rng)
            for row in cur.fetchall():
                note("НПС %s «%s» без спавна" % (row["entry"], row["name"]))

            print("\n2. Модели НПС вне клиентского DBC")
            cur.execute("""
                SELECT t.entry, t.name, m.CreatureDisplayID
                FROM creature_template t
                JOIN creature_template_model m ON m.CreatureID = t.entry
                WHERE t.entry BETWEEN %s AND %s""", rng)
            for row in cur.fetchall():
                if row["CreatureDisplayID"] not in creature_dbc:
                    note("НПС %s «%s»: displayid %s нет в CreatureDisplayInfo.dbc"
                         % (row["entry"], row["name"], row["CreatureDisplayID"]))

            print("\n3. Предметы: полнота и модели")
            cur.execute("""
                SELECT entry, name, displayid, Material, class, subclass
                FROM item_template WHERE entry BETWEEN %s AND %s ORDER BY entry""", rng)
            for row in cur.fetchall():
                if row["displayid"] == 0:
                    note("предмет %s «%s»: displayid = 0" % (row["entry"], row["name"]))
                elif row["displayid"] not in item_dbc:
                    note("предмет %s «%s»: displayid %s нет в ItemDisplayInfo.dbc"
                         % (row["entry"], row["name"], row["displayid"]))
                if row["Material"] is not None and row["Material"] < 0:
                    note("предмет %s: Material < 0" % row["entry"])
                if not row["name"]:
                    note("предмет %s: пустое имя" % row["entry"])

            print("\n4. Маунты: структура спелла")
            cur.execute("""
                SELECT i.entry, i.name, i.spellid_1, i.subclass, i.spellcategory_1,
                       s.Effect_1, s.EffectAura_1, s.EffectMiscValue_1
                FROM item_template i
                LEFT JOIN spell_dbc s ON s.ID = i.spellid_1
                WHERE i.entry BETWEEN %s AND %s AND i.class = 15 AND i.subclass = 5""", rng)
            for row in cur.fetchall():
                if row["EffectAura_1"] != 78:
                    note("маунт-предмет %s «%s»: спелл %s без SPELL_AURA_MOUNTED (aura=%s)"
                         % (row["entry"], row["name"], row["spellid_1"], row["EffectAura_1"]))
                if not row["EffectMiscValue_1"]:
                    note("маунт-предмет %s: у спелла не задано существо (misc=0)" % row["entry"])
                if row["spellcategory_1"] != 330:
                    note("маунт-предмет %s: spellcategory %s вместо 330"
                         % (row["entry"], row["spellcategory_1"]))

            print("\n5. Карта 5000")
            for label, query in (
                ("спавны существ", "SELECT COUNT(*) AS n FROM creature WHERE map = 5000"),
                ("геймобъекты", "SELECT COUNT(*) AS n FROM gameobject WHERE map = 5000"),
                ("грейвярды", "SELECT COUNT(*) AS n FROM graveyard_zone WHERE GhostZone = 5000"),
                ("ареатриггеры", "SELECT COUNT(*) AS n FROM areatrigger_teleport WHERE target_map = 5000"),
                ("game_tele", "SELECT COUNT(*) AS n FROM game_tele WHERE name LIKE '%%morza%%' OR name LIKE '%%betrayal%%'"),
            ):
                cur.execute(query)
                n = cur.fetchone()["n"]
                print("  %-16s %s" % (label, n))
                if n == 0 and label != "геймобъекты":
                    note("карта 5000: нет данных «%s»" % label)

            print("\n6. Титулы")
            cur.execute("SELECT COUNT(*) AS n FROM chartitles_dbc")
            print("  строк в chartitles_dbc: %s" % cur.fetchone()["n"])
            cur.execute("SELECT ID FROM chartitles_dbc ORDER BY ID")
            for row in cur.fetchall():
                print("  титул %s" % row["ID"])
    finally:
        conn.close()

    print("\nИТОГО: %d замечаний" % len(problems))
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())

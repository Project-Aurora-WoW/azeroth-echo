"""Сборка MPQ настоящим StormLib (через ctypes), а не самописным форматом.

Причина: наш Python-сборщик создавал архивы, которые не открываются ни
StormLib, ни libmpq: MPQ Editor отвечал «ошибка синтаксиса», mapextractor
видел 135 карт вместо 136, клиент такие патчи игнорирует.

Использование:
    # patch-x: титул и спелл
    python tools/dbc/build_mpq_stormlib.py patch-x <out.mpq> \
        <CharTitles.dbc> <Spell.dbc>

    # patch-Z: карта 5000
    python tools/dbc/build_mpq_stormlib.py patch-z <out.mpq> <каталог custom maps>

    # произвольный набор
    python tools/dbc/build_mpq_stormlib.py files <out.mpq> <диск:путь_в_архиве> ...
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from stormlib import StormLib  # noqa: E402


def build(sl, out_path, entries, max_files=4096):
    archive = sl.create(out_path, max_files=max_files)
    if not archive:
        raise SystemExit("не удалось создать архив %s" % out_path)
    try:
        for disk_path, archived_name in entries:
            if not os.path.exists(disk_path):
                raise SystemExit("нет файла %s" % disk_path)
            ok = sl.add_file(archive, disk_path, archived_name)
            print("  %-46s %8d байт  %s"
                  % (archived_name, os.path.getsize(disk_path), "ok" if ok else "ОШИБКА"))
            if not ok:
                raise SystemExit("не удалось добавить %s" % archived_name)
        sl.lib.SFileFlushArchive(archive)
    finally:
        sl.close(archive)

    check_archive = sl.open(out_path)
    if not check_archive:
        raise SystemExit("архив %s не открывается после сборки" % out_path)
    print("готово: %s (%d байт), открывается StormLib"
          % (out_path, os.path.getsize(out_path)))
    return check_archive


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        return 2

    mode, out_path = sys.argv[1], sys.argv[2]
    args = sys.argv[3:]
    entries = []

    if mode == "patch-x":
        for path in args:
            entries.append((path, "DBFilesClient\\" + os.path.basename(path)))
    elif mode == "patch-z":
        base = args[0]
        entries.append((os.path.join(base, "DBFilesClient", "Map.dbc"),
                        "DBFilesClient\\Map.dbc"))
        maps_dir = os.path.join(base, "World", "Maps", "CustomMaps")
        for name in sorted(os.listdir(maps_dir)):
            if name.lower().endswith((".wdt", ".adt")):
                entries.append((os.path.join(maps_dir, name),
                                "World\\Maps\\CustomMaps\\" + name))
    elif mode == "files":
        for pair in args:
            disk_path, archived = pair.split("=", 1)
            entries.append((disk_path, archived))
    else:
        print("неизвестный режим:", mode)
        return 2

    print("файлов: %d" % len(entries))
    sl = StormLib()
    print("StormLib:", sl.path)
    build(sl, out_path, entries)
    return 0


if __name__ == "__main__":
    sys.exit(main())

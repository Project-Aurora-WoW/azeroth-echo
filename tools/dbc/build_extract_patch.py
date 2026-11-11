"""Собирает временный patch-5.MPQ из исходников кастомной карты.

Зачем: map_extractor ищет архивы по жёсткому списку в System.cpp
(common.MPQ, lichking.MPQ, patch.MPQ ... patch-5.MPQ) и не читает
patch-x.mpq / patch-Z.mpq. Чтобы извлечь серверные данные карты 5000,
её файлы нужно положить в архив с именем из этого списка.

    python tools/dbc/build_extract_patch.py <исходники custom maps> <patch-5.MPQ>
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_mpq import build_mpq  # noqa: E402


def main():
    src = sys.argv[1]
    out = sys.argv[2]

    files = [("DBFilesClient\\Map.dbc",
              open(os.path.join(src, "DBFilesClient", "Map.dbc"), "rb").read())]

    maps_dir = os.path.join(src, "World", "Maps", "CustomMaps")
    for name in sorted(os.listdir(maps_dir)):
        if name.lower().endswith((".wdt", ".adt")):
            files.append(("World\\Maps\\CustomMaps\\" + name,
                          open(os.path.join(maps_dir, name), "rb").read()))

    print("файлов для архива: %d" % len(files))
    build_mpq(out, files)


if __name__ == "__main__":
    main()

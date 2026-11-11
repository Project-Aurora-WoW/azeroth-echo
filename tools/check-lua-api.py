"""Сверяет вызовы Lua-методов в скриптах с тем, что реально предоставляет ALE.

Зачем: скрипты писались под старый Eluna, а ALE — независимый форк. Методы
вроде `IsFFA` или `GetSession` в нём отсутствуют, и ошибка вылезает только
в рантайме, когда игрок нажмёт нужную кнопку. Проверка ловит это заранее.

Как работает:
  * из исходников ALE (LuaFunctions.cpp, GlobalMethods.h, LuaEngine) собирает
    все зарегистрированные имена — они оформлены как `{ "Name", &LuaX::Name }`;
  * выдёргивает из lua_scripts все вызовы вида `obj:Method(`;
  * вычитает стандартную библиотеку Lua и то, что ALE действительно умеет.

Использование:
    python tools/check-lua-api.py --ale E:/azeroth/modules/mod-ale --scripts E:/azeroth-echo/lua_scripts
Код возврата 1, если найдены неизвестные методы.
"""

import argparse
import os
import re
import sys

REGISTER_RE = re.compile(r'\{\s*"([A-Za-z_][A-Za-z0-9_]*)"\s*,\s*&')
# Часть методов регистрируется полем метатаблицы, а не парой { "Name", &Fn }:
# lua_setfield(E->L, metatable, "GetObjectType");
SETFIELD_RE = re.compile(r'lua_setfield\([^;]*?"([A-Za-z_][A-Za-z0-9_]*)"\s*\)')
METHOD_CALL_RE = re.compile(r':([A-Za-z_][A-Za-z0-9_]*)\s*\(')
GLOBAL_CALL_RE = re.compile(r'(?<![:.\w])([A-Za-z_][A-Za-z0-9_]*)\s*\(')

LUA_STDLIB = {
    # string
    "byte", "char", "dump", "find", "format", "gfind", "gmatch", "gsub", "len",
    "lower", "match", "rep", "reverse", "sub", "upper",
    # table
    "concat", "insert", "maxn", "remove", "sort",
    # math / os / io
    "abs", "ceil", "floor", "huge", "max", "min", "random", "randomseed", "sqrt",
    "time", "date", "clock", "difftime",
    "open", "close", "write", "read", "lines",
    # общее
    "assert", "error", "ipairs", "next", "pairs", "pcall", "print", "rawequal",
    "rawget", "rawset", "select", "setmetatable", "getmetatable", "tonumber",
    "tostring", "type", "unpack", "xpcall", "require", "collectgarbage",
}

# Совпадения, которые неизбежно ловятся регуляркой, но ошибкой не являются:
# методы объектов, создаваемых самим скриптом (AIO, Query, Packet и т.п.),
# и обращения к полям таблиц через двоеточие в комментариях.
# Файлы, которые исполняются на клиенте (WoW API: CreateFrame, SetFont и т.п.),
# а не в ALE — их методы в API движка и не должны быть.
SKIP_FILES = {"Store_Client.lua", "AIO.lua", "queue.lua"}
SKIP_DIRS = {"Dep_crc32lua", "Dep_LuaSrcDiet", "Dep_Smallfolk", "extensions", "lualzw-zeros"}

IGNORE_METHODS = {
    # Query, возвращаемый WorldDBQuery/CharDBQuery — методы ALE, но объявлены
    # в QueryMethods.h без регистрации в общем стиле
    "GetUInt8", "GetUInt16", "GetUInt32", "GetUInt64", "GetInt8", "GetInt16",
    "GetInt32", "GetInt64", "GetFloat", "GetDouble", "GetString", "GetBool",
    "NextRow", "GetRow",
}


def collect_ale_names(ale_dir):
    names = set()
    for root, _dirs, files in os.walk(ale_dir):
        for name in files:
            if not name.endswith((".cpp", ".h")):
                continue
            path = os.path.join(root, name)
            try:
                text = open(path, encoding="utf-8", errors="replace").read()
            except OSError:
                continue
            for match in REGISTER_RE.finditer(text):
                names.add(match.group(1))
            for match in SETFIELD_RE.finditer(text):
                names.add(match.group(1))
    return names


def collect_calls(scripts_dir):
    calls = {}
    for root, dirs, files in os.walk(scripts_dir):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for name in files:
            if not name.endswith(".lua") or name in SKIP_FILES:
                continue
            path = os.path.join(root, name)
            text = open(path, encoding="utf-8", errors="replace").read()
            for lineno, line in enumerate(text.splitlines(), 1):
                stripped = line.split("--", 1)[0]
                for match in METHOD_CALL_RE.finditer(stripped):
                    calls.setdefault(match.group(1), []).append(
                        "%s:%d" % (os.path.relpath(path, scripts_dir), lineno))
    return calls


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ale", required=True, help="каталог модуля mod-ale")
    ap.add_argument("--scripts", required=True, help="каталог lua_scripts")
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    ale_names = collect_ale_names(args.ale)
    if not ale_names:
        print("не удалось собрать API из %s — проверьте путь" % args.ale)
        return 2
    print("API ALE: %d зарегистрированных имён" % len(ale_names))

    calls = collect_calls(args.scripts)
    print("вызовов :Метод( в скриптах: %d различных" % len(calls))

    unknown = {}
    for meth, places in calls.items():
        if meth in ale_names or meth in LUA_STDLIB or meth in IGNORE_METHODS:
            continue
        unknown[meth] = places

    if not unknown:
        print("\nнеизвестных методов не найдено")
        return 0

    print("\nметоды, которых нет в API ALE (%d):" % len(unknown))
    for meth in sorted(unknown):
        places = unknown[meth]
        print("  %-24s %s" % (meth, ", ".join(places[:4]) + (" …" if len(places) > 4 else "")))
    return 1


if __name__ == "__main__":
    sys.exit(main())

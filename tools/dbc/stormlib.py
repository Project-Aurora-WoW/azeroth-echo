"""Обёртка StormLib через ctypes: проверка и сборка MPQ настоящей библиотекой.

Зачем: наш Python-сборщик писал архивы, которые StormLib и libmpq не читают
(MPQ Editor отвечал «ошибка синтаксиса», mapextractor видел 135 карт вместо 136).
Такие патчи клиент просто игнорирует — отсюда и зависание на загрузке карты.

Использование:
    python tools/dbc/stormlib.py check <архив> [<файл внутри>]
    python tools/dbc/stormlib.py info  <архив>
"""

import ctypes
import os
import struct
import sys

DLL_CANDIDATES = [
    r"C:\Users\Orel\Downloads\WDBX.Editor\x64\StormLib.dll",
    r"C:\Users\Orel\Downloads\WDBX.Editor\StormLib.dll",
    r"C:\Users\Orel\Desktop\Ladik's MPQ Editor\StormLib.dll",
    r"C:\Users\Orel\Desktop\Ladik's MPQ Editor\x64\StormLib.dll",
]

MPQ_CREATE_LISTFILE = 0x00100000
MPQ_CREATE_ATTRIBUTES = 0x00200000
MPQ_FILE_EXISTS = 0x80000000
MPQ_FILE_COMPRESS = 0x00000200
MPQ_COMPRESSION_ZLIB = 0x02
MPQ_OPEN_READ_ONLY = 0x00000100


def find_dll():
    for path in DLL_CANDIDATES:
        if os.path.exists(path):
            return path
    raise SystemExit("StormLib.dll не найден ни по одному из путей")


class StormLib:
    def __init__(self, dll_path=None):
        self.path = dll_path or find_dll()
        self.lib = ctypes.WinDLL(self.path)
        self._bind()

    def _bind(self):
        lib = self.lib
        lib.SFileOpenArchive.argtypes = [ctypes.c_wchar_p, ctypes.c_uint32,
                                         ctypes.c_uint32, ctypes.POINTER(ctypes.c_void_p)]
        lib.SFileOpenArchive.restype = ctypes.c_int
        lib.SFileCreateArchive.argtypes = [ctypes.c_wchar_p, ctypes.c_uint32,
                                           ctypes.c_uint32, ctypes.POINTER(ctypes.c_void_p)]
        lib.SFileCreateArchive.restype = ctypes.c_int
        lib.SFileAddFileEx.argtypes = [ctypes.c_void_p, ctypes.c_wchar_p, ctypes.c_wchar_p,
                                       ctypes.c_uint32, ctypes.c_uint32, ctypes.c_uint32]
        lib.SFileAddFileEx.restype = ctypes.c_int
        lib.SFileOpenFileEx.argtypes = [ctypes.c_void_p, ctypes.c_wchar_p, ctypes.c_uint32,
                                        ctypes.POINTER(ctypes.c_void_p)]
        lib.SFileOpenFileEx.restype = ctypes.c_int
        lib.SFileGetFileSize.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_uint32)]
        lib.SFileGetFileSize.restype = ctypes.c_uint32
        lib.SFileReadFile.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_uint32,
                                      ctypes.POINTER(ctypes.c_uint32), ctypes.c_void_p]
        lib.SFileReadFile.restype = ctypes.c_int
        lib.SFileCloseFile.argtypes = [ctypes.c_void_p]
        lib.SFileCloseFile.restype = ctypes.c_int
        lib.SFileFlushArchive.argtypes = [ctypes.c_void_p]
        lib.SFileFlushArchive.restype = ctypes.c_int
        lib.SFileCloseArchive.argtypes = [ctypes.c_void_p]
        lib.SFileCloseArchive.restype = ctypes.c_int

    def open(self, mpq_path, read_only=True):
        handle = ctypes.c_void_p()
        flags = MPQ_OPEN_READ_ONLY if read_only else 0
        ok = self.lib.SFileOpenArchive(mpq_path, 0, flags, ctypes.byref(handle))
        return handle if ok else None

    def create(self, mpq_path, max_files=2048, with_listfile=True):
        handle = ctypes.c_void_p()
        flags = MPQ_CREATE_ATTRIBUTES | (MPQ_CREATE_LISTFILE if with_listfile else 0)
        if os.path.exists(mpq_path):
            os.remove(mpq_path)
        ok = self.lib.SFileCreateArchive(mpq_path, flags, max_files,
                                         ctypes.byref(handle))
        return handle if ok else None

    def add_file(self, archive, disk_path, archived_name, compress=True):
        flags = MPQ_FILE_EXISTS | (MPQ_FILE_COMPRESS if compress else 0)
        return bool(self.lib.SFileAddFileEx(archive, disk_path,
                                            archived_name,
                                            flags, MPQ_COMPRESSION_ZLIB, 0))

    def read_file(self, archive, name):
        handle = ctypes.c_void_p()
        if not self.lib.SFileOpenFileEx(archive, name, 0, ctypes.byref(handle)):
            return None
        try:
            size_high = ctypes.c_uint32()
            size = self.lib.SFileGetFileSize(handle, ctypes.byref(size_high))
            buf = ctypes.create_string_buffer(size)
            read = ctypes.c_uint32()
            if not self.lib.SFileReadFile(handle, buf, size, ctypes.byref(read), None):
                return None
            return buf.raw[:read.value]
        finally:
            self.lib.SFileCloseFile(handle)

    def close(self, archive):
        if archive:
            self.lib.SFileCloseArchive(archive)


def dbc_record_count(data):
    if data[:4] != b"WDBC":
        return None
    return struct.unpack_from("<I", data, 4)[0]


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 2

    cmd, path = sys.argv[1], sys.argv[2]
    sl = StormLib()
    print("StormLib:", sl.path)

    if cmd in ("check", "info"):
        archive = sl.open(path)
        if not archive:
            print("НЕ ОТКРЫВАЕТСЯ: %s" % path)
            return 1
        print("открыт: %s" % path)
        if cmd == "check" and len(sys.argv) > 3:
            name = sys.argv[3]
            data = sl.read_file(archive, name)
            if data is None:
                print("файл %s не читается" % name)
                sl.close(archive)
                return 1
            print("файл %s: %d байт, записей DBC: %s"
                  % (name, len(data), dbc_record_count(data)))
        sl.close(archive)
        return 0

    print("неизвестная команда:", cmd)
    return 2


if __name__ == "__main__":
    sys.exit(main())

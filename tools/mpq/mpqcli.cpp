// mpqcli — минимальный CLI для сборки и проверки MPQ на нативном StormLib.
//
// Зачем: через ctypes (Python) StormLib стабильно портил второй вызов подряд
// (SFileAddFileEx перетирал первый файл). Нативный вызов из C++ этой проблемы
// не имеет, поэтому патчи собираются здесь, а не из Python.
//
// Сборка: см. tools/mpq/build-mpqcli.cmd
//
// Команды:
//   create <mpq> [maxfiles]                       — создать архив (v1, с listfile)
//   add    <mpq> <файл> <имя в архиве> [store]    — добавить файл (по умолчанию zlib)
//   list   <mpq>                                  — перечислить файлы
//   has    <mpq> <имя в архиве>                   — проверить наличие
//   read   <mpq> <имя в архиве> <файл на диске>   — извлечь файл
//   size   <mpq> <имя в архиве>                   — показать размер файла в архиве

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>

#include "StormLib.h"

static int usage()
{
    std::printf(
        "mpqcli create <mpq> [maxfiles]\n"
        "mpqcli add    <mpq> <diskfile> <archivedname> [store]\n"
        "mpqcli list   <mpq>\n"
        "mpqcli has    <mpq> <archivedname>\n"
        "mpqcli read   <mpq> <archivedname> <outfile>\n"
        "mpqcli size   <mpq> <archivedname>\n");
    return 2;
}

static int createArchive(const char* path, DWORD maxFiles)
{
    HANDLE hMpq = nullptr;
    if (!SFileCreateArchive(path, MPQ_CREATE_LISTFILE | MPQ_CREATE_ATTRIBUTES, maxFiles, &hMpq))
    {
        std::printf("create failed: %u\n", GetLastError());
        return 1;
    }
    SFileFlushArchive(hMpq);
    SFileCloseArchive(hMpq);
    std::printf("created %s (max %u files)\n", path, maxFiles);
    return 0;
}

static int addFile(const char* mpq, const char* disk, const char* name, bool store)
{
    HANDLE hMpq = nullptr;
    if (!SFileOpenArchive(mpq, 0, 0, &hMpq))
    {
        std::printf("open failed: %u\n", GetLastError());
        return 1;
    }

    DWORD flags = MPQ_FILE_EXISTS | MPQ_FILE_REPLACEEXISTING | (store ? 0 : MPQ_FILE_COMPRESS);
    if (!SFileAddFileEx(hMpq, disk, name, flags, store ? 0 : MPQ_COMPRESSION_ZLIB, MPQ_COMPRESSION_NEXT_SAME))
    {
        std::printf("add failed: %u\n", GetLastError());
        SFileCloseArchive(hMpq);
        return 1;
    }

    SFileFlushArchive(hMpq);
    SFileCloseArchive(hMpq);
    std::printf("added %s -> %s%s\n", disk, name, store ? " (stored)" : " (zlib)");
    return 0;
}

static int listFiles(const char* mpq)
{
    HANDLE hMpq = nullptr;
    if (!SFileOpenArchive(mpq, 0, 0, &hMpq))
    {
        std::printf("open failed: %u\n", GetLastError());
        return 1;
    }

    SFILE_FIND_DATA data;
    HANDLE hFind = SFileFindFirstFile(hMpq, "*", &data, nullptr);
    if (!hFind)
    {
        std::printf("empty archive or find failed: %u\n", GetLastError());
        SFileCloseArchive(hMpq);
        return 1;
    }

    int count = 0;
    do
    {
        std::printf("  %-48s size=%-10u comp=%-10u flags=0x%08X\n",
                    data.cFileName, data.dwFileSize, data.dwCompSize, data.dwFileFlags);
        ++count;
    } while (SFileFindNextFile(hFind, &data));

    SFileFindClose(hFind);
    SFileCloseArchive(hMpq);
    std::printf("files: %d\n", count);
    return 0;
}

static int hasFile(const char* mpq, const char* name)
{
    HANDLE hMpq = nullptr;
    if (!SFileOpenArchive(mpq, 0, MPQ_OPEN_READ_ONLY, &hMpq))
    {
        std::printf("open failed: %u\n", GetLastError());
        return 1;
    }
    BOOL has = SFileHasFile(hMpq, name);
    SFileCloseArchive(hMpq);
    std::printf("%s: %s\n", name, has ? "yes" : "no");
    return has ? 0 : 1;
}

static int fileSize(const char* mpq, const char* name)
{
    HANDLE hMpq = nullptr;
    if (!SFileOpenArchive(mpq, 0, MPQ_OPEN_READ_ONLY, &hMpq))
    {
        std::printf("open failed: %u\n", GetLastError());
        return 1;
    }

    HANDLE hFile = nullptr;
    if (!SFileOpenFileEx(hMpq, name, SFILE_OPEN_FROM_MPQ, &hFile))
    {
        std::printf("%s: not found\n", name);
        SFileCloseArchive(hMpq);
        return 1;
    }

    ULONGLONG size = SFileGetFileSize(hFile, nullptr);
    SFileCloseFile(hFile);
    SFileCloseArchive(hMpq);
    std::printf("%s: %llu bytes\n", name, static_cast<unsigned long long>(size));
    return 0;
}

static int readFile(const char* mpq, const char* name, const char* outPath)
{
    HANDLE hMpq = nullptr;
    if (!SFileOpenArchive(mpq, 0, MPQ_OPEN_READ_ONLY, &hMpq))
    {
        std::printf("open failed: %u\n", GetLastError());
        return 1;
    }

    HANDLE hFile = nullptr;
    if (!SFileOpenFileEx(hMpq, name, SFILE_OPEN_FROM_MPQ, &hFile))
    {
        std::printf("%s: not found\n", name);
        SFileCloseArchive(hMpq);
        return 1;
    }

    DWORD size = SFileGetFileSize(hFile, nullptr);
    std::string buffer(size, '\0');
    DWORD read = 0;
    BOOL ok = SFileReadFile(hFile, &buffer[0], size, &read, nullptr);
    SFileCloseFile(hFile);
    SFileCloseArchive(hMpq);

    if (!ok)
    {
        std::printf("read failed: %u\n", GetLastError());
        return 1;
    }

    FILE* f = std::fopen(outPath, "wb");
    if (!f)
    {
        std::printf("cannot write %s\n", outPath);
        return 1;
    }
    std::fwrite(buffer.data(), 1, read, f);
    std::fclose(f);
    std::printf("%s -> %s: %u bytes\n", name, outPath, read);
    return 0;
}

int main(int argc, char** argv)
{
    if (argc < 3)
        return usage();

    std::string cmd = argv[1];

    if (cmd == "create")
    {
        DWORD maxFiles = (argc > 3) ? static_cast<DWORD>(std::atoi(argv[3])) : 1024;
        return createArchive(argv[2], maxFiles);
    }
    if (cmd == "add" && argc >= 5)
        return addFile(argv[2], argv[3], argv[4], argc > 5 && std::strcmp(argv[5], "store") == 0);
    if (cmd == "list")
        return listFiles(argv[2]);
    if (cmd == "has" && argc >= 4)
        return hasFile(argv[2], argv[3]);
    if (cmd == "size" && argc >= 4)
        return fileSize(argv[2], argv[3]);
    if (cmd == "read" && argc >= 5)
        return readFile(argv[2], argv[3], argv[4]);

    return usage();
}

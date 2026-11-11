@echo off
rem Build mpqcli.exe - native CLI on top of StormLib.
set "VS=C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
if not exist "%VS%" goto no_vs
call "%VS%" >nul
cl /nologo /EHsc /O2 /W3 /std:c++17 /D_CRT_SECURE_NO_WARNINGS /DSTORMLIB_NO_AUTO_LINK /I "E:\tools\StormLib\src" "E:\azeroth-echo\tools\mpq\mpqcli.cpp" /Fe:"E:\azeroth-echo\tools\mpq\mpqcli.exe" /link /NODEFAULTLIB:StormLibRAS.lib "E:\tools\StormLib\build\Release\StormLib.lib" advapi32.lib user32.lib wininet.lib
if errorlevel 1 goto failed
echo built: E:\azeroth-echo\tools\mpq\mpqcli.exe
goto end
:no_vs
echo vcvars64.bat not found
exit /b 1
:failed
echo build failed
exit /b 1
:end

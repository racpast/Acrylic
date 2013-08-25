@echo off

set DST=C:\Temp

echo.
echo Cleaning...
echo.

call CleanSources.bat

echo.
echo Searching the compiler...
echo.

if exist "%PROGRAMFILES%\Delphi 10 Lite\Bin\DCC32.exe" set DCC="%PROGRAMFILES%\Delphi 10 Lite\Bin\DCC32.exe"
if exist "%PROGRAMFILES(X86)%\Delphi 10 Lite\Bin\DCC32.exe" set DCC="%PROGRAMFILES(X86)%\Delphi 10 Lite\Bin\DCC32.exe"

echo Compiler found here: %DCC%

echo.
echo Compiling Acrylic Console...
echo.

%DCC% AcrylicConsole.dpr

echo.
echo Compiling Acrylic Service...
echo.

%DCC% AcrylicService.dpr

echo.
echo Compiling Acrylic Controller...
echo.

%DCC% AcrylicController.dpr

echo.
echo Building Acrylic Setup Package...
echo.

"C:\Wintools\NSIS\makensis.exe" AcrylicSetup.nsi

echo.
echo Moving Acrylic Setup Package To "%DST%"...
echo.

move /y Acrylic.exe "%DST%"

echo.
echo Cleaning...
echo.

call CleanSources.bat

echo.
echo Building Acrylic Source Archive...
echo.

C:\Wintools\Console\7za.exe a Acrylic-Sources.zip *

echo.
echo Moving Acrylic Source Archive To "%DST%"...
echo.

move /y Acrylic-Sources.zip "%DST%"

echo.
echo Done. & pause.
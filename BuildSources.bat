@echo off

echo.
echo Cleaning...
echo.

call CleanSources.bat

echo.
echo Searching The Compiler...
echo.

if exist "%PROGRAMFILES%\Delphi 10 Lite\Bin\DCC32.exe" set DCC="%PROGRAMFILES%\Delphi 10 Lite\Bin\DCC32.exe"
if exist "%PROGRAMFILES(X86)%\Delphi 10 Lite\Bin\DCC32.exe" set DCC="%PROGRAMFILES(X86)%\Delphi 10 Lite\Bin\DCC32.exe"

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
echo Building Setup Package...
echo.

"C:\Wintools\NSIS\makensis.exe" AcrylicSetup.nsi

echo.
echo Done. & pause.
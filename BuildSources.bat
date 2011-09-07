@echo off

echo.
echo Cleaning...
echo.

call CleanSources.bat

echo.
echo Compiling Acrylic Console...
echo.

"%PROGRAMFILES%\Delphi 10 Lite\Bin\DCC32.exe" AcrylicConsole.dpr

echo.
echo Compiling Acrylic Service...
echo.

"%PROGRAMFILES%\Delphi 10 Lite\Bin\DCC32.exe" AcrylicService.dpr

echo.
echo Compiling Acrylic Controller...
echo.

"%PROGRAMFILES%\Delphi 10 Lite\Bin\DCC32.exe" AcrylicController.dpr

echo.
echo Building Setup Package...
echo.

"C:\Wintools\NSIS\makensis.exe" AcrylicSetup.nsi

echo.
echo Done. & pause.
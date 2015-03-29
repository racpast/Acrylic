@Echo Off

Set DST=C:\Temp

Echo.
Echo Cleaning...
Echo.

Call CleanSources.bat

Echo.
Echo Searching the compiler...
Echo.

If Exist "%PROGRAMFILES%\Delphi 10 Lite\Bin\DCC32.exe" Set DCC=%PROGRAMFILES%\Delphi 10 Lite\Bin\DCC32.exe
If Exist "%PROGRAMFILES(X86)%\Delphi 10 Lite\Bin\DCC32.exe" Set DCC=%PROGRAMFILES(X86)%\Delphi 10 Lite\Bin\DCC32.exe

Echo Compiler found here: %DCC%

Echo.
Echo Compiling Acrylic console...
Echo.

"%DCC%" AcrylicConsole.dpr

Echo.
Echo Compressing Acrylic console...
Echo.

C:\Wintools\Console\Upx.exe --best AcrylicConsole.exe

Echo.
Echo Compiling Acrylic service...
Echo.

"%DCC%" AcrylicService.dpr

Echo.
Echo Compressing Acrylic service...
Echo.

C:\Wintools\Console\Upx.exe --best AcrylicService.exe

Echo.
Echo Compiling Acrylic controller...
Echo.

"%DCC%" AcrylicController.dpr

Echo.
Echo Compressing Acrylic controller...
Echo.

C:\Wintools\Console\Upx.exe --best AcrylicController.exe

Echo.
Echo Building Acrylic setup package...
Echo.

"C:\Wintools\NSIS\makensis.exe" AcrylicSetup.nsi

Echo.
Echo Moving Acrylic setup package to "%DST%"...
Echo.

If Not Exist "%DST%" MkDir "%DST%" >NUL 2>NUL
If Exist "%DST%\Acrylic.exe" Del "%DST%\Acrylic.exe" >NUL 2>NUL

Move /y Acrylic.exe "%DST%"

Echo.
Echo Cleaning...
Echo.

Call CleanSources.bat

Echo.
Echo Building Acrylic source archive...
Echo.

C:\Wintools\Console\7za.exe a Acrylic-Sources.zip -xr!.git -x!.gitignore *

Echo.
Echo Moving Acrylic source archive to "%DST%"...
Echo.

If Not Exist "%DST%" MkDir "%DST%" >NUL 2>NUL
If Exist "%DST%\Acrylic-Sources.zip" Del "%DST%\Acrylic-Sources.zip" >NUL 2>NUL

Move /y Acrylic-Sources.zip "%DST%"

Echo.
Echo Done.

Pause
@Echo Off

Set DST=C:\Temp

Echo.
Echo Cleaning...
Echo.

Call CleanSources.bat

Echo.
Echo Searching the compiler...
Echo.

If Exist "%PROGRAMFILES%\Delphi7SE\Bin\DCC32.exe" Set DCC=%PROGRAMFILES%\Delphi7SE\Bin\DCC32.exe
If Exist "%PROGRAMFILES(X86)%\Delphi7SE\Bin\DCC32.exe" Set DCC=%PROGRAMFILES(X86)%\Delphi7SE\Bin\DCC32.exe

Echo Compiler found here: %DCC%

Echo.
Echo Compiling Acrylic console...
Echo.

"%DCC%" AcrylicConsole.dpr

Echo.
Echo Compiling Acrylic service...
Echo.

"%DCC%" AcrylicService.dpr

Echo.
Echo Compiling Acrylic controller...
Echo.

"%DCC%" AcrylicController.dpr

Echo.
Echo Building Acrylic portable package...
Echo.

C:\Wintools\Console\7za.exe a -tzip Acrylic-Portable.zip AcrylicHosts.txt AcrylicConfiguration.ini InstallAcrylicService.bat UninstallAcrylicService.bat AcrylicController.exe.manifest AcrylicController.exe AcrylicService.exe AcrylicConsole.exe License.txt Readme.txt

Echo.
Echo Moving Acrylic portable package to "%DST%"...
Echo.

If Not Exist "%DST%" MkDir "%DST%" >NUL 2>NUL
If Exist "%DST%\Acrylic-Portable.zip" Del "%DST%\Acrylic-Portable.zip" >NUL 2>NUL

Move /y Acrylic-Portable.zip "%DST%"

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
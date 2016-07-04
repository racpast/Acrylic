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

If ErrorLevel 1 Echo FAILED! & Pause & Exit /b 0

Echo.
Echo Compiling Acrylic service...
Echo.

"%DCC%" AcrylicService.dpr

If ErrorLevel 1 Echo FAILED! & Pause & Exit /b 0

Echo.
Echo Compiling Acrylic controller...
Echo.

"%DCC%" AcrylicController.dpr

If ErrorLevel 1 Echo FAILED! & Pause & Exit /b 0

Echo.
Echo Compiling Acrylic regex tester...
Echo.

"%DCC%" AcrylicRegExTester.dpr

If ErrorLevel 1 Echo FAILED! & Pause & Exit /b 0

Echo.
Echo Building Acrylic portable package...
Echo.

7za.exe a -tzip -mx9 Acrylic-Portable.zip AcrylicHosts.txt AcrylicConfiguration.ini AcrylicController.exe.manifest AcrylicController.exe AcrylicController.txt AcrylicService.exe AcrylicConsole.exe AcrylicConsole.txt AcrylicRegExTester.exe AcrylicRegExTester.txt License.txt Readme.txt InstallAcrylicService.bat UninstallAcrylicService.bat StartAcrylicService.bat StartAcrylicServiceSilently.bat StopAcrylicService.bat StopAcrylicServiceSilently.bat RestartAcrylicService.bat RestartAcrylicServiceSilently.bat PurgeAcrylicCacheData.bat PurgeAcrylicCacheDataSilently.bat ActivateAcrylicDebugLog.bat ActivateAcrylicDebugLogSilently.bat DeactivateAcrylicDebugLog.bat DeactivateAcrylicDebugLogSilently.bat

If ErrorLevel 1 Echo FAILED! & Pause & Exit /b 0

Echo.
Echo Moving Acrylic portable package to "%DST%"...
Echo.

If Not Exist "%DST%" MkDir "%DST%" >NUL 2>NUL
If Exist "%DST%\Acrylic-Portable.zip" Del "%DST%\Acrylic-Portable.zip" >NUL 2>NUL

Move /y Acrylic-Portable.zip "%DST%"

If ErrorLevel 1 Echo FAILED! & Pause & Exit /b 0

Echo.
Echo Building Acrylic setup package...
Echo.

"C:\Wintools\NSIS\App\NSIS\makensis.exe" AcrylicSetup.nsi

If ErrorLevel 1 Echo FAILED! & Pause & Exit /b 0

Echo.
Echo Moving Acrylic setup package to "%DST%"...
Echo.

If Not Exist "%DST%" MkDir "%DST%" >NUL 2>NUL
If Exist "%DST%\Acrylic.exe" Del "%DST%\Acrylic.exe" >NUL 2>NUL

Move /y Acrylic.exe "%DST%"

If ErrorLevel 1 Echo FAILED! & Pause & Exit /b 0

Echo.
Echo Cleaning...
Echo.

Call CleanSources.bat

Echo.
Echo Building Acrylic source archive...
Echo.

7za.exe a Acrylic-Sources.zip -xr!.git -x!.gitignore *

If ErrorLevel 1 Echo FAILED! & Pause & Exit /b 0

Echo.
Echo Moving Acrylic source archive to "%DST%"...
Echo.

If Not Exist "%DST%" MkDir "%DST%" >NUL 2>NUL
If Exist "%DST%\Acrylic-Sources.zip" Del "%DST%\Acrylic-Sources.zip" >NUL 2>NUL

Move /y Acrylic-Sources.zip "%DST%"

If ErrorLevel 1 Echo FAILED! & Pause & Exit /b 0

Echo.
Echo Done successfully.

Pause
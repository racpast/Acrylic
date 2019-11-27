@Echo Off

Set DST=C:\Temp\Acrylic-Latest
Set FPR=C:\Temp\Acrylic-Latest-ArchivesForFalsePositivesReports
Set FPP=C:\Temp\Acrylic-Latest-ArchivesForFalsePositivesReports-PasswordProtected

Echo CLEANING...

Call CleanSources.bat

Echo SEARCHING THE COMPILER...

If Exist "%PROGRAMFILES%\Delphi7SE\Bin\DCC32.exe" Set DCC=%PROGRAMFILES%\Delphi7SE\Bin\DCC32.exe
If Exist "%PROGRAMFILES(X86)%\Delphi7SE\Bin\DCC32.exe" Set DCC=%PROGRAMFILES(X86)%\Delphi7SE\Bin\DCC32.exe

Echo COMPILER FOUND HERE: %DCC%

Echo COMPILING ACRYLIC UI...

"%DCC%" AcrylicUI.dpr

If %ErrorLevel% Neq 0 Echo FAILED! & Pause & Exit /b 0

Echo COMPILING ACRYLIC TESTER...

"%DCC%" AcrylicTester.dpr

If %ErrorLevel% Neq 0 Echo FAILED! & Pause & Exit /b 0

Echo COMPILING ACRYLIC CONSOLE...

"%DCC%" AcrylicConsole.dpr

If %ErrorLevel% Neq 0 Echo FAILED! & Pause & Exit /b 0

Echo COMPILING ACRYLIC SERVICE...

"%DCC%" AcrylicService.dpr

If %ErrorLevel% Neq 0 Echo FAILED! & Pause & Exit /b 0

Echo CREATING DESTINATION DIRECTORIES...

RmDir /s /q "%DST%" >NUL 2>NUL & MkDir "%DST%" >NUL 2>NUL
RmDir /s /q "%FPR%" >NUL 2>NUL & MkDir "%FPR%" >NUL 2>NUL
RmDir /s /q "%FPP%" >NUL 2>NUL & MkDir "%FPP%" >NUL 2>NUL

Echo BUILDING ACRYLIC PORTABLE PACKAGE...

7za.exe a -tzip -mx9 "%DST%\Acrylic-Portable.zip" AcrylicConfiguration.ini AcrylicHosts.txt AcrylicService.exe AcrylicConsole.exe AcrylicUI.exe.manifest AcrylicUI.exe License.txt ReadMe.txt InstallAcrylicService.bat StartAcrylicService.bat StopAcrylicService.bat RestartAcrylicService.bat PurgeAcrylicCacheData.bat ActivateAcrylicDebugLog.bat DeactivateAcrylicDebugLog.bat OpenAcrylicConfigurationFile.bat OpenAcrylicHostsFile.bat UninstallAcrylicService.bat

If %ErrorLevel% Neq 0 Echo FAILED! & Pause & Exit /b 0

Echo BUILDING ACRYLIC FALSE POSITIVES STANDARD PACKAGE (AcrylicService.exe)...

7za.exe a -tzip -mx9 "%FPR%\AcrylicService.zip" AcrylicService.exe

If %ErrorLevel% Neq 0 Echo FAILED! & Pause & Exit /b 0

Echo BUILDING ACRYLIC FALSE POSITIVES PASSWORD PROTECTED PACKAGE (AcrylicService.exe)...

7za.exe a -tzip -mx9 -pinfected "%FPP%\AcrylicService.zip" AcrylicService.exe

If %ErrorLevel% Neq 0 Echo FAILED! & Pause & Exit /b 0

Echo BUILDING ACRYLIC FALSE POSITIVES STANDARD PACKAGE (AcrylicConsole.exe)...

7za.exe a -tzip -mx9 "%FPR%\AcrylicConsole.zip" AcrylicConsole.exe

If %ErrorLevel% Neq 0 Echo FAILED! & Pause & Exit /b 0

Echo BUILDING ACRYLIC FALSE POSITIVES PASSWORD PROTECTED PACKAGE (AcrylicConsole.exe)...

7za.exe a -tzip -mx9 -pinfected "%FPP%\AcrylicConsole.zip" AcrylicConsole.exe

If %ErrorLevel% Neq 0 Echo FAILED! & Pause & Exit /b 0

Echo BUILDING ACRYLIC FALSE POSITIVES STANDARD PACKAGE (AcrylicUI.exe)...

7za.exe a -tzip -mx9 "%FPR%\AcrylicUI.zip" AcrylicUI.exe

If %ErrorLevel% Neq 0 Echo FAILED! & Pause & Exit /b 0

Echo BUILDING ACRYLIC FALSE POSITIVES PASSWORD PROTECTED PACKAGE (AcrylicUI.exe)...

7za.exe a -tzip -mx9 -pinfected "%FPP%\AcrylicUI.zip" AcrylicUI.exe

If %ErrorLevel% Neq 0 Echo FAILED! & Pause & Exit /b 0

Echo BUILDING ACRYLIC SETUP PACKAGE...

"C:\Wintools\NSIS\App\NSIS\makensis.exe" AcrylicSetup.nsi

If %ErrorLevel% Neq 0 Echo FAILED! & Pause & Exit /b 0

Echo BUILDING ACRYLIC FALSE POSITIVES STANDARD PACKAGE (Acrylic.exe)...

7za.exe a -tzip -mx9 "%FPR%\Acrylic.zip" Acrylic.exe

If %ErrorLevel% Neq 0 Echo FAILED! & Pause & Exit /b 0

Echo BUILDING ACRYLIC FALSE POSITIVES PASSWORD PROTECTED PACKAGE (Acrylic.exe)...

7za.exe a -tzip -mx9 -pinfected "%FPP%\Acrylic.zip" Acrylic.exe

If %ErrorLevel% Neq 0 Echo FAILED! & Pause & Exit /b 0

Echo MOVING ACRYLIC SETUP PACKAGE TO "%DST%"...

Move /y Acrylic.exe "%DST%"

If %ErrorLevel% Neq 0 Echo FAILED! & Pause & Exit /b 0

Echo CLEANING...

Call CleanSources.bat

Echo BUILDING ACRYLIC SOURCE ARCHIVE...

7za.exe a -tzip -mx9 "%DST%\Acrylic-Sources.zip" -xr!.git -x!.gitignore *

If %ErrorLevel% Neq 0 Echo FAILED! & Pause & Exit /b 0

Echo PRINTING FILE HASHES...

Call GetFiles.bat "%DST%\*.*" | Call HashFiles.bat SHA256

Echo DONE SUCCESSFULLY.
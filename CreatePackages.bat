@Echo Off

Set DestinationDirectory=%TEMP%\Acrylic-Latest

Echo CREATING DESTINATION DIRECTORY...

RmDir /s /q "%DestinationDirectory%" >NUL 2>NUL & MkDir "%DestinationDirectory%" >NUL 2>NUL

Echo BUILDING ACRYLIC PORTABLE PACKAGE...

7za.exe a -tzip -mx9 "%DestinationDirectory%\Acrylic-Portable.zip" AcrylicConfiguration.ini AcrylicHosts.txt AcrylicService.exe AcrylicConsole.exe AcrylicUI.exe.manifest AcrylicUI.exe License.txt ReadMe.txt InstallAcrylicService.bat StartAcrylicService.bat StopAcrylicService.bat RestartAcrylicService.bat PurgeAcrylicCacheData.bat ActivateAcrylicDebugLog.bat DeactivateAcrylicDebugLog.bat OpenAcrylicConfigurationFile.bat OpenAcrylicHostsFile.bat UninstallAcrylicService.bat

If %ErrorLevel% Neq 0 Echo FAILED! & Pause & Exit /b 0

Echo BUILDING ACRYLIC SETUP PACKAGE...

"C:\Wintools\NSIS\App\NSIS\makensis.exe" AcrylicSetup.nsi

If %ErrorLevel% Neq 0 Echo FAILED! & Pause & Exit /b 0

Echo MOVING ACRYLIC SETUP PACKAGE TO "%DestinationDirectory%"...

Move /y Acrylic.exe "%DestinationDirectory%"

If %ErrorLevel% Neq 0 Echo FAILED! & Pause & Exit /b 0

Echo CLEANING...

Call CleanSources.bat

Echo BUILDING ACRYLIC SOURCE ARCHIVE...

7za.exe a -tzip -mx9 "%DestinationDirectory%\Acrylic-Sources.zip" -xr!.git -x!.gitignore *

If %ErrorLevel% Neq 0 Echo FAILED! & Pause & Exit /b 0

Echo PRINTING SHA256 FILE HASHES...

Call GetFiles.bat "%DestinationDirectory%\*.*" | Call HashFiles.bat SHA256

Echo DONE SUCCESSFULLY.
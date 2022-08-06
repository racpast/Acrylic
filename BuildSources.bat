@Echo Off

Echo CLEANING...

Call CleanSources.bat

Echo SEARCHING THE COMPILER...

If Exist "C:\Delphi7SE\Bin\DCC32.exe" Set DCC=C:\Delphi7SE\Bin\DCC32.exe
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

Echo DONE SUCCESSFULLY.
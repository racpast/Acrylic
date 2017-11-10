@Echo Off

Del Acrylic.exe >NUL 2>NUL

Del AcrylicRegExTester.exe >NUL 2>NUL
Del AcrylicController.exe >NUL 2>NUL
Del AcrylicConsole.exe >NUL 2>NUL
Del AcrylicService.exe >NUL 2>NUL
Del AcrylicTester.exe >NUL 2>NUL

Del /q *.dcu >NUL 2>NUL
Del /q *.ddp >NUL 2>NUL
Del /q *.dsk >NUL 2>NUL

Del /q *.~ddp >NUL 2>NUL
Del /q *.~dfm >NUL 2>NUL
Del /q *.~dpr >NUL 2>NUL
Del /q *.~pas >NUL 2>NUL

Del AcrylicCache.dat >NUL 2>NUL
Del AcrylicDebug.txt >NUL 2>NUL
Del AcrylicStats.txt >NUL 2>NUL

Del /q *.tmp >NUL 2>NUL

CsRun.exe SelectFiles *.dpr | Call CleanupCodeWindowsNewLinesTab2SpacesStdIn.bat
CsRun.exe SelectFiles *.pas | Call CleanupCodeWindowsNewLinesTab2SpacesStdIn.bat
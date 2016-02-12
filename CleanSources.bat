@Echo Off

Del Acrylic.exe >NUL 2>NUL
Del Acrylic-Sources.zip >NUL 2>NUL

Del AcrylicController.exe >NUL 2>NUL
Del AcrylicConsole.exe >NUL 2>NUL
Del AcrylicService.exe >NUL 2>NUL
Del AcrylicTest.exe >NUL 2>NUL

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

CsRun.exe SelectFiles *.dpr False | Call CleanupCodeWindowsNewLinesTab2SpacesStdIn.bat
CsRun.exe SelectFiles *.pas False | Call CleanupCodeWindowsNewLinesTab2SpacesStdIn.bat
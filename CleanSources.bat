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

Del AcrylicDebug.txt >NUL 2>NUL
Del AcrylicStats.txt >NUL 2>NUL

C:\Wintools\Console\CsRun.exe SelectFiles *.bat;*.dpr;*.ini;*.nsi;*.pas False | Call C:\Wintools\Console\AdjustGenericWindowsCodeStdIn.bat
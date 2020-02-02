@Echo Off

ECHO CLEANING ARTIFACTS...

Del Acrylic.exe >NUL 2>NUL

Del AcrylicConsole.exe >NUL 2>NUL
Del AcrylicService.exe >NUL 2>NUL

Del AcrylicCache.dat >NUL 2>NUL
Del AcrylicDebug.txt >NUL 2>NUL

Del AcrylicUI.exe >NUL 2>NUL
Del AcrylicUI.ini >NUL 2>NUL

Del AcrylicTester.exe >NUL 2>NUL

Del /q *.~ddp >NUL 2>NUL
Del /q *.~dfm >NUL 2>NUL
Del /q *.~dpr >NUL 2>NUL
Del /q *.~pas >NUL 2>NUL

Del /q *.dcu >NUL 2>NUL
Del /q *.ddp >NUL 2>NUL
Del /q *.dsk >NUL 2>NUL
Del /q *.map >NUL 2>NUL
Del /q *.tmp >NUL 2>NUL

ECHO CLEANING CODE FILES...

Call GetFiles.bat "*.dpr|*.pas" | Call CleanupCodeFilesWindowsNewlinesTab2Spaces.bat

ECHO CLEANING TEXT FILES...

Call WrapText.bat 120 < ReadMe.Template.txt > ReadMe.txt

Call WrapText.bat 120 "; " < AcrylicConfiguration.Template.ini > AcrylicConfiguration.ini
Call WrapText.bat 120 "# " < AcrylicHosts.Template.txt > AcrylicHosts.txt

Call WrapText.bat 80 < License.Template.txt > License.txt
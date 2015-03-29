@Echo Off

RmDir /s /q __History

Del Acrylic.exe
Del Acrylic-Sources.zip

Del /q *.bdsproj.local
Del /q *.dat
Del /q *.dcu
Del /q *.ddp
Del /q *.dsk
Del /q *.exe
Del /q *.tmp

Del /q *.~ddp
Del /q *.~dfm
Del /q *.~dpr
Del /q *.~pas

Del AcrylicDebug.txt
Del AcrylicStats.txt

Rem Normalize new lines (Windows); tab to spaces; trim end; trim top; trim bottom; remove consecutive empty lines
C:\Wintools\Console\CsRun.exe SelectFiles *.bat;*.dpr;*.ini;*.nsi;*.pas False | C:\Wintools\Console\CsRun.exe RegexReplaceAllText "/(^|[^\r])\n/s" "$1\r\n" | C:\Wintools\Console\CsRun.exe RegexReplaceAllText "/\r([^\n]|$)/s" "\r\n$1" | C:\Wintools\Console\CsRun.exe RegexReplaceAllText "/\t/s" "    " | C:\Wintools\Console\CsRun.exe RegexReplaceAllText "/ +(\r\n|$)/s" "$1" | C:\Wintools\Console\CsRun.exe RegexReplaceAllText "/^(\r\n)+/s" "" | C:\Wintools\Console\CsRun.exe RegexReplaceAllText "/(\r\n)+$/s" "" | C:\Wintools\Console\CsRun.exe RegexReplaceAllText "/\r\n\r\n(\r\n)+$/s" "\r\n\r\n" >NUL
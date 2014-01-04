@echo off
set SD=%CD%

rmdir /s /q __History

del Acrylic.exe
del Acrylic-Sources.zip

del /q *.dcu
del /q *.dsk
del /q *.~pas
del /q *.~dpr
del /q *.~ddp
del /q *.~dfm
del /q *.bdsproj.local
del /q *.dat
del /q *.exe
del /q *.tmp

del AcrylicDebug.txt
del AcrylicStats.txt

C:\Wintools\Perl32\bin\perl.exe CleanSources.pl
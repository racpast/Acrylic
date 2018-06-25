;--------------------------------
; Include Modern UI
;--------------------------------

!include "MUI.nsh"

;--------------------------------
; General
;--------------------------------

; Name
Name "Acrylic DNS Proxy (0.9.39)"

; Output
OutFile "Acrylic.exe"

; Compressor
SetCompressor "lzma"

; Default installation folder
InstallDir "$PROGRAMFILES\Acrylic DNS Proxy"

; Request administrative rights
RequestExecutionLevel admin

;--------------------------------
; Interface Settings
;--------------------------------

!define MUI_ABORTWARNING

;--------------------------------
; Pages
;--------------------------------

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "License.txt"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

!define MUI_FINISHPAGE_TEXT "Please browse the online documentation from the Acrylic Start Menu for further informations about Acrylic configuration and startup options."
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;--------------------------------
; Languages
;--------------------------------

!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Installer Sections
;--------------------------------

Section "Acrylic" SecMain

  SetShellVarContext all

  SectionIn RO
  SetOutPath "$INSTDIR"

  File "AcrylicConfiguration.ini"
  File "AcrylicHosts.txt"
  File "AcrylicService.exe"
  File "AcrylicConsole.exe"
  File "AcrylicUI.exe.manifest"
  File "AcrylicUI.exe"
  File "License.txt"
  File "ReadMe.txt"

  File "InstallAcrylicService.bat"
  File "StartAcrylicService.bat"
  File "StopAcrylicService.bat"
  File "RestartAcrylicService.bat"
  File "PurgeAcrylicCacheData.bat"
  File "ActivateAcrylicDebugLog.bat"
  File "DeactivateAcrylicDebugLog.bat"
  File "UninstallAcrylicService.bat"

  WriteUninstaller "$INSTDIR\Uninstall.exe"

  CreateDirectory "$SMPROGRAMS\Acrylic DNS Proxy"

  CreateShortCut  "$SMPROGRAMS\Acrylic DNS Proxy\Acrylic Home Page.lnk" "https://mayakron.altervista.org/acrylic.php"
  CreateShortCut  "$SMPROGRAMS\Acrylic DNS Proxy\Acrylic UI.lnk" "$INSTDIR\AcrylicUI.exe"
  CreateShortCut  "$SMPROGRAMS\Acrylic DNS Proxy\Uninstall.lnk" "$INSTDIR\Uninstall.exe"

  ExecWait "$INSTDIR\AcrylicUI.exe InstallAcrylicService"

SectionEnd

;--------------------------------
; Uninstaller Section
;--------------------------------

Section "Uninstall"

  SetShellVarContext all

  ExecWait "$INSTDIR\AcrylicUI.exe UninstallAcrylicService"

  Delete "$SMPROGRAMS\Acrylic DNS Proxy\Acrylic Home Page.lnk"
  Delete "$SMPROGRAMS\Acrylic DNS Proxy\Acrylic UI.lnk"
  Delete "$SMPROGRAMS\Acrylic DNS Proxy\Uninstall.lnk"

  RmDir  "$SMPROGRAMS\Acrylic DNS Proxy"

  Delete "$INSTDIR\AcrylicConfiguration.ini"
  Delete "$INSTDIR\AcrylicHosts.txt"
  Delete "$INSTDIR\AcrylicService.exe"
  Delete "$INSTDIR\AcrylicConsole.exe"
  Delete "$INSTDIR\AcrylicUI.exe.manifest"
  Delete "$INSTDIR\AcrylicUI.exe"
  Delete "$INSTDIR\AcrylicUI.ini"
  Delete "$INSTDIR\License.txt"
  Delete "$INSTDIR\ReadMe.txt"

  Delete "$INSTDIR\InstallAcrylicService.bat"
  Delete "$INSTDIR\StartAcrylicService.bat"
  Delete "$INSTDIR\StopAcrylicService.bat"
  Delete "$INSTDIR\RestartAcrylicService.bat"
  Delete "$INSTDIR\PurgeAcrylicCacheData.bat"
  Delete "$INSTDIR\ActivateAcrylicDebugLog.bat"
  Delete "$INSTDIR\DeactivateAcrylicDebugLog.bat"
  Delete "$INSTDIR\UninstallAcrylicService.bat"

  Delete "$INSTDIR\AcrylicCache.dat"
  Delete "$INSTDIR\AcrylicDebug.txt"
  Delete "$INSTDIR\AcrylicStats.txt"

  Delete "$INSTDIR\Uninstall.exe"

  RmDir  "$INSTDIR"

SectionEnd
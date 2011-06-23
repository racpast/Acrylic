;--------------------------------
; Include Modern UI
;--------------------------------

!include "MUI.nsh"

;--------------------------------
; General
;--------------------------------

; Name
Name "Acrylic DNS Proxy (0.9.18)"

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

!define MUI_FINISHPAGE_TEXT "Please browse the online documentation from the Support section of the Acrylic Start Menu folder for further informations about Acrylic configuration and startup options."
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

  File "AcrylicHosts.txt"
  File "AcrylicConfiguration.ini"
  File "AcrylicController.exe.manifest"
  File "AcrylicController.exe"
  File "AcrylicService.exe"
  File "AcrylicConsole.exe"

  WriteUninstaller "$INSTDIR\Uninstall.exe"

  CreateDirectory "$SMPROGRAMS\Acrylic DNS Proxy"

  CreateDirectory "$SMPROGRAMS\Acrylic DNS Proxy\Config"
  CreateDirectory "$SMPROGRAMS\Acrylic DNS Proxy\Support"
  CreateDirectory "$SMPROGRAMS\Acrylic DNS Proxy\Support\Advanced Support Tools"
  CreateDirectory "$SMPROGRAMS\Acrylic DNS Proxy\Uninstall"

  CreateShortCut  "$SMPROGRAMS\Acrylic DNS Proxy\Config\Edit Configuration File.lnk" "$INSTDIR\AcrylicController.exe" "EditAcrylicConfigurationFile"
  CreateShortCut  "$SMPROGRAMS\Acrylic DNS Proxy\Config\Edit Custom Hosts File.lnk" "$INSTDIR\AcrylicController.exe" "EditAcrylicHostsFile"
  CreateShortCut  "$SMPROGRAMS\Acrylic DNS Proxy\Config\Purge Acrylic Cache Data.lnk" "$INSTDIR\AcrylicController.exe" "PurgeAcrylicCache"
  CreateShortCut  "$SMPROGRAMS\Acrylic DNS Proxy\Config\Restart Acrylic Service.lnk" "$INSTDIR\AcrylicController.exe" "StartAcrylicService"
  CreateShortCut  "$SMPROGRAMS\Acrylic DNS Proxy\Config\Stop Acrylic Service.lnk" "$INSTDIR\AcrylicController.exe" "StopAcrylicService"

  CreateShortCut  "$SMPROGRAMS\Acrylic DNS Proxy\Support\About Acrylic.lnk" "$INSTDIR\AcrylicController.exe" "AboutAcrylic"
  CreateShortCut  "$SMPROGRAMS\Acrylic DNS Proxy\Support\Acrylic Home Page.lnk" "http://mayakron.altervista.org/support/browse.php?path=Acrylic&name=Home"
  CreateShortCut  "$SMPROGRAMS\Acrylic DNS Proxy\Support\Contact Acrylic Support.lnk" "mailto:msmfbn@gmail.com?subject=Acrylic DNS Proxy Support Request"

  CreateShortCut  "$SMPROGRAMS\Acrylic DNS Proxy\Support\Advanced Support Tools\Browse Debug Log.lnk" "$INSTDIR\AcrylicController.exe" "BrowseAcrylicDebugLog"
  CreateShortCut  "$SMPROGRAMS\Acrylic DNS Proxy\Support\Advanced Support Tools\Enable Disable Debug Log.lnk" "$INSTDIR\AcrylicController.exe" "EnableDisableAcrylicDebugLog"
  CreateShortCut  "$SMPROGRAMS\Acrylic DNS Proxy\Support\Advanced Support Tools\Run Acrylic Console Version.lnk" "$INSTDIR\AcrylicConsole.exe"

  CreateShortCut  "$SMPROGRAMS\Acrylic DNS Proxy\Uninstall\Uninstall.lnk" "$INSTDIR\Uninstall.exe"

  ExecWait "$INSTDIR\AcrylicService.exe /INSTALL /SILENT"

SectionEnd

;--------------------------------
; Uninstaller Section
;--------------------------------

Section "Uninstall"

  SetShellVarContext all

  ExecWait "$INSTDIR\AcrylicController.exe UninstallAcrylicService"

  Delete "$SMPROGRAMS\Acrylic DNS Proxy\Config\Edit Configuration File.lnk"
  Delete "$SMPROGRAMS\Acrylic DNS Proxy\Config\Edit Custom Hosts File.lnk"
  Delete "$SMPROGRAMS\Acrylic DNS Proxy\Config\Purge Acrylic Cache Data.lnk"
  Delete "$SMPROGRAMS\Acrylic DNS Proxy\Config\Restart Acrylic Service.lnk"
  Delete "$SMPROGRAMS\Acrylic DNS Proxy\Config\Stop Acrylic Service.lnk"

  Delete "$SMPROGRAMS\Acrylic DNS Proxy\Support\About Acrylic.lnk"
  Delete "$SMPROGRAMS\Acrylic DNS Proxy\Support\Acrylic Home Page.lnk"
  Delete "$SMPROGRAMS\Acrylic DNS Proxy\Support\Contact Acrylic Support.lnk"

  Delete "$SMPROGRAMS\Acrylic DNS Proxy\Support\Advanced Support Tools\Browse Debug Log.lnk"
  Delete "$SMPROGRAMS\Acrylic DNS Proxy\Support\Advanced Support Tools\Enable Disable Debug Log.lnk"
  Delete "$SMPROGRAMS\Acrylic DNS Proxy\Support\Advanced Support Tools\Run Acrylic Console Version.lnk"

  Delete "$SMPROGRAMS\Acrylic DNS Proxy\Uninstall\Uninstall.lnk"

  RmDir  "$SMPROGRAMS\Acrylic DNS Proxy\Uninstall"
  RmDir  "$SMPROGRAMS\Acrylic DNS Proxy\Support\Advanced Support Tools"
  RmDir  "$SMPROGRAMS\Acrylic DNS Proxy\Support"
  RmDir  "$SMPROGRAMS\Acrylic DNS Proxy\Config"

  RmDir  "$SMPROGRAMS\Acrylic DNS Proxy"

  Delete "$INSTDIR\AcrylicCache.dat"
  Delete "$INSTDIR\AcrylicDebug.txt"
  Delete "$INSTDIR\AcrylicStats.txt"

  Delete "$INSTDIR\AcrylicConsole.exe"
  Delete "$INSTDIR\AcrylicService.exe"
  Delete "$INSTDIR\AcrylicController.exe"
  Delete "$INSTDIR\AcrylicController.exe.manifest"
  Delete "$INSTDIR\AcrylicConfiguration.ini"
  Delete "$INSTDIR\AcrylicHosts.txt"

  Delete "$INSTDIR\Uninstall.exe"

  RmDir  "$INSTDIR"

SectionEnd

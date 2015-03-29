// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

program
  AcrylicController;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SysUtils, Windows, AcrylicVersionInfo in 'AcrylicVersionInfo.pas';

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function CmdExec(CmdLine: String): Cardinal;
var
  StartupInfo: TStartupInfo; ProcessInfo: TProcessInformation; ExitCode: Cardinal;
begin
  FillChar(StartupInfo, Sizeof(StartupInfo), #0); StartupInfo.cb := Sizeof(StartupInfo); if CreateProcess(nil, PChar(CmdLine), nil, nil, false, CREATE_NO_WINDOW or NORMAL_PRIORITY_CLASS, nil, nil, StartupInfo, ProcessInfo) then begin
    WaitForSingleObject(ProcessInfo.hProcess, INFINITE); GetExitCodeProcess(ProcessInfo.hProcess, ExitCode); CloseHandle(ProcessInfo.hProcess); CloseHandle(ProcessInfo.hThread);
  end else ExitCode := 255; Result := ExitCode;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function MakeAbsolutePath(Path: String): String;
begin
  if (Pos('\', Path) > 0) then Result := Path else Result := ExtractFilePath(ParamStr(0)) + Path;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function CreateEmptyFile(FileName: String): Boolean;
var
  Handle: THandle;
begin
  Handle := CreateFile(PChar(FileName), GENERIC_WRITE, 0, nil, CREATE_NEW, FILE_ATTRIBUTE_ARCHIVE, 0); if (Handle <> INVALID_HANDLE_VALUE) then begin
    CloseHandle(Handle); Result := True;
  end else Result := False;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

begin
  if (ParamCount > 0) then begin

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'AboutAcrylic') then begin

        MessageBox(0, 'Acrylic is a local DNS proxy which improves the performance of your computer and helps you fight unwanted ads by actively caching the responses coming from your DNS servers.' + #13#10 + #13#10 + 'For more informations please use the "Acrylic Home Page" shortcut available from the "Start Menu".' + #13#10 + #13#10 + 'Installed version is:' + #13#10 + AcrylicVersionInfo.Number + ' released on ' + AcrylicVersionInfo.ReleaseDate + '.', 'About Acrylic DNS Proxy', MB_ICONINFORMATION or MB_OK);

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'InstallAcrylicService') then begin

      CmdExec('"' + MakeAbsolutePath('AcrylicService.exe') + '" /INSTALL /SILENT');
      CmdExec('Net.exe Start "Acrylic DNS Proxy Service"');

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'UninstallAcrylicService') then begin

      CmdExec('Net.exe Stop "Acrylic DNS Proxy Service"');
      CmdExec('"' + MakeAbsolutePath('AcrylicService.exe') + '" /UNINSTALL /SILENT');

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'PurgeAcrylicCacheData') then begin

      CmdExec('Net.exe Stop "Acrylic DNS Proxy Service"');
      DeleteFile(PChar(MakeAbsolutePath('AcrylicCache.dat')));

      if (MessageBox(0, 'The Acrylic DNS Proxy cache has been purged successfully. You should restart the Acrylic DNS Proxy service.' + #13#10 + #13#10 + 'Do you want to do it now?', 'Information', MB_ICONINFORMATION or MB_YESNO) = IDYES) then begin
        if (CmdExec('Net.exe Start "Acrylic DNS Proxy Service"') = 0) then MessageBox(0, 'The Acrylic DNS Proxy service has been started successfully.', 'Information', MB_ICONINFORMATION or MB_OK) else MessageBox(0, 'An error occurred while starting the Acrylic DNS Proxy service.', 'Error', MB_ICONSTOP or MB_OK);
      end;

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'PurgeAcrylicCacheDataSilently') then begin

      CmdExec('Net.exe Stop "Acrylic DNS Proxy Service"');
      DeleteFile(PChar(MakeAbsolutePath('AcrylicCache.dat')));
      CmdExec('Net.exe Start "Acrylic DNS Proxy Service"');

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'StartAcrylicService') then begin

      CmdExec('Net.exe Stop "Acrylic DNS Proxy Service"');
      if (CmdExec('Net.exe Start "Acrylic DNS Proxy Service"') = 0) then MessageBox(0, 'The Acrylic DNS Proxy service has been started successfully.', 'Information', MB_ICONINFORMATION or MB_OK) else MessageBox(0, 'An error occurred while starting the Acrylic DNS Proxy service.', 'Error', MB_ICONSTOP or MB_OK);

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'StartAcrylicServiceSilently') then begin

      CmdExec('Net.exe Stop "Acrylic DNS Proxy Service"');
      CmdExec('Net.exe Start "Acrylic DNS Proxy Service"');

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'StopAcrylicService') then begin

      if (CmdExec('Net.exe Stop "Acrylic DNS Proxy Service"') = 0) then MessageBox(0, 'The Acrylic DNS Proxy service has been stopped successfully.', 'Information', MB_ICONINFORMATION or MB_OK) else MessageBox(0, 'An error occurred while stopping the Acrylic DNS Proxy service.', 'Error', MB_ICONSTOP or MB_OK);

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'StopAcrylicServiceSilently') then begin

      CmdExec('Net.exe Stop "Acrylic DNS Proxy Service"');

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'EditAcrylicHostsFile') then begin

      WinExec(PChar('Notepad.exe "' + MakeAbsolutePath('AcrylicHosts.txt') + '"'), SW_NORMAL);

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'EditAcrylicConfigurationFile') then begin

      WinExec(PChar('Notepad.exe "' + MakeAbsolutePath('AcrylicConfiguration.ini') + '"'), SW_NORMAL);

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'ActivateAcrylicDebugLog') then begin

      if Not FileExists(MakeAbsolutePath('AcrylicDebug.txt')) then begin

        CmdExec('Net.exe Stop "Acrylic DNS Proxy Service"');
        CreateEmptyFile(MakeAbsolutePath('AcrylicDebug.txt'));

        if (MessageBox(0, 'The Acrylic DNS Proxy debug log has been enabled successfully. You should now restart the Acrylic DNS Proxy service.' + #13#10 + #13#10 + 'Do you want to do it now?', 'Information', MB_ICONINFORMATION or MB_YESNO) = IDYES) then begin
          if (CmdExec('Net.exe Start "Acrylic DNS Proxy Service"') = 0) then MessageBox(0, 'The Acrylic DNS Proxy service has been started successfully.', 'Information', MB_ICONINFORMATION or MB_OK) else MessageBox(0, 'An error occurred while starting the Acrylic DNS Proxy service.', 'Error', MB_ICONSTOP or MB_OK);
        end;

      end else begin
        MessageBox(0, 'The Acrylic DNS Proxy debug log is already activated.', 'Information', MB_ICONINFORMATION or MB_OK);
      end;

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'ActivateAcrylicDebugLogSilently') then begin

      if Not FileExists(MakeAbsolutePath('AcrylicDebug.txt')) then begin

        CmdExec('Net.exe Stop "Acrylic DNS Proxy Service"');
        CreateEmptyFile(MakeAbsolutePath('AcrylicDebug.txt'));
        CmdExec('Net.exe Start "Acrylic DNS Proxy Service"');

      end;

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'DeactivateAcrylicDebugLog') then begin

      if FileExists(MakeAbsolutePath('AcrylicDebug.txt')) then begin

        CmdExec('Net.exe Stop "Acrylic DNS Proxy Service"');
        DeleteFile(PChar(MakeAbsolutePath('AcrylicDebug.txt')));

        if (MessageBox(0, 'The Acrylic DNS Proxy debug log has been disabled successfully. You should now restart the Acrylic DNS Proxy service.' + #13#10 + #13#10 + 'Do you want to do it now?', 'Information', MB_ICONINFORMATION or MB_YESNO) = IDYES) then begin
          if (CmdExec('Net.exe Start "Acrylic DNS Proxy Service"') = 0) then MessageBox(0, 'The Acrylic DNS Proxy service has been started successfully.', 'Information', MB_ICONINFORMATION or MB_OK) else MessageBox(0, 'An error occurred while starting the Acrylic DNS Proxy service.', 'Error', MB_ICONSTOP or MB_OK);
        end;

      end else begin
        MessageBox(0, 'The Acrylic DNS Proxy debug log is already deactivated.', 'Information', MB_ICONINFORMATION or MB_OK);
      end;

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'DeactivateAcrylicDebugLogSilently') then begin

      if FileExists(MakeAbsolutePath('AcrylicDebug.txt')) then begin

        CmdExec('Net.exe Stop "Acrylic DNS Proxy Service"');
        DeleteFile(PChar(MakeAbsolutePath('AcrylicDebug.txt')));
        CmdExec('Net.exe Start "Acrylic DNS Proxy Service"');

      end;

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'OpenCurrentAcrylicDebugLog') then begin

      if FileExists(MakeAbsolutePath('AcrylicDebug.txt')) then begin
        WinExec(PChar('Notepad.exe "' + MakeAbsolutePath('AcrylicDebug.txt') + '"'), SW_NORMAL);
      end else begin
        MessageBox(0, 'The Acrylic DNS Proxy debug log is currently deactivated.', 'Information', MB_ICONINFORMATION or MB_OK);
      end;

    end;

    // ----------------------------------------------------------------------

  end;
end.

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------
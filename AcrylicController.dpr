// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

program
  AcrylicController;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SysUtils, Windows;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function CmdExec(CmdLine: String): Cardinal;
var
  StartupInfo: TStartupInfo; ProcessInfo: TProcessInformation; ExitCode: Cardinal;
begin
  FillChar(StartupInfo, Sizeof(StartupInfo), #0); StartupInfo.cb := Sizeof(StartupInfo); if CreateProcess(nil, PChar(CmdLine), nil, nil, false, CREATE_NO_WINDOW or NORMAL_PRIORITY_CLASS, nil, nil, StartupInfo, ProcessInfo) then begin
    WaitForSingleObject(ProcessInfo.hProcess, INFINITE); GetExitCodeProcess(ProcessInfo.hProcess, ExitCode); CloseHandle(ProcessInfo.hProcess); CloseHandle(ProcessInfo.hThread);
  end else ExitCode := 4294967295; Result := ExitCode;
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

        // Show an about dialog
        MessageBox(0, 'Acrylic is a local DNS proxy which improves the performance of your computer and helps you fight unwanted ads by actively caching the responses coming from your DNS servers.' + #13#10 + #13#10 + 'For more informations please use the "Acrylic Home Page" shortcut available from the "Start Menu".' + #13#10 + #13#10 + 'Installed version is:' + #13#10 + '0.9.22 released on January 28th, 2013.', 'About Acrylic DNS Proxy', MB_ICONINFORMATION or MB_OK);

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'PurgeAcrylicCache') then begin

      // We want to stop the service first
      CmdExec('Net.exe Stop "Acrylic DNS Proxy Service"');

      // We delete the AcrylicCache.dat file
      DeleteFile(PChar('AcrylicCache.dat'));

      // We tell the user that everything went fine
      if (MessageBox(0, 'The Acrylic DNS Proxy cache has been purged successfully. You should now restart the Acrylic DNS Proxy service.' + #13#10 + #13#10 + 'Do you want to do it now?', 'Information', MB_ICONINFORMATION or MB_YESNO) = IDYES) then begin

        // We want to start the Acrylic service finally
        if (CmdExec('Net.exe Start "Acrylic DNS Proxy Service"') = 0) then MessageBox(0, 'The Acrylic DNS Proxy service has been started successfully.', 'Information', MB_ICONINFORMATION or MB_OK) else MessageBox(0, 'An error occurred while starting the Acrylic DNS Proxy service.', 'Error', MB_ICONSTOP or MB_OK);

      end;

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'StartAcrylicService') then begin

      // We want to stop the Acrylic service first
      CmdExec('Net.exe Stop "Acrylic DNS Proxy Service"');

      // We want to start the Acrylic service finally
      if (CmdExec('Net.exe Start "Acrylic DNS Proxy Service"') = 0) then MessageBox(0, 'The Acrylic DNS Proxy service has been started successfully.', 'Information', MB_ICONINFORMATION or MB_OK) else MessageBox(0, 'An error occurred while starting the Acrylic DNS Proxy service.', 'Error', MB_ICONSTOP or MB_OK);

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'StopAcrylicService') then begin

      // We want to stop the Acrylic service
      if (CmdExec('Net.exe Stop "Acrylic DNS Proxy Service"') = 0) then MessageBox(0, 'The Acrylic DNS Proxy service has been stopped successfully.', 'Information', MB_ICONINFORMATION or MB_OK) else MessageBox(0, 'An error occurred while stopping the Acrylic DNS Proxy service.', 'Error', MB_ICONSTOP or MB_OK);

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'EditAcrylicHostsFile') then begin

      // We want to edit the file using Notepad
      WinExec(PChar('Notepad.exe AcrylicHosts.txt'), SW_NORMAL);

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'EditAcrylicConfigurationFile') then begin

      // We want to edit the file using Notepad
      WinExec(PChar('Notepad.exe AcrylicConfiguration.ini'), SW_NORMAL);

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'BrowseAcrylicDebugLog') then begin

      if FileExists('AcrylicDebug.txt') then begin // If the Acrylic debug log is enabled

        // We want to browse the file using Notepad
        WinExec(PChar('Notepad.exe AcrylicDebug.txt'), SW_NORMAL);

      end else begin

        // We tell the user that the Acrylic debug log is disabled
        MessageBox(0, 'The Acrylic DNS Proxy debug log is currently disabled.', 'Information', MB_ICONINFORMATION or MB_OK);

      end;

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'EnableDisableAcrylicDebugLog') then begin

      if not(FileExists('AcrylicDebug.txt')) then begin // If the Acrylic debug log is not already enabled

        // We want to stop Acrylic first
        CmdExec('Net.exe Stop "Acrylic DNS Proxy Service"');

        // We enable the Acrylic debug log
        CreateEmptyFile('AcrylicDebug.txt');

        // We tell the user that everything went fine
        if (MessageBox(0, 'The Acrylic DNS Proxy debug log has been enabled successfully. You should now restart the Acrylic DNS Proxy service.' + #13#10 + #13#10 + 'Do you want to do it now?', 'Information', MB_ICONINFORMATION or MB_YESNO) = IDYES) then begin

          // We want to start the Acrylic service finally
          if (CmdExec('Net.exe Start "Acrylic DNS Proxy Service"') = 0) then MessageBox(0, 'The Acrylic DNS Proxy service has been started successfully.', 'Information', MB_ICONINFORMATION or MB_OK) else MessageBox(0, 'An error occurred while starting the Acrylic DNS Proxy service.', 'Error', MB_ICONSTOP or MB_OK);

        end;

      end else begin // The Acrylic debug log is already enabled

        // We want to stop Acrylic first
        CmdExec('Net.exe Stop "Acrylic DNS Proxy Service"');

        // We disable the Acrylic debug log
        DeleteFile(PChar('AcrylicDebug.txt'));

        // We tell the user that everything went fine
        if (MessageBox(0, 'The Acrylic DNS Proxy debug log has been disabled successfully. You should now restart the Acrylic DNS Proxy service.' + #13#10 + #13#10 + 'Do you want to do it now?', 'Information', MB_ICONINFORMATION or MB_YESNO) = IDYES) then begin

          // We want to start the Acrylic service finally
          if (CmdExec('Net.exe Start "Acrylic DNS Proxy Service"') = 0) then MessageBox(0, 'The Acrylic DNS Proxy service has been started successfully.', 'Information', MB_ICONINFORMATION or MB_OK) else MessageBox(0, 'An error occurred while starting the Acrylic DNS Proxy service.', 'Error', MB_ICONSTOP or MB_OK);

        end;

      end;

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'InstallAcrylicService') then begin

      // We want to register the Acrylic service
      CmdExec('AcrylicService.exe /INSTALL /SILENT');

      // We want to start the Acrylic service then
      CmdExec('Net.exe Start "Acrylic DNS Proxy Service"');

    end;

    // ----------------------------------------------------------------------

    if (ParamStr(1) = 'UninstallAcrylicService') then begin

      // We want to stop the Acrylic service first
      CmdExec('Net.exe Stop "Acrylic DNS Proxy Service"');

      // We want to remove the Acrylic service from the registry afterwards
      CmdExec('AcrylicService.exe /UNINSTALL /SILENT');

    end;

    // ----------------------------------------------------------------------

  end;
end.

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

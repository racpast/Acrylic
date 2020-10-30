// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  Environment;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Classes;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TOSVersion = packed record
    MajorVersion: Byte;
    MinorVersion: Byte;
    VersionDescription: String;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TEnvironment = class
    private
      class function  ExecuteCommandAndCaptureOutput(const CommandLine: String; var CommandOutput: String): Boolean;
      class procedure ReadOSVersion;
    public
      class procedure ReadSystemInfo;
      class function  IsWindowsVistaOrWindowsServer2008OrHigher: Boolean;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SysUtils,
  Windows,
  FileIO,
  Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  SAFE_MAX_PATH = 272;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  EXECUTE_COMMAND_WAIT_TIME = 30000;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TEnvironment.ExecuteCommandAndCaptureOutput(const CommandLine: String; var CommandOutput: String): Boolean;

var
  TempDirectoryPath: String; TempFilePath: String; TempFileHandle: Cardinal; SecurityAttributes: TSecurityAttributes; StartupInfo: TStartUpInfo; ProcessInfo: TProcessInformation;

begin

  Result := False;

  SetLength(TempDirectoryPath, SAFE_MAX_PATH); GetTempPath(SAFE_MAX_PATH, PChar(TempDirectoryPath)); TempDirectoryPath := Trim(TempDirectoryPath);

  SetLength(TempFilePath, SAFE_MAX_PATH); GetTempFileName(PChar(TempDirectoryPath), 'ADP', 0, PChar(TempFilePath)); TempFilePath := Trim(TempFilePath);

  try

    TempFileHandle := CreateFile(PChar(TempFilePath), GENERIC_WRITE, FILE_SHARE_READ, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);

    try

      SetHandleInformation(TempFileHandle, HANDLE_FLAG_INHERIT, 1);

      FillChar(SecurityAttributes, SizeOf(TSecurityAttributes), #0);

      SecurityAttributes.nLength := SizeOf(TSecurityAttributes);
      SecurityAttributes.bInheritHandle := True;
      SecurityAttributes.lpSecurityDescriptor := nil;

      FillChar(StartupInfo, SizeOf(TStartupInfo), #0);

      StartupInfo.cb := SizeOf(TStartupInfo);
      StartupInfo.wShowWindow := SW_HIDE;
      StartupInfo.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
      StartupInfo.hStdError := TempFileHandle;
      StartupInfo.hStdOutput := TempFileHandle;

      FillChar(ProcessInfo, SizeOf(TProcessInformation), #0);

      ProcessInfo.hProcess := INVALID_HANDLE_VALUE;
      ProcessInfo.hThread := INVALID_HANDLE_VALUE;

      if not(CreateProcess(nil, PChar(CommandLine), @SecurityAttributes, @SecurityAttributes, True, NORMAL_PRIORITY_CLASS, nil, nil, StartupInfo, ProcessInfo)) then Exit;

      try

        if (WaitForSingleObject(ProcessInfo.hProcess, EXECUTE_COMMAND_WAIT_TIME) <> WAIT_OBJECT_0) then Exit;

      finally

        if (ProcessInfo.hProcess <> INVALID_HANDLE_VALUE) then CloseHandle(ProcessInfo.hProcess);

        if (ProcessInfo.hThread <> INVALID_HANDLE_VALUE) then CloseHandle(ProcessInfo.hThread);

      end;

    finally

      CloseHandle(TempFileHandle);

    end;

    CommandOutput := TFileIO.ReadAllText(TempFilePath);

  finally

    DeleteFile(PChar(TempFilePath));

  end;

  Result := True;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TEnvironment_OSVersion: TOSVersion;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TEnvironment.ReadOSVersion;

var
  OSVersion: Cardinal;

begin

  OSVersion := GetVersion;

  TEnvironment_OSVersion.MajorVersion := OSVersion and $ff;
  TEnvironment_OSVersion.MinorVersion := (OSVersion shr $08) and $ff;

  case TEnvironment_OSVersion.MajorVersion of

    5:

    begin

      case TEnvironment_OSVersion.MinorVersion of

        0:

        begin
          TEnvironment_OSVersion.VersionDescription := 'Windows 2000 [' + IntToStr(OSVersion) + ']'; Exit;
        end;

        1:

        begin
          TEnvironment_OSVersion.VersionDescription := 'Windows XP [' + IntToStr(OSVersion) + ']'; Exit;
        end;

        2:

        begin
          TEnvironment_OSVersion.VersionDescription := 'Windows XP 64-Bit or Windows Server 2003 or Windows Server 2003 R2 [' + IntToStr(OSVersion) + ']'; Exit;
        end;

      end;
    end;

    6:

    begin

      case TEnvironment_OSVersion.MinorVersion of

        0:

        begin
          TEnvironment_OSVersion.VersionDescription := 'Windows Vista or Windows Server 2008 [' + IntToStr(OSVersion) + ']'; Exit;
        end;

        1:

        begin
          TEnvironment_OSVersion.VersionDescription := 'Windows 7 or Windows Server 2008 R2 [' + IntToStr(OSVersion) + ']'; Exit;
        end;

        2:

        begin
          TEnvironment_OSVersion.VersionDescription := 'Windows 8 or Windows Server 2012 [' + IntToStr(OSVersion) + ']'; Exit;
        end;

        3:

        begin
          TEnvironment_OSVersion.VersionDescription := 'Windows 8.1 or Windows Server 2012 R2 [' + IntToStr(OSVersion) + ']'; Exit;
        end;

      end;

    end;

    10:

    begin

      case TEnvironment_OSVersion.MinorVersion of

        0:

        begin
          TEnvironment_OSVersion.VersionDescription := 'Windows 10 or Windows Server 2016 [' + IntToStr(OSVersion) + ']'; Exit;
        end;

      end;

    end;

  end;

  TEnvironment_OSVersion.VersionDescription := 'Unknown Windows (v. ' + IntToStr(TEnvironment_OSVersion.MajorVersion) + '.' + IntToStr(TEnvironment_OSVersion.MinorVersion) + ') [' + IntToStr(OSVersion) + ']';

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TEnvironment.ReadSystemInfo;

var
  CommandOutput: String;

begin

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TEnvironment.ReadSystem: Reading system info...');

  Self.ReadOSVersion;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TEnvironment.ReadSystem: Operating system version is: ' + TEnvironment_OSVersion.VersionDescription + '.');

  if TTracer.IsEnabled then begin

    TTracer.Trace(TracePriorityInfo, 'TEnvironment.ReadSystem: Reading IP configuration...');

    try

      if Self.ExecuteCommandAndCaptureOutput('IpConfig.exe /All', CommandOutput) then TTracer.Write(TracePriorityInfo, CommandOutput);

    except

    end;

  end;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TEnvironment.ReadSystem: Done reading system info.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TEnvironment.IsWindowsVistaOrWindowsServer2008OrHigher: Boolean;

begin

  Result := TEnvironment_OSVersion.MajorVersion >= 6;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
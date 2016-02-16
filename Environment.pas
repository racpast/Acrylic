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
  TOSVersion = record
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
      class procedure ReadOSVersion;
    public
      class procedure ReadSystem;
    public
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
  Tracer;

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

class procedure TEnvironment.ReadSystem;
begin
  // Trace the event if a tracer is enabled
  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TEnvironment.ReadSystem: Reading system info...');

  // Read the operating system version
  ReadOSVersion;

  // Trace the event if a tracer is enabled
  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TEnvironment.ReadSystem: Operating system version is: ' + TEnvironment_OSVersion.VersionDescription + '.');

  // Trace the event if a tracer is enabled
  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TEnvironment.ReadSystem: Operation completed successfully.');
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
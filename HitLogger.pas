// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  HitLogger;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  CommunicationChannels;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  THitLogger = class
    public
      class function  IsEnabled: Boolean;
    public
      class procedure AddHit(When: TDateTime; Treatment: String; Client: TDualIPAddress; Description: String);
    public
      class procedure FlushAllPendingHitsToDisk;
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
  Classes,
  Configuration,
  EnvironmentVariables;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  MAX_PENDING_HITS = 1024;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THitLogger_BufferList: TStringList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function THitLogger.IsEnabled: Boolean;

begin

  Result := TConfiguration.GetHitLogFileName <> '';

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THitLogger.AddHit(When: TDateTime; Treatment: String; Client: TDualIPAddress; Description: String);

begin

  if (THitLogger_BufferList = nil) then begin THitLogger_BufferList := TStringList.Create; THitLogger_BufferList.Capacity := MAX_PENDING_HITS; end; THitLogger_BufferList.Add(FormatDateTime('yyyy-mm-dd HH":"nn":"ss.zzz', When) + #9 + TDualIPAddressUtility.ToString(Client) + #9 + Treatment + #9 + Description); if (THitLogger_BufferList.Count >= MAX_PENDING_HITS) then Self.FlushAllPendingHitsToDisk;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THitLogger.FlushAllPendingHitsToDisk;

var
  Name: String; Handle: THandle; Written: Cardinal; Line: String; Index: Integer;

begin

  if (THitLogger_BufferList <> nil) and (THitLogger_BufferList.Count > 0) then begin

    Name := TConfiguration.GetHitLogFileName;

    if (Pos('%DATE%', Name) > 0) then Name := StringReplace(Name, '%DATE%', FormatDateTime('yyyymmdd', Now), [rfReplaceAll]);

    if (Pos('%TEMP%', Name) > 0) then Name := StringReplace(Name, '%TEMP%', TEnvironmentVariables.Get('TEMP', '%TEMP%'), [rfReplaceAll]);
    if (Pos('%APPDATA%', Name) > 0) then Name := StringReplace(Name, '%APPDATA%', TEnvironmentVariables.Get('APPDATA', '%APPDATA%'), [rfReplaceAll]);
    if (Pos('%LOCALAPPDATA%', Name) > 0) then Name := StringReplace(Name, '%LOCALAPPDATA%', TEnvironmentVariables.Get('LOCALAPPDATA', '%LOCALAPPDATA%'), [rfReplaceAll]);

    Handle := CreateFile(PChar(Name), GENERIC_WRITE, FILE_SHARE_READ, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_ARCHIVE, 0); if (Handle <> INVALID_HANDLE_VALUE) then begin

      SetFilePointer(Handle, 0, nil, FILE_END); for Index := 0 to (THitLogger_BufferList.Count - 1) do begin Line := THitLogger_BufferList[Index] + #13#10; WriteFile(Handle, Line[1], Length(Line), Written, nil); end;

      THitLogger_BufferList.Clear;

      CloseHandle(Handle);

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
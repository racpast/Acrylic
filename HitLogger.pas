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

type
  THitLogger = class
    public
      class function  IsEnabled(): Boolean;
    public
      class procedure AddHit(When: TDateTime; Treatment: String; Client: Integer; Description: String);
    public
      class procedure FlushPendingHitsToDisk();
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SysUtils, Windows, Classes, Configuration, IpAddress;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  MAX_PENDING_HITS = 256;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THitLogger_BufferList: TStringList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function THitLogger.IsEnabled(): Boolean;
begin
  Result := TConfiguration.GetHitLogFileName() <> '';
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THitLogger.FlushPendingHitsToDisk();
var
  Handle: THandle; Written: Cardinal; Line: String; Index: Integer;
begin
  if (THitLogger_BufferList <> nil) and (THitLogger_BufferList.Count > 0) then begin

    Handle := CreateFile(PChar(StringReplace(TConfiguration.GetHitLogFileName(), '%DATE%', FormatDateTime('yyyymmdd', Now()), [rfReplaceAll])), GENERIC_WRITE, FILE_SHARE_READ, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_ARCHIVE, 0); if (Handle <> INVALID_HANDLE_VALUE) then begin

      // Append all the pending hits into the hit log
      SetFilePointer(Handle, 0, nil, FILE_END); for Index := 0 to (THitLogger_BufferList.Count - 1) do begin Line := THitLogger_BufferList[Index] + #13#10; WriteFile(Handle, Line[1], Length(Line), Written, nil); end;

      // Clean all the pending hits
      THitLogger_BufferList.Clear;

      CloseHandle(Handle);

    end;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THitLogger.AddHit(When: TDateTime; Treatment: String; Client: Integer; Description: String);
begin
  if (THitLogger_BufferList = nil) then begin THitLogger_BufferList := TStringList.Create; THitLogger_BufferList.Capacity := MAX_PENDING_HITS; end; THitLogger_BufferList.Add(FormatDateTime('yyyy-mm-dd HH":"nn":"ss.zzz', When) + #9 + TIpAddress.ToString(Client) + #9 + Treatment + #9 + Description); if (THitLogger_BufferList.Count >= MAX_PENDING_HITS) then Self.FlushPendingHitsToDisk();
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
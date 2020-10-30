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
  Classes,
  IpUtils;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  THitLogger = class
    public
      class procedure SetProperties(const FileName: String; const FileWhat: String; FullDump: Boolean; MaxPendingHits: Integer);
    public
      class function  IsEnabled: Boolean;
      class function  GetFileWhat: String;
      class function  GetFullDump: Boolean;
      class procedure AddIPv4Hit(When: TDateTime; Client: TIPv4Address; const StatusCode: String; const DnsServerIndex: String; const DnsServerResponseTime: String; const Description: String);
      class procedure AddIPv6Hit(When: TDateTime; Client: TIPv6Address; const StatusCode: String; const DnsServerIndex: String; const DnsServerResponseTime: String; const Description: String);
      class procedure WriteAllPendingHitsToDisk(Async: Boolean);
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  THitLoggerAsyncWriter = class(TThread)
    public
      IsDone: Boolean;
    private
      FileName: String;
      Contents: String;
    public
      constructor Create(const FileName: String; const Contents: String);
      procedure   Execute; override;
      destructor  Destroy; override;
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
  Configuration,
  EnvironmentVariables,
  FileIO,
  Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THitLogger_Enabled: Boolean;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THitLogger_FileName: String;
  THitLogger_FileWhat: String;
  THitLogger_FullDump: Boolean;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THitLogger_DateTemplate: Boolean;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THitLogger_BufferList: TStringList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THitLogger_MaxPendingHits: Integer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THitLogger_LastAsyncWriter: THitLoggerAsyncWriter;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THitLogger.SetProperties(const FileName: String; const FileWhat: String; FullDump: Boolean; MaxPendingHits: Integer);

begin

  if (FileName <> '') then begin

    THitLogger_Enabled := True;

    THitLogger_FileName := FileName;

    THitLogger_DateTemplate := Pos('%DATE%', FileName) > 0;

    if (Pos('%TEMP%', FileName) > 0) then THitLogger_FileName := StringReplace(THitLogger_FileName, '%TEMP%', TEnvironmentVariables.Get('TEMP', '%TEMP%'), [rfReplaceAll]);
    if (Pos('%APPDATA%', FileName) > 0) then THitLogger_FileName := StringReplace(THitLogger_FileName, '%APPDATA%', TEnvironmentVariables.Get('APPDATA', '%APPDATA%'), [rfReplaceAll]);
    if (Pos('%LOCALAPPDATA%', FileName) > 0) then THitLogger_FileName := StringReplace(THitLogger_FileName, '%LOCALAPPDATA%', TEnvironmentVariables.Get('LOCALAPPDATA', '%LOCALAPPDATA%'), [rfReplaceAll]);

    THitLogger_FileWhat := FileWhat;

    THitLogger_FullDump := FullDump;

    THitLogger_MaxPendingHits := MaxPendingHits;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function THitLogger.IsEnabled: Boolean;

begin

  Result := THitLogger_Enabled;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function THitLogger.GetFileWhat: String;

begin

  Result := THitLogger_FileWhat;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function THitLogger.GetFullDump: Boolean;

begin

  Result := THitLogger_FullDump;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THitLogger.AddIPv4Hit(When: TDateTime; Client: TIPv4Address; const StatusCode: String; const DnsServerIndex: String; const DnsServerResponseTime: String; const Description: String);

begin

  if (THitLogger_BufferList = nil) then begin THitLogger_BufferList := TStringList.Create; THitLogger_BufferList.Capacity := THitLogger_MaxPendingHits; end; THitLogger_BufferList.Add(FormatDateTime('yyyy-mm-dd HH":"nn":"ss.zzz', When) + #9 + TIPv4AddressUtility.ToString(Client) + #9 + StatusCode + #9 + DnsServerIndex + #9 + DnsServerResponseTime + #9 + Description); if (THitLogger_BufferList.Count >= THitLogger_MaxPendingHits) then Self.WriteAllPendingHitsToDisk(True);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THitLogger.AddIPv6Hit(When: TDateTime; Client: TIPv6Address; const StatusCode: String; const DnsServerIndex: String; const DnsServerResponseTime: String; const Description: String);

begin

  if (THitLogger_BufferList = nil) then begin THitLogger_BufferList := TStringList.Create; THitLogger_BufferList.Capacity := THitLogger_MaxPendingHits; end; THitLogger_BufferList.Add(FormatDateTime('yyyy-mm-dd HH":"nn":"ss.zzz', When) + #9 + TIPv6AddressUtility.ToString(Client) + #9 + StatusCode + #9 + DnsServerIndex + #9 + DnsServerResponseTime + #9 + Description); if (THitLogger_BufferList.Count >= THitLogger_MaxPendingHits) then Self.WriteAllPendingHitsToDisk(True);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THitLogger.WriteAllPendingHitsToDisk(Async: Boolean);

var
  HitLoggerBufferListCount: Integer; FileName: String; Contents: String;

begin

  if (THitLogger_BufferList <> nil) then begin

    HitLoggerBufferListCount := THitLogger_BufferList.Count;

    if (HitLoggerBufferListCount > 0) then begin

      if (THitLogger_LastAsyncWriter <> nil) then begin

        while not THitLogger_LastAsyncWriter.IsDone do Sleep(20); THitLogger_LastAsyncWriter.Free; THitLogger_LastAsyncWriter := nil;

      end;

      FileName := THitLogger_FileName; if THitLogger_DateTemplate then FileName := StringReplace(FileName, '%DATE%', FormatDateTime('yyyymmdd', Now), [rfReplaceAll]);

      Contents := THitLogger_BufferList.Text;

      try

        if Async then begin

          THitLogger_LastAsyncWriter := THitLoggerAsyncWriter.Create(FileName, Contents); if (THitLogger_LastAsyncWriter <> nil) then THitLogger_LastAsyncWriter.Resume else TFileIO.AppendAllText(FileName, Contents);

        end else begin

          TFileIO.AppendAllText(FileName, Contents);

        end;

      except

        on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'THitLogger.WriteAllPendingHitsToDisk: The following error occurred during execution: ' + E.Message);

      end;

      THitLogger_BufferList.Clear;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor THitLoggerAsyncWriter.Create(const FileName: String; const Contents: String);

begin

  inherited Create(True); Self.FreeOnTerminate := False; Self.FileName := FileName; Self.Contents := Contents;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure THitLoggerAsyncWriter.Execute;

begin

  try

    TFileIO.AppendAllText(Self.FileName, Self.Contents);

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'THitLoggerAsyncWriter.Execute: The following error occurred during execution: ' + E.Message);

  end;

  Self.IsDone := True;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor THitLoggerAsyncWriter.Destroy;

begin

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

begin

  THitLogger_Enabled := False;

end.

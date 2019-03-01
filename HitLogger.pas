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
  CommunicationChannels;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  THitLogger = class
    public
      class function  IsEnabled: Boolean;
      class procedure AddHit(When: TDateTime; Treatment: String; Client: TDualIPAddress; Description: String);
      class procedure FlushAllPendingHitsToDisk(Force: Boolean; Async: Boolean);
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
      constructor Create(FileName: String; Contents: String);
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

const
  MIN_PENDING_HITS = 1024;
  MAX_PENDING_HITS = 8192;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THitLogger_BufferList: TStringList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THitLogger_LastAsyncWriter: THitLoggerAsyncWriter;

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

  if (THitLogger_BufferList = nil) then begin THitLogger_BufferList := TStringList.Create; THitLogger_BufferList.Capacity := MAX_PENDING_HITS; end; THitLogger_BufferList.Add(FormatDateTime('yyyy-mm-dd HH":"nn":"ss.zzz', When) + #9 + TDualIPAddressUtility.ToString(Client) + #9 + Treatment + #9 + Description); if (THitLogger_BufferList.Count >= MAX_PENDING_HITS) then Self.FlushAllPendingHitsToDisk(True, True);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THitLogger.FlushAllPendingHitsToDisk(Force: Boolean; Async: Boolean);

var
  FileName: String; Contents: String;

begin

  if (THitLogger_BufferList <> nil) and (Force or (THitLogger_BufferList.Count >= MIN_PENDING_HITS)) then begin

    if (THitLogger_LastAsyncWriter <> nil) then begin

      while not(THitLogger_LastAsyncWriter.IsDone) do Sleep(50); THitLogger_LastAsyncWriter.Free; THitLogger_LastAsyncWriter := nil;

    end;

    if (THitLogger_BufferList.Count > 0) then begin

      FileName := TConfiguration.GetHitLogFileName;

      if (Pos('%DATE%', FileName) > 0) then FileName := StringReplace(FileName, '%DATE%', FormatDateTime('yyyymmdd', Now), [rfReplaceAll]);
      if (Pos('%TEMP%', FileName) > 0) then FileName := StringReplace(FileName, '%TEMP%', TEnvironmentVariables.Get('TEMP', '%TEMP%'), [rfReplaceAll]);
      if (Pos('%APPDATA%', FileName) > 0) then FileName := StringReplace(FileName, '%APPDATA%', TEnvironmentVariables.Get('APPDATA', '%APPDATA%'), [rfReplaceAll]);
      if (Pos('%LOCALAPPDATA%', FileName) > 0) then FileName := StringReplace(FileName, '%LOCALAPPDATA%', TEnvironmentVariables.Get('LOCALAPPDATA', '%LOCALAPPDATA%'), [rfReplaceAll]);

      Contents := THitLogger_BufferList.Text;

      try

        if Async then begin

          THitLogger_LastAsyncWriter := THitLoggerAsyncWriter.Create(FileName, Contents); if (THitLogger_LastAsyncWriter <> nil) then THitLogger_LastAsyncWriter.Resume else TFileIO.AppendAllText(FileName, Contents);

        end else begin

          TFileIO.AppendAllText(FileName, Contents);

        end;

      except

        on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'THitLogger.FlushAllPendingHitsToDisk: ' + E.Message);

      end;

      THitLogger_BufferList.Clear;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor THitLoggerAsyncWriter.Create(FileName: String; Contents: String);

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

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'THitLoggerAsyncWriter.Execute: ' + E.Message);

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

end.

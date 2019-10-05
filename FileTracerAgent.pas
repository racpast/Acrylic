// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  FileTracerAgent;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Classes,
  SyncObjs,
  FileIO,
  Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TFileTracerAgent = class(TInterfacedObject, ITracerAgent)
    private
      InError: Boolean;
    private
      Lock: TCriticalSection;
    private
      FileStream: TBufferedSequentialWriteStream;
    public
      constructor Create(FileName: String);
      procedure   RenderTrace(Time: Double; Priority: TracePriority; const Message: String);
      procedure   CloseTrace;
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
  Windows;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TFileTracerAgent.Create(FileName: String);

begin

  inherited Create;

  Self.Lock := TCriticalSection.Create;

  try Self.FileStream := TBufferedSequentialWriteStream.Create(FileName, True, BUFFERED_SEQUENTIAL_STREAM_256KB_BUFFER_SIZE); except Self.InError := True; end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TFileTracerAgent.RenderTrace(Time: Double; Priority: TracePriority; const Message: String);

var
  Line: String;

begin

  // Determine what to log out of the lock for performance reasons
  if (Priority = TracePriorityInfo) then Line := FormatDateTime('yyyy-MM-dd HH":"mm":"ss.zzz', Time) + ' [I] ' + Message + #13#10 else if (Priority = TracePriorityWarning) then Line := FormatDateTime('yyyy-MM-dd HH":"mm":"ss.zzz', Time) + ' [W] ' + Message + #13#10 else if (Priority = TracePriorityError) then Line := FormatDateTime('yyyy-MM-dd HH":"mm":"ss.zzz', Time) + ' [E] ' + Message + #13#10 else Line := FormatDateTime('yyyy-MM-dd HH":"mm":"ss.zzz', Time) + ' [?] ' + Message + #13#10;

  // Tracing is wrapped around a critical section for thread-safety
  Self.Lock.Acquire; try try if not(Self.InError) then if not(Self.FileStream.WriteString(Line)) then Self.InError := True; except Self.InError := True; end; finally Self.Lock.Release; end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TFileTracerAgent.CloseTrace;

begin

  if (Self.FileStream <> nil) then try if not(Self.FileStream.Flush) then Self.InError := True; except Self.InError := True; end;

  if (Self.FileStream <> nil) then Self.FileStream.Free;

  if (Self.Lock <> nil) then Self.Lock.Free;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
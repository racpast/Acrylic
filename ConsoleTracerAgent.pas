// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  ConsoleTracerAgent;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SyncObjs,
  Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TConsoleTracerAgent = class(TInterfacedObject, ITracerAgent)
    private
      Lock: TCriticalSection;
    public
      constructor Create;
      procedure   RenderTrace(TimeStamp: TDateTime; Priority: TracePriority; const Message: String);
      procedure   RenderWrite(const Message: String);
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
  SysUtils;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TConsoleTracerAgent.Create;

begin

  inherited Create;

  Self.Lock := TCriticalSection.Create;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TConsoleTracerAgent.RenderTrace(TimeStamp: TDateTime; Priority: TracePriority; const Message: String);

var
  Line: String;

begin

  // Determine what to log out of the lock for performance reasons
  if (Priority = TracePriorityInfo) then Line := FormatDateTime('yyyy-MM-dd HH":"mm":"ss.zzz', TimeStamp) + ' [I] ' + Message else if (Priority = TracePriorityWarning) then Line := FormatDateTime('yyyy-MM-dd HH":"mm":"ss.zzz', TimeStamp) + ' [W] ' + Message else if (Priority = TracePriorityError) then Line := FormatDateTime('yyyy-MM-dd HH":"mm":"ss.zzz', TimeStamp) + ' [E] ' + Message else Line := FormatDateTime('yyyy-MM-dd HH":"mm":"ss.zzz', TimeStamp) + ' [?] ' + Message;

  // Tracing is wrapped around a critical section for thread-safety
  Self.Lock.Acquire; try WriteLn(Line); finally Self.Lock.Release; end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TConsoleTracerAgent.RenderWrite(const Message: String);

begin

  // Tracing is wrapped around a critical section for thread-safety
  Self.Lock.Acquire; try WriteLn(Message); finally Self.Lock.Release; end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TConsoleTracerAgent.CloseTrace;

begin

  Self.Lock.Free;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
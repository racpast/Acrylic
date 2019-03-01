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
      procedure   RenderTrace(Time: Double; Priority: TracePriority; Message: String);
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

procedure TConsoleTracerAgent.RenderTrace(Time: Double; Priority: TracePriority; Message: String);

var
  Line: String;

begin

  // Determine what to log out of the lock for performance reasons
  if (Priority = TracePriorityInfo) then Line := FormatDateTime('yyyy-MM-dd HH":"mm":"ss.zzz', Time) + ' [I] ' + Message else if (Priority = TracePriorityWarning) then Line := FormatDateTime('yyyy-MM-dd HH":"mm":"ss.zzz', Time) + ' [W] ' + Message else if (Priority = TracePriorityError) then Line := FormatDateTime('yyyy-MM-dd HH":"mm":"ss.zzz', Time) + ' [E] ' + Message else Line := FormatDateTime('yyyy-MM-dd HH":"mm":"ss.zzz', Time) + ' [?] ' + Message;

  // Tracing is wrapped around a critical section for thread-safety
  Self.Lock.Acquire; try WriteLn(Line); finally Self.Lock.Release; end;

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
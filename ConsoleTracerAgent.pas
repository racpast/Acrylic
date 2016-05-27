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
  // Prepare the message in advance
  Line := FormatDateTime('yyyy-MM-dd HH":"mm":"ss.zzz', Time) + ' ' + Message;

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
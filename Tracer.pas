// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TracePriority = (TracePriorityInfo, TracePriorityWarning, TracePriorityError, TracePriorityNone);

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  ITracerAgent = interface(IInterface)
    procedure RenderTrace(Time: Double; Priority: TracePriority; const Message: String);
    procedure CloseTrace;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TTracer = class
    public
      class procedure Initialize;
      class procedure Finalize;
    public
      class function  IsEnabled: Boolean;
      class procedure SetTracerAgent(TracerAgent: ITracerAgent);
      class procedure SetMinimumTracingPriority(Priority: TracePriority);
    public
      class procedure Trace(Priority: TracePriority; const Message: String);
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

var TTracer_Enabled: Boolean;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TTracer_TracerAgent: ITracerAgent;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TTracer_MinimumTracingPriority: TracePriority;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TTracer.Initialize;

begin

  TTracer_Enabled := False; TTracer_TracerAgent := nil; TTracer_MinimumTracingPriority := TracePriorityInfo;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TTracer.IsEnabled: Boolean;

begin

  Result := TTracer_Enabled;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TTracer.SetTracerAgent(TracerAgent: ITracerAgent);

begin

  if (TTracer_TracerAgent <> nil) then TTracer_TracerAgent.CloseTrace; TTracer_TracerAgent := TracerAgent; TTracer_Enabled := True;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TTracer.SetMinimumTracingPriority(Priority: TracePriority);

begin

  TTracer_MinimumTracingPriority := Priority;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TTracer.Trace(Priority: TracePriority; const Message: String);

begin

  if (TTracer_TracerAgent <> nil) then begin

    if (Priority >= TTracer_MinimumTracingPriority) then TTracer_TracerAgent.RenderTrace(Now, Priority, Message);

  end else begin

    raise Exception.Create('TTracer.Trace: The tracer agent must be set before calling this method.');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TTracer.Finalize;

begin

  if (TTracer_TracerAgent <> nil) then TTracer_TracerAgent.CloseTrace; TTracer_Enabled := False; TTracer_TracerAgent := nil;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

begin

  TTracer_Enabled := False;

end.
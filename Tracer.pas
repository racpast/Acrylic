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
    procedure RenderTrace(Time: Double; Priority: TracePriority; Message: String);
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
      class procedure Trace(Priority: TracePriority; Message: String);
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
  TTracer_TracerAgent := nil; TTracer_MinimumTracingPriority := TracePriorityInfo;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TTracer.IsEnabled: Boolean;
begin
  Result := (TTracer_TracerAgent <> nil);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TTracer.SetTracerAgent(TracerAgent: ITracerAgent);
begin
  if (TTracer_TracerAgent <> nil) then TTracer_TracerAgent.CloseTrace; TTracer_TracerAgent := TracerAgent;
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

class procedure TTracer.Trace(Priority: TracePriority; Message: String);
begin
  if (TTracer_TracerAgent <> nil) then begin // If the tracer agent has been set...

    // If the priority is not less than the minimum for tracing then forward the trace to the tracer agent
    if (Priority >= TTracer_MinimumTracingPriority) then TTracer_TracerAgent.RenderTrace(Now, Priority, Message);

  end else begin // The tracer agent has not been set

    raise Exception.Create('TTracer.Trace: The tracer agent must be set before calling this method.');

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TTracer.Finalize;
begin
  if (TTracer_TracerAgent <> nil) then TTracer_TracerAgent.CloseTrace; TTracer_TracerAgent := nil;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
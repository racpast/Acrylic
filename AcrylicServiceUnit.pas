
// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  AcrylicServiceUnit;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SvcMgr;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TAcrylicController = class(TService)
      procedure ServiceShutdown(Sender: TService);
      procedure ServiceStop(Sender: TService; var Stopped: Boolean);
      procedure ServiceStart(Sender: TService; var Started: Boolean);
    public
      function  GetServiceController: TServiceController; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  AcrylicController: TAcrylicController;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SysUtils, Configuration, Tracer, FileTracerAgent, Bootstrapper;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

{$R *.dfm}

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure ServiceController(CtrlCode: Cardinal); stdcall;
begin
  AcrylicController.Controller(CtrlCode);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TAcrylicController.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TAcrylicController.ServiceShutdown(Sender: TService);
begin
  try

    // Stop the system
    TBootstrapper.StopSystem();

    // Stop everything else
    TTracer.Finalize(); TConfiguration.Finalize();

  except
    // Suppress any exception
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TAcrylicController.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  try

    // Stop the system
    TBootstrapper.StopSystem();

    // Stop everything else
    TTracer.Finalize(); TConfiguration.Finalize();

    // Report to the Service Controller
    Stopped := True;

  except
    Stopped := False;
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TAcrylicController.ServiceStart(Sender: TService; var Started: Boolean);
begin
  try

    // Init...
    DecimalSeparator := '.';

    // Start the config and eventually set the debug file
    TConfiguration.Initialize(); TTracer.Initialize(); if FileExists(TConfiguration.GetDebugLogFileName()) then TTracer.SetTracerAgent(TFileTracerAgent.Create(TConfiguration.GetDebugLogFileName()));

    // Start the system using the Bootstrapper
    TBootstrapper.StartSystem();

    // Report to the Service Controller
    Started := True;

  except
    Started := False;
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
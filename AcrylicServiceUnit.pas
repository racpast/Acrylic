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
  TAcrylicServiceController = class(TService)
      procedure ServiceAfterInstall(Sender: TService);
      procedure ServiceStart(Sender: TService; var Started: Boolean);
      procedure ServiceStop(Sender: TService; var Stopped: Boolean);
      procedure ServiceShutdown(Sender: TService);
    public
      function  GetServiceController: TServiceController; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  AcrylicServiceController: TAcrylicServiceController;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Registry, SysUtils, Windows, AcrylicVersionInfo, Bootstrapper, Configuration, Environment, FileTracerAgent, Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

{$R *.dfm}

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure ServiceController(CtrlCode: Cardinal); stdcall;
begin
  AcrylicServiceController.Controller(CtrlCode);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TAcrylicServiceController.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TAcrylicServiceController.ServiceAfterInstall(Sender: TService);
var
  R: TRegistry;
begin
  R := TRegistry.Create(KEY_READ or KEY_WRITE);

  try

    R.RootKey := HKEY_LOCAL_MACHINE;

    if R.OpenKey('\System\CurrentControlSet\Services\' + Self.Name, false) then begin
      R.WriteString('Description', 'A local DNS proxy which improves the performance of your computer.');
      R.CloseKey;
    end;

  finally

    R.Free;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TAcrylicServiceController.ServiceStart(Sender: TService; var Started: Boolean);
begin
  try

    DecimalSeparator := '.';

    TConfiguration.Initialize; TTracer.Initialize; if FileExists(TConfiguration.GetDebugLogFileName) then TTracer.SetTracerAgent(TFileTracerAgent.Create(TConfiguration.GetDebugLogFileName));

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'Acrylic version is ' + AcrylicVersionNumber + ' released on ' + AcrylicReleaseDate + '.');

    TBootstrapper.StartSystem;

    Started := True;

  except

    on E: Exception do begin

      Self.LogMessage('TAcrylicServiceController.ServiceStart: ' + E.Message, EVENTLOG_ERROR_TYPE);

      Started := False;

    end;
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TAcrylicServiceController.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  try

    TBootstrapper.StopSystem;

    TTracer.Finalize; TConfiguration.Finalize;

    Stopped := True;

  except

    on E: Exception do begin

      Self.LogMessage('TAcrylicServiceController.ServiceStop: ' + E.Message, EVENTLOG_ERROR_TYPE);

      Stopped := False;

    end;
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TAcrylicServiceController.ServiceShutdown(Sender: TService);
begin
  try

    TBootstrapper.StopSystem;

    TTracer.Finalize; TConfiguration.Finalize;

  except

    on E: Exception do begin

      Self.LogMessage('TAcrylicServiceController.ServiceShutdown: ' + E.Message, EVENTLOG_ERROR_TYPE);

    end;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

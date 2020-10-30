// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  AcrylicServiceController;

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
  TAcrylicDNSProxySvc = class(TService)
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
  AcrylicDNSProxySvc: TAcrylicDNSProxySvc;

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
  Registry,
  AcrylicVersionInfo,
  Configuration,
  DnsResolver,
  Environment,
  FileTracerAgent,
  Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

{$R *.dfm}

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure ServiceController(CtrlCode: Cardinal); stdcall;

begin

  AcrylicDNSProxySvc.Controller(CtrlCode);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TAcrylicDNSProxySvc.GetServiceController: TServiceController;

begin

  Result := ServiceController;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TAcrylicDNSProxySvc.ServiceAfterInstall(Sender: TService);

var
  R: TRegistry;

begin

  try

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

  except

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TAcrylicDNSProxySvc.ServiceStart(Sender: TService; var Started: Boolean);

begin

  Started := False;

  DecimalSeparator := '.';

  try

    TConfiguration.Initialize; TTracer.Initialize; if FileExists(TConfiguration.GetDebugLogFileName) then TTracer.SetTracerAgent(TFileTracerAgent.Create(TConfiguration.GetDebugLogFileName));

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'Acrylic version is ' + AcrylicVersionNumber + ' released on ' + AcrylicReleaseDate + '.');

    TDnsResolver.StartResolver;

    Started := True;

  except

    on E: Exception do begin

      Self.LogMessage('TAcrylicServiceController.ServiceStart: ' + E.Message, EVENTLOG_ERROR_TYPE);

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TAcrylicDNSProxySvc.ServiceStop(Sender: TService; var Stopped: Boolean);

begin

  Stopped := False;

  try

    TDnsResolver.StopResolver; TTracer.Finalize; TConfiguration.Finalize;

    Stopped := True;

  except

    on E: Exception do begin

      Self.LogMessage('TAcrylicServiceController.ServiceStop: ' + E.Message, EVENTLOG_ERROR_TYPE);

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TAcrylicDNSProxySvc.ServiceShutdown(Sender: TService);

begin

  try

    TDnsResolver.StopResolver; TTracer.Finalize; TConfiguration.Finalize;

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

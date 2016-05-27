// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  Bootstrapper;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TBootstrapper = class
    public
      class procedure StartSystem;
      class procedure StopSystem;
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
  AddressCache,
  CommunicationChannels,
  Configuration,
  Environment,
  HostsCache,
  HttpServer,
  DnsResolver,
  SessionCache,
  Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TBootstrapper.StartSystem;
begin
  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Initialization...');

  TCommunicationChannel.Initialize; TSessionCache.Initialize; TAddressCache.Initialize; THostsCache.Initialize;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Done.');

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Reading system info...');

  TEnvironment.ReadSystem;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Done.');

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Loading configuration file...');

  TConfiguration.LoadFromFile(TConfiguration.GetConfigurationFileName);

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Done.');

  if TConfiguration.GetHttpServerConfiguration.IsEnabled then begin

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Starting HTTP server...');

    THttpServer.StartInstance;

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Done.');

  end;

  if FileExists(TConfiguration.GetAddressCacheFileName) then begin

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Loading address cache items...');

    TAddressCache.LoadFromFile(TConfiguration.GetAddressCacheFileName);

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Done.');

  end;

  if FileExists(TConfiguration.GetHostsCacheFileName) then begin

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Loading hosts cache items...');

    THostsCache.LoadFromFile(TConfiguration.GetHostsCacheFileName);

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Done.');

  end;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Starting DNS resolver...');

  TDnsResolver.StartInstance;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Done.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TBootstrapper.StopSystem;
begin
  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StopSystem: Stopping DNS resolver...');

  TDnsResolver.StopInstance;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StopSystem: Done.');

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StopSystem: Saving address cache items...');

  TAddressCache.ScavengeToFile(TConfiguration.GetAddressCacheFileName);

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StopSystem: Done.');

  if TConfiguration.GetHttpServerConfiguration.IsEnabled then begin

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StopSystem: Stopping HTTP server...');

    THttpServer.StopInstance;

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StopSystem: Done.');

  end;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StopSystem: Finalization...');

  THostsCache.Finalize; TAddressCache.Finalize; TSessionCache.Finalize; TCommunicationChannel.Finalize;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StopSystem: Done.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
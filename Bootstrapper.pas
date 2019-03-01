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
  DnsResolver,
  SessionCache,
  Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TBootstrapper.StartSystem;

begin

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Initializing...');

  TCommunicationChannel.Initialize; TSessionCache.Initialize; TAddressCache.Initialize; THostsCache.Initialize;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Done initializing.');

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Reading system info...');

  TEnvironment.ReadSystem;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Done reading system info.');

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Loading configuration file...');

  TConfiguration.LoadFromFile(TConfiguration.GetConfigurationFileName);

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Done loading configuration file.');

  if not(TConfiguration.GetAddressCacheDisabled) and not(TConfiguration.GetAddressCacheInMemoryOnly) and FileExists(TConfiguration.GetAddressCacheFileName) then begin

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Loading address cache items...');

    TAddressCache.LoadFromFile(TConfiguration.GetAddressCacheFileName);

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Done loading address cache items.');

  end;

  if FileExists(TConfiguration.GetHostsCacheFileName) then begin

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Loading hosts cache items...');

    THostsCache.LoadFromFile(TConfiguration.GetHostsCacheFileName);

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Done loading hosts cache items.');

  end;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Starting DNS resolver...');

  TDnsResolver.StartInstance;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Done starting DNS resolver.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TBootstrapper.StopSystem;

begin

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StopSystem: Stopping DNS resolver...');

  TDnsResolver.StopInstance;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StopSystem: Done stopping DNS resolver.');

  if not(TConfiguration.GetAddressCacheDisabled) and not(TConfiguration.GetAddressCacheInMemoryOnly) then begin

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StopSystem: Saving address cache items...');

    TAddressCache.SaveToFile(TConfiguration.GetAddressCacheFileName);

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StopSystem: Done saving address cache items.');

  end;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StopSystem: Finalizing...');

  THostsCache.Finalize; TAddressCache.Finalize; TSessionCache.Finalize; TCommunicationChannel.Finalize;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StopSystem: Done finalizing.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
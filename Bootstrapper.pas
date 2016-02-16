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
  // Initializations
  TCommunicationChannel.Initialize; TSessionCache.Initialize; TAddressCache.Initialize; THostsCache.Initialize;

  try

    // Trace the event if a tracer is enabled
    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Reading system info...');

    // Gather informations about the system
    TEnvironment.ReadSystem;

    // Trace the event if a tracer is enabled
    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Loading configuration file...');

    // Load the configuration from file
    TConfiguration.LoadFromFile(TConfiguration.GetConfigurationFileName);

    if FileExists(TConfiguration.GetAddressCacheFileName) then begin // If the address cache file exists...

      // Trace the event if a tracer is enabled
      if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Loading address cache items...');

      // Load the address cache from file
      TAddressCache.LoadFromFile(TConfiguration.GetAddressCacheFileName);

    end;

    if FileExists(TConfiguration.GetHostsCacheFileName) then begin // If the hosts cache file exists...

      // Trace the event if a tracer is enabled
      if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Loading hosts cache items...');

      // Load the hosts cache from file
      THostsCache.LoadFromFile(TConfiguration.GetHostsCacheFileName);

    end;

  except
    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TBootstrapper.StartSystem: ' + E.Message);
  end;

  // Trace the event if a tracer is enabled
  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Starting resolver...');

  // Start the resolver thread
  TDnsResolver.StartInstance;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TBootstrapper.StopSystem;
begin
  // Trace the event if a tracer is enabled
  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StopSystem: Stopping resolver...');

  // Stop the resolver thread
  TDnsResolver.StopInstance;

  try

    // Trace the event if a tracer is enabled
    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StopSystem: Saving address cache items...');

    // Scavenge the address cache to file
    TAddressCache.ScavengeToFile(TConfiguration.GetAddressCacheFileName);

  except
    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TBootstrapper.StopSystem: ' + E.Message);
  end;

  // Trace the event if a tracer is enabled
  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StopSystem: Finalization...');

  // Finalizations
  THostsCache.Finalize; TAddressCache.Finalize; TSessionCache.Finalize; TCommunicationChannel.Finalize;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
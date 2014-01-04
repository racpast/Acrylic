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
  SysUtils, Configuration, Tracer, SessionCache, AddressCache, HostsCache, Resolver;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TBootstrapper_ResolverObject: TResolver;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TBootstrapper.StartSystem;
begin
  TSessionCache.Initialize(); TAddressCache.Initialize(); THostsCache.Initialize();

  try

    if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Loading configuration file...');

    // Load the configuration from file
    TConfiguration.LoadFromFile(TConfiguration.GetConfigurationFileName());

    if FileExists(TConfiguration.GetAddressCacheFileName()) then begin // If the address cache file exists...

      if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Loading address cache items...');

      // Load the address cache from file
      TAddressCache.LoadFromFile(TConfiguration.GetAddressCacheFileName());

    end;

    if FileExists(TConfiguration.GetHostsCacheFileName()) then begin // If the hosts cache file exists...

      if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Loading hosts cache items...');

      // Load the hosts cache from file
      THostsCache.LoadFromFile(TConfiguration.GetHostsCacheFileName());

    end;

  except
    on E: Exception do if TTracer.IsEnabled() then TTracer.Trace(TracePriorityError, 'TBootstrapper.StartSystem: ' + E.Message);
  end;

  if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StartSystem: Starting resolver...');

  // Create the Resolver thread
  TBootstrapper_ResolverObject := TResolver.Create();

  // Start the Resolver thread
  TBootstrapper_ResolverObject.Resume();
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TBootstrapper.StopSystem;
begin
  if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StopSystem: Stopping resolver...');

  // Signal termination to the Resolver thread, wait & free
  TBootstrapper_ResolverObject.Terminate(); TBootstrapper_ResolverObject.WaitFor(); TBootstrapper_ResolverObject.Free();

  try

    if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StopSystem: Saving address cache items...');

    // Scavenge the address cache to file
    TAddressCache.ScavengeToFile(TConfiguration.GetAddressCacheFileName());

  except
    on E: Exception do if TTracer.IsEnabled() then TTracer.Trace(TracePriorityError, 'TBootstrapper.StopSystem: ' + E.Message);
  end;

  if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TBootstrapper.StopSystem: Finalization...');

  THostsCache.Finalize(); TAddressCache.Finalize(); TSessionCache.Finalize();
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

program
  AcrylicService;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SvcMgr,
  AcrylicServiceController in 'AcrylicServiceController.pas',
  AcrylicVersionInfo in 'AcrylicVersionInfo.pas',
  AddressCache in 'AddressCache.pas',
  Bootstrapper in 'Bootstrapper.pas',
  CommonUtils in 'CommonUtils.pas',
  CommunicationChannels in 'CommunicationChannels.pas',
  Configuration in 'Configuration.pas',
  ConsoleTracerAgent in 'ConsoleTracerAgent.pas',
  DnsForwarder in 'DnsForwarder.pas',
  DnsProtocol in 'DnsProtocol.pas',
  DnsResolver in 'DnsResolver.pas',
  Environment in 'Environment.pas',
  EnvironmentVariables in 'EnvironmentVariables.pas',
  FileIO in 'FileIO.pas',
  FileStreamLineEx in 'FileStreamLineEx.pas',
  FileTracerAgent in 'FileTracerAgent.pas',
  HitLogger in 'HitLogger.pas',
  HostsCache in 'HostsCache.pas',
  HostsCacheBinaryTrees in 'HostsCacheBinaryTrees.pas',
  MD5 in 'MD5.pas',
  MemoryManager in 'MemoryManager.pas',
  MemoryStore in 'MemoryStore.pas',
  PatternMatching in 'PatternMatching.pas',
  PCRE in 'PCRE.pas',
  PerlRegEx in 'PerlRegEx.pas',
  SessionCache in 'SessionCache.pas',
  Tracer in 'Tracer.pas';

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

begin

  Application.Initialize;

  Application.CreateForm(TAcrylicDNSProxySvc, AcrylicDNSProxySvc);

  Application.Run;

end.
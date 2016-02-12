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
  AcrylicServiceUnit in 'AcrylicServiceUnit.pas',
  AcrylicVersionInfo in 'AcrylicVersionInfo.pas',
  AddressCache in 'AddressCache.pas',
  Bootstrapper in 'Bootstrapper.pas',
  CommunicationChannels in 'CommunicationChannels.pas',
  Configuration in 'Configuration.pas',
  ConsoleTracerAgent in 'ConsoleTracerAgent.pas',
  Digest in 'Digest.pas',
  DnsForwarder in 'DnsForwarder.pas',
  DnsProtocol in 'DnsProtocol.pas',
  DnsResolver in 'DnsResolver.pas',
  FileStreamLineEx in 'FileStreamLineEx.pas',
  FileTracerAgent in 'FileTracerAgent.pas',
  HitLogger in 'HitLogger.pas',
  HostsCache in 'HostsCache.pas',
  MemoryManager in 'MemoryManager.pas',
  MemoryStore in 'MemoryStore.pas',
  PatternMatching in 'PatternMatching.pas',
  RegExpr in 'RegExpr.pas',
  SessionCache in 'SessionCache.pas',
  Tracer in 'Tracer.pas',
  Statistics in 'Statistics.pas',
  Stopwatch in 'Stopwatch.pas';

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

begin
  Application.Initialize; Application.CreateForm(TAcrylicServiceController, AcrylicServiceController); Application.Run;
end.
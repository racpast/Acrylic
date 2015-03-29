// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

program
  AcrylicService;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SvcMgr, AcrylicServiceUnit in 'AcrylicServiceUnit.pas', AcrylicVersionInfo in 'AcrylicVersionInfo.pas', AddressCache in 'AddressCache.pas', Bootstrapper in 'Bootstrapper.pas', ClientServerSocket in 'ClientServerSocket.pas', Compression in 'Compression.pas', Configuration in 'Configuration.pas', ConsoleTracerAgent in 'ConsoleTracerAgent.pas', Digest in 'Digest.pas', FileStreamLineEx in 'FileStreamLineEx.pas', FileTracerAgent in 'FileTracerAgent.pas', HitLogger in 'HitLogger.pas', HostsCache in 'HostsCache.pas', IPAddress in 'IPAddress.pas', PatternMatching in 'PatternMatching.pas', Performance in 'Performance.pas', QueryTypeUtils in 'QueryTypeUtils.pas', RegExpr in 'RegExpr.pas', Resolver in 'Resolver.pas', SessionCache in 'SessionCache.pas', Statistics in 'Statistics.pas', Tracer in 'Tracer.pas';

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

begin
  Application.Initialize;
  Application.CreateForm(TAcrylicController, AcrylicController);
  Application.Run;
end.
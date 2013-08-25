// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

program
  AcrylicConsole;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

{$APPTYPE CONSOLE}

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SysUtils, AddressCache in 'AddressCache.pas', Bootstrapper in 'Bootstrapper.pas', ClientServerSocket in 'ClientServerSocket.pas', Compression in 'Compression.pas', Configuration in 'Configuration.pas', ConsoleTracerAgent in 'ConsoleTracerAgent.pas', Digest in 'Digest.pas', FileStreamLineEx in 'FileStreamLineEx.pas', FileTracerAgent in 'FileTracerAgent.pas', HitLogger in 'HitLogger.pas', HostsCache in 'HostsCache.pas', IPAddress in 'IPAddress.pas', PatternMatching in 'PatternMatching.pas', Performance in 'Performance.pas', RegExpr in 'RegExpr.pas', Resolver in 'Resolver.pas', SessionCache in 'SessionCache.pas', Statistics in 'Statistics.pas', Tracer in 'Tracer.pas', WinSock2 in 'WinSock2.pas';

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

begin
  WriteLn('==============================================================================');
  WriteLn('Acrylic DNS Proxy Console Version                          Press ENTER To Quit');
  WriteLn('==============================================================================');

  // Init stuff
  DecimalSeparator := '.';

  // Initialize the configuration, the tracer and set the console tracer agent
  TConfiguration.Initialize(); TTracer.Initialize(); TTracer.SetTracerAgent(TConsoleTracerAgent.Create());

  // Start the system using the Bootstrapper
  TBootstrapper.StartSystem();

  // Wait until the ENTER key is pressed
  ReadLn;

  // Stop the system
  TBootstrapper.StopSystem();

  // Finalize everything
  TTracer.Finalize(); TConfiguration.Finalize();
end.
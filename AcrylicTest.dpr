// --------------------------------------------------------------------------
// A console application container for unit and integration tests on Acrylic
// --------------------------------------------------------------------------

{$APPTYPE CONSOLE}

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

program
  AcrylicTest;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SysUtils, Classes, IniFiles, AbstractUnitTest in 'AbstractUnitTest.pas', AcrylicVersionInfo in 'AcrylicVersionInfo.pas', AddressCache in 'AddressCache.pas', Bootstrapper in 'Bootstrapper.pas', ClientServerSocket in 'ClientServerSocket.pas', Compression in 'Compression.pas', Configuration in 'Configuration.pas', ConsoleTracerAgent in 'ConsoleTracerAgent.pas', Digest in 'Digest.pas', FileStreamLineEx in 'FileStreamLineEx.pas', FileTracerAgent in 'FileTracerAgent.pas', HitLogger in 'HitLogger.pas', HostsCache in 'HostsCache.pas', IPAddress in 'IPAddress.pas', PatternMatching in 'PatternMatching.pas', Performance in 'Performance.pas', QueryTypeUtils in 'QueryTypeUtils.pas', RegExpr in 'RegExpr.pas', Resolver in 'Resolver.pas', SessionCache in 'SessionCache.pas', Statistics in 'Statistics.pas', Tracer in 'Tracer.pas';

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

{$i ClientServerSocketUnitTest.pas }
{$i SessionCacheUnitTest.pas       }
{$i AddressCacheUnitTest.pas       }
{$i HostsCacheUnitTest.pas         }
{$i BootstrapperUnitTest.pas       }

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

begin
  DecimalSeparator := '.';

  WriteLn('==============================================================================');
  WriteLn('Acrylic DNS Proxy Test Application');
  WriteLn('==============================================================================');

  // Initialize the configuration, the tracer and set the console tracer agent
  TConfiguration.Initialize(); TTracer.Initialize(); TTracer.SetTracerAgent(TConsoleTracerAgent.Create);

  // Trace Acrylic version info if a tracer is enabled
  if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'Acrylic version ' + AcrylicVersionInfo.Number + ' released on ' + AcrylicVersionInfo.ReleaseDate + '.');

  // Perform all the unit tests sequentially
  TAbstractUnitTest.ControlTestExecution(TClientServerSocketUnitTest.Create);
  TAbstractUnitTest.ControlTestExecution(TSessionCacheUnitTest.Create);
  TAbstractUnitTest.ControlTestExecution(TAddressCacheUnitTest.Create);
  TAbstractUnitTest.ControlTestExecution(THostsCacheUnitTest.Create);

  // Perform the integration test
  TAbstractUnitTest.ControlTestExecution(TBootstrapperUnitTest.Create);

  // Finalize everything
  TTracer.Finalize(); TConfiguration.Finalize();

  WriteLn('Press ENTER To Quit.'); ReadLn;
end.
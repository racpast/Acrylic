// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

{$APPTYPE CONSOLE}

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

program
  AcrylicTester;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SysUtils,
  Classes,
  IniFiles,
  AbstractUnitTest in 'AbstractUnitTest.pas',
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
  Environment in 'Environment.pas',
  FileStreamLineEx in 'FileStreamLineEx.pas',
  FileTracerAgent in 'FileTracerAgent.pas',
  HitLogger in 'HitLogger.pas',
  HostsCache in 'HostsCache.pas',
  MemoryManager in 'MemoryManager.pas',
  MemoryStore in 'MemoryStore.pas',
  PatternMatching in 'PatternMatching.pas',
  PerlRegEx in 'PerlRegEx.pas',
  SessionCache in 'SessionCache.pas',
  Statistics in 'Statistics.pas',
  Stopwatch in 'Stopwatch.pas',
  Tracer in 'Tracer.pas';

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  TAddressCacheUnitTest_KCacheItems = 750;
  THostsCacheUnitTest_KHostsItems = 1000;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

{$i CommunicationChannelsUnitTest.pas }
{$i SessionCacheUnitTest.pas }
{$i AddressCacheUnitTest.pas }
{$i HostsCacheUnitTest.pas }
{$i RegularExpressionUnitTest.pas }

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

begin

  DecimalSeparator := '.';

  WriteLn('==============================================================================');
  WriteLn('Acrylic DNS Proxy Tester');
  WriteLn('==============================================================================');

  TConfiguration.Initialize; TTracer.Initialize; TTracer.SetTracerAgent(TConsoleTracerAgent.Create);

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'Acrylic version ' + AcrylicVersionNumber + ' released on ' + AcrylicReleaseDate + '.');

  TAbstractUnitTest.ControlTestExecution(TCommunicationChannelsUnitTest.Create);
  TAbstractUnitTest.ControlTestExecution(TSessionCacheUnitTest.Create);
  TAbstractUnitTest.ControlTestExecution(TAddressCacheUnitTest.Create);
  TAbstractUnitTest.ControlTestExecution(THostsCacheUnitTest.Create);
  TAbstractUnitTest.ControlTestExecution(TRegularExpressionUnitTest.Create);

  TTracer.Finalize; TConfiguration.Finalize;

  WriteLn('Press ENTER To Quit.'); ReadLn;

end.
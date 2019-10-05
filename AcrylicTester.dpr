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
  CommonUtils in 'CommonUtils.pas',
  CommunicationChannels in 'CommunicationChannels.pas',
  Configuration in 'Configuration.pas',
  ConsoleTracerAgent in 'ConsoleTracerAgent.pas',
  DnsForwarder in 'DnsForwarder.pas',
  DnsProtocol in 'DnsProtocol.pas',
  DnsResolver in 'DnsResolver.pas',
  Environment in 'Environment.pas',
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
  PerlRegEx in 'PerlRegEx.pas',
  SessionCache in 'SessionCache.pas',
  Tracer in 'Tracer.pas';

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  TAddressCacheUnitTest_KCacheItems = 2000;
  THostsCacheUnitTest_KHostsItems = 2000;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

{$I MD5UnitTest.pas }
{$I CommunicationChannelsUnitTest.pas }
{$I SessionCacheUnitTest.pas }
{$I AddressCacheUnitTest.pas }
{$I HostsCacheUnitTest.pas }
{$I RegularExpressionUnitTest.pas }

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

  TAbstractUnitTest.ControlTestExecution(TMD5UnitTest.Create);
  TAbstractUnitTest.ControlTestExecution(TCommunicationChannelsUnitTest.Create);
  TAbstractUnitTest.ControlTestExecution(TSessionCacheUnitTest.Create);
  TAbstractUnitTest.ControlTestExecution(TAddressCacheUnitTest.Create);
  TAbstractUnitTest.ControlTestExecution(THostsCacheUnitTest.Create);
  TAbstractUnitTest.ControlTestExecution(TRegularExpressionUnitTest.Create);

  TTracer.Finalize; TConfiguration.Finalize;

  WriteLn('Press ENTER To Quit.'); ReadLn;

end.
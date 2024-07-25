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
  CommonUtils in 'CommonUtils.pas',
  CommunicationChannels in 'CommunicationChannels.pas',
  Configuration in 'Configuration.pas',
  ConsoleTracerAgent in 'ConsoleTracerAgent.pas',
  DnsForwarder in 'DnsForwarder.pas',
  DnsOverHttpsCache in 'DnsOverHttpsCache.pas',
  DnsProtocol in 'DnsProtocol.pas',
  DnsResolver in 'DnsResolver.pas',
  Environment in 'Environment.pas',
  FileIO in 'FileIO.pas',
  FileStreamLineEx in 'FileStreamLineEx.pas',
  FileTracerAgent in 'FileTracerAgent.pas',
  HitLogger in 'HitLogger.pas',
  HostsCache in 'HostsCache.pas',
  HostsCacheBinaryTrees in 'HostsCacheBinaryTrees.pas',
  IPUtils in 'IPUtils.pas',
  MD5 in 'MD5.pas',
  MemoryManager in 'MemoryManager.pas',
  MemoryStore in 'MemoryStore.pas',
  PatternMatching in 'PatternMatching.pas',
  PerlRegEx in 'PerlRegEx.pas',
  SessionCache in 'SessionCache.pas',
  Tracer in 'Tracer.pas',
  WinHttp in 'WinHttp.pas',
  WinSock in 'WinSock.pas';

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  AllTestsSucceeded: Boolean;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

{$I MD5UnitTest.pas }
{$I CommunicationChannelsUnitTest.pas }
{$I DnsOverHttpsCacheUnitTest.pas }
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

  AllTestsSucceeded := False;

  if TAbstractUnitTest.ControlTestExecution(TMD5UnitTest.Create) then
    if TAbstractUnitTest.ControlTestExecution(TCommunicationChannelsUnitTest.Create) then
      if TAbstractUnitTest.ControlTestExecution(TDnsOverHttpsCacheUnitTest.Create) then
        if TAbstractUnitTest.ControlTestExecution(TSessionCacheUnitTest.Create) then
          if TAbstractUnitTest.ControlTestExecution(TAddressCacheUnitTest.Create) then
            if TAbstractUnitTest.ControlTestExecution(THostsCacheUnitTest.Create) then
              if TAbstractUnitTest.ControlTestExecution(TRegularExpressionUnitTest.Create) then
                AllTestsSucceeded := True;

  if TTracer.IsEnabled then if AllTestsSucceeded then TTracer.Trace(TracePriorityInfo, 'ALL TESTS SUCCEEDED!') else TTracer.Trace(TracePriorityInfo, 'AT LEAST ONE TEST FAILED!');

  TTracer.Finalize; TConfiguration.Finalize;

  if AllTestsSucceeded then ExitCode := 0 else ExitCode := 1;

end.
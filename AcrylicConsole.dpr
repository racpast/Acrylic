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
  SysUtils,
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
  EnvironmentVariables in 'EnvironmentVariables.pas',
  FileStreamLineEx in 'FileStreamLineEx.pas',
  FileTracerAgent in 'FileTracerAgent.pas',
  HitLogger in 'HitLogger.pas',
  HostsCache in 'HostsCache.pas',
  MemoryManager in 'MemoryManager.pas',
  MemoryStore in 'MemoryStore.pas',
  PatternMatching in 'PatternMatching.pas',
  PCRE in 'PCRE.pas',
  PerlRegEx in 'PerlRegEx.pas',
  SessionCache in 'SessionCache.pas',
  Tracer in 'Tracer.pas',
  Statistics in 'Statistics.pas',
  Stopwatch in 'Stopwatch.pas';

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function GetBooleanCommandLineParamValue(ParamName: String): Boolean;

var
  i: Integer;

begin

  for i := 1 to ParamCount do if (ParamStr(i) = '/' + ParamName) then begin Result := True; Exit; end; Result := False;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  NoLog: Boolean;
  NoBanner: Boolean;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

begin

  DecimalSeparator := '.';

  if ((ParamCount = 1) and (ParamStr(1) = '/?')) then begin

    WriteLn('==============================================================================');
    WriteLn('Acrylic DNS Proxy Console');
    WriteLn('==============================================================================');
    WriteLn;
    WriteLn('Usage:');
    WriteLn('  AcrylicConsole.exe [/NoBanner] [/NoLog]');
    WriteLn;
    WriteLn('Options:');
    WriteLn('  /NoBanner');
    WriteLn('    Does not write the application banner to the console on startup.');
    WriteLn('  /NoLog');
    WriteLn('    Does not write the application log to the console while running.');
    WriteLn;
    WriteLn('Examples:');
    WriteLn('  AcrylicConsole.exe');
    WriteLn('  AcrylicConsole.exe /NoBanner /NoLog');

    Exit;

  end;

  NoLog := GetBooleanCommandLineParamValue('NoLog');
  NoBanner := GetBooleanCommandLineParamValue('NoBanner');

  if not NoBanner then begin

    WriteLn('==============================================================================');
    WriteLn('Acrylic DNS Proxy Console                                  Press ENTER To Quit');
    WriteLn('==============================================================================');

  end;

  TConfiguration.Initialize; TTracer.Initialize; if not(NoLog) then TTracer.SetTracerAgent(TConsoleTracerAgent.Create);

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'Acrylic version is ' + AcrylicVersionNumber + ' released on ' + AcrylicReleaseDate + '.');

  TBootstrapper.StartSystem;

  ReadLn; // Wait until the ENTER key is pressed

  TBootstrapper.StopSystem;

  TTracer.Finalize; TConfiguration.Finalize;

end.
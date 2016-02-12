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
  // Init stuff
  DecimalSeparator := '.';

  // Parse command line params
  NoLog := GetBooleanCommandLineParamValue('NoLog');
  NoBanner := GetBooleanCommandLineParamValue('NoBanner');

  if (not(NoBanner)) then begin

    WriteLn('==============================================================================');
    WriteLn('Acrylic DNS Proxy Console Version                          Press ENTER To Quit');
    WriteLn('==============================================================================');

  end;

  // Initialize all the static classes and set the console tracer agent
  TConfiguration.Initialize; TTracer.Initialize; if not(NoLog) then TTracer.SetTracerAgent(TConsoleTracerAgent.Create);

  // Trace Acrylic version info if a tracer is enabled
  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'Acrylic version is ' + AcrylicVersionNumber + ' released on ' + AcrylicReleaseDate + '.');

  // Start the system using a bootstrapper
  TBootstrapper.StartSystem;

  // Wait until the ENTER key is pressed
  ReadLn;

  // Stop the system
  TBootstrapper.StopSystem;

  // Finalize all the static classes
  TTracer.Finalize; TConfiguration.Finalize;
end.
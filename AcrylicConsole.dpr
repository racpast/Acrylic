
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
    SysUtils, Configuration, Tracer, ConsoleTracerAgent, Bootstrapper;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

begin
  WriteLn('==============================================================================');
  WriteLn('Acrylic DNS Proxy Console Version                          Press ENTER To Quit');
  WriteLn('==============================================================================');

  // Init...
  DecimalSeparator := '.';

  // Start the config and set the tracer agent
  TConfiguration.Initialize(); TTracer.Initialize(); TTracer.SetTracerAgent(TConsoleTracerAgent.Create());

  // Start the system using the Bootstrapper
  TBootstrapper.StartSystem();

  // Wait until the ENTER key is pressed
  ReadLn;

  // Stop the system
  TBootstrapper.StopSystem();

  // Unset stuff
  TTracer.Finalize(); TConfiguration.Finalize();

end.

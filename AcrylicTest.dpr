
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
  SysUtils, Classes, Configuration, Tracer, ConsoleTracerAgent, AbstractUnitTest, ClientServerSocket, SessionCache, AddressCache, HostsCache, Bootstrapper, Digest;

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
  WriteLn('Welcome to the Acrylic test application!');
  WriteLn('==============================================================================');

  // Initialize the config, tracer and set the console agent
  TConfiguration.Initialize(); TTracer.Initialize(); TTracer.SetTracerAgent(TConsoleTracerAgent.Create);

  // Perform all the tests sequentially
  TAbstractUnitTest.ControlTestExecution(TClientServerSocketUnitTest.Create);
  TAbstractUnitTest.ControlTestExecution(TSessionCacheUnitTest.Create);
  TAbstractUnitTest.ControlTestExecution(TAddressCacheUnitTest.Create);
  TAbstractUnitTest.ControlTestExecution(THostsCacheUnitTest.Create);

  // Perform the final test
  TAbstractUnitTest.ControlTestExecution(TBootstrapperUnitTest.Create);

  // Finalize everything
  TTracer.Finalize(); TConfiguration.Finalize();

  WriteLn('Press ENTER to terminate the application.'); ReadLn;
end.
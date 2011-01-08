
// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TBootstrapperUnitTest = class(TAbstractUnitTest)
    public
      procedure ExecuteTest(); override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TBootstrapperUnitTest.ExecuteTest();
begin
  // Starting bootstrapper
  TBootstrapper.StartSystem;

  {
  // Trying to resolve some well known addresses
  if not(TIPAddress.QueryByName('www.whitehouse.gov')) then raise FailedUnitTestException.Create;
  if not(TIPAddress.QueryByName('www.microsoft.com')) then raise FailedUnitTestException.Create;
  if not(TIPAddress.QueryByName('www.google.com')) then raise FailedUnitTestException.Create;
  }

  // Stopping bootstrapper
  TBootstrapper.StopSystem;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

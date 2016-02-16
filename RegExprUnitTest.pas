// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TRegExprUnitTest = class(TAbstractUnitTest)
    public
      constructor Create;
      procedure   ExecuteTest; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TRegExprUnitTest.Create;
begin
  inherited Create;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TRegExprUnitTest.ExecuteTest;
var
  RegExpr: TRegExpr;
begin
  RegExpr := TRegExpr.Create; RegExpr.Expression := '^$'; RegExpr.ModifierI := True;
  if not(RegExpr.Exec('')) then raise FailedUnitTestException.Create;
  if RegExpr.Exec('NO') then raise FailedUnitTestException.Create;
  RegExpr.Free;

  RegExpr := TRegExpr.Create; RegExpr.Expression := '^(19|20)\d\d[- /.](0[1-9]|1[012])[- /.](0[1-9]|[12][0-9]|3[01])$'; RegExpr.ModifierI := True;
  if not(RegExpr.Exec('2099-12-31')) then raise FailedUnitTestException.Create;
  if not(RegExpr.Exec('1976-05-22')) then raise FailedUnitTestException.Create;
  if RegExpr.Exec('2099-19-31') then raise FailedUnitTestException.Create;
  if RegExpr.Exec('NO') then raise FailedUnitTestException.Create;
  if RegExpr.Exec('') then raise FailedUnitTestException.Create;
  RegExpr.Free;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TRegExprUnitTest.Destroy;
begin
  inherited Destroy;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------
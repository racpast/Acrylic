// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TRegularExpressionUnitTest = class(TAbstractUnitTest)
    public
      constructor Create;
      procedure   ExecuteTest; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TRegularExpressionUnitTest.Create;

begin

  inherited Create;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TRegularExpressionUnitTest.ExecuteTest;

var
  RegularExpression: TPerlRegEx;

begin

  RegularExpression := TPerlRegEx.Create; RegularExpression.RegEx := '^(19|20)\d\d[- /.](0[1-9]|1[012])[- /.](0[1-9]|[12][0-9]|3[01])$'; RegularExpression.Options := [preCaseLess]; RegularExpression.Compile;
  RegularExpression.Subject := '2099-12-31'; if not(RegularExpression.Match) then raise FailedUnitTestException.Create;
  RegularExpression.Subject := '1970-05-22'; if not(RegularExpression.Match) then raise FailedUnitTestException.Create;
  RegularExpression.Subject := '2099-19-31'; if RegularExpression.Match then raise FailedUnitTestException.Create;
  RegularExpression.Subject := '9999-12-31'; if RegularExpression.Match then raise FailedUnitTestException.Create;
  RegularExpression.Subject := 'NO'; if RegularExpression.Match then raise FailedUnitTestException.Create;
  RegularExpression.Subject := ''; if RegularExpression.Match then raise FailedUnitTestException.Create;
  RegularExpression.Free;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TRegularExpressionUnitTest.Destroy;

begin

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------
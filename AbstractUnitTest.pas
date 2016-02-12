// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  AbstractUnitTest;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SysUtils;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  EmptyException = class(Exception)
    constructor Create(Msg: String); overload;
    constructor Create; overload;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  FailedUnitTestException = class(EmptyException);
  UndefinedUnitTestException = class(EmptyException);

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TAbstractUnitTest = class
    public
      procedure ExecuteTest; virtual;
    public
      class procedure ControlTestExecution(RealUnitTest: TAbstractUnitTest);
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor EmptyException.Create(Msg: String);
begin
  inherited Create(Msg);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor EmptyException.Create;
begin
  inherited Create('');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TAbstractUnitTest.ExecuteTest;
begin
  raise UndefinedUnitTestException.Create('');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAbstractUnitTest.ControlTestExecution(RealUnitTest: TAbstractUnitTest);
var
  ClassName: String;
begin
  ClassName := RealUnitTest.ClassName; try

    // Trace the beginning
    TTracer.Trace(TracePriorityInfo, ClassName + ': Started...');

    // Execute the real test
    try RealUnitTest.ExecuteTest finally RealUnitTest.Free end;

    // Trace the test result
    TTracer.Trace(TracePriorityInfo, ClassName + ': Succeeded.');

  except

   on FailedUnitTestException do TTracer.Trace(TracePriorityError, ClassName + ': Failed');
   on UndefinedUnitTestException do TTracer.Trace(TracePriorityError, ClassName + ': Undefined class');
   on E: Exception do TTracer.Trace(TracePriorityError, ClassName + ': Failed ' + E.Message);

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
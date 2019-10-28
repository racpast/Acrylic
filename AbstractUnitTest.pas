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
      class function ControlTestExecution(RealUnitTest: TAbstractUnitTest): Boolean;
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

class function TAbstractUnitTest.ControlTestExecution(RealUnitTest: TAbstractUnitTest): Boolean;

var
  ClassName: String;

begin

  Result := False;

  ClassName := RealUnitTest.ClassName; try

    TTracer.Trace(TracePriorityInfo, ClassName + ': Started...');

    try RealUnitTest.ExecuteTest finally RealUnitTest.Free end; Result := True;

    TTracer.Trace(TracePriorityInfo, ClassName + ': Succeeded.');

  except

   on FailedUnitTestException do TTracer.Trace(TracePriorityError, ClassName + ': FAILED!');
   on UndefinedUnitTestException do TTracer.Trace(TracePriorityError, ClassName + ': UNDEFINED CLASS!');
   on E: Exception do TTracer.Trace(TracePriorityError, ClassName + ': FAILED! ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
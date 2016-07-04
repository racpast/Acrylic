// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

program
  AcrylicRegExTester;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SysUtils,
  PerlRegEx;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  RE: TPerlRegEx;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TI: String;
  TE: String;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

begin
  WriteLn('==============================================================================');
  WriteLn('Acrylic DNS Proxy RegEx Tester');
  WriteLn('==============================================================================');

  if ((ParamCount = 1) and (ParamStr(1) = '/?')) or (ParamCount <> 2) then begin

    WriteLn;
    WriteLn('Usage:');
    WriteLn('  AcrylicRegExTester.exe DomainName RegEx');
    WriteLn;
    WriteLn('Examples:');
    WriteLn('  AcrylicRegExTester.exe www.google.com "(?<!cdn\.)google\.com$"');
    WriteLn('  AcrylicRegExTester.exe cdn.google.com "(?<!cdn\.)google\.com$"');

    Exit;

  end;

  TI := ParamStr(1);
  TE := ParamStr(2);

  WriteLn;
  WriteLn('Input: ' + TI);
  WriteLn('Regex: ' + TE);
  WriteLn;

  try

    RE := TPerlRegEx.Create;
    RE.RegEx := TE; RE.Options := [preCaseLess];

    RE.Subject := TI; if RE.Match then WriteLn('Match: YES.') else WriteLn('Match: NO.');

    RE.Free;

  except

    on E: Exception do begin

      WriteLn('Match: ' + E.Message);

    end;
  end;

end.

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

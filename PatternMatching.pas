
// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  PatternMatching;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

type
  TPatternMatching = class
    public
      class function Match(Element: PChar; Pattern: PChar): Boolean;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SysUtils;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TPatternMatching.Match(Element: PChar; Pattern: PChar): Boolean;
begin
  if (StrComp(Pattern, '*') = 0) then Result := True else if (Element^ = Chr(0)) and (Pattern^ <> Chr(0)) then Result := False else if (Element^ = Chr(0)) then Result := True else begin
    case Pattern^ of
      '*': if Match(Element, @Pattern[1]) then Result := True else Result := Match(@Element[1], Pattern);
      '?': Result := Match(@Element[1], @Pattern[1]);
      else if (UpCase(Element^) = UpCase(Pattern^)) then Result := Match(@Element[1], @Pattern[1]) else Result := False;
    end;
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  HostsLineParser;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  THostsLineParser = class
    private
      class function IsComment(Value: Char): boolean;
      class function IsSeparator(Value: Char): boolean;
      class function GetNextFieldContents(var Line: String): String;
    public
      class function Parse(Line: String; var HostName: String; var HostAddress: Integer; var HostExceptions: String): Boolean;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  IPAddress;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function THostsLineParser.IsComment(Value: Char): boolean;
begin
  Result := (Value = '#');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function THostsLineParser.IsSeparator(Value: Char): boolean;
begin
  Result := (Value = #9) or (Value = #32);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function THostsLineParser.GetNextFieldContents(var Line: String): String;
var
  Contents: String;
begin
  // Initialize
  SetLength(Contents, 0);

  // Remove separators at the beginning of the line
  while (Length(Line) > 0) and IsSeparator(Line[1]) do Delete(Line, 1, 1);

  // Find the end of the field contents or the end of line
  while (Length(Line) > 0) and not(IsSeparator(Line[1])) and not(IsComment(Line[1])) do begin Contents := Contents + Line[1]; Delete(Line, 1, 1); end;

  // Return field contents
  Result := Contents;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function THostsLineParser.Parse(Line: String; var HostName: String; var HostAddress: Integer; var HostExceptions: String): Boolean;
var
  Data: String;
begin
  Result := False; if (Length(Line) > 0) then begin // If the string is not empty...
    if not(IsComment(Line[1])) then begin // If it does not start with a comment...

      // Get the IP field
      Data := GetNextFieldContents(Line);

      if (Length(Line) > 0) then begin // If there is something else...

        // Parse the IP field
        HostAddress := TIPAddress.Parse(Data);

        // Get the host name field
        HostName := GetNextFieldContents(Line);

        // Get the host exceptions field
        if (Length(Line) > 0) then HostExceptions := GetNextFieldContents(Line) else SetLength(HostExceptions, 0);

        // Success!
        Result := True;

      end;

    end;
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

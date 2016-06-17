// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  FileStreamLineEx;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Classes;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TFileStreamLineEx = class
    private
      Stream: TStream;
      CurrentLine: String;
    public
      constructor Create(Stream: TStream);
    public
      function    ReadLine(var OutputLine: String): Boolean;
    private
      function    TryFindLineTerminator(CurrentLine: String; var Position, Length: Integer): Boolean;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  LINE_READ_CHUNK = 2048;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TFileStreamLineEx.Create(Stream: TStream);
begin
  Self.Stream := Stream; SetLength(Self.CurrentLine, 0);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TFileStreamLineEx.TryFindLineTerminator(CurrentLine: String; var Position, Length: Integer): Boolean;
var
  i: Integer;
begin
  i := Pos(#13#10, CurrentLine);

  if (i > 0) then begin
    Position := i; Length := 2; Result := True; Exit;
  end;

  i := Pos(#10, CurrentLine);

  if (i > 0) then begin
    Position := i; Length := 1; Result := True; Exit;
  end;

  i := Pos(#13, CurrentLine);

  if (i > 0) then begin
    Position := i; Length := 1; Result := True; Exit;
  end;

  Result := False;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TFileStreamLineEx.ReadLine(var OutputLine: String): Boolean;
var
  Buffer: String; Bytes: Integer; LineTerminatorFound: Boolean; Position, Length: Integer;
begin
  LineTerminatorFound := Self.TryFindLineTerminator(Self.CurrentLine, Position, Length); while not LineTerminatorFound do begin

    SetLength(Buffer, LINE_READ_CHUNK); Bytes := Stream.Read(Buffer[1], LINE_READ_CHUNK); if (Bytes > 0) then begin // If there is data...

      Self.CurrentLine := Self.CurrentLine + Copy(Buffer, 1, Bytes);

      LineTerminatorFound := Self.TryFindLineTerminator(Self.CurrentLine, Position, Length);

    end else begin // There is no data
      Break;
    end;

  end; if LineTerminatorFound then begin

    OutputLine := Copy(Self.CurrentLine, 1, Position - 1); Delete(Self.CurrentLine, 1, Position + Length - 1);

    Result := True;

  end else begin // A line terminator has not been found

    OutputLine := Self.CurrentLine; SetLength(Self.CurrentLine, 0);

    Result := False;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
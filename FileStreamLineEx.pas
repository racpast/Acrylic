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
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

{$ifdef WIN32}
const LINE_TERMINATOR = #13#10;
{$else}
const LINE_TERMINATOR = #10;
{$endif}

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

function TFileStreamLineEx.ReadLine(var OutputLine: String): Boolean;
var
  Buffer: String; Bytes, Position: Integer;
begin
  Position := Pos(LINE_TERMINATOR, CurrentLine); while not(Position > 0) do begin

    SetLength(Buffer, LINE_READ_CHUNK); Bytes := Stream.Read(Buffer[1], LINE_READ_CHUNK); if (Bytes > 0) then begin // If there is data...

      Self.CurrentLine := Self.CurrentLine + Copy(Buffer, 1, Bytes);

      Position := Pos(LINE_TERMINATOR, CurrentLine);

    end else begin // There is no data
      Break;
    end;

  end; if (Position > 0) then begin // If a line terminator has been found...

    OutputLine := Copy(Self.CurrentLine, 1, Position - 1); Delete(Self.CurrentLine, 1, Position + Length(LINE_TERMINATOR) - 1);

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
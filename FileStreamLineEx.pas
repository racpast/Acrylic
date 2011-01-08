
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
      Stream      : TStream;
      CurrentLine : String;
    public
      constructor Create(Stream: TStream);
    public
      function    ReadLine(var Line: String): Boolean;
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

const LINE_READ_CHUNK = 2048;

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

function TFileStreamLineEx.ReadLine(var Line: String): Boolean;
var
  Buffer: String; Bytes, Position: Integer;
begin
  // Find line terminator in the current line
  Position := Pos(LINE_TERMINATOR, CurrentLine); while (Position = 0) do begin

    // Clean the buffer
    SetLength(Buffer, LINE_READ_CHUNK);

    // Read a chunk of data into the buffer
    Bytes := Stream.Read(Buffer[1], LINE_READ_CHUNK); if (Bytes > 0) then begin // If there is data...

      // Append the chunk of data to the current line
      CurrentLine := CurrentLine + Copy(Buffer, 1, Bytes);

      // Find line terminator in the current line
      Position := Pos(LINE_TERMINATOR, CurrentLine);

    end else begin // There is no data
      Break;
    end;

  end; if (Position > 0) then begin // If a line terminator has been found...

    // Output line
    Line := Copy(CurrentLine, 1, Position - 1);

    // Current line
    Delete(CurrentLine, 1, Position + Length(LINE_TERMINATOR) - 1);

    // There should be more lines
    Result := True;

  end else begin // A line terminator has not been found

    // Output line
    Line := CurrentLine;

    // Current line
    SetLength(CurrentLine, 0);

    // There should be no more lines
    Result := False;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

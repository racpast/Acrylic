// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  FileIO;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TFileIO = class
    public
      class function  ReadAllText(FileName: String): String;
      class procedure WriteAllText(FileName: String; Contents: String);
      class procedure AppendAllText(FileName: String; Contents: String);
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  BUFFERED_SEQUENTIAL_STREAM_64KB_BUFFER_SIZE   = 65536;
  BUFFERED_SEQUENTIAL_STREAM_128KB_BUFFER_SIZE  = 131072;
  BUFFERED_SEQUENTIAL_STREAM_256KB_BUFFER_SIZE  = 262144;
  BUFFERED_SEQUENTIAL_STREAM_512KB_BUFFER_SIZE  = 524288;
  BUFFERED_SEQUENTIAL_STREAM_1024KB_BUFFER_SIZE = 1048576;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TBufferedSequentialReadStream = class
    public
      FileSize: Cardinal;
      Position: Cardinal;
    private
      FileHandle: THandle;
      StreamBuffer: Pointer;
      StreamBufferSize: Cardinal;
      StreamBufferPosition: Cardinal;
      StreamBufferBytesRead: Cardinal;
    public
      constructor Create(FileName: String; StreamBufferSize: Cardinal);
      function    Read(var DataBuffer; BytesToRead: Cardinal): Boolean;
      function    Advance(BytesToAdvance: Cardinal): Boolean;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TBufferedSequentialWriteStream = class
    private
      FileHandle: THandle;
      StreamBuffer: Pointer;
      StreamBufferSize: Cardinal;
      StreamBufferPosition: Cardinal;
    public
      constructor Create(FileName: String; Append: Boolean; StreamBufferSize: Cardinal);
      function    Write(const DataBuffer; BytesToWrite: Cardinal): Boolean;
      function    WriteString(const Text: String): Boolean;
      function    Flush: Boolean;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SysUtils,
  Windows,
  MemoryManager;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TFileIO.ReadAllText(FileName: String): String;

var
  FileHandle: THandle; BytesToRead: Cardinal; Contents: String; BytesRead: Cardinal;

begin

  FileHandle := CreateFile(PChar(FileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, 0); if (FileHandle <> INVALID_HANDLE_VALUE) then begin

    try

      BytesToRead := GetFileSize(FileHandle, nil); if (BytesToRead > 0) then begin

        SetLength(Contents, BytesToRead); ReadFile(FileHandle, Contents[1], BytesToRead, BytesRead, nil); if (BytesRead <> BytesToRead) then begin

          raise Exception.Create('Opening file "' + FileName + '" for reading failed.');

        end;

        Result := Contents;

      end else begin

        Result := '';

      end;

    finally

      CloseHandle(FileHandle);

    end;

  end else begin

    raise Exception.Create('Reading from file "' + FileName + '" failed.');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TFileIO.WriteAllText(FileName: String; Contents: String);

var
  FileHandle: THandle; BytesToWrite: Cardinal; BytesWritten: Cardinal;

begin

  BytesToWrite := Length(Contents); FileHandle := CreateFile(PChar(FileName), GENERIC_WRITE, FILE_SHARE_READ, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0); if (FileHandle <> INVALID_HANDLE_VALUE) then begin

    try

      WriteFile(FileHandle, Contents[1], BytesToWrite, BytesWritten, nil); if (BytesWritten <> BytesToWrite) then begin

        raise Exception.Create('Opening file "' + FileName + '" for writing failed.');

      end;

    finally

      CloseHandle(FileHandle);

    end;

  end else begin

    raise Exception.Create('Writing to file "' + FileName + '" failed.');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TFileIO.AppendAllText(FileName: String; Contents: String);

var
  FileHandle: THandle; BytesToWrite: Cardinal; BytesWritten: Cardinal;

begin

  BytesToWrite := Length(Contents); FileHandle := CreateFile(PChar(FileName), GENERIC_WRITE, FILE_SHARE_READ, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0); if (FileHandle <> INVALID_HANDLE_VALUE) then begin

    try

      SetFilePointer(FileHandle, 0, nil, FILE_END); WriteFile(FileHandle, Contents[1], BytesToWrite, BytesWritten, nil); if (BytesWritten <> BytesToWrite) then begin

        raise Exception.Create('Opening file "' + FileName + '" for writing failed.');

      end;

    finally

      CloseHandle(FileHandle);

    end;

  end else begin

    raise Exception.Create('Writing to file "' + FileName + '" failed.');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TBufferedSequentialReadStream.Create(FileName: String; StreamBufferSize: Cardinal);

begin

  Self.StreamBuffer := TMemoryManager.GetMemory(StreamBufferSize); Self.StreamBufferSize := StreamBufferSize;

  Self.FileHandle := CreateFile(PChar(FileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, 0); if not(Self.FileHandle <> INVALID_HANDLE_VALUE) then begin

    raise Exception.Create('Opening file "' + FileName + '" for reading failed.');

  end;

  Self.FileSize := GetFileSize(Self.FileHandle, nil);

  ReadFile(Self.FileHandle, Self.StreamBuffer^, Self.StreamBufferSize, Self.StreamBufferBytesRead, nil);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TBufferedSequentialReadStream.Read(var DataBuffer; BytesToRead: Cardinal): Boolean;

var
  StreamBufferBytesLeft: Cardinal; BytesLeftToRead: Cardinal;

begin

  if (BytesToRead > 0) then begin

    StreamBufferBytesLeft := Self.StreamBufferBytesRead - Self.StreamBufferPosition;

    if (StreamBufferBytesLeft > 0) then begin

      if (BytesToRead > StreamBufferBytesLeft) then begin

        Move(Pointer(Cardinal(Self.StreamBuffer) + Self.StreamBufferPosition)^, DataBuffer, StreamBufferBytesLeft); Inc(Self.Position, StreamBufferBytesLeft);

        if (Self.StreamBufferBytesRead < Self.StreamBufferSize) then begin

          Self.StreamBufferPosition := Self.StreamBufferBytesRead;

          Result := False;

        end else begin

          ReadFile(Self.FileHandle, Self.StreamBuffer^, Self.StreamBufferSize, Self.StreamBufferBytesRead, nil);

          if (Self.StreamBufferBytesRead > 0) then begin

            BytesLeftToRead := BytesToRead - StreamBufferBytesLeft;

            if (BytesLeftToRead > Self.StreamBufferBytesRead) then begin

              Move(Self.StreamBuffer^, Pointer(Cardinal(@DataBuffer) + StreamBufferBytesLeft)^, Self.StreamBufferBytesRead); Inc(Self.Position, Self.StreamBufferBytesRead);

              Self.StreamBufferPosition := Self.StreamBufferBytesRead;

              Result := False;

            end else begin

              Move(Self.StreamBuffer^, Pointer(Cardinal(@DataBuffer) + StreamBufferBytesLeft)^, BytesLeftToRead); Inc(Self.Position, BytesLeftToRead);

              Self.StreamBufferPosition := BytesLeftToRead;

              Result := True;

            end;

          end else begin

            Self.StreamBufferPosition := 0;

            Result := False;

          end;

        end;

      end else begin

        Move(Pointer(Cardinal(Self.StreamBuffer) + Self.StreamBufferPosition)^, DataBuffer, BytesToRead); Inc(Self.Position, BytesToRead);

        Inc(Self.StreamBufferPosition, BytesToRead);

        Result := True;

      end;

    end else begin

      if (Self.StreamBufferBytesRead < Self.StreamBufferSize) then begin

        Self.StreamBufferPosition := 0;

        Result := False;

      end else begin

        ReadFile(Self.FileHandle, Self.StreamBuffer^, Self.StreamBufferSize, Self.StreamBufferBytesRead, nil);

        if (Self.StreamBufferBytesRead > 0) then begin

          BytesLeftToRead := BytesToRead;

          if (BytesLeftToRead > Self.StreamBufferBytesRead) then begin

            Move(Self.StreamBuffer^, DataBuffer, Self.StreamBufferBytesRead); Inc(Self.Position, Self.StreamBufferBytesRead);

            Self.StreamBufferPosition := Self.StreamBufferBytesRead;

            Result := False;

          end else begin

            Move(Self.StreamBuffer^, DataBuffer, BytesLeftToRead); Inc(Self.Position, BytesLeftToRead);

            Self.StreamBufferPosition := BytesLeftToRead;

            Result := True;

          end;

        end else begin

          Self.StreamBufferPosition := 0;

          Result := False;

        end;

      end;

    end;

  end else begin

    Result := False;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TBufferedSequentialReadStream.Advance(BytesToAdvance: Cardinal): Boolean;

var
  StreamBufferBytesLeft: Cardinal; BytesLeftToAdvance: Cardinal;

begin

  if (BytesToAdvance > 0) then begin

    StreamBufferBytesLeft := Self.StreamBufferBytesRead - Self.StreamBufferPosition;

    if (StreamBufferBytesLeft > 0) then begin

      if (BytesToAdvance > StreamBufferBytesLeft) then begin

        Inc(Self.Position, StreamBufferBytesLeft);

        if (Self.StreamBufferBytesRead < Self.StreamBufferSize) then begin

          Self.StreamBufferPosition := Self.StreamBufferBytesRead;

          Result := False;

        end else begin

          ReadFile(Self.FileHandle, Self.StreamBuffer^, Self.StreamBufferSize, Self.StreamBufferBytesRead, nil);

          if (Self.StreamBufferBytesRead > 0) then begin

            BytesLeftToAdvance := BytesToAdvance - StreamBufferBytesLeft;

            if (BytesLeftToAdvance > Self.StreamBufferBytesRead) then begin

              Inc(Self.Position, Self.StreamBufferBytesRead);

              Self.StreamBufferPosition := Self.StreamBufferBytesRead;

              Result := False;

            end else begin

              Inc(Self.Position, BytesLeftToAdvance);

              Self.StreamBufferPosition := BytesLeftToAdvance;

              Result := True;

            end;

          end else begin

            Self.StreamBufferPosition := 0;

            Result := False;

          end;

        end;

      end else begin

        Inc(Self.Position, BytesToAdvance);

        Inc(Self.StreamBufferPosition, BytesToAdvance);

        Result := True;

      end;

    end else begin

      if (Self.StreamBufferBytesRead < Self.StreamBufferSize) then begin

        Self.StreamBufferPosition := 0;

        Result := False;

      end else begin

        ReadFile(Self.FileHandle, Self.StreamBuffer^, Self.StreamBufferSize, Self.StreamBufferBytesRead, nil);

        if (Self.StreamBufferBytesRead > 0) then begin

          BytesLeftToAdvance := BytesToAdvance;

          if (BytesLeftToAdvance > Self.StreamBufferBytesRead) then begin

            Inc(Self.Position, Self.StreamBufferBytesRead);

            Self.StreamBufferPosition := Self.StreamBufferBytesRead;

            Result := False;

          end else begin

            Inc(Self.Position, BytesLeftToAdvance);

            Self.StreamBufferPosition := BytesLeftToAdvance;

            Result := True;

          end;

        end else begin

          Self.StreamBufferPosition := 0;

          Result := False;

        end;

      end;

    end;

  end else begin

    Result := False;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TBufferedSequentialReadStream.Destroy;

begin

  if (Self.FileHandle <> INVALID_HANDLE_VALUE) then begin

    CloseHandle(Self.FileHandle);

  end;

  TMemoryManager.FreeMemory(Self.StreamBuffer, Self.StreamBufferSize);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TBufferedSequentialWriteStream.Create(FileName: String; Append: Boolean; StreamBufferSize: Cardinal);

begin

  Self.StreamBuffer := TMemoryManager.GetMemory(StreamBufferSize); Self.StreamBufferSize := StreamBufferSize;

  if Append then begin

    Self.FileHandle := CreateFile(PChar(FileName), GENERIC_WRITE, FILE_SHARE_READ, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0); if not(Self.FileHandle <> INVALID_HANDLE_VALUE) then begin

      raise Exception.Create('Opening file "' + FileName + '" for writing failed.');

    end;

    SetFilePointer(Self.FileHandle, 0, nil, FILE_END);

  end else begin

    Self.FileHandle := CreateFile(PChar(FileName), GENERIC_WRITE, FILE_SHARE_READ, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0); if not(Self.FileHandle <> INVALID_HANDLE_VALUE) then begin

      raise Exception.Create('Opening file "' + FileName + '" for writing failed.');

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TBufferedSequentialWriteStream.Write(const DataBuffer; BytesToWrite: Cardinal): Boolean;

var
  StreamBufferBytesLeft: Cardinal; BytesWritten: Cardinal; BytesLeftToWrite: Cardinal;

begin

  StreamBufferBytesLeft := Self.StreamBufferSize - Self.StreamBufferPosition;

  if (StreamBufferBytesLeft > 0) then begin

    if (BytesToWrite > StreamBufferBytesLeft) then begin

      Move(DataBuffer, Pointer(Cardinal(Self.StreamBuffer) + Self.StreamBufferPosition)^, StreamBufferBytesLeft);

      WriteFile(Self.FileHandle, Self.StreamBuffer^, Self.StreamBufferSize, BytesWritten, nil);

      if (BytesWritten < Self.StreamBufferSize) then begin

        Self.StreamBufferPosition := Self.StreamBufferSize;

        Result := False;

        Exit;

      end;

      BytesLeftToWrite := BytesToWrite - StreamBufferBytesLeft;

      Move(Pointer(Cardinal(@DataBuffer) + StreamBufferBytesLeft)^, Self.StreamBuffer^, BytesLeftToWrite);

      Self.StreamBufferPosition := BytesLeftToWrite;

    end else begin

      Move(DataBuffer, Pointer(Cardinal(Self.StreamBuffer) + Self.StreamBufferPosition)^, BytesToWrite);

      Inc(Self.StreamBufferPosition, BytesToWrite);

    end;

  end else begin

    WriteFile(Self.FileHandle, Self.StreamBuffer^, Self.StreamBufferSize, BytesWritten, nil);

    if (BytesWritten < Self.StreamBufferSize) then begin

      Self.StreamBufferPosition := Self.StreamBufferSize;

      Result := False;

      Exit;

    end;

    Move(DataBuffer, Self.StreamBuffer^, BytesToWrite);

    Self.StreamBufferPosition := BytesToWrite;

  end;

  Result := True;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TBufferedSequentialWriteStream.WriteString(const Text: String): Boolean;

begin

  Result := Self.Write(Text[1], Length(Text));

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TBufferedSequentialWriteStream.Flush: Boolean;

var
  BytesWritten: Cardinal;

begin

  if (Self.StreamBufferPosition > 0) then begin

    WriteFile(Self.FileHandle, Self.StreamBuffer^, Self.StreamBufferPosition, BytesWritten, nil);

    if (BytesWritten < Self.StreamBufferPosition) then begin

      Result := False;

      Exit;

    end;

  end;

  Result := True;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TBufferedSequentialWriteStream.Destroy;

begin

  if (Self.FileHandle <> INVALID_HANDLE_VALUE) then begin

    CloseHandle(Self.FileHandle);

  end;

  if (Self.StreamBuffer <> nil) then begin

    TMemoryManager.FreeMemory(Self.StreamBuffer, Self.StreamBufferSize);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

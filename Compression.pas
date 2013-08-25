// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  Compression;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TCompression = class
    public
      class function GetBuffer(): Pointer;
      class function GetLength(): Integer;
    public
      class function Inflate(Buffer: Pointer; BufferLen: Integer): Integer;
      class function Deflate(Buffer: Pointer; BufferLen: Integer): Integer;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  COMPRESSION_WORKIN_SIZE = 65536;
  COMPRESSION_BUFFER_SIZE = 16384;
  COMPRESSION_MARGIN_SIZE = 01024;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TCompression_Workin: Pointer;
  TCompression_Buffer: Pointer;
  TCompression_Length: Integer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure _memset(s: Pointer; c: Byte; n: Integer); cdecl;
begin
  FillChar(s^, n, c);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure _memcpy(s1, s2: Pointer; n: Integer); cdecl;
begin
  Move(s2^, s1^, n);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function _memcmp(s1, s2: Pointer; numBytes: Cardinal): Integer; cdecl;
var
  i: Integer; p1, p2: ^Byte;
begin
  p1 := s1; p2 := s2; for i := 0 to numBytes - 1 do begin
    if (p1^ <> p2^) then begin
      if (p1^ < p2^) then Result := -1 else Result := 1; Exit;
    end; Inc(p1); Inc(p2);
  end; Result := 0;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure _memmove(dstP, srcP: Pointer; numBytes: Cardinal); cdecl;
begin
  Move(srcP^, dstP^, numBytes); FreeMem(srcP, numBytes);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

{$LINK 'MiniLzo.obj'}

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function lzo1x_1_compress(const Source: Pointer; SourceLength: Cardinal; Dest: Pointer; var DestLength: Cardinal; WorkMem: Pointer): Integer; stdcall; external;
function lzo1x_decompress(const Source: Pointer; SourceLength: Cardinal; Dest: Pointer; var DestLength: Cardinal; WorkMem: Pointer): Integer; stdcall; external;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TCompression.GetBuffer(): Pointer;
begin
  Result := TCompression_Buffer;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TCompression.GetLength(): Integer;
begin
  Result := TCompression_Length;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TCompression.Inflate(Buffer: Pointer; BufferLen: Integer): Integer;
begin
  if (BufferLen <= (COMPRESSION_BUFFER_SIZE - COMPRESSION_MARGIN_SIZE)) then begin // If the buffer is not too large...

    // Allocate the working buffer if needed
    if (TCompression_Workin = nil) then GetMem(TCompression_Workin, COMPRESSION_WORKIN_SIZE);

    // Allocate the compression buffer if needed
    if (TCompression_Buffer = nil) then GetMem(TCompression_Buffer, COMPRESSION_BUFFER_SIZE);

    // Compress the data and put the results into the compression buffer
    lzo1x_1_compress(Buffer, Cardinal(BufferLen), TCompression_Buffer, Cardinal(TCompression_Length), TCompression_Workin);

    // Return the compressed size
    Result := TCompression_Length;

  end else begin // The buffer is too large and can't be compressed!

    // Return an invalid size
    Result := -1;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TCompression.Deflate(Buffer: Pointer; BufferLen: Integer): Integer;
begin
  // Allocate the compression buffer if needed
  if (TCompression_Buffer = nil) then GetMem(TCompression_Buffer, COMPRESSION_BUFFER_SIZE);

  // Compress the data and put the results into the compression buffer
  lzo1x_decompress(Buffer, Cardinal(BufferLen), TCompression_Buffer, Cardinal(TCompression_Length), nil);

  // Return the uncompressed size
  Result := TCompression_Length;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

initialization
  TCompression_Buffer := nil;
end.
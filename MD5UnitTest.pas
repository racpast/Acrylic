// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TMD5UnitTest = class(TAbstractUnitTest)
    private
      Buffer: Pointer;
      BufferLen: Integer;
    public
      constructor Create;
      procedure   ExecuteTest; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TMD5UnitTest.Create;

begin

  inherited Create;

  Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_PACKET_LEN);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMD5UnitTest.ExecuteTest;

var
  TimeStamp: TDateTime; InitSeed: Integer; i, j: Integer; MD5Digest: TMD5Digest;

begin

  TimeStamp := Now;

  InitSeed := Round(Frac(TimeStamp) * 8640000.0);

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Verifying with test vectors...');

  Move('The quick brown fox jumps over the lazy dog', Self.Buffer^, 43); MD5Digest := TMD5.Compute(Self.Buffer, 43);

  if (MD5Digest[ 0] <> $9E) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 1] <> $10) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 2] <> $7D) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 3] <> $9D) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 4] <> $37) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 5] <> $2B) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 6] <> $B6) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 7] <> $82) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 8] <> $6B) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 9] <> $D8) then raise FailedUnitTestException.Create;
  if (MD5Digest[10] <> $1D) then raise FailedUnitTestException.Create;
  if (MD5Digest[11] <> $35) then raise FailedUnitTestException.Create;
  if (MD5Digest[12] <> $42) then raise FailedUnitTestException.Create;
  if (MD5Digest[13] <> $A4) then raise FailedUnitTestException.Create;
  if (MD5Digest[14] <> $19) then raise FailedUnitTestException.Create;
  if (MD5Digest[15] <> $D6) then raise FailedUnitTestException.Create;

  Move('abc', Self.Buffer^, 3); MD5Digest := TMD5.Compute(Self.Buffer, 3);

  if (MD5Digest[ 0] <> $90) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 1] <> $01) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 2] <> $50) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 3] <> $98) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 4] <> $3C) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 5] <> $D2) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 6] <> $4F) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 7] <> $B0) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 8] <> $D6) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 9] <> $96) then raise FailedUnitTestException.Create;
  if (MD5Digest[10] <> $3F) then raise FailedUnitTestException.Create;
  if (MD5Digest[11] <> $7D) then raise FailedUnitTestException.Create;
  if (MD5Digest[12] <> $28) then raise FailedUnitTestException.Create;
  if (MD5Digest[13] <> $E1) then raise FailedUnitTestException.Create;
  if (MD5Digest[14] <> $7F) then raise FailedUnitTestException.Create;
  if (MD5Digest[15] <> $72) then raise FailedUnitTestException.Create;

  Move('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq', Self.Buffer^, 56); MD5Digest := TMD5.Compute(Self.Buffer, 56);

  if (MD5Digest[ 0] <> $82) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 1] <> $15) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 2] <> $EF) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 3] <> $07) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 4] <> $96) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 5] <> $A2) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 6] <> $0B) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 7] <> $CA) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 8] <> $AA) then raise FailedUnitTestException.Create;
  if (MD5Digest[ 9] <> $E1) then raise FailedUnitTestException.Create;
  if (MD5Digest[10] <> $16) then raise FailedUnitTestException.Create;
  if (MD5Digest[11] <> $D3) then raise FailedUnitTestException.Create;
  if (MD5Digest[12] <> $87) then raise FailedUnitTestException.Create;
  if (MD5Digest[13] <> $6C) then raise FailedUnitTestException.Create;
  if (MD5Digest[14] <> $66) then raise FailedUnitTestException.Create;
  if (MD5Digest[15] <> $4A) then raise FailedUnitTestException.Create;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Calculating 1 million hashes...');

  RandSeed := InitSeed;

  for i := 0 to 999999 do begin

    BufferLen := Random(MAX_DNS_PACKET_LEN - MIN_DNS_PACKET_LEN + 1) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLen - 1) do PByteArray(Buffer)^[j] := Random(256);

    MD5Digest := TMD5.Compute(Self.Buffer, Self.BufferLen);

  end;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TMD5UnitTest.Destroy;

begin

  TMemoryManager.FreeMemory(Buffer, MAX_DNS_PACKET_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------
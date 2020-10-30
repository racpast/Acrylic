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

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Testing vectors...');

  Move('abc', Self.Buffer^, 3); MD5Digest := TMD5.Compute(Self.Buffer, 3);

  if (MD5Digest[0] <> $98500190) then raise FailedUnitTestException.Create;
  if (MD5Digest[1] <> $B04FD23C) then raise FailedUnitTestException.Create;
  if (MD5Digest[2] <> $7D3F96D6) then raise FailedUnitTestException.Create;
  if (MD5Digest[3] <> $727FE128) then raise FailedUnitTestException.Create;

  Move('xyz', Self.Buffer^, 3); MD5Digest := TMD5.Compute(Self.Buffer, 3);

  if (MD5Digest[0] <> $6FB36FD1) then raise FailedUnitTestException.Create;
  if (MD5Digest[1] <> $78F81109) then raise FailedUnitTestException.Create;
  if (MD5Digest[2] <> $61138c99) then raise FailedUnitTestException.Create;
  if (MD5Digest[3] <> $5E70AF91) then raise FailedUnitTestException.Create;

  Move('1234567890', Self.Buffer^, 10); MD5Digest := TMD5.Compute(Self.Buffer, 10);

  if (MD5Digest[0] <> $FCF107E8) then raise FailedUnitTestException.Create;
  if (MD5Digest[1] <> $2F132DF8) then raise FailedUnitTestException.Create;
  if (MD5Digest[2] <> $CA18B09B) then raise FailedUnitTestException.Create;
  if (MD5Digest[3] <> $9FA13867) then raise FailedUnitTestException.Create;

  Move('The quick brown fox jumps over the lazy dog', Self.Buffer^, 43); MD5Digest := TMD5.Compute(Self.Buffer, 43);

  if (MD5Digest[0] <> $9D7D109E) then raise FailedUnitTestException.Create;
  if (MD5Digest[1] <> $82B62B37) then raise FailedUnitTestException.Create;
  if (MD5Digest[2] <> $351DD86B) then raise FailedUnitTestException.Create;
  if (MD5Digest[3] <> $D619A442) then raise FailedUnitTestException.Create;

  Move('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq', Self.Buffer^, 56); MD5Digest := TMD5.Compute(Self.Buffer, 56);

  if (MD5Digest[0] <> $07EF1582) then raise FailedUnitTestException.Create;
  if (MD5Digest[1] <> $CA0BA296) then raise FailedUnitTestException.Create;
  if (MD5Digest[2] <> $D316E1AA) then raise FailedUnitTestException.Create;
  if (MD5Digest[3] <> $4A666C87) then raise FailedUnitTestException.Create;

  Move('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam in ultrices nulla, sed scelerisque tortor. In hendrerit semper dui interdum lobortis. Nullam aliquet pulvinar ligula sed porta. Duis vitae arcu a augue dignissim venenatis.', Self.Buffer^, 236); MD5Digest := TMD5.Compute(Self.Buffer, 236);

  if (MD5Digest[0] <> $C76BB2F4) then raise FailedUnitTestException.Create;
  if (MD5Digest[1] <> $8F188FE1) then raise FailedUnitTestException.Create;
  if (MD5Digest[2] <> $F2924EB7) then raise FailedUnitTestException.Create;
  if (MD5Digest[3] <> $ACDF3470) then raise FailedUnitTestException.Create;

  Move('Sed dapibus posuere vestibulum. Vivamus sed mollis tellus. Pellentesque ultrices convallis nisl, non congue arcu gravida vitae. Suspendisse tristique dapibus mi ullamcorper tristique. Nam mattis vestibulum quam, nec vehicula felis blandit eu.', Self.Buffer^, 242); MD5Digest := TMD5.Compute(Self.Buffer, 242);

  if (MD5Digest[0] <> $6C98C911) then raise FailedUnitTestException.Create;
  if (MD5Digest[1] <> $E4C6933E) then raise FailedUnitTestException.Create;
  if (MD5Digest[2] <> $5EA02B94) then raise FailedUnitTestException.Create;
  if (MD5Digest[3] <> $23B408E5) then raise FailedUnitTestException.Create;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Calculating hashes...');

  RandSeed := InitSeed;

  for i := 1 to 1000000 do begin

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
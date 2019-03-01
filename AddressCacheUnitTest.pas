// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TAddressCacheUnitTest = class(TAbstractUnitTest)
    private
      BufferA: Pointer;
      BufferB: Pointer;
      BufferC: Pointer;
    private
      BufferLenA: Integer;
      BufferLenB: Integer;
      BufferLenC: Integer;
    public
      constructor  Create;
      procedure    ExecuteTest; override;
      destructor   Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TAddressCacheUnitTest.Create;

begin

  inherited Create;

  Self.BufferA := TMemoryManager.GetMemory(MAX_DNS_PACKET_LEN);
  Self.BufferB := TMemoryManager.GetMemory(MAX_DNS_PACKET_LEN);
  Self.BufferC := TMemoryManager.GetMemory(MAX_DNS_PACKET_LEN);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TAddressCacheUnitTest.ExecuteTest;

var
  TimeStamp: TDateTime; InitSeed: Integer; i, j: Integer;

begin

  TimeStamp := Now;

  InitSeed := Round(Frac(TimeStamp) * 8640000.0);

  TAddressCache.Initialize;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Starting massive insertion...');

  RandSeed := InitSeed;

  for i := 0 to ((1000 * TAddressCacheUnitTest_KCacheItems) - 1) do begin

    BufferLenA := Random(512) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLenA - 1) do PByteArray(BufferA)^[j] := Random(256);
    BufferLenB := Random(512) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLenB - 1) do PByteArray(BufferB)^[j] := Random(256);

    TAddressCache.Add(TimeStamp, TMD5.Compute(BufferA, BufferLenA), BufferB, BufferLenB, AddressCacheItemOptionsResponseTypeIsPositive);

  end;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Starting massive search...');

  RandSeed := InitSeed;

  for i := 0 to ((1000 * TAddressCacheUnitTest_KCacheItems) - 1) do begin

    BufferLenA := Random(512) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLenA - 1) do PByteArray(BufferA)^[j] := Random(256);
    BufferLenB := Random(512) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLenB - 1) do PByteArray(BufferB)^[j] := Random(256);

    if not((TAddressCache.Find(TimeStamp, TMD5.Compute(BufferA, BufferLenA), BufferC, BufferLenC) = RecentEnough)) then begin
      raise FailedUnitTestException.Create;
    end;

    if (BufferLenC <> BufferLenB) and not(CompareMem(BufferB, BufferC, BufferLenB)) then begin
      raise FailedUnitTestException.Create;
    end;

  end;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Starting saving to file...');

  TAddressCache.SaveToFile(ClassName + '.tmp');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  TAddressCache.Finalize;

  TAddressCache.Initialize;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Starting loading from file...');

  TAddressCache.LoadFromFile(ClassName + '.tmp');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Starting massive search...');

  RandSeed := InitSeed; for i := 0 to ((1000 * TAddressCacheUnitTest_KCacheItems) - 1) do begin

    BufferLenA := Random(512) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLenA - 1) do PByteArray(BufferA)^[j] := Random(256);
    BufferLenB := Random(512) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLenB - 1) do PByteArray(BufferB)^[j] := Random(256);

    if not((TAddressCache.Find(TimeStamp, TMD5.Compute(BufferA, BufferLenA), BufferC, BufferLenC) = RecentEnough)) then begin
      raise FailedUnitTestException.Create;
    end;

    if (BufferLenC <> BufferLenB) and not(CompareMem(BufferB, BufferC, BufferLenB)) then begin
      raise FailedUnitTestException.Create;
    end;

  end;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  TAddressCache.Finalize;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TAddressCacheUnitTest.Destroy;

begin

  TMemoryManager.FreeMemory(BufferA, MAX_DNS_PACKET_LEN);
  TMemoryManager.FreeMemory(BufferB, MAX_DNS_PACKET_LEN);
  TMemoryManager.FreeMemory(BufferC, MAX_DNS_PACKET_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------
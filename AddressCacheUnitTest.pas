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

  TMemoryManager.GetMemory(BufferA, MAX_DNS_PACKET_LEN);
  TMemoryManager.GetMemory(BufferB, MAX_DNS_PACKET_LEN);
  TMemoryManager.GetMemory(BufferC, MAX_DNS_PACKET_LEN);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TAddressCacheUnitTest.ExecuteTest;

var
  i, j: Integer; Time: TDateTime; InitSeed: Integer;

begin

  Time := Now;

  InitSeed := Round(Frac(Time) * 8640000.0);

  TAddressCache.Initialize;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Starting massive insertion...');

  RandSeed := InitSeed; for i := 0 to ((1000 * TAddressCacheUnitTest_KCacheItems) - 1) do begin

    BufferLenA := Random(MAX_DNS_PACKET_LEN - MIN_DNS_PACKET_LEN + 1) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLenA - 1) do PByteArray(BufferA)^[j] := Random(256);
    BufferLenB := Random(MAX_DNS_PACKET_LEN - MIN_DNS_PACKET_LEN + 1) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLenB - 1) do PByteArray(BufferB)^[j] := Random(256);

    TAddressCache.Add(Time, TDigest.ComputeCRC64(BufferA, BufferLenA), BufferB, BufferLenB, (i mod 2) = 1);

  end;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Starting saving to file...');

  TAddressCache.SaveToFile(ClassName + '.tmp');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  TAddressCache.Finalize; TAddressCache.Initialize;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Starting loading from file...');

  TAddressCache.LoadFromFile(ClassName + '.tmp');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Starting massive search...');

  RandSeed := InitSeed; for i := 0 to ((1000 * TAddressCacheUnitTest_KCacheItems) - 1) do begin

    BufferLenA := Random(MAX_DNS_PACKET_LEN - MIN_DNS_PACKET_LEN + 1) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLenA - 1) do PByteArray(BufferA)^[j] := Random(256);
    BufferLenB := Random(MAX_DNS_PACKET_LEN - MIN_DNS_PACKET_LEN + 1) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLenB - 1) do PByteArray(BufferB)^[j] := Random(256);

    if not((TAddressCache.Find(Time, TDigest.ComputeCRC64(BufferA, BufferLenA), BufferC, BufferLenC) = RecentEnough)) then begin
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
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
  i, j: Integer; Time: TDateTime; Seed: Integer; const CacheItems = 750000;
begin
  // Reference
  Time := Now;

  // Init seed
  Seed := Round(Frac(Time) * 8640000.0);

  // Init class
  TAddressCache.Initialize;

  // Trace the event if a tracer is enabled
  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Start massive insertion...');

  RandSeed := Seed; for i := 0 to (CacheItems - 1) do begin

    // Fill buffers
    BufferLenA := Random(MAX_DNS_PACKET_LEN - MIN_DNS_PACKET_LEN + 1) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLenA - 1) do PByteArray(BufferA)^[j] := Random(256);
    BufferLenB := Random(MAX_DNS_PACKET_LEN - MIN_DNS_PACKET_LEN + 1) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLenB - 1) do PByteArray(BufferB)^[j] := Random(256);

    // Insert the item into the address cache
    TAddressCache.Add(Time, TDigest.ComputeCRC64(BufferA, BufferLenA), BufferB, BufferLenB, (i mod 2) = 1);

  end;

  // Trace the event if a tracer is enabled
  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  // Trace the event if a tracer is enabled
  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Start scavenging to file...');

  // Scavenge the address cache to file
  TAddressCache.ScavengeToFile(ClassName + '.tmp');

  // Trace the event if a tracer is enabled
  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  // Finalize and reinit class
  TAddressCache.Finalize; TAddressCache.Initialize;

  // Trace the event if a tracer is enabled
  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Start loading from file...');

  // Load the cache from file
  TAddressCache.LoadFromFile(ClassName + '.tmp');

  // Trace the event if a tracer is enabled
  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  // Trace the event if a tracer is enabled
  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Start massive search...');

  RandSeed := Seed; for i := 0 to (CacheItems - 1) do begin

    // Init buffers
    BufferLenA := Random(MAX_DNS_PACKET_LEN - MIN_DNS_PACKET_LEN + 1) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLenA - 1) do PByteArray(BufferA)^[j] := Random(256);
    BufferLenB := Random(MAX_DNS_PACKET_LEN - MIN_DNS_PACKET_LEN + 1) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLenB - 1) do PByteArray(BufferB)^[j] := Random(256);

    // Search the item from the cache
    if not(TAddressCache.Find(Time, TDigest.ComputeCRC64(BufferA, BufferLenA), BufferC, BufferLenC) = RecentEnough) then raise FailedUnitTestException.Create;

    // Check the response length & contents
    if (BufferLenC <> BufferLenB) and not(CompareMem(BufferB, BufferC, BufferLenB)) then raise FailedUnitTestException.Create;

  end;

  // Trace the event if a tracer is enabled
  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  // Finalize class
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
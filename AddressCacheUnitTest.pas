// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TAddressCacheUnitTest = class(TAbstractUnitTest)
    private
      BufferLenA : Integer;
      BufferLenB : Integer;
      BufferLenC : Integer;
    private
      BufferA    : PByteArray;
      BufferB    : PByteArray;
      BufferC    : PByteArray;
    public
      constructor  Create();
      procedure    ExecuteTest(); override;
      destructor   Destroy(); override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TAddressCacheUnitTest.Create();
begin
  inherited Create;

  GetMem(BufferA, MAX_DNS_PACKET_LEN);
  GetMem(BufferB, MAX_DNS_PACKET_LEN);
  GetMem(BufferC, MAX_DNS_PACKET_LEN);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TAddressCacheUnitTest.ExecuteTest();
var
  i, j: Integer; Time: TDateTime; Seed: Integer; const CacheItems = 5000000;
begin
  Time := Now();

  // Init seed
  Seed := Round(Frac(Time) * 8640000.0);

  // Init class
  TAddressCache.Initialize;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Start massive insertion...');

  RandSeed := Seed; for i := 0 to (CacheItems - 1) do begin

    // Init buffers
    BufferLenA := Random(MAX_DNS_PACKET_LEN - MIN_DNS_PACKET_LEN + 1) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLenA - 1) do BufferA^[j] := Random(256);
    BufferLenB := Random(MAX_DNS_PACKET_LEN - MIN_DNS_PACKET_LEN + 1) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLenB - 1) do BufferB^[j] := Random(256);

    // Insert the item into the cache
    TAddressCache.Add(Time, TDigest.ComputeCRC64(BufferA, BufferLenA), BufferB, BufferLenB, (i mod 2) = 1);

  end;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Start scavenging to file...');

  // Scavenge the cache to file
  TAddressCache.ScavengeToFile(ClassName + '.tmp');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  // Reinitialize the class
  TAddressCache.Finalize(); TAddressCache.Initialize();

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Start loading from file...');

  // Load the cache from file
  TAddressCache.LoadFromFile(ClassName + '.tmp');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Start massive search...');

  RandSeed := Seed; for i := 0 to (CacheItems - 1) do begin

    // Init buffers
    BufferLenA := Random(MAX_DNS_PACKET_LEN - MIN_DNS_PACKET_LEN + 1) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLenA - 1) do BufferA^[j] := Random(256);
    BufferLenB := Random(MAX_DNS_PACKET_LEN - MIN_DNS_PACKET_LEN + 1) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLenB - 1) do BufferB^[j] := Random(256);

    // Search the item into the cache
    if not(TAddressCache.Find(Time, TDigest.ComputeCRC64(BufferA, BufferLenA), BufferC, BufferLenC) = RecentEnough) then raise FailedUnitTestException.Create;

    // Check the response length & contents
    if (BufferLenC <> BufferLenB) and not(CompareMem(BufferB, BufferC, BufferLenB)) then raise FailedUnitTestException.Create;

  end;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  // Finalize class
  TAddressCache.Finalize;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TAddressCacheUnitTest.Destroy();
begin
  FreeMem(BufferA, MAX_DNS_PACKET_LEN);
  FreeMem(BufferB, MAX_DNS_PACKET_LEN);
  FreeMem(BufferC, MAX_DNS_PACKET_LEN);

  inherited Destroy;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------
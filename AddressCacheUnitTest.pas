// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TAddressCacheUnitTest = class(TAbstractUnitTest)
    private
      BufferA: Pointer;
      BufferB: Pointer;
      BufferC: Pointer;
      BufferLenA: Integer;
      BufferLenB: Integer;
      BufferLenC: Integer;
      CacheItems: Integer;
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

  Self.CacheItems := 1000000;

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

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': ' + IntToStr(Self.CacheItems) + ' cache items.');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Starting massive insertion...');

  RandSeed := InitSeed;

  for i := 0 to (Self.CacheItems - 1) do begin

    Self.BufferLenA := Random(512) + MIN_DNS_PACKET_LEN; for j := 0 to (Self.BufferLenA - 1) do PByteArray(Self.BufferA)^[j] := Random(256);
    Self.BufferLenB := Random(512) + MIN_DNS_PACKET_LEN; for j := 0 to (Self.BufferLenB - 1) do PByteArray(Self.BufferB)^[j] := Random(256);

    TAddressCache.AddItem(TimeStamp, TMD5.Compute(Self.BufferA, Self.BufferLenA), Self.BufferB, Self.BufferLenB, AddressCacheItemOptionsResponseTypeIsPositive);

  end;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Starting massive search...');

  RandSeed := InitSeed;

  for i := 0 to (Self.CacheItems - 1) do begin

    Self.BufferLenA := Random(512) + MIN_DNS_PACKET_LEN; for j := 0 to (Self.BufferLenA - 1) do PByteArray(Self.BufferA)^[j] := Random(256);
    Self.BufferLenB := Random(512) + MIN_DNS_PACKET_LEN; for j := 0 to (Self.BufferLenB - 1) do PByteArray(Self.BufferB)^[j] := Random(256);

    if not((TAddressCache.FindItem(TimeStamp, TMD5.Compute(Self.BufferA, Self.BufferLenA), Self.BufferC, Self.BufferLenC) = RecentEnough)) then begin
      raise FailedUnitTestException.Create;
    end;

    if (Self.BufferLenC <> Self.BufferLenB) and not(CompareMem(Self.BufferB, Self.BufferC, Self.BufferLenB)) then begin
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

  RandSeed := InitSeed;

  for i := 0 to (Self.CacheItems - 1) do begin

    Self.BufferLenA := Random(512) + MIN_DNS_PACKET_LEN; for j := 0 to (Self.BufferLenA - 1) do PByteArray(Self.BufferA)^[j] := Random(256);
    Self.BufferLenB := Random(512) + MIN_DNS_PACKET_LEN; for j := 0 to (Self.BufferLenB - 1) do PByteArray(Self.BufferB)^[j] := Random(256);

    if not((TAddressCache.FindItem(TimeStamp, TMD5.Compute(Self.BufferA, Self.BufferLenA), Self.BufferC, Self.BufferLenC) = RecentEnough)) then begin
      raise FailedUnitTestException.Create;
    end;

    if (Self.BufferLenC <> Self.BufferLenB) and not(CompareMem(Self.BufferB, Self.BufferC, Self.BufferLenB)) then begin
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

  TMemoryManager.FreeMemory(Self.BufferC, MAX_DNS_PACKET_LEN);
  TMemoryManager.FreeMemory(Self.BufferB, MAX_DNS_PACKET_LEN);
  TMemoryManager.FreeMemory(Self.BufferA, MAX_DNS_PACKET_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------
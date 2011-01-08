
// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TSessionCacheUnitTest = class(TAbstractUnitTest)
    private
      BufferLen : Integer;
      Buffer    : PByteArray;
    public
      constructor Create();
      procedure   ExecuteTest(); override;
      destructor  Destroy(); override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TSessionCacheUnitTest.Create();
begin
  // Call base
  inherited Create;

  // Initialize locals
  GetMem(Buffer, MAX_DNS_PACKET_LEN);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TSessionCacheUnitTest.ExecuteTest();
var
  i, j: Integer; Seed: Integer; RequestHash: Int64; ClientAddress: Integer; ClientPort: Word; SilentUpdate, CacheException: Boolean; const CacheItems = 65536;
begin
  // Random seed
  Seed := Round(Frac(Now()) * 8640000.0);

  // Load configuration and class
  TConfiguration.Initialize(); TSessionCache.Initialize();

  RandSeed := Seed; for i := 0 to (CacheItems - 1) do begin // Massive item insertion

    // Init buffer
    BufferLen := Random(MAX_DNS_PACKET_LEN - MIN_DNS_PACKET_LEN + 1) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLen - 1) do Buffer^[j] := Random(256);

    // Insert the item into the cache
    TSessionCache.Insert(Word(i), TDigest.ComputeCRC64(Buffer, BufferLen), i, Word(65535 - i), (i mod 2) = 0, (i mod 2) = 1);

  end;

  RandSeed := Seed; for i := 0 to (CacheItems - 1) do begin // Massive item extraction...

    // Init buffer
    BufferLen := Random(MAX_DNS_PACKET_LEN - MIN_DNS_PACKET_LEN + 1) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLen - 1) do Buffer^[j] := Random(256);

    // Extract the item from the cache
    if not(TSessionCache.Extract(Word(i), RequestHash, ClientAddress, ClientPort, SilentUpdate, CacheException)) then raise FailedUnitTestException.Create;

    // Checking request hash, client address, port and flags
    if (RequestHash <> TDigest.ComputeCRC64(Buffer, BufferLen)) or (ClientAddress <> i) or (ClientPort <> Word(65535 - i)) or (SilentUpdate <> ((i mod 2) = 0)) or (CacheException <> ((i mod 2) = 1)) then raise FailedUnitTestException.Create;

  end;

  // Trying to extract a nonexistant item
  if TSessionCache.Extract(0, RequestHash, ClientAddress, ClientPort, SilentUpdate, CacheException) then raise FailedUnitTestException.Create;

  // Finalize class and configuration
  TSessionCache.Finalize(); TConfiguration.Finalize();
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TSessionCacheUnitTest.Destroy();
begin
  // Finalize locals
  FreeMem(Buffer, MAX_DNS_PACKET_LEN);

  // Call base
  inherited Destroy;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------


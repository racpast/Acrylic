// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TSessionCacheUnitTest = class(TAbstractUnitTest)
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

constructor TSessionCacheUnitTest.Create;
begin
  inherited Create;

  TMemoryManager.GetMemory(Buffer, MAX_DNS_PACKET_LEN);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TSessionCacheUnitTest.ExecuteTest;
var
  i, j: Integer; Time: TDateTime; Seed: Integer; RequestHash: Int64; ClientAddress: TDualIPAddress; ClientPort: Word; IsSilentUpdate, IsCacheException: Boolean; const CacheItems = 65536;
begin
  // Reference
  Time := Now;

  // Init seed
  Seed := Round(Frac(Time) * 8640000.0);

  // Init class
  TSessionCache.Initialize;

  RandSeed := Seed; for i := 0 to (CacheItems - 1) do begin // Massive item insertion

    // Fill buffer
    BufferLen := Random(MAX_DNS_PACKET_LEN - MIN_DNS_PACKET_LEN + 1) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLen - 1) do PByteArray(Buffer)^[j] := Random(256);

    // Insert the item into the session cache
    TSessionCache.Insert(Word(i), TDigest.ComputeCRC64(Buffer, BufferLen), TDualIPAddressUtility.CreateFromIPv4Address(i), Word(65535 - i), (i mod 2) = 0, (i mod 2) = 1);

  end;

  RandSeed := Seed; for i := 0 to (CacheItems - 1) do begin // Massive item extraction

    // Fill buffer
    BufferLen := Random(MAX_DNS_PACKET_LEN - MIN_DNS_PACKET_LEN + 1) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLen - 1) do PByteArray(Buffer)^[j] := Random(256);

    // Extract the item from the cache
    if not(TSessionCache.Extract(Word(i), RequestHash, ClientAddress, ClientPort, IsSilentUpdate, IsCacheException)) then raise FailedUnitTestException.Create else TSessionCache.Delete(Word(i));

    // Check the request hash, client address, port and flags
    if (RequestHash <> TDigest.ComputeCRC64(Buffer, BufferLen)) then raise FailedUnitTestException.Create;
    if not TDualIPAddressUtility.AreEqual(ClientAddress, TDualIPAddressUtility.CreateFromIPv4Address(i)) then raise FailedUnitTestException.Create;
    if (ClientPort <> Word(65535 - i)) then raise FailedUnitTestException.Create;
    if (IsSilentUpdate <> ((i mod 2) = 0)) then raise FailedUnitTestException.Create;
    if (IsCacheException <> ((i mod 2) = 1)) then raise FailedUnitTestException.Create;

  end;

  // Try to extract a nonexistant item
  if TSessionCache.Extract(0, RequestHash, ClientAddress, ClientPort, IsSilentUpdate, IsCacheException) then raise FailedUnitTestException.Create;

  // Finalize class
  TSessionCache.Finalize;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TSessionCacheUnitTest.Destroy;
begin
  TMemoryManager.FreeMemory(Buffer, MAX_DNS_PACKET_LEN);

  inherited Destroy;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------
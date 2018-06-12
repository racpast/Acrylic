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

  Time := Now;

  Seed := Round(Frac(Time) * 8640000.0);

  TSessionCache.Initialize;

  RandSeed := Seed; for i := 0 to (CacheItems - 1) do begin

    BufferLen := Random(MAX_DNS_PACKET_LEN - MIN_DNS_PACKET_LEN + 1) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLen - 1) do PByteArray(Buffer)^[j] := Random(256);

    TSessionCache.Insert(Word(i), TDigest.ComputeCRC64(Buffer, BufferLen), TDualIPAddressUtility.CreateFromIPv4Address(i), Word(65535 - i), (i mod 2) = 0, (i mod 2) = 1);

  end;

  RandSeed := Seed; for i := 0 to (CacheItems - 1) do begin

    BufferLen := Random(MAX_DNS_PACKET_LEN - MIN_DNS_PACKET_LEN + 1) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLen - 1) do PByteArray(Buffer)^[j] := Random(256);

    if not(TSessionCache.Extract(Word(i), RequestHash, ClientAddress, ClientPort, IsSilentUpdate, IsCacheException)) then begin
      raise FailedUnitTestException.Create;
    end else TSessionCache.Delete(Word(i));

    if (RequestHash <> TDigest.ComputeCRC64(Buffer, BufferLen)) then begin
      raise FailedUnitTestException.Create;
    end;

    if not(TDualIPAddressUtility.AreEqual(ClientAddress, TDualIPAddressUtility.CreateFromIPv4Address(i))) then begin
      raise FailedUnitTestException.Create;
    end;

    if (ClientPort <> Word(65535 - i)) then begin
      raise FailedUnitTestException.Create;
    end;

    if (IsSilentUpdate <> ((i mod 2) = 0)) then begin
      raise FailedUnitTestException.Create;
    end;

    if (IsCacheException <> ((i mod 2) = 1)) then begin
      raise FailedUnitTestException.Create;
    end;

  end;

  if TSessionCache.Extract(0, RequestHash, ClientAddress, ClientPort, IsSilentUpdate, IsCacheException) then begin
    raise FailedUnitTestException.Create;
  end;

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
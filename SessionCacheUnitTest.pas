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

  Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_PACKET_LEN);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TSessionCacheUnitTest.ExecuteTest;

var
  TimeStamp: TDateTime; InitSeed: Integer; i, j: Integer; OriginalSessionId: Word; RequestHash: TMD5Digest; ClientAddress: TDualIPAddress; ClientPort: Word; IsSilentUpdate, IsCacheException: Boolean; const CacheItems = 65536;

begin

  TimeStamp := Now;

  InitSeed := Round(Frac(TimeStamp) * 8640000.0);

  TSessionCache.Initialize;

  RandSeed := InitSeed;

  for i := 0 to (CacheItems - 1) do begin

    BufferLen := Random(MAX_DNS_PACKET_LEN - MIN_DNS_PACKET_LEN + 1) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLen - 1) do PByteArray(Buffer)^[j] := Random(256);

    TSessionCache.Insert(Time, Word(i), Word(i), TMD5.Compute(Buffer, BufferLen), TDualIPAddressUtility.CreateFromIPv4Address(i), Word(65535 - i), (i mod 2) = 0, (i mod 2) = 1);

  end;

  RandSeed := InitSeed;

  for i := 0 to (CacheItems - 1) do begin

    BufferLen := Random(MAX_DNS_PACKET_LEN - MIN_DNS_PACKET_LEN + 1) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLen - 1) do PByteArray(Buffer)^[j] := Random(256);

    if not(TSessionCache.Extract(Time, OriginalSessionId, Word(i), RequestHash, ClientAddress, ClientPort, IsSilentUpdate, IsCacheException)) then begin
      raise FailedUnitTestException.Create;
    end;

    if (OriginalSessionId <> i) then begin
      raise FailedUnitTestException.Create;
    end;

    TSessionCache.Delete(Word(i));

    if (TMD5.Compare(RequestHash, TMD5.Compute(Buffer, BufferLen)) <> 0) then begin
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

  if TSessionCache.Extract(Time, OriginalSessionId, 0, RequestHash, ClientAddress, ClientPort, IsSilentUpdate, IsCacheException) then begin
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
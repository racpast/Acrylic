// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TDnsOverHttpsCacheUnitTest = class(TAbstractUnitTest)
    private
    public
      constructor Create;
      procedure   ExecuteTest; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TDnsOverHttpsCacheUnitTest.Create;

begin

  inherited Create;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TDnsOverHttpsCacheUnitTest.ExecuteTest;

var
  IPv4AddressA, IPv4AddressB: TIPv4Address; IPv6AddressA, IPv6AddressB: TIPv6Address;

begin

  TDnsOverHttpsCache.Initialize;

  IPv4AddressA := TIPv4AddressUtility.Parse('1.2.3.4');

  TDnsOverHttpsCache.AddIPv4Entry('IPv4Domain1', IPv4AddressA);

  if not(TDnsOverHttpsCache.FindIPv4Entry('IPv4Domain1', IPv4AddressB)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(IPv4AddressA, IPv4AddressB)) then begin
    raise FailedUnitTestException.Create;
  end;

  IPv4AddressA := TIPv4AddressUtility.Parse('254.3.252.1');

  TDnsOverHttpsCache.AddIPv4Entry('IPv4Domain2', IPv4AddressA);

  if not(TDnsOverHttpsCache.FindIPv4Entry('IPv4Domain2', IPv4AddressB)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(IPv4AddressA, IPv4AddressB)) then begin
    raise FailedUnitTestException.Create;
  end;

  IPv6AddressA := TIPv6AddressUtility.Parse('1:2:3:4:5:6');

  TDnsOverHttpsCache.AddIPv6Entry('IPv6Domain1', IPv6AddressA);

  if not(TDnsOverHttpsCache.FindIPv6Entry('IPv6Domain1', IPv6AddressB)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(IPv6AddressA, IPv6AddressB)) then begin
    raise FailedUnitTestException.Create;
  end;

  IPv6AddressA := TIPv6AddressUtility.Parse('254:5:253:3:252:1');

  TDnsOverHttpsCache.AddIPv6Entry('IPv6Domain2', IPv6AddressA);

  if not(TDnsOverHttpsCache.FindIPv6Entry('IPv6Domain2', IPv6AddressB)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(IPv6AddressA, IPv6AddressB)) then begin
    raise FailedUnitTestException.Create;
  end;

  TDnsOverHttpsCache.Finalize;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TDnsOverHttpsCacheUnitTest.Destroy;

begin

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------
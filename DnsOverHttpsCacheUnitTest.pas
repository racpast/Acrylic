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
  IPv4AddressX, IPv4AddressA, IPv4AddressB, IPv4AddressC, IPv4AddressD, IPv4AddressE, IPv4AddressF, IPv4AddressG, IPv4AddressH, IPv4AddressI, IPv4AddressJ: TIPv4Address; IPv6AddressX, IPv6AddressA, IPv6AddressB, IPv6AddressC, IPv6AddressD, IPv6AddressE, IPv6AddressF, IPv6AddressG, IPv6AddressH, IPv6AddressI, IPv6AddressJ: TIPv6Address;

begin

  TDnsOverHttpsCache.Initialize;

  IPv4AddressA := TIPv4AddressUtility.Parse('51.15.98.97');     TDnsOverHttpsCache.AddIPv4Entry('dns.lchimp.com', IPv4AddressA);
  IPv4AddressB := TIPv4AddressUtility.Parse('149.112.112.10');  TDnsOverHttpsCache.AddIPv4Entry('dns10.quad9.net', IPv4AddressB);
  IPv4AddressC := TIPv4AddressUtility.Parse('136.144.215.158'); TDnsOverHttpsCache.AddIPv4Entry('doh.powerdns.org', IPv4AddressC);
  IPv4AddressD := TIPv4AddressUtility.Parse('159.69.198.101');  TDnsOverHttpsCache.AddIPv4Entry('doh-de.blahdns.com', IPv4AddressD);
  IPv4AddressE := TIPv4AddressUtility.Parse('88.198.161.8');    TDnsOverHttpsCache.AddIPv4Entry('doh.dnswarden.com', IPv4AddressE);
  IPv4AddressF := TIPv4AddressUtility.Parse('146.185.167.43');  TDnsOverHttpsCache.AddIPv4Entry('doh.securedns.eu', IPv4AddressF);
  IPv4AddressG := TIPv4AddressUtility.Parse('116.203.115.192'); TDnsOverHttpsCache.AddIPv4Entry('doh.libredns.gr', IPv4AddressG);
  IPv4AddressH := TIPv4AddressUtility.Parse('37.252.185.229');  TDnsOverHttpsCache.AddIPv4Entry('doh.applied-privacy.net', IPv4AddressH);
  IPv4AddressI := TIPv4AddressUtility.Parse('185.95.218.43');   TDnsOverHttpsCache.AddIPv4Entry('dns.digitale-gesellschaft.ch', IPv4AddressI);
  IPv4AddressJ := TIPv4AddressUtility.Parse('83.77.85.7');      TDnsOverHttpsCache.AddIPv4Entry('ibksturm.synology.me', IPv4AddressJ);

  if not(TDnsOverHttpsCache.FindIPv4Entry('dns.lchimp.com', IPv4AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(IPv4AddressA, IPv4AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TDnsOverHttpsCache.FindIPv4Entry('dns10.quad9.net', IPv4AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(IPv4AddressB, IPv4AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TDnsOverHttpsCache.FindIPv4Entry('doh.powerdns.org', IPv4AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(IPv4AddressC, IPv4AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TDnsOverHttpsCache.FindIPv4Entry('doh-de.blahdns.com', IPv4AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(IPv4AddressD, IPv4AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TDnsOverHttpsCache.FindIPv4Entry('doh.dnswarden.com', IPv4AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(IPv4AddressE, IPv4AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TDnsOverHttpsCache.FindIPv4Entry('doh.securedns.eu', IPv4AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(IPv4AddressF, IPv4AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TDnsOverHttpsCache.FindIPv4Entry('doh.libredns.gr', IPv4AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(IPv4AddressG, IPv4AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TDnsOverHttpsCache.FindIPv4Entry('doh.applied-privacy.net', IPv4AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(IPv4AddressH, IPv4AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TDnsOverHttpsCache.FindIPv4Entry('dns.digitale-gesellschaft.ch', IPv4AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(IPv4AddressI, IPv4AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TDnsOverHttpsCache.FindIPv4Entry('ibksturm.synology.me', IPv4AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(IPv4AddressJ, IPv4AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  IPv6AddressA := TIPv6AddressUtility.Parse('1:2:3:4:5:6');       TDnsOverHttpsCache.AddIPv6Entry('dns.lchimp.com', IPv6AddressA);
  IPv6AddressB := TIPv6AddressUtility.Parse('254:5:253:3:252:1'); TDnsOverHttpsCache.AddIPv6Entry('dns10.quad9.net', IPv6AddressB);
  IPv6AddressC := TIPv6AddressUtility.Parse('1:2:3:4:5:6');       TDnsOverHttpsCache.AddIPv6Entry('doh.powerdns.org', IPv6AddressC);
  IPv6AddressD := TIPv6AddressUtility.Parse('254:5:253:3:252:1'); TDnsOverHttpsCache.AddIPv6Entry('doh-de.blahdns.com', IPv6AddressD);
  IPv6AddressE := TIPv6AddressUtility.Parse('1:2:3:4:5:6');       TDnsOverHttpsCache.AddIPv6Entry('doh.dnswarden.com', IPv6AddressE);
  IPv6AddressF := TIPv6AddressUtility.Parse('254:5:253:3:252:1'); TDnsOverHttpsCache.AddIPv6Entry('doh.securedns.eu', IPv6AddressF);
  IPv6AddressG := TIPv6AddressUtility.Parse('1:2:3:4:5:6');       TDnsOverHttpsCache.AddIPv6Entry('doh.libredns.gr', IPv6AddressG);
  IPv6AddressH := TIPv6AddressUtility.Parse('254:5:253:3:252:1'); TDnsOverHttpsCache.AddIPv6Entry('doh.applied-privacy.net', IPv6AddressH);
  IPv6AddressI := TIPv6AddressUtility.Parse('1:2:3:4:5:6');       TDnsOverHttpsCache.AddIPv6Entry('dns.digitale-gesellschaft.ch', IPv6AddressI);
  IPv6AddressJ := TIPv6AddressUtility.Parse('254:5:253:3:252:1'); TDnsOverHttpsCache.AddIPv6Entry('ibksturm.synology.me', IPv6AddressJ);

  if not(TDnsOverHttpsCache.FindIPv6Entry('dns.lchimp.com', IPv6AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(IPv6AddressA, IPv6AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TDnsOverHttpsCache.FindIPv6Entry('dns10.quad9.net', IPv6AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(IPv6AddressB, IPv6AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TDnsOverHttpsCache.FindIPv6Entry('doh.powerdns.org', IPv6AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(IPv6AddressC, IPv6AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TDnsOverHttpsCache.FindIPv6Entry('doh-de.blahdns.com', IPv6AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(IPv6AddressD, IPv6AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TDnsOverHttpsCache.FindIPv6Entry('doh.dnswarden.com', IPv6AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(IPv6AddressE, IPv6AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TDnsOverHttpsCache.FindIPv6Entry('doh.securedns.eu', IPv6AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(IPv6AddressF, IPv6AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TDnsOverHttpsCache.FindIPv6Entry('doh.libredns.gr', IPv6AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(IPv6AddressG, IPv6AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TDnsOverHttpsCache.FindIPv6Entry('doh.applied-privacy.net', IPv6AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(IPv6AddressH, IPv6AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TDnsOverHttpsCache.FindIPv6Entry('dns.digitale-gesellschaft.ch', IPv6AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(IPv6AddressI, IPv6AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TDnsOverHttpsCache.FindIPv6Entry('ibksturm.synology.me', IPv6AddressX)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(IPv6AddressJ, IPv6AddressX)) then begin
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
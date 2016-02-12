// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  THostsCacheUnitTest = class(TAbstractUnitTest)
    public
      constructor Create;
      procedure   ExecuteTest; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor THostsCacheUnitTest.Create;
begin
  inherited Create;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure THostsCacheUnitTest.ExecuteTest;
var
  HostsStream: TFileStream; i, j, k: Integer; S: String; IPv4Address: TIPv4Address; IPv6Address: TIPv6Address; HostsBlock: String; HostsEntry: THostsEntry; const KHostsItems = 1000;
begin
  // Init class
  THostsCache.Initialize;

  // Trace the event if a tracer is enabled
  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Start massive insertion...');

  // Open a stream to build a hosts file
  HostsStream := TFileStream.Create(Self.ClassName + '.tmp', fmCreate);

  for i := 0 to (KHostsItems - 1) do begin // Massive item insertion

    SetLength(HostsBlock, 0); for j := 0 to 999 do begin // Fill a block of host items

      k := 1000 * i + j;

      // Generate a unique string
      S := FormatCurr('000000000', k);

      // Generate an IPv4 address
      IPv4Address := k;

      // Add a new line to the hosts block
      HostsBlock := HostsBlock + TIPv4AddressUtility.ToString(IPv4Address) + #32 + 'IPV4DOMAINNAME-' + S + '-A' + #32 + 'IPV4DOMAINNAME-' + S + '-B' + #13#10;

      // Generate an IPv6 address
      IPv6Address[0] := 0; IPv6Address[1] := k and $ff;IPv6Address[2] := 0; IPv6Address[3] := k and $ff;IPv6Address[4] := 0; IPv6Address[5] := k and $ff;IPv6Address[6] := 0; IPv6Address[7] := k and $ff;IPv6Address[8] := 0; IPv6Address[9] := k and $ff;IPv6Address[10] := 0; IPv6Address[11] := k and $ff;IPv6Address[12] := 0; IPv6Address[13] := k and $ff;IPv6Address[14] := 0; IPv6Address[15] := k and $ff;

      // Add a new line to the hosts block
      HostsBlock := HostsBlock + TIPv6AddressUtility.ToString(IPv6Address) + #32 + 'IPV6DOMAINNAME-' + S + '-A' + #32 + 'IPV6DOMAINNAME-' + S + '-B' + #13#10;

    end;

    // Write the block of host items to disk
    HostsStream.Write(HostsBlock[1], Length(HostsBlock));

  end;

  // Add patterns to the list (1)
  S := '127.0.0.1 >IPV4PATTERN-1-127-0-0-1 -NO.IPV4PATTERN-1-127-0-0-1' + #13#10; HostsStream.Write(S[1], Length(S));

  // Add patterns to the list (1)
  S := '::1 >IPV6PATTERN-1-LOCALHOST -NO.IPV6PATTERN-1-LOCALHOST' + #13#10; HostsStream.Write(S[1], Length(S));

  // Add patterns to the list (2)
  S := '127.0.0.1 >IPV4PATTERN-2-127-0-0-1.* -NO.IPV4PATTERN-2-127-0-0-1.TEST' + #13#10; HostsStream.Write(S[1], Length(S));

  // Add patterns to the list (2)
  S := '::1 >IPV6PATTERN-2-LOCALHOST.* -NO.IPV6PATTERN-2-LOCALHOST.TEST' + #13#10; HostsStream.Write(S[1], Length(S));

  // Add patterns to the list (3)
  S := '127.0.0.1 *.IPV4PATTERN-3-127-0-0-1.* -NO.IPV4PATTERN-3-127-0-0-1.TEST' + #13#10; HostsStream.Write(S[1], Length(S));

  // Add patterns to the list (3)
  S := '::1 *.IPV6PATTERN-3-LOCALHOST.* -NO.IPV6PATTERN-3-LOCALHOST.TEST' + #13#10; HostsStream.Write(S[1], Length(S));

  // Add regular expressions to the list (1)
  S := '127.0.0.1 /^.*\.IPV4REGEXP-1-127-0-0-1\..*$ -NO.IPV4REGEXP-1-127-0-0-1.TEST' + #13#10; HostsStream.Write(S[1], Length(S));

  // Add regular expressions to the list (1)
  S := '::1 /^.*\.IPV6REGEXP-1-LOCALHOST\..*$ -NO.IPV6REGEXP-1-LOCALHOST.TEST' + #13#10; HostsStream.Write(S[1], Length(S));

  // Add a dual IP address to the list for testing the query type discrimination algorithm (1)
  S := '127.0.0.1 ZDUALIPDOMAINNAME-A ZDUALIPDOMAINNAME-B ZDUALIPDOMAINNAME-C' + #13#10; HostsStream.Write(S[1], Length(S));
  S := '::1 ZDUALIPDOMAINNAME-A ZDUALIPDOMAINNAME-B ZDUALIPDOMAINNAME-D' + #13#10; HostsStream.Write(S[1], Length(S));

  // Close the stream
  HostsStream.Free;

  // Trace the event if a tracer is enabled
  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  // Trace the event if a tracer is enabled
  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Start loading cache...');

  // Load the cache from file
  THostsCache.LoadFromFile(Self.ClassName + '.tmp');

  // Trace the event if a tracer is enabled
  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  // Trace the event if a tracer is enabled
  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Start searching items...');

  for i := 0 to (KHostsItems - 1) do begin // Massive item extraction

    for j := 0 to 999 do begin

      k := 1000 * i + j;

      // Generate a unique string
      S := FormatCurr('000000000', k);

      // Generate an IPv4 address
      IPv4Address := k;

      // Search items from the cache and check their properties
      if not(THostsCache.Find('IPV4DOMAINNAME-' + S + '-A', DNS_QUERY_TYPE_A, HostsEntry)) then raise FailedUnitTestException.Create;
      if HostsEntry.Address.IsIPv6Address then raise FailedUnitTestException.Create;
      if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, IPv4Address)) then raise FailedUnitTestException.Create;
      if not(THostsCache.Find('IPV4DOMAINNAME-' + S + '-B', DNS_QUERY_TYPE_A, HostsEntry)) then raise FailedUnitTestException.Create;
      if HostsEntry.Address.IsIPv6Address then raise FailedUnitTestException.Create;
      if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, IPv4Address)) then raise FailedUnitTestException.Create;

      // Generate an IPv6 address
      IPv6Address[0] := 0; IPv6Address[1] := k and $ff;IPv6Address[2] := 0; IPv6Address[3] := k and $ff;IPv6Address[4] := 0; IPv6Address[5] := k and $ff;IPv6Address[6] := 0; IPv6Address[7] := k and $ff;IPv6Address[8] := 0; IPv6Address[9] := k and $ff;IPv6Address[10] := 0; IPv6Address[11] := k and $ff;IPv6Address[12] := 0; IPv6Address[13] := k and $ff;IPv6Address[14] := 0; IPv6Address[15] := k and $ff;

      if not(THostsCache.Find('IPV6DOMAINNAME-' + S + '-A', DNS_QUERY_TYPE_AAAA, HostsEntry)) then raise FailedUnitTestException.Create;
      if not(HostsEntry.Address.IsIPv6Address) then raise FailedUnitTestException.Create;
      if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, IPv6Address)) then raise FailedUnitTestException.Create;
      if not(THostsCache.Find('IPV6DOMAINNAME-' + S + '-B', DNS_QUERY_TYPE_AAAA, HostsEntry)) then raise FailedUnitTestException.Create;
      if not(HostsEntry.Address.IsIPv6Address) then raise FailedUnitTestException.Create;
      if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, IPv6Address)) then raise FailedUnitTestException.Create;

    end;

  end;

  // Test the pattern engine (1)
  if not(THostsCache.Find('IPV4PATTERN-1-127-0-0-1', DNS_QUERY_TYPE_A, HostsEntry)) then raise FailedUnitTestException.Create;
  if HostsEntry.Address.IsIPv6Address then raise FailedUnitTestException.Create;
  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('ipv4pattern-1-127-0-0-1', DNS_QUERY_TYPE_A, HostsEntry)) then raise FailedUnitTestException.Create;
  if HostsEntry.Address.IsIPv6Address then raise FailedUnitTestException.Create;
  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('MATCH.IPV4PATTERN-1-127-0-0-1', DNS_QUERY_TYPE_A, HostsEntry)) then raise FailedUnitTestException.Create;
  if HostsEntry.Address.IsIPv6Address then raise FailedUnitTestException.Create;
  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('match.ipv4pattern-1-127-0-0-1', DNS_QUERY_TYPE_A, HostsEntry)) then raise FailedUnitTestException.Create;
  if HostsEntry.Address.IsIPv6Address then raise FailedUnitTestException.Create;
  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then raise FailedUnitTestException.Create;
  if THostsCache.Find('NO.IPV4PATTERN-1-127-0-0-1.TEST', DNS_QUERY_TYPE_A, HostsEntry) then raise FailedUnitTestException.Create;
  if THostsCache.Find('no.ipv4pattern-1-127-0-0-1.test', DNS_QUERY_TYPE_A, HostsEntry) then raise FailedUnitTestException.Create;

  // Test the pattern engine (1)
  if not(THostsCache.Find('IPV6PATTERN-1-LOCALHOST', DNS_QUERY_TYPE_AAAA, HostsEntry)) then raise FailedUnitTestException.Create;
  if not(HostsEntry.Address.IsIPv6Address) then raise FailedUnitTestException.Create;
  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('ipv6pattern-1-LOCALHOST', DNS_QUERY_TYPE_AAAA, HostsEntry)) then raise FailedUnitTestException.Create;
  if not(HostsEntry.Address.IsIPv6Address) then raise FailedUnitTestException.Create;
  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('MATCH.IPV6PATTERN-1-LOCALHOST', DNS_QUERY_TYPE_AAAA, HostsEntry)) then raise FailedUnitTestException.Create;
  if not(HostsEntry.Address.IsIPv6Address) then raise FailedUnitTestException.Create;
  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('match.ipv6pattern-1-LOCALHOST', DNS_QUERY_TYPE_AAAA, HostsEntry)) then raise FailedUnitTestException.Create;
  if not(HostsEntry.Address.IsIPv6Address) then raise FailedUnitTestException.Create;
  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then raise FailedUnitTestException.Create;
  if THostsCache.Find('NO.IPV6PATTERN-1-LOCALHOST.TEST', DNS_QUERY_TYPE_AAAA, HostsEntry) then raise FailedUnitTestException.Create;
  if THostsCache.Find('no.ipv6pattern-1-LOCALHOST.test', DNS_QUERY_TYPE_AAAA, HostsEntry) then raise FailedUnitTestException.Create;

  // Test the pattern engine (2)
  if not(THostsCache.Find('IPV4PATTERN-2-127-0-0-1.TEST', DNS_QUERY_TYPE_A, HostsEntry)) then raise FailedUnitTestException.Create;
  if HostsEntry.Address.IsIPv6Address then raise FailedUnitTestException.Create;
  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('ipv4pattern-2-127-0-0-1.test', DNS_QUERY_TYPE_A, HostsEntry)) then raise FailedUnitTestException.Create;
  if HostsEntry.Address.IsIPv6Address then raise FailedUnitTestException.Create;
  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('MATCH.IPV4PATTERN-2-127-0-0-1.TEST', DNS_QUERY_TYPE_A, HostsEntry)) then raise FailedUnitTestException.Create;
  if HostsEntry.Address.IsIPv6Address then raise FailedUnitTestException.Create;
  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('match.ipv4pattern-2-127-0-0-1.test', DNS_QUERY_TYPE_A, HostsEntry)) then raise FailedUnitTestException.Create;
  if HostsEntry.Address.IsIPv6Address then raise FailedUnitTestException.Create;
  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then raise FailedUnitTestException.Create;
  if THostsCache.Find('NO.IPV4PATTERN-2-127-0-0-1.TEST', DNS_QUERY_TYPE_A, HostsEntry) then raise FailedUnitTestException.Create;
  if THostsCache.Find('no.ipv4pattern-2-127-0-0-1.test', DNS_QUERY_TYPE_A, HostsEntry) then raise FailedUnitTestException.Create;

  // Test the pattern engine (2)
  if not(THostsCache.Find('IPV6PATTERN-2-LOCALHOST.TEST', DNS_QUERY_TYPE_AAAA, HostsEntry)) then raise FailedUnitTestException.Create;
  if not(HostsEntry.Address.IsIPv6Address) then raise FailedUnitTestException.Create;
  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('ipv6pattern-2-LOCALHOST.test', DNS_QUERY_TYPE_AAAA, HostsEntry)) then raise FailedUnitTestException.Create;
  if not(HostsEntry.Address.IsIPv6Address) then raise FailedUnitTestException.Create;
  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('MATCH.IPV6PATTERN-2-LOCALHOST.TEST', DNS_QUERY_TYPE_AAAA, HostsEntry)) then raise FailedUnitTestException.Create;
  if not(HostsEntry.Address.IsIPv6Address) then raise FailedUnitTestException.Create;
  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('match.ipv6pattern-2-LOCALHOST.test', DNS_QUERY_TYPE_AAAA, HostsEntry)) then raise FailedUnitTestException.Create;
  if not(HostsEntry.Address.IsIPv6Address) then raise FailedUnitTestException.Create;
  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then raise FailedUnitTestException.Create;
  if THostsCache.Find('NO.IPV6PATTERN-2-LOCALHOST.TEST', DNS_QUERY_TYPE_AAAA, HostsEntry) then raise FailedUnitTestException.Create;
  if THostsCache.Find('no.ipv6pattern-2-LOCALHOST.test', DNS_QUERY_TYPE_AAAA, HostsEntry) then raise FailedUnitTestException.Create;

  // Test the pattern engine (3)
  if not(THostsCache.Find('MATCH.IPV4PATTERN-3-127-0-0-1.TEST', DNS_QUERY_TYPE_A, HostsEntry)) then raise FailedUnitTestException.Create;
  if HostsEntry.Address.IsIPv6Address then raise FailedUnitTestException.Create;
  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('match.ipv4pattern-3-127-0-0-1.test', DNS_QUERY_TYPE_A, HostsEntry)) then raise FailedUnitTestException.Create;
  if HostsEntry.Address.IsIPv6Address then raise FailedUnitTestException.Create;
  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then raise FailedUnitTestException.Create;
  if THostsCache.Find('NO.IPV4PATTERN-3-127-0-0-1.TEST', DNS_QUERY_TYPE_A, HostsEntry) then raise FailedUnitTestException.Create;
  if THostsCache.Find('no.ipv4pattern-3-127-0-0-1.test', DNS_QUERY_TYPE_A, HostsEntry) then raise FailedUnitTestException.Create;

  // Test the pattern engine (3)
  if not(THostsCache.Find('MATCH.IPV6PATTERN-3-LOCALHOST.TEST', DNS_QUERY_TYPE_AAAA, HostsEntry)) then raise FailedUnitTestException.Create;
  if not(HostsEntry.Address.IsIPv6Address) then raise FailedUnitTestException.Create;
  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('match.ipv6pattern-3-LOCALHOST.test', DNS_QUERY_TYPE_AAAA, HostsEntry)) then raise FailedUnitTestException.Create;
  if not(HostsEntry.Address.IsIPv6Address) then raise FailedUnitTestException.Create;
  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then raise FailedUnitTestException.Create;
  if THostsCache.Find('NO.IPV6PATTERN-3-LOCALHOST.TEST', DNS_QUERY_TYPE_AAAA, HostsEntry) then raise FailedUnitTestException.Create;
  if THostsCache.Find('no.ipv6pattern-3-LOCALHOST.test', DNS_QUERY_TYPE_AAAA, HostsEntry) then raise FailedUnitTestException.Create;

  // Test the regular expression engine (1)
  if not(THostsCache.Find('MATCH.IPV4REGEXP-1-127-0-0-1.TEST', DNS_QUERY_TYPE_A, HostsEntry)) then raise FailedUnitTestException.Create;
  if HostsEntry.Address.IsIPv6Address then raise FailedUnitTestException.Create;
  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('match.ipv4regexp-1-127-0-0-1.test', DNS_QUERY_TYPE_A, HostsEntry)) then raise FailedUnitTestException.Create;
  if HostsEntry.Address.IsIPv6Address then raise FailedUnitTestException.Create;
  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then raise FailedUnitTestException.Create;
  if THostsCache.Find('NO.IPV4REGEXP1-127-0-0-1.TEST', DNS_QUERY_TYPE_A, HostsEntry) then raise FailedUnitTestException.Create;
  if THostsCache.Find('no.ipv4regexp1-127-0-0-1.test', DNS_QUERY_TYPE_A, HostsEntry) then raise FailedUnitTestException.Create;

  // Test the regular expression engine (1)
  if not(THostsCache.Find('MATCH.IPV6REGEXP-1-LOCALHOST.TEST', DNS_QUERY_TYPE_AAAA, HostsEntry)) then raise FailedUnitTestException.Create;
  if not(HostsEntry.Address.IsIPv6Address) then raise FailedUnitTestException.Create;
  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('match.ipv6regexp-1-LOCALHOST.test', DNS_QUERY_TYPE_AAAA, HostsEntry)) then raise FailedUnitTestException.Create;
  if not(HostsEntry.Address.IsIPv6Address) then raise FailedUnitTestException.Create;
  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then raise FailedUnitTestException.Create;
  if THostsCache.Find('NO.IPV6REGEXP1-LOCALHOST.TEST', DNS_QUERY_TYPE_AAAA, HostsEntry) then raise FailedUnitTestException.Create;
  if THostsCache.Find('no.ipv6regexp1-LOCALHOST.test', DNS_QUERY_TYPE_AAAA, HostsEntry) then raise FailedUnitTestException.Create;

  // Test the query type discrimination algorithm (1)
  if not(THostsCache.Find('ZDUALIPDOMAINNAME-A', DNS_QUERY_TYPE_A, HostsEntry)) then raise FailedUnitTestException.Create;
  if HostsEntry.Address.IsIPv6Address then raise FailedUnitTestException.Create;
  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('ZDUALIPDOMAINNAME-A', DNS_QUERY_TYPE_AAAA, HostsEntry)) then raise FailedUnitTestException.Create;
  if not(HostsEntry.Address.IsIPv6Address) then raise FailedUnitTestException.Create;
  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('ZDUALIPDOMAINNAME-B', DNS_QUERY_TYPE_A, HostsEntry)) then raise FailedUnitTestException.Create;
  if HostsEntry.Address.IsIPv6Address then raise FailedUnitTestException.Create;
  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('ZDUALIPDOMAINNAME-B', DNS_QUERY_TYPE_AAAA, HostsEntry)) then raise FailedUnitTestException.Create;
  if not(HostsEntry.Address.IsIPv6Address) then raise FailedUnitTestException.Create;
  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('ZDUALIPDOMAINNAME-C', DNS_QUERY_TYPE_A, HostsEntry)) then raise FailedUnitTestException.Create;
  if HostsEntry.Address.IsIPv6Address then raise FailedUnitTestException.Create;
  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('ZDUALIPDOMAINNAME-D', DNS_QUERY_TYPE_AAAA, HostsEntry)) then raise FailedUnitTestException.Create;
  if not(HostsEntry.Address.IsIPv6Address) then raise FailedUnitTestException.Create;
  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then raise FailedUnitTestException.Create;
  if THostsCache.Find('ZDUALIPDOMAINNAME-C', DNS_QUERY_TYPE_AAAA, HostsEntry) then raise FailedUnitTestException.Create;
  if THostsCache.Find('ZDUALIPDOMAINNAME-D', DNS_QUERY_TYPE_A, HostsEntry) then raise FailedUnitTestException.Create;

  // Try to look for a nonexistant item (1)
  if THostsCache.Find('IPV4NONEXISTANTDOMAINNAME', DNS_QUERY_TYPE_A, HostsEntry) then raise FailedUnitTestException.Create;

  // Try to look for a nonexistant item (1)
  if THostsCache.Find('IPV6NONEXISTANTDOMAINNAME', DNS_QUERY_TYPE_AAAA, HostsEntry) then raise FailedUnitTestException.Create;

  // Trace the event if a tracer is enabled
  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  // Finalize class
  THostsCache.Finalize;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor THostsCacheUnitTest.Destroy;
begin
  inherited Destroy;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------
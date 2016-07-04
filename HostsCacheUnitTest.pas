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
  HostsStream: TFileStream; i, j, k: Integer; S: String; IPv4Address: TIPv4Address; IPv6Address: TIPv6Address; HostsBlock: String; HostsEntry: THostsEntry;
begin
  THostsCache.Initialize;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Start massive insertion...');

  HostsStream := TFileStream.Create(Self.ClassName + '.tmp', fmCreate);

  RandSeed := 0; for i := 0 to (THostsCacheUnitTest_KHostsItems - 1) do begin

    SetLength(HostsBlock, 0); for j := 0 to 999 do begin

      k := (1000 * i) + j;

      S := FormatCurr('000000000', k);

      IPv4Address := k;

      HostsBlock := HostsBlock + TIPv4AddressUtility.ToString(IPv4Address) + #32 + 'IPV4DOMAIN-' + S + '-A' + #32 + 'IPV4DOMAIN-' + S + '-B' + #32 + 'IPV4DOMAIN-' + S + '-C' + #13#10;

      IPv6Address[0] := 0; IPv6Address[1] := k and $ff; IPv6Address[2] := 0; IPv6Address[3] := k and $ff; IPv6Address[4] := 0; IPv6Address[5] := k and $ff; IPv6Address[6] := 0; IPv6Address[7] := k and $ff; IPv6Address[8] := 0; IPv6Address[9] := k and $ff; IPv6Address[10] := 0; IPv6Address[11] := k and $ff; IPv6Address[12] := 0; IPv6Address[13] := k and $ff; IPv6Address[14] := 0; IPv6Address[15] := k and $ff;

      HostsBlock := HostsBlock + TIPv6AddressUtility.ToString(IPv6Address) + #32 + 'IPV6DOMAIN-' + S + '-A' + #32 + 'IPV6DOMAIN-' + S + '-B' + #32 + 'IPV6DOMAIN-' + S + '-C' + #13#10;

    end;

    HostsStream.Write(HostsBlock[1], Length(HostsBlock));

  end;

  // IPv4 pattern (1)
  S := '127.0.0.1 >IPV4PATTERN-1-127-0-0-1 -NO.IPV4PATTERN-1-127-0-0-1' + #13#10; HostsStream.Write(S[1], Length(S));

  // IPv6 pattern (1)
  S := '::1 >IPV6PATTERN-1-LOCALHOST -NO.IPV6PATTERN-1-LOCALHOST' + #13#10; HostsStream.Write(S[1], Length(S));

  // IPv4 pattern (2)
  S := '127.0.0.1 >IPV4PATTERN-2-127-0-0-1.* -NO.IPV4PATTERN-2-127-0-0-1.TEST' + #13#10; HostsStream.Write(S[1], Length(S));

  // IPv6 pattern (2)
  S := '::1 >IPV6PATTERN-2-LOCALHOST.* -NO.IPV6PATTERN-2-LOCALHOST.TEST' + #13#10; HostsStream.Write(S[1], Length(S));

  // IPv4 pattern (3)
  S := '127.0.0.1 *.IPV4PATTERN-3-127-0-0-1.* -NO.IPV4PATTERN-3-127-0-0-1.TEST' + #13#10; HostsStream.Write(S[1], Length(S));

  // IPv6 pattern (3)
  S := '::1 *.IPV6PATTERN-3-LOCALHOST.* -NO.IPV6PATTERN-3-LOCALHOST.TEST' + #13#10; HostsStream.Write(S[1], Length(S));

  // IPv4 regular expression (1)
  S := '127.0.0.1 /^.*\.IPV4REGEXP-1-127-0-0-1\..*$ -NO.IPV4REGEXP-1-127-0-0-1.TEST' + #13#10; HostsStream.Write(S[1], Length(S));

  // IPv6 regular expression (1)
  S := '::1 /^.*\.IPV6REGEXP-1-LOCALHOST\..*$ -NO.IPV6REGEXP-1-LOCALHOST.TEST' + #13#10; HostsStream.Write(S[1], Length(S));

  // Dual IP address for testing the query type discrimination algorithm (1)
  S := '127.0.0.1 ZDUALIPDOMAIN-A ZDUALIPDOMAIN-B ZDUALIPDOMAIN-C' + #13#10; HostsStream.Write(S[1], Length(S));
  S := '::1 ZDUALIPDOMAIN-A ZDUALIPDOMAIN-B ZDUALIPDOMAIN-D' + #13#10; HostsStream.Write(S[1], Length(S));

  HostsStream.Free;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Start loading cache...');

  THostsCache.LoadFromFile(Self.ClassName + '.tmp');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Start searching items...');

  for i := 0 to (THostsCacheUnitTest_KHostsItems - 1) do begin

    for j := 0 to 999 do begin

      k := (1000 * i) + j;

      S := FormatCurr('000000000', k);

      IPv4Address := k;

      if not(THostsCache.Find('IPV4DOMAIN-' + S + '-A', DNS_QUERY_TYPE_A, HostsEntry)) then begin
        raise FailedUnitTestException.Create;
      end;

      if HostsEntry.Address.IsIPv6Address then begin
        raise FailedUnitTestException.Create;
      end;

      if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, IPv4Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(THostsCache.Find('IPV4DOMAIN-' + S + '-B', DNS_QUERY_TYPE_A, HostsEntry)) then begin
        raise FailedUnitTestException.Create;
      end;

      if HostsEntry.Address.IsIPv6Address then begin
        raise FailedUnitTestException.Create;
      end;

      if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, IPv4Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(THostsCache.Find('IPV4DOMAIN-' + S + '-C', DNS_QUERY_TYPE_A, HostsEntry)) then begin
        raise FailedUnitTestException.Create;
      end;

      if HostsEntry.Address.IsIPv6Address then begin
        raise FailedUnitTestException.Create;
      end;

      if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, IPv4Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      IPv6Address[0] := 0; IPv6Address[1] := k and $ff; IPv6Address[2] := 0; IPv6Address[3] := k and $ff; IPv6Address[4] := 0; IPv6Address[5] := k and $ff; IPv6Address[6] := 0; IPv6Address[7] := k and $ff; IPv6Address[8] := 0; IPv6Address[9] := k and $ff; IPv6Address[10] := 0; IPv6Address[11] := k and $ff; IPv6Address[12] := 0; IPv6Address[13] := k and $ff; IPv6Address[14] := 0; IPv6Address[15] := k and $ff;

      if not(THostsCache.Find('IPV6DOMAIN-' + S + '-A', DNS_QUERY_TYPE_AAAA, HostsEntry)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(HostsEntry.Address.IsIPv6Address) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, IPv6Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(THostsCache.Find('IPV6DOMAIN-' + S + '-B', DNS_QUERY_TYPE_AAAA, HostsEntry)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(HostsEntry.Address.IsIPv6Address) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, IPv6Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(THostsCache.Find('IPV6DOMAIN-' + S + '-C', DNS_QUERY_TYPE_AAAA, HostsEntry)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(HostsEntry.Address.IsIPv6Address) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, IPv6Address)) then begin
        raise FailedUnitTestException.Create;
      end;

    end;

  end;

  // IPv4 pattern (1)

  if not(THostsCache.Find('IPV4PATTERN-1-127-0-0-1', DNS_QUERY_TYPE_A, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if HostsEntry.Address.IsIPv6Address then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.Find('ipv4pattern-1-127-0-0-1', DNS_QUERY_TYPE_A, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if HostsEntry.Address.IsIPv6Address then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.Find('MATCH.IPV4PATTERN-1-127-0-0-1', DNS_QUERY_TYPE_A, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if HostsEntry.Address.IsIPv6Address then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.Find('match.ipv4pattern-1-127-0-0-1', DNS_QUERY_TYPE_A, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if HostsEntry.Address.IsIPv6Address then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.Find('NO.IPV4PATTERN-1-127-0-0-1.TEST', DNS_QUERY_TYPE_A, HostsEntry) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.Find('no.ipv4pattern-1-127-0-0-1.test', DNS_QUERY_TYPE_A, HostsEntry) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv6 pattern (1)

  if not(THostsCache.Find('IPV6PATTERN-1-LOCALHOST', DNS_QUERY_TYPE_AAAA, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(HostsEntry.Address.IsIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.Find('ipv6pattern-1-LOCALHOST', DNS_QUERY_TYPE_AAAA, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(HostsEntry.Address.IsIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.Find('MATCH.IPV6PATTERN-1-LOCALHOST', DNS_QUERY_TYPE_AAAA, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(HostsEntry.Address.IsIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.Find('match.ipv6pattern-1-LOCALHOST', DNS_QUERY_TYPE_AAAA, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(HostsEntry.Address.IsIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.Find('NO.IPV6PATTERN-1-LOCALHOST.TEST', DNS_QUERY_TYPE_AAAA, HostsEntry) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.Find('no.ipv6pattern-1-LOCALHOST.test', DNS_QUERY_TYPE_AAAA, HostsEntry) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv4 pattern (2)

  if not(THostsCache.Find('IPV4PATTERN-2-127-0-0-1.TEST', DNS_QUERY_TYPE_A, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if HostsEntry.Address.IsIPv6Address then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.Find('ipv4pattern-2-127-0-0-1.test', DNS_QUERY_TYPE_A, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if HostsEntry.Address.IsIPv6Address then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.Find('MATCH.IPV4PATTERN-2-127-0-0-1.TEST', DNS_QUERY_TYPE_A, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if HostsEntry.Address.IsIPv6Address then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.Find('match.ipv4pattern-2-127-0-0-1.test', DNS_QUERY_TYPE_A, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if HostsEntry.Address.IsIPv6Address then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.Find('NO.IPV4PATTERN-2-127-0-0-1.TEST', DNS_QUERY_TYPE_A, HostsEntry) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.Find('no.ipv4pattern-2-127-0-0-1.test', DNS_QUERY_TYPE_A, HostsEntry) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv6 pattern (2)

  if not(THostsCache.Find('IPV6PATTERN-2-LOCALHOST.TEST', DNS_QUERY_TYPE_AAAA, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(HostsEntry.Address.IsIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.Find('ipv6pattern-2-LOCALHOST.test', DNS_QUERY_TYPE_AAAA, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(HostsEntry.Address.IsIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.Find('MATCH.IPV6PATTERN-2-LOCALHOST.TEST', DNS_QUERY_TYPE_AAAA, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(HostsEntry.Address.IsIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.Find('match.ipv6pattern-2-LOCALHOST.test', DNS_QUERY_TYPE_AAAA, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(HostsEntry.Address.IsIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.Find('NO.IPV6PATTERN-2-LOCALHOST.TEST', DNS_QUERY_TYPE_AAAA, HostsEntry) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.Find('no.ipv6pattern-2-LOCALHOST.test', DNS_QUERY_TYPE_AAAA, HostsEntry) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv4 pattern (3)

  if not(THostsCache.Find('MATCH.IPV4PATTERN-3-127-0-0-1.TEST', DNS_QUERY_TYPE_A, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if HostsEntry.Address.IsIPv6Address then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.Find('match.ipv4pattern-3-127-0-0-1.test', DNS_QUERY_TYPE_A, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if HostsEntry.Address.IsIPv6Address then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.Find('NO.IPV4PATTERN-3-127-0-0-1.TEST', DNS_QUERY_TYPE_A, HostsEntry) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.Find('no.ipv4pattern-3-127-0-0-1.test', DNS_QUERY_TYPE_A, HostsEntry) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv6 pattern (3)

  if not(THostsCache.Find('MATCH.IPV6PATTERN-3-LOCALHOST.TEST', DNS_QUERY_TYPE_AAAA, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(HostsEntry.Address.IsIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.Find('match.ipv6pattern-3-LOCALHOST.test', DNS_QUERY_TYPE_AAAA, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(HostsEntry.Address.IsIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.Find('NO.IPV6PATTERN-3-LOCALHOST.TEST', DNS_QUERY_TYPE_AAAA, HostsEntry) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.Find('no.ipv6pattern-3-LOCALHOST.test', DNS_QUERY_TYPE_AAAA, HostsEntry) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv4 regular expression (1)

  if not(THostsCache.Find('MATCH.IPV4REGEXP-1-127-0-0-1.TEST', DNS_QUERY_TYPE_A, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if HostsEntry.Address.IsIPv6Address then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.Find('match.ipv4regexp-1-127-0-0-1.test', DNS_QUERY_TYPE_A, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if HostsEntry.Address.IsIPv6Address then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.Find('NO.IPV4REGEXP1-127-0-0-1.TEST', DNS_QUERY_TYPE_A, HostsEntry) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.Find('no.ipv4regexp1-127-0-0-1.test', DNS_QUERY_TYPE_A, HostsEntry) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv6 regular expression (1)

  if not(THostsCache.Find('MATCH.IPV6REGEXP-1-LOCALHOST.TEST', DNS_QUERY_TYPE_AAAA, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(HostsEntry.Address.IsIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.Find('match.ipv6regexp-1-LOCALHOST.test', DNS_QUERY_TYPE_AAAA, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(HostsEntry.Address.IsIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.Find('NO.IPV6REGEXP1-LOCALHOST.TEST', DNS_QUERY_TYPE_AAAA, HostsEntry) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.Find('no.ipv6regexp1-LOCALHOST.test', DNS_QUERY_TYPE_AAAA, HostsEntry) then begin
    raise FailedUnitTestException.Create;
  end;

  // Query type discrimination algorithm (1)

  if not(THostsCache.Find('ZDUALIPDOMAIN-A', DNS_QUERY_TYPE_A, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if HostsEntry.Address.IsIPv6Address then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.Find('ZDUALIPDOMAIN-A', DNS_QUERY_TYPE_AAAA, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(HostsEntry.Address.IsIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.Find('ZDUALIPDOMAIN-B', DNS_QUERY_TYPE_A, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if HostsEntry.Address.IsIPv6Address then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.Find('ZDUALIPDOMAIN-B', DNS_QUERY_TYPE_AAAA, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(HostsEntry.Address.IsIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.Find('ZDUALIPDOMAIN-C', DNS_QUERY_TYPE_A, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if HostsEntry.Address.IsIPv6Address then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntry.Address.IPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.Find('ZDUALIPDOMAIN-D', DNS_QUERY_TYPE_AAAA, HostsEntry)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(HostsEntry.Address.IsIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntry.Address.IPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.Find('ZDUALIPDOMAIN-C', DNS_QUERY_TYPE_AAAA, HostsEntry) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.Find('ZDUALIPDOMAIN-D', DNS_QUERY_TYPE_A, HostsEntry) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv4 nonexistant item (1)

  if THostsCache.Find('IPV4NONEXISTANTDOMAIN', DNS_QUERY_TYPE_A, HostsEntry) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv6 nonexistant item (1)

  if THostsCache.Find('IPV6NONEXISTANTDOMAIN', DNS_QUERY_TYPE_AAAA, HostsEntry) then begin
    raise FailedUnitTestException.Create;
  end;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

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
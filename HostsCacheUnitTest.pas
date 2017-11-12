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
  HostsStream: TFileStream; i, j, k: Integer; S: String; IPv4Address: TIPv4Address; IPv6Address: TIPv6Address; HostsBlock: String; HostsEntryIPv4Address: TIPv4Address; HostsEntryIPv6Address: TIPv6Address;
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

      if not(THostsCache.FindIPv4AddressHostsEntry('IPV4DOMAIN-' + S + '-A', HostsEntryIPv4Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, IPv4Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(THostsCache.FindIPv4AddressHostsEntry('IPV4DOMAIN-' + S + '-B', HostsEntryIPv4Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, IPv4Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(THostsCache.FindIPv4AddressHostsEntry('IPV4DOMAIN-' + S + '-C', HostsEntryIPv4Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, IPv4Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      IPv6Address[0] := 0; IPv6Address[1] := k and $ff; IPv6Address[2] := 0; IPv6Address[3] := k and $ff; IPv6Address[4] := 0; IPv6Address[5] := k and $ff; IPv6Address[6] := 0; IPv6Address[7] := k and $ff; IPv6Address[8] := 0; IPv6Address[9] := k and $ff; IPv6Address[10] := 0; IPv6Address[11] := k and $ff; IPv6Address[12] := 0; IPv6Address[13] := k and $ff; IPv6Address[14] := 0; IPv6Address[15] := k and $ff;

      if not(THostsCache.FindIPv6AddressHostsEntry('IPV6DOMAIN-' + S + '-A', HostsEntryIPv6Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, IPv6Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(THostsCache.FindIPv6AddressHostsEntry('IPV6DOMAIN-' + S + '-B', HostsEntryIPv6Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, IPv6Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(THostsCache.FindIPv6AddressHostsEntry('IPV6DOMAIN-' + S + '-C', HostsEntryIPv6Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, IPv6Address)) then begin
        raise FailedUnitTestException.Create;
      end;

    end;

  end;

  // IPv4 pattern (1)

  if not(THostsCache.FindIPv4AddressHostsEntry('IPV4PATTERN-1-127-0-0-1', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv4AddressHostsEntry('ipv4pattern-1-127-0-0-1', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv4AddressHostsEntry('MATCH.IPV4PATTERN-1-127-0-0-1', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv4AddressHostsEntry('match.ipv4pattern-1-127-0-0-1', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.FindIPv4AddressHostsEntry('NO.IPV4PATTERN-1-127-0-0-1.TEST', HostsEntryIPv4Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.FindIPv4AddressHostsEntry('no.ipv4pattern-1-127-0-0-1.test', HostsEntryIPv4Address) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv6 pattern (1)

  if not(THostsCache.FindIPv6AddressHostsEntry('IPV6PATTERN-1-LOCALHOST', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv6AddressHostsEntry('ipv6pattern-1-LOCALHOST', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv6AddressHostsEntry('MATCH.IPV6PATTERN-1-LOCALHOST', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv6AddressHostsEntry('match.ipv6pattern-1-LOCALHOST', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.FindIPv6AddressHostsEntry('NO.IPV6PATTERN-1-LOCALHOST.TEST', HostsEntryIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.FindIPv6AddressHostsEntry('no.ipv6pattern-1-LOCALHOST.test', HostsEntryIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv4 pattern (2)

  if not(THostsCache.FindIPv4AddressHostsEntry('IPV4PATTERN-2-127-0-0-1.TEST', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv4AddressHostsEntry('ipv4pattern-2-127-0-0-1.test', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv4AddressHostsEntry('MATCH.IPV4PATTERN-2-127-0-0-1.TEST', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv4AddressHostsEntry('match.ipv4pattern-2-127-0-0-1.test', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.FindIPv4AddressHostsEntry('NO.IPV4PATTERN-2-127-0-0-1.TEST', HostsEntryIPv4Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.FindIPv4AddressHostsEntry('no.ipv4pattern-2-127-0-0-1.test', HostsEntryIPv4Address) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv6 pattern (2)

  if not(THostsCache.FindIPv6AddressHostsEntry('IPV6PATTERN-2-LOCALHOST.TEST', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv6AddressHostsEntry('ipv6pattern-2-LOCALHOST.test', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv6AddressHostsEntry('MATCH.IPV6PATTERN-2-LOCALHOST.TEST', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv6AddressHostsEntry('match.ipv6pattern-2-LOCALHOST.test', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.FindIPv6AddressHostsEntry('NO.IPV6PATTERN-2-LOCALHOST.TEST', HostsEntryIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.FindIPv6AddressHostsEntry('no.ipv6pattern-2-LOCALHOST.test', HostsEntryIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv4 pattern (3)

  if not(THostsCache.FindIPv4AddressHostsEntry('MATCH.IPV4PATTERN-3-127-0-0-1.TEST', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv4AddressHostsEntry('match.ipv4pattern-3-127-0-0-1.test', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.FindIPv4AddressHostsEntry('NO.IPV4PATTERN-3-127-0-0-1.TEST', HostsEntryIPv4Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.FindIPv4AddressHostsEntry('no.ipv4pattern-3-127-0-0-1.test', HostsEntryIPv4Address) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv6 pattern (3)

  if not(THostsCache.FindIPv6AddressHostsEntry('MATCH.IPV6PATTERN-3-LOCALHOST.TEST', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv6AddressHostsEntry('match.ipv6pattern-3-LOCALHOST.test', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.FindIPv6AddressHostsEntry('NO.IPV6PATTERN-3-LOCALHOST.TEST', HostsEntryIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.FindIPv6AddressHostsEntry('no.ipv6pattern-3-LOCALHOST.test', HostsEntryIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv4 regular expression (1)

  if not(THostsCache.FindIPv4AddressHostsEntry('MATCH.IPV4REGEXP-1-127-0-0-1.TEST', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv4AddressHostsEntry('match.ipv4regexp-1-127-0-0-1.test', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.FindIPv4AddressHostsEntry('NO.IPV4REGEXP1-127-0-0-1.TEST', HostsEntryIPv4Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.FindIPv4AddressHostsEntry('no.ipv4regexp1-127-0-0-1.test', HostsEntryIPv4Address) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv6 regular expression (1)

  if not(THostsCache.FindIPv6AddressHostsEntry('MATCH.IPV6REGEXP-1-LOCALHOST.TEST', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv6AddressHostsEntry('match.ipv6regexp-1-LOCALHOST.test', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.FindIPv6AddressHostsEntry('NO.IPV6REGEXP1-LOCALHOST.TEST', HostsEntryIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  if THostsCache.FindIPv6AddressHostsEntry('no.ipv6regexp1-LOCALHOST.test', HostsEntryIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv4 nonexistant item (1)

  if THostsCache.FindIPv4AddressHostsEntry('IPV4NONEXISTANTDOMAIN', HostsEntryIPv4Address) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv6 nonexistant item (1)

  if THostsCache.FindIPv6AddressHostsEntry('IPV6NONEXISTANTDOMAIN', HostsEntryIPv6Address) then begin
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
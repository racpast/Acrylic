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

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Starting massive insertion...');

  HostsStream := TFileStream.Create(Self.ClassName + '.tmp', fmCreate);

  RandSeed := 0; for i := 0 to (THostsCacheUnitTest_KHostsItems - 1) do begin

    SetLength(HostsBlock, 0); for j := 0 to 999 do begin

      k := (1000 * i) + j;

      S := FormatCurr('000000000', k);

      // IPv4 entries (1)

      IPv4Address := k;

      HostsBlock := HostsBlock + TIPv4AddressUtility.ToString(IPv4Address) + #32 + 'IPV4DOMAIN1-' + S + '-A' + #32 + 'IPV4DOMAIN1-' + S + '-B' + #32 + 'IPV4DOMAIN1-' + S + '-C' + #13#10;

      // IPv6 entries (1)

      IPv6Address[0] := 0; IPv6Address[1] := k and $ff; IPv6Address[2] := 0; IPv6Address[3] := k and $ff; IPv6Address[4] := 0; IPv6Address[5] := k and $ff; IPv6Address[6] := 0; IPv6Address[7] := k and $ff; IPv6Address[8] := 0; IPv6Address[9] := k and $ff; IPv6Address[10] := 0; IPv6Address[11] := k and $ff; IPv6Address[12] := 0; IPv6Address[13] := k and $ff; IPv6Address[14] := 0; IPv6Address[15] := k and $ff;

      HostsBlock := HostsBlock + TIPv6AddressUtility.ToString(IPv6Address) + #32 + 'IPV6DOMAIN1-' + S + '-A' + #32 + 'IPV6DOMAIN1-' + S + '-B' + #32 + 'IPV6DOMAIN1-' + S + '-C' + #13#10;

      // FW entries (1)
      HostsBlock := HostsBlock + 'FW' + #32 + 'FWDOMAIN1-' + S + '-A' + #32 + 'FWDOMAIN1-' + S + '-B' + #32 + 'FWDOMAIN1-' + S + '-C' + #13#10;

      // NX entries (1)
      HostsBlock := HostsBlock + 'NX' + #32 + 'NXDOMAIN1-' + S + '-A' + #32 + 'NXDOMAIN1-' + S + '-B' + #32 + 'NXDOMAIN1-' + S + '-C' + #13#10;

    end;

    HostsStream.Write(HostsBlock[1], Length(HostsBlock));

  end;

  // IPv4 entries (2)
  S := '127.0.0.1 >IPV4DOMAIN2-127-0-0-1' + #13#10; HostsStream.Write(S[1], Length(S));

  // IPv6 entries (2)
  S := '::1 >IPV6DOMAIN2-LOCALHOST' + #13#10; HostsStream.Write(S[1], Length(S));

  // FW entries (2)
  S := 'FW >FWDOMAIN2' + #13#10; HostsStream.Write(S[1], Length(S));

  // NX entries (2)
  S := 'NX >NXDOMAIN2' + #13#10; HostsStream.Write(S[1], Length(S));

  // IPv4 entries (3)
  S := '127.0.0.1 >IPV4DOMAIN3-127-0-0-1.*' + #13#10; HostsStream.Write(S[1], Length(S));

  // IPv6 entries (3)
  S := '::1 >IPV6DOMAIN3-LOCALHOST.*' + #13#10; HostsStream.Write(S[1], Length(S));

  // FW entries (3)
  S := 'FW >FWDOMAIN3.*' + #13#10; HostsStream.Write(S[1], Length(S));

  // NX entries (3)
  S := 'NX >NXDOMAIN3.*' + #13#10; HostsStream.Write(S[1], Length(S));

  // IPv4 entries (4)
  S := '127.0.0.1 *.IPV4DOMAIN4-127-0-0-1.*' + #13#10; HostsStream.Write(S[1], Length(S));

  // IPv6 entries (4)
  S := '::1 *.IPV6DOMAIN4-LOCALHOST.*' + #13#10; HostsStream.Write(S[1], Length(S));

  // FW entries (4)
  S := 'FW *.FWDOMAIN4.*' + #13#10; HostsStream.Write(S[1], Length(S));

  // NX entries (4)
  S := 'NX *.NXDOMAIN4.*' + #13#10; HostsStream.Write(S[1], Length(S));

  // IPv4 entries (5)
  S := '127.0.0.1 /^.*\.IPV4DOMAIN5-127-0-0-1\..*$' + #13#10; HostsStream.Write(S[1], Length(S));

  // IPv6 entries (5)
  S := '::1 /^.*\.IPV6DOMAIN5-LOCALHOST\..*$' + #13#10; HostsStream.Write(S[1], Length(S));

  // FW entries (5)
  S := 'FW /^.*\.FWDOMAIN5\..*$' + #13#10; HostsStream.Write(S[1], Length(S));

  // NX entries (5)
  S := 'NX /^.*\.NXDOMAIN5\..*$' + #13#10; HostsStream.Write(S[1], Length(S));

  HostsStream.Free;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Starting loading cache...');

  THostsCache.LoadFromFile(Self.ClassName + '.tmp');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Starting searching items...');

  for i := 0 to (THostsCacheUnitTest_KHostsItems - 1) do begin

    for j := 0 to 999 do begin

      k := (1000 * i) + j;

      S := FormatCurr('000000000', k);

      IPv4Address := k;

      // IPv4 entries (1)

      if not(THostsCache.FindIPv4AddressHostsEntry('IPV4DOMAIN1-' + S + '-A', HostsEntryIPv4Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, IPv4Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(THostsCache.FindIPv4AddressHostsEntry('IPV4DOMAIN1-' + S + '-B', HostsEntryIPv4Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, IPv4Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(THostsCache.FindIPv4AddressHostsEntry('IPV4DOMAIN1-' + S + '-C', HostsEntryIPv4Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, IPv4Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      // IPv6 entries (1)

      IPv6Address[0] := 0; IPv6Address[1] := k and $ff; IPv6Address[2] := 0; IPv6Address[3] := k and $ff; IPv6Address[4] := 0; IPv6Address[5] := k and $ff; IPv6Address[6] := 0; IPv6Address[7] := k and $ff; IPv6Address[8] := 0; IPv6Address[9] := k and $ff; IPv6Address[10] := 0; IPv6Address[11] := k and $ff; IPv6Address[12] := 0; IPv6Address[13] := k and $ff; IPv6Address[14] := 0; IPv6Address[15] := k and $ff;

      if not(THostsCache.FindIPv6AddressHostsEntry('IPV6DOMAIN1-' + S + '-A', HostsEntryIPv6Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, IPv6Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(THostsCache.FindIPv6AddressHostsEntry('IPV6DOMAIN1-' + S + '-B', HostsEntryIPv6Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, IPv6Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(THostsCache.FindIPv6AddressHostsEntry('IPV6DOMAIN1-' + S + '-C', HostsEntryIPv6Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, IPv6Address)) then begin
        raise FailedUnitTestException.Create;
      end;

      // FW entries (1)

      if not(THostsCache.FindFWHostsEntry('FWDOMAIN1-' + S + '-A')) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(THostsCache.FindFWHostsEntry('FWDOMAIN1-' + S + '-B')) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(THostsCache.FindFWHostsEntry('FWDOMAIN1-' + S + '-C')) then begin
        raise FailedUnitTestException.Create;
      end;

      // NX entries (1)

      if not(THostsCache.FindNXHostsEntry('NXDOMAIN1-' + S + '-A')) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(THostsCache.FindNXHostsEntry('NXDOMAIN1-' + S + '-B')) then begin
        raise FailedUnitTestException.Create;
      end;

      if not(THostsCache.FindNXHostsEntry('NXDOMAIN1-' + S + '-C')) then begin
        raise FailedUnitTestException.Create;
      end;

    end;

  end;

  // IPv4 entries (2)

  if not(THostsCache.FindIPv4AddressHostsEntry('IPV4DOMAIN2-127-0-0-1', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv4AddressHostsEntry('ipv4domain2-127-0-0-1', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv4AddressHostsEntry('MATCH.IPV4DOMAIN2-127-0-0-1', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv4AddressHostsEntry('match.ipv4domain2-127-0-0-1', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv6 entries (2)

  if not(THostsCache.FindIPv6AddressHostsEntry('IPV6DOMAIN2-LOCALHOST', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv6AddressHostsEntry('ipv6domain2-LOCALHOST', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv6AddressHostsEntry('MATCH.IPV6DOMAIN2-LOCALHOST', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv6AddressHostsEntry('match.ipv6domain2-LOCALHOST', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  // FW entries (2)

  if not(THostsCache.FindFWHostsEntry('FWDOMAIN2')) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindFWHostsEntry('fwdomain2')) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindFWHostsEntry('MATCH.FWDOMAIN2')) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindFWHostsEntry('match.fwdomain2')) then begin
    raise FailedUnitTestException.Create;
  end;

  // NX entries (2)

  if not(THostsCache.FindNXHostsEntry('NXDOMAIN2')) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindNXHostsEntry('nxdomain2')) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindNXHostsEntry('MATCH.NXDOMAIN2')) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindNXHostsEntry('match.nxdomain2')) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv4 entries (3)

  if not(THostsCache.FindIPv4AddressHostsEntry('IPV4DOMAIN3-127-0-0-1.TEST', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv4AddressHostsEntry('ipv4domain3-127-0-0-1.test', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv4AddressHostsEntry('MATCH.IPV4DOMAIN3-127-0-0-1.TEST', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv4AddressHostsEntry('match.ipv4domain3-127-0-0-1.test', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv6 entries (3)

  if not(THostsCache.FindIPv6AddressHostsEntry('IPV6DOMAIN3-LOCALHOST.TEST', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv6AddressHostsEntry('ipv6domain3-LOCALHOST.test', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv6AddressHostsEntry('MATCH.IPV6DOMAIN3-LOCALHOST.TEST', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv6AddressHostsEntry('match.ipv6domain3-LOCALHOST.test', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  // FW entries (3)

  if not(THostsCache.FindFWHostsEntry('FWDOMAIN3.TEST')) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindFWHostsEntry('fwdomain3.test')) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindFWHostsEntry('MATCH.FWDOMAIN3.TEST')) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindFWHostsEntry('match.fwdomain3.test')) then begin
    raise FailedUnitTestException.Create;
  end;

  // NX entries (3)

  if not(THostsCache.FindNXHostsEntry('NXDOMAIN3.TEST')) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindNXHostsEntry('nxdomain3.test')) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindNXHostsEntry('MATCH.NXDOMAIN3.TEST')) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindNXHostsEntry('match.nxdomain3.test')) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv4 entries (4)

  if not(THostsCache.FindIPv4AddressHostsEntry('MATCH.IPV4DOMAIN4-127-0-0-1.TEST', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv4AddressHostsEntry('match.ipv4domain4-127-0-0-1.test', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv6 entries (4)

  if not(THostsCache.FindIPv6AddressHostsEntry('MATCH.IPV6DOMAIN4-LOCALHOST.TEST', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv6AddressHostsEntry('match.ipv6domain4-LOCALHOST.test', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  // FW entries (4)

  if not(THostsCache.FindFWHostsEntry('MATCH.FWDOMAIN4.TEST')) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindFWHostsEntry('match.fwdomain4.test')) then begin
    raise FailedUnitTestException.Create;
  end;

  // NX entries (4)

  if not(THostsCache.FindNXHostsEntry('MATCH.NXDOMAIN4.TEST')) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindNXHostsEntry('match.nxdomain4.test')) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv4 entries (5)

  if not(THostsCache.FindIPv4AddressHostsEntry('MATCH.IPV4DOMAIN5-127-0-0-1.TEST', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv4AddressHostsEntry('match.ipv4domain5-127-0-0-1.test', HostsEntryIPv4Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv4AddressUtility.AreEqual(HostsEntryIPv4Address, LOCALHOST_IPV4_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv6 entries (5)

  if not(THostsCache.FindIPv6AddressHostsEntry('MATCH.IPV6DOMAIN5-LOCALHOST.TEST', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindIPv6AddressHostsEntry('match.ipv6domain5-LOCALHOST.test', HostsEntryIPv6Address)) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(TIPv6AddressUtility.AreEqual(HostsEntryIPv6Address, LOCALHOST_IPV6_ADDRESS)) then begin
    raise FailedUnitTestException.Create;
  end;

  // FW entries (4)

  if not(THostsCache.FindFWHostsEntry('MATCH.FWDOMAIN5.TEST')) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindFWHostsEntry('match.fwdomain5.test')) then begin
    raise FailedUnitTestException.Create;
  end;

  // NX entries (4)

  if not(THostsCache.FindNXHostsEntry('MATCH.NXDOMAIN5.TEST')) then begin
    raise FailedUnitTestException.Create;
  end;

  if not(THostsCache.FindNXHostsEntry('match.nxdomain5.test')) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv4 nonexistant entry

  if THostsCache.FindIPv4AddressHostsEntry('IPV4NONEXISTANTDOMAIN', HostsEntryIPv4Address) then begin
    raise FailedUnitTestException.Create;
  end;

  // IPv6 nonexistant entry

  if THostsCache.FindIPv6AddressHostsEntry('IPV6NONEXISTANTDOMAIN', HostsEntryIPv6Address) then begin
    raise FailedUnitTestException.Create;
  end;

  // FW nonexistant entry

  if THostsCache.FindFWHostsEntry('FWNONEXISTANTDOMAIN') then begin
    raise FailedUnitTestException.Create;
  end;

  // NX nonexistant entry

  if THostsCache.FindNXHostsEntry('NXNONEXISTANTDOMAIN') then begin
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
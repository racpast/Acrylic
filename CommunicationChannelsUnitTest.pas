// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TCommunicationChannelsUnitTest = class(TAbstractUnitTest)
    private
      BufferA: Pointer;
      BufferB: Pointer;
      BufferLenA: Integer;
      BufferLenB: Integer;
      ServerPort: Word;
    public
      constructor Create;
      procedure   ExecuteTest; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TCommunicationChannelsUnitTest.Create;

begin

  inherited Create;

  Self.BufferA := TMemoryManager.GetMemory(MAX_DNS_PACKET_LEN);
  Self.BufferB := TMemoryManager.GetMemory(MAX_DNS_PACKET_LEN);

  Self.ServerPort := 2001;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TCommunicationChannelsUnitTest.ExecuteTest;

var
  TimeStamp: TDateTime; InitSeed: Integer; i, j: Integer; IPv4Address: TIPv4Address; IPv6Address: TIPv6Address; Port: Word; IPv4UdpServerCommunicationChannel: TIPv4UdpCommunicationChannel; IPv4UdpClientCommunicationChannel: TIPv4UdpCommunicationChannel; IPv6UdpServerCommunicationChannel: TIPv6UdpCommunicationChannel; IPv6UdpClientCommunicationChannel: TIPv6UdpCommunicationChannel;

begin

  TimeStamp := Now;

  InitSeed := Round(Frac(TimeStamp) * 8640000.0);

  TCommunicationChannel.Initialize;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Address parsing...');

  IPv4Address := TIPv4AddressUtility.Parse('0.0.0.0');
  if not((TIPv4AddressUtility.ToString(IPv4Address) = '0.0.0.0')) then raise FailedUnitTestException.Create;

  IPv4Address := TIPv4AddressUtility.Parse('0.0.0.1');
  if not((TIPv4AddressUtility.ToString(IPv4Address) = '0.0.0.1')) then raise FailedUnitTestException.Create;

  IPv4Address := TIPv4AddressUtility.Parse('1.0.0.0');
  if not((TIPv4AddressUtility.ToString(IPv4Address) = '1.0.0.0')) then raise FailedUnitTestException.Create;

  IPv4Address := TIPv4AddressUtility.Parse('1.0.0.1');
  if not((TIPv4AddressUtility.ToString(IPv4Address) = '1.0.0.1')) then raise FailedUnitTestException.Create;

  IPv4Address := TIPv4AddressUtility.Parse('0.1.0.0');
  if not((TIPv4AddressUtility.ToString(IPv4Address) = '0.1.0.0')) then raise FailedUnitTestException.Create;

  IPv4Address := TIPv4AddressUtility.Parse('0.0.1.0');
  if not((TIPv4AddressUtility.ToString(IPv4Address) = '0.0.1.0')) then raise FailedUnitTestException.Create;

  IPv4Address := TIPv4AddressUtility.Parse('0.1.0.1');
  if not((TIPv4AddressUtility.ToString(IPv4Address) = '0.1.0.1')) then raise FailedUnitTestException.Create;

  IPv4Address := TIPv4AddressUtility.Parse('1.2.3.4');
  if not((TIPv4AddressUtility.ToString(IPv4Address) = '1.2.3.4')) then raise FailedUnitTestException.Create;

  IPv4Address := TIPv4AddressUtility.Parse('127.0.0.1');
  if not((TIPv4AddressUtility.ToString(IPv4Address) = '127.0.0.1')) then raise FailedUnitTestException.Create;

  IPv4Address := TIPv4AddressUtility.Parse('127.255.127.255');
  if not((TIPv4AddressUtility.ToString(IPv4Address) = '127.255.127.255')) then raise FailedUnitTestException.Create;

  IPv4Address := TIPv4AddressUtility.Parse('113.249.111.247');
  if not((TIPv4AddressUtility.ToString(IPv4Address) = '113.249.111.247')) then raise FailedUnitTestException.Create;

  IPv6Address := TIPv6AddressUtility.Parse('::');
  if not((TIPv6AddressUtility.ToString(IPv6Address) = '0:0:0:0:0:0:0:0')) then raise FailedUnitTestException.Create;

  IPv6Address := TIPv6AddressUtility.Parse('::1');
  if not((TIPv6AddressUtility.ToString(IPv6Address) = '0:0:0:0:0:0:0:1')) then raise FailedUnitTestException.Create;

  IPv6Address := TIPv6AddressUtility.Parse('1::');
  if not((TIPv6AddressUtility.ToString(IPv6Address) = '1:0:0:0:0:0:0:0')) then raise FailedUnitTestException.Create;

  IPv6Address := TIPv6AddressUtility.Parse('1::1');
  if not((TIPv6AddressUtility.ToString(IPv6Address) = '1:0:0:0:0:0:0:1')) then raise FailedUnitTestException.Create;

  IPv6Address := TIPv6AddressUtility.Parse('::2:1');
  if not((TIPv6AddressUtility.ToString(IPv6Address) = '0:0:0:0:0:0:2:1')) then raise FailedUnitTestException.Create;

  IPv6Address := TIPv6AddressUtility.Parse('1:2::');
  if not((TIPv6AddressUtility.ToString(IPv6Address) = '1:2:0:0:0:0:0:0')) then raise FailedUnitTestException.Create;

  IPv6Address := TIPv6AddressUtility.Parse('::f00f:1');
  if not((TIPv6AddressUtility.ToString(IPv6Address) = '0:0:0:0:0:0:F00F:1')) then raise FailedUnitTestException.Create;

  IPv6Address := TIPv6AddressUtility.Parse('1:f00f::');
  if not((TIPv6AddressUtility.ToString(IPv6Address) = '1:F00F:0:0:0:0:0:0')) then raise FailedUnitTestException.Create;

  IPv6Address := TIPv6AddressUtility.Parse('1:2:3:4:5:6::8');
  if not((TIPv6AddressUtility.ToString(IPv6Address) = '1:2:3:4:5:6:0:8')) then raise FailedUnitTestException.Create;

  IPv6Address := TIPv6AddressUtility.Parse('1:2:3:4:5::7:8');
  if not((TIPv6AddressUtility.ToString(IPv6Address) = '1:2:3:4:5:0:7:8')) then raise FailedUnitTestException.Create;

  IPv6Address := TIPv6AddressUtility.Parse('1:2:3:4::6:7:8');
  if not((TIPv6AddressUtility.ToString(IPv6Address) = '1:2:3:4:0:6:7:8')) then raise FailedUnitTestException.Create;

  IPv6Address := TIPv6AddressUtility.Parse('1:2:3::5:6:7:8');
  if not((TIPv6AddressUtility.ToString(IPv6Address) = '1:2:3:0:5:6:7:8')) then raise FailedUnitTestException.Create;

  IPv6Address := TIPv6AddressUtility.Parse('1:2::4:5:6:7:8');
  if not((TIPv6AddressUtility.ToString(IPv6Address) = '1:2:0:4:5:6:7:8')) then raise FailedUnitTestException.Create;

  IPv6Address := TIPv6AddressUtility.Parse('1::3:4:5:6:7:8');
  if not((TIPv6AddressUtility.ToString(IPv6Address) = '1:0:3:4:5:6:7:8')) then raise FailedUnitTestException.Create;

  IPv6Address := TIPv6AddressUtility.Parse('1:2:3:4:5:6:7:8');
  if not((TIPv6AddressUtility.ToString(IPv6Address) = '1:2:3:4:5:6:7:8')) then raise FailedUnitTestException.Create;

  IPv6Address := TIPv6AddressUtility.Parse('ff05::1:3');
  if not((TIPv6AddressUtility.ToString(IPv6Address) = 'FF05:0:0:0:0:0:1:3')) then raise FailedUnitTestException.Create;

  IPv6Address := TIPv6AddressUtility.Parse('ff05::2:1:3');
  if not((TIPv6AddressUtility.ToString(IPv6Address) = 'FF05:0:0:0:0:2:1:3')) then raise FailedUnitTestException.Create;

  IPv6Address := TIPv6AddressUtility.Parse('9B:9B:9B:9B:9B:9B:9B:9B');
  if not((TIPv6AddressUtility.ToString(IPv6Address) = '9B:9B:9B:9B:9B:9B:9B:9B')) then raise FailedUnitTestException.Create;

  IPv6Address := TIPv6AddressUtility.Parse('2001:db8:85a3::8a2e:370:7334');
  if not((TIPv6AddressUtility.ToString(IPv6Address) = '2001:DB8:85A3:0:0:8A2E:370:7334')) then raise FailedUnitTestException.Create;

  IPv6Address := TIPv6AddressUtility.Parse('2001:db8:85a3:aaa:bbb:8a2e:370:7334');
  if not((TIPv6AddressUtility.ToString(IPv6Address) = '2001:DB8:85A3:AAA:BBB:8A2E:370:7334')) then raise FailedUnitTestException.Create;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Testing IPv4 UDP client and server communication...');

  IPv4UdpServerCommunicationChannel := TIPv4UdpCommunicationChannel.Create;

  IPv4UdpServerCommunicationChannel.Bind(LOCALHOST_IPV4_ADDRESS, ServerPort);

  RandSeed := InitSeed;

  for i := 1 to 1000 do begin

    BufferLenA := Random(512) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLenA - 1) do PByteArray(BufferA)^[j] := Random(256);

    IPv4UdpClientCommunicationChannel := TIPv4UdpCommunicationChannel.Create;

    IPv4UdpClientCommunicationChannel.Bind(ANY_IPV4_ADDRESS);

    IPv4UdpClientCommunicationChannel.Send(Self.BufferA, Self.BufferLenA, LOCALHOST_IPV4_ADDRESS, Self.ServerPort);

    if not IPv4UdpServerCommunicationChannel.Receive(1000, MAX_DNS_BUFFER_LEN, Self.BufferB, Self.BufferLenB, IPv4Address, Port) then begin
      raise FailedUnitTestException.Create;
    end;

    if (Self.BufferLenB <> Self.BufferLenA) and not(CompareMem(Self.BufferA, Self.BufferB, Self.BufferLenA)) then begin
      raise FailedUnitTestException.Create;
    end;

    IPv4UdpClientCommunicationChannel.Free;

  end;

  IPv4UdpServerCommunicationChannel.Free;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Testing IPv6 UDP client and server communication...');

  IPv6UdpServerCommunicationChannel := TIPv6UdpCommunicationChannel.Create;

  IPv6UdpServerCommunicationChannel.Bind(LOCALHOST_IPV6_ADDRESS, ServerPort);

  RandSeed := InitSeed;

  for i := 1 to 1000 do begin

    BufferLenA := Random(512) + MIN_DNS_PACKET_LEN; for j := 0 to (BufferLenA - 1) do PByteArray(BufferA)^[j] := Random(256);

    IPv6UdpClientCommunicationChannel := TIPv6UdpCommunicationChannel.Create;

    IPv6UdpClientCommunicationChannel.Bind(ANY_IPV6_ADDRESS);

    IPv6UdpClientCommunicationChannel.Send(Self.BufferA, Self.BufferLenA, LOCALHOST_IPV6_ADDRESS, Self.ServerPort);

    if not IPv6UdpServerCommunicationChannel.Receive(1000, MAX_DNS_BUFFER_LEN, Self.BufferB, Self.BufferLenB, IPv6Address, Port) then begin
      raise FailedUnitTestException.Create;
    end;

    if (Self.BufferLenB <> Self.BufferLenA) and not(CompareMem(Self.BufferA, Self.BufferB, Self.BufferLenA)) then begin
      raise FailedUnitTestException.Create;
    end;

    IPv6UdpClientCommunicationChannel.Free;

  end;

  IPv6UdpServerCommunicationChannel.Free;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  TCommunicationChannel.Finalize;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TCommunicationChannelsUnitTest.Destroy;

begin

  TMemoryManager.FreeMemory(Self.BufferB, MAX_DNS_PACKET_LEN);
  TMemoryManager.FreeMemory(Self.BufferA, MAX_DNS_PACKET_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------
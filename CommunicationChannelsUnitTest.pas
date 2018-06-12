// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TCommunicationChannelsUnitTest = class(TAbstractUnitTest)
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

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TCommunicationChannelsUnitTest.ExecuteTest;

var
  IPv4Address: TIPv4Address; IPv6Address: TIPv6Address;

begin

  // Init class
  TCommunicationChannel.Initialize;

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

  // Finalize class
  TCommunicationChannel.Finalize;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TCommunicationChannelsUnitTest.Destroy;

begin

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------
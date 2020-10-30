// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  CommunicationChannels;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Configuration,
  DnsProtocol,
  IPUtils;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TCommunicationChannel = class
    public
      class procedure Initialize;
      class procedure Finalize;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4UdpCommunicationChannel = class
    private
      IPv4UdpSocketHandle: Integer;
    public
      constructor Create;
      procedure   Bind(BindingAddress: TIPv4Address); overload;
      procedure   Bind(BindingAddress: TIPv4Address; BindingPort: Word); overload;
      procedure   Send(Buffer: Pointer; BufferLen: Integer; DestinationAddress: TIPv4Address; DestinationPort: Word);
      function    Receive(Timeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer; var RemoteAddress: TIPv4Address; var RemotePort: Word): Boolean;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6UdpCommunicationChannel = class
    private
      IPv6UdpSocketHandle: Integer;
    public
      constructor Create;
      procedure   Bind(BindingAddress: TIPv6Address); overload;
      procedure   Bind(BindingAddress: TIPv6Address; BindingPort: Word); overload;
      procedure   Send(Buffer: Pointer; BufferLen: Integer; DestinationAddress: TIPv6Address; DestinationPort: Word);
      function    Receive(Timeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer; var RemoteAddress: TIPv6Address; var RemotePort: Word): Boolean;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4TcpCommunicationChannel = class
    private
      IPv4TcpSocketHandle: Integer;
    public
      IsConnected: Boolean;
    public
      RemoteAddress: TIPv4Address;
      RemotePort: Word;
    public
      constructor Create; overload;
      constructor Create(IPv4TcpSocketHandle: Integer; RemoteAddress: TIPv4Address; RemotePort: Word); overload;
      procedure   Bind(BindingAddress: TIPv4Address; BindingPort: Word);
      function    Listen: TIPv4TcpCommunicationChannel;
      procedure   Connect(RemoteAddress: TIPv4Address; RemotePort: Word);
      procedure   Send(Buffer: Pointer; BufferLen: Integer);
      function    Receive(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer): Boolean;
      function    PerformSocks5Handshake(ProxyFirstByteTimeout: Integer; ProxyOtherBytesTimeout: Integer; ProxyRemoteConnectTimeout: Integer; RemoteAddress: TDualIPAddress; RemotePort: Word): Boolean;
      destructor  Destroy; override;
    private
      procedure   InternalSend(Buffer: Pointer; BufferLen: Integer);
      procedure   InternalSendContinue(Buffer: Pointer; BufferLen: Integer; BytesSent: Integer);
      function    InternalReceive(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; Buffer: Pointer; BufferLen: Integer): Boolean;
      function    InternalReceiveContinue(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; Buffer: Pointer; BufferLen: Integer; BytesReceived: Integer): Boolean;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6TcpCommunicationChannel = class
    private
      IPv6TcpSocketHandle: Integer;
    public
      IsConnected: Boolean;
    public
      RemoteAddress: TIpv6Address;
      RemotePort: Word;
    public
      constructor Create; overload;
      constructor Create(IPv6TcpSocketHandle: Integer; RemoteAddress: TIPv6Address; RemotePort: Word); overload;
      procedure   Bind(BindingAddress: TIPv6Address; BindingPort: Word);
      function    Listen: TIPv6TcpCommunicationChannel;
      procedure   Connect(RemoteAddress: TIPv6Address; RemotePort: Word);
      procedure   Send(Buffer: Pointer; BufferLen: Integer);
      function    Receive(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer): Boolean;
      function    PerformSocks5Handshake(ProxyFirstByteTimeout: Integer; ProxyOtherBytesTimeout: Integer; ProxyRemoteConnectTimeout: Integer; RemoteAddress: TDualIPAddress; RemotePort: Word): Boolean;
      destructor  Destroy; override;
    private
      procedure   InternalSend(Buffer: Pointer; BufferLen: Integer);
      procedure   InternalSendContinue(Buffer: Pointer; BufferLen: Integer; BytesSent: Integer);
      function    InternalReceive(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; Buffer: Pointer; BufferLen: Integer): Boolean;
      function    InternalReceiveContinue(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; Buffer: Pointer; BufferLen: Integer; BytesReceived: Integer): Boolean;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TDnsOverHttpsCommunicationChannel = class
    public
      constructor Create;
      function    SendAndReceiveUsingWinInet(RequestBuffer: Pointer; RequestBufferLen: Integer; const DestinationAddress: String; DestinationPort: Word; const DestinationPath: String; const DestinationHost: String; ConnectionType: TDnsOverHttpsProtocolConnectionType; ReuseConnections: Boolean; ResponseTimeout: Integer; MaxResponseBufferLen: Integer; var ResponseBuffer: Pointer; var ResponseBufferLen: Integer): Boolean;
      function    SendAndReceiveUsingWinHttp(RequestBuffer: Pointer; RequestBufferLen: Integer; const DestinationAddress: String; DestinationPort: Word; const DestinationPath: String; const DestinationHost: String; ConnectionType: TDnsOverHttpsProtocolConnectionType; ReuseConnections: Boolean; ResponseTimeout: Integer; MaxResponseBufferLen: Integer; var ResponseBuffer: Pointer; var ResponseBufferLen: Integer): Boolean;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SysUtils,
  WinInet,
  AcrylicVersionInfo,
  WinHttp,
  WinSock;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TCommunicationChannel.Initialize;

var
  WSAData: TWSAData;

begin

  WSAStartup(WINDOWS_SOCKETS_VERSION, WSAData);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TCommunicationChannel.Finalize;

begin

  WSACleanup;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4UdpCommunicationChannel.Create;

begin

  Self.IPv4UdpSocketHandle := INVALID_SOCKET;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4UdpCommunicationChannel.Bind(BindingAddress: TIPv4Address);

var
  IPv4SocketAddress: TIPv4SocketAddress;

begin

  Self.IPv4UdpSocketHandle := Socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);

  if not(IsValidSocketHandle(Self.IPv4UdpSocketHandle)) then raise Exception.Create('TIPv4UdpCommunicationChannel.Bind: Socket allocation failed.');

  FillChar(IPv4SocketAddress, SizeOf(TIPv4SocketAddress), 0);

  IPv4SocketAddress.sin_family := AF_INET; IPv4SocketAddress.sin_addr := BindingAddress;

  if not(IsValidSocketResult(IPv4Bind(Self.IPv4UdpSocketHandle, IPv4SocketAddress, SizeOf(TIPv4SocketAddress)))) then raise Exception.Create('TIPv4UdpCommunicationChannel.Bind: Bind failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4UdpCommunicationChannel.Bind(BindingAddress: TIPv4Address; BindingPort: Word);

var
  IPv4SocketAddress: TIPv4SocketAddress;

begin

  Self.IPv4UdpSocketHandle := Socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);

  if not(IsValidSocketHandle(Self.IPv4UdpSocketHandle)) then raise Exception.Create('TIPv4UdpCommunicationChannel.Bind: Socket allocation failed.');

  FillChar(IPv4SocketAddress, SizeOf(TIPv4SocketAddress), 0);

  IPv4SocketAddress.sin_family := AF_INET; IPv4SocketAddress.sin_addr := BindingAddress; IPv4SocketAddress.sin_port := HTONS(BindingPort);

  if not(IsValidSocketResult(IPv4Bind(Self.IPv4UdpSocketHandle, IPv4SocketAddress, SizeOf(TIPv4SocketAddress)))) then raise Exception.Create('TIPv4UdpCommunicationChannel.Bind: Bind failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4UdpCommunicationChannel.Send(Buffer: Pointer; BufferLen: Integer; DestinationAddress: TIPv4Address; DestinationPort: Word);

var
  IPv4SocketAddress: TIPv4SocketAddress;

begin

  FillChar(IPv4SocketAddress, SizeOf(TIPv4SocketAddress), 0);

  IPv4SocketAddress.sin_family := AF_INET; IPv4SocketAddress.sin_addr := DestinationAddress; IPv4SocketAddress.sin_port := HTONS(DestinationPort);

  if not(IsValidSocketResult(IPv4SendTo(Self.IPv4UdpSocketHandle, Buffer^, BufferLen, 0, IPv4SocketAddress, SizeOf(TIPv4SocketAddress)))) then raise Exception.Create('TIPv4UdpCommunicationChannel.Send: Send failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv4UdpCommunicationChannel.Receive(Timeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer; var RemoteAddress: TIPv4Address; var RemotePort: Word): Boolean;

var
  TimeVal: TTimeVal; ReadFDSet: TFDSet; SelectResult: Integer; IPv4SocketAddress: TIPv4SocketAddress; IPv4SocketAddressSize: Integer;

begin

  Result := False;

  TimeVal.tv_sec := Timeout div 1000;
  TimeVal.tv_usec := 1000 * (Timeout mod 1000);

  ReadFDSet.fd_count := 1; ReadFDSet.fd_array[0] := Self.IPv4UdpSocketHandle;

  SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if not(IsValidSocketResult(SelectResult)) then raise Exception.Create('TIPv4UdpCommunicationChannel.Receive: Select failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (SelectResult > 0) then begin

    IPv4SocketAddressSize := SizeOf(TIPv4SocketAddress); BufferLen := IPv4RecvFrom(Self.IPv4UdpSocketHandle, Buffer^, MaxBufferLen, 0, IPv4SocketAddress, IPv4SocketAddressSize);

    if (BufferLen > 0) then begin

      RemoteAddress := IPv4SocketAddress.sin_addr; RemotePort := HTONS(IPv4SocketAddress.sin_port); Result := True; Exit;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4UdpCommunicationChannel.Destroy;

begin

  if IsValidSocketHandle(Self.IPv4UdpSocketHandle) then CloseSocket(Self.IPv4UdpSocketHandle);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6UdpCommunicationChannel.Create;

begin

  Self.IPv6UdpSocketHandle := INVALID_SOCKET;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6UdpCommunicationChannel.Bind(BindingAddress: TIPv6Address);

var
  IPv6SocketAddress: TIPv6SocketAddress;

begin

  Self.IPv6UdpSocketHandle := Socket(AF_INET6, SOCK_DGRAM, IPPROTO_UDP);

  if not(IsValidSocketHandle(Self.IPv6UdpSocketHandle)) then raise Exception.Create('TIPv6UdpCommunicationChannel.Bind: Socket allocation failed.');

  FillChar(IPv6SocketAddress, SizeOf(TIPv6SocketAddress), 0);

  IPv6SocketAddress.sin_family := AF_INET6; IPv6SocketAddress.sin_addr := BindingAddress;

  if not(IsValidSocketResult(IPv6Bind(Self.IPv6UdpSocketHandle, IPv6SocketAddress, SizeOf(TIPv6SocketAddress)))) then raise Exception.Create('TIPv6UdpCommunicationChannel.Bind: Bind failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6UdpCommunicationChannel.Bind(BindingAddress: TIPv6Address; BindingPort: Word);

var
  IPv6SocketAddress: TIPv6SocketAddress;

begin

  Self.IPv6UdpSocketHandle := Socket(AF_INET6, SOCK_DGRAM, IPPROTO_UDP);

  if not(IsValidSocketHandle(Self.IPv6UdpSocketHandle)) then raise Exception.Create('TIPv6UdpCommunicationChannel.Bind: Socket allocation failed.');

  FillChar(IPv6SocketAddress, SizeOf(TIPv6SocketAddress), 0);

  IPv6SocketAddress.sin_family := AF_INET6; IPv6SocketAddress.sin_addr := BindingAddress; IPv6SocketAddress.sin_port := HTONS(BindingPort);

  if not(IsValidSocketResult(IPv6Bind(Self.IPv6UdpSocketHandle, IPv6SocketAddress, SizeOf(TIPv6SocketAddress)))) then raise Exception.Create('TIPv6UdpCommunicationChannel.Bind: Bind failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6UdpCommunicationChannel.Send(Buffer: Pointer; BufferLen: Integer; DestinationAddress: TIPv6Address; DestinationPort: Word);

var
  IPv6SocketAddress: TIPv6SocketAddress;

begin

  FillChar(IPv6SocketAddress, SizeOf(TIPv6SocketAddress), 0);

  IPv6SocketAddress.sin_family := AF_INET6; IPv6SocketAddress.sin_addr := DestinationAddress; IPv6SocketAddress.sin_port := HTONS(DestinationPort);

  if not(IsValidSocketResult(IPv6SendTo(Self.IPv6UdpSocketHandle, Buffer^, BufferLen, 0, IPv6SocketAddress, SizeOf(TIPv6SocketAddress)))) then raise Exception.Create('TIPv6UdpCommunicationChannel.Send: Send failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv6UdpCommunicationChannel.Receive(Timeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer; var RemoteAddress: TIPv6Address; var RemotePort: Word): Boolean;

var
  TimeVal: TTimeVal; ReadFDSet: TFDSet; SelectResult: Integer; IPv6SocketAddress: TIPv6SocketAddress; IPv6SocketAddressSize: Integer;

begin

  Result := False;

  TimeVal.tv_sec := Timeout div 1000;
  TimeVal.tv_usec := 1000 * (Timeout mod 1000);

  ReadFDSet.fd_count := 1; ReadFDSet.fd_array[0] := Self.IPv6UdpSocketHandle;

  SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if not(IsValidSocketResult(SelectResult)) then raise Exception.Create('TIPv6UdpCommunicationChannel.Receive: Select failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (SelectResult > 0) then begin

    IPv6SocketAddressSize := SizeOf(TIPv6SocketAddress); BufferLen := IPv6RecvFrom(Self.IPv6UdpSocketHandle, Buffer^, MaxBufferLen, 0, IPv6SocketAddress, IPv6SocketAddressSize);

    if (BufferLen > 0) then begin

      RemoteAddress := IPv6SocketAddress.sin_addr; RemotePort := HTONS(IPv6SocketAddress.sin_port); Result := True; Exit;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6UdpCommunicationChannel.Destroy;

begin

  if IsValidSocketHandle(Self.IPv6UdpSocketHandle) then CloseSocket(Self.IPv6UdpSocketHandle);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4TcpCommunicationChannel.Create;

begin

  Self.IPv4TcpSocketHandle := INVALID_SOCKET;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4TcpCommunicationChannel.Create(IPv4TcpSocketHandle: Integer; RemoteAddress: TIPv4Address; RemotePort: Word);

begin

  Self.IPv4TcpSocketHandle := IPv4TcpSocketHandle;

  Self.RemoteAddress := RemoteAddress; Self.RemotePort := RemotePort; Self.IsConnected := True;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4TcpCommunicationChannel.Bind(BindingAddress: TIPv4Address; BindingPort: Word);

var
  IPv4SocketAddress: TIPv4SocketAddress;

begin

  Self.IPv4TcpSocketHandle := Socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

  if not(IsValidSocketHandle(Self.IPv4TcpSocketHandle)) then raise Exception.Create('TIPv4TcpCommunicationChannel.Bind: Socket allocation failed.');

  FillChar(IPv4SocketAddress, SizeOf(TIPv4SocketAddress), 0);

  IPv4SocketAddress.sin_family := AF_INET; IPv4SocketAddress.sin_addr := BindingAddress; IPv4SocketAddress.sin_port := HTONS(BindingPort);

  if not(IsValidSocketResult(IPv4Bind(Self.IPv4TcpSocketHandle, IPv4SocketAddress, SizeOf(TIPv4SocketAddress)))) then raise Exception.Create('TIPv4TcpCommunicationChannel.Bind: Bind failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv4TcpCommunicationChannel.Listen: TIPv4TcpCommunicationChannel;

var
  IPv4TcpSessionSocketHandle: Integer; IPv4SocketAddress: TIPv4SocketAddress; IPv4SocketAddressSize: Integer;

begin

  if (IPv4Listen(Self.IPv4TcpSocketHandle, 200) = 0) then begin

    IPv4SocketAddressSize := SizeOf(TIPv4SocketAddress); IPv4TcpSessionSocketHandle := IPv4Accept(Self.IPv4TcpSocketHandle, IPv4SocketAddress, IPv4SocketAddressSize); if IsValidSocketHandle(IPv4TcpSessionSocketHandle) then begin

      Result := TIPv4TcpCommunicationChannel.Create(IPv4TcpSessionSocketHandle, IPv4SocketAddress.sin_addr, HTONS(IPv4SocketAddress.sin_port)); Exit;

    end;

  end;

  Result := nil;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4TcpCommunicationChannel.Connect(RemoteAddress: TIPv4Address; RemotePort: Word);

var
  IPv4SocketAddress: TIPv4SocketAddress;

begin

  Self.IPv4TcpSocketHandle := Socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

  if not(IsValidSocketHandle(Self.IPv4TcpSocketHandle)) then raise Exception.Create('TIPv4TcpCommunicationChannel.Connect: Socket allocation failed.');

  FillChar(IPv4SocketAddress, SizeOf(TIPv4SocketAddress), 0);

  IPv4SocketAddress.sin_family := AF_INET; IPv4SocketAddress.sin_addr := RemoteAddress; IPv4SocketAddress.sin_port := HTONS(RemotePort);

  if not(IsValidSocketResult(IPv4Connect(Self.IPv4TcpSocketHandle, IPv4SocketAddress, SizeOf(TIPv4SocketAddress)))) then raise Exception.Create('TIPv4TcpCommunicationChannel.Connect: Connect to address ' + TIPv4AddressUtility.ToString(RemoteAddress) + ' and port ' + IntToStr(RemotePort) + ' failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

  Self.RemoteAddress := RemoteAddress; Self.RemotePort := RemotePort; Self.IsConnected := True;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4TcpCommunicationChannel.Send(Buffer: Pointer; BufferLen: Integer);

var
  DnsPacketLen: Word;

begin

  DnsPacketLen := HTONS(Word(BufferLen)); Self.InternalSend(@DnsPacketLen, SizeOf(Word)); Self.InternalSend(Buffer, BufferLen);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4TcpCommunicationChannel.InternalSend(Buffer: Pointer; BufferLen: Integer);

var
  IPv4SendResult: Integer;

begin

  IPv4SendResult := IPv4Send(Self.IPv4TcpSocketHandle, Buffer^, BufferLen, 0); if not(IsValidSocketResult(IPv4SendResult)) then raise Exception.Create('TIPv4TcpCommunicationChannel.Send: Send failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv4SendResult = 0) then raise Exception.Create('TIPv4TcpCommunicationChannel.Send: Send failed with Windows Sockets reporting 0 bytes sent.'); if (IPv4SendResult < BufferLen) then Self.InternalSendContinue(Buffer, BufferLen, IPv4SendResult);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4TcpCommunicationChannel.InternalSendContinue(Buffer: Pointer; BufferLen: Integer; BytesSent: Integer);

var
  BytesRemaining: Integer; IPv4SendResult: Integer;

begin

  BytesRemaining := BufferLen - BytesSent; IPv4SendResult := IPv4Send(Self.IPv4TcpSocketHandle, Pointer(Integer(Buffer) + BytesSent)^, BytesRemaining, 0); if not(IsValidSocketResult(IPv4SendResult)) then raise Exception.Create('TIPv4TcpCommunicationChannel.Send: Send failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv4SendResult = 0) then raise Exception.Create('TIPv4TcpClientCommunicationChannel.Send: Send failed with Windows Sockets reporting 0 bytes sent.'); while (IPv4SendResult < BytesRemaining) do begin

    BytesSent := BytesSent + IPv4SendResult; BytesRemaining := BytesRemaining - IPv4SendResult; IPv4SendResult := IPv4Send(Self.IPv4TcpSocketHandle, Pointer(Integer(Buffer) + BytesSent)^, BytesRemaining, 0); if not(IsValidSocketResult(IPv4SendResult)) then raise Exception.Create('TIPv4TcpCommunicationChannel.Send: Send failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv4SendResult = 0) then raise Exception.Create('TIPv4TcpCommunicationChannel.Send: Send failed with Windows Sockets reporting 0 bytes sent.');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv4TcpCommunicationChannel.Receive(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer): Boolean;

var
  DnsPacketLen: Word;

begin

  Result := False;

  if Self.InternalReceive(FirstByteTimeout, OtherBytesTimeout, @DnsPacketLen, SizeOf(Word)) then begin

    DnsPacketLen := HTONS(DnsPacketLen); if (DnsPacketLen > MaxBufferLen) then DnsPacketLen := MaxBufferLen;

    if Self.InternalReceive(OtherBytesTimeout, OtherBytesTimeout, Buffer, DnsPacketLen) then begin

      BufferLen := DnsPacketLen; Result := True;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv4TcpCommunicationChannel.InternalReceive(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; Buffer: Pointer; BufferLen: Integer): Boolean;

var
  TimeVal: TTimeVal; ReadFDSet: TFDSet; SelectResult: Integer; IPv4RecvResult: Integer;

begin

  Result := False;

  TimeVal.tv_sec := FirstByteTimeout div 1000;
  TimeVal.tv_usec := 1000 * (FirstByteTimeout mod 1000);

  ReadFDSet.fd_count := 1; ReadFDSet.fd_array[0] := Self.IPv4TcpSocketHandle;

  SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if not(IsValidSocketResult(SelectResult)) then raise Exception.Create('TIPv4TcpCommunicationChannel.Receive: Select failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (SelectResult > 0) then begin

    IPv4RecvResult := IPv4Recv(Self.IPv4TcpSocketHandle, Buffer^, BufferLen, 0); if not(IsValidSocketResult(IPv4RecvResult)) then raise Exception.Create('TIPv4TcpCommunicationChannel.Receive: Receive failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv4RecvResult = 0) then raise Exception.Create('TIPv4TcpCommunicationChannel.Receive: Receive failed with Windows Sockets reporting 0 bytes received.'); if (IPv4RecvResult < BufferLen) then Result := Self.InternalReceiveContinue(FirstByteTimeout, OtherBytesTimeout, Buffer, BufferLen, IPv4RecvResult) else Result := True;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv4TcpCommunicationChannel.InternalReceiveContinue(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; Buffer: Pointer; BufferLen: Integer; BytesReceived: Integer): Boolean;

var
  TimeVal: TTimeVal; ReadFDSet: TFDSet; SelectResult: Integer; BytesRemaining: Integer; IPv4RecvResult: Integer;

begin

  Result := False;

  TimeVal.tv_sec := OtherBytesTimeout div 1000;
  TimeVal.tv_usec := 1000 * (OtherBytesTimeout mod 1000);

  ReadFDSet.fd_count := 1; ReadFDSet.fd_array[0] := Self.IPv4TcpSocketHandle;

  SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if not(IsValidSocketResult(SelectResult)) then raise Exception.Create('TIPv4TcpCommunicationChannel.Receive: Select failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (SelectResult > 0) then begin

    BytesRemaining := BufferLen - BytesReceived; IPv4RecvResult := IPv4Recv(Self.IPv4TcpSocketHandle, Pointer(Integer(Buffer) + BytesReceived)^, BytesRemaining, 0); if not(IsValidSocketResult(IPv4RecvResult)) then raise Exception.Create('TIPv4TcpCommunicationChannel.Receive: Receive failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv4RecvResult = 0) then raise Exception.Create('TIPv4TcpCommunicationChannel.Receive: Receive failed with Windows Sockets reporting 0 bytes received.'); while (IPv4RecvResult < BytesRemaining) do begin

      SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if not(IsValidSocketResult(SelectResult)) then raise Exception.Create('TIPv4TcpCommunicationChannel.Receive: Select failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (SelectResult > 0) then begin

        BytesReceived := BytesReceived + IPv4RecvResult; BytesRemaining := BytesRemaining - IPv4RecvResult; IPv4RecvResult := IPv4Recv(Self.IPv4TcpSocketHandle, Pointer(Integer(Buffer) + BytesReceived)^, BytesRemaining, 0); if not(IsValidSocketResult(IPv4RecvResult)) then raise Exception.Create('TIPv4TcpCommunicationChannel.Receive: Receive failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv4RecvResult = 0) then raise Exception.Create('TIPv4TcpCommunicationChannel.Receive: Receive failed with Windows Sockets reporting 0 bytes received.');

      end else begin

        Exit;

      end;

    end;

    Result := True;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv4TcpCommunicationChannel.PerformSocks5Handshake(ProxyFirstByteTimeout: Integer; ProxyOtherBytesTimeout: Integer; ProxyRemoteConnectTimeout: Integer; RemoteAddress: TDualIPAddress; RemotePort: Word): Boolean;

var
  Socks5Buffer: Array [0..1023] of Byte;

begin

  Socks5Buffer[00] := $05;
  Socks5Buffer[01] := $01;
  Socks5Buffer[02] := $00;

  Self.InternalSend(@Socks5Buffer, 3); if Self.InternalReceive(ProxyFirstByteTimeout, ProxyOtherBytesTimeout, @Socks5Buffer, 2) then begin

    if RemoteAddress.IsIPv6Address then begin

      Socks5Buffer[00] := $05;
      Socks5Buffer[01] := $01;
      Socks5Buffer[02] := $00;
      Socks5Buffer[03] := $04;

      Move(RemoteAddress.IPv6Address, Socks5Buffer[04], SizeOf(TIPv6Address));

      Socks5Buffer[20] := RemotePort shr $08;
      Socks5Buffer[21] := RemotePort and $ff;

      Self.InternalSend(@Socks5Buffer, 22); if Self.InternalReceive(ProxyRemoteConnectTimeout, ProxyOtherBytesTimeout, @Socks5Buffer, 22) then begin

        if (Socks5Buffer[01] <> 0) then begin

          raise Exception.Create('TIPv4TcpCommunicationChannel.PerformSocks5Handshake: Handshake failed on phase 3 with reply ' + IntToStr(Socks5Buffer[01]) + '.');

        end;

        Result := True;

      end else begin

        raise Exception.Create('TIPv4TcpCommunicationChannel.PerformSocks5Handshake: Handshake failed on phase 2.');

      end;

    end else begin

      Socks5Buffer[00] := $05;
      Socks5Buffer[01] := $01;
      Socks5Buffer[02] := $00;
      Socks5Buffer[03] := $01;

      Move(RemoteAddress.IPv4Address, Socks5Buffer[04], SizeOf(TIPv4Address));

      Socks5Buffer[08] := RemotePort shr $08;
      Socks5Buffer[09] := RemotePort and $ff;

      Self.InternalSend(@Socks5Buffer, 10);

      if Self.InternalReceive(ProxyRemoteConnectTimeout, ProxyOtherBytesTimeout, @Socks5Buffer, 10) then begin

        if (Socks5Buffer[01] <> 0) then begin

          raise Exception.Create('TIPv4TcpCommunicationChannel.PerformSocks5Handshake: Handshake failed on phase 3 with reply ' + IntToStr(Socks5Buffer[01]) + '.');

        end;

        Result := True;

      end else begin

        raise Exception.Create('TIPv4TcpCommunicationChannel.PerformSocks5Handshake: Handshake failed on phase 2.');

      end;

    end;

  end else begin

    raise Exception.Create('TIPv4TcpCommunicationChannel.PerformSocks5Handshake: Handshake failed on phase 1.');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4TcpCommunicationChannel.Destroy;

begin

  if IsValidSocketHandle(Self.IPv4TcpSocketHandle) then begin if Self.IsConnected then IPv4Shutdown(Self.IPv4TcpSocketHandle, 2); CloseSocket(Self.IPv4TcpSocketHandle); end;

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6TcpCommunicationChannel.Create;

begin

  Self.IPv6TcpSocketHandle := INVALID_SOCKET;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6TcpCommunicationChannel.Create(IPv6TcpSocketHandle: Integer; RemoteAddress: TIPv6Address; RemotePort: Word);

begin

  Self.IPv6TcpSocketHandle := IPv6TcpSocketHandle;

  Self.RemoteAddress := RemoteAddress; Self.RemotePort := RemotePort; Self.IsConnected := True;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6TcpCommunicationChannel.Bind(BindingAddress: TIPv6Address; BindingPort: Word);

var
  IPv6SocketAddress: TIPv6SocketAddress;

begin

  Self.IPv6TcpSocketHandle := Socket(AF_INET6, SOCK_STREAM, IPPROTO_TCP);

  if not(IsValidSocketHandle(Self.IPv6TcpSocketHandle)) then raise Exception.Create('TIPv6TcpCommunicationChannel.Bind: Socket allocation failed.');

  FillChar(IPv6SocketAddress, SizeOf(IPv6SocketAddress), 0);

  IPv6SocketAddress.sin_family := AF_INET6; IPv6SocketAddress.sin_addr := BindingAddress; IPv6SocketAddress.sin_port := HTONS(BindingPort);

  if not(IsValidSocketResult(IPv6Bind(Self.IPv6TcpSocketHandle, IPv6SocketAddress, SizeOf(TIPv6SocketAddress)))) then raise Exception.Create('TIPv6TcpCommunicationChannel.Bind: Bind failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv6TcpCommunicationChannel.Listen: TIPv6TcpCommunicationChannel;

var
  IPv6TcpChildSocketHandle: Integer; IPv6SocketAddress: TIPv6SocketAddress; IPv6SocketAddressSize: Integer;

begin

  if (IPv6Listen(Self.IPv6TcpSocketHandle, 200) = 0) then begin

    IPv6SocketAddressSize := SizeOf(TIPv6SocketAddress); IPv6TcpChildSocketHandle := IPv6Accept(Self.IPv6TcpSocketHandle, IPv6SocketAddress, IPv6SocketAddressSize); if IsValidSocketHandle(IPv6TcpChildSocketHandle) then begin

      Result := TIPv6TcpCommunicationChannel.Create(IPv6TcpChildSocketHandle, IPv6SocketAddress.sin_addr, HTONS(IPv6SocketAddress.sin_port)); Exit;

    end;

  end;

  Result := nil;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6TcpCommunicationChannel.Connect(RemoteAddress: TIPv6Address; RemotePort: Word);

var
  IPv6SocketAddress: TIPv6SocketAddress;

begin

  Self.IPv6TcpSocketHandle := Socket(AF_INET6, SOCK_STREAM, IPPROTO_TCP);

  if not(IsValidSocketHandle(Self.IPv6TcpSocketHandle)) then raise Exception.Create('TIPv6TcpCommunicationChannel.Create: Socket allocation failed.');

  FillChar(IPv6SocketAddress, SizeOf(TIPv6SocketAddress), 0);

  IPv6SocketAddress.sin_family := AF_INET6; IPv6SocketAddress.sin_addr := RemoteAddress; IPv6SocketAddress.sin_port := HTONS(RemotePort);

  if not(IsValidSocketResult(IPv6Connect(Self.IPv6TcpSocketHandle, IPv6SocketAddress, SizeOf(TIPv6SocketAddress)))) then raise Exception.Create('TIPv6TcpCommunicationChannel.Connect: Connect to address ' + TIPv6AddressUtility.ToString(RemoteAddress) + ' and port ' + IntToStr(RemotePort) + ' failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

  Self.RemoteAddress := RemoteAddress; Self.RemotePort := RemotePort; Self.IsConnected := True;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6TcpCommunicationChannel.Send(Buffer: Pointer; BufferLen: Integer);

var
  DnsPacketLen: Word;

begin

  DnsPacketLen := HTONS(Word(BufferLen)); Self.InternalSend(@DnsPacketLen, SizeOf(Word)); Self.InternalSend(Buffer, BufferLen);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6TcpCommunicationChannel.InternalSend(Buffer: Pointer; BufferLen: Integer);

var
  IPv6SendResult: Integer;

begin

  IPv6SendResult := IPv6Send(Self.IPv6TcpSocketHandle, Buffer^, BufferLen, 0); if not(IsValidSocketResult(IPv6SendResult)) then raise Exception.Create('TIPv6TcpCommunicationChannel.Send: Send failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv6SendResult = 0) then raise Exception.Create('TIPv6TcpCommunicationChannel.Send: Send failed with Windows Sockets reporting 0 bytes sent.'); if (IPv6SendResult < BufferLen) then Self.InternalSendContinue(Buffer, BufferLen, IPv6SendResult);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6TcpCommunicationChannel.InternalSendContinue(Buffer: Pointer; BufferLen: Integer; BytesSent: Integer);

var
  BytesRemaining: Integer; IPv6SendResult: Integer;

begin

  BytesRemaining := BufferLen - BytesSent; IPv6SendResult := IPv6Send(Self.IPv6TcpSocketHandle, Pointer(Integer(Buffer) + BytesSent)^, BytesRemaining, 0); if not(IsValidSocketResult(IPv6SendResult)) then raise Exception.Create('TIPv6TcpCommunicationChannel.Send: Send failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv6SendResult = 0) then raise Exception.Create('TIPv6TcpCommunicationChannel.Send: Send failed with Windows Sockets reporting 0 bytes sent.'); while (IPv6SendResult < BytesRemaining) do begin

    BytesSent := BytesSent + IPv6SendResult; BytesRemaining := BytesRemaining - IPv6SendResult; IPv6SendResult := IPv6Send(Self.IPv6TcpSocketHandle, Pointer(Integer(Buffer) + BytesSent)^, BytesRemaining, 0); if not(IsValidSocketResult(IPv6SendResult)) then raise Exception.Create('TIPv6TcpCommunicationChannel.Send: Send failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv6SendResult = 0) then raise Exception.Create('TIPv6TcpCommunicationChannel.Send: Send failed with Windows Sockets reporting 0 bytes sent.');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv6TcpCommunicationChannel.Receive(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer): Boolean;

var
  DnsPacketLen: Word;

begin

  Result := False;

  if Self.InternalReceive(FirstByteTimeout, OtherBytesTimeout, @DnsPacketLen, SizeOf(Word)) then begin

    DnsPacketLen := HTONS(DnsPacketLen); if (DnsPacketLen > MaxBufferLen) then DnsPacketLen := MaxBufferLen;

    if Self.InternalReceive(OtherBytesTimeout, OtherBytesTimeout, Buffer, DnsPacketLen) then begin

      BufferLen := DnsPacketLen; Result := True;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv6TcpCommunicationChannel.InternalReceive(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; Buffer: Pointer; BufferLen: Integer): Boolean;

var
  TimeVal: TTimeVal; ReadFDSet: TFDSet; SelectResult: Integer; IPv6RecvResult: Integer;

begin

  Result := False;

  TimeVal.tv_sec := FirstByteTimeout div 1000;
  TimeVal.tv_usec := 1000 * (FirstByteTimeout mod 1000);

  ReadFDSet.fd_count := 1; ReadFDSet.fd_array[0] := Self.IPv6TcpSocketHandle;

  SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if not(IsValidSocketResult(SelectResult)) then raise Exception.Create('TIPv6TcpCommunicationChannel.Receive: Select failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (SelectResult > 0) then begin

    IPv6RecvResult := IPv6Recv(Self.IPv6TcpSocketHandle, Buffer^, BufferLen, 0); if not(IsValidSocketResult(IPv6RecvResult)) then raise Exception.Create('TIPv6TcpCommunicationChannel.Receive: Receive failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv6RecvResult = 0) then raise Exception.Create('TIPv6TcpCommunicationChannel.Receive: Receive failed with Windows Sockets reporting 0 bytes received.'); if (IPv6RecvResult < BufferLen) then Result := Self.InternalReceiveContinue(FirstByteTimeout, OtherBytesTimeout, Buffer, BufferLen, IPv6RecvResult) else Result := True;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv6TcpCommunicationChannel.InternalReceiveContinue(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; Buffer: Pointer; BufferLen: Integer; BytesReceived: Integer): Boolean;

var
  TimeVal: TTimeVal; ReadFDSet: TFDSet; SelectResult: Integer; BytesRemaining: Integer; IPv6RecvResult: Integer;

begin

  Result := False;

  TimeVal.tv_sec := OtherBytesTimeout div 1000;
  TimeVal.tv_usec := 1000 * (OtherBytesTimeout mod 1000);

  ReadFDSet.fd_count := 1; ReadFDSet.fd_array[0] := Self.IPv6TcpSocketHandle;

  SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if not(IsValidSocketResult(SelectResult)) then raise Exception.Create('TIPv6TcpCommunicationChannel.Receive: Select failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (SelectResult > 0) then begin

    BytesRemaining := BufferLen - BytesReceived; IPv6RecvResult := IPv6Recv(Self.IPv6TcpSocketHandle, Pointer(Integer(Buffer) + BytesReceived)^, BytesRemaining, 0); if not(IsValidSocketResult(IPv6RecvResult)) then raise Exception.Create('TIPv6TcpCommunicationChannel.Receive: Receive failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv6RecvResult = 0) then raise Exception.Create('TIPv6TcpCommunicationChannel.Receive: Receive failed with Windows Sockets reporting 0 bytes received.'); while (IPv6RecvResult < BytesRemaining) do begin

      SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if not(IsValidSocketResult(SelectResult)) then raise Exception.Create('TIPv6TcpCommunicationChannel.Receive: Select failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (SelectResult > 0) then begin

        BytesReceived := BytesReceived + IPv6RecvResult; BytesRemaining := BytesRemaining - IPv6RecvResult; IPv6RecvResult := IPv6Recv(Self.IPv6TcpSocketHandle, Pointer(Integer(Buffer) + BytesReceived)^, BytesRemaining, 0); if not(IsValidSocketResult(IPv6RecvResult)) then raise Exception.Create('TIPv6TcpCommunicationChannel.Receive: Receive failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv6RecvResult = 0) then raise Exception.Create('TIPv6TcpCommunicationChannel.Receive: Receive failed with Windows Sockets reporting 0 bytes received.');

      end else begin

        Exit;

      end;

    end;

    Result := True;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv6TcpCommunicationChannel.PerformSocks5Handshake(ProxyFirstByteTimeout: Integer; ProxyOtherBytesTimeout: Integer; ProxyRemoteConnectTimeout: Integer; RemoteAddress: TDualIPAddress; RemotePort: Word): Boolean;

var
  Socks5Buffer: Array [0..1023] of Byte;

begin

  Socks5Buffer[00] := $05;
  Socks5Buffer[01] := $01;
  Socks5Buffer[02] := $00;

  Self.InternalSend(@Socks5Buffer, 3); if Self.InternalReceive(ProxyFirstByteTimeout, ProxyOtherBytesTimeout, @Socks5Buffer, 2) then begin

    if RemoteAddress.IsIPv6Address then begin

      Socks5Buffer[00] := $05;
      Socks5Buffer[01] := $01;
      Socks5Buffer[02] := $00;
      Socks5Buffer[03] := $04;

      Move(RemoteAddress.IPv6Address, Socks5Buffer[04], SizeOf(TIPv6Address));

      Socks5Buffer[20] := RemotePort shr $08;
      Socks5Buffer[21] := RemotePort and $ff;

      Self.InternalSend(@Socks5Buffer, 22); if Self.InternalReceive(ProxyRemoteConnectTimeout, ProxyOtherBytesTimeout, @Socks5Buffer, 22) then begin

        if (Socks5Buffer[01] <> 0) then begin

          raise Exception.Create('TIPv6TcpCommunicationChannel.PerformSocks5Handshake: Handshake failed on phase 3 with reply ' + IntToStr(Socks5Buffer[01]) + '.');

        end;

        Result := True;

      end else begin

        raise Exception.Create('TIPv6TcpCommunicationChannel.PerformSocks5Handshake: Handshake failed on phase 2.');

      end;

    end else begin

      Socks5Buffer[00] := $05;
      Socks5Buffer[01] := $01;
      Socks5Buffer[02] := $00;
      Socks5Buffer[03] := $01;

      Move(RemoteAddress.IPv6Address, Socks5Buffer[04], SizeOf(TIPv6Address));

      Socks5Buffer[08] := RemotePort shr $08;
      Socks5Buffer[09] := RemotePort and $ff;

      Self.InternalSend(@Socks5Buffer, 10);

      if Self.InternalReceive(ProxyRemoteConnectTimeout, ProxyOtherBytesTimeout, @Socks5Buffer, 10) then begin

        if (Socks5Buffer[01] <> 0) then begin

          raise Exception.Create('TIPv6TcpCommunicationChannel.PerformSocks5Handshake: Handshake failed on phase 3 with reply ' + IntToStr(Socks5Buffer[01]) + '.');

        end;

        Result := True;

      end else begin

        raise Exception.Create('TIPv6TcpCommunicationChannel.PerformSocks5Handshake: Handshake failed on phase 2.');

      end;

    end;

  end else begin

    raise Exception.Create('TIPv6TcpCommunicationChannel.PerformSocks5Handshake: Handshake failed on phase 1.');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6TcpCommunicationChannel.Destroy;

begin

  if IsValidSocketHandle(Self.IPv6TcpSocketHandle) then begin if Self.IsConnected then IPv6Shutdown(Self.IPv6TcpSocketHandle, 2); CloseSocket(Self.IPv6TcpSocketHandle); end;

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TDnsOverHttpsCommunicationChannel.Create;

begin

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TDnsOverHttpsCommunicationChannel.SendAndReceiveUsingWinInet(RequestBuffer: Pointer; RequestBufferLen: Integer; const DestinationAddress: String; DestinationPort: Word; const DestinationPath: String; const DestinationHost: String; ConnectionType: TDnsOverHttpsProtocolConnectionType; ReuseConnections: Boolean; ResponseTimeout: Integer; MaxResponseBufferLen: Integer; var ResponseBuffer: Pointer; var ResponseBufferLen: Integer): Boolean;

var
  InternetConnectionType: Cardinal; InternetHandle: HINTERNET; InternetConnectHandle: Pointer; InternetHttpOpenRequestFlags: Cardinal; InternetHttpOpenRequestHandle: Pointer; InternetHttpOpenRequestSecurityFlags: Cardinal; InternetHttpOpenRequestSecurityFlagsBufferLength: Cardinal; HttpRequestHeaders: String; NumberOfBytesRead: Cardinal;

begin

  Result := False;

  if (ConnectionType = SystemDnsOverHttpsProtocolConnectionType) then InternetConnectionType := INTERNET_OPEN_TYPE_PRECONFIG else if (ConnectionType = DirectDnsOverHttpsProtocolConnectionType) then InternetConnectionType := INTERNET_OPEN_TYPE_DIRECT else InternetConnectionType := INTERNET_OPEN_TYPE_PRECONFIG;

  InternetHandle := WinInet.InternetOpen(PChar('AcrylicDNSProxy/' + AcrylicVersionNumber + #0), InternetConnectionType, nil, nil, 0);

  if (InternetHandle = nil) then begin

    raise Exception.Create('TDnsOverHttpsClientCommunicationChannel.SendAndReceiveUsingWinInet: WinInet.InternetOpen failed with error code ' + IntToStr(GetLastError) + '.');

  end;

  try

    InternetConnectHandle := WinInet.InternetConnect(InternetHandle, PChar(DestinationAddress + #0), DestinationPort, nil, nil, INTERNET_SERVICE_HTTP, 0, 0);

    if (InternetConnectHandle = nil) then begin

      raise Exception.Create('TDnsOverHttpsClientCommunicationChannel.SendAndReceiveUsingWinInet: WinInet.InternetConnect failed with error code ' + IntToStr(GetLastError) + '.');

    end;

    try

      if ReuseConnections then InternetHttpOpenRequestFlags := INTERNET_FLAG_SECURE or INTERNET_FLAG_NO_CACHE_WRITE or INTERNET_FLAG_KEEP_CONNECTION else InternetHttpOpenRequestFlags := INTERNET_FLAG_SECURE or INTERNET_FLAG_NO_CACHE_WRITE;

      InternetHttpOpenRequestHandle := WinInet.HttpOpenRequest(InternetConnectHandle, PChar('POST' + #0), PChar(DestinationPath + #0), nil, nil, nil, InternetHttpOpenRequestFlags, 0);

      if (InternetHttpOpenRequestHandle = nil) then begin

        raise Exception.Create('TDnsOverHttpsClientCommunicationChannel.SendAndReceiveUsingWinInet: WinInet.HttpOpenRequest failed with error code ' + IntToStr(GetLastError) + '.');

      end;

      InternetHttpOpenRequestSecurityFlagsBufferLength := SizeOf(InternetHttpOpenRequestSecurityFlags);

      if not(WinInet.InternetQueryOption(InternetHttpOpenRequestHandle, INTERNET_OPTION_SECURITY_FLAGS, @InternetHttpOpenRequestSecurityFlags, InternetHttpOpenRequestSecurityFlagsBufferLength)) then begin

        raise Exception.Create('TDnsOverHttpsClientCommunicationChannel.SendAndReceiveUsingWinInet: WinInet.InternetQueryOption failed with error code ' + IntToStr(GetLastError) + '.');

      end;

      InternetHttpOpenRequestSecurityFlags := InternetHttpOpenRequestSecurityFlags or SECURITY_FLAG_IGNORE_REVOCATION;

      if not(WinInet.InternetSetOption(InternetHttpOpenRequestHandle, INTERNET_OPTION_SECURITY_FLAGS, @InternetHttpOpenRequestSecurityFlags, InternetHttpOpenRequestSecurityFlagsBufferLength)) then begin

        raise Exception.Create('TDnsOverHttpsClientCommunicationChannel.SendAndReceiveUsingWinInet: WinInet.InternetSetOption failed with error code ' + IntToStr(GetLastError) + '.');

      end;

      try

        HttpRequestHeaders := 'Host: ' + DestinationHost + #10 + 'Content-Type: application/dns-message' + #10 + 'Accept: application/dns-message' + #10;

        if not WinInet.HttpSendRequest(InternetHttpOpenRequestHandle, PChar(HttpRequestHeaders), Length(HttpRequestHeaders), RequestBuffer, RequestBufferLen) then begin

          raise Exception.Create('TDnsOverHttpsClientCommunicationChannel.SendAndReceiveUsingWinInet: WinInet.HttpSendRequest failed with error code ' + IntToStr(GetLastError) + '.');

        end;

        if not WinInet.InternetReadFile(InternetHttpOpenRequestHandle, ResponseBuffer, MaxResponseBufferLen, NumberOfBytesRead) then begin

          raise Exception.Create('TDnsOverHttpsClientCommunicationChannel.SendAndReceiveUsingWinInet: WinInet.InternetReadFile failed with error code ' + IntToStr(GetLastError) + '.');

        end;

        ResponseBufferLen := NumberOfBytesRead;

        Result := NumberOfBytesRead > 0;

      finally

        WinInet.InternetCloseHandle(InternetHttpOpenRequestHandle);

      end;

    finally

      WinInet.InternetCloseHandle(InternetConnectHandle);

    end;

  finally

    WinInet.InternetCloseHandle(InternetHandle);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TDnsOverHttpsCommunicationChannel.SendAndReceiveUsingWinHttp(RequestBuffer: Pointer; RequestBufferLen: Integer; const DestinationAddress: String; DestinationPort: Word; const DestinationPath: String; const DestinationHost: String; ConnectionType: TDnsOverHttpsProtocolConnectionType; ReuseConnections: Boolean; ResponseTimeout: Integer; MaxResponseBufferLen: Integer; var ResponseBuffer: Pointer; var ResponseBufferLen: Integer): Boolean;

var
  InternetConnectionType: Cardinal; UserAgentWideString: WideString; InternetHandle: Pointer; DestinationAddressWideString: WideString; InternetConnectHandle: Pointer; InternetHttpOpenRequestFlags: Cardinal; InternetHttpOpenRequestVerbWideString: WideString; InternetHttpOpenRequestDestinationPathWideString: WideString; InternetHttpOpenRequestHandle: Pointer; InternetHttpSendRequestHeadersWideString: WideString; NumberOfBytesRead: Cardinal;

begin

  Result := False;

  if (ConnectionType = SystemDnsOverHttpsProtocolConnectionType) then InternetConnectionType := WINHTTP_ACCESS_TYPE_DEFAULT_PROXY else if (ConnectionType = DirectDnsOverHttpsProtocolConnectionType) then InternetConnectionType := WINHTTP_ACCESS_TYPE_NO_PROXY else InternetConnectionType := WINHTTP_ACCESS_TYPE_DEFAULT_PROXY;

  UserAgentWideString := 'AcrylicDNSProxy/' + AcrylicVersionNumber + #0;

  InternetHandle := WinHttpOpen(PWideChar(UserAgentWideString), InternetConnectionType, nil, nil, 0);

  if (InternetHandle = nil) then begin

    raise Exception.Create('TDnsOverHttpsClientCommunicationChannel.SendAndReceiveUsingWinHttp: WinHttpOpen failed with error code ' + IntToStr(GetLastError) + '.');

  end;

  try

    DestinationAddressWideString := DestinationAddress + #0;

    InternetConnectHandle := WinHttpConnect(InternetHandle, PWideChar(DestinationAddressWideString), DestinationPort, 0);

    if (InternetConnectHandle = nil) then begin

      raise Exception.Create('TDnsOverHttpsClientCommunicationChannel.SendAndReceiveUsingWinHttp: WinHttpConnect failed with error code ' + IntToStr(GetLastError) + '.');

    end;

    try

      InternetHttpOpenRequestFlags := WINHTTP_FLAG_SECURE or WINHTTP_FLAG_BYPASS_PROXY_CACHE;

      InternetHttpOpenRequestVerbWideString := 'POST' + #0;

      InternetHttpOpenRequestDestinationPathWideString := DestinationPath + #0;

      InternetHttpOpenRequestHandle := WinHttpOpenRequest(InternetConnectHandle, PWideChar(InternetHttpOpenRequestVerbWideString), PWideChar(InternetHttpOpenRequestDestinationPathWideString), nil, nil, nil, InternetHttpOpenRequestFlags);

      if (InternetHttpOpenRequestHandle = nil) then begin

        raise Exception.Create('TDnsOverHttpsClientCommunicationChannel.SendAndReceiveUsingWinHttp: WinHttpOpenRequest failed with error code ' + IntToStr(GetLastError) + '.');

      end;

      try

        InternetHttpSendRequestHeadersWideString := 'Host: ' + DestinationHost + #10 + 'Content-Type: application/dns-message' + #10 + 'Accept: application/dns-message' + #10;

        if not WinHttpSendRequest(InternetHttpOpenRequestHandle, PWideChar(InternetHttpSendRequestHeadersWideString), Length(InternetHttpSendRequestHeadersWideString), RequestBuffer, RequestBufferLen, RequestBufferLen, 0) then begin

          raise Exception.Create('TDnsOverHttpsClientCommunicationChannel.SendAndReceiveUsingWinHttp: WinHttpSendRequest failed with error code ' + IntToStr(GetLastError) + '.');

        end;

        if not WinHttpReceiveResponse(InternetHttpOpenRequestHandle, nil) then begin

          raise Exception.Create('TDnsOverHttpsClientCommunicationChannel.SendAndReceiveUsingWinHttp: WinHttpReceiveResponse failed with error code ' + IntToStr(GetLastError) + '.');

        end;

        if not WinHttpReadData(InternetHttpOpenRequestHandle, ResponseBuffer, MaxResponseBufferLen, NumberOfBytesRead) then begin

          raise Exception.Create('TDnsOverHttpsClientCommunicationChannel.SendAndReceiveUsingWinHttp: WinHttpReadData failed with error code ' + IntToStr(GetLastError) + '.');

        end;

        ResponseBufferLen := NumberOfBytesRead;

        Result := NumberOfBytesRead > 0;

      finally

        WinHttpCloseHandle(InternetHttpOpenRequestHandle);

      end;

    finally

      WinHttpCloseHandle(InternetConnectHandle);

    end;

  finally

    WinHttpCloseHandle(InternetHandle);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TDnsOverHttpsCommunicationChannel.Destroy;

begin

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

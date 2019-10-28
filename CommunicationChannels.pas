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
  IpUtils;

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
  TIPv4UdpClientCommunicationChannel = class
    private
      SocketHandle: Integer;
    public
      constructor Create;
      procedure   BindToDynamicPort(BindingAddress: TIPv4Address);
      procedure   SendTo(Buffer: Pointer; BufferLen: Integer; DestinationAddress: TIPv4Address; DestinationPort: Word);
      function    ReceiveFrom(Timeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer; var RemoteAddress: TIPv4Address; var RemotePort: Word): Boolean;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6UdpClientCommunicationChannel = class
    private
      SocketHandle: Integer;
    public
      constructor Create;
      procedure   BindToDynamicPort(BindingAddress: TIPv6Address);
      procedure   SendTo(Buffer: Pointer; BufferLen: Integer; DestinationAddress: TIPv6Address; DestinationPort: Word);
      function    ReceiveFrom(Timeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer; var RemoteAddress: TIPv6Address; var RemotePort: Word): Boolean;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TDualUdpServerCommunicationChannel = class
    private
      IPv4SocketHandle: Integer;
      IPv6SocketHandle: Integer;
    public
      constructor Create;
      procedure   Bind(IPv4Binding: Boolean; IPv4BindingAddress: TIPv4Address; IPv4BindingPort: Word; IPv6Binding: Boolean; IPv6BindingAddress: TIPv6Address; IPv6BindingPort: Word);
      procedure   SendTo(Buffer: Pointer; BufferLen: Integer; DestinationAddress: TDualIPAddress; DestinationPort: Word);
      function    ReceiveFrom(Timeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer; var RemoteAddress: TDualIPAddress; var RemotePort: Word): Boolean;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4TcpClientCommunicationChannel = class
    private
      SocketHandle: Integer;
    public
      RemoteAddress: TIPv4Address; RemotePort: Word;
    private
      procedure   Send(Buffer: Pointer; BufferLen: Integer);
      procedure   ContinueSend(Buffer: Pointer; BufferLen: Integer; BytesSent: Integer);
      function    Receive(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; Buffer: Pointer; BufferLen: Integer): Boolean;
      function    ContinueReceive(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; Buffer: Pointer; BufferLen: Integer; BytesReceived: Integer): Boolean;
    public
      constructor Create; overload;
      procedure   Connect(RemoteAddress: TIPv4Address; RemotePort: Word);
      procedure   SendWrappedDnsPacket(Buffer: Pointer; BufferLen: Integer);
      function    ReceiveWrappedDnsPacket(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer): Boolean;
      function    PerformSocks5Handshake(ProxyFirstByteTimeout: Integer; ProxyOtherBytesTimeout: Integer; ProxyRemoteConnectTimeout: Integer; RemoteAddress: TDualIPAddress; RemotePort: Word): Boolean;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6TcpClientCommunicationChannel = class
    private
      SocketHandle: Integer;
    public
      RemoteAddress: TIPv6Address; RemotePort: Word;
    private
      procedure   Send(Buffer: Pointer; BufferLen: Integer);
      procedure   ContinueSend(Buffer: Pointer; BufferLen: Integer; BytesSent: Integer);
      function    Receive(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; Buffer: Pointer; BufferLen: Integer): Boolean;
      function    ContinueReceive(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; Buffer: Pointer; BufferLen: Integer; BytesReceived: Integer): Boolean;
    public
      constructor Create; overload;
      procedure   Connect(RemoteAddress: TIPv6Address; RemotePort: Word);
      procedure   SendWrappedDnsPacket(Buffer: Pointer; BufferLen: Integer);
      function    ReceiveWrappedDnsPacket(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer): Boolean;
      function    PerformSocks5Handshake(ProxyFirstByteTimeout: Integer; ProxyOtherBytesTimeout: Integer; ProxyRemoteConnectTimeout: Integer; RemoteAddress: TDualIPAddress; RemotePort: Word): Boolean;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TDnsOverHttpsClientCommunicationChannel = class
    public
      constructor Create;
      function    SendToAndReceiveFrom(RequestBuffer: Pointer; RequestBufferLen: Integer; const DestinationAddress: String; DestinationPort: Word; const DestinationPath: String; const DestinationHost: String; ConnectionType: TDnsOverHttpsProtocolConnectionType; ReuseConnections: Boolean; ResponseTimeout: Integer; MaxResponseBufferLen: Integer; var ResponseBuffer: Pointer; var ResponseBufferLen: Integer): Boolean;
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
  WinSock;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TCommunicationChannel.Initialize;

var
  WSAData: TWSAData;

begin

  if not((WSAStartup(WINDOWS_SOCKETS_VERSION, WSAData) = 0)) then raise Exception.Create('TCommunicationChannel.Initialize: WSAStartup function failed.');

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

constructor TIPv4UdpClientCommunicationChannel.Create;

begin

  Self.SocketHandle := Socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);

  if not(IsValidSocketHandle(Self.SocketHandle)) then raise Exception.Create('TIPv4UdpClientCommunicationChannel.Create: Socket allocation failed.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4UdpClientCommunicationChannel.BindToDynamicPort(BindingAddress: TIPv4Address);

var
  IPv4SocketAddress: TIPv4SocketAddress;

begin

  FillChar(IPv4SocketAddress, SizeOf(TIPv4SocketAddress), 0);

  IPv4SocketAddress.sin_family := AF_INET; IPv4SocketAddress.sin_addr := BindingAddress;

  if not(IsValidSocketResult(IPv4Bind(Self.SocketHandle, IPv4SocketAddress, SizeOf(TIPv4SocketAddress)))) then raise Exception.Create('TIPv4UdpClientCommunicationChannel.BindToDynamicPort: Binding failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4UdpClientCommunicationChannel.SendTo(Buffer: Pointer; BufferLen: Integer; DestinationAddress: TIPv4Address; DestinationPort: Word);

var
  IPv4SocketAddress: TIPv4SocketAddress;

begin

  FillChar(IPv4SocketAddress, SizeOf(TIPv4SocketAddress), 0);

  IPv4SocketAddress.sin_family := AF_INET; IPv4SocketAddress.sin_addr := DestinationAddress; IPv4SocketAddress.sin_port := HTONS(DestinationPort);

  if not(IsValidSocketResult(IPv4SendTo(Self.SocketHandle, Buffer^, BufferLen, 0, IPv4SocketAddress, SizeOf(TIPv4SocketAddress)))) then raise Exception.Create('TIPv4UdpClientCommunicationChannel.SendTo: Sending failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv4UdpClientCommunicationChannel.ReceiveFrom(Timeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer; var RemoteAddress: TIPv4Address; var RemotePort: Word): Boolean;

var
  TimeVal: TTimeVal; ReadFDSet: TFDSet; SelectResult: Integer; IPv4SocketAddress: TIPv4SocketAddress; IPv4SocketAddressSize: Integer;

begin

  Result := False;

  TimeVal.tv_sec := Timeout div 1000;
  TimeVal.tv_usec := 1000 * (Timeout mod 1000);

  ReadFDSet.fd_count := 1; ReadFDSet.fd_array[0] := Self.SocketHandle;

  SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if IsValidSocketResult(SelectResult) and (SelectResult > 0) then begin

    IPv4SocketAddressSize := SizeOf(TIPv4SocketAddress); BufferLen := IPv4RecvFrom(Self.SocketHandle, Buffer^, MaxBufferLen, 0, IPv4SocketAddress, IPv4SocketAddressSize);

    if (BufferLen > 0) then begin

      RemoteAddress := IPv4SocketAddress.sin_addr; RemotePort := HTONS(IPv4SocketAddress.sin_port); Result := True; Exit;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4UdpClientCommunicationChannel.Destroy;

begin

  if IsValidSocketHandle(Self.SocketHandle) then CloseSocket(Self.SocketHandle);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6UdpClientCommunicationChannel.Create;

begin

  Self.SocketHandle := Socket(AF_INET6, SOCK_DGRAM, IPPROTO_UDP);

  if not(IsValidSocketHandle(Self.SocketHandle)) then raise Exception.Create('TIPv6UdpClientCommunicationChannel.Create: Socket allocation failed.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6UdpClientCommunicationChannel.BindToDynamicPort(BindingAddress: TIPv6Address);

var
  IPv6SocketAddress: TIPv6SocketAddress;

begin

  FillChar(IPv6SocketAddress, SizeOf(TIPv6SocketAddress), 0);

  IPv6SocketAddress.sin_family := AF_INET6; IPv6SocketAddress.sin_addr := BindingAddress;

  if not(IsValidSocketResult(IPv6Bind(Self.SocketHandle, IPv6SocketAddress, SizeOf(TIPv6SocketAddress)))) then raise Exception.Create('TIPv6UdpClientCommunicationChannel.BindToDynamicPort: Binding failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6UdpClientCommunicationChannel.SendTo(Buffer: Pointer; BufferLen: Integer; DestinationAddress: TIPv6Address; DestinationPort: Word);

var
  IPv6SocketAddress: TIPv6SocketAddress;

begin

  FillChar(IPv6SocketAddress, SizeOf(TIPv6SocketAddress), 0);

  IPv6SocketAddress.sin_family := AF_INET6; IPv6SocketAddress.sin_addr := DestinationAddress; IPv6SocketAddress.sin_port := HTONS(DestinationPort);

  if not(IsValidSocketResult(IPv6SendTo(Self.SocketHandle, Buffer^, BufferLen, 0, IPv6SocketAddress, SizeOf(TIPv6SocketAddress)))) then raise Exception.Create('TIPv6UdpClientCommunicationChannel.SendTo: Sending failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv6UdpClientCommunicationChannel.ReceiveFrom(Timeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer; var RemoteAddress: TIPv6Address; var RemotePort: Word): Boolean;

var
  TimeVal: TTimeVal; ReadFDSet: TFDSet; SelectResult: Integer; IPv6SocketAddress: TIPv6SocketAddress; IPv6SocketAddressSize: Integer;

begin

  Result := False;

  TimeVal.tv_sec := Timeout div 1000;
  TimeVal.tv_usec := 1000 * (Timeout mod 1000);

  ReadFDSet.fd_count := 1; ReadFDSet.fd_array[0] := Self.SocketHandle;

  SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if IsValidSocketResult(SelectResult) and (SelectResult > 0) then begin

    IPv6SocketAddressSize := SizeOf(TIPv6SocketAddress); BufferLen := IPv6RecvFrom(Self.SocketHandle, Buffer^, MaxBufferLen, 0, IPv6SocketAddress, IPv6SocketAddressSize);

    if (BufferLen > 0) then begin

      RemoteAddress := IPv6SocketAddress.sin_addr; RemotePort := HTONS(IPv6SocketAddress.sin_port); Result := True; Exit;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6UdpClientCommunicationChannel.Destroy;

begin

  if IsValidSocketHandle(Self.SocketHandle) then CloseSocket(Self.SocketHandle);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TDualUdpServerCommunicationChannel.Create;

begin

  Self.IPv6SocketHandle := INVALID_SOCKET;
  Self.IPv4SocketHandle := INVALID_SOCKET;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TDualUdpServerCommunicationChannel.Bind(IPv4Binding: Boolean; IPv4BindingAddress: TIPv4Address; IPv4BindingPort: Word; IPv6Binding: Boolean; IPv6BindingAddress: TIPv6Address; IPv6BindingPort: Word);

var
  IPv4SocketAddress: TIPv4SocketAddress; IPv6SocketAddress: TIPv6SocketAddress;

begin

  if IPv6Binding then begin

    Self.IPv6SocketHandle := Socket(AF_INET6, SOCK_DGRAM, IPPROTO_UDP);

    if not(IsValidSocketHandle(Self.IPv6SocketHandle)) then raise Exception.Create('TDualUdpServerCommunicationChannel.Bind: IPv6 socket allocation failed.');

    FillChar(IPv6SocketAddress, SizeOf(TIPv6SocketAddress), 0);

    IPv6SocketAddress.sin_family := AF_INET6; IPv6SocketAddress.sin_addr := IPv6BindingAddress; IPv6SocketAddress.sin_port := HTONS(IPv6BindingPort);

    if not(IsValidSocketResult(IPv6Bind(Self.IPv6SocketHandle, IPv6SocketAddress, SizeOf(TIPv6SocketAddress)))) then raise Exception.Create('TDualUdpServerCommunicationChannel.Bind: Binding to IPv6 address failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

  end;

  if IPv4Binding then begin

    Self.IPv4SocketHandle := Socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);

    if not(IsValidSocketHandle(Self.IPv4SocketHandle)) then raise Exception.Create('TDualUdpServerCommunicationChannel.Bind: IPv4 socket allocation failed.');

    FillChar(IPv4SocketAddress, SizeOf(TIPv4SocketAddress), 0);

    IPv4SocketAddress.sin_family := AF_INET; IPv4SocketAddress.sin_addr := IPv4BindingAddress; IPv4SocketAddress.sin_port := HTONS(IPv4BindingPort);

    if not(IsValidSocketResult(IPv4Bind(Self.IPv4SocketHandle, IPv4SocketAddress, SizeOf(TIPv4SocketAddress)))) then raise Exception.Create('TDualUdpServerCommunicationChannel.Bind: Binding to IPv4 address failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TDualUdpServerCommunicationChannel.SendTo(Buffer: Pointer; BufferLen: Integer; DestinationAddress: TDualIPAddress; DestinationPort: Word);

var
  IPv4SocketAddress: TIPv4SocketAddress; IPv6SocketAddress: TIPv6SocketAddress;

begin

  if DestinationAddress.IsIPv6Address then begin

    if IsValidSocketHandle(Self.IPv6SocketHandle) then begin

      FillChar(IPv6SocketAddress, SizeOf(TIPv6SocketAddress), 0);

      IPv6SocketAddress.sin_family := AF_INET6; IPv6SocketAddress.sin_addr := DestinationAddress.IPv6Address; IPv6SocketAddress.sin_port := HTONS(DestinationPort);

      if not(IsValidSocketResult(IPv6SendTo(Self.IPv6SocketHandle, Buffer^, BufferLen, 0, IPv6SocketAddress, SizeOf(TIPv6SocketAddress)))) then raise Exception.Create('TDualUdpServerCommunicationChannel.SendTo: Sending to IPv6 address failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

    end else begin

      raise Exception.Create('TDualUdpServerCommunicationChannel.SendTo: Sending to IPv6 address failed because the IPv6 socket is uninitialized.');

    end;

  end else begin

    if IsValidSocketHandle(Self.IPv4SocketHandle) then begin

      FillChar(IPv4SocketAddress, SizeOf(TIPv4SocketAddress), 0);

      IPv4SocketAddress.sin_family := AF_INET; IPv4SocketAddress.sin_addr := DestinationAddress.IPv4Address; IPv4SocketAddress.sin_port := HTONS(DestinationPort);

      if not(IsValidSocketResult(IPv4SendTo(Self.IPv4SocketHandle, Buffer^, BufferLen, 0, IPv4SocketAddress, SizeOf(TIPv4SocketAddress)))) then raise Exception.Create('TDualUdpServerCommunicationChannel.SendTo: Sending to IPv4 address failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

    end else begin

      raise Exception.Create('TDualUdpServerCommunicationChannel.SendTo: Sending to IPv4 address failed because the IPv4 socket is uninitialized.');

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TDualUdpServerCommunicationChannel.ReceiveFrom(Timeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer; var RemoteAddress: TDualIPAddress; var RemotePort: Word): Boolean;

var
  TimeVal: TTimeVal; ReadFDSet: TFDSet; SelectResult: Integer; IPv4SocketAddress: TIPv4SocketAddress; IPv4SocketAddressSize: Integer; IPv6SocketAddress: TIPv6SocketAddress; IPv6SocketAddressSize: Integer;

begin

  Result := False;

  if IsValidSocketHandle(Self.IPv4SocketHandle) and IsValidSocketHandle(Self.IPv6SocketHandle) then begin

    TimeVal.tv_sec := Timeout div 1000;
    TimeVal.tv_usec := 1000 * (Timeout mod 1000);

    ReadFDSet.fd_count := 2; ReadFDSet.fd_array[0] := Self.IPv4SocketHandle; ReadFDSet.fd_array[1] := Self.IPv6SocketHandle;

    SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if IsValidSocketResult(SelectResult) and (SelectResult > 0) then begin

      TimeVal.tv_sec := 0;
      TimeVal.tv_usec := 0;

      ReadFDSet.fd_count := 1; ReadFDSet.fd_array[0] := Self.IPv4SocketHandle;

      SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if IsValidSocketResult(SelectResult) and (SelectResult > 0) then begin

        IPv4SocketAddressSize := SizeOf(TIPv4SocketAddress); BufferLen := IPv4RecvFrom(Self.IPv4SocketHandle, Buffer^, MaxBufferLen, 0, IPv4SocketAddress, IPv4SocketAddressSize);

        if (BufferLen > 0) then begin

          RemoteAddress := TDualIPAddressUtility.CreateFromIPv4Address(IPv4SocketAddress.sin_addr); RemotePort := HTONS(IPv4SocketAddress.sin_port); Result := True; Exit;

        end;

      end;

      TimeVal.tv_sec := 0;
      TimeVal.tv_usec := 0;

      ReadFDSet.fd_count := 1; ReadFDSet.fd_array[0] := Self.IPv6SocketHandle;

      SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if IsValidSocketResult(SelectResult) and (SelectResult > 0) then begin

        IPv6SocketAddressSize := SizeOf(TIPv6SocketAddress); BufferLen := IPv6RecvFrom(Self.IPv6SocketHandle, Buffer^, MaxBufferLen, 0, IPv6SocketAddress, IPv6SocketAddressSize);

        if (BufferLen > 0) then begin

          RemoteAddress := TDualIPAddressUtility.CreateFromIPv6Address(IPv6SocketAddress.sin_addr); RemotePort := HTONS(IPv6SocketAddress.sin_port); Result := True; Exit;

        end;

      end;

    end;

  end else if IsValidSocketHandle(Self.IPv6SocketHandle) then begin

    TimeVal.tv_sec := Timeout div 1000;
    TimeVal.tv_usec := 1000 * (Timeout mod 1000);

    ReadFDSet.fd_count := 1; ReadFDSet.fd_array[0] := Self.IPv6SocketHandle;

    SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if IsValidSocketResult(SelectResult) and (SelectResult > 0) then begin

      IPv6SocketAddressSize := SizeOf(TIPv6SocketAddress); BufferLen := IPv6RecvFrom(Self.IPv6SocketHandle, Buffer^, MaxBufferLen, 0, IPv6SocketAddress, IPv6SocketAddressSize);

      if (BufferLen > 0) then begin

        RemoteAddress := TDualIPAddressUtility.CreateFromIPv6Address(IPv6SocketAddress.sin_addr); RemotePort := HTONS(IPv6SocketAddress.sin_port); Result := True; Exit;

      end;

    end;

  end else if IsValidSocketHandle(Self.IPv4SocketHandle) then begin

    TimeVal.tv_sec := Timeout div 1000;
    TimeVal.tv_usec := 1000 * (Timeout mod 1000);

    ReadFDSet.fd_count := 1; ReadFDSet.fd_array[0] := Self.IPv4SocketHandle;

    SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if IsValidSocketResult(SelectResult) and (SelectResult > 0) then begin

      IPv4SocketAddressSize := SizeOf(TIPv4SocketAddress); BufferLen := IPv4RecvFrom(Self.IPv4SocketHandle, Buffer^, MaxBufferLen, 0, IPv4SocketAddress, IPv4SocketAddressSize);

      if (BufferLen > 0) then begin

        RemoteAddress := TDualIPAddressUtility.CreateFromIPv4Address(IPv4SocketAddress.sin_addr); RemotePort := HTONS(IPv4SocketAddress.sin_port); Result := True; Exit;

      end;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TDualUdpServerCommunicationChannel.Destroy;

begin

  if IsValidSocketHandle(Self.IPv4SocketHandle) then CloseSocket(Self.IPv4SocketHandle);
  if IsValidSocketHandle(Self.IPv6SocketHandle) then CloseSocket(Self.IPv6SocketHandle);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4TcpClientCommunicationChannel.Create;

begin

  Self.SocketHandle := Socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

  if not(IsValidSocketHandle(Self.SocketHandle)) then raise Exception.Create('TIPv4TcpClientCommunicationChannel.Create: Socket allocation failed.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4TcpClientCommunicationChannel.Connect(RemoteAddress: TIPv4Address; RemotePort: Word);

var
  IPv4SocketAddress: TIPv4SocketAddress;

begin

  FillChar(IPv4SocketAddress, SizeOf(TIPv4SocketAddress), 0);

  IPv4SocketAddress.sin_family := AF_INET; IPv4SocketAddress.sin_addr := RemoteAddress; IPv4SocketAddress.sin_port := HTONS(RemotePort);

  if not(IsValidSocketResult(IPv4Connect(Self.SocketHandle, IPv4SocketAddress, SizeOf(TIPv4SocketAddress)))) then raise Exception.Create('TIPv4TcpClientCommunicationChannel.Connect: Connection failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

  Self.RemoteAddress := RemoteAddress; Self.RemotePort := RemotePort;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4TcpClientCommunicationChannel.Send(Buffer: Pointer; BufferLen: Integer);

var
  IPv4SendResult: Integer;

begin

  IPv4SendResult := IPv4Send(Self.SocketHandle, Buffer^, BufferLen, 0); if not(IsValidSocketResult(IPv4SendResult)) then raise Exception.Create('TIPv4TcpClientCommunicationChannel.Send: Sending failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv4SendResult = 0) then raise Exception.Create('TIPv4TcpClientCommunicationChannel.Send: Sending failed with Windows Sockets reporting 0 bytes sent.'); if (IPv4SendResult < BufferLen) then Self.ContinueSend(Buffer, BufferLen, IPv4SendResult);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4TcpClientCommunicationChannel.ContinueSend(Buffer: Pointer; BufferLen: Integer; BytesSent: Integer);

var
  BytesRemaining: Integer; IPv4SendResult: Integer;

begin

  BytesRemaining := BufferLen - BytesSent; IPv4SendResult := IPv4Send(Self.SocketHandle, Pointer(Integer(Buffer) + BytesSent)^, BytesRemaining, 0); if not(IsValidSocketResult(IPv4SendResult)) then raise Exception.Create('TIPv4TcpClientCommunicationChannel.ContinueSend: Sending failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv4SendResult = 0) then raise Exception.Create('TIPv4TcpClientCommunicationChannel.ContinueSend: Sending failed with Windows Sockets reporting 0 bytes sent.'); while (IPv4SendResult < BytesRemaining) do begin

    BytesSent := BytesSent + IPv4SendResult; BytesRemaining := BytesRemaining - IPv4SendResult; IPv4SendResult := IPv4Send(Self.SocketHandle, Pointer(Integer(Buffer) + BytesSent)^, BytesRemaining, 0); if not(IsValidSocketResult(IPv4SendResult)) then raise Exception.Create('TIPv4TcpClientCommunicationChannel.ContinueSend: Sending failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv4SendResult = 0) then raise Exception.Create('TIPv4TcpClientCommunicationChannel.ContinueSend: Sending failed with Windows Sockets reporting 0 bytes sent.');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv4TcpClientCommunicationChannel.Receive(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; Buffer: Pointer; BufferLen: Integer): Boolean;

var
  TimeVal: TTimeVal; ReadFDSet: TFDSet; SelectResult: Integer; IPv4RecvResult: Integer;

begin

  Result := False;

  TimeVal.tv_sec := FirstByteTimeout div 1000;
  TimeVal.tv_usec := 1000 * (FirstByteTimeout mod 1000);

  ReadFDSet.fd_count := 1; ReadFDSet.fd_array[0] := Self.SocketHandle;

  SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if IsValidSocketResult(SelectResult) and (SelectResult > 0) then begin

    IPv4RecvResult := IPv4Recv(Self.SocketHandle, Buffer^, BufferLen, 0); if not(IsValidSocketResult(IPv4RecvResult)) then raise Exception.Create('TIPv4TcpClientCommunicationChannel.Receive: Receiving failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv4RecvResult = 0) then raise Exception.Create('TIPv4TcpClientCommunicationChannel.Receive: Receiving failed with Windows Sockets reporting 0 bytes received.'); if (IPv4RecvResult < BufferLen) then Result := Self.ContinueReceive(FirstByteTimeout, OtherBytesTimeout, Buffer, BufferLen, IPv4RecvResult) else Result := True;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv4TcpClientCommunicationChannel.ContinueReceive(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; Buffer: Pointer; BufferLen: Integer; BytesReceived: Integer): Boolean;

var
  TimeVal: TTimeVal; ReadFDSet: TFDSet; SelectResult: Integer; BytesRemaining: Integer; IPv4RecvResult: Integer;

begin

  Result := False;

  TimeVal.tv_sec := OtherBytesTimeout div 1000;
  TimeVal.tv_usec := 1000 * (OtherBytesTimeout mod 1000);

  ReadFDSet.fd_count := 1; ReadFDSet.fd_array[0] := Self.SocketHandle;

  SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if IsValidSocketResult(SelectResult) and (SelectResult > 0) then begin

    BytesRemaining := BufferLen - BytesReceived; IPv4RecvResult := IPv4Recv(Self.SocketHandle, Pointer(Integer(Buffer) + BytesReceived)^, BytesRemaining, 0); if not(IsValidSocketResult(IPv4RecvResult)) then raise Exception.Create('TIPv4TcpClientCommunicationChannel.ContinueReceive: Receiving failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv4RecvResult = 0) then raise Exception.Create('TIPv4TcpClientCommunicationChannel.ContinueReceive: Receiving failed with Windows Sockets reporting 0 bytes received.'); while (IPv4RecvResult < BytesRemaining) do begin

      SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if IsValidSocketResult(SelectResult) and (SelectResult > 0) then begin

        BytesReceived := BytesReceived + IPv4RecvResult; BytesRemaining := BytesRemaining - IPv4RecvResult; IPv4RecvResult := IPv4Recv(Self.SocketHandle, Pointer(Integer(Buffer) + BytesReceived)^, BytesRemaining, 0); if not(IsValidSocketResult(IPv4RecvResult)) then raise Exception.Create('TIPv4TcpClientCommunicationChannel.ContinueReceive: Receiving failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv4RecvResult = 0) then raise Exception.Create('TIPv4TcpClientCommunicationChannel.ContinueReceive: Receiving failed with Windows Sockets reporting 0 bytes received.');

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

procedure TIPv4TcpClientCommunicationChannel.SendWrappedDnsPacket(Buffer: Pointer; BufferLen: Integer);

var
  DnsPacketLen: Word;

begin

  DnsPacketLen := HTONS(Word(BufferLen)); Self.Send(@DnsPacketLen, SizeOf(Word)); Self.Send(Buffer, BufferLen);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv4TcpClientCommunicationChannel.ReceiveWrappedDnsPacket(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer): Boolean;

var
  DnsPacketLen: Word;

begin

  Result := False;

  if Self.Receive(FirstByteTimeout, OtherBytesTimeout, @DnsPacketLen, SizeOf(Word)) then begin

    DnsPacketLen := HTONS(DnsPacketLen); if (DnsPacketLen > MaxBufferLen) then DnsPacketLen := MaxBufferLen;

    if Self.Receive(OtherBytesTimeout, OtherBytesTimeout, Buffer, DnsPacketLen) then begin

      BufferLen := DnsPacketLen; Result := True;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv4TcpClientCommunicationChannel.PerformSocks5Handshake(ProxyFirstByteTimeout: Integer; ProxyOtherBytesTimeout: Integer; ProxyRemoteConnectTimeout: Integer; RemoteAddress: TDualIPAddress; RemotePort: Word): Boolean;

var
  Socks5Buffer: Array [0..1023] of Byte;

begin

  Socks5Buffer[00] := $05;
  Socks5Buffer[01] := $01;
  Socks5Buffer[02] := $00;

  Self.Send(@Socks5Buffer, 3); if Self.Receive(ProxyFirstByteTimeout, ProxyOtherBytesTimeout, @Socks5Buffer, 2) then begin

    if RemoteAddress.IsIPv6Address then begin

      Socks5Buffer[00] := $05;
      Socks5Buffer[01] := $01;
      Socks5Buffer[02] := $00;
      Socks5Buffer[03] := $04;

      Move(RemoteAddress.IPv6Address, Socks5Buffer[04], SizeOf(TIPv6Address));

      Socks5Buffer[20] := RemotePort shr $08;
      Socks5Buffer[21] := RemotePort and $ff;

      Self.Send(@Socks5Buffer, 22); if Self.Receive(ProxyRemoteConnectTimeout, ProxyOtherBytesTimeout, @Socks5Buffer, 22) then begin

        if (Socks5Buffer[01] <> 0) then begin

          raise Exception.Create('TIPv4TcpClientCommunicationChannel.PerformSocks5Handshake: Handshake failed on phase 3 with reply ' + IntToStr(Socks5Buffer[01]) + '.');

        end;

        Result := True;

      end else begin

        raise Exception.Create('TIPv4TcpClientCommunicationChannel.PerformSocks5Handshake: Handshake failed on phase 2.');

      end;

    end else begin

      Socks5Buffer[00] := $05;
      Socks5Buffer[01] := $01;
      Socks5Buffer[02] := $00;
      Socks5Buffer[03] := $01;

      Move(RemoteAddress.IPv4Address, Socks5Buffer[04], SizeOf(TIPv4Address));

      Socks5Buffer[08] := RemotePort shr $08;
      Socks5Buffer[09] := RemotePort and $ff;

      Self.Send(@Socks5Buffer, 10);

      if Self.Receive(ProxyRemoteConnectTimeout, ProxyOtherBytesTimeout, @Socks5Buffer, 10) then begin

        if (Socks5Buffer[01] <> 0) then begin

          raise Exception.Create('TIPv4TcpClientCommunicationChannel.PerformSocks5Handshake: Handshake failed on phase 3 with reply ' + IntToStr(Socks5Buffer[01]) + '.');

        end;

        Result := True;

      end else begin

        raise Exception.Create('TIPv4TcpClientCommunicationChannel.PerformSocks5Handshake: Handshake failed on phase 2.');

      end;

    end;

  end else begin

    raise Exception.Create('TIPv4TcpClientCommunicationChannel.PerformSocks5Handshake: Handshake failed on phase 1.');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4TcpClientCommunicationChannel.Destroy;

begin

  if IsValidSocketHandle(Self.SocketHandle) then CloseSocket(Self.SocketHandle);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6TcpClientCommunicationChannel.Create;

begin

  Self.SocketHandle := Socket(AF_INET6, SOCK_STREAM, IPPROTO_TCP);

  if not(IsValidSocketHandle(Self.SocketHandle)) then raise Exception.Create('TIPv6TcpClientCommunicationChannel.Create: Socket allocation failed.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6TcpClientCommunicationChannel.Connect(RemoteAddress: TIPv6Address; RemotePort: Word);

var
  IPv6SocketAddress: TIPv6SocketAddress;

begin

  FillChar(IPv6SocketAddress, SizeOf(TIPv6SocketAddress), 0);

  IPv6SocketAddress.sin_family := AF_INET6; IPv6SocketAddress.sin_addr := RemoteAddress; IPv6SocketAddress.sin_port := HTONS(RemotePort);

  if not(IsValidSocketResult(IPv6Connect(Self.SocketHandle, IPv6SocketAddress, SizeOf(TIPv6SocketAddress)))) then raise Exception.Create('TIPv6TcpClientCommunicationChannel.Connect: Connection to address ' + TIPv6AddressUtility.ToString(RemoteAddress) + ' and port ' + IntToStr(RemotePort) + ' failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

  Self.RemoteAddress := RemoteAddress; Self.RemotePort := RemotePort;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6TcpClientCommunicationChannel.Send(Buffer: Pointer; BufferLen: Integer);

var
  IPv6SendResult: Integer;

begin

  IPv6SendResult := IPv6Send(Self.SocketHandle, Buffer^, BufferLen, 0); if not(IsValidSocketResult(IPv6SendResult)) then raise Exception.Create('TIPv6TcpClientCommunicationChannel.Send: Sending failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv6SendResult = 0) then raise Exception.Create('TIPv6TcpClientCommunicationChannel.Send: Sending failed with Windows Sockets reporting 0 bytes sent.'); if (IPv6SendResult < BufferLen) then Self.ContinueSend(Buffer, BufferLen, IPv6SendResult);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6TcpClientCommunicationChannel.ContinueSend(Buffer: Pointer; BufferLen: Integer; BytesSent: Integer);

var
  BytesRemaining: Integer; IPv6SendResult: Integer;

begin

  BytesRemaining := BufferLen - BytesSent; IPv6SendResult := IPv6Send(Self.SocketHandle, Pointer(Integer(Buffer) + BytesSent)^, BytesRemaining, 0); if not(IsValidSocketResult(IPv6SendResult)) then raise Exception.Create('TIPv6TcpClientCommunicationChannel.ContinueSend: Sending failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv6SendResult = 0) then raise Exception.Create('TIPv6TcpClientCommunicationChannel.ContinueSend: Sending failed with Windows Sockets reporting 0 bytes sent.'); while (IPv6SendResult < BytesRemaining) do begin

    BytesSent := BytesSent + IPv6SendResult; BytesRemaining := BytesRemaining - IPv6SendResult; IPv6SendResult := IPv6Send(Self.SocketHandle, Pointer(Integer(Buffer) + BytesSent)^, BytesRemaining, 0); if not(IsValidSocketResult(IPv6SendResult)) then raise Exception.Create('TIPv6TcpClientCommunicationChannel.ContinueSend: Sending failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv6SendResult = 0) then raise Exception.Create('TIPv6TcpClientCommunicationChannel.ContinueSend: Sending failed with Windows Sockets reporting 0 bytes sent.');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv6TcpClientCommunicationChannel.Receive(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; Buffer: Pointer; BufferLen: Integer): Boolean;

var
  TimeVal: TTimeVal; ReadFDSet: TFDSet; SelectResult: Integer; IPv6RecvResult: Integer;

begin

  Result := False;

  TimeVal.tv_sec := FirstByteTimeout div 1000;
  TimeVal.tv_usec := 1000 * (FirstByteTimeout mod 1000);

  ReadFDSet.fd_count := 1; ReadFDSet.fd_array[0] := Self.SocketHandle;

  SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if IsValidSocketResult(SelectResult) and (SelectResult > 0) then begin

    IPv6RecvResult := IPv6Recv(Self.SocketHandle, Buffer^, BufferLen, 0); if not(IsValidSocketResult(IPv6RecvResult)) then raise Exception.Create('TIPv6TcpClientCommunicationChannel.Receive: Receiving failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv6RecvResult = 0) then raise Exception.Create('TIPv6TcpClientCommunicationChannel.Receive: Receiving failed with Windows Sockets reporting 0 bytes received.'); if (IPv6RecvResult < BufferLen) then Result := Self.ContinueReceive(FirstByteTimeout, OtherBytesTimeout, Buffer, BufferLen, IPv6RecvResult) else Result := True;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv6TcpClientCommunicationChannel.ContinueReceive(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; Buffer: Pointer; BufferLen: Integer; BytesReceived: Integer): Boolean;

var
  TimeVal: TTimeVal; ReadFDSet: TFDSet; SelectResult: Integer; BytesRemaining: Integer; IPv6RecvResult: Integer;

begin

  Result := False;

  TimeVal.tv_sec := OtherBytesTimeout div 1000;
  TimeVal.tv_usec := 1000 * (OtherBytesTimeout mod 1000);

  ReadFDSet.fd_count := 1; ReadFDSet.fd_array[0] := Self.SocketHandle;

  SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if IsValidSocketResult(SelectResult) and (SelectResult > 0) then begin

    BytesRemaining := BufferLen - BytesReceived; IPv6RecvResult := IPv6Recv(Self.SocketHandle, Pointer(Integer(Buffer) + BytesReceived)^, BytesRemaining, 0); if not(IsValidSocketResult(IPv6RecvResult)) then raise Exception.Create('TIPv6TcpClientCommunicationChannel.ContinueReceive: Receiving failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv6RecvResult = 0) then raise Exception.Create('TIPv6TcpClientCommunicationChannel.ContinueReceive: Receiving failed with Windows Sockets reporting 0 bytes received.'); while (IPv6RecvResult < BytesRemaining) do begin

      SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if IsValidSocketResult(SelectResult) and (SelectResult > 0) then begin

        BytesReceived := BytesReceived + IPv6RecvResult; BytesRemaining := BytesRemaining - IPv6RecvResult; IPv6RecvResult := IPv6Recv(Self.SocketHandle, Pointer(Integer(Buffer) + BytesReceived)^, BytesRemaining, 0); if not(IsValidSocketResult(IPv6RecvResult)) then raise Exception.Create('TIPv6TcpClientCommunicationChannel.ContinueReceive: Receiving failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); if (IPv6RecvResult = 0) then raise Exception.Create('TIPv6TcpClientCommunicationChannel.ContinueReceive: Receiving failed with Windows Sockets reporting 0 bytes received.');

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

procedure TIPv6TcpClientCommunicationChannel.SendWrappedDnsPacket(Buffer: Pointer; BufferLen: Integer);

var
  DnsPacketLen: Word;

begin

  DnsPacketLen := HTONS(Word(BufferLen)); Self.Send(@DnsPacketLen, SizeOf(Word)); Self.Send(Buffer, BufferLen);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv6TcpClientCommunicationChannel.ReceiveWrappedDnsPacket(FirstByteTimeout: Integer; OtherBytesTimeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer): Boolean;

var
  DnsPacketLen: Word;

begin

  Result := False;

  if Self.Receive(FirstByteTimeout, OtherBytesTimeout, @DnsPacketLen, SizeOf(Word)) then begin

    DnsPacketLen := HTONS(DnsPacketLen); if (DnsPacketLen > MaxBufferLen) then DnsPacketLen := MaxBufferLen;

    if Self.Receive(OtherBytesTimeout, OtherBytesTimeout, Buffer, DnsPacketLen) then begin

      BufferLen := DnsPacketLen; Result := True;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv6TcpClientCommunicationChannel.PerformSocks5Handshake(ProxyFirstByteTimeout: Integer; ProxyOtherBytesTimeout: Integer; ProxyRemoteConnectTimeout: Integer; RemoteAddress: TDualIPAddress; RemotePort: Word): Boolean;

var
  Socks5Buffer: Array [0..1023] of Byte;

begin

  Socks5Buffer[00] := $05;
  Socks5Buffer[01] := $01;
  Socks5Buffer[02] := $00;

  Self.Send(@Socks5Buffer, 3); if Self.Receive(ProxyFirstByteTimeout, ProxyOtherBytesTimeout, @Socks5Buffer, 2) then begin

    if RemoteAddress.IsIPv6Address then begin

      Socks5Buffer[00] := $05;
      Socks5Buffer[01] := $01;
      Socks5Buffer[02] := $00;
      Socks5Buffer[03] := $04;

      Move(RemoteAddress.IPv6Address, Socks5Buffer[04], SizeOf(TIPv6Address));

      Socks5Buffer[20] := RemotePort shr $08;
      Socks5Buffer[21] := RemotePort and $ff;

      Self.Send(@Socks5Buffer, 22); if Self.Receive(ProxyRemoteConnectTimeout, ProxyOtherBytesTimeout, @Socks5Buffer, 22) then begin

        if (Socks5Buffer[01] <> 0) then begin

          raise Exception.Create('TIPv6TcpClientCommunicationChannel.PerformSocks5Handshake: Handshake failed on phase 3 with reply ' + IntToStr(Socks5Buffer[01]) + '.');

        end;

        Result := True;

      end else begin

        raise Exception.Create('TIPv6TcpClientCommunicationChannel.PerformSocks5Handshake: Handshake failed on phase 2.');

      end;

    end else begin

      Socks5Buffer[00] := $05;
      Socks5Buffer[01] := $01;
      Socks5Buffer[02] := $00;
      Socks5Buffer[03] := $01;

      Move(RemoteAddress.IPv6Address, Socks5Buffer[04], SizeOf(TIPv6Address));

      Socks5Buffer[08] := RemotePort shr $08;
      Socks5Buffer[09] := RemotePort and $ff;

      Self.Send(@Socks5Buffer, 10);

      if Self.Receive(ProxyRemoteConnectTimeout, ProxyOtherBytesTimeout, @Socks5Buffer, 10) then begin

        if (Socks5Buffer[01] <> 0) then begin

          raise Exception.Create('TIPv6TcpClientCommunicationChannel.PerformSocks5Handshake: Handshake failed on phase 3 with reply ' + IntToStr(Socks5Buffer[01]) + '.');

        end;

        Result := True;

      end else begin

        raise Exception.Create('TIPv6TcpClientCommunicationChannel.PerformSocks5Handshake: Handshake failed on phase 2.');

      end;

    end;

  end else begin

    raise Exception.Create('TIPv6TcpClientCommunicationChannel.PerformSocks5Handshake: Handshake failed on phase 1.');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6TcpClientCommunicationChannel.Destroy;

begin

  if IsValidSocketHandle(Self.SocketHandle) then CloseSocket(Self.SocketHandle);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TDnsOverHttpsClientCommunicationChannel.Create;

begin

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TDnsOverHttpsClientCommunicationChannel.SendToAndReceiveFrom(RequestBuffer: Pointer; RequestBufferLen: Integer; const DestinationAddress: String; DestinationPort: Word; const DestinationPath: String; const DestinationHost: String; ConnectionType: TDnsOverHttpsProtocolConnectionType; ReuseConnections: Boolean; ResponseTimeout: Integer; MaxResponseBufferLen: Integer; var ResponseBuffer: Pointer; var ResponseBufferLen: Integer): Boolean;

var
  InternetConnectionType: Cardinal; InternetHandle: HINTERNET; InternetConnectHandle: Pointer; InternetHttpOpenRequestFlags: Cardinal; InternetHttpOpenRequestHandle: Pointer; InternetHttpOpenRequestSecurityFlags: Cardinal; InternetHttpOpenRequestSecurityFlagsBufferLength: Cardinal; HttpRequestHeaders: String; NumberOfBytesRead: Cardinal;

begin

  Result := False;

  if (ConnectionType = ConfigDnsOverHttpsProtocolConnectionType) then InternetConnectionType := INTERNET_OPEN_TYPE_PRECONFIG else if (ConnectionType = DirectDnsOverHttpsProtocolConnectionType) then InternetConnectionType := INTERNET_OPEN_TYPE_DIRECT else InternetConnectionType := INTERNET_OPEN_TYPE_PRECONFIG;

  InternetHandle := WinInet.InternetOpen(PChar('AcrylicDNSProxy/' + AcrylicVersionNumber + #0), InternetConnectionType, nil, nil, 0);

  if (InternetHandle = nil) then begin

    raise Exception.Create('TDnsOverHttpsClientCommunicationChannel.SendToAndReceiveFrom: WinInet.InternetOpen failed with error code ' + IntToStr(GetLastError) + '.');

  end;

  try

    InternetConnectHandle := WinInet.InternetConnect(InternetHandle, PChar(DestinationAddress + #0), DestinationPort, nil, nil, INTERNET_SERVICE_HTTP, 0, 0);

    if (InternetConnectHandle = nil) then begin

      raise Exception.Create('TDnsOverHttpsClientCommunicationChannel.SendToAndReceiveFrom: WinInet.InternetConnect failed with error code ' + IntToStr(GetLastError) + '.');

    end;

    try

      if ReuseConnections then InternetHttpOpenRequestFlags := INTERNET_FLAG_SECURE or INTERNET_FLAG_NO_CACHE_WRITE or INTERNET_FLAG_KEEP_CONNECTION else InternetHttpOpenRequestFlags := INTERNET_FLAG_SECURE or INTERNET_FLAG_NO_CACHE_WRITE;

      InternetHttpOpenRequestHandle := WinInet.HttpOpenRequest(InternetConnectHandle, PChar('POST' + #0), PChar(DestinationPath + #0), nil, nil, nil, InternetHttpOpenRequestFlags, 0);

      if (InternetHttpOpenRequestHandle = nil) then begin

        raise Exception.Create('TDnsOverHttpsClientCommunicationChannel.SendToAndReceiveFrom: WinInet.HttpOpenRequest failed with error code ' + IntToStr(GetLastError) + '.');

      end;

      InternetHttpOpenRequestSecurityFlagsBufferLength := SizeOf(InternetHttpOpenRequestSecurityFlags);

      if not(WinInet.InternetQueryOption(InternetHttpOpenRequestHandle, INTERNET_OPTION_SECURITY_FLAGS, @InternetHttpOpenRequestSecurityFlags, InternetHttpOpenRequestSecurityFlagsBufferLength)) then begin

        raise Exception.Create('TDnsOverHttpsClientCommunicationChannel.SendToAndReceiveFrom: WinInet.InternetQueryOption failed with error code ' + IntToStr(GetLastError) + '.');

      end;

      InternetHttpOpenRequestSecurityFlags := InternetHttpOpenRequestSecurityFlags or SECURITY_FLAG_IGNORE_REVOCATION;

      if not(WinInet.InternetSetOption(InternetHttpOpenRequestHandle, INTERNET_OPTION_SECURITY_FLAGS, @InternetHttpOpenRequestSecurityFlags, InternetHttpOpenRequestSecurityFlagsBufferLength)) then begin

        raise Exception.Create('TDnsOverHttpsClientCommunicationChannel.SendToAndReceiveFrom: WinInet.InternetSetOption failed with error code ' + IntToStr(GetLastError) + '.');

      end;

      try

        HttpRequestHeaders := 'Host: ' + DestinationHost + #10 + 'Content-Type: application/dns-message' + #10 + 'Accept: application/dns-message' + #10;

        if not WinInet.HttpSendRequest(InternetHttpOpenRequestHandle, PChar(HttpRequestHeaders), Length(HttpRequestHeaders), RequestBuffer, RequestBufferLen) then begin

          raise Exception.Create('TDnsOverHttpsClientCommunicationChannel.SendToAndReceiveFrom: WinInet.HttpSendRequest failed with error code ' + IntToStr(GetLastError) + '.');

        end;

        if not WinInet.InternetReadFile(InternetHttpOpenRequestHandle, ResponseBuffer, MaxResponseBufferLen, NumberOfBytesRead) then begin

          raise Exception.Create('TDnsOverHttpsClientCommunicationChannel.SendToAndReceiveFrom: WinInet.InternetReadFile failed with error code ' + IntToStr(GetLastError) + '.');

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

destructor TDnsOverHttpsClientCommunicationChannel.Destroy;

begin

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

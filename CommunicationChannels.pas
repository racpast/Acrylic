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

type
  PIPv4Address = ^TIPv4Address;
  TIPv4Address = Integer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  PIPv6Address = ^TIPv6Address;
  TIPv6Address = Array [0..15] of Byte;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  PDualIPAddress = ^TDualIPAddress;
  TDualIPAddress = packed record
    IsIPv6Address: Boolean;
    case Integer of
      0: (IPv4Address: TIPv4Address);
      1: (IPv6Address: TIPv6Address);
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  ANY_IPV4_ADDRESS: TIPv4Address = $00000000;
  ANY_IPV6_ADDRESS: TIPv6Address = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  LOCALHOST_IPV4_ADDRESS: TIPv4Address = $100007F;
  LOCALHOST_IPV6_ADDRESS: TIPv6Address = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4AddressUtility = class
    public
      class function Parse(Text: String): Integer;
      class function ToString(Address: TIPv4Address): String;
      class function IsLocalHost(Address: TIPv4Address): Boolean;
      class function AreEqual(Address1, Address2: TIPv4Address): Boolean;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6AddressUtility = class
    public
      class function Parse(Text: String): TIPv6Address;
      class function ToString(Address: TIPv6Address): String;
      class function IsLocalHost(Address: TIPv6Address): Boolean;
      class function AreEqual(Address1, Address2: TIPv6Address): Boolean;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TDualIPAddressUtility = class
    public
      class function Parse(Text: String): TDualIPAddress;
      class function ToString(Address: TDualIPAddress): String;
      class function IsLocalHost(Address: TDualIPAddress): Boolean;
      class function AreEqual(Address1, Address2: TDualIPAddress): Boolean;
      class function CreateFromIPv4Address(Address: TIPv4Address): TDualIPAddress;
      class function CreateFromIPv6Address(Address: TIPv6Address): TDualIPAddress;
  end;

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
      RemoteAddress: TIPv4Address; RemotePort: Word; Connected: Boolean; LastConnectTime: TDateTime;
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
      RemoteAddress: TIPv6Address; RemotePort: Word; Connected: Boolean; LastConnectTime: TDateTime;
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
  TIPv4TcpClientCommunicationManager = class
    public
      class procedure Initialize;
      class function  AcquireCommunicationChannel(ReferenceTime: TDateTime; PoolIndex: Integer): TIPv4TcpClientCommunicationChannel;
      class procedure ReleaseCommunicationChannel(ReferenceTime: TDateTime; PoolIndex: Integer; CommunicationChannel: TIPv4TcpClientCommunicationChannel; ExchangeSucceeded: Boolean);
      class procedure Finalize;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6TcpClientCommunicationManager = class
    public
      class procedure Initialize;
      class function  AcquireCommunicationChannel(ReferenceTime: TDateTime; PoolIndex: Integer): TIPv6TcpClientCommunicationChannel;
      class procedure ReleaseCommunicationChannel(ReferenceTime: TDateTime; PoolIndex: Integer; CommunicationChannel: TIPv6TcpClientCommunicationChannel; ExchangeSucceeded: Boolean);
      class procedure Finalize;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Classes,
  Contnrs,
  SyncObjs,
  SysUtils,
  Configuration;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  WINDOWS_SOCKETS_VERSION = $0202;
  WINDOWS_SOCKETS_DLL = 'WS2_32.DLL';

type
  PWSAData = ^TWSAData;
  TWSAData = packed record
    wVersion       : Word;
    wHighVersion   : Word;
    szDescription  : Array [0..256] of Char;
    szSystemStatus : Array [0..128] of Char;
    iMaxSockets    : Word;
    iMaxUdpDg      : Word;
    lpVendorInfo   : PChar;
  end;

type
  PIPv4SocketAddress = ^TIPv4SocketAddress;
  TIPv4SocketAddress = packed record
    sin_family : Word;
    sin_port   : Word;
    sin_addr   : TIPv4Address;
    sin_zero   : Array [0..7] of Char;
  end;

type
  PIPv6SocketAddress = ^TIPv6SocketAddress;
  TIPv6SocketAddress = packed record
    sin_family   : Word;
    sin_port     : Word;
    sin_flowinfo : LongInt;
    sin_addr     : TIPv6Address;
    sin_scopeid  : LongInt;
  end;

type
  PFDSet = ^TFDSet;
  TFDSet = packed record
    fd_count: Cardinal;
    fd_array: Array [0..63] of Integer;
  end;

type
  PTimeVal = ^TTimeVal;
  TTimeVal = packed record
    tv_sec: LongInt;
    tv_usec: LongInt;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function WSAStartup(VersionRequired: Word; var WSAData: TWSAData): Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'WSAStartup';

function Socket(AF, Struct, Protocol: Integer): Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'socket';
function IPv4Bind(S: Integer; var Addr: TIPv4SocketAddress; AddrLen: Integer): Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'bind';
function IPv6Bind(S: Integer; var Addr: TIPv6SocketAddress; AddrLen: Integer): Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'bind';
function IPv4Connect(S: Integer; var Addr: TIPv4SocketAddress; AddrLen: Integer): Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'connect';
function IPv6Connect(S: Integer; var Addr: TIPv6SocketAddress; AddrLen: Integer): Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'connect';
function Select(NFDS: Integer; ReadFDS, WriteFDS, ExceptFDS: PFDSet; Timeout: PTimeVal): Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'select';
function Listen(S: Integer; BackLog: Integer): Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'listen';
function IPv4Accept(S: Integer; var Addr: TIPv4SocketAddress; var AddrLen: Integer): Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'accept';
function IPv6Accept(S: Integer; var Addr: TIPv6SocketAddress; var AddrLen: Integer): Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'accept';
function IPv4Recv(S: Integer; var Buf; Len, Flags: Integer): Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'recv';
function IPv6Recv(S: Integer; var Buf; Len, Flags: Integer): Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'recv';
function IPv4RecvFrom(S: Integer; var Buf; Len, Flags: Integer; var Addr: TIPv4SocketAddress; var AddrLen: Integer): Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'recvfrom';
function IPv6RecvFrom(S: Integer; var Buf; Len, Flags: Integer; var Addr: TIPv6SocketAddress; var AddrLen: Integer): Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'recvfrom';
function IPv4Send(S: Integer; var Buf; Len, Flags: Integer): Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'send';
function IPv6Send(S: Integer; var Buf; Len, Flags: Integer): Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'send';
function IPv4SendTo(S: Integer; var Buf; Len, Flags: Integer; var Addr: TIPv4SocketAddress; AddrLen: Integer): Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'sendto';
function IPv6SendTo(S: Integer; var Buf; Len, Flags: Integer; var Addr: TIPv6SocketAddress; AddrLen: Integer): Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'sendto';
function IPv4Shutdown(S: Integer; How: Integer): Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'shutdown';
function IPv6Shutdown(S: Integer; How: Integer): Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'shutdown';
function CloseSocket(S: Integer): Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'closesocket';

function WSAGetLastError: Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'WSAGetLastError';

function WSACleanup: Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'WSACleanup';

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  AF_INET = 2;
  AF_INET6 = 23;

const
  SOCK_STREAM = 1;
  SOCK_DGRAM = 2;

const
  IPPROTO_TCP = 6;
  IPPROTO_UDP = 17;

const
  SD_SEND = 1;
  SD_BOTH = 2;

const
  SOCKET_ERROR = -1;
  INVALID_SOCKET = -1;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function HTONS(Value: Word): Word;

begin

  Result := (Value shr $08) + ((Value and $ff) shl $08);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function IsValidSocketHandle(SocketHandle: Integer): Boolean;

begin

  Result := SocketHandle <> INVALID_SOCKET;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function IsValidSocketResult(SocketResult: Integer): Boolean;

begin

  Result := SocketResult <> SOCKET_ERROR;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure LowLevelIPv4AddressParse(Text: String; var Address: TIPv4Address);

var
  PartIndex, SepAt: Integer; PartText: String; PartValue: Word; ValResult: Integer;

begin

  Address := 0;

  if (Text = '0.0.0.0') then Exit else if (Text = '127.0.0.1') then begin Address := LOCALHOST_IPV4_ADDRESS; Exit; end else begin

    PartIndex := 0; while (Text <> '') and (PartIndex < 4) do begin

      SepAt := Pos('.', Text); if (SepAt > 0) then begin PartText := Copy(Text, 1, SepAt - 1); Delete(Text, 1, SepAt); end else begin PartText := Text; Text := ''; end; if (PartText <> '') then begin

        Val(PartText, PartValue, ValResult);

        Inc(Address, PartValue shl (8 * PartIndex));

      end; Inc(PartIndex);

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function LowLevelIPv4AddressToString(var Address: TIPv4Address): String;

begin

  Result := IntToStr(Address and $ff) + '.' + IntToStr((Address shr 8) and $ff) + '.' + IntToStr((Address shr 16) and $ff) + '.' + IntToStr(Address shr 24);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure LowLevelIPv6AddressParse(Text: String; var Address: TIPv6Address);

var
  PartIndex, SepAt, GapAt: Integer; PartText: String; PartValue: Word; ValResult: Integer;

begin

  FillChar(Address, SizeOf(TIPv6Address), 0);

  if (Text = '::') then Exit else if (Text = '::1') then begin Address[15] := 1; Exit; end else begin

    PartIndex := 0; GapAt := -1; while (Text <> '') and (PartIndex < 16) do begin

      SepAt := Pos(':', Text); if (SepAt > 0) then begin PartText := Copy(Text, 1, SepAt - 1); Delete(Text, 1, SepAt); end else begin PartText := Text; Text := ''; end; if (PartText <> '') then begin

        Val('$' + PartText, PartValue, ValResult);

        Address[PartIndex] := PartValue shr $08; Inc(PartIndex);
        Address[PartIndex] := PartValue and $ff; Inc(PartIndex);

      end else begin

        if (GapAt = -1) then GapAt := PartIndex;

      end;

    end;

    if (GapAt > -1) and (GapAt < 14) then begin

      Move(Address[GapAt], Address[16 + GapAt - PartIndex], PartIndex - GapAt); FillChar(Address[GapAt], 16 - PartIndex, 0);

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function LowLevelIPv6AddressToString(var Address: TIPv6Address): String;

begin

  Result := IntToHex((Address[0] shl 8) + Address[1], 1) + ':' + IntToHex((Address[2] shl 8) + Address[3], 1) + ':' + IntToHex((Address[4] shl 8) + Address[5], 1) + ':' + IntToHex((Address[6] shl 8) + Address[7], 1) + ':' + IntToHex((Address[8] shl 8) + Address[9], 1) + ':' + IntToHex((Address[10] shl 8) + Address[11], 1) + ':' + IntToHex((Address[12] shl 8) + Address[13], 1) + ':' + IntToHex((Address[14] shl 8) + Address[15], 1);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TIPv4AddressUtility.Parse(Text: String): TIPv4Address;

var
  IPv4Address: TIPv4Address;

begin

  LowLevelIPv4AddressParse(Text, IPv4Address); Result := IPv4Address;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TIPv4AddressUtility.ToString(Address: TIPv4Address): String;

begin

  Result := LowLevelIPv4AddressToString(Address);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TIPv4AddressUtility.IsLocalHost(Address: TIPv4Address): Boolean;

begin

  Result := TIPv4AddressUtility.AreEqual(Address, LOCALHOST_IPV4_ADDRESS);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TIPv4AddressUtility.AreEqual(Address1, Address2: TIPv4Address): Boolean;

begin

  Result := (Address1 = Address2);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TIPv6AddressUtility.Parse(Text: String): TIPv6Address;

var
  IPv6Address: TIPv6Address;

begin

  LowLevelIPv6AddressParse(Text, IPv6Address); Result := IPv6Address;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TIPv6AddressUtility.ToString(Address: TIPv6Address): String;

begin

  Result := LowLevelIPv6AddressToString(Address);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TIPv6AddressUtility.IsLocalHost(Address: TIPv6Address): Boolean;

begin

  Result := TIPv6AddressUtility.AreEqual(Address, LOCALHOST_IPV6_ADDRESS);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TIPv6AddressUtility.AreEqual(Address1, Address2: TIPv6Address): Boolean;

begin

  Result := (Address1[0] = Address2[0]) and (Address1[1] = Address2[1]) and (Address1[2] = Address2[2]) and (Address1[3] = Address2[3]) and (Address1[4] = Address2[4]) and (Address1[5] = Address2[5]) and (Address1[6] = Address2[6]) and (Address1[7] = Address2[7]) and (Address1[8] = Address2[8]) and (Address1[9] = Address2[9]) and (Address1[10] = Address2[10]) and (Address1[11] = Address2[11]) and (Address1[12] = Address2[12]) and (Address1[13] = Address2[13]) and (Address1[14] = Address2[14]) and (Address1[15] = Address2[15]);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDualIPAddressUtility.Parse(Text: String): TDualIPAddress;

var
  DualIPAddress: TDualIPAddress;

begin

  if (Pos(':', Text) > 0) then begin DualIPAddress.IPv6Address := TIPv6AddressUtility.Parse(Text); DualIPAddress.IsIPv6Address := True; end else begin DualIPAddress.IPv4Address := TIPv4AddressUtility.Parse(Text); DualIPAddress.IsIPv6Address := False; end; Result := DualIPAddress;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDualIPAddressUtility.ToString(Address: TDualIPAddress): String;

begin

  if Address.IsIPv6Address then Result := TIPv6AddressUtility.ToString(Address.IPv6Address) else Result := TIPv4AddressUtility.ToString(Address.IPv4Address);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDualIPAddressUtility.IsLocalHost(Address: TDualIPAddress): Boolean;

begin

  Result := (Address.IsIPv6Address and TIPv6AddressUtility.IsLocalHost(Address.IPv6Address)) or (not Address.IsIPv6Address and TIPv4AddressUtility.IsLocalHost(Address.IPv4Address));

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDualIPAddressUtility.AreEqual(Address1, Address2: TDualIPAddress): Boolean;

begin

  if Address1.IsIPv6Address then Result := Address2.IsIPv6Address and TIPv6AddressUtility.AreEqual(Address1.IPv6Address, Address2.IPv6Address) else Result := not Address2.IsIPv6Address and TIPv4AddressUtility.AreEqual(Address1.IPv4Address, Address2.IPv4Address);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDualIPAddressUtility.CreateFromIPv4Address(Address: TIPv4Address): TDualIPAddress;

var
  DualIPAddress: TDualIPAddress;

begin

  DualIPAddress.IPv4Address := Address; DualIPAddress.IsIPv6Address := False; Result := DualIPAddress;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDualIPAddressUtility.CreateFromIPv6Address(Address: TIPv6Address): TDualIPAddress;

var
  DualIPAddress: TDualIPAddress;

begin

  DualIPAddress.IPv6Address := Address; DualIPAddress.IsIPv6Address := True; Result := DualIPAddress;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TCommunicationChannel.Initialize;

var
  WSAData: TWSAData;

begin

  if not((WSAStartup(WINDOWS_SOCKETS_VERSION, WSAData) = 0)) then raise Exception.Create('TCommunicationChannel.Initialize: WSAStartup function failed.');

  TIPv6TcpClientCommunicationManager.Initialize;
  TIPv4TcpClientCommunicationManager.Initialize;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TCommunicationChannel.Finalize;

begin

  TIPv6TcpClientCommunicationManager.Finalize;
  TIPv4TcpClientCommunicationManager.Finalize;

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

  Self.RemoteAddress := RemoteAddress; Self.RemotePort := RemotePort; Self.Connected := True; Self.LastConnectTime := Now;

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

  Self.RemoteAddress := RemoteAddress; Self.RemotePort := RemotePort; Self.Connected := True; Self.LastConnectTime := Now;

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

var
  TIPv4TcpClientCommunicationManager_Lock: TCriticalSection;
  TIPv4TcpClientCommunicationManager_Pool: Array [0..(Configuration.MAX_NUM_DNS_SERVERS - 1)] of TObjectQueue;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TIPv4TcpClientCommunicationManager.Initialize;

begin

  TIPv4TcpClientCommunicationManager_Lock := TCriticalSection.Create;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TIPv4TcpClientCommunicationManager.AcquireCommunicationChannel(ReferenceTime: TDateTime; PoolIndex: Integer): TIPv4TcpClientCommunicationChannel;

var
  CommunicationManagerPool: TObjectQueue; CommunicationChannel: TIPv4TcpClientCommunicationChannel;

begin

  if TConfiguration.GetServerTcpProtocolPipeliningDisabled then begin

    CommunicationChannel := TIPv4TcpClientCommunicationChannel.Create; Result := CommunicationChannel; Exit;

  end;

  TIPv4TcpClientCommunicationManager_Lock.Acquire;

  try

    CommunicationManagerPool := TIPv4TcpClientCommunicationManager_Pool[PoolIndex]; if (CommunicationManagerPool <> nil) then begin

      while (CommunicationManagerPool.Count > 0) do begin

        CommunicationChannel := TIPv4TcpClientCommunicationChannel(CommunicationManagerPool.Pop);

        if ((ReferenceTime - CommunicationChannel.LastConnectTime) <= (TConfiguration.GetServerTcpProtocolPipeliningSessionLifetime / 86400.0)) then begin

          Result := CommunicationChannel; Exit;

        end else begin

          CommunicationChannel.Free;

        end;

      end;

    end;

  finally

    TIPv4TcpClientCommunicationManager_Lock.Release;

  end;

  CommunicationChannel := TIPv4TcpClientCommunicationChannel.Create; Result := CommunicationChannel;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TIPv4TcpClientCommunicationManager.ReleaseCommunicationChannel(ReferenceTime: TDateTime; PoolIndex: Integer; CommunicationChannel: TIPv4TcpClientCommunicationChannel; ExchangeSucceeded: Boolean);

var
  CommunicationManagerPool: TObjectQueue;

begin

  if TConfiguration.GetServerTcpProtocolPipeliningDisabled then begin

    CommunicationChannel.Free; Exit;

  end;

  if ExchangeSucceeded then begin

    TIPv4TcpClientCommunicationManager_Lock.Acquire;

    try

      CommunicationManagerPool := TIPv4TcpClientCommunicationManager_Pool[PoolIndex];

      if (CommunicationManagerPool = nil) then begin CommunicationManagerPool := TObjectQueue.Create; TIPv4TcpClientCommunicationManager_Pool[PoolIndex] := CommunicationManagerPool; end; CommunicationManagerPool.Push(TObject(CommunicationChannel));

    finally

      TIPv4TcpClientCommunicationManager_Lock.Release;

    end;

  end else begin

    CommunicationChannel.Free;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TIPv4TcpClientCommunicationManager.Finalize;

var
  PoolIndex: Integer; CommunicationManagerPool: TObjectQueue; CommunicationChannel: TIPv4TcpClientCommunicationChannel;

begin

  for PoolIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin

    CommunicationManagerPool := TIPv4TcpClientCommunicationManager_Pool[PoolIndex]; if (CommunicationManagerPool <> nil) then begin

      while (CommunicationManagerPool.Count > 0) do begin

        CommunicationChannel := TIPv4TcpClientCommunicationChannel(CommunicationManagerPool.Pop); CommunicationChannel.Free;

      end;

      CommunicationManagerPool.Free;

    end;

  end;

  TIPv4TcpClientCommunicationManager_Lock.Free;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TIPv6TcpClientCommunicationManager_Lock: TCriticalSection;
  TIPv6TcpClientCommunicationManager_Pool: Array [0..(Configuration.MAX_NUM_DNS_SERVERS - 1)] of TObjectQueue;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TIPv6TcpClientCommunicationManager.Initialize;

begin

  TIPv6TcpClientCommunicationManager_Lock := TCriticalSection.Create;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TIPv6TcpClientCommunicationManager.AcquireCommunicationChannel(ReferenceTime: TDateTime; PoolIndex: Integer): TIPv6TcpClientCommunicationChannel;

var
  CommunicationManagerPool: TObjectQueue; CommunicationChannel: TIPv6TcpClientCommunicationChannel;

begin

  if TConfiguration.GetServerTcpProtocolPipeliningDisabled then begin

    CommunicationChannel := TIPv6TcpClientCommunicationChannel.Create; Result := CommunicationChannel; Exit;

  end;

  TIPv6TcpClientCommunicationManager_Lock.Acquire;

  try

    CommunicationManagerPool := TIPv6TcpClientCommunicationManager_Pool[PoolIndex]; if (CommunicationManagerPool <> nil) then begin

      while (CommunicationManagerPool.Count > 0) do begin

        CommunicationChannel := TIPv6TcpClientCommunicationChannel(CommunicationManagerPool.Pop);

        if ((ReferenceTime - CommunicationChannel.LastConnectTime) <= (TConfiguration.GetServerTcpProtocolPipeliningSessionLifetime / 86400.0)) then begin

          Result := CommunicationChannel; Exit;

        end else begin

          CommunicationChannel.Free;

        end;

      end;

    end;

  finally

    TIPv6TcpClientCommunicationManager_Lock.Release;

  end;

  CommunicationChannel := TIPv6TcpClientCommunicationChannel.Create; Result := CommunicationChannel;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TIPv6TcpClientCommunicationManager.ReleaseCommunicationChannel(ReferenceTime: TDateTime; PoolIndex: Integer; CommunicationChannel: TIPv6TcpClientCommunicationChannel; ExchangeSucceeded: Boolean);

var
  CommunicationManagerPool: TObjectQueue;

begin

  if TConfiguration.GetServerTcpProtocolPipeliningDisabled then begin

    CommunicationChannel.Free; Exit;

  end;

  if ExchangeSucceeded then begin

    TIPv6TcpClientCommunicationManager_Lock.Acquire;

    try

      CommunicationManagerPool := TIPv6TcpClientCommunicationManager_Pool[PoolIndex];

      if (CommunicationManagerPool = nil) then begin CommunicationManagerPool := TObjectQueue.Create; TIPv6TcpClientCommunicationManager_Pool[PoolIndex] := CommunicationManagerPool; end; CommunicationManagerPool.Push(TObject(CommunicationChannel));

    finally

      TIPv6TcpClientCommunicationManager_Lock.Release;

    end;

  end else begin

    CommunicationChannel.Free;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TIPv6TcpClientCommunicationManager.Finalize;

var
  PoolIndex: Integer; CommunicationManagerPool: TObjectQueue; CommunicationChannel: TIPv6TcpClientCommunicationChannel;

begin

  for PoolIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin

    CommunicationManagerPool := TIPv6TcpClientCommunicationManager_Pool[PoolIndex]; if (CommunicationManagerPool <> nil) then begin

      while (CommunicationManagerPool.Count > 0) do begin

        CommunicationChannel := TIPv6TcpClientCommunicationChannel(CommunicationManagerPool.Pop); CommunicationChannel.Free;

      end;

      CommunicationManagerPool.Free;

    end;

  end;

  TIPv6TcpClientCommunicationManager_Lock.Free;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

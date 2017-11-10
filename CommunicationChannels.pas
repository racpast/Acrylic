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
      class function AreEqual(Address1, Address2: TIPv4Address): Boolean;
    public
      class function IsLocalHost(Address: TIPv4Address): Boolean;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6AddressUtility = class
    public
      class function Parse(Text: String): TIPv6Address;
      class function ToString(Address: TIPv6Address): String;
      class function AreEqual(Address1, Address2: TIPv6Address): Boolean;
    public
      class function IsLocalHost(Address: TIPv6Address): Boolean;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TDualIPAddressUtility = class
    public
      class function Parse(Text: String): TDualIPAddress;
      class function ParseAsPointer(Text: String): PDualIPAddress;
    public
      class function ToString(Address: TDualIPAddress): String;
    public
      class function CreateFromIPv4Address(Address: TIPv4Address): TDualIPAddress;
      class function CreateFromIPv6Address(Address: TIPv6Address): TDualIPAddress;
    public
      class function CreateFromIPv4AddressAsPointer(Address: TIPv4Address): PDualIPAddress;
      class function CreateFromIPv6AddressAsPointer(Address: TIPv6Address): PDualIPAddress;
    public
      class function AreEqual(Address1, Address2: TDualIPAddress): Boolean;
    public
      class function IsLocalHost(Address: TDualIPAddress): Boolean;
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
  TIPv4UdpCommunicationChannel = class
    private
      SocketHandle: Integer;
    public
      constructor Create;
      procedure   Bind(BindingAddress: TIPv4Address; BindingPort: Word);
      procedure   BindToRandomUnregisteredPort(BindingAddress: TIPv4Address; MaxBindRetries: Integer);
      procedure   SendTo(Buffer: Pointer; BufferLen: Integer; DestinationAddress: TIPv4Address; DestinationPort: Word);
      function    ReceiveFrom(Timeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer; var RemoteAddress: TIPv4Address; var RemotePort: Word): Boolean;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6UdpCommunicationChannel = class
    private
      SocketHandle: Integer;
    public
      constructor Create;
      procedure   Bind(BindingAddress: TIPv6Address; BindingPort: Word);
      procedure   BindToRandomUnregisteredPort(BindingAddress: TIPv6Address; MaxBindRetries: Integer);
      procedure   SendTo(Buffer: Pointer; BufferLen: Integer; DestinationAddress: TIPv6Address; DestinationPort: Word);
      function    ReceiveFrom(Timeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer; var RemoteAddress: TIPv6Address; var RemotePort: Word): Boolean;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TDualUdpCommunicationChannel = class
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
  TIPv4TcpCommunicationChannel = class
    private
      SocketHandle: Integer;
    public
      RemoteAddress: TIPv4Address; RemotePort: Word;
    public
      constructor Create; overload;
      constructor Create(SocketHandle: Integer; RemoteAddress: TIPv4Address; RemotePort: Word); overload;
      procedure   Bind(BindingAddress: TIPv4Address; BindingPort: Word);
      procedure   Listen;
      function    Accept: TIPv4TcpCommunicationChannel; overload;
      function    Accept(Timeout: Integer): TIPv4TcpCommunicationChannel; overload;
      procedure   Connect(RemoteAddress: TIPv4Address; RemotePort: Word);
      procedure   Send(Buffer: Pointer; BufferLen: Integer);
      function    Receive(Timeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer): Boolean;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6TcpCommunicationChannel = class
    private
      SocketHandle: Integer;
    public
      RemoteAddress: TIPv6Address; RemotePort: Word;
    public
      constructor Create; overload;
      constructor Create(SocketHandle: Integer; RemoteAddress: TIPv6Address; RemotePort: Word); overload;
      procedure   Bind(BindingAddress: TIPv6Address; BindingPort: Word);
      procedure   Listen;
      function    Accept: TIPv6TcpCommunicationChannel; overload;
      function    Accept(Timeout: Integer): TIPv6TcpCommunicationChannel; overload;
      procedure   Connect(RemoteAddress: TIPv6Address; RemotePort: Word);
      procedure   Send(Buffer: Pointer; BufferLen: Integer);
      function    Receive(Timeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer): Boolean;
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
  SysUtils;

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
  INVALID_SOCKET = -1;

const
  SOCKET_ERROR = -1;

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
function CloseSocket(S: Integer): Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'closesocket';

function WSAGetLastError: Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'WSAGetLastError';

function WSACleanup: Integer; stdcall; external WINDOWS_SOCKETS_DLL name 'WSACleanup';

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

class function TIPv4AddressUtility.AreEqual(Address1, Address2: TIPv4Address): Boolean;
begin
  Result := (Address1 = Address2);
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

class function TIPv6AddressUtility.AreEqual(Address1, Address2: TIPv6Address): Boolean;
begin
  Result := (Address1[0] = Address2[0]) and (Address1[1] = Address2[1]) and (Address1[2] = Address2[2]) and (Address1[3] = Address2[3]) and (Address1[4] = Address2[4]) and (Address1[5] = Address2[5]) and (Address1[6] = Address2[6]) and (Address1[7] = Address2[7]) and (Address1[8] = Address2[8]) and (Address1[9] = Address2[9]) and (Address1[10] = Address2[10]) and (Address1[11] = Address2[11]) and (Address1[12] = Address2[12]) and (Address1[13] = Address2[13]) and (Address1[14] = Address2[14]) and (Address1[15] = Address2[15]);
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

class function TDualIPAddressUtility.Parse(Text: String): TDualIPAddress;
var
  DualIPAddress: TDualIPAddress;
begin
  if (Pos(':', Text) > 0) then begin DualIPAddress.IPv6Address := TIPv6AddressUtility.Parse(Text); DualIPAddress.IsIPv6Address := True; end else begin DualIPAddress.IPv4Address := TIPv4AddressUtility.Parse(Text); DualIPAddress.IsIPv6Address := False; end; Result := DualIPAddress;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDualIPAddressUtility.ParseAsPointer(Text: String): PDualIPAddress;
var
  DualIPAddress: TDualIPAddress;
begin
  DualIPAddress := TDualIPAddressUtility.Parse(Text); Result := @DualIPAddress;
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

class function TDualIPAddressUtility.CreateFromIPv4AddressAsPointer(Address: TIPv4Address): PDualIPAddress;
var
  DualIPAddress: TDualIPAddress;
begin
  DualIPAddress := TDualIPAddressUtility.CreateFromIPv4Address(Address); Result := @DualIPAddress;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDualIPAddressUtility.CreateFromIPv6AddressAsPointer(Address: TIPv6Address): PDualIPAddress;
var
  DualIPAddress: TDualIPAddress;
begin
  DualIPAddress := TDualIPAddressUtility.CreateFromIPv6Address(Address); Result := @DualIPAddress;
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

constructor TIPv4UdpCommunicationChannel.Create;
begin
  Self.SocketHandle := Socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);

  if not(IsValidSocketHandle(Self.SocketHandle)) then raise Exception.Create('TIPv4UdpCommunicationChannel.Create: Socket allocation failed.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4UdpCommunicationChannel.Bind(BindingAddress: TIPv4Address; BindingPort: Word);
var
  IPv4SocketAddress: TIPv4SocketAddress;
begin
  FillChar(IPv4SocketAddress, SizeOf(TIPv4SocketAddress), 0);

  IPv4SocketAddress.sin_family := AF_INET; IPv4SocketAddress.sin_addr := BindingAddress; IPv4SocketAddress.sin_port := HTONS(BindingPort);

  if not(IsValidSocketResult(IPv4Bind(Self.SocketHandle, IPv4SocketAddress, SizeOf(TIPv4SocketAddress)))) then raise Exception.Create('TIPv4UdpCommunicationChannel.Bind: Binding to address ' + TIPv4AddressUtility.ToString(BindingAddress) + ' and port ' + IntToStr(BindingPort) + ' failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4UdpCommunicationChannel.BindToRandomUnregisteredPort(BindingAddress: TIPv4Address; MaxBindRetries: Integer);
var
  IPv4SocketAddress: TIPv4SocketAddress; BindRetryIndex: Integer;
begin
  FillChar(IPv4SocketAddress, SizeOf(TIPv4SocketAddress), 0);

  IPv4SocketAddress.sin_family := AF_INET; IPv4SocketAddress.sin_addr := BindingAddress;

  for BindRetryIndex := 1 to MaxBindRetries do begin

    IPv4SocketAddress.sin_port := HTONS(49152 + Random(16384));

    if IsValidSocketResult(IPv4Bind(Self.SocketHandle, IPv4SocketAddress, SizeOf(TIPv4SocketAddress))) then Exit;

  end;

  raise Exception.Create('TIPv4UdpCommunicationChannel.BindToRandomUnregisteredPort: Binding to address ' + TIPv4AddressUtility.ToString(BindingAddress) + ' and a random unregistered port failed after ' + IntToStr(MaxBindRetries) + ' retries.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4UdpCommunicationChannel.SendTo(Buffer: Pointer; BufferLen: Integer; DestinationAddress: TIPv4Address; DestinationPort: Word);
var
  IPv4SocketAddress: TIPv4SocketAddress;
begin
  FillChar(IPv4SocketAddress, SizeOf(TIPv4SocketAddress), 0);

  IPv4SocketAddress.sin_family := AF_INET; IPv4SocketAddress.sin_addr := DestinationAddress; IPv4SocketAddress.sin_port := HTONS(DestinationPort);

  if not(IsValidSocketResult(IPv4SendTo(Self.SocketHandle, Buffer^, BufferLen, 0, IPv4SocketAddress, SizeOf(TIPv4SocketAddress)))) then raise Exception.Create('TIPv4UdpCommunicationChannel.SendTo: Sending to address ' + TIPv4AddressUtility.ToString(DestinationAddress) + ' and port ' + IntToStr(DestinationPort) + ' failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv4UdpCommunicationChannel.ReceiveFrom(Timeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer; var RemoteAddress: TIPv4Address; var RemotePort: Word): Boolean;
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

destructor TIPv4UdpCommunicationChannel.Destroy;
begin
  if IsValidSocketHandle(Self.SocketHandle) then CloseSocket(Self.SocketHandle);

  inherited Destroy;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6UdpCommunicationChannel.Create;
begin
  Self.SocketHandle := Socket(AF_INET6, SOCK_DGRAM, IPPROTO_UDP);

  if not(IsValidSocketHandle(Self.SocketHandle)) then raise Exception.Create('TIPv6UdpCommunicationChannel.Create: Socket allocation failed.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6UdpCommunicationChannel.Bind(BindingAddress: TIPv6Address; BindingPort: Word);
var
  IPv6SocketAddress: TIPv6SocketAddress;
begin
  FillChar(IPv6SocketAddress, SizeOf(TIPv6SocketAddress), 0);

  IPv6SocketAddress.sin_family := AF_INET6; IPv6SocketAddress.sin_addr := BindingAddress; IPv6SocketAddress.sin_port := HTONS(BindingPort);

  if not(IsValidSocketResult(IPv6Bind(Self.SocketHandle, IPv6SocketAddress, SizeOf(TIPv6SocketAddress)))) then raise Exception.Create('TIPv6UdpCommunicationChannel.Bind: Binding to address ' + TIPv6AddressUtility.ToString(BindingAddress) + ' and port ' + IntToStr(BindingPort) + ' failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6UdpCommunicationChannel.BindToRandomUnregisteredPort(BindingAddress: TIPv6Address; MaxBindRetries: Integer);
var
  IPv6SocketAddress: TIPv6SocketAddress; BindRetryIndex: Integer;
begin
  FillChar(IPv6SocketAddress, SizeOf(TIPv6SocketAddress), 0);

  IPv6SocketAddress.sin_family := AF_INET6; IPv6SocketAddress.sin_addr := BindingAddress;

  for BindRetryIndex := 1 to MaxBindRetries do begin

    IPv6SocketAddress.sin_port := HTONS(49152 + Random(16384));

    if IsValidSocketResult(IPv6Bind(Self.SocketHandle, IPv6SocketAddress, SizeOf(TIPv6SocketAddress))) then Exit;

  end;

  raise Exception.Create('TIPv6UdpCommunicationChannel.BindToRandomUnregisteredPort: Binding to address ' + TIPv6AddressUtility.ToString(BindingAddress) + ' and a random unregistered port failed after ' + IntToStr(MaxBindRetries) + ' retries.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6UdpCommunicationChannel.SendTo(Buffer: Pointer; BufferLen: Integer; DestinationAddress: TIPv6Address; DestinationPort: Word);
var
  IPv6SocketAddress: TIPv6SocketAddress;
begin
  FillChar(IPv6SocketAddress, SizeOf(TIPv6SocketAddress), 0);

  IPv6SocketAddress.sin_family := AF_INET6; IPv6SocketAddress.sin_addr := DestinationAddress; IPv6SocketAddress.sin_port := HTONS(DestinationPort);

  if not(IsValidSocketResult(IPv6SendTo(Self.SocketHandle, Buffer^, BufferLen, 0, IPv6SocketAddress, SizeOf(TIPv6SocketAddress)))) then raise Exception.Create('TIPv6UdpCommunicationChannel.SendTo: Sending to address ' + TIPv6AddressUtility.ToString(DestinationAddress) + ' and port ' + IntToStr(DestinationPort) + ' failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv6UdpCommunicationChannel.ReceiveFrom(Timeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer; var RemoteAddress: TIPv6Address; var RemotePort: Word): Boolean;
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

destructor TIPv6UdpCommunicationChannel.Destroy;
begin
  if IsValidSocketHandle(Self.SocketHandle) then CloseSocket(Self.SocketHandle);

  inherited Destroy;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TDualUdpCommunicationChannel.Create;
begin
  Self.IPv4SocketHandle := INVALID_SOCKET;
  Self.IPv6SocketHandle := INVALID_SOCKET;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TDualUdpCommunicationChannel.Bind(IPv4Binding: Boolean; IPv4BindingAddress: TIPv4Address; IPv4BindingPort: Word; IPv6Binding: Boolean; IPv6BindingAddress: TIPv6Address; IPv6BindingPort: Word);
var
  IPv4SocketAddress: TIPv4SocketAddress; IPv6SocketAddress: TIPv6SocketAddress;
begin
  if IPv4Binding then begin

    Self.IPv4SocketHandle := Socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);

    if not(IsValidSocketHandle(Self.IPv4SocketHandle)) then raise Exception.Create('TDualUdpCommunicationChannel.Bind: IPv4 socket allocation failed.');

    FillChar(IPv4SocketAddress, SizeOf(TIPv4SocketAddress), 0);

    IPv4SocketAddress.sin_family := AF_INET; IPv4SocketAddress.sin_addr := IPv4BindingAddress; IPv4SocketAddress.sin_port := HTONS(IPv4BindingPort);

    if not(IsValidSocketResult(IPv4Bind(Self.IPv4SocketHandle, IPv4SocketAddress, SizeOf(TIPv4SocketAddress)))) then raise Exception.Create('TDualUdpCommunicationChannel.Bind: Binding to IPv4 address ' + TIPv4AddressUtility.ToString(IPv4BindingAddress) + ' and port ' + IntToStr(IPv4BindingPort) + ' failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

  end;

  if IPv6Binding then begin

    Self.IPv6SocketHandle := Socket(AF_INET6, SOCK_DGRAM, IPPROTO_UDP);

    if not(IsValidSocketHandle(Self.IPv6SocketHandle)) then raise Exception.Create('TDualUdpCommunicationChannel.Bind: IPv6 socket allocation failed.');

    FillChar(IPv6SocketAddress, SizeOf(TIPv6SocketAddress), 0);

    IPv6SocketAddress.sin_family := AF_INET6; IPv6SocketAddress.sin_addr := IPv6BindingAddress; IPv6SocketAddress.sin_port := HTONS(IPv6BindingPort);

    if not(IsValidSocketResult(IPv6Bind(Self.IPv6SocketHandle, IPv6SocketAddress, SizeOf(TIPv6SocketAddress)))) then raise Exception.Create('TDualUdpCommunicationChannel.Bind: Binding to IPv6 address ' + TIPv6AddressUtility.ToString(IPv6BindingAddress) + ' and port ' + IntToStr(IPv6BindingPort) + ' failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TDualUdpCommunicationChannel.SendTo(Buffer: Pointer; BufferLen: Integer; DestinationAddress: TDualIPAddress; DestinationPort: Word);
var
  IPv4SocketAddress: TIPv4SocketAddress; IPv6SocketAddress: TIPv6SocketAddress;
begin
  if DestinationAddress.IsIPv6Address then begin

    if IsValidSocketHandle(Self.IPv6SocketHandle) then begin

      FillChar(IPv6SocketAddress, SizeOf(TIPv6SocketAddress), 0);

      IPv6SocketAddress.sin_family := AF_INET6; IPv6SocketAddress.sin_addr := DestinationAddress.IPv6Address; IPv6SocketAddress.sin_port := HTONS(DestinationPort);

      if not(IsValidSocketResult(IPv6SendTo(Self.IPv6SocketHandle, Buffer^, BufferLen, 0, IPv6SocketAddress, SizeOf(TIPv6SocketAddress)))) then raise Exception.Create('TDualUdpCommunicationChannel.SendTo: Sending to IPv6 address ' + TIPv6AddressUtility.ToString(DestinationAddress.IPv6Address) + ' and port ' + IntToStr(DestinationPort) + ' failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

    end;

  end else begin

    if IsValidSocketHandle(Self.IPv4SocketHandle) then begin

      FillChar(IPv4SocketAddress, SizeOf(TIPv4SocketAddress), 0);

      IPv4SocketAddress.sin_family := AF_INET; IPv4SocketAddress.sin_addr := DestinationAddress.IPv4Address; IPv4SocketAddress.sin_port := HTONS(DestinationPort);

      if not(IsValidSocketResult(IPv4SendTo(Self.IPv4SocketHandle, Buffer^, BufferLen, 0, IPv4SocketAddress, SizeOf(TIPv4SocketAddress)))) then raise Exception.Create('TDualUdpCommunicationChannel.SendTo: Sending to IPv4 address ' + TIPv4AddressUtility.ToString(DestinationAddress.IPv4Address) + ' and port ' + IntToStr(DestinationPort) + ' failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

    end;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TDualUdpCommunicationChannel.ReceiveFrom(Timeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer; var RemoteAddress: TDualIPAddress; var RemotePort: Word): Boolean;
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

      ReadFDSet.fd_count := 1; ReadFDSet.fd_array[0] := Self.IPv6SocketHandle;

      SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if IsValidSocketResult(SelectResult) and (SelectResult > 0) then begin

        IPv6SocketAddressSize := SizeOf(TIPv6SocketAddress); BufferLen := IPv6RecvFrom(Self.IPv6SocketHandle, Buffer^, MaxBufferLen, 0, IPv6SocketAddress, IPv6SocketAddressSize);

        if (BufferLen > 0) then begin

          RemoteAddress := TDualIPAddressUtility.CreateFromIPv6Address(IPv6SocketAddress.sin_addr); RemotePort := HTONS(IPv6SocketAddress.sin_port); Result := True; Exit;

        end;

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

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TDualUdpCommunicationChannel.Destroy;
begin
  if IsValidSocketHandle(Self.IPv6SocketHandle) then CloseSocket(Self.IPv6SocketHandle);
  if IsValidSocketHandle(Self.IPv4SocketHandle) then CloseSocket(Self.IPv4SocketHandle);

  inherited Destroy;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4TcpCommunicationChannel.Create;
begin
  Self.SocketHandle := Socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

  if not(IsValidSocketHandle(Self.SocketHandle)) then raise Exception.Create('TIPv4TcpCommunicationChannel.Create: Socket allocation failed.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4TcpCommunicationChannel.Create(SocketHandle: Integer; RemoteAddress: TIPv4Address; RemotePort: Word);
begin
  Self.SocketHandle := SocketHandle; Self.RemoteAddress := RemoteAddress; Self.RemotePort := RemotePort;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4TcpCommunicationChannel.Bind(BindingAddress: TIPv4Address; BindingPort: Word);
var
  IPv4SocketAddress: TIPv4SocketAddress;
begin
  FillChar(IPv4SocketAddress, SizeOf(TIPv4SocketAddress), 0);

  IPv4SocketAddress.sin_family := AF_INET; IPv4SocketAddress.sin_addr := BindingAddress; IPv4SocketAddress.sin_port := HTONS(BindingPort);

  if not(IsValidSocketResult(IPv4Bind(Self.SocketHandle, IPv4SocketAddress, SizeOf(TIPv4SocketAddress)))) then raise Exception.Create('TIPv4TcpCommunicationChannel.Bind: Binding to address ' + TIPv4AddressUtility.ToString(BindingAddress) + ' and port ' + IntToStr(BindingPort) + ' failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4TcpCommunicationChannel.Listen;
begin
  if not(IsValidSocketResult(CommunicationChannels.Listen(Self.SocketHandle, 0))) then raise Exception.Create('TIPv4TcpCommunicationChannel.Listen: Listening failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv4TcpCommunicationChannel.Accept: TIPv4TcpCommunicationChannel;
var
  IncomingConnectionSocketHandle: Integer; IPv4SocketAddress: TIPv4SocketAddress; IPv4SocketAddressLen: Integer;
begin
  IPv4SocketAddressLen := SizeOf(TIPv4SocketAddress); FillChar(IPv4SocketAddress, IPv4SocketAddressLen, 0);

  IncomingConnectionSocketHandle := IPv4Accept(Self.SocketHandle, IPv4SocketAddress, IPv4SocketAddressLen); if not(IsValidSocketHandle(IncomingConnectionSocketHandle)) then raise Exception.Create('TIPv4TcpCommunicationChannel.Accept: Accepting socket failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); Result := TIPv4TcpCommunicationChannel.Create(IncomingConnectionSocketHandle, IPv4SocketAddress.sin_addr, HTONS(IPv4SocketAddress.sin_port));
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv4TcpCommunicationChannel.Accept(Timeout: Integer): TIPv4TcpCommunicationChannel;
var
  TimeVal: TTimeVal; ReadFDSet: TFDSet; SelectResult: Integer; IncomingConnectionSocketHandle: Integer; IPv4SocketAddress: TIPv4SocketAddress; IPv4SocketAddressLen: Integer;
begin
  TimeVal.tv_sec := Timeout div 1000;
  TimeVal.tv_usec := 1000 * (Timeout mod 1000);

  ReadFDSet.fd_count := 1; ReadFDSet.fd_array[0] := Self.SocketHandle;

  SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if IsValidSocketResult(SelectResult) and (SelectResult > 0) then begin

    IPv4SocketAddressLen := SizeOf(TIPv4SocketAddress); FillChar(IPv4SocketAddress, IPv4SocketAddressLen, 0);

    IncomingConnectionSocketHandle := IPv4Accept(Self.SocketHandle, IPv4SocketAddress, IPv4SocketAddressLen); if not(IsValidSocketHandle(IncomingConnectionSocketHandle)) then raise Exception.Create('TIPv4TcpCommunicationChannel.Accept: Accepting socket failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); Result := TIPv4TcpCommunicationChannel.Create(IncomingConnectionSocketHandle, IPv4SocketAddress.sin_addr, HTONS(IPv4SocketAddress.sin_port));

  end else begin

    Result := nil;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4TcpCommunicationChannel.Connect(RemoteAddress: TIPv4Address; RemotePort: Word);
var
  IPv4SocketAddress: TIPv4SocketAddress;
begin
  FillChar(IPv4SocketAddress, SizeOf(TIPv4SocketAddress), 0);

  IPv4SocketAddress.sin_family := AF_INET; IPv4SocketAddress.sin_addr := RemoteAddress; IPv4SocketAddress.sin_port := HTONS(RemotePort);

  if not(IsValidSocketResult(IPv4Connect(Self.SocketHandle, IPv4SocketAddress, SizeOf(TIPv4SocketAddress)))) then raise Exception.Create('TIPv4TcpCommunicationChannel.Connect: Connection to address ' + TIPv4AddressUtility.ToString(RemoteAddress) + ' and port ' + IntToStr(RemotePort) + ' failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

  Self.RemoteAddress := RemoteAddress; Self.RemotePort := RemotePort;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4TcpCommunicationChannel.Send(Buffer: Pointer; BufferLen: Integer);
begin
  if not(IsValidSocketResult(IPv4Send(Self.SocketHandle, Buffer^, BufferLen, 0))) then raise Exception.Create('TIPv4TcpCommunicationChannel.Send: Sending to address ' + TIPv4AddressUtility.ToString(Self.RemoteAddress) + ' and port ' + IntToStr(Self.RemotePort) + ' failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv4TcpCommunicationChannel.Receive(Timeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer): Boolean;
var
  TimeVal: TTimeVal; ReadFDSet: TFDSet; SelectResult: Integer;
begin
  TimeVal.tv_sec := Timeout div 1000;
  TimeVal.tv_usec := 1000 * (Timeout mod 1000);

  ReadFDSet.fd_count := 1; ReadFDSet.fd_array[0] := Self.SocketHandle;

  SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if IsValidSocketResult(SelectResult) and (SelectResult > 0) then begin

    BufferLen := IPv4Recv(Self.SocketHandle, Buffer^, MaxBufferLen, 0);

    Result := BufferLen > 0;

  end else begin

    Result := False;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4TcpCommunicationChannel.Destroy;
begin
  if IsValidSocketHandle(Self.SocketHandle) then CloseSocket(Self.SocketHandle);

  inherited Destroy;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6TcpCommunicationChannel.Create;
begin
  Self.SocketHandle := Socket(AF_INET6, SOCK_STREAM, IPPROTO_TCP);

  if not(IsValidSocketHandle(Self.SocketHandle)) then raise Exception.Create('TIPv6TcpCommunicationChannel.Create: Socket allocation failed.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6TcpCommunicationChannel.Create(SocketHandle: Integer; RemoteAddress: TIPv6Address; RemotePort: Word);
begin
  Self.SocketHandle := SocketHandle; Self.RemoteAddress := RemoteAddress; Self.RemotePort := RemotePort;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6TcpCommunicationChannel.Bind(BindingAddress: TIPv6Address; BindingPort: Word);
var
  IPv6SocketAddress: TIPv6SocketAddress;
begin
  FillChar(IPv6SocketAddress, SizeOf(TIPv6SocketAddress), 0);

  IPv6SocketAddress.sin_family := AF_INET6; IPv6SocketAddress.sin_addr := BindingAddress; IPv6SocketAddress.sin_port := HTONS(BindingPort);

  if not(IsValidSocketResult(IPv6Bind(Self.SocketHandle, IPv6SocketAddress, SizeOf(TIPv6SocketAddress)))) then raise Exception.Create('TIPv6TcpCommunicationChannel.Bind: Binding to address ' + TIPv6AddressUtility.ToString(BindingAddress) + ' and port ' + IntToStr(BindingPort) + ' failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6TcpCommunicationChannel.Listen;
begin
  if not(IsValidSocketResult(CommunicationChannels.Listen(Self.SocketHandle, 0))) then raise Exception.Create('TIPv6TcpCommunicationChannel.Listen: Listening failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv6TcpCommunicationChannel.Accept: TIPv6TcpCommunicationChannel;
var
  IncomingConnectionSocketHandle: Integer; IPv6SocketAddress: TIPv6SocketAddress; IPv6SocketAddressLen: Integer;
begin
  IPv6SocketAddressLen := SizeOf(TIPv6SocketAddress); FillChar(IPv6SocketAddress, IPv6SocketAddressLen, 0);

  IncomingConnectionSocketHandle := IPv6Accept(Self.SocketHandle, IPv6SocketAddress, IPv6SocketAddressLen); if not(IsValidSocketHandle(IncomingConnectionSocketHandle)) then raise Exception.Create('TIPv6TcpCommunicationChannel.Accept: Accepting socket failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); Result := TIPv6TcpCommunicationChannel.Create(IncomingConnectionSocketHandle, IPv6SocketAddress.sin_addr, HTONS(IPv6SocketAddress.sin_port));
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv6TcpCommunicationChannel.Accept(Timeout: Integer): TIPv6TcpCommunicationChannel;
var
  TimeVal: TTimeVal; ReadFDSet: TFDSet; SelectResult: Integer; IncomingConnectionSocketHandle: Integer; IPv6SocketAddress: TIPv6SocketAddress; IPv6SocketAddressLen: Integer;
begin
  TimeVal.tv_sec := Timeout div 1000;
  TimeVal.tv_usec := 1000 * (Timeout mod 1000);

  ReadFDSet.fd_count := 1; ReadFDSet.fd_array[0] := Self.SocketHandle;

  SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if IsValidSocketResult(SelectResult) and (SelectResult > 0) then begin

    IPv6SocketAddressLen := SizeOf(TIPv6SocketAddress); FillChar(IPv6SocketAddress, IPv6SocketAddressLen, 0);

    IncomingConnectionSocketHandle := IPv6Accept(Self.SocketHandle, IPv6SocketAddress, IPv6SocketAddressLen); if not(IsValidSocketHandle(IncomingConnectionSocketHandle)) then raise Exception.Create('TIPv6TcpCommunicationChannel.Accept: Accepting socket failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.'); Result := TIPv6TcpCommunicationChannel.Create(IncomingConnectionSocketHandle, IPv6SocketAddress.sin_addr, HTONS(IPv6SocketAddress.sin_port));

  end else begin

    Result := nil;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6TcpCommunicationChannel.Connect(RemoteAddress: TIPv6Address; RemotePort: Word);
var
  IPv6SocketAddress: TIPv6SocketAddress;
begin
  FillChar(IPv6SocketAddress, SizeOf(TIPv6SocketAddress), 0);

  IPv6SocketAddress.sin_family := AF_INET6; IPv6SocketAddress.sin_addr := RemoteAddress; IPv6SocketAddress.sin_port := HTONS(RemotePort);

  if not(IsValidSocketResult(IPv6Connect(Self.SocketHandle, IPv6SocketAddress, SizeOf(TIPv6SocketAddress)))) then raise Exception.Create('TIPv6TcpCommunicationChannel.Connect: Connection to address ' + TIPv6AddressUtility.ToString(RemoteAddress) + ' and port ' + IntToStr(RemotePort) + ' failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');

  Self.RemoteAddress := RemoteAddress; Self.RemotePort := RemotePort;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6TcpCommunicationChannel.Send(Buffer: Pointer; BufferLen: Integer);
begin
  if not(IsValidSocketResult(IPv6Send(Self.SocketHandle, Buffer^, BufferLen, 0))) then raise Exception.Create('TIPv6TcpCommunicationChannel.Send: Sending to address ' + TIPv6AddressUtility.ToString(Self.RemoteAddress) + ' and port ' + IntToStr(Self.RemotePort) + ' failed with Windows Sockets error code ' + IntToStr(WSAGetLastError) + '.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TIPv6TcpCommunicationChannel.Receive(Timeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer): Boolean;
var
  TimeVal: TTimeVal; ReadFDSet: TFDSet; SelectResult: Integer;
begin
  TimeVal.tv_sec := Timeout div 1000;
  TimeVal.tv_usec := 1000 * (Timeout mod 1000);

  ReadFDSet.fd_count := 1; ReadFDSet.fd_array[0] := Self.SocketHandle;

  SelectResult := Select(0, @ReadFDSet, nil, nil, @TimeVal); if IsValidSocketResult(SelectResult) and (SelectResult > 0) then begin

    BufferLen := IPv6Recv(Self.SocketHandle, Buffer^, MaxBufferLen, 0);

    Result := BufferLen > 0;

  end else begin

    Result := False;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6TcpCommunicationChannel.Destroy;
begin
  if IsValidSocketHandle(Self.SocketHandle) then CloseSocket(Self.SocketHandle);

  inherited Destroy;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  WinSock;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  IpUtils;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  WINDOWS_SOCKETS_VERSION = $0202;
  WINDOWS_SOCKETS_DLL = 'WS2_32.DLL';

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

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

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  PIPv4SocketAddress = ^TIPv4SocketAddress;
  TIPv4SocketAddress = packed record
    sin_family : Word;
    sin_port   : Word;
    sin_addr   : TIPv4Address;
    sin_zero   : Array [0..7] of Char;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  PIPv6SocketAddress = ^TIPv6SocketAddress;
  TIPv6SocketAddress = packed record
    sin_family   : Word;
    sin_port     : Word;
    sin_flowinfo : LongInt;
    sin_addr     : TIPv6Address;
    sin_scopeid  : LongInt;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  PFDSet = ^TFDSet;
  TFDSet = packed record
    fd_count: Cardinal;
    fd_array: Array [0..63] of Integer;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

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

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  SOCK_STREAM = 1;
  SOCK_DGRAM = 2;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  IPPROTO_TCP = 6;
  IPPROTO_UDP = 17;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  SD_SEND = 1;
  SD_BOTH = 2;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  SOCKET_ERROR = -1;
  INVALID_SOCKET = -1;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function HTONS(Value: Word): Word;

function IsValidSocketHandle(SocketHandle: Integer): Boolean;
function IsValidSocketResult(SocketResult: Integer): Boolean;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

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

end.


// --------------------------------------------------------------------------
// This unit handles I/O communications through sockets
// --------------------------------------------------------------------------

unit
  ClientServerSocket;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  WinSock;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TClientServerSocket = class
    private
      SocketHandle  : Integer;
      SocketAddrIn  : WinSock.TSockAddrIn;
      SocketAddrOut : WinSock.TSockAddrIn;
      SocketTimeout : WinSock.Timeval;
      SocketSet     : WinSock.TFDSet;
    public
      class procedure Initialize;
      class procedure Finalize;
    public
      constructor     Create(BindingAddress: Integer; BindingPort: Word);
      procedure       SendTo(Buffer: Pointer; BufferLen: Integer; Address: Integer; Port: Word);
      function        ReceiveFrom(Timeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer; var Address: Integer; var Port: Word): Boolean;
      destructor      Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SysUtils, IPAddress;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TClientServerSocket.Initialize;
var
  WSAData: WinSock.TWSAData;
begin
  if not(WinSock.WSAStartup(257, WSAData) = 0) then raise Exception.Create('TClientServerSocket.Initialize: WSAStartup function failed.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TClientServerSocket.Create(BindingAddress: Integer; BindingPort: Word);
begin
  SocketHandle := WinSock.Socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP); if (SocketHandle <> INVALID_SOCKET) then begin

    // Configure the server socket
    SocketAddrIn.sin_family := WinSock.AF_INET;
    SocketAddrIn.sin_addr.S_addr := BindingAddress; SocketAddrIn.sin_port := WinSock.htons(BindingPort);

    // If binding the server socket does not succeed then raise an exception
    if not(WinSock.Bind(SocketHandle, SocketAddrIn, SizeOf(SocketAddrIn)) <> SOCKET_ERROR) then raise Exception.Create('TClientServerSocket.Create: Binding to address ' + TIPAddress.ToString(BindingAddress) + ' and port ' + IntToStr(BindingPort) + ' failed. Is there another DNS server/proxy running?');

  end else begin // The server socket cannot be opened
    raise Exception.Create('TClientServerSocket.Create: Socket allocation failed.');
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TClientServerSocket.Destroy;
begin
  // If the socket handle is valid then close it
  if (SocketHandle <> INVALID_SOCKET) then WinSock.CloseSocket(SocketHandle);

  // Call the base destructor
  inherited Destroy;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TClientServerSocket.SendTo(Buffer: Pointer; BufferLen: Integer; Address: Integer; Port: Word);
begin
  // Configure the address
  SocketAddrOut.sin_family := WinSock.AF_INET;
  SocketAddrOut.sin_addr.S_addr := Address; SocketAddrOut.sin_port := WinSock.htons(Port);

  // Send the buffer to the specified address
  WinSock.sendto(SocketHandle, Buffer^, BufferLen, 0, SocketAddrOut, SizeOf(SocketAddrOut));
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TClientServerSocket.ReceiveFrom(Timeout: Integer; MaxBufferLen: Integer; Buffer: Pointer; var BufferLen: Integer; var Address: Integer; var Port: Word): Boolean;
var
  SocketAddrSize: Integer;
begin
  // Set the socket timeout
  SocketTimeout.tv_sec := Timeout div 1000;
  SocketTimeout.tv_usec := 1000 * (Timeout mod 1000);

  // Set the socket parameters
  SocketSet.fd_count := 1; SocketSet.fd_array[0] := SocketHandle;

  if (WinSock.Select(0, @SocketSet, nil, nil, @SocketTimeout) > 0) then begin // If there is a packet available...

    // Initialize the address size
    SocketAddrSize := SizeOf(SocketAddrIn);

    // Get the pending packet (and put it into the buffer)
    BufferLen := WinSock.recvfrom(SocketHandle, Buffer^, MaxBufferLen, 0, SocketAddrIn, SocketAddrSize);

    if (BufferLen > 0) then begin // If the packet is valid...
      
      // Get the source remote address
      Address := SocketAddrIn.sin_addr.S_addr;

      // Get the source remote UDP port
      Port := WinSock.htons(SocketAddrIn.sin_port);

      // Success!
      Result := True;

    end else begin // The packet is not valid

      // Failure!
      Result := False;

    end;

  end else begin // There are no packets available

    // Failure!
    Result := False;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TClientServerSocket.Finalize;
begin
  WinSock.WSACleanup;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

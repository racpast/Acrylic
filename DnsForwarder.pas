// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  DnsForwarder;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Classes,
  SysUtils,
  Configuration;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TDnsForwarder = class
    class function ForwardDnsRequest(ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word): Boolean;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4UdpDnsForwarder = class(TThread)
    private
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6UdpDnsForwarder = class(TThread)
    private
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4TcpDnsForwarder = class(TThread)
    private
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6TcpDnsForwarder = class(TThread)
    private
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4Socks5DnsForwarder = class(TThread)
    private
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6Socks5DnsForwarder = class(TThread)
    private
      ReferenceTime: TDateTime;
      DnsServerIndex: Integer;
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      SessionId: Word;
    public
      constructor Create(ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
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
  CommunicationChannels,
  DnsProtocol,
  DnsResolver,
  MemoryManager,
  Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsForwarder.ForwardDnsRequest(ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word): Boolean;

var
  DnsForwarderThread: TThread;

begin

  Result := False;

  DnsForwarderThread := nil; try

    case DnsServerConfiguration.Protocol of

      UdpProtocol:

        if DnsServerConfiguration.Address.IsIPv6Address then begin

          DnsForwarderThread := TIPv6UdpDnsForwarder.Create(ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarderThread <> nil) then begin

            DnsForwarderThread.Resume;

            Result := True;

          end;

        end else begin

          DnsForwarderThread := TIPv4UdpDnsForwarder.Create(ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarderThread <> nil) then begin

            DnsForwarderThread.Resume;

            Result := True;

          end;

        end;

      TcpProtocol:

        if DnsServerConfiguration.Address.IsIPv6Address then begin

          DnsForwarderThread := TIPv6TcpDnsForwarder.Create(ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarderThread <> nil) then begin

            DnsForwarderThread.Resume;

            Result := True;

          end;

        end else begin

          DnsForwarderThread := TIPv4TcpDnsForwarder.Create(ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarderThread <> nil) then begin

            DnsForwarderThread.Resume;

            Result := True;

          end;

        end;

      Socks5Protocol:

        if DnsServerConfiguration.ProxyAddress.IsIPv6Address then begin

          DnsForwarderThread := TIPv6Socks5DnsForwarder.Create(ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarderThread <> nil) then begin

            DnsForwarderThread.Resume;

            Result := True;

          end;

        end else begin

          DnsForwarderThread := TIPv4Socks5DnsForwarder.Create(ReferenceTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarderThread <> nil) then begin

            DnsForwarderThread.Resume;

            Result := True;

          end;

        end;

    end;

  except

    on E: Exception do if (DnsForwarderThread <> nil) then DnsForwarderThread.Destroy;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4UdpDnsForwarder.Create(ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4UdpDnsForwarder.Execute;

var
  CommunicationChannel: TIPv4UdpClientCommunicationChannel; IPv4Address: TIPv4Address; Port: Word;

begin

  try

    CommunicationChannel := TIPv4UdpClientCommunicationChannel.Create;

    try

      CommunicationChannel.BindToDynamicPort(ANY_IPV4_ADDRESS);

      CommunicationChannel.SendTo(Self.Buffer, Self.BufferLen, Self.DnsServerConfiguration.Address.IPv4Address, Self.DnsServerConfiguration.Port);

      if CommunicationChannel.ReceiveFrom(TConfiguration.GetServerUdpProtocolResponseTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen, IPv4Address, Port) then begin

        TDnsResolver.GetInstance.HandleDnsResponse(Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex);

      end;

    finally

      CommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv4UdpDnsForwarder.Execute: ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4UdpDnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6UdpDnsForwarder.Create(ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6UdpDnsForwarder.Execute;

var
  CommunicationChannel: TIPv6UdpClientCommunicationChannel; IPv6Address: TIPv6Address; Port: Word;

begin

  try

    CommunicationChannel := TIPv6UdpClientCommunicationChannel.Create;

    try

      CommunicationChannel.BindToDynamicPort(ANY_IPV6_ADDRESS);

      CommunicationChannel.SendTo(Self.Buffer, Self.BufferLen, Self.DnsServerConfiguration.Address.IPv6Address, Self.DnsServerConfiguration.Port);

      if CommunicationChannel.ReceiveFrom(TConfiguration.GetServerUdpProtocolResponseTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen, IPv6Address, Port) then begin

        TDnsResolver.GetInstance.HandleDnsResponse(Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex);

      end;

    finally

      CommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv4UdpDnsForwarder.Execute: ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6UdpDnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4TcpDnsForwarder.Create(ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4TcpDnsForwarder.Execute;

var
  CommunicationChannel: TIPv4TcpClientCommunicationChannel; ExchangeSucceeded: Boolean;

begin

  try

    CommunicationChannel := TIPv4TcpClientCommunicationManager.AcquireCommunicationChannel(Self.ReferenceTime, Self.DnsServerIndex); ExchangeSucceeded := False; try

      if not CommunicationChannel.Connected then CommunicationChannel.Connect(Self.DnsServerConfiguration.Address.IPv4Address, Self.DnsServerConfiguration.Port);

      CommunicationChannel.SendWrappedDnsPacket(Self.Buffer, Self.BufferLen);

      if CommunicationChannel.ReceiveWrappedDnsPacket(TConfiguration.GetServerTcpProtocolResponseTimeout, TConfiguration.GetServerTcpProtocolInternalTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

        TDnsResolver.GetInstance.HandleDnsResponse(Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex); ExchangeSucceeded := True;

      end else begin

        raise Exception.Create('No response received.');

      end;

    finally

      TIPv4TcpClientCommunicationManager.ReleaseCommunicationChannel(Self.ReferenceTime, Self.DnsServerIndex, CommunicationChannel, ExchangeSucceeded);

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv4TcpDnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4TcpDnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6TcpDnsForwarder.Create(ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6TcpDnsForwarder.Execute;

var
  CommunicationChannel: TIPv6TcpClientCommunicationChannel; ExchangeSucceeded: Boolean;

begin

  try

    CommunicationChannel := TIPv6TcpClientCommunicationManager.AcquireCommunicationChannel(Self.ReferenceTime, Self.DnsServerIndex); ExchangeSucceeded := False; try

      if not CommunicationChannel.Connected then CommunicationChannel.Connect(Self.DnsServerConfiguration.Address.IPv6Address, Self.DnsServerConfiguration.Port);

      CommunicationChannel.SendWrappedDnsPacket(Self.Buffer, Self.BufferLen);

      if CommunicationChannel.ReceiveWrappedDnsPacket(TConfiguration.GetServerTcpProtocolResponseTimeout, TConfiguration.GetServerTcpProtocolInternalTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

        TDnsResolver.GetInstance.HandleDnsResponse(Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex); ExchangeSucceeded := True;

      end else begin

        raise Exception.Create('No response received.');

      end;

    finally

      TIPv6TcpClientCommunicationManager.ReleaseCommunicationChannel(Self.ReferenceTime, Self.DnsServerIndex, CommunicationChannel, ExchangeSucceeded);

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv6TcpDnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6TcpDnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4Socks5DnsForwarder.Create(ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4Socks5DnsForwarder.Execute;

var
  CommunicationChannel: TIPv4TcpClientCommunicationChannel;

begin

  try

    CommunicationChannel := TIPv4TcpClientCommunicationChannel.Create;

    try

      CommunicationChannel.Connect(Self.DnsServerConfiguration.ProxyAddress.IPv4Address, Self.DnsServerConfiguration.ProxyPort);

      if CommunicationChannel.PerformSocks5Handshake(TConfiguration.GetServerSocks5ProtocolProxyFirstByteTimeout, TConfiguration.GetServerSocks5ProtocolProxyOtherBytesTimeout, TConfiguration.GetServerSocks5ProtocolProxyRemoteConnectTimeout, Self.DnsServerConfiguration.Address, Self.DnsServerConfiguration.Port) then begin

        CommunicationChannel.SendWrappedDnsPacket(Self.Buffer, Self.BufferLen);

        if CommunicationChannel.ReceiveWrappedDnsPacket(TConfiguration.GetServerSocks5ProtocolProxyRemoteResponseTimeout, TConfiguration.GetServerSocks5ProtocolProxyOtherBytesTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

          TDnsResolver.GetInstance.HandleDnsResponse(Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex);

        end else begin

          raise Exception.Create('No response received.');

        end;

      end;

    finally

      CommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv4Socks5DnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4Socks5DnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6Socks5DnsForwarder.Create(ReferenceTime: TDateTime; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);

begin

  inherited Create(True); Self.FreeOnTerminate := True;

  Self.ReferenceTime := ReferenceTime; Self.DnsServerIndex := DnsServerIndex; Self.DnsServerConfiguration := DnsServerConfiguration; Self.Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; Self.SessionId := SessionId;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6Socks5DnsForwarder.Execute;

var
  CommunicationChannel: TIPv6TcpClientCommunicationChannel;

begin

  try

    CommunicationChannel := TIPv6TcpClientCommunicationChannel.Create;

    try

      CommunicationChannel.Connect(Self.DnsServerConfiguration.ProxyAddress.IPv6Address, Self.DnsServerConfiguration.ProxyPort);

      if CommunicationChannel.PerformSocks5Handshake(TConfiguration.GetServerSocks5ProtocolProxyFirstByteTimeout, TConfiguration.GetServerSocks5ProtocolProxyOtherBytesTimeout, TConfiguration.GetServerSocks5ProtocolProxyRemoteConnectTimeout, Self.DnsServerConfiguration.Address, Self.DnsServerConfiguration.Port) then begin

        CommunicationChannel.SendWrappedDnsPacket(Self.Buffer, Self.BufferLen);

        if CommunicationChannel.ReceiveWrappedDnsPacket(TConfiguration.GetServerSocks5ProtocolProxyRemoteResponseTimeout, TConfiguration.GetServerSocks5ProtocolProxyOtherBytesTimeout, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen) then begin

          TDnsResolver.GetInstance.HandleDnsResponse(Now, Self.Buffer, Self.BufferLen, Self.DnsServerIndex);

        end else begin

          raise Exception.Create('No response received.');

        end;

      end;

    finally

      CommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv6Socks5DnsForwarder.Execute: The following error occurred while forwarding request ID ' + IntToStr(Self.SessionId) + ' to server ' + IntToStr(Self.DnsServerIndex + 1) + ': ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6Socks5DnsForwarder.Destroy;

begin

  TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

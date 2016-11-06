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
    class function ForwardDnsRequest(DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word): Boolean;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4UdpDnsForwarder = class(TThread)
    private
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      Output: Pointer;
      OutputLen: Integer;
      SessionId: Word;
    public
      constructor Create(DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6UdpDnsForwarder = class(TThread)
    private
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      Output: Pointer;
      OutputLen: Integer;
      SessionId: Word;
    public
      constructor Create(DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4TcpDnsForwarder = class(TThread)
    private
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      Intermediate: Pointer;
      IntermediateLen: Integer;
      Output: Pointer;
      OutputLen: Integer;
      SessionId: Word;
    public
      constructor Create(DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6TcpDnsForwarder = class(TThread)
    private
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      Intermediate: Pointer;
      IntermediateLen: Integer;
      Output: Pointer;
      OutputLen: Integer;
      SessionId: Word;
    public
      constructor Create(DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4Socks5DnsForwarder = class(TThread)
    private
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      Intermediate: Pointer;
      IntermediateLen: Integer;
      Output: Pointer;
      OutputLen: Integer;
      SessionId: Word;
    public
      constructor Create(DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6Socks5DnsForwarder = class(TThread)
    private
      DnsServerConfiguration: TDnsServerConfiguration;
      Buffer: Pointer;
      BufferLen: Integer;
      Intermediate: Pointer;
      IntermediateLen: Integer;
      Output: Pointer;
      OutputLen: Integer;
      SessionId: Word;
    public
      constructor Create(DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
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

const
  DNS_FORWARDER_MAX_BIND_RETRIES = 10;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  DNS_FORWARDER_RESPONSE_RECEIVE_TIMEOUT = 3989;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsForwarder.ForwardDnsRequest(DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word): Boolean;
var
  DnsForwarderThread: TThread;
begin
  Result := False;

  DnsForwarderThread := nil; try

    case DnsServerConfiguration.Protocol of

      UdpProtocol:

        if DnsServerConfiguration.Address.IsIPv6Address then begin

          DnsForwarderThread := TIPv6UdpDnsForwarder.Create(DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarderThread <> nil) then begin

            DnsForwarderThread.Resume;

            Result := True;

          end;

        end else begin

          DnsForwarderThread := TIPv4UdpDnsForwarder.Create(DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarderThread <> nil) then begin

            DnsForwarderThread.Resume;

            Result := True;

          end;

        end;

      TcpProtocol:

        if DnsServerConfiguration.Address.IsIPv6Address then begin

          DnsForwarderThread := TIPv6TcpDnsForwarder.Create(DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarderThread <> nil) then begin

            DnsForwarderThread.Resume;

            Result := True;

          end;

        end else begin

          DnsForwarderThread := TIPv4TcpDnsForwarder.Create(DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarderThread <> nil) then begin

            DnsForwarderThread.Resume;

            Result := True;

          end;

        end;

      Socks5Protocol:

        if DnsServerConfiguration.ProxyAddress.IsIPv6Address then begin

          DnsForwarderThread := TIPv6Socks5DnsForwarder.Create(DnsServerConfiguration, Buffer, BufferLen, SessionId);

          if (DnsForwarderThread <> nil) then begin

            DnsForwarderThread.Resume;

            Result := True;

          end;

        end else begin

          DnsForwarderThread := TIPv4Socks5DnsForwarder.Create(DnsServerConfiguration, Buffer, BufferLen, SessionId);

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

constructor TIPv4UdpDnsForwarder.Create(DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
begin
  inherited Create(True); Self.FreeOnTerminate := True;

  Self.DnsServerConfiguration := DnsServerConfiguration; TMemoryManager.GetMemory(Self.Buffer, MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; TMemoryManager.GetMemory(Self.Output, MAX_DNS_BUFFER_LEN); Self.OutputLen := 0; Self.SessionId := SessionId;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4UdpDnsForwarder.Execute;
var
  CommunicationChannel: TIPv4UdpCommunicationChannel; IPv4Address: TIPv4Address; Port: Word;
begin
  try

    CommunicationChannel := TIPv4UdpCommunicationChannel.Create;

    try

      CommunicationChannel.BindToRandomUnregisteredPort(ANY_IPV4_ADDRESS, DNS_FORWARDER_MAX_BIND_RETRIES);

      CommunicationChannel.SendTo(Self.Buffer, Self.BufferLen, Self.DnsServerConfiguration.Address.IPv4Address, Self.DnsServerConfiguration.Port);

      if CommunicationChannel.ReceiveFrom(DNS_FORWARDER_RESPONSE_RECEIVE_TIMEOUT, MAX_DNS_BUFFER_LEN, Self.Output, Self.OutputLen, IPv4Address, Port) then begin

        TDnsResolver.GetInstance.HandleDnsResponse(Self.Output, Self.OutputLen, TDualIPAddressUtility.CreateFromIPv4Address(IPv4Address), Port);

      end;

    finally

      CommunicationChannel.Free;

    end;

  except

    on E: Exception do if (TTracer.IsEnabled) then TTracer.Trace(TracePriorityError, 'TIPv4UdpDnsForwarder.Execute: ' + E.Message);

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4UdpDnsForwarder.Destroy;
begin
  TMemoryManager.FreeMemory(Self.Output, MAX_DNS_BUFFER_LEN); TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6UdpDnsForwarder.Create(DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
begin
  inherited Create(True); Self.FreeOnTerminate := True;

  Self.DnsServerConfiguration := DnsServerConfiguration; TMemoryManager.GetMemory(Self.Buffer, MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; TMemoryManager.GetMemory(Self.Output, MAX_DNS_BUFFER_LEN); Self.OutputLen := 0; Self.SessionId := SessionId;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6UdpDnsForwarder.Execute;
var
  CommunicationChannel: TIPv6UdpCommunicationChannel; IPv6Address: TIPv6Address; Port: Word;
begin
  try

    CommunicationChannel := TIPv6UdpCommunicationChannel.Create;

    try

      CommunicationChannel.BindToRandomUnregisteredPort(ANY_IPV6_ADDRESS, DNS_FORWARDER_MAX_BIND_RETRIES);

      CommunicationChannel.SendTo(Self.Buffer, Self.BufferLen, Self.DnsServerConfiguration.Address.IPv6Address, Self.DnsServerConfiguration.Port);

      if CommunicationChannel.ReceiveFrom(DNS_FORWARDER_RESPONSE_RECEIVE_TIMEOUT, MAX_DNS_BUFFER_LEN, Self.Output, Self.OutputLen, IPv6Address, Port) then begin

        TDnsResolver.GetInstance.HandleDnsResponse(Self.Output, Self.OutputLen, TDualIPAddressUtility.CreateFromIPv6Address(IPv6Address), Port);

      end;

    finally

      CommunicationChannel.Free;

    end;

  except

    on E: Exception do if (TTracer.IsEnabled) then TTracer.Trace(TracePriorityError, 'TIPv4UdpDnsForwarder.Execute: ' + E.Message);

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6UdpDnsForwarder.Destroy;
begin
  TMemoryManager.FreeMemory(Self.Output, MAX_DNS_BUFFER_LEN); TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4TcpDnsForwarder.Create(DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
begin
  inherited Create(True); Self.FreeOnTerminate := True;

  Self.DnsServerConfiguration := DnsServerConfiguration; TMemoryManager.GetMemory(Self.Buffer, MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; TMemoryManager.GetMemory(Self.Intermediate, MAX_DNS_BUFFER_LEN); Self.IntermediateLen := 0; TMemoryManager.GetMemory(Self.Output, MAX_DNS_BUFFER_LEN); Self.OutputLen := 0; Self.SessionId := SessionId;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4TcpDnsForwarder.Execute;
var
  CommunicationChannel: TIPv4TcpCommunicationChannel;
begin
  try

    CommunicationChannel := TIPv4TcpCommunicationChannel.Create;

    try

      CommunicationChannel.Connect(Self.DnsServerConfiguration.Address.IPv4Address, Self.DnsServerConfiguration.Port);

      TDnsProtocolUtility.WrapUdpRequestPacketOverTcpRequestPacket(Buffer, BufferLen, Self.Intermediate, Self.IntermediateLen);

      CommunicationChannel.Send(Self.Intermediate, Self.IntermediateLen);

      if CommunicationChannel.Receive(DNS_FORWARDER_RESPONSE_RECEIVE_TIMEOUT, MAX_DNS_BUFFER_LEN, Self.Intermediate, Self.IntermediateLen) then begin

        TDnsProtocolUtility.WrapTcpResponsePacketOverUdpResponsePacket(Self.Intermediate, Self.IntermediateLen, Self.Output, Self.OutputLen);

        TDnsResolver.GetInstance.HandleDnsResponse(Self.Output, Self.OutputLen, Self.DnsServerConfiguration.Address, Self.DnsServerConfiguration.Port);

      end;

    finally

      CommunicationChannel.Free;

    end;

  except

    on E: Exception do if (TTracer.IsEnabled) then TTracer.Trace(TracePriorityError, 'TIPv4TcpDnsForwarder.Execute: ' + E.Message);

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4TcpDnsForwarder.Destroy;
begin
  TMemoryManager.FreeMemory(Self.Output, MAX_DNS_BUFFER_LEN); TMemoryManager.FreeMemory(Self.Intermediate, MAX_DNS_BUFFER_LEN); TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6TcpDnsForwarder.Create(DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
begin
  inherited Create(True); Self.FreeOnTerminate := True;

  Self.DnsServerConfiguration := DnsServerConfiguration; TMemoryManager.GetMemory(Self.Buffer, MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; TMemoryManager.GetMemory(Self.Intermediate, MAX_DNS_BUFFER_LEN); Self.IntermediateLen := 0; TMemoryManager.GetMemory(Self.Output, MAX_DNS_BUFFER_LEN); Self.OutputLen := 0; Self.SessionId := SessionId;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6TcpDnsForwarder.Execute;
var
  CommunicationChannel: TIPv6TcpCommunicationChannel;
begin
  try

    CommunicationChannel := TIPv6TcpCommunicationChannel.Create;

    try

      CommunicationChannel.Connect(Self.DnsServerConfiguration.Address.IPv6Address, Self.DnsServerConfiguration.Port);

      TDnsProtocolUtility.WrapUdpRequestPacketOverTcpRequestPacket(Buffer, BufferLen, Self.Intermediate, Self.IntermediateLen);

      CommunicationChannel.Send(Self.Intermediate, Self.IntermediateLen);

      if CommunicationChannel.Receive(DNS_FORWARDER_RESPONSE_RECEIVE_TIMEOUT, MAX_DNS_BUFFER_LEN, Self.Intermediate, Self.IntermediateLen) then begin

        TDnsProtocolUtility.WrapTcpResponsePacketOverUdpResponsePacket(Self.Intermediate, Self.IntermediateLen, Self.Output, Self.OutputLen);

        TDnsResolver.GetInstance.HandleDnsResponse(Self.Output, Self.OutputLen, Self.DnsServerConfiguration.Address, Self.DnsServerConfiguration.Port);

      end;

    finally

      CommunicationChannel.Free;

    end;

  except

    on E: Exception do if (TTracer.IsEnabled) then TTracer.Trace(TracePriorityError, 'TIPv6TcpDnsForwarder.Execute: ' + E.Message);

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6TcpDnsForwarder.Destroy;
begin
  TMemoryManager.FreeMemory(Self.Output, MAX_DNS_BUFFER_LEN); TMemoryManager.FreeMemory(Self.Intermediate, MAX_DNS_BUFFER_LEN); TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4Socks5DnsForwarder.Create(DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
begin
  inherited Create(True); Self.FreeOnTerminate := True;

  Self.DnsServerConfiguration := DnsServerConfiguration; TMemoryManager.GetMemory(Self.Buffer, MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; TMemoryManager.GetMemory(Self.Intermediate, MAX_DNS_BUFFER_LEN); Self.IntermediateLen := 0; TMemoryManager.GetMemory(Self.Output, MAX_DNS_BUFFER_LEN); Self.OutputLen := 0; Self.SessionId := SessionId;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4Socks5DnsForwarder.Execute;
var
  CommunicationChannel: TIPv4TcpCommunicationChannel;
begin
  try

    CommunicationChannel := TIPv4TcpCommunicationChannel.Create;

    try

      CommunicationChannel.Connect(Self.DnsServerConfiguration.ProxyAddress.IPv4Address, Self.DnsServerConfiguration.ProxyPort);

      PByteArray(Self.Intermediate)^[00] := $05;
      PByteArray(Self.Intermediate)^[01] := $01;
      PByteArray(Self.Intermediate)^[02] := $00;

      Self.IntermediateLen := 3;

      CommunicationChannel.Send(Self.Intermediate, Self.IntermediateLen); if CommunicationChannel.Receive(DNS_FORWARDER_RESPONSE_RECEIVE_TIMEOUT, MAX_DNS_BUFFER_LEN, Self.Intermediate, Self.IntermediateLen) then begin

        if Self.DnsServerConfiguration.Address.IsIPv6Address then begin

          PByteArray(Self.Intermediate)^[00] := $05;
          PByteArray(Self.Intermediate)^[01] := $01;
          PByteArray(Self.Intermediate)^[02] := $00;
          PByteArray(Self.Intermediate)^[03] := $04;

          Move(Self.DnsServerConfiguration.Address.IPv6Address, PByteArray(Self.Intermediate)^[04], SizeOf(TIPv6Address));

          PByteArray(Self.Intermediate)^[20] := Self.DnsServerConfiguration.Port shr $08;
          PByteArray(Self.Intermediate)^[21] := Self.DnsServerConfiguration.Port and $ff;

          Self.IntermediateLen := 22;

        end else begin

          PByteArray(Self.Intermediate)^[00] := $05;
          PByteArray(Self.Intermediate)^[01] := $01;
          PByteArray(Self.Intermediate)^[02] := $00;
          PByteArray(Self.Intermediate)^[03] := $01;

          Move(Self.DnsServerConfiguration.Address.IPv4Address, PByteArray(Self.Intermediate)^[04], SizeOf(TIPv4Address));

          PByteArray(Self.Intermediate)^[08] := Self.DnsServerConfiguration.Port shr $08;
          PByteArray(Self.Intermediate)^[09] := Self.DnsServerConfiguration.Port and $ff;

          Self.IntermediateLen := 10;

        end;

        CommunicationChannel.Send(Self.Intermediate, Self.IntermediateLen); if CommunicationChannel.Receive(DNS_FORWARDER_RESPONSE_RECEIVE_TIMEOUT, MAX_DNS_BUFFER_LEN, Self.Intermediate, Self.IntermediateLen) then begin

          TDnsProtocolUtility.WrapUdpRequestPacketOverTcpRequestPacket(Buffer, BufferLen, Self.Intermediate, Self.IntermediateLen);

          CommunicationChannel.Send(Self.Intermediate, Self.IntermediateLen); if CommunicationChannel.Receive(DNS_FORWARDER_RESPONSE_RECEIVE_TIMEOUT, MAX_DNS_BUFFER_LEN, Self.Intermediate, Self.IntermediateLen) then begin

            TDnsProtocolUtility.WrapTcpResponsePacketOverUdpResponsePacket(Self.Intermediate, Self.IntermediateLen, Self.Output, Self.OutputLen);

            TDnsResolver.GetInstance.HandleDnsResponse(Self.Output, Self.OutputLen, DnsServerConfiguration.Address, DnsServerConfiguration.Port);

          end;

        end;

      end;

    finally

      CommunicationChannel.Free;

    end;

  except

    on E: Exception do if (TTracer.IsEnabled) then TTracer.Trace(TracePriorityError, 'TIPv4Socks5DnsForwarder.Execute: ' + E.Message);

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4Socks5DnsForwarder.Destroy;
begin
  TMemoryManager.FreeMemory(Self.Output, MAX_DNS_BUFFER_LEN); TMemoryManager.FreeMemory(Self.Intermediate, MAX_DNS_BUFFER_LEN); TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6Socks5DnsForwarder.Create(DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
begin
  inherited Create(True); Self.FreeOnTerminate := True;

  Self.DnsServerConfiguration := DnsServerConfiguration; TMemoryManager.GetMemory(Self.Buffer, MAX_DNS_BUFFER_LEN); Move(Buffer^, Self.Buffer^, BufferLen); Self.BufferLen := BufferLen; TMemoryManager.GetMemory(Self.Intermediate, MAX_DNS_BUFFER_LEN); Self.IntermediateLen := 0; TMemoryManager.GetMemory(Self.Output, MAX_DNS_BUFFER_LEN); Self.OutputLen := 0; Self.SessionId := SessionId;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6Socks5DnsForwarder.Execute;
var
  CommunicationChannel: TIPv6TcpCommunicationChannel;
begin
  try

    CommunicationChannel := TIPv6TcpCommunicationChannel.Create;

    try

      CommunicationChannel.Connect(Self.DnsServerConfiguration.ProxyAddress.IPv6Address, Self.DnsServerConfiguration.ProxyPort);

      PByteArray(Self.Intermediate)^[00] := $05;
      PByteArray(Self.Intermediate)^[01] := $01;
      PByteArray(Self.Intermediate)^[02] := $00;

      Self.IntermediateLen := 3;

      CommunicationChannel.Send(Self.Intermediate, Self.IntermediateLen); if CommunicationChannel.Receive(DNS_FORWARDER_RESPONSE_RECEIVE_TIMEOUT, MAX_DNS_BUFFER_LEN, Self.Intermediate, Self.IntermediateLen) then begin

        if Self.DnsServerConfiguration.Address.IsIPv6Address then begin

          PByteArray(Self.Intermediate)^[00] := $05;
          PByteArray(Self.Intermediate)^[01] := $01;
          PByteArray(Self.Intermediate)^[02] := $00;
          PByteArray(Self.Intermediate)^[03] := $04;

          Move(Self.DnsServerConfiguration.Address.IPv6Address, PByteArray(Self.Intermediate)^[04], SizeOf(TIPv6Address));

          PByteArray(Self.Intermediate)^[20] := Self.DnsServerConfiguration.Port shr $08;
          PByteArray(Self.Intermediate)^[21] := Self.DnsServerConfiguration.Port and $ff;

          Self.IntermediateLen := 22;

        end else begin

          PByteArray(Self.Intermediate)^[00] := $05;
          PByteArray(Self.Intermediate)^[01] := $01;
          PByteArray(Self.Intermediate)^[02] := $00;
          PByteArray(Self.Intermediate)^[03] := $01;

          Move(Self.DnsServerConfiguration.Address.IPv4Address, PByteArray(Self.Intermediate)^[04], SizeOf(TIPv4Address));

          PByteArray(Self.Intermediate)^[08] := Self.DnsServerConfiguration.Port shr $08;
          PByteArray(Self.Intermediate)^[09] := Self.DnsServerConfiguration.Port and $ff;

          Self.IntermediateLen := 10;

        end;

        CommunicationChannel.Send(Self.Intermediate, Self.IntermediateLen); if CommunicationChannel.Receive(DNS_FORWARDER_RESPONSE_RECEIVE_TIMEOUT, MAX_DNS_BUFFER_LEN, Self.Intermediate, Self.IntermediateLen) then begin

          TDnsProtocolUtility.WrapUdpRequestPacketOverTcpRequestPacket(Buffer, BufferLen, Self.Intermediate, Self.IntermediateLen);

          CommunicationChannel.Send(Self.Intermediate, Self.IntermediateLen); if CommunicationChannel.Receive(DNS_FORWARDER_RESPONSE_RECEIVE_TIMEOUT, MAX_DNS_BUFFER_LEN, Self.Intermediate, Self.IntermediateLen) then begin

            TDnsProtocolUtility.WrapTcpResponsePacketOverUdpResponsePacket(Self.Intermediate, Self.IntermediateLen, Self.Output, Self.OutputLen);

            TDnsResolver.GetInstance.HandleDnsResponse(Self.Output, Self.OutputLen, Self.DnsServerConfiguration.Address, Self.DnsServerConfiguration.Port);

          end;

        end;

      end;

    finally

      CommunicationChannel.Free;

    end;

  except

    on E: Exception do if (TTracer.IsEnabled) then TTracer.Trace(TracePriorityError, 'TIPv6Socks5DnsForwarder.Execute: ' + E.Message);

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6Socks5DnsForwarder.Destroy;
begin
  TMemoryManager.FreeMemory(Self.Output, MAX_DNS_BUFFER_LEN); TMemoryManager.FreeMemory(Self.Intermediate, MAX_DNS_BUFFER_LEN); TMemoryManager.FreeMemory(Self.Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

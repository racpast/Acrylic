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
    class procedure ForwardDnsRequest(DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
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
  DNS_FORWARDER_RESPONSE_RECEIVE_TIMEOUT = 3989;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsForwarder.ForwardDnsRequest(DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
begin
  if DnsServerConfiguration.Address.IsIPv6Address then begin
    case DnsServerConfiguration.Protocol of
      UdpProtocol: TIPv6UdpDnsForwarder.Create(DnsServerConfiguration, Buffer, BufferLen, SessionId).Resume;
      TcpProtocol: TIPv6TcpDnsForwarder.Create(DnsServerConfiguration, Buffer, BufferLen, SessionId).Resume;
    end;
  end else begin
    case DnsServerConfiguration.Protocol of
      UdpProtocol: TIPv4UdpDnsForwarder.Create(DnsServerConfiguration, Buffer, BufferLen, SessionId).Resume;
      TcpProtocol: TIPv4TcpDnsForwarder.Create(DnsServerConfiguration, Buffer, BufferLen, SessionId).Resume;
    end;
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4UdpDnsForwarder.Create(DnsServerConfiguration: TDnsServerConfiguration; Buffer: Pointer; BufferLen: Integer; SessionId: Word);
begin
  inherited Create(True);

  // Free automatically
  FreeOnTerminate := True;

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

    // Create the communication channel
    CommunicationChannel := TIPv4UdpCommunicationChannel.Create;

    try

      // Bind the communication channel to a random unregistered port
      CommunicationChannel.BindToRandomUnregisteredPort(ANY_IPV4_ADDRESS, DNS_FORWARDER_MAX_BIND_RETRIES);

      // Forward the DNS request to the specified DNS server
      CommunicationChannel.SendTo(Self.Buffer, Self.BufferLen, DnsServerConfiguration.Address.IPv4Address, DnsServerConfiguration.Port);

      // Wait for a reply and if there is a packet available
      if CommunicationChannel.ReceiveFrom(DNS_FORWARDER_RESPONSE_RECEIVE_TIMEOUT, MAX_DNS_BUFFER_LEN, Self.Output, Self.OutputLen, IPv4Address, Port) then begin

        // Try to handle it as a DNS response
        TDnsResolver.GetInstance.HandleDnsResponse(Self.Output, Self.OutputLen, TDualIPAddressUtility.CreateFromIPv4Address(IPv4Address), Port);

      end;

    finally

      // Destroy the communication channel
      CommunicationChannel.Free;

    end;

  except // In case of an exception

    // Trace the event if a tracer is enabled
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
  inherited Create(True);

  // Free automatically
  FreeOnTerminate := True;

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

    // Create the communication channel
    CommunicationChannel := TIPv6UdpCommunicationChannel.Create;

    try

      // Bind the communication channel to a random unregistered port
      CommunicationChannel.BindToRandomUnregisteredPort(ANY_IPV6_ADDRESS, DNS_FORWARDER_MAX_BIND_RETRIES);

      // Forward the DNS request to the specified DNS server
      CommunicationChannel.SendTo(Self.Buffer, Self.BufferLen, DnsServerConfiguration.Address.IPv6Address, DnsServerConfiguration.Port);

      // Wait for a reply and if there is a packet available
      if CommunicationChannel.ReceiveFrom(DNS_FORWARDER_RESPONSE_RECEIVE_TIMEOUT, MAX_DNS_BUFFER_LEN, Self.Output, Self.OutputLen, IPv6Address, Port) then begin

        // Try to handle it as a DNS response
        TDnsResolver.GetInstance.HandleDnsResponse(Self.Output, Self.OutputLen, TDualIPAddressUtility.CreateFromIPv6Address(IPv6Address), Port);

      end;

    finally

      // Destroy the communication channel
      CommunicationChannel.Free;

    end;

  except // In case of an exception

    // Trace the event if a tracer is enabled
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
  inherited Create(True);

  // Free automatically
  FreeOnTerminate := True;

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

    // Create the communication channel
    CommunicationChannel := TIPv4TcpCommunicationChannel.Create;

    try

      // Connect with the specified DNS server
      CommunicationChannel.Connect(DnsServerConfiguration.Address.IPv4Address, DnsServerConfiguration.Port);

      // Wrap the UDP request over a TCP request
      TDnsProtocolUtility.WrapUdpRequestPacketOverTcpRequestPacket(Buffer, BufferLen, Self.Intermediate, Self.IntermediateLen);

      // Forward the DNS request to the specified DNS server
      CommunicationChannel.Send(Self.Intermediate, Self.IntermediateLen);

      // Wait for a reply and if there is a packet available...
      if CommunicationChannel.Receive(DNS_FORWARDER_RESPONSE_RECEIVE_TIMEOUT, MAX_DNS_BUFFER_LEN, Self.Intermediate, Self.IntermediateLen) then begin

        // Wrap the TCP response over a UDP response
        TDnsProtocolUtility.WrapTcpResponsePacketOverUdpResponsePacket(Self.Intermediate, Self.IntermediateLen, Self.Output, Self.OutputLen);

        // Try to handle it as a DNS response
        TDnsResolver.GetInstance.HandleDnsResponse(Self.Output, Self.OutputLen, DnsServerConfiguration.Address, DnsServerConfiguration.Port);

      end;

    finally

      // Destroy the communication channel
      CommunicationChannel.Free;

    end;

  except // In case of an exception

    // Trace the event if a tracer is enabled
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
  inherited Create(True);

  // Free automatically
  FreeOnTerminate := True;

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

    // Create the communication channel
    CommunicationChannel := TIPv6TcpCommunicationChannel.Create;

    try

      // Connect with the specified DNS server
      CommunicationChannel.Connect(DnsServerConfiguration.Address.IPv6Address, DnsServerConfiguration.Port);

      // Wrap the UDP request over a TCP request
      TDnsProtocolUtility.WrapUdpRequestPacketOverTcpRequestPacket(Buffer, BufferLen, Self.Intermediate, Self.IntermediateLen);

      // Forward the DNS request to the specified DNS server
      CommunicationChannel.Send(Self.Intermediate, Self.IntermediateLen);

      // Wait for a reply and if there is a packet available...
      if CommunicationChannel.Receive(DNS_FORWARDER_RESPONSE_RECEIVE_TIMEOUT, MAX_DNS_BUFFER_LEN, Self.Intermediate, Self.IntermediateLen) then begin

        // Wrap the TCP response over a UDP response
        TDnsProtocolUtility.WrapTcpResponsePacketOverUdpResponsePacket(Self.Intermediate, Self.IntermediateLen, Self.Output, Self.OutputLen);

        // Try to handle it as a DNS response
        TDnsResolver.GetInstance.HandleDnsResponse(Self.Output, Self.OutputLen, DnsServerConfiguration.Address, DnsServerConfiguration.Port);

      end;

    finally

      // Destroy the communication channel
      CommunicationChannel.Free;

    end;

  except // In case of an exception

    // Trace the event if a tracer is enabled
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

end.

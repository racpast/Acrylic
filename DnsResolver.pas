// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  DnsResolver;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Classes,
  SyncObjs,
  CommunicationChannels,
  Configuration,
  IPUtils;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TDnsResolver = class
    public
      class procedure StartResolver;
      class procedure StopResolver;
    private
      class procedure StartResolverThreads;
      class procedure StopResolverThreads;
    public
      class procedure HandleDnsRequestForIPv4Udp(ServerCommunicationChannel: TIPv4UdpCommunicationChannel; ArrivalTime: TDateTime; Buffer: Pointer; BufferLen: Integer; var Output: Pointer; var OutputLen: Integer; Address: TIPv4Address; Port: Word);
      class procedure HandleDnsRequestForIPv4Tcp(ServerCommunicationChannel: TIPv4TcpCommunicationChannel; ArrivalTime: TDateTime; Buffer: Pointer; BufferLen: Integer; var Output: Pointer; var OutputLen: Integer; Address: TIPv4Address; Port: Word);
      class procedure HandleDnsRequestForIPv6Udp(ServerCommunicationChannel: TIPv6UdpCommunicationChannel; ArrivalTime: TDateTime; Buffer: Pointer; BufferLen: Integer; var Output: Pointer; var OutputLen: Integer; Address: TIPv6Address; Port: Word);
      class procedure HandleDnsRequestForIPv6Tcp(ServerCommunicationChannel: TIPv6TcpCommunicationChannel; ArrivalTime: TDateTime; Buffer: Pointer; BufferLen: Integer; var Output: Pointer; var OutputLen: Integer; Address: TIPv6Address; Port: Word);
    public
      class procedure HandleDnsResponseForIPv4Udp(ServerCommunicationChannel: TIPv4UdpCommunicationChannel; ArrivalTime: TDateTime; Buffer: Pointer; BufferLen: Integer; DnsServerIndex: Integer; DnsServerResponseTime: Double; DnsServerConfiguration: TDnsServerConfiguration);
      class procedure HandleDnsResponseForIPv4Tcp(ServerCommunicationChannel: TIPv4TcpCommunicationChannel; ArrivalTime: TDateTime; Buffer: Pointer; BufferLen: Integer; DnsServerIndex: Integer; DnsServerResponseTime: Double; DnsServerConfiguration: TDnsServerConfiguration);
      class procedure HandleDnsResponseForIPv6Udp(ServerCommunicationChannel: TIPv6UdpCommunicationChannel; ArrivalTime: TDateTime; Buffer: Pointer; BufferLen: Integer; DnsServerIndex: Integer; DnsServerResponseTime: Double; DnsServerConfiguration: TDnsServerConfiguration);
      class procedure HandleDnsResponseForIPv6Tcp(ServerCommunicationChannel: TIPv6TcpCommunicationChannel; ArrivalTime: TDateTime; Buffer: Pointer; BufferLen: Integer; DnsServerIndex: Integer; DnsServerResponseTime: Double; DnsServerConfiguration: TDnsServerConfiguration);
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4UdpDnsResolver = class(TThread)
    public
      constructor Create;
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4TcpDnsResolver = class(TThread)
    public
      constructor Create;
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4TcpDnsResolverSession = class(TThread)
    private
      ServerCommunicationChannel: TIPv4TcpCommunicationChannel;
    public
      constructor Create(ServerCommunicationChannel: TIPv4TcpCommunicationChannel);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6UdpDnsResolver = class(TThread)
    public
      constructor Create;
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6TcpDnsResolver = class(TThread)
    public
      constructor Create;
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6TcpDnsResolverSession = class(TThread)
    private
      ServerCommunicationChannel: TIPv6TcpCommunicationChannel;
    public
      constructor Create(ServerCommunicationChannel: TIPv6TcpCommunicationChannel);
      procedure   Execute; override;
      destructor  Destroy; override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TDnsResolverAddressCachePruner = class(TThread)
    public
      constructor Create;
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
  SysUtils,
  Windows,
  AddressCache,
  DnsForwarder,
  DnsOverHttpsCache,
  DnsProtocol,
  Environment,
  HitLogger,
  HostsCache,
  MD5,
  MemoryManager,
  SessionCache,
  Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  DNS_RESOLVER_WAIT_TIME = 4999;
  DNS_RESOLVER_FADE_TIME = 1999;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TDnsResolver_Lock: TCriticalSection;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  IPv4UdpDnsResolver: TIPv4UdpDnsResolver;
  IPv4TcpDnsResolver: TIPv4TcpDnsResolver;
  IPv6UdpDnsResolver: TIPv6UdpDnsResolver;
  IPv6TcpDnsResolver: TIPv6TcpDnsResolver;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  DnsResolverAddressCachePruner: TDnsResolverAddressCachePruner;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsResolver.StartResolver;

begin

  Randomize;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.StartResolver: Initializing...');

  TCommunicationChannel.Initialize; TDnsOverHttpsCache.Initialize; TSessionCache.Initialize; TAddressCache.Initialize; THostsCache.Initialize;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.StartResolver: Done initializing.');

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.StartResolver: Reading system info...');

  TEnvironment.ReadSystemInfo;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.StartResolver: Done reading system info.');

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.StartResolver: Loading configuration...');

  TConfiguration.LoadFromFile(TConfiguration.GetConfigurationFileName);

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.StartResolver: Done loading configuration.');

  if FileExists(TConfiguration.GetHostsCacheFileName) then begin

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.StartResolver: Loading hosts cache items...');

    try

      THostsCache.LoadFromFile(TConfiguration.GetHostsCacheFileName);

    except

      on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TDnsResolver.StartResolver: The following error occurred while loading hosts cache items: ' + E.Message);

    end;

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.StartResolver: Done loading hosts cache items.');

  end;

  if not(TConfiguration.GetAddressCacheDisabled) and not(TConfiguration.GetAddressCacheInMemoryOnly) and FileExists(TConfiguration.GetAddressCacheFileName) then begin

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.StartResolver: Loading address cache items...');

    try

      TAddressCache.LoadFromFile(TConfiguration.GetAddressCacheFileName);

    except

      on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TDnsResolver.StartResolver: The following error occurred while loading address cache items: ' + E.Message);

    end;

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.StartResolver: Done loading address cache items.');

  end;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.StartResolver: Starting resolver threads...');

  TDnsResolver.StartResolverThreads;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.StartResolver: Done starting resolver threads.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsResolver.StartResolverThreads;

begin

  TDnsResolver_Lock := TCriticalSection.Create;

  if TConfiguration.IsLocalIPv4BindingEnabled then begin

    IPv4UdpDnsResolver := TIPv4UdpDnsResolver.Create; IPv4TcpDnsResolver := TIPv4TcpDnsResolver.Create;

  end;

  if TConfiguration.IsLocalIPv6BindingEnabled then begin

    IPv6UdpDnsResolver := TIPv6UdpDnsResolver.Create; IPv6TcpDnsResolver := TIPv6TcpDnsResolver.Create;

  end;

  if not TConfiguration.GetAddressCacheDisabled then begin

    DnsResolverAddressCachePruner := TDnsResolverAddressCachePruner.Create;

  end;

  if TConfiguration.IsLocalIPv4BindingEnabled then begin

    IPv4UdpDnsResolver.Resume; IPv4TcpDnsResolver.Resume;

  end;

  if TConfiguration.IsLocalIPv6BindingEnabled then begin

    IPv6UdpDnsResolver.Resume; IPv6TcpDnsResolver.Resume;

  end;

  if not TConfiguration.GetAddressCacheDisabled then begin

    DnsResolverAddressCachePruner.Resume;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsResolver.StopResolverThreads;

begin

  if not TConfiguration.GetAddressCacheDisabled then begin

    DnsResolverAddressCachePruner.Terminate;

  end;

  if TConfiguration.IsLocalIPv6BindingEnabled then begin

    IPv6UdpDnsResolver.Terminate; IPv6TcpDnsResolver.Terminate; TerminateThread(IPv6TcpDnsResolver.Handle, 0);

  end;

  if TConfiguration.IsLocalIPv4BindingEnabled then begin

    IPv4UdpDnsResolver.Terminate; IPv4TcpDnsResolver.Terminate; TerminateThread(IPv4TcpDnsResolver.Handle, 0);

  end;

  if TConfiguration.IsLocalIPv6BindingEnabled then begin

    IPv6UdpDnsResolver.WaitFor;

  end;

  if TConfiguration.IsLocalIPv4BindingEnabled then begin

    IPv4UdpDnsResolver.WaitFor;

  end;

  if not TConfiguration.GetAddressCacheDisabled then begin

    DnsResolverAddressCachePruner.WaitFor;

  end;

  if TConfiguration.IsLocalIPv6BindingEnabled then begin

    IPv6UdpDnsResolver.Free; IPv6TcpDnsResolver.Free;

  end;

  if TConfiguration.IsLocalIPv4BindingEnabled then begin

    IPv4UdpDnsResolver.Free; IPv4TcpDnsResolver.Free;

  end;

  if not TConfiguration.GetAddressCacheDisabled then begin

    DnsResolverAddressCachePruner.Free;

  end;

  Sleep(DNS_RESOLVER_FADE_TIME); // This is to ensure all volatile threads have terminated

  TDnsResolver_Lock.Free; TDnsResolver_Lock := nil;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsResolver.StopResolver;

begin

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.StopResolver: Stopping resolver threads...');

  TDnsResolver.StopResolverThreads;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.StopResolver: Done stopping resolver threads.');

  if THitLogger.IsEnabled then begin

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.StopResolver: Flushing hit log items...');

    try

      THitLogger.WriteAllPendingHitsToDisk(False);

    except

      on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TDnsResolver.StopResolver: The following error occurred while flushing hit log items: ' + E.Message);

    end;

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.StopResolver: Done flushing hit log items.');

  end;

  if not(TConfiguration.GetAddressCacheDisabled) and not(TConfiguration.GetAddressCacheInMemoryOnly) then begin

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.StopResolver: Saving address cache items...');

    try

      TAddressCache.SaveToFile(TConfiguration.GetAddressCacheFileName);

    except

      on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TDnsResolver.StopResolver: The following error occurred while saving address cache items: ' + E.Message);

    end;

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.StopResolver: Done saving address cache items.');

  end;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.StopResolver: Finalizing...');

  THostsCache.Finalize; TAddressCache.Finalize; TSessionCache.Finalize; TDnsOverHttpsCache.Finalize; TCommunicationChannel.Finalize;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.StopResolver: Done finalizing.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsResolver.HandleDnsRequestForIPv4Udp(ServerCommunicationChannel: TIPv4UdpCommunicationChannel; ArrivalTime: TDateTime; Buffer: Pointer; BufferLen: Integer; var Output: Pointer; var OutputLen: Integer; Address: TIPv4Address; Port: Word);

var
  OriginalSessionId: Word; RequestHash: TMD5Digest; QueryType: Word; DomainName: String; IPv4Address: TIPv4Address; IPv6Address: TIPv6Address; RemappedSessionId: Word; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Forwarded: Boolean;

begin

  if (TDnsResolver_Lock <> nil) then begin

    TDnsResolver_Lock.Acquire;

    try

      if (BufferLen >= MIN_DNS_PACKET_LEN) and (BufferLen <= MAX_DNS_PACKET_LEN) and TDnsProtocolUtility.IsValidRequestPacket(Buffer, BufferLen) then begin

        OriginalSessionId := TDnsProtocolUtility.GetIdFromPacket(Buffer);

        TDnsProtocolUtility.GetDomainNameAndQueryTypeFromRequestPacket(Buffer, BufferLen, DomainName, QueryType);

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Request ID ' + FormatCurr('00000', OriginalSessionId) + ' received from client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, True) + '].');

        if (QueryType = DNS_QUERY_TYPE_A) then begin

          if TDnsOverHttpsCache.FindIPv4Item(DomainName, IPv4Address) then begin

            TDnsProtocolUtility.BuildPositiveIPv4ResponsePacket(DomainName, QueryType, IPv4Address, TConfiguration.GetGeneratedDnsResponseTimeToLive, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using dns over https cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if TDnsOverHttpsCache.FindIPv6Item(DomainName, IPv6Address) then begin

            TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using dns over https cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindFWItem(DomainName) then begin

            // Don't do anything, let the execution flow...

          end else if THostsCache.FindNXItem(DomainName) then begin

            TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindIPv4Item(DomainName, IPv4Address) then begin

            TDnsProtocolUtility.BuildPositiveIPv4ResponsePacket(DomainName, QueryType, IPv4Address, TConfiguration.GetGeneratedDnsResponseTimeToLive, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindIPv6Item(DomainName, IPv6Address) then begin

            TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end;

        end else if (QueryType = DNS_QUERY_TYPE_AAAA) then begin

          if TDnsOverHttpsCache.FindIPv6Item(DomainName, IPv6Address) then begin

            TDnsProtocolUtility.BuildPositiveIPv6ResponsePacket(DomainName, QueryType, IPv6Address, TConfiguration.GetGeneratedDnsResponseTimeToLive, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using dns over https cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if TDnsOverHttpsCache.FindIPv4Item(DomainName, IPv4Address) then begin

            TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using dns over https cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if TConfiguration.GetSinkholeIPv6Lookups then begin

            TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from resolver [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindFWItem(DomainName) then begin

            // Don't do anything, let the execution flow...

          end else if THostsCache.FindNXItem(DomainName) then begin

            TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindIPv6Item(DomainName, IPv6Address) then begin

            TDnsProtocolUtility.BuildPositiveIPv6ResponsePacket(DomainName, QueryType, IPv6Address, TConfiguration.GetGeneratedDnsResponseTimeToLive, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindIPv4Item(DomainName, IPv4Address) then begin

            TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end;

        end else if (QueryType = DNS_QUERY_TYPE_PTR) then begin

          if not(TConfiguration.GetForwardPrivateReverseLookups) and TDnsProtocolUtility.IsPrivateReverseLookup(DomainName) then begin

            TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from resolver [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end;

        end;

        TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); RequestHash := TMD5.Compute(Buffer, BufferLen); TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer);

        if not(TConfiguration.IsDomainNameAffinityMatch(DomainName, TConfiguration.GetAddressCacheDomainNameAffinityMask)) or not(TConfiguration.IsQueryTypeAffinityMatch(QueryType, TConfiguration.GetAddressCacheQueryTypeAffinityMask)) then begin

          TSessionCache.ReserveItem(ArrivalTime, OriginalSessionId, RemappedSessionId);

          TDnsProtocolUtility.SetIdIntoPacket(RemappedSessionId, Buffer);

          Forwarded := False;

          for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin

            DnsServerConfiguration := TConfiguration.GetDnsServerConfiguration(DnsServerIndex);

            if DnsServerConfiguration.IsEnabled then begin

              if TConfiguration.IsDomainNameAffinityMatch(DomainName, DnsServerConfiguration.DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, DnsServerConfiguration.QueryTypeAffinityMask) then begin

                if TDnsForwarder.ForwardDnsRequestForIPv4Udp(ServerCommunicationChannel, ArrivalTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, RemappedSessionId) then begin

                  Forwarded := True;

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' forwarded to server ' + IntToStr(DnsServerIndex + 1) + ' (cache exception).');

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' failed to be forwarded to server ' + IntToStr(DnsServerIndex + 1) + ' (cache exception).');

                end;

              end;

            end;

          end;

          if Forwarded then begin

            TSessionCache.InsertIPv4Item(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, False, True);

            if THitLogger.IsEnabled and (Pos('F', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'F', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

          end else begin

            if (QueryType = DNS_QUERY_TYPE_PTR) then TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen) else TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from resolver [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

          end;

        end else begin

          if not(TConfiguration.GetAddressCacheDisabled) then begin

            case TAddressCache.FindItem(ArrivalTime, RequestHash, Output, OutputLen) of

              RecentEnough:

              begin

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using address cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

                if THitLogger.IsEnabled and (Pos('C', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'C', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

              end;

              NeedsUpdate:

              begin

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using address cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

                if THitLogger.IsEnabled and (Pos('C', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'C', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

                TSessionCache.ReserveItem(ArrivalTime, OriginalSessionId, RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(RemappedSessionId, Buffer);

                Forwarded := False;

                for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin

                  DnsServerConfiguration := TConfiguration.GetDnsServerConfiguration(DnsServerIndex);

                  if DnsServerConfiguration.IsEnabled then begin

                    if TConfiguration.IsDomainNameAffinityMatch(DomainName, DnsServerConfiguration.DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, DnsServerConfiguration.QueryTypeAffinityMask) then begin

                      if TDnsForwarder.ForwardDnsRequestForIPv4Udp(ServerCommunicationChannel, ArrivalTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, RemappedSessionId) then begin

                        Forwarded := True;

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' forwarded to server ' + IntToStr(DnsServerIndex + 1) + ' (silent update).');

                      end else begin

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' failed to be forwarded to server ' + IntToStr(DnsServerIndex + 1) + ' (silent update).');

                      end;

                    end;

                  end;

                end;

                if Forwarded then begin

                  TSessionCache.InsertIPv4Item(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, True, False);

                end;

              end;

              NotFound:

              begin

                TSessionCache.ReserveItem(ArrivalTime, OriginalSessionId, RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(RemappedSessionId, Buffer);

                Forwarded := False;

                for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin

                  DnsServerConfiguration := TConfiguration.GetDnsServerConfiguration(DnsServerIndex);

                  if DnsServerConfiguration.IsEnabled then begin

                    if TConfiguration.IsDomainNameAffinityMatch(DomainName, DnsServerConfiguration.DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, DnsServerConfiguration.QueryTypeAffinityMask) then begin

                      if TDnsForwarder.ForwardDnsRequestForIPv4Udp(ServerCommunicationChannel, ArrivalTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, RemappedSessionId) then begin

                        Forwarded := True;

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' forwarded to server ' + IntToStr(DnsServerIndex + 1) + '.');

                      end else begin

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' failed to be forwarded to server ' + IntToStr(DnsServerIndex + 1) + '.');

                      end;

                    end;

                  end;

                end;

                if Forwarded then begin

                  TSessionCache.InsertIPv4Item(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, False, False);

                  if THitLogger.IsEnabled and (Pos('F', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'F', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

                end else begin

                  if (QueryType = DNS_QUERY_TYPE_PTR) then TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen) else TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

                  TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from resolver [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

                  if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

                end;

              end;

            end;

          end else begin

            TSessionCache.ReserveItem(ArrivalTime, OriginalSessionId, RemappedSessionId);

            TDnsProtocolUtility.SetIdIntoPacket(RemappedSessionId, Buffer);

            Forwarded := False;

            for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin

              DnsServerConfiguration := TConfiguration.GetDnsServerConfiguration(DnsServerIndex);

              if DnsServerConfiguration.IsEnabled then begin

                if TConfiguration.IsDomainNameAffinityMatch(DomainName, DnsServerConfiguration.DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, DnsServerConfiguration.QueryTypeAffinityMask) then begin

                  if TDnsForwarder.ForwardDnsRequestForIPv4Udp(ServerCommunicationChannel, ArrivalTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, RemappedSessionId) then begin

                    Forwarded := True;

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' forwarded to server ' + IntToStr(DnsServerIndex + 1) + '.');

                  end else begin

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' failed to be forwarded to server ' + IntToStr(DnsServerIndex + 1) + '.');

                  end;

                end;

              end;

            end;

            if Forwarded then begin

              TSessionCache.InsertIPv4Item(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, False, False);

              if THitLogger.IsEnabled and (Pos('F', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'F', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            end else begin

              if (QueryType = DNS_QUERY_TYPE_PTR) then TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen) else TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

              TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

              if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from resolver [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

              if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            end;

          end;

        end;

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Udp: Malformed packet received from client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) + '].');

      end;

    finally

      TDnsResolver_Lock.Release;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsResolver.HandleDnsRequestForIPv4Tcp(ServerCommunicationChannel: TIPv4TcpCommunicationChannel; ArrivalTime: TDateTime; Buffer: Pointer; BufferLen: Integer; var Output: Pointer; var OutputLen: Integer; Address: TIPv4Address; Port: Word);

var
  OriginalSessionId: Word; RequestHash: TMD5Digest; QueryType: Word; DomainName: String; IPv4Address: TIPv4Address; IPv6Address: TIPv6Address; RemappedSessionId: Word; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Forwarded: Boolean;

begin

  if (TDnsResolver_Lock <> nil) then begin

    TDnsResolver_Lock.Acquire;

    try

      if (BufferLen >= MIN_DNS_PACKET_LEN) and (BufferLen <= MAX_DNS_PACKET_LEN) and TDnsProtocolUtility.IsValidRequestPacket(Buffer, BufferLen) then begin

        OriginalSessionId := TDnsProtocolUtility.GetIdFromPacket(Buffer);

        TDnsProtocolUtility.GetDomainNameAndQueryTypeFromRequestPacket(Buffer, BufferLen, DomainName, QueryType);

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Request ID ' + FormatCurr('00000', OriginalSessionId) + ' received from client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, True) + '].');

        if (QueryType = DNS_QUERY_TYPE_A) then begin

          if TDnsOverHttpsCache.FindIPv4Item(DomainName, IPv4Address) then begin

            TDnsProtocolUtility.BuildPositiveIPv4ResponsePacket(DomainName, QueryType, IPv4Address, TConfiguration.GetGeneratedDnsResponseTimeToLive, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using dns over https cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if TDnsOverHttpsCache.FindIPv6Item(DomainName, IPv6Address) then begin

            TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using dns over https cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindFWItem(DomainName) then begin

            // Don't do anything, let the execution flow...

          end else if THostsCache.FindNXItem(DomainName) then begin

            TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindIPv4Item(DomainName, IPv4Address) then begin

            TDnsProtocolUtility.BuildPositiveIPv4ResponsePacket(DomainName, QueryType, IPv4Address, TConfiguration.GetGeneratedDnsResponseTimeToLive, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindIPv6Item(DomainName, IPv6Address) then begin

            TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end;

        end else if (QueryType = DNS_QUERY_TYPE_AAAA) then begin

          if TDnsOverHttpsCache.FindIPv6Item(DomainName, IPv6Address) then begin

            TDnsProtocolUtility.BuildPositiveIPv6ResponsePacket(DomainName, QueryType, IPv6Address, TConfiguration.GetGeneratedDnsResponseTimeToLive, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using dns over https cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if TDnsOverHttpsCache.FindIPv4Item(DomainName, IPv4Address) then begin

            TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using dns over https cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if TConfiguration.GetSinkholeIPv6Lookups then begin

            TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from resolver [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindFWItem(DomainName) then begin

            // Don't do anything, let the execution flow...

          end else if THostsCache.FindNXItem(DomainName) then begin

            TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindIPv6Item(DomainName, IPv6Address) then begin

            TDnsProtocolUtility.BuildPositiveIPv6ResponsePacket(DomainName, QueryType, IPv6Address, TConfiguration.GetGeneratedDnsResponseTimeToLive, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindIPv4Item(DomainName, IPv4Address) then begin

            TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end;

        end else if (QueryType = DNS_QUERY_TYPE_PTR) then begin

          if not(TConfiguration.GetForwardPrivateReverseLookups) and TDnsProtocolUtility.IsPrivateReverseLookup(DomainName) then begin

            TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from resolver [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end;

        end;

        TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); RequestHash := TMD5.Compute(Buffer, BufferLen); TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer);

        if not(TConfiguration.IsDomainNameAffinityMatch(DomainName, TConfiguration.GetAddressCacheDomainNameAffinityMask)) or not(TConfiguration.IsQueryTypeAffinityMatch(QueryType, TConfiguration.GetAddressCacheQueryTypeAffinityMask)) then begin

          TSessionCache.ReserveItem(ArrivalTime, OriginalSessionId, RemappedSessionId);

          TDnsProtocolUtility.SetIdIntoPacket(RemappedSessionId, Buffer);

          Forwarded := False;

          for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin

            DnsServerConfiguration := TConfiguration.GetDnsServerConfiguration(DnsServerIndex);

            if DnsServerConfiguration.IsEnabled then begin

              if TConfiguration.IsDomainNameAffinityMatch(DomainName, DnsServerConfiguration.DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, DnsServerConfiguration.QueryTypeAffinityMask) then begin

                if TDnsForwarder.ForwardDnsRequestForIPv4Tcp(ServerCommunicationChannel, ArrivalTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, RemappedSessionId) then begin

                  Forwarded := True;

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' forwarded to server ' + IntToStr(DnsServerIndex + 1) + ' (cache exception).');

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' failed to be forwarded to server ' + IntToStr(DnsServerIndex + 1) + ' (cache exception).');

                end;

              end;

            end;

          end;

          if Forwarded then begin

            TSessionCache.InsertIPv4Item(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, False, True);

            if THitLogger.IsEnabled and (Pos('F', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'F', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

          end else begin

            if (QueryType = DNS_QUERY_TYPE_PTR) then TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen) else TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from resolver [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

          end;

        end else begin

          if not(TConfiguration.GetAddressCacheDisabled) then begin

            case TAddressCache.FindItem(ArrivalTime, RequestHash, Output, OutputLen) of

              RecentEnough:

              begin

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using address cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

                if THitLogger.IsEnabled and (Pos('C', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'C', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

              end;

              NeedsUpdate:

              begin

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using address cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

                if THitLogger.IsEnabled and (Pos('C', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'C', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

                TSessionCache.ReserveItem(ArrivalTime, OriginalSessionId, RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(RemappedSessionId, Buffer);

                Forwarded := False;

                for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin

                  DnsServerConfiguration := TConfiguration.GetDnsServerConfiguration(DnsServerIndex);

                  if DnsServerConfiguration.IsEnabled then begin

                    if TConfiguration.IsDomainNameAffinityMatch(DomainName, DnsServerConfiguration.DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, DnsServerConfiguration.QueryTypeAffinityMask) then begin

                      if TDnsForwarder.ForwardDnsRequestForIPv4Tcp(ServerCommunicationChannel, ArrivalTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, RemappedSessionId) then begin

                        Forwarded := True;

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' forwarded to server ' + IntToStr(DnsServerIndex + 1) + ' (silent update).');

                      end else begin

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' failed to be forwarded to server ' + IntToStr(DnsServerIndex + 1) + ' (silent update).');

                      end;

                    end;

                  end;

                end;

                if Forwarded then begin

                  TSessionCache.InsertIPv4Item(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, True, False);

                end;

              end;

              NotFound:

              begin

                TSessionCache.ReserveItem(ArrivalTime, OriginalSessionId, RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(RemappedSessionId, Buffer);

                Forwarded := False;

                for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin

                  DnsServerConfiguration := TConfiguration.GetDnsServerConfiguration(DnsServerIndex);

                  if DnsServerConfiguration.IsEnabled then begin

                    if TConfiguration.IsDomainNameAffinityMatch(DomainName, DnsServerConfiguration.DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, DnsServerConfiguration.QueryTypeAffinityMask) then begin

                      if TDnsForwarder.ForwardDnsRequestForIPv4Tcp(ServerCommunicationChannel, ArrivalTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, RemappedSessionId) then begin

                        Forwarded := True;

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' forwarded to server ' + IntToStr(DnsServerIndex + 1) + '.');

                      end else begin

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' failed to be forwarded to server ' + IntToStr(DnsServerIndex + 1) + '.');

                      end;

                    end;

                  end;

                end;

                if Forwarded then begin

                  TSessionCache.InsertIPv4Item(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, False, False);

                  if THitLogger.IsEnabled and (Pos('F', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'F', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

                end else begin

                  if (QueryType = DNS_QUERY_TYPE_PTR) then TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen) else TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

                  TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from resolver [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

                  if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

                end;

              end;

            end;

          end else begin

            TSessionCache.ReserveItem(ArrivalTime, OriginalSessionId, RemappedSessionId);

            TDnsProtocolUtility.SetIdIntoPacket(RemappedSessionId, Buffer);

            Forwarded := False;

            for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin

              DnsServerConfiguration := TConfiguration.GetDnsServerConfiguration(DnsServerIndex);

              if DnsServerConfiguration.IsEnabled then begin

                if TConfiguration.IsDomainNameAffinityMatch(DomainName, DnsServerConfiguration.DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, DnsServerConfiguration.QueryTypeAffinityMask) then begin

                  if TDnsForwarder.ForwardDnsRequestForIPv4Tcp(ServerCommunicationChannel, ArrivalTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, RemappedSessionId) then begin

                    Forwarded := True;

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' forwarded to server ' + IntToStr(DnsServerIndex + 1) + '.');

                  end else begin

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' failed to be forwarded to server ' + IntToStr(DnsServerIndex + 1) + '.');

                  end;

                end;

              end;

            end;

            if Forwarded then begin

              TSessionCache.InsertIPv4Item(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, False, False);

              if THitLogger.IsEnabled and (Pos('F', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'F', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            end else begin

              if (QueryType = DNS_QUERY_TYPE_PTR) then TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen) else TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

              TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

              if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from resolver [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

              if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            end;

          end;

        end;

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv4Tcp: Malformed packet received from client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) + '].');

      end;

    finally

      TDnsResolver_Lock.Release;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsResolver.HandleDnsRequestForIPv6Udp(ServerCommunicationChannel: TIPv6UdpCommunicationChannel; ArrivalTime: TDateTime; Buffer: Pointer; BufferLen: Integer; var Output: Pointer; var OutputLen: Integer; Address: TIPv6Address; Port: Word);

var
  OriginalSessionId: Word; RequestHash: TMD5Digest; QueryType: Word; DomainName: String; IPv4Address: TIPv4Address; IPv6Address: TIPv6Address; RemappedSessionId: Word; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Forwarded: Boolean;

begin

  if (TDnsResolver_Lock <> nil) then begin

    TDnsResolver_Lock.Acquire;

    try

      if (BufferLen >= MIN_DNS_PACKET_LEN) and (BufferLen <= MAX_DNS_PACKET_LEN) and TDnsProtocolUtility.IsValidRequestPacket(Buffer, BufferLen) then begin

        OriginalSessionId := TDnsProtocolUtility.GetIdFromPacket(Buffer);

        TDnsProtocolUtility.GetDomainNameAndQueryTypeFromRequestPacket(Buffer, BufferLen, DomainName, QueryType);

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Request ID ' + FormatCurr('00000', OriginalSessionId) + ' received from client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, True) + '].');

        if (QueryType = DNS_QUERY_TYPE_A) then begin

          if TDnsOverHttpsCache.FindIPv4Item(DomainName, IPv4Address) then begin

            TDnsProtocolUtility.BuildPositiveIPv4ResponsePacket(DomainName, QueryType, IPv4Address, TConfiguration.GetGeneratedDnsResponseTimeToLive, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using dns over https cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if TDnsOverHttpsCache.FindIPv6Item(DomainName, IPv6Address) then begin

            TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using dns over https cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindFWItem(DomainName) then begin

            // Don't do anything, let the execution flow...

          end else if THostsCache.FindNXItem(DomainName) then begin

            TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindIPv4Item(DomainName, IPv4Address) then begin

            TDnsProtocolUtility.BuildPositiveIPv4ResponsePacket(DomainName, QueryType, IPv4Address, TConfiguration.GetGeneratedDnsResponseTimeToLive, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindIPv6Item(DomainName, IPv6Address) then begin

            TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end;

        end else if (QueryType = DNS_QUERY_TYPE_AAAA) then begin

          if TDnsOverHttpsCache.FindIPv6Item(DomainName, IPv6Address) then begin

            TDnsProtocolUtility.BuildPositiveIPv6ResponsePacket(DomainName, QueryType, IPv6Address, TConfiguration.GetGeneratedDnsResponseTimeToLive, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using dns over https cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if TDnsOverHttpsCache.FindIPv4Item(DomainName, IPv4Address) then begin

            TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using dns over https cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if TConfiguration.GetSinkholeIPv6Lookups then begin

            TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from resolver [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindFWItem(DomainName) then begin

            // Don't do anything, let the execution flow...

          end else if THostsCache.FindNXItem(DomainName) then begin

            TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindIPv6Item(DomainName, IPv6Address) then begin

            TDnsProtocolUtility.BuildPositiveIPv6ResponsePacket(DomainName, QueryType, IPv6Address, TConfiguration.GetGeneratedDnsResponseTimeToLive, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindIPv4Item(DomainName, IPv4Address) then begin

            TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end;

        end else if (QueryType = DNS_QUERY_TYPE_PTR) then begin

          if not(TConfiguration.GetForwardPrivateReverseLookups) and TDnsProtocolUtility.IsPrivateReverseLookup(DomainName) then begin

            TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from resolver [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end;

        end;

        TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); RequestHash := TMD5.Compute(Buffer, BufferLen); TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer);

        if not(TConfiguration.IsDomainNameAffinityMatch(DomainName, TConfiguration.GetAddressCacheDomainNameAffinityMask)) or not(TConfiguration.IsQueryTypeAffinityMatch(QueryType, TConfiguration.GetAddressCacheQueryTypeAffinityMask)) then begin

          TSessionCache.ReserveItem(ArrivalTime, OriginalSessionId, RemappedSessionId);

          TDnsProtocolUtility.SetIdIntoPacket(RemappedSessionId, Buffer);

          Forwarded := False;

          for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin

            DnsServerConfiguration := TConfiguration.GetDnsServerConfiguration(DnsServerIndex);

            if DnsServerConfiguration.IsEnabled then begin

              if TConfiguration.IsDomainNameAffinityMatch(DomainName, DnsServerConfiguration.DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, DnsServerConfiguration.QueryTypeAffinityMask) then begin

                if TDnsForwarder.ForwardDnsRequestForIPv6Udp(ServerCommunicationChannel, ArrivalTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, RemappedSessionId) then begin

                  Forwarded := True;

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' forwarded to server ' + IntToStr(DnsServerIndex + 1) + ' (cache exception).');

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' failed to be forwarded to server ' + IntToStr(DnsServerIndex + 1) + ' (cache exception).');

                end;

              end;

            end;

          end;

          if Forwarded then begin

            TSessionCache.InsertIPv6Item(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, False, True);

            if THitLogger.IsEnabled and (Pos('F', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'F', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

          end else begin

            if (QueryType = DNS_QUERY_TYPE_PTR) then TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen) else TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from resolver [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

          end;

        end else begin

          if not(TConfiguration.GetAddressCacheDisabled) then begin

            case TAddressCache.FindItem(ArrivalTime, RequestHash, Output, OutputLen) of

              RecentEnough:

              begin

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using address cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

                if THitLogger.IsEnabled and (Pos('C', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'C', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

              end;

              NeedsUpdate:

              begin

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using address cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

                if THitLogger.IsEnabled and (Pos('C', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'C', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

                TSessionCache.ReserveItem(ArrivalTime, OriginalSessionId, RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(RemappedSessionId, Buffer);

                Forwarded := False;

                for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin

                  DnsServerConfiguration := TConfiguration.GetDnsServerConfiguration(DnsServerIndex);

                  if DnsServerConfiguration.IsEnabled then begin

                    if TConfiguration.IsDomainNameAffinityMatch(DomainName, DnsServerConfiguration.DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, DnsServerConfiguration.QueryTypeAffinityMask) then begin

                      if TDnsForwarder.ForwardDnsRequestForIPv6Udp(ServerCommunicationChannel, ArrivalTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, RemappedSessionId) then begin

                        Forwarded := True;

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' forwarded to server ' + IntToStr(DnsServerIndex + 1) + ' (silent update).');

                      end else begin

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' failed to be forwarded to server ' + IntToStr(DnsServerIndex + 1) + ' (silent update).');

                      end;

                    end;

                  end;

                end;

                if Forwarded then begin

                  TSessionCache.InsertIPv6Item(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, True, False);

                end;

              end;

              NotFound:

              begin

                TSessionCache.ReserveItem(ArrivalTime, OriginalSessionId, RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(RemappedSessionId, Buffer);

                Forwarded := False;

                for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin

                  DnsServerConfiguration := TConfiguration.GetDnsServerConfiguration(DnsServerIndex);

                  if DnsServerConfiguration.IsEnabled then begin

                    if TConfiguration.IsDomainNameAffinityMatch(DomainName, DnsServerConfiguration.DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, DnsServerConfiguration.QueryTypeAffinityMask) then begin

                      if TDnsForwarder.ForwardDnsRequestForIPv6Udp(ServerCommunicationChannel, ArrivalTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, RemappedSessionId) then begin

                        Forwarded := True;

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' forwarded to server ' + IntToStr(DnsServerIndex + 1) + '.');

                      end else begin

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' failed to be forwarded to server ' + IntToStr(DnsServerIndex + 1) + '.');

                      end;

                    end;

                  end;

                end;

                if Forwarded then begin

                  TSessionCache.InsertIPv6Item(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, False, False);

                  if THitLogger.IsEnabled and (Pos('F', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'F', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

                end else begin

                  if (QueryType = DNS_QUERY_TYPE_PTR) then TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen) else TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

                  TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from resolver [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

                  if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

                end;

              end;

            end;

          end else begin

            TSessionCache.ReserveItem(ArrivalTime, OriginalSessionId, RemappedSessionId);

            TDnsProtocolUtility.SetIdIntoPacket(RemappedSessionId, Buffer);

            Forwarded := False;

            for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin

              DnsServerConfiguration := TConfiguration.GetDnsServerConfiguration(DnsServerIndex);

              if DnsServerConfiguration.IsEnabled then begin

                if TConfiguration.IsDomainNameAffinityMatch(DomainName, DnsServerConfiguration.DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, DnsServerConfiguration.QueryTypeAffinityMask) then begin

                  if TDnsForwarder.ForwardDnsRequestForIPv6Udp(ServerCommunicationChannel, ArrivalTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, RemappedSessionId) then begin

                    Forwarded := True;

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' forwarded to server ' + IntToStr(DnsServerIndex + 1) + '.');

                  end else begin

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' failed to be forwarded to server ' + IntToStr(DnsServerIndex + 1) + '.');

                  end;

                end;

              end;

            end;

            if Forwarded then begin

              TSessionCache.InsertIPv6Item(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, False, False);

              if THitLogger.IsEnabled and (Pos('F', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'F', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            end else begin

              if (QueryType = DNS_QUERY_TYPE_PTR) then TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen) else TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

              TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen, Address, Port);

              if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from resolver [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

              if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            end;

          end;

        end;

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Udp: Malformed packet received from client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) + '].');

      end;

    finally

      TDnsResolver_Lock.Release;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsResolver.HandleDnsRequestForIPv6Tcp(ServerCommunicationChannel: TIPv6TcpCommunicationChannel; ArrivalTime: TDateTime; Buffer: Pointer; BufferLen: Integer; var Output: Pointer; var OutputLen: Integer; Address: TIPv6Address; Port: Word);

var
  OriginalSessionId: Word; RequestHash: TMD5Digest; QueryType: Word; DomainName: String; IPv4Address: TIPv4Address; IPv6Address: TIPv6Address; RemappedSessionId: Word; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Forwarded: Boolean;

begin

  if (TDnsResolver_Lock <> nil) then begin

    TDnsResolver_Lock.Acquire;

    try

      if (BufferLen >= MIN_DNS_PACKET_LEN) and (BufferLen <= MAX_DNS_PACKET_LEN) and TDnsProtocolUtility.IsValidRequestPacket(Buffer, BufferLen) then begin

        OriginalSessionId := TDnsProtocolUtility.GetIdFromPacket(Buffer);

        TDnsProtocolUtility.GetDomainNameAndQueryTypeFromRequestPacket(Buffer, BufferLen, DomainName, QueryType);

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Request ID ' + FormatCurr('00000', OriginalSessionId) + ' received from client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, True) + '].');

        if (QueryType = DNS_QUERY_TYPE_A) then begin

          if TDnsOverHttpsCache.FindIPv4Item(DomainName, IPv4Address) then begin

            TDnsProtocolUtility.BuildPositiveIPv4ResponsePacket(DomainName, QueryType, IPv4Address, TConfiguration.GetGeneratedDnsResponseTimeToLive, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using dns over https cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if TDnsOverHttpsCache.FindIPv6Item(DomainName, IPv6Address) then begin

            TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using dns over https cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindFWItem(DomainName) then begin

            // Don't do anything, let the execution flow...

          end else if THostsCache.FindNXItem(DomainName) then begin

            TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindIPv4Item(DomainName, IPv4Address) then begin

            TDnsProtocolUtility.BuildPositiveIPv4ResponsePacket(DomainName, QueryType, IPv4Address, TConfiguration.GetGeneratedDnsResponseTimeToLive, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindIPv6Item(DomainName, IPv6Address) then begin

            TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end;

        end else if (QueryType = DNS_QUERY_TYPE_AAAA) then begin

          if TDnsOverHttpsCache.FindIPv6Item(DomainName, IPv6Address) then begin

            TDnsProtocolUtility.BuildPositiveIPv6ResponsePacket(DomainName, QueryType, IPv6Address, TConfiguration.GetGeneratedDnsResponseTimeToLive, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using dns over https cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if TDnsOverHttpsCache.FindIPv4Item(DomainName, IPv4Address) then begin

            TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using dns over https cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if TConfiguration.GetSinkholeIPv6Lookups then begin

            TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from resolver [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindFWItem(DomainName) then begin

            // Don't do anything, let the execution flow...

          end else if THostsCache.FindNXItem(DomainName) then begin

            TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindIPv6Item(DomainName, IPv6Address) then begin

            TDnsProtocolUtility.BuildPositiveIPv6ResponsePacket(DomainName, QueryType, IPv6Address, TConfiguration.GetGeneratedDnsResponseTimeToLive, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end else if THostsCache.FindIPv4Item(DomainName, IPv4Address) then begin

            TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using hosts cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('H', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'H', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end;

        end else if (QueryType = DNS_QUERY_TYPE_PTR) then begin

          if not(TConfiguration.GetForwardPrivateReverseLookups) and TDnsProtocolUtility.IsPrivateReverseLookup(DomainName) then begin

            TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from resolver [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            Exit;

          end;

        end;

        TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); RequestHash := TMD5.Compute(Buffer, BufferLen); TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer);

        if not(TConfiguration.IsDomainNameAffinityMatch(DomainName, TConfiguration.GetAddressCacheDomainNameAffinityMask)) or not(TConfiguration.IsQueryTypeAffinityMatch(QueryType, TConfiguration.GetAddressCacheQueryTypeAffinityMask)) then begin

          TSessionCache.ReserveItem(ArrivalTime, OriginalSessionId, RemappedSessionId);

          TDnsProtocolUtility.SetIdIntoPacket(RemappedSessionId, Buffer);

          Forwarded := False;

          for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin

            DnsServerConfiguration := TConfiguration.GetDnsServerConfiguration(DnsServerIndex);

            if DnsServerConfiguration.IsEnabled then begin

              if TConfiguration.IsDomainNameAffinityMatch(DomainName, DnsServerConfiguration.DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, DnsServerConfiguration.QueryTypeAffinityMask) then begin

                if TDnsForwarder.ForwardDnsRequestForIPv6Tcp(ServerCommunicationChannel, ArrivalTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, RemappedSessionId) then begin

                  Forwarded := True;

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' forwarded to server ' + IntToStr(DnsServerIndex + 1) + ' (cache exception).');

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' failed to be forwarded to server ' + IntToStr(DnsServerIndex + 1) + ' (cache exception).');

                end;

              end;

            end;

          end;

          if Forwarded then begin

            TSessionCache.InsertIPv6Item(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, False, True);

            if THitLogger.IsEnabled and (Pos('F', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'F', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

          end else begin

            if (QueryType = DNS_QUERY_TYPE_PTR) then TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen) else TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from resolver [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

            if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

          end;

        end else begin

          if not(TConfiguration.GetAddressCacheDisabled) then begin

            case TAddressCache.FindItem(ArrivalTime, RequestHash, Output, OutputLen) of

              RecentEnough:

              begin

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using address cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

                if THitLogger.IsEnabled and (Pos('C', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'C', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

              end;

              NeedsUpdate:

              begin

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' using address cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

                if THitLogger.IsEnabled and (Pos('C', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'C', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

                TSessionCache.ReserveItem(ArrivalTime, OriginalSessionId, RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(RemappedSessionId, Buffer);

                Forwarded := False;

                for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin

                  DnsServerConfiguration := TConfiguration.GetDnsServerConfiguration(DnsServerIndex);

                  if DnsServerConfiguration.IsEnabled then begin

                    if TConfiguration.IsDomainNameAffinityMatch(DomainName, DnsServerConfiguration.DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, DnsServerConfiguration.QueryTypeAffinityMask) then begin

                      if TDnsForwarder.ForwardDnsRequestForIPv6Tcp(ServerCommunicationChannel, ArrivalTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, RemappedSessionId) then begin

                        Forwarded := True;

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' forwarded to server ' + IntToStr(DnsServerIndex + 1) + ' (silent update).');

                      end else begin

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' failed to be forwarded to server ' + IntToStr(DnsServerIndex + 1) + ' (silent update).');

                      end;

                    end;

                  end;

                end;

                if Forwarded then begin

                  TSessionCache.InsertIPv6Item(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, True, False);

                end;

              end;

              NotFound:

              begin

                TSessionCache.ReserveItem(ArrivalTime, OriginalSessionId, RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(RemappedSessionId, Buffer);

                Forwarded := False;

                for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin

                  DnsServerConfiguration := TConfiguration.GetDnsServerConfiguration(DnsServerIndex);

                  if DnsServerConfiguration.IsEnabled then begin

                    if TConfiguration.IsDomainNameAffinityMatch(DomainName, DnsServerConfiguration.DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, DnsServerConfiguration.QueryTypeAffinityMask) then begin

                      if TDnsForwarder.ForwardDnsRequestForIPv6Tcp(ServerCommunicationChannel, ArrivalTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, RemappedSessionId) then begin

                        Forwarded := True;

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' forwarded to server ' + IntToStr(DnsServerIndex + 1) + '.');

                      end else begin

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' failed to be forwarded to server ' + IntToStr(DnsServerIndex + 1) + '.');

                      end;

                    end;

                  end;

                end;

                if Forwarded then begin

                  TSessionCache.InsertIPv6Item(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, False, False);

                  if THitLogger.IsEnabled and (Pos('F', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'F', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

                end else begin

                  if (QueryType = DNS_QUERY_TYPE_PTR) then TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen) else TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

                  TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from resolver [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

                  if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

                end;

              end;

            end;

          end else begin

            TSessionCache.ReserveItem(ArrivalTime, OriginalSessionId, RemappedSessionId);

            TDnsProtocolUtility.SetIdIntoPacket(RemappedSessionId, Buffer);

            Forwarded := False;

            for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin

              DnsServerConfiguration := TConfiguration.GetDnsServerConfiguration(DnsServerIndex);

              if DnsServerConfiguration.IsEnabled then begin

                if TConfiguration.IsDomainNameAffinityMatch(DomainName, DnsServerConfiguration.DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, DnsServerConfiguration.QueryTypeAffinityMask) then begin

                  if TDnsForwarder.ForwardDnsRequestForIPv6Tcp(ServerCommunicationChannel, ArrivalTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, RemappedSessionId) then begin

                    Forwarded := True;

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' forwarded to server ' + IntToStr(DnsServerIndex + 1) + '.');

                  end else begin

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' failed to be forwarded to server ' + IntToStr(DnsServerIndex + 1) + '.');

                  end;

                end;

              end;

            end;

            if Forwarded then begin

              TSessionCache.InsertIPv6Item(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, False, False);

              if THitLogger.IsEnabled and (Pos('F', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'F', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            end else begin

              if (QueryType = DNS_QUERY_TYPE_PTR) then TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen) else TDnsProtocolUtility.BuildPositiveNullResponsePacket(DomainName, QueryType, Output, OutputLen);

              TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); ServerCommunicationChannel.Send(Output, OutputLen);

              if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from resolver [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Output, OutputLen, True) + '].');

              if THitLogger.IsEnabled and (Pos('X', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'X', '', '', TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(DomainName, QueryType, Buffer, BufferLen, THitLogger.GetFullDump));

            end;

          end;

        end;

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsRequestForIPv6Tcp: Malformed packet received from client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) + '].');

      end;

    finally

      TDnsResolver_Lock.Release;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsResolver.HandleDnsResponseForIPv4Udp(ServerCommunicationChannel: TIPv4UdpCommunicationChannel; ArrivalTime: TDateTime; Buffer: Pointer; BufferLen: Integer; DnsServerIndex: Integer; DnsServerResponseTime: Double; DnsServerConfiguration: TDnsServerConfiguration);

var
  RemappedSessionId: Word; OriginalSessionId: Word; Address: TIPv4Address; Port: Word; RequestHash: TMD5Digest; IsSilentUpdate: Boolean; IsCacheException: Boolean;

begin

  if (TDnsResolver_Lock <> nil) then begin

    TDnsResolver_Lock.Acquire;

    try

      if (BufferLen >= MIN_DNS_PACKET_LEN) and (BufferLen <= MAX_DNS_PACKET_LEN) and TDnsProtocolUtility.IsValidResponsePacket(Buffer, BufferLen) then begin

        RemappedSessionId := TDnsProtocolUtility.GetIdFromPacket(Buffer);

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' in ' + FormatFloat('0.0', 1000 * DnsServerResponseTime) + ' msecs [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, True) + '].');

        if TSessionCache.ExtractIPv4Item(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, IsSilentUpdate, IsCacheException) then begin

          if IsCacheException then begin

            if not(TDnsProtocolUtility.IsFailureResponsePacket(Buffer, BufferLen)) then begin

              if not(TDnsProtocolUtility.IsNegativeResponsePacket(Buffer, BufferLen)) then begin

                TSessionCache.DeleteItem(RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen, Address, Port);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

              end else begin

                if not(DnsServerConfiguration.IgnoreNegativeResponsesFromServer) then begin

                  TSessionCache.DeleteItem(RemappedSessionId);

                  TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen, Address, Port);

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                  if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded.');

                end;

              end;

            end else begin

              if not(DnsServerConfiguration.IgnoreFailureResponsesFromServer) then begin

                TSessionCache.DeleteItem(RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen, Address, Port);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

              end else begin

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded.');

              end;

            end;

          end else if IsSilentUpdate then begin

            if not(TDnsProtocolUtility.IsFailureResponsePacket(Buffer, BufferLen)) then begin

              if not(TDnsProtocolUtility.IsNegativeResponsePacket(Buffer, BufferLen)) then begin

                TSessionCache.DeleteItem(RemappedSessionId);

                if not(TDnsProtocolUtility.IsTruncatedResponsePacket(Buffer, BufferLen)) then begin

                  if not(TConfiguration.GetAddressCacheDisabled) and (TConfiguration.GetAddressCacheScavengingTime > 0) then begin

                    TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.AddItem(ArrivalTime, RequestHash, Buffer, BufferLen, AddressCacheItemOptionsResponseTypeIsPositive);

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' put into the address cache (silent update).');

                  end;

                  if THitLogger.IsEnabled and (Pos('U', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'U', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded (silent update).');

                end;

              end else begin

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded (silent update).');

              end;

            end else begin

              if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded (silent update).');

            end;

          end else begin

            if not(TDnsProtocolUtility.IsFailureResponsePacket(Buffer, BufferLen)) then begin

              if not(TDnsProtocolUtility.IsNegativeResponsePacket(Buffer, BufferLen)) then begin

                TSessionCache.DeleteItem(RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen, Address, Port);

                if not(TDnsProtocolUtility.IsTruncatedResponsePacket(Buffer, BufferLen)) then begin

                  if not(TConfiguration.GetAddressCacheDisabled) and (TConfiguration.GetAddressCacheScavengingTime > 0) then begin

                    TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.AddItem(ArrivalTime, RequestHash, Buffer, BufferLen, AddressCacheItemOptionsResponseTypeIsPositive);

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' and put into the address cache.');

                  end else begin

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                  end;

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                end;

                if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

              end else begin

                if not(DnsServerConfiguration.IgnoreNegativeResponsesFromServer) then begin

                  TSessionCache.DeleteItem(RemappedSessionId);

                  TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen, Address, Port);

                  if not(TDnsProtocolUtility.IsTruncatedResponsePacket(Buffer, BufferLen)) then begin

                    if not(TConfiguration.GetAddressCacheDisabled) and (TConfiguration.GetAddressCacheNegativeTime > 0) then begin

                      TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.AddItem(ArrivalTime, RequestHash, Buffer, BufferLen, AddressCacheItemOptionsResponseTypeIsNegative);

                      if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' and put into the address cache.');

                    end else begin

                      if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                    end;

                  end else begin

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                  end;

                  if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded.');

                end;

              end;

            end else begin

              if not(DnsServerConfiguration.IgnoreFailureResponsesFromServer) then begin

                TSessionCache.DeleteItem(RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen, Address, Port);

                if not(TDnsProtocolUtility.IsTruncatedResponsePacket(Buffer, BufferLen)) then begin

                  if not(TConfiguration.GetAddressCacheDisabled) and (TConfiguration.GetAddressCacheFailureTime > 0) then begin

                    TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.AddItem(ArrivalTime, RequestHash, Buffer, BufferLen, AddressCacheItemOptionsResponseTypeIsFailure);

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' and put into the address cache.');

                  end else begin

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                  end;

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                end;

                if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

              end else begin

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded.');

              end;

            end;

          end;

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded.');

        end;

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Udp: Malformed packet received from server ' + IntToStr(DnsServerIndex + 1) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) + '].');

      end;

    finally

      TDnsResolver_Lock.Release;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsResolver.HandleDnsResponseForIPv4Tcp(ServerCommunicationChannel: TIPv4TcpCommunicationChannel; ArrivalTime: TDateTime; Buffer: Pointer; BufferLen: Integer; DnsServerIndex: Integer; DnsServerResponseTime: Double; DnsServerConfiguration: TDnsServerConfiguration);

var
  RemappedSessionId: Word; OriginalSessionId: Word; Address: TIPv4Address; Port: Word; RequestHash: TMD5Digest; IsSilentUpdate: Boolean; IsCacheException: Boolean;

begin

  if (TDnsResolver_Lock <> nil) then begin

    TDnsResolver_Lock.Acquire;

    try

      if (BufferLen >= MIN_DNS_PACKET_LEN) and (BufferLen <= MAX_DNS_PACKET_LEN) and TDnsProtocolUtility.IsValidResponsePacket(Buffer, BufferLen) then begin

        RemappedSessionId := TDnsProtocolUtility.GetIdFromPacket(Buffer);

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' in ' + FormatFloat('0.0', 1000 * DnsServerResponseTime) + ' msecs [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, True) + '].');

        if TSessionCache.ExtractIPv4Item(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, IsSilentUpdate, IsCacheException) then begin

          if IsCacheException then begin

            if not(TDnsProtocolUtility.IsFailureResponsePacket(Buffer, BufferLen)) then begin

              if not(TDnsProtocolUtility.IsNegativeResponsePacket(Buffer, BufferLen)) then begin

                TSessionCache.DeleteItem(RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

              end else begin

                if not(DnsServerConfiguration.IgnoreNegativeResponsesFromServer) then begin

                  TSessionCache.DeleteItem(RemappedSessionId);

                  TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen);

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                  if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded.');

                end;

              end;

            end else begin

              if not(DnsServerConfiguration.IgnoreFailureResponsesFromServer) then begin

                TSessionCache.DeleteItem(RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

              end else begin

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded.');

              end;

            end;

          end else if IsSilentUpdate then begin

            if not(TDnsProtocolUtility.IsFailureResponsePacket(Buffer, BufferLen)) then begin

              if not(TDnsProtocolUtility.IsNegativeResponsePacket(Buffer, BufferLen)) then begin

                TSessionCache.DeleteItem(RemappedSessionId);

                if not(TConfiguration.GetAddressCacheDisabled) and (TConfiguration.GetAddressCacheScavengingTime > 0) then begin

                  TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.AddItem(ArrivalTime, RequestHash, Buffer, BufferLen, AddressCacheItemOptionsResponseTypeIsPositive);

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' put into the address cache (silent update).');

                end;

                if THitLogger.IsEnabled and (Pos('U', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'U', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

              end else begin

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded (silent update).');

              end;

            end else begin

              if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded (silent update).');

            end;

          end else begin

            if not(TDnsProtocolUtility.IsFailureResponsePacket(Buffer, BufferLen)) then begin

              if not(TDnsProtocolUtility.IsNegativeResponsePacket(Buffer, BufferLen)) then begin

                TSessionCache.DeleteItem(RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen);

                if not(TConfiguration.GetAddressCacheDisabled) and (TConfiguration.GetAddressCacheScavengingTime > 0) then begin

                  TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.AddItem(ArrivalTime, RequestHash, Buffer, BufferLen, AddressCacheItemOptionsResponseTypeIsPositive);

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' and put into the address cache.');

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                end;

                if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

              end else begin

                if not(DnsServerConfiguration.IgnoreNegativeResponsesFromServer) then begin

                  TSessionCache.DeleteItem(RemappedSessionId);

                  TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen);

                  if not(TConfiguration.GetAddressCacheDisabled) and (TConfiguration.GetAddressCacheNegativeTime > 0) then begin

                    TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.AddItem(ArrivalTime, RequestHash, Buffer, BufferLen, AddressCacheItemOptionsResponseTypeIsNegative);

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' and put into the address cache.');

                  end else begin

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                  end;

                  if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded.');

                end;

              end;

            end else begin

              if not(DnsServerConfiguration.IgnoreFailureResponsesFromServer) then begin

                TSessionCache.DeleteItem(RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen);

                if not(TConfiguration.GetAddressCacheDisabled) and (TConfiguration.GetAddressCacheFailureTime > 0) then begin

                  TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.AddItem(ArrivalTime, RequestHash, Buffer, BufferLen, AddressCacheItemOptionsResponseTypeIsFailure);

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' and put into the address cache.');

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                end;

                if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv4Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

              end else begin

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded.');

              end;

            end;

          end;

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded.');

        end;

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv4Tcp: Malformed packet received from server ' + IntToStr(DnsServerIndex + 1) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) + '].');

      end;

    finally

      TDnsResolver_Lock.Release;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsResolver.HandleDnsResponseForIPv6Udp(ServerCommunicationChannel: TIPv6UdpCommunicationChannel; ArrivalTime: TDateTime; Buffer: Pointer; BufferLen: Integer; DnsServerIndex: Integer; DnsServerResponseTime: Double; DnsServerConfiguration: TDnsServerConfiguration);

var
  RemappedSessionId: Word; OriginalSessionId: Word; Address: TIPv6Address; Port: Word; RequestHash: TMD5Digest; IsSilentUpdate: Boolean; IsCacheException: Boolean;

begin

  if (TDnsResolver_Lock <> nil) then begin

    TDnsResolver_Lock.Acquire;

    try

      if (BufferLen >= MIN_DNS_PACKET_LEN) and (BufferLen <= MAX_DNS_PACKET_LEN) and TDnsProtocolUtility.IsValidResponsePacket(Buffer, BufferLen) then begin

        RemappedSessionId := TDnsProtocolUtility.GetIdFromPacket(Buffer);

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' in ' + FormatFloat('0.0', 1000 * DnsServerResponseTime) + ' msecs [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, True) + '].');

        if TSessionCache.ExtractIPv6Item(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, IsSilentUpdate, IsCacheException) then begin

          if IsCacheException then begin

            if not(TDnsProtocolUtility.IsFailureResponsePacket(Buffer, BufferLen)) then begin

              if not(TDnsProtocolUtility.IsNegativeResponsePacket(Buffer, BufferLen)) then begin

                TSessionCache.DeleteItem(RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen, Address, Port);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

              end else begin

                if not(DnsServerConfiguration.IgnoreNegativeResponsesFromServer) then begin

                  TSessionCache.DeleteItem(RemappedSessionId);

                  TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen, Address, Port);

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                  if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded.');

                end;

              end;

            end else begin

              if not(DnsServerConfiguration.IgnoreFailureResponsesFromServer) then begin

                TSessionCache.DeleteItem(RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen, Address, Port);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

              end else begin

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded.');

              end;

            end;

          end else if IsSilentUpdate then begin

            if not(TDnsProtocolUtility.IsFailureResponsePacket(Buffer, BufferLen)) then begin

              if not(TDnsProtocolUtility.IsNegativeResponsePacket(Buffer, BufferLen)) then begin

                TSessionCache.DeleteItem(RemappedSessionId);

                if not(TDnsProtocolUtility.IsTruncatedResponsePacket(Buffer, BufferLen)) then begin

                  if not(TConfiguration.GetAddressCacheDisabled) and (TConfiguration.GetAddressCacheScavengingTime > 0) then begin

                    TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.AddItem(ArrivalTime, RequestHash, Buffer, BufferLen, AddressCacheItemOptionsResponseTypeIsPositive);

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' put into the address cache (silent update).');

                  end;

                  if THitLogger.IsEnabled and (Pos('U', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'U', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded (silent update).');

                end;

              end else begin

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded (silent update).');

              end;

            end else begin

              if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded (silent update).');

            end;

          end else begin

            if not(TDnsProtocolUtility.IsFailureResponsePacket(Buffer, BufferLen)) then begin

              if not(TDnsProtocolUtility.IsNegativeResponsePacket(Buffer, BufferLen)) then begin

                TSessionCache.DeleteItem(RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen, Address, Port);

                if not(TDnsProtocolUtility.IsTruncatedResponsePacket(Buffer, BufferLen)) then begin

                  if not(TConfiguration.GetAddressCacheDisabled) and (TConfiguration.GetAddressCacheScavengingTime > 0) then begin

                    TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.AddItem(ArrivalTime, RequestHash, Buffer, BufferLen, AddressCacheItemOptionsResponseTypeIsPositive);

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' and put into the address cache.');

                  end else begin

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                  end;

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                end;

                if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

              end else begin

                if not(DnsServerConfiguration.IgnoreNegativeResponsesFromServer) then begin

                  TSessionCache.DeleteItem(RemappedSessionId);

                  TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen, Address, Port);

                  if not(TDnsProtocolUtility.IsTruncatedResponsePacket(Buffer, BufferLen)) then begin

                    if not(TConfiguration.GetAddressCacheDisabled) and (TConfiguration.GetAddressCacheNegativeTime > 0) then begin

                      TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.AddItem(ArrivalTime, RequestHash, Buffer, BufferLen, AddressCacheItemOptionsResponseTypeIsNegative);

                      if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' and put into the address cache.');

                    end else begin

                      if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                    end;

                  end else begin

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                  end;

                  if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded.');

                end;

              end;

            end else begin

              if not(DnsServerConfiguration.IgnoreFailureResponsesFromServer) then begin

                TSessionCache.DeleteItem(RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen, Address, Port);

                if not(TDnsProtocolUtility.IsTruncatedResponsePacket(Buffer, BufferLen)) then begin

                  if not(TConfiguration.GetAddressCacheDisabled) and (TConfiguration.GetAddressCacheFailureTime > 0) then begin

                    TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.AddItem(ArrivalTime, RequestHash, Buffer, BufferLen, AddressCacheItemOptionsResponseTypeIsFailure);

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' and put into the address cache.');

                  end else begin

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                  end;

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                end;

                if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

              end else begin

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded.');

              end;

            end;

          end;

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Response ID ' + FormatCurr('00000', RemappedSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded.');

        end;

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Udp: Malformed packet received from server ' + IntToStr(DnsServerIndex + 1) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) + '].');

      end;

    finally

      TDnsResolver_Lock.Release;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsResolver.HandleDnsResponseForIPv6Tcp(ServerCommunicationChannel: TIPv6TcpCommunicationChannel; ArrivalTime: TDateTime; Buffer: Pointer; BufferLen: Integer; DnsServerIndex: Integer; DnsServerResponseTime: Double; DnsServerConfiguration: TDnsServerConfiguration);

var
  RemappedSessionId: Word; OriginalSessionId: Word; Address: TIPv6Address; Port: Word; RequestHash: TMD5Digest; IsSilentUpdate: Boolean; IsCacheException: Boolean;

begin

  if (TDnsResolver_Lock <> nil) then begin

    TDnsResolver_Lock.Acquire;

    try

      if (BufferLen >= MIN_DNS_PACKET_LEN) and (BufferLen <= MAX_DNS_PACKET_LEN) and TDnsProtocolUtility.IsValidResponsePacket(Buffer, BufferLen) then begin

        RemappedSessionId := TDnsProtocolUtility.GetIdFromPacket(Buffer);

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' in ' + FormatFloat('0.0', 1000 * DnsServerResponseTime) + ' msecs [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, True) + '].');

        if TSessionCache.ExtractIPv6Item(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, IsSilentUpdate, IsCacheException) then begin

          if IsCacheException then begin

            if not(TDnsProtocolUtility.IsFailureResponsePacket(Buffer, BufferLen)) then begin

              if not(TDnsProtocolUtility.IsNegativeResponsePacket(Buffer, BufferLen)) then begin

                TSessionCache.DeleteItem(RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

              end else begin

                if not(DnsServerConfiguration.IgnoreNegativeResponsesFromServer) then begin

                  TSessionCache.DeleteItem(RemappedSessionId);

                  TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen);

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                  if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded.');

                end;

              end;

            end else begin

              if not(DnsServerConfiguration.IgnoreFailureResponsesFromServer) then begin

                TSessionCache.DeleteItem(RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

              end else begin

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded.');

              end;

            end;

          end else if IsSilentUpdate then begin

            if not(TDnsProtocolUtility.IsFailureResponsePacket(Buffer, BufferLen)) then begin

              if not(TDnsProtocolUtility.IsNegativeResponsePacket(Buffer, BufferLen)) then begin

                TSessionCache.DeleteItem(RemappedSessionId);

                if not(TConfiguration.GetAddressCacheDisabled) and (TConfiguration.GetAddressCacheScavengingTime > 0) then begin

                  TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.AddItem(ArrivalTime, RequestHash, Buffer, BufferLen, AddressCacheItemOptionsResponseTypeIsPositive);

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' put into the address cache (silent update).');

                end;

                if THitLogger.IsEnabled and (Pos('U', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'U', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

              end else begin

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded (silent update).');

              end;

            end else begin

              if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded (silent update).');

            end;

          end else begin

            if not(TDnsProtocolUtility.IsFailureResponsePacket(Buffer, BufferLen)) then begin

              if not(TDnsProtocolUtility.IsNegativeResponsePacket(Buffer, BufferLen)) then begin

                TSessionCache.DeleteItem(RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen);

                if not(TConfiguration.GetAddressCacheDisabled) and (TConfiguration.GetAddressCacheScavengingTime > 0) then begin

                  TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.AddItem(ArrivalTime, RequestHash, Buffer, BufferLen, AddressCacheItemOptionsResponseTypeIsPositive);

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' and put into the address cache.');

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                end;

                if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

              end else begin

                if not(DnsServerConfiguration.IgnoreNegativeResponsesFromServer) then begin

                  TSessionCache.DeleteItem(RemappedSessionId);

                  TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen);

                  if not(TConfiguration.GetAddressCacheDisabled) and (TConfiguration.GetAddressCacheNegativeTime > 0) then begin

                    TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.AddItem(ArrivalTime, RequestHash, Buffer, BufferLen, AddressCacheItemOptionsResponseTypeIsNegative);

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' and put into the address cache.');

                  end else begin

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                  end;

                  if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded.');

                end;

              end;

            end else begin

              if not(DnsServerConfiguration.IgnoreFailureResponsesFromServer) then begin

                TSessionCache.DeleteItem(RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); ServerCommunicationChannel.Send(Buffer, BufferLen);

                if not(TConfiguration.GetAddressCacheDisabled) and (TConfiguration.GetAddressCacheFailureTime > 0) then begin

                  TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.AddItem(ArrivalTime, RequestHash, Buffer, BufferLen, AddressCacheItemOptionsResponseTypeIsFailure);

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' and put into the address cache.');

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' sent to client ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + '.');

                end;

                if THitLogger.IsEnabled and (Pos('R', THitLogger.GetFileWhat) > 0) then THitLogger.AddIPv6Hit(ArrivalTime, Address, 'R', IntToStr(DnsServerIndex + 1), FormatFloat('0.0', 1000 * DnsServerResponseTime), TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer, BufferLen, THitLogger.GetFullDump));

              end else begin

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded.');

              end;

            end;

          end;

        end else begin

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Tcp: Response ID ' + FormatCurr('00000', RemappedSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' discarded.');

        end;

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.HandleDnsResponseForIPv6Tcp: Malformed packet received from server ' + IntToStr(DnsServerIndex + 1) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) + '].');

      end;

    finally

      TDnsResolver_Lock.Release;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4UdpDnsResolver.Create;

begin

  inherited Create(True); FreeOnTerminate := False;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4UdpDnsResolver.Execute;

var
  ServerCommunicationChannel: TIPv4UdpCommunicationChannel; Buffer: Pointer; BufferLen: Integer; Output: Pointer; OutputLen: Integer; Address: TIPv4Address; Port: Word;

begin

  try

    ServerCommunicationChannel := TIPv4UdpCommunicationChannel.Create;

    try

      ServerCommunicationChannel.Bind(TConfiguration.GetLocalIPv4BindingAddress, TConfiguration.GetLocalIPv4BindingPort);

      try

        Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN);

        try

          Output := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN);

          try

            repeat

              try

                if ServerCommunicationChannel.Receive(DNS_RESOLVER_WAIT_TIME, MAX_DNS_BUFFER_LEN, Buffer, BufferLen, Address, Port) then begin

                  if TIPv4AddressUtility.IsLocalHost(Address) or TConfiguration.IsAllowedAddress(TIPv4AddressUtility.ToString(Address)) then begin

                    TDnsResolver.HandleDnsRequestForIPv4Udp(ServerCommunicationChannel, Now, Buffer, BufferLen, Output, OutputLen, Address, Port);

                  end else begin

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv4UdpDnsResolver.Execute: Unexpected packet received from address ' + TIPv4AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) + '].');

                  end;

                end;

              except

                on E: Exception do begin if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv4UdpDnsResolver.Execute: The following error occurred during execution: ' + E.Message); Sleep(20); end;

              end;

            until Terminated;

          finally

            TMemoryManager.FreeMemory(Output, MAX_DNS_BUFFER_LEN);

          end;

        finally

          TMemoryManager.FreeMemory(Buffer, MAX_DNS_BUFFER_LEN);

        end;

      finally

        // Nothing do to.

      end;

    finally

      ServerCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv4UdpDnsResolver.Execute: The following error occurred during execution: ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4UdpDnsResolver.Destroy;

begin

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6UdpDnsResolver.Create;

begin

  inherited Create(True); FreeOnTerminate := False;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6UdpDnsResolver.Execute;

var
  ServerCommunicationChannel: TIPv6UdpCommunicationChannel; Buffer: Pointer; BufferLen: Integer; Output: Pointer; OutputLen: Integer; Address: TIPv6Address; Port: Word;

begin

  try

    ServerCommunicationChannel := TIPv6UdpCommunicationChannel.Create;

    try

      ServerCommunicationChannel.Bind(TConfiguration.GetLocalIPv6BindingAddress, TConfiguration.GetLocalIPv6BindingPort);

      try

        Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN);

        try

          Output := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN);

          try

            repeat

              try

                if ServerCommunicationChannel.Receive(DNS_RESOLVER_WAIT_TIME, MAX_DNS_BUFFER_LEN, Buffer, BufferLen, Address, Port) then begin

                  if TIPv6AddressUtility.IsLocalHost(Address) or TConfiguration.IsAllowedAddress(TIPv6AddressUtility.ToString(Address)) then begin

                    TDnsResolver.HandleDnsRequestForIPv6Udp(ServerCommunicationChannel, Now, Buffer, BufferLen, Output, OutputLen, Address, Port);

                  end else begin

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv6UdpDnsResolver.Execute: Unexpected packet received from address ' + TIPv6AddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) + '].');

                  end;

                end;

              except

                on E: Exception do begin if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv6UdpDnsResolver.Execute: The following error occurred during execution: ' + E.Message); Sleep(20); end;

              end;

            until Terminated;

          finally

            TMemoryManager.FreeMemory(Output, MAX_DNS_BUFFER_LEN);

          end;

        finally

          TMemoryManager.FreeMemory(Buffer, MAX_DNS_BUFFER_LEN);

        end;

      finally

        // Nothing do to.

      end;

    finally

      ServerCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv6UdpDnsResolver.Execute: The following error occurred during execution: ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6UdpDnsResolver.Destroy;

begin

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4TcpDnsResolver.Create;

begin

  inherited Create(True); FreeOnTerminate := False;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4TcpDnsResolver.Execute;

var
  ServerCommunicationChannel: TIPv4TcpCommunicationChannel; ServerCommunicationChannelSession: TIPv4TcpCommunicationChannel; IPv4TcpDnsResolverSession: TIPv4TcpDnsResolverSession;

begin

  try

    ServerCommunicationChannel := TIPv4TcpCommunicationChannel.Create;

    try

      ServerCommunicationChannel.Bind(TConfiguration.GetLocalIPv4BindingAddress, TConfiguration.GetLocalIPv4BindingPort);

      repeat

        try

          ServerCommunicationChannelSession := ServerCommunicationChannel.Listen; if (ServerCommunicationChannelSession <> nil) then begin

            if TIPv4AddressUtility.IsLocalHost(ServerCommunicationChannelSession.RemoteAddress) or TConfiguration.IsAllowedAddress(TIPv4AddressUtility.ToString(ServerCommunicationChannelSession.RemoteAddress)) then begin

              IPv4TcpDnsResolverSession := TIPv4TcpDnsResolverSession.Create(ServerCommunicationChannelSession); if (IPv4TcpDnsResolverSession <> nil) then begin

                IPv4TcpDnsResolverSession.Resume;

              end;

            end else begin

              if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv4TcpDnsResolver.Execute: Unexpected connection attempted from address ' + TIPv4AddressUtility.ToString(ServerCommunicationChannelSession.RemoteAddress) + ':' + IntToStr(ServerCommunicationChannelSession.RemotePort) + '.');

              ServerCommunicationChannelSession.Free;

            end;

          end;

        except

          on E: Exception do begin if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv4TcpDnsResolver.Execute: The following error occurred during execution: ' + E.Message); Sleep(20); end;

        end;

      until Terminated;

    finally

      ServerCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv4TcpDnsResolver.Execute: The following error occurred during execution: ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4TcpDnsResolver.Destroy;

begin

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv4TcpDnsResolverSession.Create(ServerCommunicationChannel: TIPv4TcpCommunicationChannel);

begin

  inherited Create(True); FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv4TcpDnsResolverSession.Execute;

var
  Buffer: Pointer; BufferLen: Integer; Output: Pointer; OutputLen: Integer;

begin

  try

    Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN);

    try

      Output := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN);

      try

        if Self.ServerCommunicationChannel.Receive(2477, 1249, MAX_DNS_BUFFER_LEN, Buffer, BufferLen) then begin

          TDnsResolver.HandleDnsRequestForIPv4Tcp(ServerCommunicationChannel, Now, Buffer, BufferLen, Output, OutputLen, Self.ServerCommunicationChannel.RemoteAddress, Self.ServerCommunicationChannel.RemotePort);

          Sleep(14983);

        end;

      finally

        TMemoryManager.FreeMemory(Output, MAX_DNS_BUFFER_LEN);

      end;

    finally

      TMemoryManager.FreeMemory(Buffer, MAX_DNS_BUFFER_LEN);

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv4TcpDnsResolverSession.Execute: The following error occurred during execution: ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv4TcpDnsResolverSession.Destroy;

begin

  Self.ServerCommunicationChannel.Free;

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6TcpDnsResolver.Create;

begin

  inherited Create(True); FreeOnTerminate := False;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6TcpDnsResolver.Execute;

var
  ServerCommunicationChannel: TIPv6TcpCommunicationChannel; ServerCommunicationChannelSession: TIPv6TcpCommunicationChannel; IPv6TcpDnsResolverSession: TIPv6TcpDnsResolverSession;

begin

  try

    ServerCommunicationChannel := TIPv6TcpCommunicationChannel.Create;

    try

      ServerCommunicationChannel.Bind(TConfiguration.GetLocalIPv6BindingAddress, TConfiguration.GetLocalIPv6BindingPort);

      repeat

        try

          ServerCommunicationChannelSession := ServerCommunicationChannel.Listen; if (ServerCommunicationChannelSession <> nil) then begin

            if TIPv6AddressUtility.IsLocalHost(ServerCommunicationChannelSession.RemoteAddress) or TConfiguration.IsAllowedAddress(TIPv6AddressUtility.ToString(ServerCommunicationChannelSession.RemoteAddress)) then begin

              IPv6TcpDnsResolverSession := TIPv6TcpDnsResolverSession.Create(ServerCommunicationChannelSession); if (IPv6TcpDnsResolverSession <> nil) then begin

                IPv6TcpDnsResolverSession.Resume;

              end;

            end else begin

              if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TIPv6TcpDnsResolver.Execute: Unexpected connection attempted from address ' + TIPv6AddressUtility.ToString(ServerCommunicationChannelSession.RemoteAddress) + ':' + IntToStr(ServerCommunicationChannelSession.RemotePort) + '.');

              ServerCommunicationChannelSession.Free;

            end;

          end;

        except

          on E: Exception do begin if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv6TcpDnsResolver.Execute: The following error occurred during execution: ' + E.Message); Sleep(20); end;

        end;

      until Terminated;

    finally

      ServerCommunicationChannel.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv6TcpDnsResolver.Execute: The following error occurred during execution: ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6TcpDnsResolver.Destroy;

begin

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TIPv6TcpDnsResolverSession.Create(ServerCommunicationChannel: TIPv6TcpCommunicationChannel);

begin

  inherited Create(True); FreeOnTerminate := True;

  Self.ServerCommunicationChannel := ServerCommunicationChannel;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TIPv6TcpDnsResolverSession.Execute;

var
  Buffer: Pointer; BufferLen: Integer; Output: Pointer; OutputLen: Integer;

begin

  try

    Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN);

    try

      Output := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN);

      try

        if Self.ServerCommunicationChannel.Receive(2477, 1249, MAX_DNS_BUFFER_LEN, Buffer, BufferLen) then begin

          TDnsResolver.HandleDnsRequestForIPv6Tcp(ServerCommunicationChannel, Now, Buffer, BufferLen, Output, OutputLen, Self.ServerCommunicationChannel.RemoteAddress, Self.ServerCommunicationChannel.RemotePort);

          Sleep(14983);

        end;

      finally

        TMemoryManager.FreeMemory(Output, MAX_DNS_BUFFER_LEN);

      end;

    finally

      TMemoryManager.FreeMemory(Buffer, MAX_DNS_BUFFER_LEN);

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TIPv6TcpDnsResolverSession.Execute: The following error occurred during execution: ' + E.Message);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TIPv6TcpDnsResolverSession.Destroy;

begin

  Self.ServerCommunicationChannel.Free;

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TDnsResolverAddressCachePruner.Create;

begin

  inherited Create(True); FreeOnTerminate := False;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TDnsResolverAddressCachePruner.Execute;

var
  ReferenceTime: TDateTime;

begin

  repeat

    Sleep(DNS_RESOLVER_WAIT_TIME);

    ReferenceTime := Now; if TAddressCache.IsTimeForPeriodicPruning(ReferenceTime) then begin

      TDnsResolver_Lock.Acquire;

      try

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolverAddressCachePruner.Execute: Pruning address cache items...');

        try

          TAddressCache.Prune(ReferenceTime);

        except

          on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TDnsResolverAddressCachePruner.Execute: The following error occurred while pruning address cache items: ' + E.Message);

        end;

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolverAddressCachePruner.Execute: Done pruning address cache items.');

      finally

        TDnsResolver_Lock.Release;

      end;

    end;

  until Terminated;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TDnsResolverAddressCachePruner.Destroy;

begin

  inherited Destroy;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

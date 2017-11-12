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
  CommunicationChannels;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TDnsResolver = class(TThread)
    private
      Lock: TCriticalSection;
    private
      CommunicationChannel: TDualUdpCommunicationChannel;
    public
      class function  GetInstance: TDnsResolver;
      class procedure StartInstance;
      class procedure StopInstance;
    public
      constructor Create;
      destructor  Destroy; override;
      procedure   Execute; override;
    public
      procedure   HandleDnsRequest(Buffer: Pointer; BufferLen: Integer; var Output: Pointer; var OutputLen: Integer; Address: TDualIPAddress; Port: Word);
      procedure   HandleDnsResponse(Buffer: Pointer; BufferLen: Integer; Address: TDualIPAddress; Port: Word);
    public
      procedure   HandleIdleTimeOperations;
      procedure   HandleTerminalOperations;
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
  AddressCache,
  Configuration,
  Digest,
  DnsForwarder,
  DnsProtocol,
  HitLogger,
  HostsCache,
  MemoryManager,
  SessionCache,
  Statistics,
  Stopwatch,
  Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  DNS_RESOLVER_MAX_BLOCK_TIME = 6287;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TDnsResolver_Instance: TDnsResolver;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsResolver.GetInstance;
begin
  Result := TDnsResolver_Instance;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsResolver.StartInstance;
begin
  TDnsResolver_Instance := TDnsResolver.Create; TDnsResolver_Instance.Resume;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsResolver.StopInstance;
begin
  TDnsResolver_Instance.Terminate; TDnsResolver_Instance.WaitFor; TDnsResolver_Instance.Free;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TDnsResolver.Create;
begin
  inherited Create(True); FreeOnTerminate := False;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TDnsResolver.HandleDnsRequest(Buffer: Pointer; BufferLen: Integer; var Output: Pointer; var OutputLen: Integer; Address: TDualIPAddress; Port: Word);
var
  ArrivalTick: Double; ArrivalTime: TDateTime; SessionId: Word; RequestHash: Int64; QueryType: Word; DomainName: String; IPv4Address: TIPv4Address; IPv6Address: TIPv6Address; DnsServerIndex: Integer; Forwarded: Boolean;
begin
  ArrivalTick := TStopwatch.GetInstantValue;
  ArrivalTime := Now;

  Self.Lock.Acquire;

  try

    if (BufferLen >= MIN_DNS_PACKET_LEN) and (BufferLen <= MAX_DNS_PACKET_LEN) then begin

      if TDualIPAddressUtility.IsLocalHost(Address) or TConfiguration.IsAllowedAddress(TDualIPAddressUtility.ToString(Address)) then begin

        SessionId := TDnsProtocolUtility.GetIdFromPacket(Buffer);

        TDnsProtocolUtility.GetDomainNameAndQueryTypeFromRequestPacket(Buffer, BufferLen, DomainName, QueryType);

        if TStatistics.IsEnabled then TStatistics.IncTotalRequestsReceived;

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', SessionId) + ' received from address ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, True) + '].');

        if TConfiguration.IsBlackException(DomainName) then begin

          if (QueryType = DNS_QUERY_TYPE_A) then begin

            TDnsProtocolUtility.BuildPositiveIPv4ResponsePacket(DomainName, QueryType, LOCALHOST_IPV4_ADDRESS, TConfiguration.GetGeneratedDnsResponseTimeToLive, Output, OutputLen);

          end else if (QueryType = DNS_QUERY_TYPE_AAAA) then begin

            TDnsProtocolUtility.BuildPositiveIPv6ResponsePacket(DomainName, QueryType, LOCALHOST_IPV6_ADDRESS, TConfiguration.GetGeneratedDnsResponseTimeToLive, Output, OutputLen);

          end else begin

            TDnsProtocolUtility.BuildPositiveResponsePacket(DomainName, QueryType, Output, OutputLen);

          end;

          TDnsProtocolUtility.SetIdIntoPacket(SessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

          if TStatistics.IsEnabled then TStatistics.IncTotalRequestsResolvedThroughOtherWays;

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' as black exception.');

          if THitLogger.IsEnabled and (Pos('B', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'B', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'B', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

        end else if (QueryType = DNS_QUERY_TYPE_A) and THostsCache.FindNXHostsEntry(DomainName) then begin

          TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

          TDnsProtocolUtility.SetIdIntoPacket(SessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

          if TStatistics.IsEnabled then TStatistics.IncTotalRequestsResolvedThroughHostsFile;

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from hosts cache.');

          if THitLogger.IsEnabled and (Pos('H', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

        end else if (QueryType = DNS_QUERY_TYPE_A) and THostsCache.FindIPv4AddressHostsEntry(DomainName, IPv4Address) then begin

          TDnsProtocolUtility.BuildPositiveIPv4ResponsePacket(DomainName, QueryType, IPv4Address, TConfiguration.GetGeneratedDnsResponseTimeToLive, Output, OutputLen);

          TDnsProtocolUtility.SetIdIntoPacket(SessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

          if TStatistics.IsEnabled then TStatistics.IncTotalRequestsResolvedThroughHostsFile;

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from hosts cache.');

          if THitLogger.IsEnabled and (Pos('H', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

        end else if (QueryType = DNS_QUERY_TYPE_A) and THostsCache.FindIPv6AddressHostsEntry(DomainName, IPv6Address) then begin

          TDnsProtocolUtility.BuildPositiveResponsePacket(DomainName, QueryType, Output, OutputLen);

          TDnsProtocolUtility.SetIdIntoPacket(SessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

          if TStatistics.IsEnabled then TStatistics.IncTotalRequestsResolvedThroughHostsFile;

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from hosts cache.');

          if THitLogger.IsEnabled and (Pos('H', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

        end else if (QueryType = DNS_QUERY_TYPE_AAAA) and THostsCache.FindNXHostsEntry(DomainName) then begin

          TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

          TDnsProtocolUtility.SetIdIntoPacket(SessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

          if TStatistics.IsEnabled then TStatistics.IncTotalRequestsResolvedThroughHostsFile;

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from hosts cache.');

          if THitLogger.IsEnabled and (Pos('H', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

        end else if (QueryType = DNS_QUERY_TYPE_AAAA) and THostsCache.FindIPv6AddressHostsEntry(DomainName, IPv6Address) then begin

          TDnsProtocolUtility.BuildPositiveIPv6ResponsePacket(DomainName, QueryType, IPv6Address, TConfiguration.GetGeneratedDnsResponseTimeToLive, Output, OutputLen);

          TDnsProtocolUtility.SetIdIntoPacket(SessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

          if TStatistics.IsEnabled then TStatistics.IncTotalRequestsResolvedThroughHostsFile;

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from hosts cache.');

          if THitLogger.IsEnabled and (Pos('H', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

        end else if (QueryType = DNS_QUERY_TYPE_AAAA) and THostsCache.FindIPv4AddressHostsEntry(DomainName, IPv4Address) then begin

          TDnsProtocolUtility.BuildPositiveResponsePacket(DomainName, QueryType, Output, OutputLen);

          TDnsProtocolUtility.SetIdIntoPacket(SessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

          if TStatistics.IsEnabled then TStatistics.IncTotalRequestsResolvedThroughHostsFile;

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from hosts cache.');

          if THitLogger.IsEnabled and (Pos('H', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

        end else if TConfiguration.IsCacheException(DomainName) then begin

          Forwarded := False;

          for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin // For every DNS server
            if TConfiguration.GetDnsServerConfiguration(DnsServerIndex).IsEnabled then begin // If it has been configured
              if TConfiguration.IsDomainNameAffinityMatch(DomainName, TConfiguration.GetDnsServerConfiguration(DnsServerIndex).DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, TConfiguration.GetDnsServerConfiguration(DnsServerIndex).QueryTypeAffinityMask) then begin

                if TDnsForwarder.ForwardDnsRequest(TConfiguration.GetDnsServerConfiguration(DnsServerIndex), Buffer, BufferLen, SessionId) then begin

                  Forwarded := True;

                  if TStatistics.IsEnabled then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalTick, False, DnsServerIndex, SessionId);

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', SessionId) + ' forwarded to server ' + TDualIPAddressUtility.ToString(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Address) + ':' + IntToStr(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Port) + ' as cache exception.');

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', SessionId) + ' failed to be forwarded to server ' + TDualIPAddressUtility.ToString(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Address) + ':' + IntToStr(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Port) + ' as cache exception.');

                end;

              end;
            end;
          end;

          if Forwarded then begin

            TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); RequestHash := TDigest.ComputeCRC64(Buffer, BufferLen); TSessionCache.Insert(SessionId, RequestHash, Address, Port, False, True);

            if TStatistics.IsEnabled then TStatistics.IncTotalRequestsForwarded;

            if THitLogger.IsEnabled and (Pos('F', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'F', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'F', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

          end else begin

            TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(SessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly as negative.');

          end;

        end else begin // The domain name is neither in the hosts cache nor is a cache exception

          if not(TConfiguration.GetAddressCacheDisabled) then begin

            // Gonna check by hash if the request exists in the address cache
            TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); RequestHash := TDigest.ComputeCRC64(Buffer, BufferLen); TDnsProtocolUtility.SetIdIntoPacket(SessionId, Buffer); case TAddressCache.Find(ArrivalTime, RequestHash, Output, OutputLen) of

              RecentEnough:
              begin

                TDnsProtocolUtility.SetIdIntoPacket(SessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

                if TStatistics.IsEnabled then TStatistics.IncTotalRequestsResolvedThroughCache;

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from address cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Output, OutputLen, True) + '].');

                if THitLogger.IsEnabled and (Pos('C', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'C', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'C', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

              end;

              NeedsUpdate:
              begin

                TDnsProtocolUtility.SetIdIntoPacket(SessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from address cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Output, OutputLen, True) + '].');

                Forwarded := False;

                for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin // For every DNS server
                  if TConfiguration.GetDnsServerConfiguration(DnsServerIndex).IsEnabled then begin // If it has been configured
                    if TConfiguration.IsDomainNameAffinityMatch(DomainName, TConfiguration.GetDnsServerConfiguration(DnsServerIndex).DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, TConfiguration.GetDnsServerConfiguration(DnsServerIndex).QueryTypeAffinityMask) then begin

                      if TDnsForwarder.ForwardDnsRequest(TConfiguration.GetDnsServerConfiguration(DnsServerIndex), Buffer, BufferLen, SessionId) then begin

                        Forwarded := True;

                        if TStatistics.IsEnabled then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalTick, False, DnsServerIndex, SessionId);

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', SessionId) + ' forwarded to server ' + TDualIPAddressUtility.ToString(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Address) + ':' + IntToStr(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Port) + ' as silent update.');

                      end else begin

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', SessionId) + ' failed to be forwarded to server ' + TDualIPAddressUtility.ToString(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Address) + ':' + IntToStr(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Port) + ' as silent update.');

                      end;

                    end;
                  end;
                end;

                if Forwarded then begin

                  TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TSessionCache.Insert(SessionId, RequestHash, Address, Port, True, False);

                  if TStatistics.IsEnabled then TStatistics.IncTotalRequestsResolvedThroughCache;

                  if THitLogger.IsEnabled and (Pos('C', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'C', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'C', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

                end;

              end;

              NotFound:
              begin

                Forwarded := False;

                for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin // For every DNS server
                  if TConfiguration.GetDnsServerConfiguration(DnsServerIndex).IsEnabled then begin // If it has been configured
                    if TConfiguration.IsDomainNameAffinityMatch(DomainName, TConfiguration.GetDnsServerConfiguration(DnsServerIndex).DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, TConfiguration.GetDnsServerConfiguration(DnsServerIndex).QueryTypeAffinityMask) then begin

                      if TDnsForwarder.ForwardDnsRequest(TConfiguration.GetDnsServerConfiguration(DnsServerIndex), Buffer, BufferLen, SessionId) then begin

                        Forwarded := True;

                        if TStatistics.IsEnabled then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalTick, False, DnsServerIndex, SessionId);

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', SessionId) + ' forwarded to server ' + TDualIPAddressUtility.ToString(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Address) + ':' + IntToStr(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Port) + '.');

                      end else begin

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', SessionId) + ' failed to be forwarded to server ' + TDualIPAddressUtility.ToString(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Address) + ':' + IntToStr(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Port) + '.');

                      end;

                    end;
                  end;
                end;

                if Forwarded then begin

                  TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TSessionCache.Insert(SessionId, RequestHash, Address, Port, False, False);

                  if TStatistics.IsEnabled then TStatistics.IncTotalRequestsForwarded;

                  if THitLogger.IsEnabled and (Pos('F', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'F', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'F', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

                end else begin

                  TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

                  TDnsProtocolUtility.SetIdIntoPacket(SessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly as negative.');

                end;

              end;

            end;

          end else begin // The address cache has been disabled

            Forwarded := False;

            for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin // For every DNS server
              if TConfiguration.GetDnsServerConfiguration(DnsServerIndex).IsEnabled then begin // If it has been configured
                if TConfiguration.IsDomainNameAffinityMatch(DomainName, TConfiguration.GetDnsServerConfiguration(DnsServerIndex).DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, TConfiguration.GetDnsServerConfiguration(DnsServerIndex).QueryTypeAffinityMask) then begin

                  if TDnsForwarder.ForwardDnsRequest(TConfiguration.GetDnsServerConfiguration(DnsServerIndex), Buffer, BufferLen, SessionId) then begin

                    Forwarded := True;

                    if TStatistics.IsEnabled then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalTick, False, DnsServerIndex, SessionId);

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', SessionId) + ' forwarded to server ' + TDualIPAddressUtility.ToString(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Address) + ':' + IntToStr(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Port) + '.');

                  end else begin

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', SessionId) + ' failed to be forwarded to server ' + TDualIPAddressUtility.ToString(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Address) + ':' + IntToStr(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Port) + '.');

                  end;

                end;
              end;
            end;

            if Forwarded then begin

              TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); RequestHash := TDigest.ComputeCRC64(Buffer, BufferLen); TSessionCache.Insert(SessionId, RequestHash, Address, Port, False, False);

              if TStatistics.IsEnabled then TStatistics.IncTotalRequestsForwarded;

              if THitLogger.IsEnabled and (Pos('F', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'F', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'F', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

            end else begin

              TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

              TDnsProtocolUtility.SetIdIntoPacket(SessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

              if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly as negative.');

            end;

          end;

        end;

      end else begin // It's a spurious packet coming from the infinite

        if TStatistics.IsEnabled then TStatistics.IncTotalPacketsDiscarded;

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Unexpected packet received from address ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) + '].');

      end;

    end else begin // It's a spurious packet coming from the infinite

      if TStatistics.IsEnabled then TStatistics.IncTotalPacketsDiscarded;

      if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Malformed packet received from address ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) + '].');

    end;

  finally

    Self.Lock.Release;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TDnsResolver.HandleDnsResponse(Buffer: Pointer; BufferLen: Integer; Address: TDualIPAddress; Port: Word);
var
  ArrivalTick: Double; ArrivalTime: TDateTime; DnsServerIndex: Integer; SessionId: Word; AltAddress: TDualIPAddress; AltPort: Word; RequestHash: Int64; IsSilentUpdate: Boolean; IsCacheException: Boolean;
begin
  ArrivalTick := TStopwatch.GetInstantValue;
  ArrivalTime := Now;

  Self.Lock.Acquire;

  try

    if (BufferLen >= MIN_DNS_PACKET_LEN) and (BufferLen <= MAX_DNS_PACKET_LEN) then begin

      DnsServerIndex := TConfiguration.FindDnsServerConfiguration(Address, Port); if (DnsServerIndex > -1) then begin

        SessionId := TDnsProtocolUtility.GetIdFromPacket(Buffer);

        if TStatistics.IsEnabled then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalTick, True, DnsServerIndex, SessionId);

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' received from server ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, True) + '].');

        if not(TDnsProtocolUtility.IsFailureResponsePacket(Buffer, BufferLen)) then begin

          if TSessionCache.Extract(SessionId, RequestHash, AltAddress, AltPort, IsSilentUpdate, IsCacheException) then begin

            if IsCacheException then begin

              if not(TDnsProtocolUtility.IsNegativeResponsePacket(Buffer, BufferLen)) then begin

                TSessionCache.Delete(SessionId);

                Self.CommunicationChannel.SendTo(Buffer, BufferLen, AltAddress, AltPort);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(AltAddress) + ':' + IntToStr(AltPort) + ' as positive.');

                if THitLogger.IsEnabled and (Pos('R', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

              end else begin // The response is negative!

                if not(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).IgnoreNegativeResponsesFromServer) then begin

                  TSessionCache.Delete(SessionId);

                  Self.CommunicationChannel.SendTo(Buffer, BufferLen, AltAddress, AltPort);

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(AltAddress) + ':' + IntToStr(AltPort) + ' as negative.');

                  if THitLogger.IsEnabled and (Pos('R', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' discarded as negative.');

                end;

              end;

            end else if IsSilentUpdate then begin

              if not(TDnsProtocolUtility.IsNegativeResponsePacket(Buffer, BufferLen)) then begin

                TSessionCache.Delete(SessionId);

                if not(TConfiguration.GetAddressCacheDisabled) then begin

                  TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.Add(ArrivalTime, RequestHash, Buffer, BufferLen, False);

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' put into the address cache as positive silent update.');

                end;

                if THitLogger.IsEnabled and (Pos('U', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'U', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'U', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

              end else begin // The response is negative!

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + ' discarded as negative silent update.');

              end;

            end else begin // It's a response to a standard request!

              if not(TDnsProtocolUtility.IsNegativeResponsePacket(Buffer, BufferLen)) then begin

                TSessionCache.Delete(SessionId);

                Self.CommunicationChannel.SendTo(Buffer, BufferLen, AltAddress, AltPort);

                if not(TConfiguration.GetAddressCacheDisabled) then begin

                  TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.Add(ArrivalTime, RequestHash, Buffer, BufferLen, False);

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(AltAddress) + ':' + IntToStr(AltPort) + ' and put into the address cache as positive.');

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(AltAddress) + ':' + IntToStr(AltPort) + ' as positive.');

                end;

                if THitLogger.IsEnabled and (Pos('R', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

              end else begin // The response is negative!

                if not(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).IgnoreNegativeResponsesFromServer) then begin

                  TSessionCache.Delete(SessionId);

                  Self.CommunicationChannel.SendTo(Buffer, BufferLen, AltAddress, AltPort);

                  if not(TConfiguration.GetAddressCacheDisabled) then begin

                    TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.Add(ArrivalTime, RequestHash, Buffer, BufferLen, True);

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(AltAddress) + ':' + IntToStr(AltPort) + ' and put into the address cache as negative.');

                  end else begin

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(AltAddress) + ':' + IntToStr(AltPort) + ' as negative.');

                  end;

                  if THitLogger.IsEnabled and (Pos('R', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' discarded as negative.');

                end;

              end;

            end;

          end else begin // The item has not been found in the session cache!

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' discarded because no session cache entry matched.');

          end;

        end else begin // The response is a failure

          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' discarded as failure.');

        end;

      end else begin // It's a spurious packet coming from the infinite

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Unexpected packet received from address ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) + '].');

      end;

    end else begin // It's a malformed packet coming from the infinite

      if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Malformed packet received from address ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) + '].');

    end;

  finally

    Self.Lock.Release;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TDnsResolver.HandleIdleTimeOperations;
begin
  Self.Lock.Acquire;

  try

    if TStatistics.IsEnabled then TStatistics.FlushStatisticsToDisk;

    if THitLogger.IsEnabled then THitLogger.FlushAllPendingHitsToDisk;

  finally

    Self.Lock.Release;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TDnsResolver.HandleTerminalOperations;
begin
  Self.Lock.Acquire;

  try

    if TStatistics.IsEnabled then TStatistics.FlushStatisticsToDisk;

    if THitLogger.IsEnabled then THitLogger.FlushAllPendingHitsToDisk;

  finally

    Self.Lock.Release;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TDnsResolver.Execute;
var
  Buffer: Pointer; BufferLen: Integer; Output: Pointer; OutputLen: Integer; Address: TDualIPAddress; Port: Word;
begin
  try

    Self.Lock := TCriticalSection.Create;

    try

      Self.CommunicationChannel := TDualUdpCommunicationChannel.Create;

      try

        Self.CommunicationChannel.Bind(TConfiguration.IsLocalIPv4BindingEnabled, TConfiguration.GetLocalIPv4BindingAddress, TConfiguration.GetLocalIPv4BindingPort, TConfiguration.IsLocalIPv6BindingEnabled, TConfiguration.GetLocalIPv6BindingAddress, TConfiguration.GetLocalIPv6BindingPort);

        try

          TMemoryManager.GetMemory(Buffer, MAX_DNS_BUFFER_LEN);

          try

            TMemoryManager.GetMemory(Output, MAX_DNS_BUFFER_LEN);

            try

              repeat

                if Self.CommunicationChannel.ReceiveFrom(DNS_RESOLVER_MAX_BLOCK_TIME, MAX_DNS_BUFFER_LEN, Buffer, BufferLen, Address, Port) then begin

                  Self.HandleDnsRequest(Buffer, BufferLen, Output, OutputLen, Address, Port);

                end else begin

                  Self.HandleIdleTimeOperations;

                end;

              until Terminated;

              Self.HandleTerminalOperations;

            finally

              TMemoryManager.FreeMemory(Output, MAX_DNS_BUFFER_LEN);

            end;

          finally

            TMemoryManager.FreeMemory(Buffer, MAX_DNS_BUFFER_LEN);

          end;

        finally

          // Nothing do to

        end;

      finally

        Self.CommunicationChannel.Free;

      end;

    finally

      Self.Lock.Free;

    end;

  except

    on E: Exception do if (TTracer.IsEnabled) then TTracer.Trace(TracePriorityError, 'TDnsResolver.Execute: ' + E.Message);

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TDnsResolver.Destroy;
begin
  inherited Destroy;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

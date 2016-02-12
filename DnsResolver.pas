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
      procedure   HandleLowPriorityOperations;
      procedure   HandleTerminatedOperations;
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
  DNS_RESOLVER_MAX_BLOCK_TIME = 6283;

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
  inherited Create(True);

  // Want to free by hand
  FreeOnTerminate := False;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TDnsResolver.HandleDnsRequest(Buffer: Pointer; BufferLen: Integer; var Output: Pointer; var OutputLen: Integer; Address: TDualIPAddress; Port: Word);
var
  ArrivalTick: Double; ArrivalTime: TDateTime; SessionId: Word; RequestHash: Int64; DomainName: String; HostsEntry: THostsEntry; QueryType: Word; DnsServerIndex: Integer; Forwarded: Boolean;
begin
  ArrivalTick := TStopwatch.GetInstantValue;
  ArrivalTime := Now;

  Self.Lock.Acquire;

  try

    // If the packet is not too small or large
    if (BufferLen >= MIN_DNS_PACKET_LEN) and (BufferLen <= MAX_DNS_PACKET_LEN) then begin

      // If it's a request coming from one of the allowed DNS clients
      if TDualIPAddressUtility.IsLocalHost(Address) or TConfiguration.IsAllowedAddress(TDualIPAddressUtility.ToString(Address)) then begin

        // Get the id field from the packet
        SessionId := TDnsProtocolUtility.GetIdFromPacket(Buffer);

        // Get the domain name and query type from the request
        TDnsProtocolUtility.GetDomainNameAndQueryTypeFromRequestPacket(Buffer, BufferLen, DomainName, QueryType);

        // Update performance stats if enabled
        if TStatistics.IsEnabled then TStatistics.IncTotalRequestsReceived;

        // Trace the event if a tracer is enabled
        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', SessionId) + ' received from client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, True) + '].');

        if TConfiguration.IsBlackException(DomainName) then begin // If a black exception

          case QueryType of // Build a positive response

            DNS_QUERY_TYPE_A:
              TDnsProtocolUtility.BuildPositiveIPv4ResponsePacket(DomainName, QueryType, LOCALHOST_IPV4_ADDRESS, Output, OutputLen);

            DNS_QUERY_TYPE_AAAA:
              TDnsProtocolUtility.BuildPositiveIPv6ResponsePacket(DomainName, QueryType, LOCALHOST_IPV6_ADDRESS, Output, OutputLen);

            else
              TDnsProtocolUtility.BuildPositiveResponsePacket(DomainName, QueryType, Output, OutputLen);

          end;

          // Send the response to the client
          TDnsProtocolUtility.SetIdIntoPacket(SessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

          // Update performance stats if enabled
          if TStatistics.IsEnabled then TStatistics.IncTotalRequestsResolvedThroughOtherWays;

          // Trace the event if a tracer is enabled
          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' as black exception.');

          // Trace the event into the hit log if enabled
          if THitLogger.IsEnabled and (Pos('B', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'B', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'B', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

        end else if THostsCache.Find(DomainName, QueryType, HostsEntry) then begin // If the domain name exists in the hosts cache

          case QueryType of // Build a positive response

            DNS_QUERY_TYPE_A:
              TDnsProtocolUtility.BuildPositiveIPv4ResponsePacket(DomainName, QueryType, HostsEntry.Address.IPv4Address, Output, OutputLen);

            DNS_QUERY_TYPE_AAAA:
              TDnsProtocolUtility.BuildPositiveIPv6ResponsePacket(DomainName, QueryType, HostsEntry.Address.IPv6Address, Output, OutputLen);

            else
              TDnsProtocolUtility.BuildPositiveResponsePacket(DomainName, QueryType, Output, OutputLen);

          end;

          // Send the response to the client
          TDnsProtocolUtility.SetIdIntoPacket(SessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

          // Update performance stats if enabled
          if TStatistics.IsEnabled then TStatistics.IncTotalRequestsResolvedThroughHostsFile;

          // Trace the event if a tracer is enabled
          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from hosts cache.');

          // Trace the event into the hit log if enabled
          if THitLogger.IsEnabled and (Pos('H', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

        end else if TConfiguration.IsCacheException(DomainName) then begin // If the domain name is configured as a cache exception

          // We need to know if the request has been forwarded to at least one DNS server or not
          Forwarded := False;

          for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin // For every DNS server
            if TConfiguration.GetDnsServerConfiguration(DnsServerIndex).IsEnabled then begin // If it has been configured
              if TConfiguration.IsDomainNameAffinityMatch(DomainName, TConfiguration.GetDnsServerConfiguration(DnsServerIndex).DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, TConfiguration.GetDnsServerConfiguration(DnsServerIndex).QueryTypeAffinityMask) then begin

                Forwarded := True;

                // Forward the request to the server
                TDnsForwarder.ForwardDnsRequest(TConfiguration.GetDnsServerConfiguration(DnsServerIndex), Buffer, BufferLen, SessionId);

                // Update performance stats if enabled
                if TStatistics.IsEnabled then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalTick, False, DnsServerIndex, SessionId);

                // Trace the event if a tracer is enabled
                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', SessionId) + ' forwarded to server ' + TDualIPAddressUtility.ToString(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Address) + ':' + IntToStr(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Port) + ' as cache exception.');

              end;
            end;
          end;

          if Forwarded then begin

            // Insert the item into the session cache
            TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); RequestHash := TDigest.ComputeCRC64(Buffer, BufferLen); TSessionCache.Insert(SessionId, RequestHash, Address, Port, False, True);

            // Update performance stats if enabled
            if TStatistics.IsEnabled then TStatistics.IncTotalRequestsForwarded;

            // Trace the event into the hit log if enabled
            if THitLogger.IsEnabled and (Pos('F', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'F', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'F', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

          end else begin

            // Build a negative response
            TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

            // Send the response to the client
            TDnsProtocolUtility.SetIdIntoPacket(SessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

            // Trace the event if a tracer is enabled
            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly as negative.');

          end;

        end else begin // The domain name is neither in the hosts cache nor is a cache exception

          if not TConfiguration.GetAddressCacheDisabled then begin

            // Gonna check by hash if the request exists in the address cache
            TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); RequestHash := TDigest.ComputeCRC64(Buffer, BufferLen); TDnsProtocolUtility.SetIdIntoPacket(SessionId, Buffer);

            case TAddressCache.Find(ArrivalTime, RequestHash, Output, OutputLen) of

              RecentEnough: begin // The address cache item is recent

                // Send the response to the client
                TDnsProtocolUtility.SetIdIntoPacket(SessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

                // Update performance stats if enabled
                if TStatistics.IsEnabled then TStatistics.IncTotalRequestsResolvedThroughCache;

                // Trace the event if a tracer is enabled
                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from address cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Output, OutputLen, True) + '].');

                // Trace the event into the hit log if enabled
                if THitLogger.IsEnabled and (Pos('C', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'C', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'C', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

              end;

              NeedsUpdate: begin // The address cache item needs a silent update

                // Send the response to the client
                TDnsProtocolUtility.SetIdIntoPacket(SessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

                // Trace the event if a tracer is enabled
                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly from address cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Output, OutputLen, True) + '].');

                // We need to know if the request has been forwarded to at least one DNS server or not
                Forwarded := False;

                for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin // For every DNS server
                  if TConfiguration.GetDnsServerConfiguration(DnsServerIndex).IsEnabled then begin // If it has been configured
                    if TConfiguration.IsDomainNameAffinityMatch(DomainName, TConfiguration.GetDnsServerConfiguration(DnsServerIndex).DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, TConfiguration.GetDnsServerConfiguration(DnsServerIndex).QueryTypeAffinityMask) then begin

                      Forwarded := True;

                      // Forward the request to the server
                      TDnsForwarder.ForwardDnsRequest(TConfiguration.GetDnsServerConfiguration(DnsServerIndex), Buffer, BufferLen, SessionId);

                      // Update performance stats if enabled
                      if TStatistics.IsEnabled then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalTick, False, DnsServerIndex, SessionId);

                      // Trace the event if a tracer is enabled
                      if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', SessionId) + ' forwarded to server ' + TDualIPAddressUtility.ToString(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Address) + ':' + IntToStr(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Port) + ' as silent update.');

                    end;
                  end;
                end;

                if Forwarded then begin

                  // Put the item into the session cache
                  TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TSessionCache.Insert(SessionId, RequestHash, Address, Port, True, False);

                  // Update performance stats if enabled
                  if TStatistics.IsEnabled then TStatistics.IncTotalRequestsResolvedThroughCache;

                  // Trace the event into the hit log if enabled
                  if THitLogger.IsEnabled and (Pos('C', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'C', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'C', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

                end;

              end;

              NotFound: begin // The item is not in the address cache

                // We need to know if the request has been forwarded to at least one DNS server or not
                Forwarded := False;

                for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin // For every DNS server
                  if TConfiguration.GetDnsServerConfiguration(DnsServerIndex).IsEnabled then begin // If it has been configured
                    if TConfiguration.IsDomainNameAffinityMatch(DomainName, TConfiguration.GetDnsServerConfiguration(DnsServerIndex).DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, TConfiguration.GetDnsServerConfiguration(DnsServerIndex).QueryTypeAffinityMask) then begin

                      Forwarded := True;

                      // Forward the request to the server
                      TDnsForwarder.ForwardDnsRequest(TConfiguration.GetDnsServerConfiguration(DnsServerIndex), Buffer, BufferLen, SessionId);

                      // Update performance stats if enabled
                      if TStatistics.IsEnabled then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalTick, False, DnsServerIndex, SessionId);

                      // Trace the event if a tracer is enabled
                      if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', SessionId) + ' forwarded to server ' + TDualIPAddressUtility.ToString(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Address) + ':' + IntToStr(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Port) + '.');

                    end;
                  end;
                end;

                if Forwarded then begin

                  // Put the item into the session cache
                  TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TSessionCache.Insert(SessionId, RequestHash, Address, Port, False, False);

                  // Update performance stats if enabled
                  if TStatistics.IsEnabled then TStatistics.IncTotalRequestsForwarded;

                  // Trace the event into the hit log if enabled
                  if THitLogger.IsEnabled and (Pos('F', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'F', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'F', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

                end else begin

                  // Build a negative response
                  TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

                  // Send the response to the client
                  TDnsProtocolUtility.SetIdIntoPacket(SessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

                  // Trace the event if a tracer is enabled
                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly as negative.');

                end;

              end;

            end;

          end else begin // The address cache has been disabled

            // We need to know if the request has been forwarded to at least one DNS server or not
            Forwarded := False;

            for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin // For every DNS server
              if TConfiguration.GetDnsServerConfiguration(DnsServerIndex).IsEnabled then begin // If it has been configured
                if TConfiguration.IsDomainNameAffinityMatch(DomainName, TConfiguration.GetDnsServerConfiguration(DnsServerIndex).DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, TConfiguration.GetDnsServerConfiguration(DnsServerIndex).QueryTypeAffinityMask) then begin

                  Forwarded := True;

                  // Forward the request to the server
                  TDnsForwarder.ForwardDnsRequest(TConfiguration.GetDnsServerConfiguration(DnsServerIndex), Buffer, BufferLen, SessionId);

                  // Update performance stats if enabled
                  if TStatistics.IsEnabled then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalTick, False, DnsServerIndex, SessionId);

                  // Trace the event if a tracer is enabled
                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', SessionId) + ' forwarded to server ' + TDualIPAddressUtility.ToString(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Address) + ':' + IntToStr(TConfiguration.GetDnsServerConfiguration(DnsServerIndex).Port) + '.');

                end;
              end;
            end;

            if Forwarded then begin

              // Put the item into the session cache
              TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); RequestHash := TDigest.ComputeCRC64(Buffer, BufferLen); TSessionCache.Insert(SessionId, RequestHash, Address, Port, False, False);

              // Update performance stats if enabled
              if TStatistics.IsEnabled then TStatistics.IncTotalRequestsForwarded;

              // Trace the event into the hit log if enabled
              if THitLogger.IsEnabled and (Pos('F', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'F', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'F', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

            end else begin

              // Build a negative response
              TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

              // Send the response to the client
              TDnsProtocolUtility.SetIdIntoPacket(SessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

              // Trace the event if a tracer is enabled
              if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' directly as negative.');

            end;

          end;

        end;

      end else begin // It's a spurious packet coming from the infinite

        // Update performance stats if enabled
        if TStatistics.IsEnabled then TStatistics.IncTotalPacketsDiscarded;

        // Trace the event if a tracer is enabled
        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Unexpected packet received from address ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) + '].');

      end;

    end else begin // It's a spurious packet coming from the infinite

      // Update performance stats if enabled
      if TStatistics.IsEnabled then TStatistics.IncTotalPacketsDiscarded;

      // Trace the event if a tracer is enabled
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

    // If the packet is not too small or large
    if (BufferLen >= MIN_DNS_PACKET_LEN) and (BufferLen <= MAX_DNS_PACKET_LEN) then begin

      // If it's a response coming from one of the DNS servers
      DnsServerIndex := TConfiguration.FindDnsServerConfiguration(Address, Port); if (DnsServerIndex > -1) then begin

        // Get the id field from the packet
        SessionId := TDnsProtocolUtility.GetIdFromPacket(Buffer);

        // Update performance stats if enabled
        if TStatistics.IsEnabled then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalTick, True, DnsServerIndex, SessionId);

        // Trace the event if a tracer is enabled
        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' received from server ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, True) + '].');

        if not TDnsProtocolUtility.IsFailureResponsePacket(Buffer, BufferLen) then begin // If the response is not a failure

          // If the item exists in the session cache
          if TSessionCache.Extract(SessionId, RequestHash, AltAddress, AltPort, IsSilentUpdate, IsCacheException) then begin

            if IsCacheException then begin // If it's a response to a cache exception request

              if not TDnsProtocolUtility.IsNegativeResponsePacket(Buffer, BufferLen) then begin // If the response is not negative

                // Clear the item
                TSessionCache.Delete(SessionId);

                // Forward the packet to the client
                Self.CommunicationChannel.SendTo(Buffer, BufferLen, AltAddress, AltPort);

                // Trace the event if a tracer is enabled
                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(AltAddress) + ':' + IntToStr(AltPort) + ' as positive.');

                // Trace the event into the hit log if enabled
                if THitLogger.IsEnabled and (Pos('R', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

              end else begin // The response is negative!

                if not TConfiguration.GetDnsServerConfiguration(DnsServerIndex).IgnoreNegativeResponsesFromServer then begin

                  // Clear the item
                  TSessionCache.Delete(SessionId);

                  // Forward the packet to the client
                  Self.CommunicationChannel.SendTo(Buffer, BufferLen, AltAddress, AltPort);

                  // Trace the event if a tracer is enabled
                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(AltAddress) + ':' + IntToStr(AltPort) + ' as negative.');

                  // Trace the event into the hit log if enabled
                  if THitLogger.IsEnabled and (Pos('R', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

                end else begin

                  // Trace the event if a tracer is enabled
                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' discarded as negative.');

                end;

              end;

            end else if IsSilentUpdate then begin // If it's a response to a silent update request

              if not TDnsProtocolUtility.IsNegativeResponsePacket(Buffer, BufferLen) then begin // If the response is not negative

                // Clear the item
                TSessionCache.Delete(SessionId);

                if not TConfiguration.GetAddressCacheDisabled then begin

                  // Put the item into the address cache
                  TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.Add(ArrivalTime, RequestHash, Buffer, BufferLen, False);

                  // Trace the event if a tracer is enabled
                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' put into the address cache as positive silent update.');

                end;

                // Trace the event into the hit log if enabled
                if THitLogger.IsEnabled and (Pos('U', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'U', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'U', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

              end else begin // The response is negative!

                // Trace the event if a tracer is enabled
                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + ' discarded as negative silent update.');

              end;

            end else begin // It's a response to a standard request!

              if not TDnsProtocolUtility.IsNegativeResponsePacket(Buffer, BufferLen) then begin // If the response is not negative

                // Clear the item
                TSessionCache.Delete(SessionId);

                // Forward the packet to the client
                Self.CommunicationChannel.SendTo(Buffer, BufferLen, AltAddress, AltPort);

                if not(TConfiguration.GetAddressCacheDisabled) then begin

                  // Put the item into the address cache
                  TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.Add(ArrivalTime, RequestHash, Buffer, BufferLen, False);

                  // Trace the event if a tracer is enabled
                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(AltAddress) + ':' + IntToStr(AltPort) + ' and put into the address cache as positive.');

                end else begin

                  // Trace the event if a tracer is enabled
                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(AltAddress) + ':' + IntToStr(AltPort) + ' as positive.');

                end;

                // Trace the event into the hit log if enabled
                if THitLogger.IsEnabled and (Pos('R', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

              end else begin // The response is negative!

                if not TConfiguration.GetDnsServerConfiguration(DnsServerIndex).IgnoreNegativeResponsesFromServer then begin

                  // Clear the item
                  TSessionCache.Delete(SessionId);

                  // Forward the packet to the client
                  Self.CommunicationChannel.SendTo(Buffer, BufferLen, AltAddress, AltPort);

                  if not(TConfiguration.GetAddressCacheDisabled) then begin

                    // Put the item into the address cache
                    TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.Add(ArrivalTime, RequestHash, Buffer, BufferLen, True);

                    // Trace the event if a tracer is enabled
                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(AltAddress) + ':' + IntToStr(AltPort) + ' and put into the address cache as negative.');

                  end else begin

                    // Trace the event if a tracer is enabled
                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(AltAddress) + ':' + IntToStr(AltPort) + ' as negative.');

                  end;

                  // Trace the event into the hit log if enabled
                  if THitLogger.IsEnabled and (Pos('R', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

                end else begin

                  // Trace the event if a tracer is enabled
                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' discarded as negative.');

                end;

              end;

            end;

          end else begin // The item has not been found in the session cache!

            // Trace the event if a tracer is enabled
            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' discarded because no session cache entry matched.');

          end;

        end else begin // The response is a failure

          // Trace the event if a tracer is enabled
          if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' discarded as failure.');

        end;

      end else begin // It's a spurious packet coming from the infinite

        // Trace the event if a tracer is enabled
        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Unexpected packet received from address ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) + '].');

      end;

    end else begin // It's a spurious packet coming from the infinite

      // Trace the event if a tracer is enabled
      if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Malformed packet received from address ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) + '].');

    end;

  finally

    Self.Lock.Release;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TDnsResolver.HandleLowPriorityOperations;
begin
  Self.Lock.Acquire;

  try

    // If enabled flush statistics to disk
    if TStatistics.IsEnabled then TStatistics.FlushStatisticsToDisk;

    // If enabled flush the hit log of any pending data
    if THitLogger.IsEnabled then THitLogger.FlushAllPendingHitsToDisk;

  finally

    Self.Lock.Release;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TDnsResolver.HandleTerminatedOperations;
begin
  Self.Lock.Acquire;

  try

    // If enabled flush statistics to disk
    if TStatistics.IsEnabled then TStatistics.FlushStatisticsToDisk;

    // If enabled flush the hit log of any pending data
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

      // Open and bind the socket
      Self.CommunicationChannel := TDualUdpCommunicationChannel.Create; Self.CommunicationChannel.Bind(TConfiguration.IsLocalIPv4BindingEnabled, TConfiguration.GetLocalIPv4BindingAddress, TConfiguration.GetLocalIPv4BindingPort, TConfiguration.IsLocalIPv6BindingEnabled, TConfiguration.GetLocalIPv6BindingAddress, TConfiguration.GetLocalIPv6BindingPort);

      try

        TMemoryManager.GetMemory(Buffer, MAX_DNS_BUFFER_LEN);
        TMemoryManager.GetMemory(Output, MAX_DNS_BUFFER_LEN);

        try

          repeat // Working cycle

            // If there is a packet available
            if Self.CommunicationChannel.ReceiveFrom(DNS_RESOLVER_MAX_BLOCK_TIME, MAX_DNS_BUFFER_LEN, Buffer, BufferLen, Address, Port) then begin

              // Try to handle it as a DNS request
              Self.HandleDnsRequest(Buffer, BufferLen, Output, OutputLen, Address, Port);

            end else begin

              // Good place for low priority operations here
              Self.HandleLowPriorityOperations;

            end;

          until Terminated;

          // We handle all final operations here
          Self.HandleTerminatedOperations;

        finally

          TMemoryManager.FreeMemory(Output, MAX_DNS_BUFFER_LEN);
          TMemoryManager.FreeMemory(Buffer, MAX_DNS_BUFFER_LEN);

        end;

      finally

        Self.CommunicationChannel.Free;

      end;

    finally

      Self.Lock.Free;

    end;

  except // In case of an exception

    // Trace the event if a tracer is enabled
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

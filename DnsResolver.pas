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
    public
      class function  GetInstance: TDnsResolver;
      class procedure StartInstance;
      class procedure StopInstance;
    private
      Lock: TCriticalSection;
    private
      CommunicationChannel: TDualUdpServerCommunicationChannel;
    public
      constructor Create;
      procedure   Execute; override;
      procedure   HandleDnsRequest(Buffer: Pointer; BufferLen: Integer; var Output: Pointer; var OutputLen: Integer; Address: TDualIPAddress; Port: Word);
      procedure   HandleDnsResponse(Buffer: Pointer; BufferLen: Integer; DnsServerIndex: Integer);
      procedure   HandleIdleTimeOperations;
      procedure   HandleTerminalOperations;
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
  AddressCache,
  Configuration,
  DnsForwarder,
  DnsProtocol,
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
  ArrivalTime: TDateTime; OriginalSessionId: Word; RequestHash: TMD5Digest; QueryType: Word; DomainName: String; IPv4Address: TIPv4Address; IPv6Address: TIPv6Address; RemappedSessionId: Word; DnsServerIndex: Integer; DnsServerConfiguration: TDnsServerConfiguration; Forwarded: Boolean;

begin

  ArrivalTime := Now;

  Self.Lock.Acquire;

  try

    if (BufferLen >= MIN_DNS_PACKET_LEN) and (BufferLen <= MAX_DNS_PACKET_LEN) then begin

      if TDualIPAddressUtility.IsLocalHost(Address) or TConfiguration.IsAllowedAddress(TDualIPAddressUtility.ToString(Address)) then begin

        OriginalSessionId := TDnsProtocolUtility.GetIdFromPacket(Buffer);

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', OriginalSessionId) + ' received from client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, True) + '].');

        TDnsProtocolUtility.GetDomainNameAndQueryTypeFromRequestPacket(Buffer, BufferLen, DomainName, QueryType);

        if (QueryType = DNS_QUERY_TYPE_A) then begin

          if THostsCache.FindFWHostsEntry(DomainName) then begin

            // Don't do anything, let the execution flow...

          end else if THostsCache.FindNXHostsEntry(DomainName) then begin

            TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' from hosts cache.');

            if THitLogger.IsEnabled and (Pos('H', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

            Exit;

          end else if THostsCache.FindIPv4HostsEntry(DomainName, IPv4Address) then begin

            TDnsProtocolUtility.BuildPositiveIPv4ResponsePacket(DomainName, QueryType, IPv4Address, TConfiguration.GetGeneratedDnsResponseTimeToLive, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' from hosts cache.');

            if THitLogger.IsEnabled and (Pos('H', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

            Exit;

          end else if THostsCache.FindIPv6HostsEntry(DomainName, IPv6Address) then begin

            TDnsProtocolUtility.BuildPositiveResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' from hosts cache.');

            if THitLogger.IsEnabled and (Pos('H', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

            Exit;

          end;

        end else if (QueryType = DNS_QUERY_TYPE_AAAA) then begin

          if THostsCache.FindFWHostsEntry(DomainName) then begin

            // Don't do anything, let the execution flow...

          end else if THostsCache.FindNXHostsEntry(DomainName) then begin

            TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' from hosts cache.');

            if THitLogger.IsEnabled and (Pos('H', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

            Exit;

          end else if THostsCache.FindIPv6HostsEntry(DomainName, IPv6Address) then begin

            TDnsProtocolUtility.BuildPositiveIPv6ResponsePacket(DomainName, QueryType, IPv6Address, TConfiguration.GetGeneratedDnsResponseTimeToLive, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' from hosts cache.');

            if THitLogger.IsEnabled and (Pos('H', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

            Exit;

          end else if THostsCache.FindIPv4HostsEntry(DomainName, IPv4Address) then begin

            TDnsProtocolUtility.BuildPositiveResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' from hosts cache.');

            if THitLogger.IsEnabled and (Pos('H', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'H', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

            Exit;

          end;

        end;

        TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); RequestHash := TMD5.Compute(Buffer, BufferLen); TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer);

        if TConfiguration.IsCacheException(DomainName) then begin

          TSessionCache.Reserve(ArrivalTime, OriginalSessionId, RemappedSessionId);

          TDnsProtocolUtility.SetIdIntoPacket(RemappedSessionId, Buffer);

          Forwarded := False;

          for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin

            DnsServerConfiguration := TConfiguration.GetDnsServerConfiguration(DnsServerIndex);

            if DnsServerConfiguration.IsEnabled then begin

              if TConfiguration.IsDomainNameAffinityMatch(DomainName, DnsServerConfiguration.DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, DnsServerConfiguration.QueryTypeAffinityMask) then begin

                if TDnsForwarder.ForwardDnsRequest(ArrivalTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, RemappedSessionId) then begin

                  Forwarded := True;

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' forwarded to server ' + IntToStr(DnsServerIndex + 1) + ' as cache exception.');

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' failed to be forwarded to server ' + IntToStr(DnsServerIndex + 1) + ' as cache exception.');

                end;

              end;

            end;

          end;

          if Forwarded then begin

            TSessionCache.Insert(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, False, True);

            if THitLogger.IsEnabled and (Pos('F', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'F', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'F', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

          end else begin

            TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

            TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' as negative.');

          end;

        end else begin

          if not(TConfiguration.GetAddressCacheDisabled) then begin

            case TAddressCache.Find(ArrivalTime, RequestHash, Output, OutputLen) of

              RecentEnough:

              begin

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' from address cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Output, OutputLen, True) + '].');

                if THitLogger.IsEnabled and (Pos('C', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'C', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'C', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

              end;

              NeedsUpdate:

              begin

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' from address cache [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Output, OutputLen, True) + '].');

                TSessionCache.Reserve(ArrivalTime, OriginalSessionId, RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(RemappedSessionId, Buffer);

                Forwarded := False;

                for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin

                  DnsServerConfiguration := TConfiguration.GetDnsServerConfiguration(DnsServerIndex);

                  if DnsServerConfiguration.IsEnabled then begin

                    if TConfiguration.IsDomainNameAffinityMatch(DomainName, DnsServerConfiguration.DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, DnsServerConfiguration.QueryTypeAffinityMask) then begin

                      if TDnsForwarder.ForwardDnsRequest(ArrivalTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, RemappedSessionId) then begin

                        Forwarded := True;

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' forwarded to server ' + IntToStr(DnsServerIndex + 1) + ' as silent update.');

                      end else begin

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' failed to be forwarded to server ' + IntToStr(DnsServerIndex + 1) + ' as silent update.');

                      end;

                    end;

                  end;

                end;

                if Forwarded then begin

                  TSessionCache.Insert(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, True, False);

                  if THitLogger.IsEnabled and (Pos('C', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'C', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'C', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

                end;

              end;

              NotFound:

              begin

                TSessionCache.Reserve(ArrivalTime, OriginalSessionId, RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(RemappedSessionId, Buffer);

                Forwarded := False;

                for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin

                  DnsServerConfiguration := TConfiguration.GetDnsServerConfiguration(DnsServerIndex);

                  if DnsServerConfiguration.IsEnabled then begin

                    if TConfiguration.IsDomainNameAffinityMatch(DomainName, DnsServerConfiguration.DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, DnsServerConfiguration.QueryTypeAffinityMask) then begin

                      if TDnsForwarder.ForwardDnsRequest(ArrivalTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, RemappedSessionId) then begin

                        Forwarded := True;

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' forwarded to server ' + IntToStr(DnsServerIndex + 1) + '.');

                      end else begin

                        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' failed to be forwarded to server ' + IntToStr(DnsServerIndex + 1) + '.');

                      end;

                    end;

                  end;

                end;

                if Forwarded then begin

                  TSessionCache.Insert(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, False, False);

                  if THitLogger.IsEnabled and (Pos('F', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'F', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'F', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

                end else begin

                  TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

                  TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' as negative.');

                end;

              end;

            end;

          end else begin

            TSessionCache.Reserve(ArrivalTime, OriginalSessionId, RemappedSessionId);

            TDnsProtocolUtility.SetIdIntoPacket(RemappedSessionId, Buffer);

            Forwarded := False;

            for DnsServerIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin

              DnsServerConfiguration := TConfiguration.GetDnsServerConfiguration(DnsServerIndex);

              if DnsServerConfiguration.IsEnabled then begin

                if TConfiguration.IsDomainNameAffinityMatch(DomainName, DnsServerConfiguration.DomainNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, DnsServerConfiguration.QueryTypeAffinityMask) then begin

                  if TDnsForwarder.ForwardDnsRequest(ArrivalTime, DnsServerIndex, DnsServerConfiguration, Buffer, BufferLen, RemappedSessionId) then begin

                    Forwarded := True;

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' forwarded to server ' + IntToStr(DnsServerIndex + 1) + '.');

                  end else begin

                    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Request ID ' + FormatCurr('00000', OriginalSessionId) + '>' + FormatCurr('00000', RemappedSessionId) + ' failed to be forwarded to server ' + IntToStr(DnsServerIndex + 1) + '.');

                  end;

                end;

              end;

            end;

            if Forwarded then begin

              TSessionCache.Insert(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, False, False);

              if THitLogger.IsEnabled and (Pos('F', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'F', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'F', Address, TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

            end else begin

              TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName, QueryType, Output, OutputLen);

              TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Output); Self.CommunicationChannel.SendTo(Output, OutputLen, Address, Port);

              if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' as negative.');

            end;

          end;

        end;

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Unexpected packet received from address ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) + '].');

      end;

    end else begin

      if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Malformed packet received from address ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) + '].');

    end;

  finally

    Self.Lock.Release;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TDnsResolver.HandleDnsResponse(Buffer: Pointer; BufferLen: Integer; DnsServerIndex: Integer);

var
  ArrivalTime: TDateTime; DnsServerConfiguration: TDnsServerConfiguration; RemappedSessionId: Word; OriginalSessionId: Word; Address: TDualIPAddress; Port: Word; RequestHash: TMD5Digest; IsSilentUpdate: Boolean; IsCacheException: Boolean;

begin

  ArrivalTime := Now;

  Self.Lock.Acquire;

  try

    if (BufferLen >= MIN_DNS_PACKET_LEN) and (BufferLen <= MAX_DNS_PACKET_LEN) then begin

      DnsServerConfiguration := TConfiguration.GetDnsServerConfiguration(DnsServerIndex);

      RemappedSessionId := TDnsProtocolUtility.GetIdFromPacket(Buffer);

      if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', RemappedSessionId) + ' received from server ' + IntToStr(DnsServerIndex + 1) + ' [' + TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, True) + '].');

      if TSessionCache.Extract(ArrivalTime, OriginalSessionId, RemappedSessionId, RequestHash, Address, Port, IsSilentUpdate, IsCacheException) then begin

        if IsCacheException then begin

          if not(TDnsProtocolUtility.IsFailureResponsePacket(Buffer, BufferLen)) then begin

            if not(TDnsProtocolUtility.IsNegativeResponsePacket(Buffer, BufferLen)) then begin

              TSessionCache.Delete(RemappedSessionId);

              TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); Self.CommunicationChannel.SendTo(Buffer, BufferLen, Address, Port);

              if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' as positive.');

              if THitLogger.IsEnabled and (Pos('R', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

            end else begin

              if not(DnsServerConfiguration.IgnoreNegativeResponsesFromServer) then begin

                TSessionCache.Delete(RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); Self.CommunicationChannel.SendTo(Buffer, BufferLen, Address, Port);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' as negative.');

                if THitLogger.IsEnabled and (Pos('R', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

              end else begin

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' discarded as negative.');

              end;

            end;

          end else begin

            if not(DnsServerConfiguration.IgnoreFailureResponsesFromServer) then begin

              TSessionCache.Delete(RemappedSessionId);

              TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); Self.CommunicationChannel.SendTo(Buffer, BufferLen, Address, Port);

              if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' as failure.');

              if THitLogger.IsEnabled and (Pos('R', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

            end else begin

              if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' discarded as failure.');

            end;

          end;

        end else if IsSilentUpdate then begin

          if not(TDnsProtocolUtility.IsFailureResponsePacket(Buffer, BufferLen)) then begin

            if not(TDnsProtocolUtility.IsNegativeResponsePacket(Buffer, BufferLen)) then begin

              TSessionCache.Delete(RemappedSessionId);

              if not(TConfiguration.GetAddressCacheDisabled) and (TConfiguration.GetAddressCacheScavengingTime > 0) then begin

                TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.Add(ArrivalTime, RequestHash, Buffer, BufferLen, AddressCacheItemOptionsResponseTypeIsPositive);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' put into the address cache as positive silent update.');

              end;

              if THitLogger.IsEnabled and (Pos('U', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'U', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'U', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

            end else begin

              if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' discarded as negative silent update.');

            end;

          end else begin

            if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' discarded as failure silent update.');

          end;

        end else begin

          if not(TDnsProtocolUtility.IsFailureResponsePacket(Buffer, BufferLen)) then begin

            if not(TDnsProtocolUtility.IsNegativeResponsePacket(Buffer, BufferLen)) then begin

              TSessionCache.Delete(RemappedSessionId);

              TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); Self.CommunicationChannel.SendTo(Buffer, BufferLen, Address, Port);

              if not(TConfiguration.GetAddressCacheDisabled) and (TConfiguration.GetAddressCacheScavengingTime > 0) then begin

                TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.Add(ArrivalTime, RequestHash, Buffer, BufferLen, AddressCacheItemOptionsResponseTypeIsPositive);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' and put into the address cache as positive.');

              end else begin

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' as positive.');

              end;

              if THitLogger.IsEnabled and (Pos('R', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

            end else begin

              if not(DnsServerConfiguration.IgnoreNegativeResponsesFromServer) then begin

                TSessionCache.Delete(RemappedSessionId);

                TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); Self.CommunicationChannel.SendTo(Buffer, BufferLen, Address, Port);

                if not(TConfiguration.GetAddressCacheDisabled) and (TConfiguration.GetAddressCacheNegativeTime > 0) then begin

                  TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.Add(ArrivalTime, RequestHash, Buffer, BufferLen, AddressCacheItemOptionsResponseTypeIsNegative);

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' and put into the address cache as negative.');

                end else begin

                  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' as negative.');

                end;

                if THitLogger.IsEnabled and (Pos('R', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

              end else begin

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' discarded as negative.');

              end;

            end;

          end else begin

            if not(DnsServerConfiguration.IgnoreFailureResponsesFromServer) then begin

              TSessionCache.Delete(RemappedSessionId);

              TDnsProtocolUtility.SetIdIntoPacket(OriginalSessionId, Buffer); Self.CommunicationChannel.SendTo(Buffer, BufferLen, Address, Port);

              if not(TConfiguration.GetAddressCacheDisabled) and (TConfiguration.GetAddressCacheFailureTime > 0) then begin

                TDnsProtocolUtility.SetIdIntoPacket(0, Buffer); TAddressCache.Add(ArrivalTime, RequestHash, Buffer, BufferLen, AddressCacheItemOptionsResponseTypeIsFailure);

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' and put into the address cache as failure.');

              end else begin

                if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' sent to client ' + TDualIPAddressUtility.ToString(Address) + ':' + IntToStr(Port) + ' as failure.');

              end;

              if THitLogger.IsEnabled and (Pos('R', TConfiguration.GetHitLogFileWhat) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Buffer, BufferLen, False)) else THitLogger.AddHit(ArrivalTime, 'R', Address, TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, False)); end;

            end else begin

              if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', RemappedSessionId) + '>' + FormatCurr('00000', OriginalSessionId) + ' discarded as failure.');

            end;

          end;

        end;

      end else begin

        if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Response ID ' + FormatCurr('00000', RemappedSessionId) + ' discarded as needless.');

      end;

    end else begin

      if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TDnsResolver.Execute: Malformed packet received from server ' + IntToStr(DnsServerIndex + 1) + ' [' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) + '].');

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

  if THitLogger.IsEnabled then begin

    Self.Lock.Acquire;

    try

      THitLogger.FlushAllPendingHitsToDisk(False, True);

    finally

      Self.Lock.Release;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TDnsResolver.HandleTerminalOperations;

begin

  if THitLogger.IsEnabled then begin

    Self.Lock.Acquire;

    try

      THitLogger.FlushAllPendingHitsToDisk(True, False);

    finally

      Self.Lock.Release;

    end;

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

      Self.CommunicationChannel := TDualUdpServerCommunicationChannel.Create;

      try

        Self.CommunicationChannel.Bind(TConfiguration.IsLocalIPv4BindingEnabled, TConfiguration.GetLocalIPv4BindingAddress, TConfiguration.GetLocalIPv4BindingPort, TConfiguration.IsLocalIPv6BindingEnabled, TConfiguration.GetLocalIPv6BindingAddress, TConfiguration.GetLocalIPv6BindingPort);

        try

          Buffer := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN);

          try

            Output := TMemoryManager.GetMemory(MAX_DNS_BUFFER_LEN);

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

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TDnsResolver.Execute: ' + E.Message);

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

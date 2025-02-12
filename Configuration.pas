// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  Configuration;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Classes,
  DnsProtocol,
  IPUtils;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  MAX_NUM_DNS_SERVERS = 10;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TDnsServerConfiguration = packed record
    IsEnabled: Boolean;
    DomainNameAffinityMask: TStringList;
    QueryTypeAffinityMask: TList;
    Address: TDualIPAddress;
    Port: Word;
    Protocol: TDnsProtocol;
    Socks5ProtocolProxyAddress: TDualIPAddress;
    Socks5ProtocolProxyPort: Word;
    DnsOverHttpsProtocolHost: String;
    DnsOverHttpsProtocolPath: String;
    DnsOverHttpsProtocolConnectionType: TDnsOverHttpsProtocolConnectionType;
    DnsOverHttpsProtocolReuseConnections: Boolean;
    DnsOverHttpsProtocolUseWinHttp: Boolean;
    IgnoreFailureResponsesFromServer: Boolean;
    IgnoreNegativeResponsesFromServer: Boolean;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TConfiguration = class
    public
      class function  MakeAbsolutePath(const Path: String): String;
    public
      class function  GetConfigurationFileName: String;
      class function  GetAddressCacheFileName: String;
      class function  GetHostsCacheFileName: String;
      class function  GetDebugLogFileName: String;
    public
      class function  GetDnsServerConfiguration(Index: Integer): TDnsServerConfiguration;
    public
      class function  GetSinkholeIPv6Lookups: Boolean;
      class function  GetForwardPrivateReverseLookups: Boolean;
    public
      class function  GetAddressCacheFailureTime: Integer;
      class function  GetAddressCacheNegativeTime: Integer;
      class function  GetAddressCacheScavengingTime: Integer;
      class function  GetAddressCacheSilentUpdateTime: Integer;
      class function  GetAddressCachePeriodicPruningTime: Integer;
      class function  GetAddressCacheDomainNameAffinityMask: TStringList;
      class function  GetAddressCacheQueryTypeAffinityMask: TList;
      class function  GetAddressCacheInMemoryOnly: Boolean;
      class function  GetAddressCacheDisabled: Boolean;
    public
      class function  IsLocalIPv4BindingEnabled: Boolean;
    public
      class function  GetLocalIPv4BindingAddress: TIPv4Address;
      class function  GetLocalIPv4BindingPort: Word;
    public
      class function  IsLocalIPv6BindingEnabled: Boolean;
    public
      class function  GetLocalIPv6BindingAddress: TIPv6Address;
      class function  GetLocalIPv6BindingPort: Word;
    public
      class function  GetGeneratedDnsResponseTimeToLive: Integer;
    public
      class function  GetServerUdpProtocolResponseTimeout: Integer;
      class function  GetServerTcpProtocolResponseTimeout: Integer;
      class function  GetServerTcpProtocolInternalTimeout: Integer;
      class function  GetServerSocks5ProtocolProxyFirstByteTimeout: Integer;
      class function  GetServerSocks5ProtocolProxyOtherBytesTimeout: Integer;
      class function  GetServerSocks5ProtocolProxyRemoteConnectTimeout: Integer;
      class function  GetServerSocks5ProtocolProxyRemoteResponseTimeout: Integer;
    public
      class function  IsDomainNameAffinityMatch(const DomainName: String; DomainNameAffinityMask: TStringList): Boolean;
      class function  IsQueryTypeAffinityMatch(QueryType: Word; QueryTypeAffinityMask: TList): Boolean;
    public
      class function  IsAllowedAddress(const Value: String): Boolean;
    public
      class procedure Initialize;
      class procedure LoadFromFile(const FileName: String);
      class procedure Finalize;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  IniFiles,
  SysUtils,
  CommonUtils,
  DnsOverHttpsCache,
  Environment,
  HitLogger,
  PatternMatching,
  Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_ConfigurationFileName: String;
  TConfiguration_AddressCacheFileName: String;
  TConfiguration_HostsCacheFileName: String;
  TConfiguration_DebugLogFileName: String;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  DNS_SERVER_INDEX_DESCRIPTION: Array [0..(MAX_NUM_DNS_SERVERS - 1)] of String = ('Primary', 'Secondary', 'Tertiary', 'Quaternary', 'Quinary', 'Senary', 'Septenary', 'Octonary', 'Nonary', 'Denary');

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_DnsServerConfiguration: Array [0..(MAX_NUM_DNS_SERVERS - 1)] of TDnsServerConfiguration;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_SinkholeIPv6Lookups: Boolean;
  TConfiguration_ForwardPrivateReverseLookups: Boolean;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_AddressCacheFailureTime: Integer;
  TConfiguration_AddressCacheNegativeTime: Integer;
  TConfiguration_AddressCacheScavengingTime: Integer;
  TConfiguration_AddressCacheSilentUpdateTime: Integer;
  TConfiguration_AddressCachePeriodicPruningTime: Integer;
  TConfiguration_AddressCacheDomainNameAffinityMask: TStringList;
  TConfiguration_AddressCacheQueryTypeAffinityMask: TList;
  TConfiguration_AddressCacheInMemoryOnly: Boolean;
  TConfiguration_AddressCacheDisabled: Boolean;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_IsLocalIPv4BindingEnabled: Boolean;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_LocalIPv4BindingAddress: TIPv4Address;
  TConfiguration_LocalIPv4BindingPort: Word;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_IsLocalIPv6BindingEnabled: Boolean;
  TConfiguration_IsLocalIPv6BindingEnabledOnWindowsVersionsPriorToWindowsVistaOrWindowsServer2008: Boolean;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_LocalIPv6BindingAddress: TIPv6Address;
  TConfiguration_LocalIPv6BindingPort: Word;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_GeneratedDnsResponseTimeToLive: Integer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_ServerUdpProtocolResponseTimeout: Integer;
  TConfiguration_ServerTcpProtocolResponseTimeout: Integer;
  TConfiguration_ServerTcpProtocolInternalTimeout: Integer;
  TConfiguration_ServerSocks5ProtocolProxyFirstByteTimeout: Integer;
  TConfiguration_ServerSocks5ProtocolProxyOtherBytesTimeout: Integer;
  TConfiguration_ServerSocks5ProtocolProxyRemoteConnectTimeout: Integer;
  TConfiguration_ServerSocks5ProtocolProxyRemoteResponseTimeout: Integer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_HitLogFileName: String;
  TConfiguration_HitLogFileWhat: String;
  TConfiguration_HitLogFullDump: Boolean;
  TConfiguration_HitLogMaxPendingHits: Integer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_AllowedAddresses: TStringList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TConfiguration.Initialize;

var
  i: Integer;

begin

  TConfiguration_ConfigurationFileName := Self.MakeAbsolutePath('AcrylicConfiguration.ini');
  TConfiguration_AddressCacheFileName := Self.MakeAbsolutePath('AcrylicCache.dat');
  TConfiguration_HostsCacheFileName := Self.MakeAbsolutePath('AcrylicHosts.txt');
  TConfiguration_DebugLogFileName := Self.MakeAbsolutePath('AcrylicDebug.txt');

  for i := 0 to (MAX_NUM_DNS_SERVERS - 1) do begin

    TConfiguration_DnsServerConfiguration[i].IsEnabled := False;
    TConfiguration_DnsServerConfiguration[i].DomainNameAffinityMask := nil;
    TConfiguration_DnsServerConfiguration[i].QueryTypeAffinityMask := nil;
    TConfiguration_DnsServerConfiguration[i].Address.IPv4Address := LOCALHOST_IPV4_ADDRESS;
    TConfiguration_DnsServerConfiguration[i].Address.IsIPv6Address := False;
    TConfiguration_DnsServerConfiguration[i].Port := 53;
    TConfiguration_DnsServerConfiguration[i].Protocol := UdpProtocol;
    TConfiguration_DnsServerConfiguration[i].Socks5ProtocolProxyAddress.IsIPv6Address := False;
    TConfiguration_DnsServerConfiguration[i].Socks5ProtocolProxyAddress.IPv4Address := LOCALHOST_IPV4_ADDRESS;
    TConfiguration_DnsServerConfiguration[i].Socks5ProtocolProxyPort := 9150;
    TConfiguration_DnsServerConfiguration[i].DnsOverHttpsProtocolConnectionType := SystemDnsOverHttpsProtocolConnectionType;
    TConfiguration_DnsServerConfiguration[i].DnsOverHttpsProtocolReuseConnections := True;
    TConfiguration_DnsServerConfiguration[i].DnsOverHttpsProtocolUseWinHttp := True;
    TConfiguration_DnsServerConfiguration[i].IgnoreFailureResponsesFromServer := False;
    TConfiguration_DnsServerConfiguration[i].IgnoreNegativeResponsesFromServer := False;

  end;

  TConfiguration_SinkholeIPv6Lookups := False;
  TConfiguration_ForwardPrivateReverseLookups := False;

  TConfiguration_AddressCacheFailureTime := 0;
  TConfiguration_AddressCacheNegativeTime := 60;
  TConfiguration_AddressCacheScavengingTime := 5760;
  TConfiguration_AddressCacheSilentUpdateTime := 1440;
  TConfiguration_AddressCachePeriodicPruningTime := 720;
  TConfiguration_AddressCacheDomainNameAffinityMask := nil;
  TConfiguration_AddressCacheQueryTypeAffinityMask := nil;
  TConfiguration_AddressCacheInMemoryOnly := False;
  TConfiguration_AddressCacheDisabled := False;

  TConfiguration_IsLocalIPv4BindingEnabled := False;

  TConfiguration_LocalIPv4BindingAddress := ANY_IPV4_ADDRESS;
  TConfiguration_LocalIPv4BindingPort := 53;

  TConfiguration_IsLocalIPv6BindingEnabled := False;
  TConfiguration_IsLocalIPv6BindingEnabledOnWindowsVersionsPriorToWindowsVistaOrWindowsServer2008 := False;

  TConfiguration_LocalIPv6BindingAddress := ANY_IPV6_ADDRESS;
  TConfiguration_LocalIPv6BindingPort := 53;

  TConfiguration_GeneratedDnsResponseTimeToLive := 60;

  TConfiguration_ServerUdpProtocolResponseTimeout := 3989;
  TConfiguration_ServerTcpProtocolResponseTimeout := 3989;
  TConfiguration_ServerTcpProtocolInternalTimeout := 3989;
  TConfiguration_ServerSocks5ProtocolProxyFirstByteTimeout := 3989;
  TConfiguration_ServerSocks5ProtocolProxyOtherBytesTimeout := 3989;
  TConfiguration_ServerSocks5ProtocolProxyRemoteConnectTimeout := 3989;
  TConfiguration_ServerSocks5ProtocolProxyRemoteResponseTimeout := 3989;

  TConfiguration_HitLogFileName := '';
  TConfiguration_HitLogFileWhat := '';
  TConfiguration_HitLogFullDump := False;
  TConfiguration_HitLogMaxPendingHits := 256;

  TConfiguration_AllowedAddresses := nil;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.MakeAbsolutePath(const Path: String): String;

begin

  if (Pos('\', Path) > 0) then Result := Path else Result := ExtractFilePath(ParamStr(0)) + Path;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetConfigurationFileName: String;

begin

  Result := TConfiguration_ConfigurationFileName;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetAddressCacheFileName: String;

begin

  Result := TConfiguration_AddressCacheFileName;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetHostsCacheFileName: String;

begin

  Result := TConfiguration_HostsCacheFileName;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetDebugLogFileName: String;

begin

  Result := TConfiguration_DebugLogFileName;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetDnsServerConfiguration(Index: Integer): TDnsServerConfiguration;

begin

  Result := TConfiguration_DnsServerConfiguration[Index];

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetSinkholeIPv6Lookups: Boolean;

begin

  Result := TConfiguration_SinkholeIPv6Lookups;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetForwardPrivateReverseLookups: Boolean;

begin

  Result := TConfiguration_ForwardPrivateReverseLookups;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetAddressCacheFailureTime: Integer;

begin

  Result := TConfiguration_AddressCacheFailureTime;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetAddressCacheNegativeTime: Integer;

begin

  Result := TConfiguration_AddressCacheNegativeTime;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetAddressCacheScavengingTime: Integer;

begin

  Result := TConfiguration_AddressCacheScavengingTime;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetAddressCacheSilentUpdateTime: Integer;

begin

  Result := TConfiguration_AddressCacheSilentUpdateTime;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetAddressCachePeriodicPruningTime: Integer;

begin

  Result := TConfiguration_AddressCachePeriodicPruningTime;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetAddressCacheDomainNameAffinityMask: TStringList;

begin

  Result := TConfiguration_AddressCacheDomainNameAffinityMask;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetAddressCacheQueryTypeAffinityMask: TList;

begin

  Result := TConfiguration_AddressCacheQueryTypeAffinityMask;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetAddressCacheInMemoryOnly: Boolean;

begin

  Result := TConfiguration_AddressCacheInMemoryOnly;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetAddressCacheDisabled: Boolean;

begin

  Result := TConfiguration_AddressCacheDisabled;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.IsLocalIPv4BindingEnabled: Boolean;

begin

  Result := TConfiguration_IsLocalIPv4BindingEnabled;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetLocalIPv4BindingAddress: TIPv4Address;

begin

  Result := TConfiguration_LocalIPv4BindingAddress;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetLocalIPv4BindingPort: Word;

begin

  Result := TConfiguration_LocalIPv4BindingPort;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.IsLocalIPv6BindingEnabled: Boolean;

begin

  Result := TConfiguration_IsLocalIPv6BindingEnabled;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetLocalIPv6BindingAddress: TIPv6Address;

begin

  Result := TConfiguration_LocalIPv6BindingAddress;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetLocalIPv6BindingPort: Word;

begin

  Result := TConfiguration_LocalIPv6BindingPort;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetGeneratedDnsResponseTimeToLive: Integer;

begin

  Result := TConfiguration_GeneratedDnsResponseTimeToLive;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetServerUdpProtocolResponseTimeout: Integer;

begin

  Result := TConfiguration_ServerUdpProtocolResponseTimeout;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetServerTcpProtocolResponseTimeout: Integer;

begin

  Result := TConfiguration_ServerTcpProtocolResponseTimeout;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetServerTcpProtocolInternalTimeout: Integer;

begin

  Result := TConfiguration_ServerTcpProtocolInternalTimeout;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetServerSocks5ProtocolProxyFirstByteTimeout: Integer;

begin

  Result := TConfiguration_ServerSocks5ProtocolProxyFirstByteTimeout;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetServerSocks5ProtocolProxyOtherBytesTimeout: Integer;

begin

  Result := TConfiguration_ServerSocks5ProtocolProxyOtherBytesTimeout;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetServerSocks5ProtocolProxyRemoteConnectTimeout: Integer;

begin

  Result := TConfiguration_ServerSocks5ProtocolProxyRemoteConnectTimeout;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetServerSocks5ProtocolProxyRemoteResponseTimeout: Integer;

begin

  Result := TConfiguration_ServerSocks5ProtocolProxyRemoteResponseTimeout;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.IsDomainNameAffinityMatch(const DomainName: String; DomainNameAffinityMask: TStringList): Boolean;

var
  i: Integer; S: String;

begin

  if (DomainNameAffinityMask <> nil) then begin

    for i := 0 to (DomainNameAffinityMask.Count - 1) do begin

      S := DomainNameAffinityMask[i];

      if (S[1] = '^') then begin
        if TPatternMatching.Match(PChar(DomainName), PChar(Copy(S, 2, Length(S) - 1))) then begin Result := False; Exit; end;
      end else begin
        if TPatternMatching.Match(PChar(DomainName), PChar(S)) then begin Result := True; Exit; end;
      end;

    end;

    Result := False;

  end else begin

    Result := True;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.IsQueryTypeAffinityMatch(QueryType: Word; QueryTypeAffinityMask: TList): Boolean;

begin

  Result := (QueryTypeAffinityMask = nil) or (QueryTypeAffinityMask.IndexOf(Pointer(QueryType)) > -1);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.IsAllowedAddress(const Value: String): Boolean;

var
  i: Integer; S: String;

begin

  Result := False;

  if (TConfiguration_AllowedAddresses <> nil) then begin

    for i := 0 to (TConfiguration_AllowedAddresses.Count - 1) do begin

      S := TConfiguration_AllowedAddresses.Strings[i];

      if TPatternMatching.Match(PChar(Value), PChar(S)) then begin Result := True; Exit; end;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TConfiguration.LoadFromFile(const FileName: String);

var
  IniFile: TMemIniFile; StringList: TStringList; DnsServerIndex: Integer; DnsServerAddress: TDualIPAddress; i: Integer; S: String; W: Word;

begin

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TConfiguration.LoadFromFile: Loading configuration file...');

  IniFile := TMemIniFile.Create(FileName); try

    if TTracer.IsEnabled then begin

      StringList := TStringList.Create;

      IniFile.ReadSectionValues('GlobalSection', StringList); if (StringList.Count > 0) then begin
        for i := 0 to (StringList.Count - 1) do begin
          if (StringList[i] <> '') then begin
            TTracer.Trace(TracePriorityInfo, 'TConfiguration.LoadFromFile: [GlobalSection] ' + StringList[i]);
          end;
        end;
      end;

      StringList.Free;

      StringList := TStringList.Create;

      IniFile.ReadSectionValues('AllowedAddressesSection', StringList); if (StringList.Count > 0) then begin
        for i := 0 to (StringList.Count - 1) do begin
          if (StringList[i] <> '') then begin
            TTracer.Trace(TracePriorityInfo, 'TConfiguration.LoadFromFile: [AllowedAddressesSection] ' + StringList[i]);
          end;
        end;
      end;

      StringList.Free;

    end;

    for DnsServerIndex := 0 to (MAX_NUM_DNS_SERVERS - 1) do begin

      TConfiguration_DnsServerConfiguration[DnsServerIndex].IsEnabled := False;

      S := IniFile.ReadString('GlobalSection', DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'ServerAddress', ''); if (S <> '') then begin

        DnsServerAddress := TDualIPAddressUtility.Parse(S);

        TConfiguration_DnsServerConfiguration[DnsServerIndex].Address := DnsServerAddress;

        S := IniFile.ReadString('GlobalSection', DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'ServerPort', ''); if (S <> '') then begin

          TConfiguration_DnsServerConfiguration[DnsServerIndex].Port := StrToInt(S);

          S := IniFile.ReadString('GlobalSection', DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'ServerProtocol', ''); if (S <> '') then begin

            TConfiguration_DnsServerConfiguration[DnsServerIndex].Protocol := TDnsProtocolUtility.ParseDnsProtocol(S);

            TConfiguration_DnsServerConfiguration[DnsServerIndex].IsEnabled := True;

            if (TConfiguration_DnsServerConfiguration[DnsServerIndex].Protocol = Socks5Protocol) then begin

              S := IniFile.ReadString('GlobalSection', DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'ServerSocks5ProtocolProxyAddress', ''); if (S <> '') then begin

                TConfiguration_DnsServerConfiguration[DnsServerIndex].Socks5ProtocolProxyAddress := TDualIPAddressUtility.Parse(S);

                S := IniFile.ReadString('GlobalSection', DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'ServerSocks5ProtocolProxyPort', ''); if (S <> '') then begin

                  TConfiguration_DnsServerConfiguration[DnsServerIndex].Socks5ProtocolProxyPort := StrToInt(S);

                end;

              end else begin

                S := IniFile.ReadString('GlobalSection', DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'ServerProxyAddress', ''); if (S <> '') then begin

                  TConfiguration_DnsServerConfiguration[DnsServerIndex].Socks5ProtocolProxyAddress := TDualIPAddressUtility.Parse(S);

                  S := IniFile.ReadString('GlobalSection', DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'ServerProxyPort', ''); if (S <> '') then begin

                    TConfiguration_DnsServerConfiguration[DnsServerIndex].Socks5ProtocolProxyPort := StrToInt(S);

                  end;

                end;

              end;

            end else if (TConfiguration_DnsServerConfiguration[DnsServerIndex].Protocol = DnsOverHttpsProtocol) then begin

              S := IniFile.ReadString('GlobalSection', DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'ServerDoHProtocolHost', ''); if (S <> '') then begin

                TConfiguration_DnsServerConfiguration[DnsServerIndex].DnsOverHttpsProtocolHost := S;

              end;

              S := IniFile.ReadString('GlobalSection', DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'ServerDoHProtocolPath', ''); if (S <> '') then begin

                TConfiguration_DnsServerConfiguration[DnsServerIndex].DnsOverHttpsProtocolPath := S;

              end;

              S := IniFile.ReadString('GlobalSection', DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'ServerDoHProtocolConnectionType', ''); if (S <> '') then begin

                TConfiguration_DnsServerConfiguration[DnsServerIndex].DnsOverHttpsProtocolConnectionType := TDnsProtocolUtility.ParseDnsOverHttpsProtocolConnectionType(S);

              end;

              TConfiguration_DnsServerConfiguration[DnsServerIndex].DnsOverHttpsProtocolReuseConnections := CommonUtils.StringToBoolean(IniFile.ReadString('GlobalSection', DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'ServerDoHProtocolReuseConnections', 'YES'));

              TConfiguration_DnsServerConfiguration[DnsServerIndex].DnsOverHttpsProtocolUseWinHttp := CommonUtils.StringToBoolean(IniFile.ReadString('GlobalSection', DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'ServerDoHProtocolUseWinHttp', 'YES'));

              if DnsServerAddress.IsIPv6Address then TDnsOverHttpsCache.AddIPv6Item(TConfiguration_DnsServerConfiguration[DnsServerIndex].DnsOverHttpsProtocolHost, DnsServerAddress.IPv6Address) else TDnsOverHttpsCache.AddIPv4Item(TConfiguration_DnsServerConfiguration[DnsServerIndex].DnsOverHttpsProtocolHost, DnsServerAddress.IPv4Address);

            end;

            S := IniFile.ReadString('GlobalSection', DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'ServerDomainNameAffinityMask', ''); if (S <> '') then begin

              StringList := TStringList.Create; StringList.Delimiter := ';'; StringList.DelimitedText := S;

              if (StringList.Count > 0) then begin
                for i := 0 to (StringList.Count - 1) do begin
                  if (StringList[i] <> '') then begin
                    if (TConfiguration_DnsServerConfiguration[DnsServerIndex].DomainNameAffinityMask = nil) then TConfiguration_DnsServerConfiguration[DnsServerIndex].DomainNameAffinityMask := TStringList.Create; TConfiguration_DnsServerConfiguration[DnsServerIndex].DomainNameAffinityMask.Add(StringList[i]);
                  end;
                end;
              end;

              StringList.Free;

            end;

            S := IniFile.ReadString('GlobalSection', DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'ServerQueryTypeAffinityMask', ''); if (S <> '') then begin

              StringList := TStringList.Create; StringList.Delimiter := ';'; StringList.DelimitedText := S;

              if (StringList.Count > 0) then begin
                for i := 0 to (StringList.Count - 1) do begin
                  if (StringList[i] <> '') then begin
                    W := TDnsProtocolUtility.ParseDnsQueryType(StringList[i]); if (W > 0) then begin
                      if (TConfiguration_DnsServerConfiguration[DnsServerIndex].QueryTypeAffinityMask = nil) then TConfiguration_DnsServerConfiguration[DnsServerIndex].QueryTypeAffinityMask := TList.Create; TConfiguration_DnsServerConfiguration[DnsServerIndex].QueryTypeAffinityMask.Add(Pointer(W));
                    end;
                  end;
                end;
              end;

              StringList.Free;

            end;

            TConfiguration_DnsServerConfiguration[DnsServerIndex].IgnoreFailureResponsesFromServer := CommonUtils.StringToBoolean(IniFile.ReadString('GlobalSection', 'IgnoreFailureResponsesFrom' + DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'Server', ''));
            TConfiguration_DnsServerConfiguration[DnsServerIndex].IgnoreNegativeResponsesFromServer := CommonUtils.StringToBoolean(IniFile.ReadString('GlobalSection', 'IgnoreNegativeResponsesFrom' + DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'Server', ''));

          end;

        end;

      end;

    end;

    TConfiguration_SinkholeIPv6Lookups := CommonUtils.StringToBoolean(IniFile.ReadString('GlobalSection', 'SinkholeIPv6Lookups', ''));
    TConfiguration_ForwardPrivateReverseLookups := CommonUtils.StringToBoolean(IniFile.ReadString('GlobalSection', 'ForwardPrivateReverseLookups', ''));

    TConfiguration_AddressCacheFailureTime := IniFile.ReadInteger('GlobalSection', 'AddressCacheFailureTime', TConfiguration_AddressCacheFailureTime);
    TConfiguration_AddressCacheNegativeTime := IniFile.ReadInteger('GlobalSection', 'AddressCacheNegativeTime', TConfiguration_AddressCacheNegativeTime);
    TConfiguration_AddressCacheScavengingTime := IniFile.ReadInteger('GlobalSection', 'AddressCacheScavengingTime', TConfiguration_AddressCacheScavengingTime);
    TConfiguration_AddressCacheSilentUpdateTime := IniFile.ReadInteger('GlobalSection', 'AddressCacheSilentUpdateTime', TConfiguration_AddressCacheSilentUpdateTime);
    TConfiguration_AddressCachePeriodicPruningTime := IniFile.ReadInteger('GlobalSection', 'AddressCachePeriodicPruningTime', TConfiguration_AddressCachePeriodicPruningTime);

    S := IniFile.ReadString('GlobalSection', 'AddressCacheDomainNameAffinityMask', ''); if (S <> '') then begin

      StringList := TStringList.Create; StringList.Delimiter := ';'; StringList.DelimitedText := S;

        if (StringList.Count > 0) then begin
          for i := 0 to (StringList.Count - 1) do begin
            if (StringList[i] <> '') then begin
              if (TConfiguration_AddressCacheDomainNameAffinityMask = nil) then TConfiguration_AddressCacheDomainNameAffinityMask := TStringList.Create; TConfiguration_AddressCacheDomainNameAffinityMask.Add(StringList[i]);
            end;
          end;
        end;

        StringList.Free;

    end;

    S := IniFile.ReadString('GlobalSection', 'AddressCacheQueryTypeAffinityMask', ''); if (S <> '') then begin

      StringList := TStringList.Create; StringList.Delimiter := ';'; StringList.DelimitedText := S;

        if (StringList.Count > 0) then begin
          for i := 0 to (StringList.Count - 1) do begin
            if (StringList[i] <> '') then begin
              W := TDnsProtocolUtility.ParseDnsQueryType(StringList[i]); if (W > 0) then begin
                if (TConfiguration_AddressCacheQueryTypeAffinityMask = nil) then TConfiguration_AddressCacheQueryTypeAffinityMask := TList.Create; TConfiguration_AddressCacheQueryTypeAffinityMask.Add(Pointer(W));
              end;
            end;
          end;
        end;

      StringList.Free;

    end;

    TConfiguration_AddressCacheInMemoryOnly := CommonUtils.StringToBoolean(IniFile.ReadString('GlobalSection', 'AddressCacheInMemoryOnly', ''));
    TConfiguration_AddressCacheDisabled := CommonUtils.StringToBoolean(IniFile.ReadString('GlobalSection', 'AddressCacheDisabled', ''));

    S := IniFile.ReadString('GlobalSection', 'LocalIPv4BindingAddress', ''); if (S <> '') then begin

      TConfiguration_IsLocalIPv4BindingEnabled := True;

      TConfiguration_LocalIPv4BindingAddress := TIPv4AddressUtility.Parse(S);

      TConfiguration_LocalIPv4BindingPort := StrToIntDef(IniFile.ReadString('GlobalSection', 'LocalIPv4BindingPort', IntToStr(TConfiguration_LocalIPv4BindingPort)), TConfiguration_LocalIPv4BindingPort);

    end;

    S := IniFile.ReadString('GlobalSection', 'LocalIPv6BindingAddress', ''); if (S <> '') then begin

      TConfiguration_IsLocalIPv6BindingEnabledOnWindowsVersionsPriorToWindowsVistaOrWindowsServer2008 := CommonUtils.StringToBoolean(IniFile.ReadString('GlobalSection', 'LocalIPv6BindingEnabledOnWindowsVersionsPriorToWindowsVistaOrWindowsServer2008', ''));

      if TEnvironment.IsWindowsVistaOrWindowsServer2008OrHigher or TConfiguration_IsLocalIPv6BindingEnabledOnWindowsVersionsPriorToWindowsVistaOrWindowsServer2008 then begin

        TConfiguration_IsLocalIPv6BindingEnabled := True;

        TConfiguration_LocalIPv6BindingAddress := TIPv6AddressUtility.Parse(S);

        TConfiguration_LocalIPv6BindingPort := StrToIntDef(IniFile.ReadString('GlobalSection', 'LocalIPv6BindingPort', IntToStr(TConfiguration_LocalIPv6BindingPort)), TConfiguration_LocalIPv6BindingPort);

      end;

    end;

    TConfiguration_GeneratedDnsResponseTimeToLive := IniFile.ReadInteger('GlobalSection', 'GeneratedResponseTimeToLive', TConfiguration_GeneratedDnsResponseTimeToLive);

    TConfiguration_ServerUdpProtocolResponseTimeout := IniFile.ReadInteger('GlobalSection', 'ServerUdpProtocolResponseTimeout', TConfiguration_ServerUdpProtocolResponseTimeout);
    TConfiguration_ServerTcpProtocolResponseTimeout := IniFile.ReadInteger('GlobalSection', 'ServerTcpProtocolResponseTimeout', TConfiguration_ServerTcpProtocolResponseTimeout);
    TConfiguration_ServerTcpProtocolInternalTimeout := IniFile.ReadInteger('GlobalSection', 'ServerTcpProtocolInternalTimeout', TConfiguration_ServerTcpProtocolInternalTimeout);
    TConfiguration_ServerSocks5ProtocolProxyFirstByteTimeout := IniFile.ReadInteger('GlobalSection', 'ServerSocks5ProtocolProxyFirstByteTimeout', TConfiguration_ServerSocks5ProtocolProxyFirstByteTimeout);
    TConfiguration_ServerSocks5ProtocolProxyOtherBytesTimeout := IniFile.ReadInteger('GlobalSection', 'ServerSocks5ProtocolProxyOtherBytesTimeout', TConfiguration_ServerSocks5ProtocolProxyOtherBytesTimeout);
    TConfiguration_ServerSocks5ProtocolProxyRemoteConnectTimeout := IniFile.ReadInteger('GlobalSection', 'ServerSocks5ProtocolProxyRemoteConnectTimeout', TConfiguration_ServerSocks5ProtocolProxyRemoteConnectTimeout);
    TConfiguration_ServerSocks5ProtocolProxyRemoteResponseTimeout := IniFile.ReadInteger('GlobalSection', 'ServerSocks5ProtocolProxyRemoteResponseTimeout', TConfiguration_ServerSocks5ProtocolProxyRemoteResponseTimeout);

    TConfiguration_HitLogFileName := IniFile.ReadString('GlobalSection', 'HitLogFileName', ''); if (TConfiguration_HitLogFileName <> '') then begin

      TConfiguration_HitLogFileName := Self.MakeAbsolutePath(TConfiguration_HitLogFileName);

      TConfiguration_HitLogFileWhat := IniFile.ReadString('GlobalSection', 'HitLogFileWhat', '');
      TConfiguration_HitLogFullDump := CommonUtils.StringToBoolean(IniFile.ReadString('GlobalSection', 'HitLogFullDump', ''));

      TConfiguration_HitLogMaxPendingHits := IniFile.ReadInteger('GlobalSection', 'HitLogMaxPendingHits', TConfiguration_HitLogMaxPendingHits);

      THitLogger.SetProperties(TConfiguration_HitLogFileName, TConfiguration_HitLogFileWhat, TConfiguration_HitLogFullDump, TConfiguration_HitLogMaxPendingHits);

    end;

    StringList := TStringList.Create;

    IniFile.ReadSection('AllowedAddressesSection', StringList); if (StringList.Count > 0) then begin
      TConfiguration_AllowedAddresses := TStringList.Create; for i := 0 to (StringList.Count - 1) do TConfiguration_AllowedAddresses.Add(Trim(IniFile.ReadString('AllowedAddressesSection', StringList.Strings[i], '')));
    end;

    StringList.Free;

  finally

    IniFile.Free;

  end;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TConfiguration.LoadFromFile: Configuration file loaded successfully.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TConfiguration.Finalize;

var
  i: Integer;

begin

  if (TConfiguration_AllowedAddresses <> nil) then TConfiguration_AllowedAddresses.Free;

  if (TConfiguration_AddressCacheQueryTypeAffinityMask <> nil) then TConfiguration_AddressCacheQueryTypeAffinityMask.Free;
  if (TConfiguration_AddressCacheDomainNameAffinityMask <> nil) then TConfiguration_AddressCacheDomainNameAffinityMask.Free;

  for i := 0 to (MAX_NUM_DNS_SERVERS - 1) do begin

    if (TConfiguration_DnsServerConfiguration[i].QueryTypeAffinityMask <> nil) then TConfiguration_DnsServerConfiguration[i].QueryTypeAffinityMask.Free;
    if (TConfiguration_DnsServerConfiguration[i].DomainNameAffinityMask <> nil) then TConfiguration_DnsServerConfiguration[i].DomainNameAffinityMask.Free;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
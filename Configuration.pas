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
  CommunicationChannels,
  DnsProtocol;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  MAX_NUM_DNS_SERVERS = 10;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TDnsServerConfiguration = record
    IsEnabled: Boolean;
    DomainNameAffinityMask: TStringList;
    QueryTypeAffinityMask: TList;
    Address: TDualIPAddress;
    Port: Word;
    Protocol: TDnsProtocol;
    ProxyAddress: TDualIPAddress;
    ProxyPort: Word;
    IgnoreNegativeResponsesFromServer: Boolean;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  THttpServerConfiguration = record
    IsEnabled: Boolean;
    BindingAddress: TIPv4Address;
    BindingPort: Word;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TConfiguration = class
    public
      class function  MakeAbsolutePath(Path: String): String;
    public
      class function  GetHitLogFileName: String;
      class function  GetHitLogFileWhat: String;
      class function  GetHitLogFileMode: String;
      class function  GetStatsLogFileName: String;
      class function  GetDebugLogFileName: String;
      class function  GetConfigurationFileName: String;
      class function  GetAddressCacheFileName: String;
      class function  GetHostsCacheFileName: String;
    public
      class function  GetDnsServerConfiguration(Index: Integer): TDnsServerConfiguration;
      class function  FindDnsServerConfiguration(Address: TDualIPAddress; Port: Word): Integer;
    public
      class function  GetAddressCacheDisabled: Boolean;
      class function  GetAddressCacheNegativeTime: Integer;
      class function  GetAddressCacheScavengingTime: Integer;
      class function  GetAddressCacheSilentUpdateTime: Integer;
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
      class function  GetHttpServerConfiguration: THttpServerConfiguration;
    public
      class function  IsDomainNameAffinityMatch(DomainName: String; DomainNameAffinityMask: TStringList): Boolean;
      class function  IsQueryTypeAffinityMatch(QueryType: Word; QueryTypeAffinityMask: TList): Boolean;
    public
      class function  IsAllowedAddress(Value: String): Boolean;
      class function  IsCacheException(Value: String): Boolean;
      class function  IsBlackException(Value: String): Boolean;
    public
      class procedure Initialize;
      class procedure LoadFromFile(FileName: String);
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
  Environment,
  PatternMatching,
  Tracer;

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
  TConfiguration_AddressCacheDisabled: Boolean;
  TConfiguration_AddressCacheNegativeTime: Integer;
  TConfiguration_AddressCacheScavengingTime: Integer;
  TConfiguration_AddressCacheSilentUpdateTime: Integer;

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
  TConfiguration_IsLocalIPv6BindingEnabledOnWindowsVersionsPriorToWindowsVistaOrWindowsServer2008: Boolean;
  TConfiguration_IsLocalIPv6BindingEnabled: Boolean;

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
  TConfiguration_HttpServerConfiguration: THttpServerConfiguration;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_CacheExceptions: TStringList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_WhiteExceptions: TStringList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_AllowedAddresses: TStringList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_HitLogFileName: String;
  TConfiguration_HitLogFileWhat: String;
  TConfiguration_HitLogFileMode: String;
  TConfiguration_StatsLogFileName: String;
  TConfiguration_DebugLogFileName: String;
  TConfiguration_ConfigurationFileName: String;
  TConfiguration_AddressCacheFileName: String;
  TConfiguration_HostsCacheFileName: String;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TConfiguration.Initialize;
var
  i: Integer;
begin
  for i := 0 to (MAX_NUM_DNS_SERVERS - 1) do begin
    TConfiguration_DnsServerConfiguration[i].IsEnabled := False;
    TConfiguration_DnsServerConfiguration[i].DomainNameAffinityMask := nil;
    TConfiguration_DnsServerConfiguration[i].QueryTypeAffinityMask := nil;
    TConfiguration_DnsServerConfiguration[i].Address.IPv4Address := LOCALHOST_IPV4_ADDRESS;
    TConfiguration_DnsServerConfiguration[i].Address.IsIPv6Address := False;
    TConfiguration_DnsServerConfiguration[i].Port := 8053;
    TConfiguration_DnsServerConfiguration[i].Protocol := UdpProtocol;
    TConfiguration_DnsServerConfiguration[i].ProxyAddress.IPv4Address := LOCALHOST_IPV4_ADDRESS;
    TConfiguration_DnsServerConfiguration[i].ProxyAddress.IsIPv6Address := False;
    TConfiguration_DnsServerConfiguration[i].ProxyPort := 9150;
    TConfiguration_DnsServerConfiguration[i].IgnoreNegativeResponsesFromServer := False;
  end;

  TConfiguration_AddressCacheDisabled := False;
  TConfiguration_AddressCacheNegativeTime := 10;
  TConfiguration_AddressCacheScavengingTime := 28800;
  TConfiguration_AddressCacheSilentUpdateTime := 1440;

  TConfiguration_IsLocalIPv4BindingEnabled := False;

  TConfiguration_LocalIPv4BindingAddress := ANY_IPV4_ADDRESS;
  TConfiguration_LocalIPv4BindingPort := 53;

  TConfiguration_IsLocalIPv6BindingEnabled := False;
  TConfiguration_IsLocalIPv6BindingEnabledOnWindowsVersionsPriorToWindowsVistaOrWindowsServer2008 := False;

  TConfiguration_LocalIPv6BindingAddress := ANY_IPV6_ADDRESS;
  TConfiguration_LocalIPv6BindingPort := 53;

  TConfiguration_GeneratedDnsResponseTimeToLive := 60;

  TConfiguration_HitLogFileName := '';
  TConfiguration_HitLogFileWhat := '';
  TConfiguration_HitLogFileMode := '';
  TConfiguration_StatsLogFileName := '';

  TConfiguration_HttpServerConfiguration.IsEnabled := False;

  TConfiguration_HttpServerConfiguration.BindingAddress := ANY_IPV4_ADDRESS;
  TConfiguration_HttpServerConfiguration.BindingPort := 80;

  TConfiguration_DebugLogFileName := Self.MakeAbsolutePath('AcrylicDebug.txt');
  TConfiguration_ConfigurationFileName := Self.MakeAbsolutePath('AcrylicConfiguration.ini');
  TConfiguration_AddressCacheFileName := Self.MakeAbsolutePath('AcrylicCache.dat');
  TConfiguration_HostsCacheFileName := Self.MakeAbsolutePath('AcrylicHosts.txt');

  TConfiguration_AllowedAddresses := nil;
  TConfiguration_CacheExceptions := nil;
  TConfiguration_WhiteExceptions := nil;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.MakeAbsolutePath(Path: String): String;
begin
  if (Pos('\', Path) > 0) then Result := Path else Result := ExtractFilePath(ParamStr(0)) + Path;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetHitLogFileName: String;
begin
  Result := TConfiguration_HitLogFileName;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetHitLogFileWhat: String;
begin
  Result := TConfiguration_HitLogFileWhat;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetHitLogFileMode: String;
begin
  Result := TConfiguration_HitLogFileMode;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetStatsLogFileName: String;
begin
  Result := TConfiguration_StatsLogFileName;
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

class function TConfiguration.GetDnsServerConfiguration(Index: Integer): TDnsServerConfiguration;
begin
  Result := TConfiguration_DnsServerConfiguration[Index];
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.FindDnsServerConfiguration(Address: TDualIPAddress; Port: Word): Integer;
var
  Index: Integer;
begin
  for Index := 0 to (MAX_NUM_DNS_SERVERS - 1) do begin
    if TConfiguration_DnsServerConfiguration[Index].IsEnabled and TDualIPAddressUtility.AreEqual(Address, TConfiguration_DnsServerConfiguration[Index].Address) then begin
      Result := Index; Exit;
    end;
  end; Result := -1;
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

class function TConfiguration.GetAddressCacheSilentUpdateTime: Integer;
begin
  Result := TConfiguration_AddressCacheSilentUpdateTime;
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

class function TConfiguration.GetAddressCacheNegativeTime: Integer;
begin
  Result := TConfiguration_AddressCacheNegativeTime;
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

class function TConfiguration.GetGeneratedDnsResponseTimeToLive: Integer;
begin
  Result := TConfiguration_GeneratedDnsResponseTimeToLive;
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

class function TConfiguration.GetHttpServerConfiguration: THttpServerConfiguration;
begin
  Result := TConfiguration_HttpServerConfiguration;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.IsDomainNameAffinityMatch(DomainName: String; DomainNameAffinityMask: TStringList): Boolean;
var
  i: Integer; S: String;
begin
  Result := True; if (DomainNameAffinityMask <> nil) and (DomainNameAffinityMask.Count > 0) then begin
    Result := False; for i := 0 to (DomainNameAffinityMask.Count - 1) do begin
      S := DomainNameAffinityMask[i]; if (S <> '') then begin
        if (S[1] = '^') then begin
          if TPatternMatching.Match(PChar(DomainName), PChar(Copy(S, 2, Length(S) - 1))) then begin Result := False; Exit; end;
        end else begin
          if TPatternMatching.Match(PChar(DomainName), PChar(S)) then begin Result := True; Exit; end;
        end;
      end;
    end;
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.IsQueryTypeAffinityMatch(QueryType: Word; QueryTypeAffinityMask: TList): Boolean;
begin
  Result := True; if (QueryTypeAffinityMask <> nil) and (QueryTypeAffinityMask.Count > 0) then begin
    Result := QueryTypeAffinityMask.IndexOf(Pointer(QueryType)) > -1;
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.IsAllowedAddress(Value: String): Boolean;
var
  i: Integer; S: String;
begin
  Result := False; if (TConfiguration_AllowedAddresses <> nil) and (TConfiguration_AllowedAddresses.Count > 0) then begin
    for i := 0 to (TConfiguration_AllowedAddresses.Count - 1) do begin
      S := TConfiguration_AllowedAddresses.Strings[i]; if (S <> '') and TPatternMatching.Match(PChar(Value), PChar(S)) then begin Result := True; Exit; end;
    end;
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.IsCacheException(Value: String): Boolean;
var
  i: Integer; S: String;
begin
  Result := False; if (TConfiguration_CacheExceptions <> nil) and (TConfiguration_CacheExceptions.Count > 0) then begin
    for i := 0 to (TConfiguration_CacheExceptions.Count - 1) do begin
      S := TConfiguration_CacheExceptions.Strings[i]; if (S <> '') and TPatternMatching.Match(PChar(Value), PChar(S)) then begin Result := True; Exit; end;
    end;
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.IsBlackException(Value: String): Boolean;
var
  i: Integer; S: String;
begin
  Result := False; if (TConfiguration_WhiteExceptions <> nil) and (TConfiguration_WhiteExceptions.Count > 0) then begin
    Result := True; for i := 0 to (TConfiguration_WhiteExceptions.Count - 1) do begin
      S := TConfiguration_WhiteExceptions.Strings[i]; if (S <> '') and TPatternMatching.Match(PChar(Value), PChar(S)) then begin Result := False; Exit; end;
    end;
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TConfiguration.LoadFromFile(FileName: String);
var
  IniFile: TMemIniFile; StringList: TStringList; DnsServerIndex: Integer; i: Integer; S: String; W: Word;
begin
  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TConfiguration.LoadFromFile: Loading configuration file...');

  IniFile := nil; try

    IniFile := TMemIniFile.Create(FileName);

    if TTracer.IsEnabled then begin
      StringList := TStringList.Create; IniFile.ReadSectionValues('GlobalSection', StringList); for i := 0 to (StringList.Count - 1) do TTracer.Trace(TracePriorityInfo, 'TConfiguration.LoadFromFile: [GlobalSection] ' + StringList[i]); StringList.Free;
      StringList := TStringList.Create; IniFile.ReadSectionValues('AllowedAddressesSection', StringList); for i := 0 to (StringList.Count - 1) do TTracer.Trace(TracePriorityInfo, 'TConfiguration.LoadFromFile: [AllowedAddressesSection] ' + StringList[i]); StringList.Free;
      StringList := TStringList.Create; IniFile.ReadSectionValues('CacheExceptionsSection', StringList); for i := 0 to (StringList.Count - 1) do TTracer.Trace(TracePriorityInfo, 'TConfiguration.LoadFromFile: [CacheExceptionsSection] ' + StringList[i]); StringList.Free;
      StringList := TStringList.Create; IniFile.ReadSectionValues('WhiteExceptionsSection', StringList); for i := 0 to (StringList.Count - 1) do TTracer.Trace(TracePriorityInfo, 'TConfiguration.LoadFromFile: [WhiteExceptionsSection] ' + StringList[i]); StringList.Free;
    end;

    for DnsServerIndex := 0 to (MAX_NUM_DNS_SERVERS - 1) do begin

      TConfiguration_DnsServerConfiguration[DnsServerIndex].IsEnabled := False;

      S := IniFile.ReadString('GlobalSection', DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'ServerAddress', ''); if (S <> '') then begin

        TConfiguration_DnsServerConfiguration[DnsServerIndex].Address := TDualIPAddressUtility.Parse(S);

        S := IniFile.ReadString('GlobalSection', DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'ServerPort', ''); if (S <> '') then begin

          TConfiguration_DnsServerConfiguration[DnsServerIndex].Port := StrToInt(S);

          S := IniFile.ReadString('GlobalSection', DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'ServerProtocol', ''); if (S <> '') then begin

            TConfiguration_DnsServerConfiguration[DnsServerIndex].Protocol := TDnsProtocolUtility.ParseDnsProtocol(S);

            TConfiguration_DnsServerConfiguration[DnsServerIndex].IsEnabled := True;

            S := IniFile.ReadString('GlobalSection', DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'ServerProxyAddress', ''); if (S <> '') then begin

              TConfiguration_DnsServerConfiguration[DnsServerIndex].ProxyAddress := TDualIPAddressUtility.Parse(S);

              S := IniFile.ReadString('GlobalSection', DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'ServerProxyPort', ''); if (S <> '') then begin

                TConfiguration_DnsServerConfiguration[DnsServerIndex].ProxyPort := StrToInt(S);

              end;

            end;

            S := IniFile.ReadString('GlobalSection', DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'ServerDomainNameAffinityMask', ''); if (S <> '') then begin
              TConfiguration_DnsServerConfiguration[DnsServerIndex].DomainNameAffinityMask := TStringList.Create; TConfiguration_DnsServerConfiguration[DnsServerIndex].DomainNameAffinityMask.Delimiter := ';'; TConfiguration_DnsServerConfiguration[DnsServerIndex].DomainNameAffinityMask.DelimitedText := S;
            end;

            S := IniFile.ReadString('GlobalSection', DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'ServerQueryTypeAffinityMask', ''); if (S <> '') then begin
              TConfiguration_DnsServerConfiguration[DnsServerIndex].QueryTypeAffinityMask := TList.Create; StringList := TStringList.Create; StringList.Delimiter := ';'; StringList.DelimitedText := S; for i := 0 to (StringList.Count - 1) do begin W := TDnsQueryTypeUtility.Parse(StringList[i]); if (W > 0) then TConfiguration_DnsServerConfiguration[DnsServerIndex].QueryTypeAffinityMask.Add(Pointer(W)); end; StringList.Free;
            end;

            TConfiguration_DnsServerConfiguration[DnsServerIndex].IgnoreNegativeResponsesFromServer := UpperCase(IniFile.ReadString('GlobalSection', 'IgnoreNegativeResponsesFrom' + DNS_SERVER_INDEX_DESCRIPTION[DnsServerIndex] + 'Server', '')) = 'YES';

          end;

        end;

      end;

    end;

    TConfiguration_AddressCacheDisabled := UpperCase(IniFile.ReadString('GlobalSection', 'AddressCacheDisabled', '')) = 'YES';

    TConfiguration_AddressCacheNegativeTime := IniFile.ReadInteger('GlobalSection', 'AddressCacheNegativeTime', TConfiguration_AddressCacheNegativeTime);
    TConfiguration_AddressCacheScavengingTime := IniFile.ReadInteger('GlobalSection', 'AddressCacheScavengingTime', TConfiguration_AddressCacheScavengingTime);
    TConfiguration_AddressCacheSilentUpdateTime := IniFile.ReadInteger('GlobalSection', 'AddressCacheSilentUpdateTime', TConfiguration_AddressCacheSilentUpdateTime);

    S := IniFile.ReadString('GlobalSection', 'LocalIPv4BindingAddress', ''); if (S <> '') then begin

      TConfiguration_IsLocalIPv4BindingEnabled := True;

      TConfiguration_LocalIPv4BindingAddress := TIPv4AddressUtility.Parse(S);
      TConfiguration_LocalIPv4BindingPort := StrToIntDef(IniFile.ReadString('GlobalSection', 'LocalIPv4BindingPort', IntToStr(TConfiguration_LocalIPv4BindingPort)), TConfiguration_LocalIPv4BindingPort);

    end;

    S := IniFile.ReadString('GlobalSection', 'LocalIPv6BindingAddress', ''); if (S <> '') then begin

      TConfiguration_IsLocalIPv6BindingEnabledOnWindowsVersionsPriorToWindowsVistaOrWindowsServer2008 := UpperCase(IniFile.ReadString('GlobalSection', 'LocalIPv6BindingEnabledOnWindowsVersionsPriorToWindowsVistaOrWindowsServer2008', '')) = 'YES';

      if TEnvironment.IsWindowsVistaOrWindowsServer2008OrHigher or TConfiguration_IsLocalIPv6BindingEnabledOnWindowsVersionsPriorToWindowsVistaOrWindowsServer2008 then begin

        TConfiguration_IsLocalIPv6BindingEnabled := True;

        TConfiguration_LocalIPv6BindingAddress := TIPv6AddressUtility.Parse(S);
        TConfiguration_LocalIPv6BindingPort := StrToIntDef(IniFile.ReadString('GlobalSection', 'LocalIPv6BindingPort', IntToStr(TConfiguration_LocalIPv6BindingPort)), TConfiguration_LocalIPv6BindingPort);

      end;

    end;

    TConfiguration_GeneratedDnsResponseTimeToLive := IniFile.ReadInteger('GlobalSection', 'GeneratedResponseTimeToLive', TConfiguration_GeneratedDnsResponseTimeToLive);

    TConfiguration_HitLogFileName := IniFile.ReadString('GlobalSection', 'HitLogFileName', ''); if (TConfiguration_HitLogFileName <> '') then TConfiguration_HitLogFileName := Self.MakeAbsolutePath(TConfiguration_HitLogFileName);
    TConfiguration_HitLogFileWhat := IniFile.ReadString('GlobalSection', 'HitLogFileWhat', '');
    TConfiguration_HitLogFileMode := IniFile.ReadString('GlobalSection', 'HitLogFileMode', '');

    TConfiguration_StatsLogFileName := IniFile.ReadString('GlobalSection', 'StatsLogFileName', ''); if (TConfiguration_StatsLogFileName <> '') then TConfiguration_StatsLogFileName := Self.MakeAbsolutePath(TConfiguration_StatsLogFileName);

    TConfiguration_HttpServerConfiguration.IsEnabled := UpperCase(IniFile.ReadString('GlobalSection', 'HttpServerEnabled', '')) = 'YES';

    S := IniFile.ReadString('GlobalSection', 'HttpServerBindingAddress', ''); if (S <> '') then begin

      TConfiguration_HttpServerConfiguration.IsEnabled := True;

      TConfiguration_HttpServerConfiguration.BindingAddress := TIPv4AddressUtility.Parse(S);
      TConfiguration_HttpServerConfiguration.BindingPort := StrToIntDef(IniFile.ReadString('GlobalSection', 'HttpServerBindingPort', IntToStr(TConfiguration_HttpServerConfiguration.BindingPort)), TConfiguration_HttpServerConfiguration.BindingPort);

    end;

    StringList := TStringList.Create; IniFile.ReadSection('AllowedAddressesSection', StringList); if (StringList.Count > 0) then begin
      TConfiguration_AllowedAddresses := TStringList.Create; for i := 0 to (StringList.Count - 1) do TConfiguration_AllowedAddresses.Add(Trim(IniFile.ReadString('AllowedAddressesSection', StringList.Strings[i], '')));
    end; StringList.Free;

    StringList := TStringList.Create; IniFile.ReadSection('CacheExceptionsSection', StringList); if (StringList.Count > 0) then begin
      TConfiguration_CacheExceptions := TStringList.Create; for i := 0 to (StringList.Count - 1) do TConfiguration_CacheExceptions.Add(Trim(IniFile.ReadString('CacheExceptionsSection', StringList.Strings[i], '')));
    end; StringList.Free;

    StringList := TStringList.Create; IniFile.ReadSection('WhiteExceptionsSection', StringList); if (StringList.Count > 0) then begin
      TConfiguration_WhiteExceptions := TStringList.Create; for i := 0 to (StringList.Count - 1) do TConfiguration_WhiteExceptions.Add(Trim(IniFile.ReadString('WhiteExceptionsSection', StringList.Strings[i], '')));
    end; StringList.Free;

  finally

    if (IniFile <> nil) then IniFile.Free;

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
  if (TConfiguration_WhiteExceptions <> nil) then TConfiguration_WhiteExceptions.Free;
  if (TConfiguration_CacheExceptions <> nil) then TConfiguration_CacheExceptions.Free;
  if (TConfiguration_AllowedAddresses <> nil) then TConfiguration_AllowedAddresses.Free;

  for i := 0 to (MAX_NUM_DNS_SERVERS - 1) do begin
    if (TConfiguration_DnsServerConfiguration[i].QueryTypeAffinityMask <> nil) then TConfiguration_DnsServerConfiguration[i].QueryTypeAffinityMask.Free;
    if (TConfiguration_DnsServerConfiguration[i].DomainNameAffinityMask <> nil) then TConfiguration_DnsServerConfiguration[i].DomainNameAffinityMask.Free;
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
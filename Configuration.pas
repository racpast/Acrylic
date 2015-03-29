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
  Classes;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  LOCALHOST_ADDRESS = $100007F;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  MIN_DNS_PACKET_LEN = 16;
  MAX_DNS_PACKET_LEN = 4096;
  MAX_DNS_BUFFER_LEN = 65536;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  MAX_NUM_DNS_SERVERS = 10;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  RESOLVER_THREAD_MAX_BLOCK_TIME = 6283;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TServerConfiguration = record
    HostNameAffinityMask: TStringList;
    QueryTypeAffinityMask: TList;
    Address: Integer;
    Port: Word;
    IgnoreNegativeResponsesFromServer: Boolean;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TConfiguration = class
    private
      class function  MakeAbsolutePath(Path: String): String;
    public
      class function  GetHitLogFileName(): String;
      class function  GetHitLogFileWhat(): String;
      class function  GetStatsLogFileName(): String;
      class function  GetDebugLogFileName(): String;
      class function  GetConfigurationFileName(): String;
      class function  GetAddressCacheFileName(): String;
      class function  GetHostsCacheFileName(): String;
    public
      class function  GetServerConfiguration(Index: Integer): TServerConfiguration;
    public
      class function  GetAddressCacheDisabled(): Boolean;
      class function  GetAddressCacheNegativeTime(): Integer;
      class function  GetAddressCacheScavengingTime(): Integer;
      class function  GetAddressCacheSilentUpdateTime(): Integer;
      class function  GetAddressCacheDisableCompression(): Boolean;
    public
      class function  GetLocalBindingAddress(): Integer;
      class function  GetLocalBindingPort(): Word;
    public
      class function  IsHostNameAffinityMatch(HostName: String; HostNameAffinityMask: TStringList): Boolean;
      class function  IsQueryTypeAffinityMatch(QueryType: Word; QueryTypeAffinityMask: TList): Boolean;
    public
      class function  IsAllowedAddress(Value: String): Boolean;
      class function  IsCacheException(Value: String): Boolean;
      class function  IsBlackException(Value: String): Boolean;
    public
      class procedure Initialize();
      class procedure LoadFromFile(FileName: String);
      class procedure Finalize();
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  IniFiles, SysUtils, IPAddress, PatternMatching, QueryTypeUtils, Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_ServerConfiguration: Array [0..(MAX_NUM_DNS_SERVERS - 1)] of TServerConfiguration;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_AddressCacheDisabled: Boolean;
  TConfiguration_AddressCacheNegativeTime: Integer;
  TConfiguration_AddressCacheScavengingTime: Integer;
  TConfiguration_AddressCacheSilentUpdateTime: Integer;
  TConfiguration_AddressCacheDisableCompression: Boolean;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_LocalBindingAddress: Integer;
  TConfiguration_LocalBindingPort: Word;

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
  TConfiguration_StatsLogFileName: String;
  TConfiguration_DebugLogFileName: String;
  TConfiguration_ConfigurationFileName: String;
  TConfiguration_AddressCacheFileName: String;
  TConfiguration_HostsCacheFileName: String;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TConfiguration.Initialize();
var
  i: Integer;
begin
  // Initialize server config
  for i := 0 to (MAX_NUM_DNS_SERVERS - 1) do begin
    TConfiguration_ServerConfiguration[i].HostNameAffinityMask := nil;
    TConfiguration_ServerConfiguration[i].QueryTypeAffinityMask := nil;
    TConfiguration_ServerConfiguration[i].Address := -1;
    TConfiguration_ServerConfiguration[i].Port := 0;
    TConfiguration_ServerConfiguration[i].IgnoreNegativeResponsesFromServer := False;
  end;

  // Initialize caching config
  TConfiguration_AddressCacheDisabled := False;
  TConfiguration_AddressCacheNegativeTime := 10;
  TConfiguration_AddressCacheScavengingTime := 28800;
  TConfiguration_AddressCacheSilentUpdateTime := 1440;
  TConfiguration_AddressCacheDisableCompression := False;

  // Initialize local binding params
  TConfiguration_LocalBindingAddress := 0;
  TConfiguration_LocalBindingPort := 53;

  // Initialize various file names
  TConfiguration_HitLogFileName := '';
  TConfiguration_HitLogFileWhat := '';
  TConfiguration_StatsLogFileName := '';
  TConfiguration_DebugLogFileName := Self.MakeAbsolutePath('AcrylicDebug.txt');
  TConfiguration_ConfigurationFileName := Self.MakeAbsolutePath('AcrylicConfiguration.ini');
  TConfiguration_AddressCacheFileName := Self.MakeAbsolutePath('AcrylicCache.dat');
  TConfiguration_HostsCacheFileName := Self.MakeAbsolutePath('AcrylicHosts.txt');

  // Initialize various lists
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

class function TConfiguration.GetHitLogFileName(): String;
begin
  Result := TConfiguration_HitLogFileName;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetHitLogFileWhat(): String;
begin
  Result := TConfiguration_HitLogFileWhat;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetDebugLogFileName(): String;
begin
  Result := TConfiguration_DebugLogFileName;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetStatsLogFileName(): String;
begin
  Result := TConfiguration_StatsLogFileName;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetConfigurationFileName(): String;
begin
  Result := TConfiguration_ConfigurationFileName;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetAddressCacheFileName(): String;
begin
  Result := TConfiguration_AddressCacheFileName;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetHostsCacheFileName(): String;
begin
  Result := TConfiguration_HostsCacheFileName;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetServerConfiguration(Index: Integer): TServerConfiguration;
begin
  Result := TConfiguration_ServerConfiguration[Index];
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetAddressCacheDisabled(): Boolean;
begin
  Result := TConfiguration_AddressCacheDisabled;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetAddressCacheSilentUpdateTime(): Integer;
begin
  Result := TConfiguration_AddressCacheSilentUpdateTime;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetAddressCacheScavengingTime(): Integer;
begin
  Result := TConfiguration_AddressCacheScavengingTime;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetAddressCacheNegativeTime(): Integer;
begin
  Result := TConfiguration_AddressCacheNegativeTime;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetAddressCacheDisableCompression(): Boolean;
begin
  Result := TConfiguration_AddressCacheDisableCompression;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetLocalBindingAddress(): Integer;
begin
  Result := TConfiguration_LocalBindingAddress;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetLocalBindingPort(): Word;
begin
  Result := TConfiguration_LocalBindingPort;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.IsHostNameAffinityMatch(HostName: String; HostNameAffinityMask: TStringList): Boolean;
var
  i: Integer; S: String;
begin
  Result := True; if (HostNameAffinityMask <> nil) and (HostNameAffinityMask.Count > 0) then begin
    Result := False; for i := 0 to (HostNameAffinityMask.Count - 1) do begin
      S := HostNameAffinityMask[i]; if (S <> '') then begin
        if (S[1] = '^') then begin
          if TPatternMatching.Match(PChar(HostName), PChar(Copy(S, 2))) then begin Result := False; Exit; end;
        end else begin
          if TPatternMatching.Match(PChar(HostName), PChar(S)) then begin Result := True; Exit; end;
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
  IniFile: TIniFile; StringList: TStringList; i: Integer; S: String; W: Word;
begin
  if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TConfiguration.LoadFromFile: Loading configuration file...');

  IniFile := nil; try

    IniFile := TIniFile.Create(FileName);

    if TTracer.IsEnabled() then begin
      StringList := TStringList.Create; IniFile.ReadSectionValues('GlobalSection'          , StringList); for i := 0 to (StringList.Count - 1) do TTracer.Trace(TracePriorityInfo, 'TConfiguration.LoadFromFile: [GlobalSection] '           + StringList[i]); StringList.Free;
      StringList := TStringList.Create; IniFile.ReadSectionValues('AllowedAddressesSection', StringList); for i := 0 to (StringList.Count - 1) do TTracer.Trace(TracePriorityInfo, 'TConfiguration.LoadFromFile: [AllowedAddressesSection] ' + StringList[i]); StringList.Free;
      StringList := TStringList.Create; IniFile.ReadSectionValues('CacheExceptionsSection' , StringList); for i := 0 to (StringList.Count - 1) do TTracer.Trace(TracePriorityInfo, 'TConfiguration.LoadFromFile: [CacheExceptionsSection] '  + StringList[i]); StringList.Free;
      StringList := TStringList.Create; IniFile.ReadSectionValues('WhiteExceptionsSection' , StringList); for i := 0 to (StringList.Count - 1) do TTracer.Trace(TracePriorityInfo, 'TConfiguration.LoadFromFile: [WhiteExceptionsSection] '  + StringList[i]); StringList.Free;
    end;

    S := IniFile.ReadString('GlobalSection', 'PrimaryServerHostNameAffinityMask', ''); if (S <> '') then begin
      TConfiguration_ServerConfiguration[0].HostNameAffinityMask := TStringList.Create; TConfiguration_ServerConfiguration[0].HostNameAffinityMask.Delimiter := ';'; TConfiguration_ServerConfiguration[0].HostNameAffinityMask.DelimitedText := S;
    end;

    S := IniFile.ReadString('GlobalSection', 'PrimaryServerQueryTypeAffinityMask', ''); if (S <> '') then begin
      TConfiguration_ServerConfiguration[0].QueryTypeAffinityMask := TList.Create; StringList := TStringList.Create; StringList.Delimiter := ';'; StringList.DelimitedText := S; for i := 0 to (StringList.Count - 1) do begin W := TQueryTypeUtils.Parse(StringList[i]); if (W > 0) then TConfiguration_ServerConfiguration[0].QueryTypeAffinityMask.Add(Pointer(W)); end; StringList.Free;
    end;

    TConfiguration_ServerConfiguration[0].Address := TIPAddress.Parse(IniFile.ReadString('GlobalSection', 'PrimaryServerAddress', ''));
    TConfiguration_ServerConfiguration[0].Port := StrToIntDef(IniFile.ReadString('GlobalSection', 'PrimaryServerPort', '53'), 53);
    TConfiguration_ServerConfiguration[0].IgnoreNegativeResponsesFromServer := UpperCase(IniFile.ReadString('GlobalSection', 'IgnoreNegativeResponsesFromPrimaryServer', '')) = 'YES';

    S := IniFile.ReadString('GlobalSection', 'SecondaryServerHostNameAffinityMask', ''); if (S <> '') then begin
      TConfiguration_ServerConfiguration[1].HostNameAffinityMask := TStringList.Create; TConfiguration_ServerConfiguration[1].HostNameAffinityMask.Delimiter := ';'; TConfiguration_ServerConfiguration[1].HostNameAffinityMask.DelimitedText := S;
    end;

    S := IniFile.ReadString('GlobalSection', 'SecondaryServerQueryTypeAffinityMask', ''); if (S <> '') then begin
      TConfiguration_ServerConfiguration[1].QueryTypeAffinityMask := TList.Create; StringList := TStringList.Create; StringList.Delimiter := ';'; StringList.DelimitedText := S; for i := 0 to (StringList.Count - 1) do begin W := TQueryTypeUtils.Parse(StringList[i]); if (W > 0) then TConfiguration_ServerConfiguration[1].QueryTypeAffinityMask.Add(Pointer(W)); end; StringList.Free;
    end;

    TConfiguration_ServerConfiguration[1].Address := TIPAddress.Parse(IniFile.ReadString('GlobalSection', 'SecondaryServerAddress', ''));
    TConfiguration_ServerConfiguration[1].Port := StrToIntDef(IniFile.ReadString('GlobalSection', 'SecondaryServerPort', '53'), 53);
    TConfiguration_ServerConfiguration[1].IgnoreNegativeResponsesFromServer := UpperCase(IniFile.ReadString('GlobalSection', 'IgnoreNegativeResponsesFromSecondaryServer', '')) = 'YES';

    S := IniFile.ReadString('GlobalSection', 'TertiaryServerHostNameAffinityMask', ''); if (S <> '') then begin
      TConfiguration_ServerConfiguration[2].HostNameAffinityMask := TStringList.Create; TConfiguration_ServerConfiguration[2].HostNameAffinityMask.Delimiter := ';'; TConfiguration_ServerConfiguration[2].HostNameAffinityMask.DelimitedText := S;
    end;

    S := IniFile.ReadString('GlobalSection', 'TertiaryServerQueryTypeAffinityMask', ''); if (S <> '') then begin
      TConfiguration_ServerConfiguration[2].QueryTypeAffinityMask := TList.Create; StringList := TStringList.Create; StringList.Delimiter := ';'; StringList.DelimitedText := S; for i := 0 to (StringList.Count - 1) do begin W := TQueryTypeUtils.Parse(StringList[i]); if (W > 0) then TConfiguration_ServerConfiguration[2].QueryTypeAffinityMask.Add(Pointer(W)); end; StringList.Free;
    end;

    TConfiguration_ServerConfiguration[2].Address := TIPAddress.Parse(IniFile.ReadString('GlobalSection', 'TertiaryServerAddress', ''));
    TConfiguration_ServerConfiguration[2].Port := StrToIntDef(IniFile.ReadString('GlobalSection', 'TertiaryServerPort', '53'), 53);
    TConfiguration_ServerConfiguration[2].IgnoreNegativeResponsesFromServer := UpperCase(IniFile.ReadString('GlobalSection', 'IgnoreNegativeResponsesFromTertiaryServer', '')) = 'YES';

    S := IniFile.ReadString('GlobalSection', 'QuaternaryServerHostNameAffinityMask', ''); if (S <> '') then begin
      TConfiguration_ServerConfiguration[3].HostNameAffinityMask := TStringList.Create; TConfiguration_ServerConfiguration[3].HostNameAffinityMask.Delimiter := ';'; TConfiguration_ServerConfiguration[3].HostNameAffinityMask.DelimitedText := S;
    end;

    S := IniFile.ReadString('GlobalSection', 'QuaternaryServerQueryTypeAffinityMask', ''); if (S <> '') then begin
      TConfiguration_ServerConfiguration[3].QueryTypeAffinityMask := TList.Create; StringList := TStringList.Create; StringList.Delimiter := ';'; StringList.DelimitedText := S; for i := 0 to (StringList.Count - 1) do begin W := TQueryTypeUtils.Parse(StringList[i]); if (W > 0) then TConfiguration_ServerConfiguration[3].QueryTypeAffinityMask.Add(Pointer(W)); end; StringList.Free;
    end;

    TConfiguration_ServerConfiguration[3].Address := TIPAddress.Parse(IniFile.ReadString('GlobalSection', 'QuaternaryServerAddress', ''));
    TConfiguration_ServerConfiguration[3].Port := StrToIntDef(IniFile.ReadString('GlobalSection', 'QuaternaryServerPort', '53'), 53);
    TConfiguration_ServerConfiguration[3].IgnoreNegativeResponsesFromServer := UpperCase(IniFile.ReadString('GlobalSection', 'IgnoreNegativeResponsesFromQuaternaryServer', '')) = 'YES';

    S := IniFile.ReadString('GlobalSection', 'QuinaryServerHostNameAffinityMask', ''); if (S <> '') then begin
      TConfiguration_ServerConfiguration[4].HostNameAffinityMask := TStringList.Create; TConfiguration_ServerConfiguration[4].HostNameAffinityMask.Delimiter := ';'; TConfiguration_ServerConfiguration[4].HostNameAffinityMask.DelimitedText := S;
    end;

    S := IniFile.ReadString('GlobalSection', 'QuinaryServerQueryTypeAffinityMask', ''); if (S <> '') then begin
      TConfiguration_ServerConfiguration[4].QueryTypeAffinityMask := TList.Create; StringList := TStringList.Create; StringList.Delimiter := ';'; StringList.DelimitedText := S; for i := 0 to (StringList.Count - 1) do begin W := TQueryTypeUtils.Parse(StringList[i]); if (W > 0) then TConfiguration_ServerConfiguration[4].QueryTypeAffinityMask.Add(Pointer(W)); end; StringList.Free;
    end;

    TConfiguration_ServerConfiguration[4].Address := TIPAddress.Parse(IniFile.ReadString('GlobalSection', 'QuinaryServerAddress', ''));
    TConfiguration_ServerConfiguration[4].Port := StrToIntDef(IniFile.ReadString('GlobalSection', 'QuinaryServerPort', '53'), 53);
    TConfiguration_ServerConfiguration[4].IgnoreNegativeResponsesFromServer := UpperCase(IniFile.ReadString('GlobalSection', 'IgnoreNegativeResponsesFromQuinaryServer', '')) = 'YES';

    S := IniFile.ReadString('GlobalSection', 'SenaryServerHostNameAffinityMask', ''); if (S <> '') then begin
      TConfiguration_ServerConfiguration[5].HostNameAffinityMask := TStringList.Create; TConfiguration_ServerConfiguration[5].HostNameAffinityMask.Delimiter := ';'; TConfiguration_ServerConfiguration[5].HostNameAffinityMask.DelimitedText := S;
    end;

    S := IniFile.ReadString('GlobalSection', 'SenaryServerQueryTypeAffinityMask', ''); if (S <> '') then begin
      TConfiguration_ServerConfiguration[5].QueryTypeAffinityMask := TList.Create; StringList := TStringList.Create; StringList.Delimiter := ';'; StringList.DelimitedText := S; for i := 0 to (StringList.Count - 1) do begin W := TQueryTypeUtils.Parse(StringList[i]); if (W > 0) then TConfiguration_ServerConfiguration[5].QueryTypeAffinityMask.Add(Pointer(W)); end; StringList.Free;
    end;

    TConfiguration_ServerConfiguration[5].Address := TIPAddress.Parse(IniFile.ReadString('GlobalSection', 'SenaryServerAddress', ''));
    TConfiguration_ServerConfiguration[5].Port := StrToIntDef(IniFile.ReadString('GlobalSection', 'SenaryServerPort', '53'), 53);
    TConfiguration_ServerConfiguration[5].IgnoreNegativeResponsesFromServer := UpperCase(IniFile.ReadString('GlobalSection', 'IgnoreNegativeResponsesFromSenaryServer', '')) = 'YES';

    S := IniFile.ReadString('GlobalSection', 'SeptenaryServerHostNameAffinityMask', ''); if (S <> '') then begin
      TConfiguration_ServerConfiguration[6].HostNameAffinityMask := TStringList.Create; TConfiguration_ServerConfiguration[6].HostNameAffinityMask.Delimiter := ';'; TConfiguration_ServerConfiguration[6].HostNameAffinityMask.DelimitedText := S;
    end;

    S := IniFile.ReadString('GlobalSection', 'SeptenaryServerQueryTypeAffinityMask', ''); if (S <> '') then begin
      TConfiguration_ServerConfiguration[6].QueryTypeAffinityMask := TList.Create; StringList := TStringList.Create; StringList.Delimiter := ';'; StringList.DelimitedText := S; for i := 0 to (StringList.Count - 1) do begin W := TQueryTypeUtils.Parse(StringList[i]); if (W > 0) then TConfiguration_ServerConfiguration[6].QueryTypeAffinityMask.Add(Pointer(W)); end; StringList.Free;
    end;

    TConfiguration_ServerConfiguration[6].Address := TIPAddress.Parse(IniFile.ReadString('GlobalSection', 'SeptenaryServerAddress', ''));
    TConfiguration_ServerConfiguration[6].Port := StrToIntDef(IniFile.ReadString('GlobalSection', 'SeptenaryServerPort', '53'), 53);
    TConfiguration_ServerConfiguration[6].IgnoreNegativeResponsesFromServer := UpperCase(IniFile.ReadString('GlobalSection', 'IgnoreNegativeResponsesFromSeptenaryServer', '')) = 'YES';

    S := IniFile.ReadString('GlobalSection', 'OctonaryServerHostNameAffinityMask', ''); if (S <> '') then begin
      TConfiguration_ServerConfiguration[7].HostNameAffinityMask := TStringList.Create; TConfiguration_ServerConfiguration[7].HostNameAffinityMask.Delimiter := ';'; TConfiguration_ServerConfiguration[7].HostNameAffinityMask.DelimitedText := S;
    end;

    S := IniFile.ReadString('GlobalSection', 'OctonaryServerQueryTypeAffinityMask', ''); if (S <> '') then begin
      TConfiguration_ServerConfiguration[7].QueryTypeAffinityMask := TList.Create; StringList := TStringList.Create; StringList.Delimiter := ';'; StringList.DelimitedText := S; for i := 0 to (StringList.Count - 1) do begin W := TQueryTypeUtils.Parse(StringList[i]); if (W > 0) then TConfiguration_ServerConfiguration[7].QueryTypeAffinityMask.Add(Pointer(W)); end; StringList.Free;
    end;

    TConfiguration_ServerConfiguration[7].Address := TIPAddress.Parse(IniFile.ReadString('GlobalSection', 'OctonaryServerAddress', ''));
    TConfiguration_ServerConfiguration[7].Port := StrToIntDef(IniFile.ReadString('GlobalSection', 'OctonaryServerPort', '53'), 53);
    TConfiguration_ServerConfiguration[7].IgnoreNegativeResponsesFromServer := UpperCase(IniFile.ReadString('GlobalSection', 'IgnoreNegativeResponsesFromOctonaryServer', '')) = 'YES';

    S := IniFile.ReadString('GlobalSection', 'NonaryServerHostNameAffinityMask', ''); if (S <> '') then begin
      TConfiguration_ServerConfiguration[8].HostNameAffinityMask := TStringList.Create; TConfiguration_ServerConfiguration[8].HostNameAffinityMask.Delimiter := ';'; TConfiguration_ServerConfiguration[8].HostNameAffinityMask.DelimitedText := S;
    end;

    S := IniFile.ReadString('GlobalSection', 'NonaryServerQueryTypeAffinityMask', ''); if (S <> '') then begin
      TConfiguration_ServerConfiguration[8].QueryTypeAffinityMask := TList.Create; StringList := TStringList.Create; StringList.Delimiter := ';'; StringList.DelimitedText := S; for i := 0 to (StringList.Count - 1) do begin W := TQueryTypeUtils.Parse(StringList[i]); if (W > 0) then TConfiguration_ServerConfiguration[8].QueryTypeAffinityMask.Add(Pointer(W)); end; StringList.Free;
    end;

    TConfiguration_ServerConfiguration[8].Address := TIPAddress.Parse(IniFile.ReadString('GlobalSection', 'NonaryServerAddress', ''));
    TConfiguration_ServerConfiguration[8].Port := StrToIntDef(IniFile.ReadString('GlobalSection', 'NonaryServerPort', '53'), 53);
    TConfiguration_ServerConfiguration[8].IgnoreNegativeResponsesFromServer := UpperCase(IniFile.ReadString('GlobalSection', 'IgnoreNegativeResponsesFromNonaryServer', '')) = 'YES';

    S := IniFile.ReadString('GlobalSection', 'DenaryServerHostNameAffinityMask', ''); if (S <> '') then begin
      TConfiguration_ServerConfiguration[9].HostNameAffinityMask := TStringList.Create; TConfiguration_ServerConfiguration[9].HostNameAffinityMask.Delimiter := ';'; TConfiguration_ServerConfiguration[9].HostNameAffinityMask.DelimitedText := S;
    end;

    S := IniFile.ReadString('GlobalSection', 'DenaryServerQueryTypeAffinityMask', ''); if (S <> '') then begin
      TConfiguration_ServerConfiguration[9].QueryTypeAffinityMask := TList.Create; StringList := TStringList.Create; StringList.Delimiter := ';'; StringList.DelimitedText := S; for i := 0 to (StringList.Count - 1) do begin W := TQueryTypeUtils.Parse(StringList[i]); if (W > 0) then TConfiguration_ServerConfiguration[9].QueryTypeAffinityMask.Add(Pointer(W)); end; StringList.Free;
    end;

    TConfiguration_ServerConfiguration[9].Address := TIPAddress.Parse(IniFile.ReadString('GlobalSection', 'DenaryServerAddress', ''));
    TConfiguration_ServerConfiguration[9].Port := StrToIntDef(IniFile.ReadString('GlobalSection', 'DenaryServerPort', '53'), 53);
    TConfiguration_ServerConfiguration[9].IgnoreNegativeResponsesFromServer := UpperCase(IniFile.ReadString('GlobalSection', 'IgnoreNegativeResponsesFromDenaryServer', '')) = 'YES';

    TConfiguration_AddressCacheDisabled := UpperCase(IniFile.ReadString('GlobalSection', 'AddressCacheDisabled', '')) = 'YES';
    TConfiguration_AddressCacheNegativeTime := IniFile.ReadInteger('GlobalSection', 'AddressCacheNegativeTime', TConfiguration_AddressCacheNegativeTime);
    TConfiguration_AddressCacheScavengingTime := IniFile.ReadInteger('GlobalSection', 'AddressCacheScavengingTime', TConfiguration_AddressCacheScavengingTime);
    TConfiguration_AddressCacheSilentUpdateTime := IniFile.ReadInteger('GlobalSection', 'AddressCacheSilentUpdateTime', TConfiguration_AddressCacheSilentUpdateTime);
    TConfiguration_AddressCacheDisableCompression := UpperCase(IniFile.ReadString('GlobalSection', 'AddressCacheDisableCompression', '')) = 'YES';

    TConfiguration_LocalBindingAddress := TIPAddress.Parse(IniFile.ReadString('GlobalSection', 'LocalBindingAddress', '0.0.0.0'));
    TConfiguration_LocalBindingPort := StrToIntDef(IniFile.ReadString('GlobalSection', 'LocalBindingPort', IntToStr(TConfiguration_LocalBindingPort)), TConfiguration_LocalBindingPort);

    TConfiguration_HitLogFileName := IniFile.ReadString('GlobalSection', 'HitLogFileName', ''); if (TConfiguration_HitLogFileName <> '') then TConfiguration_HitLogFileName := Self.MakeAbsolutePath(TConfiguration_HitLogFileName);
    TConfiguration_HitLogFileWhat := IniFile.ReadString('GlobalSection', 'HitLogFileWhat', '');

    TConfiguration_StatsLogFileName := IniFile.ReadString('GlobalSection', 'StatsLogFileName', ''); if (TConfiguration_StatsLogFileName <> '') then TConfiguration_StatsLogFileName := Self.MakeAbsolutePath(TConfiguration_StatsLogFileName);

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

  if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TConfiguration.LoadFromFile: Configuration file loaded successfully.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TConfiguration.Finalize();
var
  i: Integer;
begin
  if (TConfiguration_WhiteExceptions <> nil) then TConfiguration_WhiteExceptions.Free;
  if (TConfiguration_CacheExceptions <> nil) then TConfiguration_CacheExceptions.Free;
  if (TConfiguration_AllowedAddresses <> nil) then TConfiguration_AllowedAddresses.Free;

  for i := 0 to (MAX_NUM_DNS_SERVERS - 1) do begin
    if (TConfiguration_ServerConfiguration[i].QueryTypeAffinityMask <> nil) then TConfiguration_ServerConfiguration[i].QueryTypeAffinityMask.Free;
    if (TConfiguration_ServerConfiguration[i].HostNameAffinityMask <> nil) then TConfiguration_ServerConfiguration[i].HostNameAffinityMask.Free;
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

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
  LOCALHOST_ADDRESS              = $100007F;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  MIN_DNS_PACKET_LEN             = 16;
  MAX_DNS_PACKET_LEN             = 512;
  MAX_DNS_BUFFER_LEN             = 65536;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  MAX_NUM_DNS_SERVERS            = 3;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  REQ_HOST_NAME_OFFSET           = 12;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  RESOLVER_THREAD_MAX_BLOCK_TIME = 6283;

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
      class function  GetServerAddress(Index: Integer): Integer;
      class function  GetServerPort(Index: Integer): Word;
    public
      class function  GetAddressCacheScavengingTime(): Integer;
      class function  GetAddressCacheSilentUpdateTime(): Integer;
      class function  GetAddressCacheNegativeTime(): Integer;
    public
      class function  GetLocalBindingAddress(): Integer;
      class function  GetLocalBindingPort(): Word;
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
  SysUtils, IniFiles, IPAddress;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_ServerAddresses              : Array [0..(MAX_NUM_DNS_SERVERS - 1)] of Integer;
  TConfiguration_ServerPorts                  : Array [0..(MAX_NUM_DNS_SERVERS - 1)] of Word;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_AddressCacheNegativeTime     : Integer;
  TConfiguration_AddressCacheScavengingTime   : Integer;
  TConfiguration_AddressCacheSilentUpdateTime : Integer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_LocalBindingAddress          : Integer;
  TConfiguration_LocalBindingPort             : Word;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_CacheExceptions              : THashedStringList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_WhiteExceptions              : THashedStringList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_AllowedAddresses             : TStringList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TConfiguration_HitLogFileName               : String;
  TConfiguration_HitLogFileWhat               : String;
  TConfiguration_StatsLogFileName             : String;
  TConfiguration_DebugLogFileName             : String;
  TConfiguration_ConfigurationFileName        : String;
  TConfiguration_AddressCacheFileName         : String;
  TConfiguration_HostsCacheFileName           : String;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TConfiguration.Initialize();
begin
  // Initialize server addresses
  FillChar(TConfiguration_ServerAddresses, SizeOf(TConfiguration_ServerAddresses), 0);

  // Initialize the caching times
  TConfiguration_AddressCacheNegativeTime     := 00120;
  TConfiguration_AddressCacheScavengingTime   := 28800;
  TConfiguration_AddressCacheSilentUpdateTime := 07200;

  // Initialize local binding params
  TConfiguration_LocalBindingAddress          := 0;
  TConfiguration_LocalBindingPort             := 53;

  // Initialize the various file names
  TConfiguration_HitLogFileName               := '';
  TConfiguration_HitLogFileWhat               := '';
  TConfiguration_StatsLogFileName             := '';
  TConfiguration_DebugLogFileName             := Self.MakeAbsolutePath('AcrylicDebug.txt');
  TConfiguration_ConfigurationFileName        := Self.MakeAbsolutePath('AcrylicConfiguration.ini');
  TConfiguration_AddressCacheFileName         := Self.MakeAbsolutePath('AcrylicCache.dat');
  TConfiguration_HostsCacheFileName           := Self.MakeAbsolutePath('AcrylicHosts.txt');

  // Initialize various list
  TConfiguration_AllowedAddresses             := nil;
  TConfiguration_CacheExceptions              := nil;
  TConfiguration_WhiteExceptions              := nil;
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

class function TConfiguration.GetServerAddress(Index: Integer): Integer;
begin
  Result := TConfiguration_ServerAddresses[Index];
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.GetServerPort(Index: Integer): Word;
begin
  Result := TConfiguration_ServerPorts[Index];
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

class function TConfiguration.IsAllowedAddress(Value: String): Boolean;
var
  i: Integer; S: String;
begin
  Result := False; if (TConfiguration_AllowedAddresses <> nil) and (TConfiguration_AllowedAddresses.Count > 0) then begin
    for i := 0 to (TConfiguration_AllowedAddresses.Count - 1) do begin
      S := TConfiguration_AllowedAddresses.Strings[i]; if (Length(S) > 0) and (Pos(S, Value) = 1) then begin Result := True; Exit; end;
    end;
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.IsCacheException(Value: String): Boolean;
begin
  if (TConfiguration_CacheExceptions <> nil) and (TConfiguration_CacheExceptions.Count > 0) and (TConfiguration_CacheExceptions.IndexOf(Value) > -1) then Result := True else Result := False;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TConfiguration.IsBlackException(Value: String): Boolean;
begin
  if (TConfiguration_WhiteExceptions <> nil) and (TConfiguration_WhiteExceptions.Count > 0) and not(TConfiguration_WhiteExceptions.IndexOf(Value) > -1) then Result := True else Result := False;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TConfiguration.LoadFromFile(FileName: String);
var
  IniFile: TIniFile; StringList: TStringList; i: Integer;
begin
  IniFile := nil; try

    IniFile := TIniFile.Create(FileName);

    TConfiguration_ServerAddresses[0]           := TIPAddress.Parse(IniFile.ReadString('GlobalSection', 'PrimaryServerAddress', ''));
    TConfiguration_ServerAddresses[1]           := TIPAddress.Parse(IniFile.ReadString('GlobalSection', 'SecondaryServerAddress', ''));
    TConfiguration_ServerAddresses[2]           := TIPAddress.Parse(IniFile.ReadString('GlobalSection', 'TertiaryServerAddress', ''));

    TConfiguration_ServerPorts[0]               := StrToIntDef(IniFile.ReadString('GlobalSection', 'PrimaryServerPort', '53'), 53);
    TConfiguration_ServerPorts[1]               := StrToIntDef(IniFile.ReadString('GlobalSection', 'SecondaryServerPort', '53'), 53);
    TConfiguration_ServerPorts[2]               := StrToIntDef(IniFile.ReadString('GlobalSection', 'TertiaryServerPort', '53'), 53);

    TConfiguration_AddressCacheNegativeTime     := IniFile.ReadInteger('GlobalSection', 'AddressCacheNegativeTime', TConfiguration_AddressCacheNegativeTime);
    TConfiguration_AddressCacheScavengingTime   := IniFile.ReadInteger('GlobalSection', 'AddressCacheScavengingTime', TConfiguration_AddressCacheScavengingTime);
    TConfiguration_AddressCacheSilentUpdateTime := IniFile.ReadInteger('GlobalSection', 'AddressCacheSilentUpdateTime', TConfiguration_AddressCacheSilentUpdateTime);

    TConfiguration_LocalBindingAddress          := TIPAddress.Parse(IniFile.ReadString('GlobalSection', 'LocalBindingAddress', '0.0.0.0'));
    TConfiguration_LocalBindingPort             := StrToIntDef(IniFile.ReadString('GlobalSection', 'LocalBindingPort', IntToStr(TConfiguration_LocalBindingPort)), TConfiguration_LocalBindingPort);

    TConfiguration_HitLogFileName               := IniFile.ReadString('GlobalSection', 'HitLogFileName', ''); if (TConfiguration_HitLogFileName <> '') then TConfiguration_HitLogFileName := Self.MakeAbsolutePath(TConfiguration_HitLogFileName);
    TConfiguration_HitLogFileWhat               := IniFile.ReadString('GlobalSection', 'HitLogFileWhat', '');

    TConfiguration_StatsLogFileName             := IniFile.ReadString('GlobalSection', 'StatsLogFileName', ''); if (TConfiguration_StatsLogFileName <> '') then TConfiguration_StatsLogFileName := Self.MakeAbsolutePath(TConfiguration_StatsLogFileName);

    StringList := TStringList.Create; IniFile.ReadSection('AllowedAddressesSection', StringList); if (StringList.Count > 0) then begin
      TConfiguration_AllowedAddresses := TStringList.Create; for i := 0 to (StringList.Count - 1) do TConfiguration_AllowedAddresses.Add(Trim(IniFile.ReadString('AllowedAddressesSection', StringList.Strings[i], '')));
    end; StringList.Free;

    StringList := TStringList.Create; IniFile.ReadSection('CacheExceptionsSection', StringList); if (StringList.Count > 0) then begin
      TConfiguration_CacheExceptions := THashedStringList.Create; for i := 0 to (StringList.Count - 1) do TConfiguration_CacheExceptions.Add(Trim(IniFile.ReadString('CacheExceptionsSection', StringList.Strings[i], ''))); if (TConfiguration_CacheExceptions.Count > 1) then TConfiguration_CacheExceptions.Sort;
    end; StringList.Free;

    StringList := TStringList.Create; IniFile.ReadSection('WhiteExceptionsSection', StringList); if (StringList.Count > 0) then begin
      TConfiguration_WhiteExceptions := THashedStringList.Create; for i := 0 to (StringList.Count - 1) do TConfiguration_WhiteExceptions.Add(Trim(IniFile.ReadString('WhiteExceptionsSection', StringList.Strings[i], ''))); if (TConfiguration_WhiteExceptions.Count > 1) then TConfiguration_WhiteExceptions.Sort;
    end; StringList.Free;

  finally

    if (IniFile <> nil) then IniFile.Free;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TConfiguration.Finalize();
begin
  if (TConfiguration_WhiteExceptions  <> nil) then TConfiguration_WhiteExceptions.Free;
  if (TConfiguration_CacheExceptions  <> nil) then TConfiguration_CacheExceptions.Free;
  if (TConfiguration_AllowedAddresses <> nil) then TConfiguration_AllowedAddresses.Free;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

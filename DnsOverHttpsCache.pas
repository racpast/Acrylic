// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  DnsOverHttpsCache;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  IPUtils;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TDnsOverHttpsCache = class
    public
      class procedure Initialize;
      class procedure AddIPv4Item(const HostName: String; var IPv4Address: TIPv4Address);
      class procedure AddIPv6Item(const HostName: String; var IPv6Address: TIPv6Address);
      class function  FindIPv4Item(const HostName: String; var IPv4Address: TIPv4Address): Boolean;
      class function  FindIPv6Item(const HostName: String; var IPv6Address: TIPv6Address): Boolean;
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
  Classes,
  SysUtils;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TDnsOverHttpsCache_IPv4List: TStringList;
  TDnsOverHttpsCache_IPv6List: TStringList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsOverHttpsCache.Initialize;

begin

  // Nothing to do.

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsOverHttpsCache.AddIPv4Item(const HostName: String; var IPv4Address: TIPv4Address);

begin

  if (TDnsOverHttpsCache_IPv4List = nil) then TDnsOverHttpsCache_IPv4List := TStringList.Create;

  TDnsOverHttpsCache_IPv4List.AddObject(HostName, TObject(IPv4Address));

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsOverHttpsCache.AddIPv6Item(const HostName: String; var IPv6Address: TIPv6Address);

begin

  if (TDnsOverHttpsCache_IPv6List = nil) then TDnsOverHttpsCache_IPv6List := TStringList.Create;

  TDnsOverHttpsCache_IPv6List.AddObject(HostName, TObject(@IPv6Address));

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsOverHttpsCache.FindIPv4Item(const HostName: String; var IPv4Address: TIPv4Address): Boolean;

var
  ListIndex: Integer;

begin

  if (TDnsOverHttpsCache_IPv4List <> nil) then begin

    ListIndex := TDnsOverHttpsCache_IPv4List.IndexOf(HostName); if (ListIndex >= 0) then begin

      IPv4Address := TIPv4Address(TDnsOverHttpsCache_IPv4List.Objects[ListIndex]);

      Result := True;

      Exit;

    end;

  end;

  Result := False;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsOverHttpsCache.FindIPv6Item(const HostName: String; var IPv6Address: TIPv6Address): Boolean;

var
  ListIndex: Integer;

begin

  if (TDnsOverHttpsCache_IPv6List <> nil) then begin

    ListIndex := TDnsOverHttpsCache_IPv6List.IndexOf(HostName); if (ListIndex >= 0) then begin

      IPv6Address := PIPv6Address(TDnsOverHttpsCache_IPv6List.Objects[ListIndex])^;

      Result := True;

      Exit;

    end;

  end;

  Result := False;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsOverHttpsCache.Finalize;

begin

  if (TDnsOverHttpsCache_IPv6List <> nil) then TDnsOverHttpsCache_IPv6List.Free;
  if (TDnsOverHttpsCache_IPv4List <> nil) then TDnsOverHttpsCache_IPv4List.Free;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

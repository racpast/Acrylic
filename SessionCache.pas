// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  SessionCache;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  IPUtils,
  MD5;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TSessionCache = class
    public
      class procedure Initialize;
      class procedure ReserveItem(ReferenceTime: TDateTime; OriginalSessionId: Word; var RemappedSessionId: Word);
      class procedure InsertIPv4Item(ReferenceTime: TDateTime; OriginalSessionId: Word; RemappedSessionId: Word; RequestHash: TMD5Digest; ClientAddress: TIPv4Address; ClientPort: Word; IsSilentUpdate: Boolean; IsCacheException: Boolean);
      class procedure InsertIPv6Item(ReferenceTime: TDateTime; OriginalSessionId: Word; RemappedSessionId: Word; RequestHash: TMD5Digest; ClientAddress: TIPv6Address; ClientPort: Word; IsSilentUpdate: Boolean; IsCacheException: Boolean);
      class function  ExtractIPv4Item(ReferenceTime: TDateTime; var OriginalSessionId: Word; RemappedSessionId: Word; var RequestHash: TMD5Digest; var ClientAddress: TIPv4Address; var ClientPort: Word; var IsSilentUpdate: Boolean; var IsCacheException: Boolean): Boolean;
      class function  ExtractIPv6Item(ReferenceTime: TDateTime; var OriginalSessionId: Word; RemappedSessionId: Word; var RequestHash: TMD5Digest; var ClientAddress: TIPv6Address; var ClientPort: Word; var IsSilentUpdate: Boolean; var IsCacheException: Boolean): Boolean;
      class procedure DeleteItem(RemappedSessionId: Word);
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
  SysUtils;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  SESSION_CACHE_EXPIRATION_TIME = 3.472222e-4; // 30 seconds

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TSessionCacheItem = packed record
    SessionId: Word;
    IsAllocated: Boolean;
    AllocationTime: TDateTime;
    RequestHash: TMD5Digest;
    ClientAddress: TDualIPAddress;
    ClientPort: Word;
    IsSilentUpdate: Boolean;
    IsCacheException: Boolean;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TSessionCache_List: array [0..65535] of TSessionCacheItem;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TSessionCache.Initialize;

begin

  FillChar(TSessionCache_List, SizeOf(TSessionCache_List), 0);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TSessionCache.ReserveItem(ReferenceTime: TDateTime; OriginalSessionId: Word; var RemappedSessionId: Word);

var
  i: Integer;

begin

  for i := 1 to 100 do begin

    RemappedSessionId := Random(65536);

    if not(TSessionCache_List[RemappedSessionId].IsAllocated) or ((ReferenceTime - TSessionCache_List[RemappedSessionId].AllocationTime) > SESSION_CACHE_EXPIRATION_TIME) then Exit;

  end;

  raise Exception.Create('TSessionCache.ReserveItem: All reservation retries for Session ID ' + FormatCurr('00000', OriginalSessionId) + ' have been exhausted.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TSessionCache.InsertIPv4Item(ReferenceTime: TDateTime; OriginalSessionId: Word; RemappedSessionId: Word; RequestHash: TMD5Digest; ClientAddress: TIPv4Address; ClientPort: Word; IsSilentUpdate: Boolean; IsCacheException: Boolean);

begin

  TSessionCache_List[RemappedSessionId].IsAllocated := True;
  TSessionCache_List[RemappedSessionId].AllocationTime := ReferenceTime;

  TSessionCache_List[RemappedSessionId].SessionId := OriginalSessionId;
  TSessionCache_List[RemappedSessionId].RequestHash := RequestHash;
  TSessionCache_List[RemappedSessionId].ClientAddress := TDualIPAddressUtility.CreateFromIPv4Address(ClientAddress);
  TSessionCache_List[RemappedSessionId].ClientPort := ClientPort;
  TSessionCache_List[RemappedSessionId].IsSilentUpdate := IsSilentUpdate;
  TSessionCache_List[RemappedSessionId].IsCacheException := IsCacheException;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TSessionCache.InsertIPv6Item(ReferenceTime: TDateTime; OriginalSessionId: Word; RemappedSessionId: Word; RequestHash: TMD5Digest; ClientAddress: TIPv6Address; ClientPort: Word; IsSilentUpdate: Boolean; IsCacheException: Boolean);

begin

  TSessionCache_List[RemappedSessionId].IsAllocated := True;
  TSessionCache_List[RemappedSessionId].AllocationTime := ReferenceTime;

  TSessionCache_List[RemappedSessionId].SessionId := OriginalSessionId;
  TSessionCache_List[RemappedSessionId].RequestHash := RequestHash;
  TSessionCache_List[RemappedSessionId].ClientAddress := TDualIPAddressUtility.CreateFromIPv6Address(ClientAddress);
  TSessionCache_List[RemappedSessionId].ClientPort := ClientPort;
  TSessionCache_List[RemappedSessionId].IsSilentUpdate := IsSilentUpdate;
  TSessionCache_List[RemappedSessionId].IsCacheException := IsCacheException;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TSessionCache.ExtractIPv4Item(ReferenceTime: TDateTime; var OriginalSessionId: Word; RemappedSessionId: Word; var RequestHash: TMD5Digest; var ClientAddress: TIPv4Address; var ClientPort: Word; var IsSilentUpdate: Boolean; var IsCacheException: Boolean): Boolean;

begin

  if TSessionCache_List[RemappedSessionId].IsAllocated and not(TSessionCache_List[RemappedSessionId].ClientAddress.IsIPv6Address) then begin

    OriginalSessionId := TSessionCache_List[RemappedSessionId].SessionId;
    RequestHash := TSessionCache_List[RemappedSessionId].RequestHash;
    ClientAddress := TSessionCache_List[RemappedSessionId].ClientAddress.IPv4Address;
    ClientPort := TSessionCache_List[RemappedSessionId].ClientPort;
    IsSilentUpdate := TSessionCache_List[RemappedSessionId].IsSilentUpdate;
    IsCacheException := TSessionCache_List[RemappedSessionId].IsCacheException;

    Result := True;

  end else begin

    Result := False;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TSessionCache.ExtractIPv6Item(ReferenceTime: TDateTime; var OriginalSessionId: Word; RemappedSessionId: Word; var RequestHash: TMD5Digest; var ClientAddress: TIPv6Address; var ClientPort: Word; var IsSilentUpdate: Boolean; var IsCacheException: Boolean): Boolean;

begin

  if TSessionCache_List[RemappedSessionId].IsAllocated and TSessionCache_List[RemappedSessionId].ClientAddress.IsIPv6Address then begin

    OriginalSessionId := TSessionCache_List[RemappedSessionId].SessionId;
    RequestHash := TSessionCache_List[RemappedSessionId].RequestHash;
    ClientAddress := TSessionCache_List[RemappedSessionId].ClientAddress.IPv6Address;
    ClientPort := TSessionCache_List[RemappedSessionId].ClientPort;
    IsSilentUpdate := TSessionCache_List[RemappedSessionId].IsSilentUpdate;
    IsCacheException := TSessionCache_List[RemappedSessionId].IsCacheException;

    Result := True;

  end else begin

    Result := False;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TSessionCache.DeleteItem(RemappedSessionId: Word);

begin

  TSessionCache_List[RemappedSessionId].IsAllocated := False;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TSessionCache.Finalize;

begin

  // Nothing to do.

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

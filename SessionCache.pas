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
  CommunicationChannels,
  MD5;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TSessionCache = class
    public
      class procedure Initialize;
      class procedure Reserve(ReferenceTime: TDateTime; OriginalSessionId: Word; var RemappedSessionId: Word);
      class procedure Insert(ReferenceTime: TDateTime; OriginalSessionId: Word; RemappedSessionId: Word; RequestHash: TMD5Digest; ClientAddress: TDualIPAddress; ClientPort: Word; IsSilentUpdate: Boolean; IsCacheException: Boolean);
      class function  Extract(ReferenceTime: TDateTime; var OriginalSessionId: Word; RemappedSessionId: Word; var RequestHash: TMD5Digest; var ClientAddress: TDualIPAddress; var ClientPort: Word; var IsSilentUpdate: Boolean; var IsCacheException: Boolean): Boolean;
      class procedure Delete(RemappedSessionId: Word);
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
  SESSION_CACHE_EXPIRATION_TIME_1 = 6.944444e-4; // 60 seconds
  SESSION_CACHE_EXPIRATION_TIME_2 = 3.472222e-4; // 30 seconds
  SESSION_CACHE_EXPIRATION_TIME_3 = 1.736111e-4; // 15 seconds

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

class procedure TSessionCache.Reserve(ReferenceTime: TDateTime; OriginalSessionId: Word; var RemappedSessionId: Word);

var
  i: Integer;

begin

  for i := 1 to 10 do begin

    RemappedSessionId := Random(65536);

    if not(TSessionCache_List[RemappedSessionId].IsAllocated) or ((ReferenceTime - TSessionCache_List[RemappedSessionId].AllocationTime) > SESSION_CACHE_EXPIRATION_TIME_1) then Exit;

  end;

  for i := 1 to 10 do begin

    RemappedSessionId := Random(65536);

    if not(TSessionCache_List[RemappedSessionId].IsAllocated) or ((ReferenceTime - TSessionCache_List[RemappedSessionId].AllocationTime) > SESSION_CACHE_EXPIRATION_TIME_2) then Exit;

  end;

  for i := 1 to 10 do begin

    RemappedSessionId := Random(65536);

    if not(TSessionCache_List[RemappedSessionId].IsAllocated) or ((ReferenceTime - TSessionCache_List[RemappedSessionId].AllocationTime) > SESSION_CACHE_EXPIRATION_TIME_3) then Exit;

  end;

  while (True) do begin

    RemappedSessionId := Random(65536);

    if not(TSessionCache_List[RemappedSessionId].IsAllocated) or ((ReferenceTime - TSessionCache_List[RemappedSessionId].AllocationTime) > SESSION_CACHE_EXPIRATION_TIME_3) then Exit else Sleep(50);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TSessionCache.Insert(ReferenceTime: TDateTime; OriginalSessionId: Word; RemappedSessionId: Word; RequestHash: TMD5Digest; ClientAddress: TDualIPAddress; ClientPort: Word; IsSilentUpdate: Boolean; IsCacheException: Boolean);

begin

  TSessionCache_List[RemappedSessionId].IsAllocated := True;
  TSessionCache_List[RemappedSessionId].AllocationTime := ReferenceTime;

  TSessionCache_List[RemappedSessionId].SessionId := OriginalSessionId;
  TSessionCache_List[RemappedSessionId].RequestHash := RequestHash;
  TSessionCache_List[RemappedSessionId].ClientAddress := ClientAddress;
  TSessionCache_List[RemappedSessionId].ClientPort := ClientPort;
  TSessionCache_List[RemappedSessionId].IsSilentUpdate := IsSilentUpdate;
  TSessionCache_List[RemappedSessionId].IsCacheException := IsCacheException;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TSessionCache.Extract(ReferenceTime: TDateTime; var OriginalSessionId: Word; RemappedSessionId: Word; var RequestHash: TMD5Digest; var ClientAddress: TDualIPAddress; var ClientPort: Word; var IsSilentUpdate: Boolean; var IsCacheException: Boolean): Boolean;

begin

  if TSessionCache_List[RemappedSessionId].IsAllocated then begin

    OriginalSessionId := TSessionCache_List[RemappedSessionId].SessionId;
    RequestHash := TSessionCache_List[RemappedSessionId].RequestHash;
    ClientAddress := TSessionCache_List[RemappedSessionId].ClientAddress;
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

class procedure TSessionCache.Delete(RemappedSessionId: Word);

begin

    TSessionCache_List[RemappedSessionId].IsAllocated := False;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TSessionCache.Finalize;

begin

  // Nothing to do

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
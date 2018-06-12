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
  CommunicationChannels;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TSessionCache = class
    public
      class procedure Initialize;
      class procedure Insert(SessionId: Word; RequestHash: Int64; ClientAddress: TDualIPAddress; ClientPort: Word; IsSilentUpdate: Boolean; IsCacheException: Boolean);
      class function  Extract(SessionId: Word; var RequestHash: Int64; var ClientAddress: TDualIPAddress; var ClientPort: Word; var IsSilentUpdate: Boolean; var IsCacheException: Boolean): Boolean;
      class procedure Delete(SessionId: Word);
      class procedure Finalize;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TSessionCacheItem = record
    IsAllocated: Boolean;
    RequestHash: Int64;
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

class procedure TSessionCache.Insert(SessionId: Word; RequestHash: Int64; ClientAddress: TDualIPAddress; ClientPort: Word; IsSilentUpdate: Boolean; IsCacheException: Boolean);

begin

  TSessionCache_List[SessionId].IsAllocated := True;
  TSessionCache_List[SessionId].RequestHash := RequestHash;
  TSessionCache_List[SessionId].ClientAddress := ClientAddress;
  TSessionCache_List[SessionId].ClientPort := ClientPort;
  TSessionCache_List[SessionId].IsSilentUpdate := IsSilentUpdate;
  TSessionCache_List[SessionId].IsCacheException := IsCacheException;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TSessionCache.Extract(SessionId: Word; var RequestHash: Int64; var ClientAddress: TDualIPAddress; var ClientPort: Word; var IsSilentUpdate: Boolean; var IsCacheException: Boolean): Boolean;

begin

  if TSessionCache_List[SessionId].IsAllocated then begin

    RequestHash := TSessionCache_List[SessionId].RequestHash;
    ClientAddress := TSessionCache_List[SessionId].ClientAddress;
    ClientPort := TSessionCache_List[SessionId].ClientPort;
    IsSilentUpdate := TSessionCache_List[SessionId].IsSilentUpdate;
    IsCacheException := TSessionCache_List[SessionId].IsCacheException;

    Result := True;

  end else begin

    Result := False;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TSessionCache.Delete(SessionId: Word);

begin

    TSessionCache_List[SessionId].IsAllocated := False;

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
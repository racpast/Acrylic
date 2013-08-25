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

type
  TSessionCache = class
    public
      class procedure Initialize();
      class procedure Insert(SessionId: Word; RequestHash: Int64; ClientAddress: Integer; ClientPort: Word; SilentUpdate: Boolean; CacheException: Boolean);
      class function  Extract(SessionId: Word; var RequestHash: Int64; var ClientAddress: Integer; var ClientPort: Word; var SilentUpdate: Boolean; var CacheException: Boolean): Boolean;
      class procedure Delete(SessionId: Word);
      class procedure Finalize();
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
    RequestHash   : Int64;
    ClientAddress : Integer;
    ClientPort    : Word;
    Flags         : Word;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TSessionCache_List: array [0..65535] of TSessionCacheItem;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TSessionCache.Initialize();
begin
  FillChar(TSessionCache_List, SizeOf(TSessionCache_List), 0);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TSessionCache.Insert(SessionId: Word; RequestHash: Int64; ClientAddress: Integer; ClientPort: Word; SilentUpdate: Boolean; CacheException: Boolean);
begin
  // Set parameters
  TSessionCache_List[SessionId].RequestHash   := RequestHash;
  TSessionCache_List[SessionId].ClientAddress := ClientAddress;
  TSessionCache_List[SessionId].ClientPort    := ClientPort;

  // Set flags (the first bit sets the allocated flag)
  TSessionCache_List[SessionId].Flags := 1 or (Word(SilentUpdate) shl 1) or (Word(CacheException) shl 2);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TSessionCache.Extract(SessionId: Word; var RequestHash: Int64; var ClientAddress: Integer; var ClientPort: Word; var SilentUpdate: Boolean; var CacheException: Boolean): Boolean;
begin
  if ((TSessionCache_List[SessionId].Flags and 1) > 0) then begin

    RequestHash    := TSessionCache_List[SessionId].RequestHash;
    ClientAddress  := TSessionCache_List[SessionId].ClientAddress;
    ClientPort     := TSessionCache_List[SessionId].ClientPort;

    SilentUpdate   := (TSessionCache_List[SessionId].Flags and 2) > 0;
    CacheException := (TSessionCache_List[SessionId].Flags and 4) > 0;

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
    TSessionCache_List[SessionId].Flags := 0;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TSessionCache.Finalize();
begin
  // Nothing to do
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
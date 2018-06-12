// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  AddressCache;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Classes,
  SysUtils;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TAddressCacheFindResult = (NotFound, NeedsUpdate, RecentEnough);

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  PAddressCacheItem = ^TAddressCacheItem;
  TAddressCacheItem = record
    Time: Cardinal;
    ResponseLen: Integer;
    Response: Pointer;
    IsNegativeResponse: Boolean;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  PHashPointerItem = ^THashPointerItem;
  THashPointerItem = record
    LHash: Int64;
    LData: Pointer;
    LNext: PHashPointerItem;
    RHash: Int64;
    RData: Pointer;
    RNext: PHashPointerItem;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TAddressCache = class
    public
      class procedure Initialize;
      class procedure Finalize;
    public
      class procedure Add(ArrivalTime: TDateTime; RequestHash: Int64; Response: Pointer; ResponseLen: Integer; IsNegativeResponse: Boolean);
      class function  Find(ArrivalTime: TDateTime; RequestHash: Int64; Response: Pointer; var ResponseLen: Integer): TAddressCacheFindResult;
    public
      class procedure ScavengeToFile(FileName: String);
      class procedure LoadFromFile(FileName: String);
    private
      class function  ShortTime(Value: TDateTime): Cardinal;
    private
      class procedure InternalAdd(Hash: Int64; Data: Pointer);
      class procedure InternalIns(Hash: Int64; Data: Pointer; Item: PHashPointerItem; Bull: Int64; Half: Int64);
      class procedure InternalXpl(Hash: Int64; Data: Pointer; Item: PHashPointerItem; Bull: Int64; Half: Int64);
      class procedure InternalXpr(Hash: Int64; Data: Pointer; Item: PHashPointerItem; Bull: Int64; Half: Int64);
    private
      class procedure InternalFind(Hash: Int64; var Data: Pointer; Item: PHashPointerItem);
      class procedure InternalEraseLastFoundItem;
    private
      class procedure InternalScavengeItemToFile(FileStream: TFileStream; Time: Cardinal; Item: PHashPointerItem);
      class procedure InternalScavengePartToFile(FileStream: TFileStream; Time: Cardinal; Hash: Int64; Part: Pointer);
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Configuration,
  MemoryStore,
  Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TAddressCache_MemoryStore: TMemoryStore;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TAddressCache_Root: PHashPointerItem; TAddressCache_LastFoundItem: PHashPointerItem; TAddressCache_LastFoundSide: Integer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.Initialize;

begin

  TAddressCache_MemoryStore := TMemoryStore.Create;

  TAddressCache_Root := nil;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TAddressCache.ShortTime(Value: TDateTime): Cardinal;

begin

  Result := Cardinal(Round((Value - 29221.0) * 1440.0));

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.InternalXpl(Hash: Int64; Data: Pointer; Item: PHashPointerItem; Bull: Int64; Half: Int64);

begin

  if (Item^.LNext = nil) then begin

    Item^.LNext := TAddressCache_MemoryStore.GetMemory(SizeOf(THashPointerItem));

    Item^.LNext^.LHash := Hash; Item^.LNext^.LData := Data; Item^.LNext^.LNext := nil;
    Item^.LNext^.RHash := Hash; Item^.LNext^.RData := Data; Item^.LNext^.RNext := nil;

  end else begin

    Self.InternalIns(Hash, Data, Item^.LNext, Bull - Half, Half div 2);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.InternalXpr(Hash: Int64; Data: Pointer; Item: PHashPointerItem; Bull: Int64; Half: Int64);

begin

  if (Item^.RNext = nil) then begin

    Item^.RNext := TAddressCache_MemoryStore.GetMemory(SizeOf(THashPointerItem));

    Item^.RNext^.LHash := Hash; Item^.RNext^.LData := Data; Item^.RNext^.LNext := nil;
    Item^.RNext^.RHash := Hash; Item^.RNext^.RData := Data; Item^.RNext^.RNext := nil;

  end else begin

    Self.InternalIns(Hash, Data, Item^.RNext, Bull + Half, Half div 2);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.InternalIns(Hash: Int64; Data: Pointer; Item: PHashPointerItem; Bull: Int64; Half: Int64);

begin

  if (Item^.LHash <> Item^.RHash) then begin

    if (Item^.LHash = Hash) then begin
      Item^.LData := Data;
    end else if (Item^.RHash = Hash) then begin
      Item^.RData := Data;
    end else if (Hash < Item^.RHash) then begin
      Self.InternalXpr(Hash, Data, Item, Bull, Half);
    end else if (Hash > Item^.LHash) then begin
      Self.InternalXpl(Hash, Data, Item, Bull, Half);
    end else if (Hash <= Bull) then begin
      Self.InternalXpr(Item^.RHash, Item^.RData, Item, Bull, Half); Item^.RHash := Hash; Item^.RData := Data;
    end else begin
      Self.InternalXpl(Item^.LHash, Item^.LData, Item, Bull, Half); Item^.LHash := Hash; Item^.LData := Data;
    end;

  end else begin

    if (Item^.LHash = Hash) then begin
      Item^.LData := Data; Item^.RData := Data;
    end else if (Hash > Item^.LHash) then begin
      Item^.LHash := Hash; Item^.LData := Data;
    end else begin
      Item^.RHash := Hash; Item^.RData := Data;
    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.InternalAdd(Hash: Int64; Data: Pointer);

begin

  if (TAddressCache_Root = nil) then begin

    TAddressCache_Root := TAddressCache_MemoryStore.GetMemory(SizeOf(THashPointerItem));

    TAddressCache_Root^.LHash := Hash; TAddressCache_Root^.LData := Data; TAddressCache_Root^.LNext := nil;
    TAddressCache_Root^.RHash := Hash; TAddressCache_Root^.RData := Data; TAddressCache_Root^.RNext := nil;

  end else begin

    Self.InternalIns(Hash, Data, TAddressCache_Root, Int64(0), Int64($4000000000000000));

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.InternalFind(Hash: Int64; var Data: Pointer; Item: PHashPointerItem);

begin

  if (Hash = Item^.LHash) then begin

    if (Item^.LData <> nil) then begin
      Data := Item^.LData; TAddressCache_LastFoundItem := Item; TAddressCache_LastFoundSide := -1;
    end;

  end else if (Hash = Item^.RHash) then begin

    if (Item^.RData <> nil) then begin
      Data := Item^.RData; TAddressCache_LastFoundItem := Item; TAddressCache_LastFoundSide := +1;
    end;

  end else if (Hash > Item^.LHash) then begin

    if (Item^.LNext <> nil) then Self.InternalFind(Hash, Data, Item^.LNext);

  end else if (Hash < Item^.RHash) then begin

    if (Item^.RNext <> nil) then Self.InternalFind(Hash, Data, Item^.RNext);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.InternalEraseLastFoundItem;

begin

  if (TAddressCache_LastFoundItem <> nil) then begin

    if (TAddressCache_LastFoundSide < 0) then begin
      TAddressCache_LastFoundItem^.LData := nil; if (TAddressCache_LastFoundItem^.LHash = TAddressCache_LastFoundItem^.RHash) then TAddressCache_LastFoundItem^.RData := nil;
    end else if (TAddressCache_LastFoundSide > 0) then begin
      TAddressCache_LastFoundItem^.RData := nil; if (TAddressCache_LastFoundItem^.LHash = TAddressCache_LastFoundItem^.RHash) then TAddressCache_LastFoundItem^.LData := nil;
    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.Add(ArrivalTime: TDateTime; RequestHash: Int64; Response: Pointer; ResponseLen: Integer; IsNegativeResponse: Boolean);

var
  AddressCacheItem: PAddressCacheItem;

begin

  AddressCacheItem := TAddressCache_MemoryStore.GetMemory(SizeOf(TAddressCacheItem));

  AddressCacheItem^.Time := ShortTime(ArrivalTime);
  AddressCacheItem^.IsNegativeResponse := IsNegativeResponse;

  AddressCacheItem^.Response := TAddressCache_MemoryStore.GetMemory(ResponseLen); Move(Response^, AddressCacheItem^.Response^, ResponseLen); AddressCacheItem^.ResponseLen := ResponseLen;

  Self.InternalAdd(RequestHash, AddressCacheItem);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TAddressCache.Find(ArrivalTime: TDateTime; RequestHash: Int64; Response: Pointer; var ResponseLen: Integer): TAddressCacheFindResult;

var
  AddressCacheItem: PAddressCacheItem; ElapsedTime: Cardinal;

begin

  Result := NotFound; if (TAddressCache_Root <> nil) then begin

    AddressCacheItem := nil; Self.InternalFind(RequestHash, Pointer(AddressCacheItem), TAddressCache_Root); if (AddressCacheItem <> nil) then begin

      ElapsedTime := ShortTime(ArrivalTime) - AddressCacheItem^.Time;

      if (not AddressCacheItem^.IsNegativeResponse and (ElapsedTime <= Cardinal(TConfiguration.GetAddressCacheScavengingTime))) or (AddressCacheItem^.IsNegativeResponse and (ElapsedTime <= Cardinal(TConfiguration.GetAddressCacheNegativeTime))) then begin

        ResponseLen := AddressCacheItem^.ResponseLen; Move(AddressCacheItem^.Response^, Response^, ResponseLen);

        if (ElapsedTime <= Cardinal(TConfiguration.GetAddressCacheSilentUpdateTime)) then Result := RecentEnough else Result := NeedsUpdate;

      end else begin

        Self.InternalEraseLastFoundItem;

      end;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.InternalScavengeItemToFile(FileStream: TFileStream; Time: Cardinal; Item: PHashPointerItem);

begin

  if (Item^.LData <> nil) then Self.InternalScavengePartToFile(FileStream, Time, Item^.LHash, Item^.LData);
  if (Item^.LHash <> Item^.RHash) and (Item^.RData <> nil) then Self.InternalScavengePartToFile(FileStream, Time, Item^.RHash, Item^.RData);

  if (Item^.LNext <> nil) then Self.InternalScavengeItemToFile(FileStream, Time, Item^.LNext);
  if (Item^.RNext <> nil) then Self.InternalScavengeItemToFile(FileStream, Time, Item^.RNext);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.InternalScavengePartToFile(FileStream: TFileStream; Time: Cardinal; Hash: Int64; Part: Pointer);

var
  ElapsedTime: Cardinal;

begin

  ElapsedTime := Time - PAddressCacheItem(Part)^.Time;

  if (not PAddressCacheItem(Part)^.IsNegativeResponse and (ElapsedTime <= Cardinal(TConfiguration.GetAddressCacheScavengingTime))) or (PAddressCacheItem(Part)^.IsNegativeResponse and (ElapsedTime <= Cardinal(TConfiguration.GetAddressCacheNegativeTime))) then begin

    if (FileStream.Write(Hash, SizeOf(Int64)) <> SizeOf(Int64)) then raise Exception.Create('TAddressCache.ScavengeToFile: Saving of the Hash field failed.');

    if (FileStream.Write(PAddressCacheItem(Part)^.Time, SizeOf(Cardinal)) <> SizeOf(Cardinal)) then raise Exception.Create('TAddressCache.ScavengeToFile: Saving of the Time field failed.');

    if (FileStream.Write(PAddressCacheItem(Part)^.ResponseLen, SizeOf(Integer)) <> SizeOf(Integer)) then raise Exception.Create('TAddressCache.ScavengeToFile: Saving of the ResponseLen field failed.');

    if (FileStream.Write(PAddressCacheItem(Part)^.Response^, PAddressCacheItem(Part)^.ResponseLen) <> PAddressCacheItem(Part)^.ResponseLen) then raise Exception.Create('TAddressCache.ScavengeToFile: Saving of the Response field failed.');

    if (FileStream.Write(PAddressCacheItem(Part)^.IsNegativeResponse, SizeOf(Boolean)) <> SizeOf(Boolean)) then raise Exception.Create('TAddressCache.ScavengeToFile: Saving of the IsNegativeResponse field failed.');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.ScavengeToFile(FileName: String);

var
  FileStream: TFileStream;

begin

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TAddressCache.ScavengeToFile: Saving address cache items...');

  FileStream := TFileStream.Create(FileName, fmCreate, fmShareDenyWrite);

  try

    if (TAddressCache_Root <> nil) then Self.InternalScavengeItemToFile(FileStream, ShortTime(Now), TAddressCache_Root);

  finally

    FileStream.Free;

  end;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TAddressCache.ScavengeToFile: Address cache items saved successfully.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.LoadFromFile(FileName: String);

var
  NumberOfItemsLoaded: Cardinal; FileStream: TFileStream; Hash: Int64; AddressCacheItem: PAddressCacheItem;

begin

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TAddressCache.LoadFromFile: Loading address cache items...');

  NumberOfItemsLoaded := 0; FileStream := TFileStream.Create(FileName, fmOpenRead, fmShareDenyWrite); try

    while (FileStream.Position < FileStream.Size) do begin

      try

        AddressCacheItem := TAddressCache_MemoryStore.GetMemory(SizeOf(TAddressCacheItem)); AddressCacheItem^.Response := nil;

        if (SizeOf(Int64) <> FileStream.Read(Hash, SizeOf(Int64))) then raise Exception.Create('TAddressCache.LoadFromFile: Loading of the Hash field failed.');

        if (SizeOf(Cardinal) <> FileStream.Read(AddressCacheItem^.Time, SizeOf(Cardinal))) then raise Exception.Create('TAddressCache.LoadFromFile: Loading of the Time field failed.');

        if (SizeOf(Integer) <> FileStream.Read(AddressCacheItem^.ResponseLen, SizeOf(Integer))) then raise Exception.Create('TAddressCache.LoadFromFile: Loading of the ResponseLen field failed.');

        AddressCacheItem^.Response := TAddressCache_MemoryStore.GetMemory(AddressCacheItem^.ResponseLen);

        if (AddressCacheItem^.ResponseLen <> FileStream.Read(AddressCacheItem^.Response^, AddressCacheItem^.ResponseLen)) then raise Exception.Create('TAddressCache.LoadFromFile: Loading of the Response field failed.');

        if (SizeOf(Boolean) <> FileStream.Read(AddressCacheItem^.IsNegativeResponse, SizeOf(Boolean))) then raise Exception.Create('TAddressCache.LoadFromFile: Loading of the IsNegativeResponse field failed.');

        Self.InternalAdd(Hash, Pointer(AddressCacheItem));

        Inc(NumberOfItemsLoaded);

      except

      end;

    end;

  finally

    FileStream.Free;

  end;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TAddressCache.LoadFromFile: Loaded ' + IntToStr(NumberOfItemsLoaded) + ' address cache items successfully.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.Finalize;

begin

  TAddressCache_MemoryStore.Free;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
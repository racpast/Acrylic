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

type
  TAddressCacheFindResult = (NotFound, NeedsUpdate, RecentEnough);

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  PAddressCacheItem = ^TAddressCacheItem;
  TAddressCacheItem = record
    Time        : Cardinal;
    ResponseLen : Integer;
    Response    : Pointer;
    Flags       : Word;
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
      class procedure Initialize();
      class procedure Add(Arrival: TDateTime; RequestHash: Int64; Response: Pointer; ResponseLen: Integer; NegativeResponse: Boolean);
      class function  Find(Arrival: TDateTime; RequestHash: Int64; Response: Pointer; var ResponseLen: Integer): TAddressCacheFindResult;
      class procedure ScavengeToFile(FileName: String);
      class procedure LoadFromFile(FileName: String);
      class procedure Finalize();
    private
      class function  ShortTime(Value: TDateTime): Cardinal;
    private
      class procedure InternalMem(Data: Pointer);
      class procedure InternalXpl(Hash: Int64; Data: Pointer; Item: PHashPointerItem; Bull: Int64; Half: Int64);
      class procedure InternalXpr(Hash: Int64; Data: Pointer; Item: PHashPointerItem; Bull: Int64; Half: Int64);
      class procedure InternalIns(Hash: Int64; Data: Pointer; Item: PHashPointerItem; Bull: Int64; Half: Int64);
      class procedure InternalAdd(Hash: Int64; Data: Pointer);
    private
      class procedure InternalFind(Hash: Int64; var Data: Pointer; Item: PHashPointerItem);
      class procedure InternalEraseLastFoundItem();
    private
      class procedure InternalScavengeItemToFile(Reference: Cardinal; Item: PHashPointerItem);
      class procedure InternalScavengeItemPartToFile(Reference: Cardinal; Hash: Int64; Data: Pointer);
    private
      class procedure InternalDestroy(Item: PHashPointerItem);
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Classes, SysUtils, Configuration, Compression, Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TAddressCache_Root: PHashPointerItem;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TAddressCache_LastFoundItem: PHashPointerItem; TAddressCache_LastFoundSide: Integer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TAddressCache_FileStream: TFileStream;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.Initialize;
begin
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
    GetMem(Item^.LNext, SizeOf(THashPointerItem));
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
    GetMem(Item^.RNext, SizeOf(THashPointerItem));
    Item^.RNext^.LHash := Hash; Item^.RNext^.LData := Data; Item^.RNext^.LNext := nil;
    Item^.RNext^.RHash := Hash; Item^.RNext^.RData := Data; Item^.RNext^.RNext := nil;
  end else begin
    Self.InternalIns(Hash, Data, Item^.RNext, Bull + Half, Half div 2);
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.InternalMem(Data: Pointer);
begin
  if (Data <> nil) then begin
    FreeMem(PAddressCacheItem(Data)^.Response, PAddressCacheItem(Data)^.ResponseLen); FreeMem(Data, SizeOf(TAddressCacheItem));
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.InternalIns(Hash: Int64; Data: Pointer; Item: PHashPointerItem; Bull: Int64; Half: Int64);
begin
  if (Item^.LHash <> Item^.RHash) then begin

    if (Item^.LHash = Hash) then begin
      Self.InternalMem(Item^.LData); Item^.LData := Data;
    end else if (Item^.RHash = Hash) then begin
      Self.InternalMem(Item^.RData); Item^.RData := Data;
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
      Self.InternalMem(Item^.LData); Item^.LData := Data; Item^.RData := Data;
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
    GetMem(TAddressCache_Root, SizeOf(THashPointerItem));
    TAddressCache_Root^.LHash := Hash; TAddressCache_Root^.LData := Data; TAddressCache_Root^.LNext := nil;
    TAddressCache_Root^.RHash := Hash; TAddressCache_Root^.RData := Data; TAddressCache_Root^.RNext := nil;
  end else begin
    Self.InternalIns(Hash, Data, TAddressCache_Root, Int64(0), Int64($4000000000000000));
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.Add(Arrival: TDateTime; RequestHash: Int64; Response: Pointer; ResponseLen: Integer; NegativeResponse: Boolean);
var
  AddressCacheItem: PAddressCacheItem;
begin
  // Allocate memory for the item
  GetMem(AddressCacheItem, SizeOf(TAddressCacheItem));

  if not(TConfiguration.GetAddressCacheDisableCompression()) and (TCompression.Inflate(Response, ResponseLen) < ResponseLen) then begin

    AddressCacheItem^.Time        := ShortTime(Arrival);
    AddressCacheItem^.ResponseLen := TCompression.GetLength();
    AddressCacheItem^.Flags       := 1 or (Word(NegativeResponse) shl 1);

    // Allocate memory for the Response and copy compressed data
    GetMem(AddressCacheItem^.Response, AddressCacheItem^.ResponseLen); Move(TCompression.GetBuffer()^, AddressCacheItem^.Response^, AddressCacheItem^.ResponseLen);

  end else begin // Compression is either not useful or disabled!

    AddressCacheItem^.Time        := ShortTime(Arrival);
    AddressCacheItem^.ResponseLen := ResponseLen;
    AddressCacheItem^.Flags       := 0 or (Word(NegativeResponse) shl 1);

    // Allocate memory for the Response and copy the original data
    GetMem(AddressCacheItem^.Response, AddressCacheItem^.ResponseLen); Move(Response^, AddressCacheItem^.Response^, AddressCacheItem^.ResponseLen);

  end;

  // Add the item to the AddressCache tree
  Self.InternalAdd(RequestHash, AddressCacheItem);
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

class procedure TAddressCache.InternalEraseLastFoundItem();
begin
  if (TAddressCache_LastFoundItem <> nil) then begin
    if (TAddressCache_LastFoundSide < 0) then begin
      Self.InternalMem(TAddressCache_LastFoundItem^.LData); TAddressCache_LastFoundItem^.LData := nil; if (TAddressCache_LastFoundItem^.LHash = TAddressCache_LastFoundItem^.RHash) then TAddressCache_LastFoundItem^.RData := nil;
    end else if (TAddressCache_LastFoundSide > 0) then begin
      Self.InternalMem(TAddressCache_LastFoundItem^.RData); TAddressCache_LastFoundItem^.RData := nil; if (TAddressCache_LastFoundItem^.LHash = TAddressCache_LastFoundItem^.RHash) then TAddressCache_LastFoundItem^.LData := nil;
    end;
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TAddressCache.Find(Arrival: TDateTime; RequestHash: Int64; Response: Pointer; var ResponseLen: Integer): TAddressCacheFindResult;
var
  AddressCacheItem: PAddressCacheItem; Elapsed: Cardinal;
begin
  // Default
  Result := NotFound; if (TAddressCache_Root <> nil) then begin

    // Search the hash into the AddressCache list, if it's found...
    AddressCacheItem := nil; Self.InternalFind(RequestHash, Pointer(AddressCacheItem), TAddressCache_Root); if (AddressCacheItem <> nil) then begin

      Elapsed := ShortTime(Arrival) - AddressCacheItem^.Time;

      // If the item is not older than the positive or negative time (which one depends by its type)...
      if ((((AddressCacheItem^.Flags and 2) = 0) and (Elapsed <= Cardinal(TConfiguration.GetAddressCacheScavengingTime())))  or
          (((AddressCacheItem^.Flags and 2) > 0) and (Elapsed <= Cardinal(TConfiguration.GetAddressCacheNegativeTime())  ))) then begin

        if ((AddressCacheItem^.Flags and 1) > 0) then begin // If the item is compressed...

          // Decompress the data and copy it to the response
          ResponseLen := TCompression.Deflate(AddressCacheItem^.Response, AddressCacheItem^.ResponseLen); Move(TCompression.GetBuffer()^, Response^, ResponseLen);

        end else begin // The item is not compressed!

          // Get the item's Response
          ResponseLen := AddressCacheItem^.ResponseLen; Move(AddressCacheItem^.Response^, Response^, ResponseLen);

        end;

        // Return whether the Request needs a silent update or not (if it's older than the silent update time)
        if (Elapsed <= Cardinal(TConfiguration.GetAddressCacheSilentUpdateTime())) then Result := RecentEnough else Result := NeedsUpdate;

      end else begin // The item is older than the scavenging time (so it should be removed from the list)

        Self.InternalEraseLastFoundItem();

      end;

    end;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.InternalScavengeItemToFile(Reference: Cardinal; Item: PHashPointerItem);
begin
  if (Item^.LData <> nil) then Self.InternalScavengeItemPartToFile(Reference, Item^.LHash, Item^.LData);
  if (Item^.LHash <> Item^.RHash) and (Item^.RData <> nil) then Self.InternalScavengeItemPartToFile(Reference, Item^.RHash, Item^.RData);

  if (Item^.LNext <> nil) then Self.InternalScavengeItemToFile(Reference, Item^.LNext);
  if (Item^.RNext <> nil) then Self.InternalScavengeItemToFile(Reference, Item^.RNext);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.InternalScavengeItemPartToFile(Reference: Cardinal; Hash: Int64; Data: Pointer);
var
  Elapsed: Cardinal;
begin
  Elapsed := Reference - PAddressCacheItem(Data)^.Time;

  // If the item is not older than the positive or negative time (which one depends by its type)...
  if ((((PAddressCacheItem(Data)^.Flags and 2) = 0) and (Elapsed <= Cardinal(TConfiguration.GetAddressCacheScavengingTime())))  or
      (((PAddressCacheItem(Data)^.Flags and 2) > 0) and (Elapsed <= Cardinal(TConfiguration.GetAddressCacheNegativeTime())  ))) then begin

    // Save the hash value
    if (TAddressCache_FileStream.Write(Hash, SizeOf(Int64)) <> SizeOf(Int64)) then raise Exception.Create('TAddressCache.ScavengeToFile: Saving of the Hash field failed.');

    // Save the item's parameters and the Response
    if (TAddressCache_FileStream.Write(PAddressCacheItem(Data)^.Time, SizeOf(Cardinal)) <> SizeOf(Cardinal)) then raise Exception.Create('TAddressCache.ScavengeToFile: Saving of the Time field failed.');
    if (TAddressCache_FileStream.Write(PAddressCacheItem(Data)^.ResponseLen, SizeOf(Integer)) <> SizeOf(Integer)) then raise Exception.Create('TAddressCache.ScavengeToFile: Saving of the ResponseLen field failed.');
    if (TAddressCache_FileStream.Write(PAddressCacheItem(Data)^.Response^, PAddressCacheItem(Data)^.ResponseLen) <> PAddressCacheItem(Data)^.ResponseLen) then raise Exception.Create('TAddressCache.ScavengeToFile: Saving of the Response field failed.');
    if (TAddressCache_FileStream.Write(PAddressCacheItem(Data)^.Flags, SizeOf(Integer)) <> SizeOf(Cardinal)) then raise Exception.Create('TAddressCache.ScavengeToFile: Saving of the Flags field failed.');

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.ScavengeToFile(FileName: String);
begin
  if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TAddressCache.ScavengeToFile: Saving address cache items...');

  TAddressCache_FileStream := TFileStream.Create(FileName, fmCreate, fmShareDenyWrite);

  try

    // Traverse the tree writing items to disk and scavenging old ones
    if (TAddressCache_Root <> nil) then Self.InternalScavengeItemToFile(ShortTime(Now()), TAddressCache_Root);

  finally

    TAddressCache_FileStream.Free;

  end;

  if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TAddressCache.ScavengeToFile: Address cache items saved successfully.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.LoadFromFile(FileName: String);
var
  Hash: Int64; AddressCacheItem: PAddressCacheItem; NumberOfItemsLoaded: Cardinal;
begin
  if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TAddressCache.LoadFromFile: Loading address cache items...');

  NumberOfItemsLoaded := 0; TAddressCache_FileStream := TFileStream.Create(FileName, fmOpenRead, fmShareDenyWrite); try

    while (TAddressCache_FileStream.Position < TAddressCache_FileStream.Size) do begin

      AddressCacheItem := nil; try

        // Allocate memory for the item
        GetMem(AddressCacheItem, SizeOf(TAddressCacheItem)); AddressCacheItem^.Response := nil;

        if (SizeOf(Int64) <> TAddressCache_FileStream.Read(Hash, SizeOf(Int64))) then raise Exception.Create('TAddressCache.LoadFromFile: Loading of the Hash field failed.');
        if (SizeOf(Cardinal) <> TAddressCache_FileStream.Read(AddressCacheItem^.Time, SizeOf(Cardinal))) then raise Exception.Create('TAddressCache.LoadFromFile: Loading of the Time field failed.');
        if (SizeOf(Integer) <> TAddressCache_FileStream.Read(AddressCacheItem^.ResponseLen, SizeOf(Integer))) or (AddressCacheItem^.ResponseLen < MIN_DNS_PACKET_LEN) or (AddressCacheItem^.ResponseLen > MAX_DNS_PACKET_LEN) then raise Exception.Create('TAddressCache.LoadFromFile: Loading of the ResponseLen field failed.');

        // Allocate memory for the Response
        GetMem(AddressCacheItem^.Response, AddressCacheItem^.ResponseLen);

        if (AddressCacheItem^.ResponseLen <> TAddressCache_FileStream.Read(AddressCacheItem^.Response^, AddressCacheItem^.ResponseLen)) then raise Exception.Create('TAddressCache.LoadFromFile: Loading of the Response field failed.');
        if (SizeOf(Cardinal) <> TAddressCache_FileStream.Read(AddressCacheItem^.Flags, SizeOf(Cardinal))) then raise Exception.Create('TAddressCache.LoadFromFile: Loading of the Flags field failed.');

        // Add the item into the AddressCache list
        Self.InternalAdd(Hash, Pointer(AddressCacheItem));

        Inc(NumberOfItemsLoaded);

      except

        on E: Exception do begin

          if (AddressCacheItem <> nil) then begin

            // If the Response has been allocated then deallocate it...
            if (AddressCacheItem^.Response <> nil) then FreeMem(AddressCacheItem^.Response, AddressCacheItem^.ResponseLen);

            // Deallocate the item also
            FreeMem(AddressCacheItem, SizeOf(TAddressCacheItem));

          end;

          raise E;

        end;

      end;

    end;

  finally

    TAddressCache_FileStream.Free;

  end;

  if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TAddressCache.LoadFromFile: Loaded ' + IntToStr(NumberOfItemsLoaded) + ' address cache items successfully.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.InternalDestroy(Item: PHashPointerItem);
begin
  Self.InternalMem(Item^.LData); Item^.LData := nil;
  if (Item^.LHash <> Item^.RHash) then begin Self.InternalMem(Item^.RData); Item^.RData := nil; end;

  if (Item^.LNext <> nil) then Self.InternalDestroy(Item^.LNext);
  if (Item^.RNext <> nil) then Self.InternalDestroy(Item^.RNext);

  FreeMem(Item, SizeOf(THashPointerItem));
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.Finalize();
begin
  if (TAddressCache_Root <> nil) then Self.InternalDestroy(TAddressCache_Root);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
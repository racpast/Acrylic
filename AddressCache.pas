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
  FileIO,
  MD5;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TAddressCacheFindResult = (NotFound, NeedsUpdate, RecentEnough);

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  AddressCacheItemOptionsResponseTypeBitMask    = $03;
  AddressCacheItemOptionsResponseTypeIsPositive = $00;
  AddressCacheItemOptionsResponseTypeIsNegative = $01;
  AddressCacheItemOptionsResponseTypeIsFailure  = $02;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  PAddressCacheItem = ^TAddressCacheItem;
  TAddressCacheItem = record
    TimeStamp   : Integer;
    ResponseLen : Integer;
    Response    : Pointer;
    Options     : Byte;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  PAddressCacheHashTreeItem = ^TAddressCacheHashTreeItem;
  TAddressCacheHashTreeItem = record
    Hash : TMD5Digest;
    Data : PAddressCacheItem;
    L    : PAddressCacheHashTreeItem;
    R    : PAddressCacheHashTreeItem;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TAddressCache = class
    public
      class procedure Initialize;
      class procedure Add(ArrivalTime: TDateTime; RequestHash: TMD5Digest; Response: Pointer; ResponseLen: Integer; Options: Byte);
      class function  Find(ArrivalTime: TDateTime; RequestHash: TMD5Digest; Response: Pointer; var ResponseLen: Integer): TAddressCacheFindResult;
      class procedure LoadFromFile(FileName: String);
      class procedure SaveToFile(FileName: String);
      class procedure Finalize;
    private
      class function  GetTimeStamp(Value: TDateTime): Integer;
    private
      class procedure InternalAdd(RequestHash: TMD5Digest; ResponseData: PAddressCacheItem);
      class procedure InternalFind(RequestHash: TMD5Digest; var ResponseData: PAddressCacheItem);
      class procedure InternalLoadFromFile(FileStream: TBufferedSequentialReadStream; TimeStamp: Integer);
      class procedure InternalSaveToFile(FileStream: TBufferedSequentialWriteStream; TimeStamp: Integer);
      class procedure InternalSaveAddressCacheHashTreeItemToFile(FileStream: TBufferedSequentialWriteStream; TimeStamp: Integer; HashTreeItem: PAddressCacheHashTreeItem);
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SysUtils,
  Configuration,
  DnsProtocol,
  MemoryStore,
  Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TAddressCache_MemoryStore_A: TType2MemoryStore;
  TAddressCache_MemoryStore_B: TType2MemoryStore;
  TAddressCache_MemoryStore_C: TType2MemoryStore;
  TAddressCache_MemoryStore_D: TType2MemoryStore;
  TAddressCache_MemoryStore_E: TType2MemoryStore;
  TAddressCache_MemoryStore_F: TType2MemoryStore;
  TAddressCache_MemoryStore_G: TType2MemoryStore;
  TAddressCache_MemoryStore_H: TType2MemoryStore;
  TAddressCache_MemoryStore_I: TType2MemoryStore;
  TAddressCache_MemoryStore_J: TType2MemoryStore;
  TAddressCache_MemoryStore_K: TType2MemoryStore;
  TAddressCache_MemoryStore_L: TType2MemoryStore;
  TAddressCache_MemoryStore_M: TType2MemoryStore;
  TAddressCache_MemoryStore_N: TType2MemoryStore;
  TAddressCache_MemoryStore_O: TType2MemoryStore;
  TAddressCache_MemoryStore_P: TType2MemoryStore;
  TAddressCache_MemoryStore_Q: TType2MemoryStore;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TAddressCacheMemoryStore = class
    public
      class procedure Initialize;
      class function  GetMemory(Size: Cardinal): Pointer;
      class procedure FreeMemory(Address: Pointer; Size: Cardinal);
      class procedure Finalize;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCacheMemoryStore.Initialize;

begin

  TAddressCache_MemoryStore_A := TType2MemoryStore.Create(98304, 16);
  TAddressCache_MemoryStore_B := TType2MemoryStore.Create(98280, 28);
  TAddressCache_MemoryStore_C := TType2MemoryStore.Create(98304, 64);
  TAddressCache_MemoryStore_D := TType2MemoryStore.Create(98304, 96);
  TAddressCache_MemoryStore_E := TType2MemoryStore.Create(98304, 128);
  TAddressCache_MemoryStore_F := TType2MemoryStore.Create(98240, 160);
  TAddressCache_MemoryStore_G := TType2MemoryStore.Create(98304, 192);
  TAddressCache_MemoryStore_H := TType2MemoryStore.Create(98112, 224);
  TAddressCache_MemoryStore_I := TType2MemoryStore.Create(98304, 256);
  TAddressCache_MemoryStore_J := TType2MemoryStore.Create(98240, 320);
  TAddressCache_MemoryStore_K := TType2MemoryStore.Create(98304, 384);
  TAddressCache_MemoryStore_L := TType2MemoryStore.Create(98112, 448);
  TAddressCache_MemoryStore_M := TType2MemoryStore.Create(98304, 512);
  TAddressCache_MemoryStore_N := TType2MemoryStore.Create(98304, 768);
  TAddressCache_MemoryStore_O := TType2MemoryStore.Create(98304, 1024);
  TAddressCache_MemoryStore_P := TType2MemoryStore.Create(98304, 2048);
  TAddressCache_MemoryStore_Q := TType2MemoryStore.Create(98304, MAX_DNS_PACKET_LEN);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TAddressCacheMemoryStore.GetMemory(Size: Cardinal): Pointer;

begin

  // WriteLn('#ACMEM+' + IntToStr(Size));

       if (Size <= 16)                 then Result := TAddressCache_MemoryStore_A.GetMemory(Size)
  else if (Size <= 28)                 then Result := TAddressCache_MemoryStore_B.GetMemory(Size)
  else if (Size <= 64)                 then Result := TAddressCache_MemoryStore_C.GetMemory(Size)
  else if (Size <= 96)                 then Result := TAddressCache_MemoryStore_D.GetMemory(Size)
  else if (Size <= 128)                then Result := TAddressCache_MemoryStore_E.GetMemory(Size)
  else if (Size <= 160)                then Result := TAddressCache_MemoryStore_F.GetMemory(Size)
  else if (Size <= 192)                then Result := TAddressCache_MemoryStore_G.GetMemory(Size)
  else if (Size <= 224)                then Result := TAddressCache_MemoryStore_H.GetMemory(Size)
  else if (Size <= 256)                then Result := TAddressCache_MemoryStore_I.GetMemory(Size)
  else if (Size <= 320)                then Result := TAddressCache_MemoryStore_J.GetMemory(Size)
  else if (Size <= 384)                then Result := TAddressCache_MemoryStore_K.GetMemory(Size)
  else if (Size <= 448)                then Result := TAddressCache_MemoryStore_L.GetMemory(Size)
  else if (Size <= 512)                then Result := TAddressCache_MemoryStore_M.GetMemory(Size)
  else if (Size <= 768)                then Result := TAddressCache_MemoryStore_N.GetMemory(Size)
  else if (Size <= 1024)               then Result := TAddressCache_MemoryStore_O.GetMemory(Size)
  else if (Size <= 2048)               then Result := TAddressCache_MemoryStore_P.GetMemory(Size)
  else if (Size <= MAX_DNS_PACKET_LEN) then Result := TAddressCache_MemoryStore_Q.GetMemory(Size)
  else raise Exception.Create('Getting memory for TAddressCacheMemoryStore failed for a size of ' + IntToStr(Size) + ' bytes.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCacheMemoryStore.FreeMemory(Address: Pointer; Size: Cardinal);

begin

  // WriteLn('#ACMEM-' + IntToStr(Size));

       if (Size <= 16)                 then TAddressCache_MemoryStore_A.FreeMemory(Address)
  else if (Size <= 28)                 then TAddressCache_MemoryStore_B.FreeMemory(Address)
  else if (Size <= 64)                 then TAddressCache_MemoryStore_C.FreeMemory(Address)
  else if (Size <= 96)                 then TAddressCache_MemoryStore_D.FreeMemory(Address)
  else if (Size <= 128)                then TAddressCache_MemoryStore_E.FreeMemory(Address)
  else if (Size <= 160)                then TAddressCache_MemoryStore_F.FreeMemory(Address)
  else if (Size <= 192)                then TAddressCache_MemoryStore_G.FreeMemory(Address)
  else if (Size <= 224)                then TAddressCache_MemoryStore_H.FreeMemory(Address)
  else if (Size <= 256)                then TAddressCache_MemoryStore_I.FreeMemory(Address)
  else if (Size <= 320)                then TAddressCache_MemoryStore_J.FreeMemory(Address)
  else if (Size <= 384)                then TAddressCache_MemoryStore_K.FreeMemory(Address)
  else if (Size <= 448)                then TAddressCache_MemoryStore_L.FreeMemory(Address)
  else if (Size <= 512)                then TAddressCache_MemoryStore_M.FreeMemory(Address)
  else if (Size <= 768)                then TAddressCache_MemoryStore_N.FreeMemory(Address)
  else if (Size <= 1024)               then TAddressCache_MemoryStore_O.FreeMemory(Address)
  else if (Size <= 2048)               then TAddressCache_MemoryStore_P.FreeMemory(Address)
  else if (Size <= MAX_DNS_PACKET_LEN) then TAddressCache_MemoryStore_Q.FreeMemory(Address)
  else raise Exception.Create('Freeing memory for TAddressCacheMemoryStore failed for a size of ' + IntToStr(Size) + ' bytes.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCacheMemoryStore.Finalize;

begin

  TAddressCache_MemoryStore_Q.Free;
  TAddressCache_MemoryStore_P.Free;
  TAddressCache_MemoryStore_O.Free;
  TAddressCache_MemoryStore_N.Free;
  TAddressCache_MemoryStore_M.Free;
  TAddressCache_MemoryStore_L.Free;
  TAddressCache_MemoryStore_K.Free;
  TAddressCache_MemoryStore_J.Free;
  TAddressCache_MemoryStore_I.Free;
  TAddressCache_MemoryStore_H.Free;
  TAddressCache_MemoryStore_G.Free;
  TAddressCache_MemoryStore_F.Free;
  TAddressCache_MemoryStore_E.Free;
  TAddressCache_MemoryStore_D.Free;
  TAddressCache_MemoryStore_C.Free;
  TAddressCache_MemoryStore_B.Free;
  TAddressCache_MemoryStore_A.Free;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TAddressCache_HashTreeRoot: PAddressCacheHashTreeItem;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.Initialize;

begin

  TAddressCacheMemoryStore.Initialize;

  TAddressCache_HashTreeRoot := nil;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TAddressCache.GetTimeStamp(Value: TDateTime): Integer;

begin

  Result := Trunc((Value - 29221.0) * 1440.0);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.Add(ArrivalTime: TDateTime; RequestHash: TMD5Digest; Response: Pointer; ResponseLen: Integer; Options: Byte);

var
  AddressCacheItem: PAddressCacheItem;

begin

  AddressCacheItem := TAddressCacheMemoryStore.GetMemory(SizeOf(TAddressCacheItem));

  AddressCacheItem^.TimeStamp := GetTimeStamp(ArrivalTime);

  AddressCacheItem^.Response := TAddressCacheMemoryStore.GetMemory(ResponseLen); Move(Response^, AddressCacheItem^.Response^, ResponseLen); AddressCacheItem^.ResponseLen := ResponseLen;

  AddressCacheItem^.Options := Options;

  Self.InternalAdd(RequestHash, AddressCacheItem);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TAddressCache.Find(ArrivalTime: TDateTime; RequestHash: TMD5Digest; Response: Pointer; var ResponseLen: Integer): TAddressCacheFindResult;

var
  AddressCacheItem: PAddressCacheItem; TimeStamp: Integer; ElapsedTime: Integer; AddressCacheItemOptionsResponseType: Byte;

begin

  AddressCacheItem := nil; Self.InternalFind(RequestHash, AddressCacheItem); if (AddressCacheItem <> nil) then begin

    TimeStamp := GetTimeStamp(ArrivalTime);

    AddressCacheItemOptionsResponseType := AddressCacheItem^.Options and AddressCacheItemOptionsResponseTypeBitMask;

    if (TimeStamp > AddressCacheItem^.TimeStamp) then ElapsedTime := TimeStamp - AddressCacheItem^.TimeStamp else ElapsedTime := 0;

    if (AddressCacheItemOptionsResponseType = AddressCacheItemOptionsResponseTypeIsPositive) then begin

      if (ElapsedTime < TConfiguration.GetAddressCacheScavengingTime) then begin

        ResponseLen := AddressCacheItem^.ResponseLen; Move(AddressCacheItem^.Response^, Response^, ResponseLen);

        if (ElapsedTime < TConfiguration.GetAddressCacheSilentUpdateTime) then begin

          Result := RecentEnough; Exit;

        end else begin

          Result := NeedsUpdate; Exit;

        end;

      end;

    end else if (AddressCacheItemOptionsResponseType = AddressCacheItemOptionsResponseTypeIsNegative) then begin

      if (ElapsedTime < TConfiguration.GetAddressCacheNegativeTime) then begin

        ResponseLen := AddressCacheItem^.ResponseLen; Move(AddressCacheItem^.Response^, Response^, ResponseLen);

        Result := RecentEnough; Exit;

      end;

    end else if (AddressCacheItemOptionsResponseType = AddressCacheItemOptionsResponseTypeIsFailure) then begin

      if (ElapsedTime < TConfiguration.GetAddressCacheFailureTime) then begin

        ResponseLen := AddressCacheItem^.ResponseLen; Move(AddressCacheItem^.Response^, Response^, ResponseLen);

        Result := RecentEnough; Exit;

      end;

    end;

  end;

  Result := NotFound;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.LoadFromFile(FileName: String);

var
  FileStream: TBufferedSequentialReadStream;

begin

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TAddressCache.LoadFromFile: Loading address cache items...');

  try

    FileStream := TBufferedSequentialReadStream.Create(FileName, BUFFERED_SEQUENTIAL_STREAM_256KB_BUFFER_SIZE); try

      Self.InternalLoadFromFile(FileStream, GetTimeStamp(Now));

    finally

      FileStream.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TAddressCache.LoadFromFile: ' + E.Message);

  end;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TAddressCache.LoadFromFile: Done loading address cache items.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.SaveToFile(FileName: String);

var
  FileStream: TBufferedSequentialWriteStream;

begin

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TAddressCache.SaveToFile: Saving address cache items...');

  try

    FileStream := TBufferedSequentialWriteStream.Create(FileName, False, BUFFERED_SEQUENTIAL_STREAM_256KB_BUFFER_SIZE); try

      Self.InternalSaveToFile(FileStream, GetTimeStamp(Now));

    finally

      FileStream.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'TAddressCache.SaveToFile: ' + E.Message);

  end;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'TAddressCache.SaveToFile: Done saving address cache items.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.Finalize;

begin

  TAddressCacheMemoryStore.Finalize;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.InternalAdd(RequestHash: TMD5Digest; ResponseData: PAddressCacheItem);

var
  AddressCacheHashTreeItem: PAddressCacheHashTreeItem; CompareResult: Integer;

begin

  if (TAddressCache_HashTreeRoot <> nil) then begin

    AddressCacheHashTreeItem := TAddressCache_HashTreeRoot; while True do begin

      CompareResult := TMD5.Compare(RequestHash, AddressCacheHashTreeItem^.Hash);

      if (CompareResult > 0) then begin

        if (AddressCacheHashTreeItem^.R = nil) then begin

          AddressCacheHashTreeItem^.R := TAddressCacheMemoryStore.GetMemory(SizeOf(TAddressCacheHashTreeItem)); AddressCacheHashTreeItem^.R^.Hash := RequestHash; AddressCacheHashTreeItem^.R^.Data := ResponseData; AddressCacheHashTreeItem^.R^.L := nil; AddressCacheHashTreeItem^.R^.R := nil; Exit;

        end else begin

          AddressCacheHashTreeItem := AddressCacheHashTreeItem^.R;

        end;

      end else if (CompareResult < 0) then begin

        if (AddressCacheHashTreeItem^.L = nil) then begin

          AddressCacheHashTreeItem^.L := TAddressCacheMemoryStore.GetMemory(SizeOf(TAddressCacheHashTreeItem)); AddressCacheHashTreeItem^.L^.Hash := RequestHash; AddressCacheHashTreeItem^.L^.Data := ResponseData; AddressCacheHashTreeItem^.L^.L := nil; AddressCacheHashTreeItem^.L^.R := nil; Exit;

        end else begin

          AddressCacheHashTreeItem := AddressCacheHashTreeItem^.L;

        end;

      end else begin

        if (AddressCacheHashTreeItem^.Data <> nil) then begin

          if (AddressCacheHashTreeItem^.Data^.Response <> nil) then begin

            TAddressCacheMemoryStore.FreeMemory(AddressCacheHashTreeItem^.Data^.Response, AddressCacheHashTreeItem^.Data^.ResponseLen);

          end;

          TAddressCacheMemoryStore.FreeMemory(AddressCacheHashTreeItem^.Data, SizeOf(TAddressCacheItem));

        end;

        AddressCacheHashTreeItem^.Data := ResponseData; Exit;

      end;

    end;

  end else begin

    TAddressCache_HashTreeRoot := TAddressCacheMemoryStore.GetMemory(SizeOf(TAddressCacheHashTreeItem)); TAddressCache_HashTreeRoot^.Hash := RequestHash; TAddressCache_HashTreeRoot^.Data := ResponseData; TAddressCache_HashTreeRoot^.L := nil; TAddressCache_HashTreeRoot^.R := nil;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.InternalFind(RequestHash: TMD5Digest; var ResponseData: PAddressCacheItem);

var
  AddressCacheHashTreeItem: PAddressCacheHashTreeItem; CompareResult: Integer;

begin

  if (TAddressCache_HashTreeRoot <> nil) then begin

    AddressCacheHashTreeItem := TAddressCache_HashTreeRoot; while True do begin

      CompareResult := TMD5.Compare(RequestHash, AddressCacheHashTreeItem^.Hash);

      if (CompareResult > 0) then begin

        if (AddressCacheHashTreeItem^.R <> nil) then begin

          AddressCacheHashTreeItem := AddressCacheHashTreeItem^.R;

        end else begin

          Exit;

        end;

      end else if (CompareResult < 0) then begin

        if (AddressCacheHashTreeItem^.L <> nil) then begin

          AddressCacheHashTreeItem := AddressCacheHashTreeItem^.L;

        end else begin

          Exit;

        end;

      end else begin

        ResponseData := AddressCacheHashTreeItem^.Data; Exit;

      end;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.InternalLoadFromFile(FileStream: TBufferedSequentialReadStream; TimeStamp: Integer);

var
  ToLoad: Boolean; AddressCacheItem: PAddressCacheItem; RequestHash: TMD5Digest; AddressCacheItemOptions: Byte; AddressCacheItemTimeStamp: Integer; AddressCacheItemResponseLen: Integer; ElapsedTime: Integer; AddressCacheItemOptionsResponseType: Byte;

begin

  while (FileStream.Position < FileStream.FileSize) do begin

    ToLoad := False;

    if not(FileStream.Read(RequestHash, SizeOf(TMD5Digest))) then raise Exception.Create('Loading of the Hash field failed.');

    if not(FileStream.Read(AddressCacheItemOptions, SizeOf(Byte))) then raise Exception.Create('Loading of the Options field failed.');

    if not(FileStream.Read(AddressCacheItemTimeStamp, SizeOf(Integer))) then raise Exception.Create('Loading of the TimeStamp field failed.');

    if not(FileStream.Read(AddressCacheItemResponseLen, SizeOf(Integer))) then raise Exception.Create('Loading of the ResponseLen field failed.');

    AddressCacheItemOptionsResponseType := AddressCacheItemOptions and AddressCacheItemOptionsResponseTypeBitMask;

    if (TimeStamp > AddressCacheItemTimeStamp) then ElapsedTime := TimeStamp - AddressCacheItemTimeStamp else ElapsedTime := 0;

    if (AddressCacheItemOptionsResponseType = AddressCacheItemOptionsResponseTypeIsPositive) then begin

      if (ElapsedTime < TConfiguration.GetAddressCacheScavengingTime) then begin

        ToLoad := True;

      end;

    end else if (AddressCacheItemOptionsResponseType = AddressCacheItemOptionsResponseTypeIsNegative) then begin

      if (ElapsedTime < TConfiguration.GetAddressCacheNegativeTime) then begin

        ToLoad := True;

      end;

    end else if (AddressCacheItemOptionsResponseType = AddressCacheItemOptionsResponseTypeIsFailure) then begin

      if (ElapsedTime < TConfiguration.GetAddressCacheFailureTime) then begin

        ToLoad := True;

      end;

    end;

    if ToLoad then begin

      AddressCacheItem := TAddressCacheMemoryStore.GetMemory(SizeOf(TAddressCacheItem));

      AddressCacheItem^.Options := AddressCacheItemOptions;
      AddressCacheItem^.TimeStamp := AddressCacheItemTimeStamp;
      AddressCacheItem^.ResponseLen := AddressCacheItemResponseLen;

      AddressCacheItem^.Response := TAddressCacheMemoryStore.GetMemory(AddressCacheItemResponseLen);

      if not(FileStream.Read(AddressCacheItem^.Response^, AddressCacheItemResponseLen)) then raise Exception.Create('Loading of the Response field failed.');

      Self.InternalAdd(RequestHash, AddressCacheItem);

    end else begin

      if not(FileStream.Advance(AddressCacheItemResponseLen)) then raise Exception.Create('Skipping of the Response field failed.');

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.InternalSaveToFile(FileStream: TBufferedSequentialWriteStream; TimeStamp: Integer);

begin

  if (TAddressCache_HashTreeRoot <> nil) then begin

    Self.InternalSaveAddressCacheHashTreeItemToFile(FileStream, TimeStamp, TAddressCache_HashTreeRoot);

    if not(FileStream.Flush) then raise Exception.Create('Flushing of the buffered file stream failed.');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TAddressCache.InternalSaveAddressCacheHashTreeItemToFile(FileStream: TBufferedSequentialWriteStream; TimeStamp: Integer; HashTreeItem: PAddressCacheHashTreeItem);

var
  ToWrite: Boolean; AddressCacheItem: PAddressCacheItem; ElapsedTime: Integer; AddressCacheItemOptionsResponseType: Byte;

begin

  ToWrite := False;

  AddressCacheItem := HashTreeItem^.Data;

  AddressCacheItemOptionsResponseType := AddressCacheItem^.Options and AddressCacheItemOptionsResponseTypeBitMask;

  if (TimeStamp > AddressCacheItem^.TimeStamp) then ElapsedTime := TimeStamp - AddressCacheItem^.TimeStamp else ElapsedTime := 0;

  if (AddressCacheItemOptionsResponseType = AddressCacheItemOptionsResponseTypeIsPositive) then begin

    if (ElapsedTime < TConfiguration.GetAddressCacheScavengingTime) then begin

      ToWrite := True;

    end;

  end else if (AddressCacheItemOptionsResponseType = AddressCacheItemOptionsResponseTypeIsNegative) then begin

    if (ElapsedTime < TConfiguration.GetAddressCacheNegativeTime) then begin

      ToWrite := True;

    end;

  end else if (AddressCacheItemOptionsResponseType = AddressCacheItemOptionsResponseTypeIsFailure) then begin

    if (ElapsedTime < TConfiguration.GetAddressCacheFailureTime) then begin

      ToWrite := True;

    end;

  end;

  if ToWrite then begin

    if not(FileStream.Write(HashTreeItem^.Hash, SizeOf(TMD5Digest))) then raise Exception.Create('Saving of the Hash field failed.');

    if not(FileStream.Write(AddressCacheItem^.Options, SizeOf(Byte))) then raise Exception.Create('Saving of the Options field failed.');

    if not(FileStream.Write(AddressCacheItem^.TimeStamp, SizeOf(Integer))) then raise Exception.Create('Saving of the TimeStamp field failed.');

    if not(FileStream.Write(AddressCacheItem^.ResponseLen, SizeOf(Integer))) then raise Exception.Create('Saving of the ResponseLen field failed.');

    if not(FileStream.Write(AddressCacheItem^.Response^, AddressCacheItem^.ResponseLen)) then raise Exception.Create('Saving of the Response field failed.');

  end;

  if (HashTreeItem^.L <> nil) then begin

    Self.InternalSaveAddressCacheHashTreeItemToFile(FileStream, TimeStamp, HashTreeItem^.L);

  end;

  if (HashTreeItem^.R <> nil) then begin

    Self.InternalSaveAddressCacheHashTreeItemToFile(FileStream, TimeStamp, HashTreeItem^.R);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
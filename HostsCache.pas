// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  HostsCache;

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
  THostsEntryFamily = (None, NXHostsEntryFamily, DualIPAddressHostsEntryFamily);

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  PHostsEntry = ^THostsEntry;
  THostsEntry = record
    Family: THostsEntryFamily;
    Address: PDualIPAddress;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  THostsCache = class
    public
      class procedure Initialize;
      class procedure LoadFromFile(FileName: String);
      class function  FindNXHostsEntryFamily(HostName: String; var HostsEntry: THostsEntry): Boolean;
      class function  FindIPv4AddressHostsEntryFamily(HostName: String; var HostsEntry: THostsEntry): Boolean;
      class function  FindIPv6AddressHostsEntryFamily(HostName: String; var HostsEntry: THostsEntry): Boolean;
      class procedure Finalize;
    private
      class procedure LoadFromFileEx(FileName: String; var HostsCacheNXListLastAdded: String; var HostsCacheNXListNeedsSorting: Boolean; var HostsCacheIPv4ListLastAdded: String; var HostsCacheIPv4ListNeedsSorting: Boolean; var HostsCacheIPv6ListLastAdded: String; var HostsCacheIPv6ListNeedsSorting: Boolean);
    private
      class procedure ParseNXHostsLine(FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer; var HostsCacheListLastAdded: String; var HostsCacheListNeedsSorting: Boolean);
      class procedure ParseIPv4HostsLine(FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer; HostsLineAddressData: TIPv4Address; var HostsCacheListLastAdded: String; var HostsCacheListNeedsSorting: Boolean);
      class procedure ParseIPv6HostsLine(FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer; HostsLineAddressData: TIPv6Address; var HostsCacheListLastAdded: String; var HostsCacheListNeedsSorting: Boolean);
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
  IniFiles,
  StrUtils,
  SysUtils,
  Configuration,
  DnsProtocol,
  FileStreamLineEx,
  MemoryStore,
  PatternMatching,
  PerlRegEx,
  Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TRegularExpressionList = class
    private
      List1: TList;
      List2: TList;
    public
      Count: Integer;
    public
      constructor Create;
      procedure   Add(Expression: String; Associated: TObject);
      function    ExecRegularExpression(Index: Integer; InputStr: String): Boolean;
      function    GetAssociatedObject(Index: Integer): TObject;
      procedure   BeginUpdate;
      procedure   EndUpdate;
      destructor  Free;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THostsCache_MemoryStore: TMemoryStore;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THostsCache_NXList: THashedStringList;
  THostsCache_NXExpressions: TRegularExpressionList;
  THostsCache_NXPatterns: TStringList;
  THostsCache_NXExceptions: THashedStringList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THostsCache_IPv4List: THashedStringList;
  THostsCache_IPv4Expressions: TRegularExpressionList;
  THostsCache_IPv4Patterns: TStringList;
  THostsCache_IPv4Exceptions: THashedStringList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THostsCache_IPv6List: THashedStringList;
  THostsCache_IPv6Expressions: TRegularExpressionList;
  THostsCache_IPv6Patterns: TStringList;
  THostsCache_IPv6Exceptions: THashedStringList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.Initialize;
begin
  THostsCache_MemoryStore := TMemoryStore.Create;

  THostsCache_NXList := THashedStringList.Create; THostsCache_NXList.CaseSensitive := False; THostsCache_NXList.Duplicates := dupIgnore;
  THostsCache_NXExpressions := TRegularExpressionList.Create;
  THostsCache_NXPatterns := TStringList.Create;
  THostsCache_NXExceptions := THashedStringList.Create; THostsCache_NXExceptions.CaseSensitive := False; THostsCache_NXExceptions.Duplicates := dupIgnore;

  THostsCache_IPv4List := THashedStringList.Create; THostsCache_IPv4List.CaseSensitive := False; THostsCache_IPv4List.Duplicates := dupIgnore;
  THostsCache_IPv4Expressions := TRegularExpressionList.Create;
  THostsCache_IPv4Patterns := TStringList.Create;
  THostsCache_IPv4Exceptions := THashedStringList.Create; THostsCache_IPv4Exceptions.CaseSensitive := False; THostsCache_IPv4Exceptions.Duplicates := dupIgnore;

  THostsCache_IPv6List := THashedStringList.Create; THostsCache_IPv6List.CaseSensitive := False; THostsCache_IPv6List.Duplicates := dupIgnore;
  THostsCache_IPv6Expressions := TRegularExpressionList.Create;
  THostsCache_IPv6Patterns := TStringList.Create;
  THostsCache_IPv6Exceptions := THashedStringList.Create; THostsCache_IPv6Exceptions.CaseSensitive := False; THostsCache_IPv6Exceptions.Duplicates := dupIgnore;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function THostsCache.FindNXHostsEntryFamily(HostName: String; var HostsEntry: THostsEntry): Boolean;
var
  ListIndex: Integer; ExceptionIndex: Integer;
begin
  if (THostsCache_NXList.Find(HostName, ListIndex)) then begin

    HostsEntry.Family  := NXHostsEntryFamily;
    HostsEntry.Address := nil;

    Result := True; Exit;

  end else begin

    if (THostsCache_NXPatterns.Count > 0) then begin

      for ListIndex := 0 to (THostsCache_NXPatterns.Count - 1) do begin
        if TPatternMatching.Match(PChar(HostName), PChar(THostsCache_NXPatterns.Strings[ListIndex])) then begin
          if not(THostsCache_NXExceptions.Find(HostName, ExceptionIndex)) then begin

            HostsEntry.Family  := NXHostsEntryFamily;
            HostsEntry.Address := nil;

            Result := True; Exit;

          end else begin

            Result := False; Exit;

          end;
        end;
      end;

    end;

    if (THostsCache_NXExpressions.Count > 0) then begin

      for ListIndex := 0 to (THostsCache_NXExpressions.Count - 1) do begin
        try
          if THostsCache_NXExpressions.ExecRegularExpression(ListIndex, HostName) then begin
            if not(THostsCache_NXExceptions.Find(HostName, ExceptionIndex)) then begin

              HostsEntry.Family  := NXHostsEntryFamily;
              HostsEntry.Address := nil;

              Result := True; Exit;

            end else begin

              Result := False; Exit;

            end;
          end;
        except
        end;
      end;

    end;

  end;

  Result := False;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function THostsCache.FindIPv4AddressHostsEntryFamily(HostName: String; var HostsEntry: THostsEntry): Boolean;
var
  ListIndex: Integer; ExceptionIndex: Integer;
begin
  if (THostsCache_IPv4List.Find(HostName, ListIndex)) then begin

    HostsEntry.Family  := DualIPAddressHostsEntryFamily;
    HostsEntry.Address := TDualIPAddressUtility.CreateFromIPv4AddressAsPointer(Integer(THostsCache_IPv4List.Objects[ListIndex]));

    Result := True; Exit;

  end else begin

    if (THostsCache_IPv4Patterns.Count > 0) then begin

      for ListIndex := 0 to (THostsCache_IPv4Patterns.Count - 1) do begin
        if TPatternMatching.Match(PChar(HostName), PChar(THostsCache_IPv4Patterns.Strings[ListIndex])) then begin
          if not(THostsCache_IPv4Exceptions.Find(HostName, ExceptionIndex)) then begin

            HostsEntry.Family  := DualIPAddressHostsEntryFamily;
            HostsEntry.Address := TDualIPAddressUtility.CreateFromIPv4AddressAsPointer(Integer(THostsCache_IPv4Patterns.Objects[ListIndex]));

            Result := True; Exit;

          end else begin

            Result := False; Exit;

          end;
        end;
      end;

    end;

    if (THostsCache_IPv4Expressions.Count > 0) then begin

      for ListIndex := 0 to (THostsCache_IPv4Expressions.Count - 1) do begin
        try
          if THostsCache_IPv4Expressions.ExecRegularExpression(ListIndex, HostName) then begin
            if not(THostsCache_IPv4Exceptions.Find(HostName, ExceptionIndex)) then begin

              HostsEntry.Family  := DualIPAddressHostsEntryFamily;
              HostsEntry.Address := TDualIPAddressUtility.CreateFromIPv4AddressAsPointer(Integer(THostsCache_IPv4Expressions.GetAssociatedObject(ListIndex)));

              Result := True; Exit;

            end else begin

              Result := False; Exit;

            end;
          end;
        except
        end;
      end;

    end;

  end;

  Result := False;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function THostsCache.FindIPv6AddressHostsEntryFamily(HostName: String; var HostsEntry: THostsEntry): Boolean;
var
  ListIndex: Integer; ExceptionIndex: Integer;
begin
  if (THostsCache_IPv6List.Find(HostName, ListIndex)) then begin

    HostsEntry.Family  := DualIPAddressHostsEntryFamily;
    HostsEntry.Address := TDualIPAddressUtility.CreateFromIPv6AddressAsPointer(PIPv6Address(THostsCache_IPv6List.Objects[ListIndex])^);

    Result := True; Exit;

  end else begin

    if (THostsCache_IPv6Patterns.Count > 0) then begin

      for ListIndex := 0 to (THostsCache_IPv6Patterns.Count - 1) do begin
        if TPatternMatching.Match(PChar(HostName), PChar(THostsCache_IPv6Patterns.Strings[ListIndex])) then begin
          if not(THostsCache_IPv6Exceptions.Find(HostName, ExceptionIndex)) then begin

            HostsEntry.Family  := DualIPAddressHostsEntryFamily;
            HostsEntry.Address := TDualIPAddressUtility.CreateFromIPv6AddressAsPointer(PIPv6Address(THostsCache_IPv6Patterns.Objects[ListIndex])^);

            Result := True; Exit;

          end else begin

            Result := False; Exit;

          end;
        end;
      end;

    end;

    if (THostsCache_IPv6Expressions.Count > 0) then begin

      for ListIndex := 0 to (THostsCache_IPv6Expressions.Count - 1) do begin
        try
          if THostsCache_IPv6Expressions.ExecRegularExpression(ListIndex, HostName) then begin
            if not(THostsCache_IPv6Exceptions.Find(HostName, ExceptionIndex)) then begin

              HostsEntry.Family  := DualIPAddressHostsEntryFamily;
              HostsEntry.Address := TDualIPAddressUtility.CreateFromIPv6AddressAsPointer(PIPv6Address(THostsCache_IPv6Expressions.GetAssociatedObject(ListIndex))^);

              Result := True; Exit;

            end else begin

              Result := False; Exit;

            end;
          end;
        except
        end;
      end;

    end;

  end;

  Result := False;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.ParseNXHostsLine(FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer; var HostsCacheListLastAdded: String; var HostsCacheListNeedsSorting: Boolean);
var
  HostsLineTextData: String;
begin
  HostsLineTextData := Copy(FileStreamLineData, HostsLineIndexA, HostsLineIndexB - HostsLineIndexA);

  if (FileStreamLineData[HostsLineIndexA] = '-') then begin

    THostsCache_NXExceptions.Add(Copy(HostsLineTextData, 2, MaxInt))

  end else if (FileStreamLineData[HostsLineIndexA] = '/') then begin

    THostsCache_NXExpressions.Add(Copy(HostsLineTextData, 2, MaxInt), nil)

  end else if (FileStreamLineData[HostsLineIndexA] = '>') then begin

    HostsLineTextData := Copy(HostsLineTextData, 2, MaxInt);

    THostsCache_NXPatterns.AddObject('*.' + HostsLineTextData, nil);

    if (Pos('*', HostsLineTextData) > 0) or (Pos('?', HostsLineTextData) > 0) then THostsCache_NXPatterns.AddObject(HostsLineTextData, nil) else begin

      THostsCache_NXList.AddObject(HostsLineTextData, nil);

      if (HostsLineTextData < HostsCacheListLastAdded) then HostsCacheListNeedsSorting := True; HostsCacheListLastAdded := HostsLineTextData;

    end;

  end else if (Pos('*', HostsLineTextData) > 0) or (Pos('?', HostsLineTextData) > 0) then begin

    THostsCache_NXPatterns.AddObject(HostsLineTextData, nil)

  end else begin

    THostsCache_NXList.AddObject(HostsLineTextData, nil);

    if (HostsLineTextData < HostsCacheListLastAdded) then HostsCacheListNeedsSorting := True; HostsCacheListLastAdded := HostsLineTextData;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.ParseIPv4HostsLine(FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer; HostsLineAddressData: TIPv4Address; var HostsCacheListLastAdded: String; var HostsCacheListNeedsSorting: Boolean);
var
  HostsLineTextData: String;
begin
  HostsLineTextData := Copy(FileStreamLineData, HostsLineIndexA, HostsLineIndexB - HostsLineIndexA);

  if (FileStreamLineData[HostsLineIndexA] = '-') then begin

    THostsCache_IPv4Exceptions.Add(Copy(HostsLineTextData, 2, MaxInt))

  end else if (FileStreamLineData[HostsLineIndexA] = '/') then begin

    THostsCache_IPv4Expressions.Add(Copy(HostsLineTextData, 2, MaxInt), TObject(HostsLineAddressData))

  end else if (FileStreamLineData[HostsLineIndexA] = '>') then begin

    HostsLineTextData := Copy(HostsLineTextData, 2, MaxInt);

    THostsCache_IPv4Patterns.AddObject('*.' + HostsLineTextData, TObject(HostsLineAddressData));

    if (Pos('*', HostsLineTextData) > 0) or (Pos('?', HostsLineTextData) > 0) then THostsCache_IPv4Patterns.AddObject(HostsLineTextData, TObject(HostsLineAddressData)) else begin

      THostsCache_IPv4List.AddObject(HostsLineTextData, TObject(HostsLineAddressData));

      if (HostsLineTextData < HostsCacheListLastAdded) then HostsCacheListNeedsSorting := True; HostsCacheListLastAdded := HostsLineTextData;

    end;

  end else if (Pos('*', HostsLineTextData) > 0) or (Pos('?', HostsLineTextData) > 0) then begin

    THostsCache_IPv4Patterns.AddObject(HostsLineTextData, TObject(HostsLineAddressData))

  end else begin

    THostsCache_IPv4List.AddObject(HostsLineTextData, TObject(HostsLineAddressData));

    if (HostsLineTextData < HostsCacheListLastAdded) then HostsCacheListNeedsSorting := True; HostsCacheListLastAdded := HostsLineTextData;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.ParseIPv6HostsLine(FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer; HostsLineAddressData: TIPv6Address; var HostsCacheListLastAdded: String; var HostsCacheListNeedsSorting: Boolean);
var
  HostsLineTextData: String; PHostsLineAddressData: PIPv6Address;
begin
  HostsLineTextData := Copy(FileStreamLineData, HostsLineIndexA, HostsLineIndexB - HostsLineIndexA);
  PHostsLineAddressData := THostsCache_MemoryStore.GetMemory(SizeOf(TIPv6Address)); PHostsLineAddressData^[0] := HostsLineAddressData[0]; PHostsLineAddressData^[1] := HostsLineAddressData[1]; PHostsLineAddressData^[2] := HostsLineAddressData[2]; PHostsLineAddressData^[3] := HostsLineAddressData[3]; PHostsLineAddressData^[4] := HostsLineAddressData[4]; PHostsLineAddressData^[5] := HostsLineAddressData[5]; PHostsLineAddressData^[6] := HostsLineAddressData[6]; PHostsLineAddressData^[7] := HostsLineAddressData[7]; PHostsLineAddressData^[8] := HostsLineAddressData[8]; PHostsLineAddressData^[9] := HostsLineAddressData[9]; PHostsLineAddressData^[10] := HostsLineAddressData[10]; PHostsLineAddressData^[11] := HostsLineAddressData[11]; PHostsLineAddressData^[12] := HostsLineAddressData[12]; PHostsLineAddressData^[13] := HostsLineAddressData[13]; PHostsLineAddressData^[14] := HostsLineAddressData[14]; PHostsLineAddressData^[15] := HostsLineAddressData[15];

  if (FileStreamLineData[HostsLineIndexA] = '-') then begin

    THostsCache_IPv6Exceptions.Add(Copy(HostsLineTextData, 2, MaxInt))

  end else if (FileStreamLineData[HostsLineIndexA] = '/') then begin

    THostsCache_IPv6Expressions.Add(Copy(HostsLineTextData, 2, MaxInt), TObject(PHostsLineAddressData))

  end else if (FileStreamLineData[HostsLineIndexA] = '>') then begin

    HostsLineTextData := Copy(HostsLineTextData, 2, MaxInt);

    THostsCache_IPv6Patterns.AddObject('*.' + HostsLineTextData, TObject(PHostsLineAddressData));

    if (Pos('*', HostsLineTextData) > 0) or (Pos('?', HostsLineTextData) > 0) then THostsCache_IPv6Patterns.AddObject(HostsLineTextData, TObject(PHostsLineAddressData)) else begin

      THostsCache_IPv6List.AddObject(HostsLineTextData, TObject(PHostsLineAddressData));

      if (HostsLineTextData < HostsCacheListLastAdded) then HostsCacheListNeedsSorting := True; HostsCacheListLastAdded := HostsLineTextData;

    end;

  end else if (Pos('*', HostsLineTextData) > 0) or (Pos('?', HostsLineTextData) > 0) then begin

    THostsCache_IPv6Patterns.AddObject(HostsLineTextData, TObject(PHostsLineAddressData))

  end else begin

    THostsCache_IPv6List.AddObject(HostsLineTextData, TObject(PHostsLineAddressData));

    if (HostsLineTextData < HostsCacheListLastAdded) then HostsCacheListNeedsSorting := True; HostsCacheListLastAdded := HostsLineTextData;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.LoadFromFile(FileName: String);
var
  HostsCacheNXListLastAdded: String; HostsCacheNXListNeedsSorting: Boolean; HostsCacheIPv4ListLastAdded: String; HostsCacheIPv4ListNeedsSorting: Boolean; HostsCacheIPv6ListLastAdded: String; HostsCacheIPv6ListNeedsSorting: Boolean;
begin
  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'THostsCache.LoadFromFile: Loading hosts cache items...');

  THostsCache_NXList.BeginUpdate; THostsCache_NXExpressions.BeginUpdate; THostsCache_NXPatterns.BeginUpdate; THostsCache_NXExceptions.BeginUpdate;
  THostsCache_IPv4List.BeginUpdate; THostsCache_IPv4Expressions.BeginUpdate; THostsCache_IPv4Patterns.BeginUpdate; THostsCache_IPv4Exceptions.BeginUpdate;
  THostsCache_IPv6List.BeginUpdate; THostsCache_IPv6Expressions.BeginUpdate; THostsCache_IPv6Patterns.BeginUpdate; THostsCache_IPv6Exceptions.BeginUpdate;

  SetLength(HostsCacheNXListLastAdded, 0); HostsCacheNXListNeedsSorting := False;
  SetLength(HostsCacheIPv4ListLastAdded, 0); HostsCacheIPv4ListNeedsSorting := False;
  SetLength(HostsCacheIPv6ListLastAdded, 0); HostsCacheIPv6ListNeedsSorting := False;

  Self.LoadFromFileEx(FileName, HostsCacheNXListLastAdded, HostsCacheNXListNeedsSorting, HostsCacheIPv4ListLastAdded, HostsCacheIPv4ListNeedsSorting, HostsCacheIPv6ListLastAdded, HostsCacheIPv6ListNeedsSorting);

  if (HostsCacheIPv6ListNeedsSorting) then THostsCache_IPv6List.Sort else THostsCache_IPv6List.Sorted := True; THostsCache_IPv6Exceptions.Sort;
  if (HostsCacheIPv4ListNeedsSorting) then THostsCache_IPv4List.Sort else THostsCache_IPv4List.Sorted := True; THostsCache_IPv4Exceptions.Sort;
  if (HostsCacheNXListNeedsSorting) then THostsCache_NXList.Sort else THostsCache_NXList.Sorted := True; THostsCache_NXExceptions.Sort;

  THostsCache_IPv6Exceptions.EndUpdate; THostsCache_IPv6Patterns.EndUpdate; THostsCache_IPv6Expressions.EndUpdate; THostsCache_IPv6List.EndUpdate;
  THostsCache_IPv4Exceptions.EndUpdate; THostsCache_IPv4Patterns.EndUpdate; THostsCache_IPv4Expressions.EndUpdate; THostsCache_IPv4List.EndUpdate;
  THostsCache_NXExceptions.EndUpdate; THostsCache_NXPatterns.EndUpdate; THostsCache_NXExpressions.EndUpdate; THostsCache_NXList.EndUpdate;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'THostsCache.LoadFromFile: Loaded ' +
    IntToStr(THostsCache_NXList.Count) + ' ' + IfThen(HostsCacheNXListNeedsSorting, 'unordered', 'sorted') + ' NX hostnames, ' + IntToStr(THostsCache_NXExpressions.Count) + ' NX regexes, ' + IntToStr(THostsCache_NXPatterns.Count) + ' NX patterns, ' + IntToStr(THostsCache_NXExceptions.Count) + ' NX exceptions, ' +
    IntToStr(THostsCache_IPv4List.Count) + ' ' + IfThen(HostsCacheIPv4ListNeedsSorting, 'unordered', 'sorted') + ' IPv4 hostnames, ' + IntToStr(THostsCache_IPv4Expressions.Count) + ' IPv4 regexes, ' + IntToStr(THostsCache_IPv4Patterns.Count) + ' IPv4 patterns, ' + IntToStr(THostsCache_IPv4Exceptions.Count) + ' IPv4 exceptions, ' +
    IntToStr(THostsCache_IPv6List.Count) + ' ' + IfThen(HostsCacheIPv6ListNeedsSorting, 'unordered', 'sorted') + ' IPv6 hostnames, ' + IntToStr(THostsCache_IPv6Expressions.Count) + ' IPv6 regexes, ' + IntToStr(THostsCache_IPv6Patterns.Count) + ' IPv6 patterns, ' + IntToStr(THostsCache_IPv6Exceptions.Count) + ' IPv6 exceptions successfully.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.LoadFromFileEx(FileName: String; var HostsCacheNXListLastAdded: String; var HostsCacheNXListNeedsSorting: Boolean; var HostsCacheIPv4ListLastAdded: String; var HostsCacheIPv4ListNeedsSorting: Boolean; var HostsCacheIPv6ListLastAdded: String; var HostsCacheIPv6ListNeedsSorting: Boolean);
var
  FileStream: TFileStream; FileStreamLineEx: TFileStreamLineEx; FileStreamLineData: String; FileStreamLineMoreAvailable: Boolean; FileStreamLineSize: Integer; FileNameEx: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer; HostsEntryFamilyData: String; HostsEntry: THostsEntry;
begin
  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'THostsCache.LoadFromFileEx: Loading hosts cache items from file "' + FileName + '"...');

  FileStream := TFileStream.Create(FileName, fmOpenRead, fmShareDenyWrite); try

    FileStreamLineEx := TFileStreamLineEx.Create(FileStream);

    repeat

      FileStreamLineMoreAvailable := FileStreamLineEx.ReadLine(FileStreamLineData); FileStreamLineSize := Length(FileStreamLineData); if (FileStreamLineSize > 0) then begin

        if (FileStreamLineData[1] = '@') then begin

          if (FileStreamLineSize >= 3) then begin

            if (FileStreamLineData[2] = ' ') then begin

              FileNameEx := TConfiguration.MakeAbsolutePath(Copy(FileStreamLineData, 3, FileStreamLineSize - 2));

              if FileExists(FileNameEx) then begin

                Self.LoadFromFileEx(FileNameEx, HostsCacheNXListLastAdded, HostsCacheNXListNeedsSorting, HostsCacheIPv4ListLastAdded, HostsCacheIPv4ListNeedsSorting, HostsCacheIPv6ListLastAdded, HostsCacheIPv6ListNeedsSorting);

              end;

            end;

          end;

          Continue;

        end;

        HostsLineIndexA := 1;
        HostsLineIndexB := 1;

        HostsEntry.Family := None; while (HostsLineIndexB <= FileStreamLineSize) do begin

          case (FileStreamLineData[HostsLineIndexB]) of

            #9,
            #32:
            begin
              if (HostsLineIndexB > HostsLineIndexA) then begin

                case (HostsEntry.Family) of

                  None:
                  begin

                    HostsEntryFamilyData := Copy(FileStreamLineData, HostsLineIndexA, HostsLineIndexB - HostsLineIndexA);

                    if (HostsEntryFamilyData = 'NX') then begin

                      HostsEntry.Family  := NXHostsEntryFamily;
                      HostsEntry.Address := nil;

                    end else begin

                      HostsEntry.Family  := DualIPAddressHostsEntryFamily;
                      HostsEntry.Address := TDualIPAddressUtility.ParseAsPointer(HostsEntryFamilyData);

                    end;

                  end;

                  NXHostsEntryFamily:
                  begin

                    Self.ParseNXHostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsCacheNXListLastAdded, HostsCacheNXListNeedsSorting);

                  end;

                  DualIPAddressHostsEntryFamily:
                  begin

                    if HostsEntry.Address^.IsIPv6Address then Self.ParseIPv6HostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsEntry.Address^.IPv6Address, HostsCacheIPv6ListLastAdded, HostsCacheIPv6ListNeedsSorting) else Self.ParseIPv4HostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsEntry.Address^.IPv4Address, HostsCacheIPv4ListLastAdded, HostsCacheIPv4ListNeedsSorting);

                  end;

                end;

              end;

              HostsLineIndexA := HostsLineIndexB + 1;
            end;

            '#':
            begin
              Break;
            end;

          end;

          Inc(HostsLineIndexB);

        end; if (HostsLineIndexB > HostsLineIndexA) then begin

          case (HostsEntry.Family) of

            NXHostsEntryFamily:
            begin

              Self.ParseNXHostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsCacheNXListLastAdded, HostsCacheNXListNeedsSorting);

            end;

            DualIPAddressHostsEntryFamily:
            begin

              if HostsEntry.Address^.IsIPv6Address then Self.ParseIPv6HostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsEntry.Address^.IPv6Address, HostsCacheIPv6ListLastAdded, HostsCacheIPv6ListNeedsSorting) else Self.ParseIPv4HostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsEntry.Address^.IPv4Address, HostsCacheIPv4ListLastAdded, HostsCacheIPv4ListNeedsSorting);

            end;

          end;

        end;

      end;

    until not(FileStreamLineMoreAvailable);

  finally

    FileStream.Free;

  end;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'THostsCache.LoadFromFileEx: Done loading from file "' + FileName + '".');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.Finalize;
begin
  THostsCache_IPv6Exceptions.Free; THostsCache_IPv6Patterns.Free; THostsCache_IPv6Expressions.Free; THostsCache_IPv6List.Free;
  THostsCache_IPv4Exceptions.Free; THostsCache_IPv4Patterns.Free; THostsCache_IPv4Expressions.Free; THostsCache_IPv4List.Free;
  THostsCache_NXExceptions.Free; THostsCache_NXPatterns.Free; THostsCache_NXExpressions.Free; THostsCache_NXList.Free;

  THostsCache_MemoryStore.Free;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TRegularExpressionList.Create;
begin
  List1 := TList.Create; List2 := TList.Create; Count := 0;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TRegularExpressionList.Add(Expression: String; Associated: TObject);
var
  RegularExpression: TPerlRegEx;
begin
  RegularExpression := TPerlRegEx.Create; RegularExpression.RegEx := Expression; RegularExpression.Options := [preCaseLess]; RegularExpression.Compile; List1.Add(RegularExpression); List2.Add(Associated); Inc(Count);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TRegularExpressionList.ExecRegularExpression(Index: Integer; InputStr: String): Boolean;
var
  RegularExpression: TPerlRegEx;
begin
  RegularExpression := TPerlRegEx(List1[Index]); RegularExpression.Subject := InputStr; Result := RegularExpression.Match;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TRegularExpressionList.GetAssociatedObject(Index: Integer): TObject;
begin
  Result := List2[Index];
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TRegularExpressionList.BeginUpdate;
begin
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TRegularExpressionList.EndUpdate;
begin
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TRegularExpressionList.Free;
var
  Index: Integer;
begin
  List2.Free; for Index := 0 to (Count - 1) do TPerlRegEx(List1[Index]).Free; List1.Free;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
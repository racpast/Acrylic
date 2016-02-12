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
  THostsEntryFamily = (AddressHostsEntryFamily);

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  PHostsEntry = ^THostsEntry;
  THostsEntry = record
    Family: THostsEntryFamily;
    Address: TDualIPAddress;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  THostsCache = class
    public
      class procedure Initialize;
      class function  Find(HostName: String; QueryType: Word; var HostsEntry: THostsEntry): Boolean;
      class procedure LoadFromFile(FileName: String);
      class procedure Finalize;
    private
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
  DnsProtocol,
  FileStreamLineEx,
  MemoryStore,
  PatternMatching,
  RegExpr,
                                                                                                                                                                                                                                                   Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TRegExprList = class
    private
      List1: TList;
      List2: TList;
    public
      Count: Integer;
    public
      constructor Create;
      procedure   Add(Expression: String; Associated: TObject);
      function    ExecRegExpr(Index: Integer; InputStr: String): Boolean;
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
  THostsCache_IPv4List: THashedStringList;
  THostsCache_IPv4Expressions: TRegExprList;
  THostsCache_IPv4Patterns: TStringList;
  THostsCache_IPv4Exceptions: THashedStringList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THostsCache_IPv6List: THashedStringList;
  THostsCache_IPv6Expressions: TRegExprList;
  THostsCache_IPv6Patterns: TStringList;
  THostsCache_IPv6Exceptions: THashedStringList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.Initialize;
begin
  THostsCache_MemoryStore := TMemoryStore.Create(65536);

  THostsCache_IPv4List := THashedStringList.Create; THostsCache_IPv4List.CaseSensitive := False; THostsCache_IPv4List.Duplicates := dupIgnore;
  THostsCache_IPv4Expressions := TRegExprList.Create;
  THostsCache_IPv4Patterns := TStringList.Create;
  THostsCache_IPv4Exceptions := THashedStringList.Create; THostsCache_IPv4Exceptions.CaseSensitive := False; THostsCache_IPv4Exceptions.Duplicates := dupIgnore;

  THostsCache_IPv6List := THashedStringList.Create; THostsCache_IPv6List.CaseSensitive := False; THostsCache_IPv6List.Duplicates := dupIgnore;
  THostsCache_IPv6Expressions := TRegExprList.Create;
  THostsCache_IPv6Patterns := TStringList.Create;
  THostsCache_IPv6Exceptions := THashedStringList.Create; THostsCache_IPv6Exceptions.CaseSensitive := False; THostsCache_IPv6Exceptions.Duplicates := dupIgnore;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function THostsCache.Find(HostName: String; QueryType: Word; var HostsEntry: THostsEntry): Boolean;
var
  ListIndex: Integer;
begin
  case QueryType of

    DNS_QUERY_TYPE_A:

      begin

        if (THostsCache_IPv4List.Find(HostName, ListIndex)) then begin

          HostsEntry.Family := AddressHostsEntryFamily;
          HostsEntry.Address := TDualIPAddressUtility.CreateFromIPv4Address(Integer(THostsCache_IPv4List.Objects[ListIndex]));

          Result := True; Exit;

        end else begin

          if (THostsCache_IPv4Patterns.Count > 0) then begin

            for ListIndex := 0 to (THostsCache_IPv4Patterns.Count - 1) do begin
              if TPatternMatching.Match(PChar(HostName), PChar(THostsCache_IPv4Patterns.Strings[ListIndex])) then begin
                if not(THostsCache_IPv4Exceptions.IndexOf(HostName) > -1) then begin

                  HostsEntry.Family := AddressHostsEntryFamily;
                  HostsEntry.Address := TDualIPAddressUtility.CreateFromIPv4Address(Integer(THostsCache_IPv4Patterns.Objects[ListIndex]));

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
                if THostsCache_IPv4Expressions.ExecRegExpr(ListIndex, HostName) then begin
                  if not(THostsCache_IPv4Exceptions.IndexOf(HostName) > -1) then begin

                    HostsEntry.Family := AddressHostsEntryFamily;
                    HostsEntry.Address := TDualIPAddressUtility.CreateFromIPv4Address(Integer(THostsCache_IPv4Expressions.GetAssociatedObject(ListIndex)));

                    Result := True; Exit;

                  end else begin

                    Result := False; Exit;

                  end;
                end;
              except
              end;
            end;

          end;

        end; Result := False;

      end;

    DNS_QUERY_TYPE_AAAA:

      begin

        if (THostsCache_IPv6List.Find(HostName, ListIndex)) then begin

          HostsEntry.Family := AddressHostsEntryFamily;
          HostsEntry.Address := TDualIPAddressUtility.CreateFromIPv6Address(PIPv6Address(THostsCache_IPv6List.Objects[ListIndex])^);

          Result := True; Exit;

        end else begin

          if (THostsCache_IPv6Patterns.Count > 0) then begin

            for ListIndex := 0 to (THostsCache_IPv6Patterns.Count - 1) do begin
              if TPatternMatching.Match(PChar(HostName), PChar(THostsCache_IPv6Patterns.Strings[ListIndex])) then begin
                if not(THostsCache_IPv6Exceptions.IndexOf(HostName) > -1) then begin

                  HostsEntry.Family := AddressHostsEntryFamily;
                  HostsEntry.Address := TDualIPAddressUtility.CreateFromIPv6Address(PIPv6Address(THostsCache_IPv6Patterns.Objects[ListIndex])^);

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
                if THostsCache_IPv6Expressions.ExecRegExpr(ListIndex, HostName) then begin
                  if not(THostsCache_IPv6Exceptions.IndexOf(HostName) > -1) then begin

                    HostsEntry.Family := AddressHostsEntryFamily;
                    HostsEntry.Address := TDualIPAddressUtility.CreateFromIPv6Address(PIPv6Address(THostsCache_IPv6Expressions.GetAssociatedObject(ListIndex))^);

                    Result := True; Exit;

                  end else begin

                    Result := False; Exit;

                  end;
                end;
              except
              end;
            end;

          end;

        end; Result := False;

      end;

    else Result := False;

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
    if (Pos('*', HostsLineTextData) > 0) or (Pos('?', HostsLineTextData) > 0) then THostsCache_IPv4Patterns.AddObject(HostsLineTextData, TObject(HostsLineAddressData)) else begin THostsCache_IPv4List.AddObject(HostsLineTextData, TObject(HostsLineAddressData)); if (HostsLineTextData < HostsCacheListLastAdded) then HostsCacheListNeedsSorting := True; HostsCacheListLastAdded := HostsLineTextData; end;
  end else if (Pos('*', HostsLineTextData) > 0) or (Pos('?', HostsLineTextData) > 0) then begin
    THostsCache_IPv4Patterns.AddObject(HostsLineTextData, TObject(HostsLineAddressData))
  end else begin
    THostsCache_IPv4List.AddObject(HostsLineTextData, TObject(HostsLineAddressData)); if (HostsLineTextData < HostsCacheListLastAdded) then HostsCacheListNeedsSorting := True; HostsCacheListLastAdded := HostsLineTextData;
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
    if (Pos('*', HostsLineTextData) > 0) or (Pos('?', HostsLineTextData) > 0) then THostsCache_IPv6Patterns.AddObject(HostsLineTextData, TObject(PHostsLineAddressData)) else begin THostsCache_IPv6List.AddObject(HostsLineTextData, TObject(PHostsLineAddressData)); if (HostsLineTextData < HostsCacheListLastAdded) then HostsCacheListNeedsSorting := True; HostsCacheListLastAdded := HostsLineTextData; end;
  end else if (Pos('*', HostsLineTextData) > 0) or (Pos('?', HostsLineTextData) > 0) then begin
    THostsCache_IPv6Patterns.AddObject(HostsLineTextData, TObject(PHostsLineAddressData))
  end else begin
    THostsCache_IPv6List.AddObject(HostsLineTextData, TObject(PHostsLineAddressData)); if (HostsLineTextData < HostsCacheListLastAdded) then HostsCacheListNeedsSorting := True; HostsCacheListLastAdded := HostsLineTextData;
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.LoadFromFile(FileName: String);
var
  FileStream: TFileStream; FileStreamLineEx: TFileStreamLineEx;
  FileStreamLineData: String; FileStreamLineMoreAvailable: Boolean; FileStreamLineSize: Integer; HostsLineIndexA: Integer; HostsLineIndexB: Integer; HostsLineAddressData: TDualIPAddress; HostsLineAddressDone: Boolean; HostsCacheIPv4ListLastAdded: String; HostsCacheIPv4ListNeedsSorting: Boolean; HostsCacheIPv6ListLastAdded: String; HostsCacheIPv6ListNeedsSorting: Boolean;
begin
  // Trace the event if a tracer is enabled
  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'THostsCache.LoadFromFile: Loading hosts cache items...');

  FileStream := TFileStream.Create(FileName, fmOpenRead, fmShareDenyWrite); try

    // Create the decorator object
    FileStreamLineEx := TFileStreamLineEx.Create(FileStream);

    // Signal that we're going to do a big update
    THostsCache_IPv4List.BeginUpdate; THostsCache_IPv4Expressions.BeginUpdate; THostsCache_IPv4Patterns.BeginUpdate; THostsCache_IPv4Exceptions.BeginUpdate;
    THostsCache_IPv6List.BeginUpdate; THostsCache_IPv6Expressions.BeginUpdate; THostsCache_IPv6Patterns.BeginUpdate; THostsCache_IPv6Exceptions.BeginUpdate;

    SetLength(HostsCacheIPv4ListLastAdded, 0); HostsCacheIPv4ListNeedsSorting := False;
    SetLength(HostsCacheIPv6ListLastAdded, 0); HostsCacheIPv6ListNeedsSorting := False;

    repeat // Until there are no more lines available

      // Read the next line from the stream
      FileStreamLineMoreAvailable := FileStreamLineEx.ReadLine(FileStreamLineData); FileStreamLineSize := Length(FileStreamLineData); if (FileStreamLineSize > 0) then begin

        HostsLineIndexA := 1;
        HostsLineIndexB := 1;

        FillChar(HostsLineAddressData, SizeOf(TDualIPAddress), 0); HostsLineAddressDone := False; while (HostsLineIndexB <= FileStreamLineSize) do begin

          case (FileStreamLineData[HostsLineIndexB]) of

            #9,
            #32:
            begin
              if (HostsLineIndexB > HostsLineIndexA) then begin

                if HostsLineAddressDone then begin

                  if HostsLineAddressData.IsIPv6Address then Self.ParseIPv6HostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsLineAddressData.IPv6Address, HostsCacheIPv6ListLastAdded, HostsCacheIPv6ListNeedsSorting) else Self.ParseIPv4HostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsLineAddressData.IPv4Address, HostsCacheIPv4ListLastAdded, HostsCacheIPv4ListNeedsSorting);

                end else begin

                  HostsLineAddressData := TDualIPAddressUtility.Parse(Copy(FileStreamLineData, HostsLineIndexA, HostsLineIndexB - HostsLineIndexA));
                  HostsLineAddressDone := True;

                end;

              end; HostsLineIndexA := HostsLineIndexB + 1;
            end;

            '#':
            begin
              Break;
            end;

          end; Inc(HostsLineIndexB);

        end; if (HostsLineIndexB > HostsLineIndexA) then begin

          if HostsLineAddressDone then begin

            if HostsLineAddressData.IsIPv6Address then Self.ParseIPv6HostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsLineAddressData.IPv6Address, HostsCacheIPv6ListLastAdded, HostsCacheIPv6ListNeedsSorting) else Self.ParseIPv4HostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsLineAddressData.IPv4Address, HostsCacheIPv4ListLastAdded, HostsCacheIPv4ListNeedsSorting);

          end;

        end;

      end;

    until not(FileStreamLineMoreAvailable);

    // Sort the lists now to improve search later
    if (HostsCacheIPv6ListNeedsSorting) then THostsCache_IPv6List.Sort; THostsCache_IPv6Exceptions.Sort;
    if (HostsCacheIPv4ListNeedsSorting) then THostsCache_IPv4List.Sort; THostsCache_IPv4Exceptions.Sort;

    // Signal that the big update is done
    THostsCache_IPv6Exceptions.EndUpdate; THostsCache_IPv6Patterns.EndUpdate; THostsCache_IPv6Expressions.EndUpdate; THostsCache_IPv6List.EndUpdate;
    THostsCache_IPv4Exceptions.EndUpdate; THostsCache_IPv4Patterns.EndUpdate; THostsCache_IPv4Expressions.EndUpdate; THostsCache_IPv4List.EndUpdate;

  finally

    FileStream.Free;

  end;

  // Trace the event if a tracer is enabled
  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'THostsCache.LoadFromFile: Loaded ' + IntToStr(THostsCache_IPv4List.Count) + ' ' + IfThen(HostsCacheIPv4ListNeedsSorting, 'unordered', 'sorted') + ' IPv4 hostnames, ' + IntToStr(THostsCache_IPv4Expressions.Count) + ' IPv4 regexes, ' + IntToStr(THostsCache_IPv4Patterns.Count) + ' IPv4 patterns, ' + IntToStr(THostsCache_IPv4Exceptions.Count) + ' IPv4 exceptions, ' + IntToStr(THostsCache_IPv6List.Count) + ' ' + IfThen(HostsCacheIPv6ListNeedsSorting, 'unordered', 'sorted') + ' IPv6 hostnames, ' + IntToStr(THostsCache_IPv6Expressions.Count) + ' IPv6 regexes, ' + IntToStr(THostsCache_IPv6Patterns.Count) + ' IPv6 patterns, ' + IntToStr(THostsCache_IPv6Exceptions.Count) + ' IPv6 exceptions successfully.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.Finalize;
begin
  THostsCache_IPv6Exceptions.Free; THostsCache_IPv6Patterns.Free; THostsCache_IPv6Expressions.Free; THostsCache_IPv6List.Free;
  THostsCache_IPv4Exceptions.Free; THostsCache_IPv4Patterns.Free; THostsCache_IPv4Expressions.Free; THostsCache_IPv4List.Free;

  THostsCache_MemoryStore.Free;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TRegExprList.Create;
begin
  List1 := TList.Create; List2 := TList.Create; Count := 0;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TRegExprList.Add(Expression: String; Associated: TObject);
var
  RegExpr: TRegExpr;
begin
  RegExpr := TRegExpr.Create; RegExpr.Expression := Expression; RegExpr.ModifierI := True; List1.Add(RegExpr); List2.Add(Associated); Inc(Count);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TRegExprList.ExecRegExpr(Index: Integer; InputStr: String): Boolean;
begin
  Result := TRegExpr(List1[Index]).Exec(InputStr);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TRegExprList.GetAssociatedObject(Index: Integer): TObject;
begin
  Result := List2[Index];
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TRegExprList.BeginUpdate;
begin
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TRegExprList.EndUpdate;
begin
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TRegExprList.Free;
var
  Index: Integer;
begin
  List2.Free; for Index := 0 to (Count - 1) do TRegExpr(List1[Index]).Free; List1.Free;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
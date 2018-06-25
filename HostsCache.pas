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
  THostsCache = class
    public
      class procedure Initialize;
      class procedure LoadFromFile(FileName: String);
      class function  FindFWHostsEntry(HostName: String): Boolean;
      class function  FindNXHostsEntry(HostName: String): Boolean;
      class function  FindIPv4AddressHostsEntry(HostName: String; var IPv4Address: TIPv4Address): Boolean;
      class function  FindIPv6AddressHostsEntry(HostName: String; var IPv6Address: TIPv6Address): Boolean;
      class procedure Finalize;
    private
      class procedure LoadFromFileEx(FileName: String; var HostsCacheFWListLastAdded: String; var HostsCacheFWListNeedsSorting: Boolean; var HostsCacheNXListLastAdded: String; var HostsCacheNXListNeedsSorting: Boolean; var HostsCacheIPv4ListLastAdded: String; var HostsCacheIPv4ListNeedsSorting: Boolean; var HostsCacheIPv6ListLastAdded: String; var HostsCacheIPv6ListNeedsSorting: Boolean);
      class procedure ParseFWHostsLine(FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer; var HostsCacheListLastAdded: String; var HostsCacheListNeedsSorting: Boolean);
      class procedure ParseNXHostsLine(FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer; var HostsCacheListLastAdded: String; var HostsCacheListNeedsSorting: Boolean);
      class procedure ParseIPv4HostsLine(FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer; var HostsLineAddressData: TIPv4Address; var HostsCacheListLastAdded: String; var HostsCacheListNeedsSorting: Boolean);
      class procedure ParseIPv6HostsLine(FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer; var HostsLineAddressData: TIPv6Address; var HostsCacheListLastAdded: String; var HostsCacheListNeedsSorting: Boolean);
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
  THostsCache_FWList: THashedStringList;
  THostsCache_FWPatterns: TStringList;
  THostsCache_FWExpressions: TRegularExpressionList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THostsCache_NXList: THashedStringList;
  THostsCache_NXPatterns: TStringList;
  THostsCache_NXExpressions: TRegularExpressionList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THostsCache_IPv4List: THashedStringList;
  THostsCache_IPv4Patterns: TStringList;
  THostsCache_IPv4Expressions: TRegularExpressionList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THostsCache_IPv6List: THashedStringList;
  THostsCache_IPv6Patterns: TStringList;
  THostsCache_IPv6Expressions: TRegularExpressionList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.Initialize;

begin

  THostsCache_MemoryStore := TMemoryStore.Create;

  THostsCache_FWList := THashedStringList.Create; THostsCache_FWList.CaseSensitive := False; THostsCache_FWList.Duplicates := dupIgnore;
  THostsCache_FWPatterns := TStringList.Create;
  THostsCache_FWExpressions := TRegularExpressionList.Create;

  THostsCache_NXList := THashedStringList.Create; THostsCache_NXList.CaseSensitive := False; THostsCache_NXList.Duplicates := dupIgnore;
  THostsCache_NXPatterns := TStringList.Create;
  THostsCache_NXExpressions := TRegularExpressionList.Create;

  THostsCache_IPv4List := THashedStringList.Create; THostsCache_IPv4List.CaseSensitive := False; THostsCache_IPv4List.Duplicates := dupIgnore;
  THostsCache_IPv4Patterns := TStringList.Create;
  THostsCache_IPv4Expressions := TRegularExpressionList.Create;

  THostsCache_IPv6List := THashedStringList.Create; THostsCache_IPv6List.CaseSensitive := False; THostsCache_IPv6List.Duplicates := dupIgnore;
  THostsCache_IPv6Patterns := TStringList.Create;
  THostsCache_IPv6Expressions := TRegularExpressionList.Create;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function THostsCache.FindFWHostsEntry(HostName: String): Boolean;

var
  ListIndex: Integer;

begin

  if (THostsCache_FWList.Find(HostName, ListIndex)) then begin

    Result := True; Exit;

  end else begin

    if (THostsCache_FWPatterns.Count > 0) then begin

      for ListIndex := 0 to (THostsCache_FWPatterns.Count - 1) do begin
        if TPatternMatching.Match(PChar(HostName), PChar(THostsCache_FWPatterns.Strings[ListIndex])) then begin
          Result := True; Exit;
        end;
      end;

    end;

    if (THostsCache_FWExpressions.Count > 0) then begin

      for ListIndex := 0 to (THostsCache_FWExpressions.Count - 1) do begin
        try
          if THostsCache_FWExpressions.ExecRegularExpression(ListIndex, HostName) then begin
            Result := True; Exit;
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

class function THostsCache.FindNXHostsEntry(HostName: String): Boolean;

var
  ListIndex: Integer;

begin

  if (THostsCache_NXList.Find(HostName, ListIndex)) then begin

    Result := True; Exit;

  end else begin

    if (THostsCache_NXPatterns.Count > 0) then begin

      for ListIndex := 0 to (THostsCache_NXPatterns.Count - 1) do begin
        if TPatternMatching.Match(PChar(HostName), PChar(THostsCache_NXPatterns.Strings[ListIndex])) then begin
          Result := True; Exit;
        end;
      end;

    end;

    if (THostsCache_NXExpressions.Count > 0) then begin

      for ListIndex := 0 to (THostsCache_NXExpressions.Count - 1) do begin
        try
          if THostsCache_NXExpressions.ExecRegularExpression(ListIndex, HostName) then begin
            Result := True; Exit;
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

class function THostsCache.FindIPv4AddressHostsEntry(HostName: String; var IPv4Address: TIPv4Address): Boolean;

var
  ListIndex: Integer;

begin

  if (THostsCache_IPv4List.Find(HostName, ListIndex)) then begin

    IPv4Address := Integer(THostsCache_IPv4List.Objects[ListIndex]); Result := True; Exit;

  end else begin

    if (THostsCache_IPv4Patterns.Count > 0) then begin

      for ListIndex := 0 to (THostsCache_IPv4Patterns.Count - 1) do begin
        if TPatternMatching.Match(PChar(HostName), PChar(THostsCache_IPv4Patterns.Strings[ListIndex])) then begin
          IPv4Address := Integer(THostsCache_IPv4Patterns.Objects[ListIndex]); Result := True; Exit;
        end;
      end;

    end;

    if (THostsCache_IPv4Expressions.Count > 0) then begin

      for ListIndex := 0 to (THostsCache_IPv4Expressions.Count - 1) do begin
        try
          if THostsCache_IPv4Expressions.ExecRegularExpression(ListIndex, HostName) then begin
            IPv4Address := Integer(THostsCache_IPv4Expressions.GetAssociatedObject(ListIndex)); Result := True; Exit;
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

class function THostsCache.FindIPv6AddressHostsEntry(HostName: String; var IPv6Address: TIPv6Address): Boolean;

var
  ListIndex: Integer;

begin

  if (THostsCache_IPv6List.Find(HostName, ListIndex)) then begin

    IPv6Address := PIPv6Address(THostsCache_IPv6List.Objects[ListIndex])^; Result := True; Exit;

  end else begin

    if (THostsCache_IPv6Patterns.Count > 0) then begin

      for ListIndex := 0 to (THostsCache_IPv6Patterns.Count - 1) do begin
        if TPatternMatching.Match(PChar(HostName), PChar(THostsCache_IPv6Patterns.Strings[ListIndex])) then begin
          IPv6Address := PIPv6Address(THostsCache_IPv6Patterns.Objects[ListIndex])^; Result := True; Exit;
        end;
      end;

    end;

    if (THostsCache_IPv6Expressions.Count > 0) then begin

      for ListIndex := 0 to (THostsCache_IPv6Expressions.Count - 1) do begin
        try
          if THostsCache_IPv6Expressions.ExecRegularExpression(ListIndex, HostName) then begin
            IPv6Address := PIPv6Address(THostsCache_IPv6Expressions.GetAssociatedObject(ListIndex))^; Result := True; Exit;
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

class procedure THostsCache.ParseFWHostsLine(FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer; var HostsCacheListLastAdded: String; var HostsCacheListNeedsSorting: Boolean);

var
  HostsLineTextData: String;

begin

  HostsLineTextData := Copy(FileStreamLineData, HostsLineIndexA, HostsLineIndexB - HostsLineIndexA);

  if (FileStreamLineData[HostsLineIndexA] = '/') then begin

    THostsCache_FWExpressions.Add(Copy(HostsLineTextData, 2, MaxInt), nil)

  end else if (FileStreamLineData[HostsLineIndexA] = '>') then begin

    HostsLineTextData := Copy(HostsLineTextData, 2, MaxInt);

    THostsCache_FWPatterns.AddObject('*.' + HostsLineTextData, nil);

    if (Pos('*', HostsLineTextData) > 0) or (Pos('?', HostsLineTextData) > 0) then THostsCache_FWPatterns.AddObject(HostsLineTextData, nil) else begin

      THostsCache_FWList.AddObject(HostsLineTextData, nil);

      if (HostsLineTextData < HostsCacheListLastAdded) then HostsCacheListNeedsSorting := True; HostsCacheListLastAdded := HostsLineTextData;

    end;

  end else if (Pos('*', HostsLineTextData) > 0) or (Pos('?', HostsLineTextData) > 0) then begin

    THostsCache_FWPatterns.AddObject(HostsLineTextData, nil)

  end else begin

    THostsCache_FWList.AddObject(HostsLineTextData, nil);

    if (HostsLineTextData < HostsCacheListLastAdded) then HostsCacheListNeedsSorting := True; HostsCacheListLastAdded := HostsLineTextData;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.ParseNXHostsLine(FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer; var HostsCacheListLastAdded: String; var HostsCacheListNeedsSorting: Boolean);

var
  HostsLineTextData: String;

begin

  HostsLineTextData := Copy(FileStreamLineData, HostsLineIndexA, HostsLineIndexB - HostsLineIndexA);

  if (FileStreamLineData[HostsLineIndexA] = '/') then begin

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

class procedure THostsCache.ParseIPv4HostsLine(FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer; var HostsLineAddressData: TIPv4Address; var HostsCacheListLastAdded: String; var HostsCacheListNeedsSorting: Boolean);

var
  HostsLineTextData: String;

begin

  HostsLineTextData := Copy(FileStreamLineData, HostsLineIndexA, HostsLineIndexB - HostsLineIndexA);

  if (FileStreamLineData[HostsLineIndexA] = '/') then begin

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

class procedure THostsCache.ParseIPv6HostsLine(FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer; var HostsLineAddressData: TIPv6Address; var HostsCacheListLastAdded: String; var HostsCacheListNeedsSorting: Boolean);

var
  HostsLineTextData: String; PHostsLineAddressData: PIPv6Address;

begin

  HostsLineTextData := Copy(FileStreamLineData, HostsLineIndexA, HostsLineIndexB - HostsLineIndexA);
  PHostsLineAddressData := THostsCache_MemoryStore.GetMemory(SizeOf(TIPv6Address)); PHostsLineAddressData^[0] := HostsLineAddressData[0]; PHostsLineAddressData^[1] := HostsLineAddressData[1]; PHostsLineAddressData^[2] := HostsLineAddressData[2]; PHostsLineAddressData^[3] := HostsLineAddressData[3]; PHostsLineAddressData^[4] := HostsLineAddressData[4]; PHostsLineAddressData^[5] := HostsLineAddressData[5]; PHostsLineAddressData^[6] := HostsLineAddressData[6]; PHostsLineAddressData^[7] := HostsLineAddressData[7]; PHostsLineAddressData^[8] := HostsLineAddressData[8]; PHostsLineAddressData^[9] := HostsLineAddressData[9]; PHostsLineAddressData^[10] := HostsLineAddressData[10]; PHostsLineAddressData^[11] := HostsLineAddressData[11]; PHostsLineAddressData^[12] := HostsLineAddressData[12]; PHostsLineAddressData^[13] := HostsLineAddressData[13]; PHostsLineAddressData^[14] := HostsLineAddressData[14]; PHostsLineAddressData^[15] := HostsLineAddressData[15];

  if (FileStreamLineData[HostsLineIndexA] = '/') then begin

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
  HostsCacheFWListLastAdded: String; HostsCacheFWListNeedsSorting: Boolean; HostsCacheNXListLastAdded: String; HostsCacheNXListNeedsSorting: Boolean; HostsCacheIPv4ListLastAdded: String; HostsCacheIPv4ListNeedsSorting: Boolean; HostsCacheIPv6ListLastAdded: String; HostsCacheIPv6ListNeedsSorting: Boolean;

begin

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'THostsCache.LoadFromFile: Loading hosts cache items...');

  THostsCache_FWList.BeginUpdate; THostsCache_FWExpressions.BeginUpdate; THostsCache_FWPatterns.BeginUpdate;
  THostsCache_NXList.BeginUpdate; THostsCache_NXExpressions.BeginUpdate; THostsCache_NXPatterns.BeginUpdate;

  THostsCache_IPv4List.BeginUpdate; THostsCache_IPv4Expressions.BeginUpdate; THostsCache_IPv4Patterns.BeginUpdate;
  THostsCache_IPv6List.BeginUpdate; THostsCache_IPv6Expressions.BeginUpdate; THostsCache_IPv6Patterns.BeginUpdate;

  SetLength(HostsCacheFWListLastAdded, 0); HostsCacheFWListNeedsSorting := False;
  SetLength(HostsCacheNXListLastAdded, 0); HostsCacheNXListNeedsSorting := False;

  SetLength(HostsCacheIPv4ListLastAdded, 0); HostsCacheIPv4ListNeedsSorting := False;
  SetLength(HostsCacheIPv6ListLastAdded, 0); HostsCacheIPv6ListNeedsSorting := False;

  Self.LoadFromFileEx(FileName, HostsCacheFWListLastAdded, HostsCacheFWListNeedsSorting, HostsCacheNXListLastAdded, HostsCacheNXListNeedsSorting, HostsCacheIPv4ListLastAdded, HostsCacheIPv4ListNeedsSorting, HostsCacheIPv6ListLastAdded, HostsCacheIPv6ListNeedsSorting);

  if (HostsCacheIPv6ListNeedsSorting) then THostsCache_IPv6List.Sort else THostsCache_IPv6List.Sorted := True;
  if (HostsCacheIPv4ListNeedsSorting) then THostsCache_IPv4List.Sort else THostsCache_IPv4List.Sorted := True;

  if (HostsCacheNXListNeedsSorting) then THostsCache_NXList.Sort else THostsCache_NXList.Sorted := True;
  if (HostsCacheFWListNeedsSorting) then THostsCache_FWList.Sort else THostsCache_FWList.Sorted := True;

  THostsCache_IPv6Patterns.EndUpdate; THostsCache_IPv6Expressions.EndUpdate; THostsCache_IPv6List.EndUpdate;
  THostsCache_IPv4Patterns.EndUpdate; THostsCache_IPv4Expressions.EndUpdate; THostsCache_IPv4List.EndUpdate;

  THostsCache_NXPatterns.EndUpdate; THostsCache_NXExpressions.EndUpdate; THostsCache_NXList.EndUpdate;
  THostsCache_FWPatterns.EndUpdate; THostsCache_FWExpressions.EndUpdate; THostsCache_FWList.EndUpdate;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'THostsCache.LoadFromFile: Done loading hosts cache items.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.LoadFromFileEx(FileName: String; var HostsCacheFWListLastAdded: String; var HostsCacheFWListNeedsSorting: Boolean; var HostsCacheNXListLastAdded: String; var HostsCacheNXListNeedsSorting: Boolean; var HostsCacheIPv4ListLastAdded: String; var HostsCacheIPv4ListNeedsSorting: Boolean; var HostsCacheIPv6ListLastAdded: String; var HostsCacheIPv6ListNeedsSorting: Boolean);

var
  FileStream: TFileStream; FileStreamLineEx: TFileStreamLineEx; FileStreamLineData: String; FileStreamLineMoreAvailable: Boolean; FileStreamLineSize: Integer; FileNameEx: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer; HostsLineRecordType: Integer; HostsLineAddressText: String; HostsLineAddressData: TDualIPAddress;

begin

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'THostsCache.LoadFromFileEx: Loading hosts cache items from file "' + FileName + '"...');

  try

    FileStream := TFileStream.Create(FileName, fmOpenRead, fmShareDenyWrite); try

      FileStreamLineEx := TFileStreamLineEx.Create(FileStream);

      repeat

        FileStreamLineMoreAvailable := FileStreamLineEx.ReadLine(FileStreamLineData); FileStreamLineSize := Length(FileStreamLineData); if (FileStreamLineSize > 0) then begin

          if (FileStreamLineData[1] = '@') then begin

            if (FileStreamLineSize >= 3) then begin

              if (FileStreamLineData[2] = ' ') then begin

                FileNameEx := TConfiguration.MakeAbsolutePath(Copy(FileStreamLineData, 3, FileStreamLineSize - 2));

                if FileExists(FileNameEx) then begin

                  Self.LoadFromFileEx(FileNameEx, HostsCacheFWListLastAdded, HostsCacheFWListNeedsSorting, HostsCacheNXListLastAdded, HostsCacheNXListNeedsSorting, HostsCacheIPv4ListLastAdded, HostsCacheIPv4ListNeedsSorting, HostsCacheIPv6ListLastAdded, HostsCacheIPv6ListNeedsSorting);

                end;

              end;

            end;

            Continue;

          end;

          HostsLineIndexA := 1;
          HostsLineIndexB := 1;

          HostsLineRecordType := 0; while (HostsLineIndexB <= FileStreamLineSize) do begin

            case (FileStreamLineData[HostsLineIndexB]) of

              #9,
              #32:

              begin

                if (HostsLineIndexB > HostsLineIndexA) then begin

                  case (HostsLineRecordType) of

                    00: begin

                      HostsLineAddressText := Copy(FileStreamLineData, HostsLineIndexA, HostsLineIndexB - HostsLineIndexA);

                      if (HostsLineAddressText = 'FW') then begin

                        HostsLineRecordType  := 10;

                      end else if (HostsLineAddressText = 'NX') then begin

                        HostsLineRecordType  := 20;

                      end else begin

                        HostsLineRecordType  := 99;

                        HostsLineAddressData := TDualIPAddressUtility.Parse(HostsLineAddressText);

                      end;

                    end;

                    10: begin

                      Self.ParseFWHostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsCacheFWListLastAdded, HostsCacheFWListNeedsSorting);

                    end;

                    20: begin

                      Self.ParseNXHostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsCacheNXListLastAdded, HostsCacheNXListNeedsSorting);

                    end;

                    99: begin

                      if HostsLineAddressData.IsIPv6Address then Self.ParseIPv6HostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsLineAddressData.IPv6Address, HostsCacheIPv6ListLastAdded, HostsCacheIPv6ListNeedsSorting) else Self.ParseIPv4HostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsLineAddressData.IPv4Address, HostsCacheIPv4ListLastAdded, HostsCacheIPv4ListNeedsSorting);

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

            case (HostsLineRecordType) of

              10: begin

                Self.ParseFWHostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsCacheFWListLastAdded, HostsCacheFWListNeedsSorting);

              end;

              20: begin

                Self.ParseNXHostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsCacheNXListLastAdded, HostsCacheNXListNeedsSorting);

              end;

              99: begin

                if HostsLineAddressData.IsIPv6Address then Self.ParseIPv6HostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsLineAddressData.IPv6Address, HostsCacheIPv6ListLastAdded, HostsCacheIPv6ListNeedsSorting) else Self.ParseIPv4HostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsLineAddressData.IPv4Address, HostsCacheIPv4ListLastAdded, HostsCacheIPv4ListNeedsSorting);

              end;

            end;

          end;

        end;

      until not(FileStreamLineMoreAvailable);

    finally

      FileStream.Free;

    end;

  except

    on E: Exception do if TTracer.IsEnabled then TTracer.Trace(TracePriorityError, 'THostsCache.LoadFromFileEx: ' + E.Message);

  end;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'THostsCache.LoadFromFileEx: Done loading hosts cache items from file "' + FileName + '".');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.Finalize;

begin

  THostsCache_IPv6Patterns.Free; THostsCache_IPv6Expressions.Free; THostsCache_IPv6List.Free;
  THostsCache_IPv4Patterns.Free; THostsCache_IPv4Expressions.Free; THostsCache_IPv4List.Free;

  THostsCache_NXPatterns.Free; THostsCache_NXExpressions.Free; THostsCache_NXList.Free;
  THostsCache_FWPatterns.Free; THostsCache_FWExpressions.Free; THostsCache_FWList.Free;

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
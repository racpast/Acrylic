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
      class procedure LoadFromFile(const FileName: String);
      class function  FindFWHostsEntry(const HostName: String): Boolean;
      class function  FindNXHostsEntry(const HostName: String): Boolean;
      class function  FindIPv4HostsEntry(const HostName: String; var IPv4Address: TIPv4Address): Boolean;
      class function  FindIPv6HostsEntry(const HostName: String; var IPv6Address: TIPv6Address): Boolean;
      class procedure Finalize;
    private
      class procedure InternalLoadFromFile(const FileName: String);
      class procedure InternalParseFWHostsLine(const FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer);
      class procedure InternalParseNXHostsLine(const FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer);
      class procedure InternalParseIPv4HostsLine(const FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer; var HostsLineAddressData: TIPv4Address);
      class procedure InternalParseIPv6HostsLine(const FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer; var HostsLineAddressData: TIPv6Address);
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
  StrUtils,
  SysUtils,
  Configuration,
  DnsProtocol,
  FileStreamLineEx,
  HostsCacheBinaryTrees,
  MemoryStore,
  PatternMatching,
  PerlRegEx,
  Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TRegularExpressionList = class
    public
      Count: Integer;
    private
      List1: TList;
      List2: TList;
    public
      constructor Create;
      procedure   Add(const Expression: String; Associated: TObject);
      function    ExecRegularExpression(Index: Integer; const InputStr: String): Boolean;
      function    GetAssociatedObject(Index: Integer): TObject;
      procedure   BeginUpdate;
      procedure   EndUpdate;
      destructor  Free;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THostsCache_MemoryStore: TType1MemoryStore;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THostsCache_FWTree: THostsCacheNameOnlyBinaryTree;
  THostsCache_FWPatterns: TStringList;
  THostsCache_FWExpressions: TRegularExpressionList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THostsCache_NXTree: THostsCacheNameOnlyBinaryTree;
  THostsCache_NXPatterns: TStringList;
  THostsCache_NXExpressions: TRegularExpressionList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THostsCache_IPv4Tree: THostsCacheIPv4AddressBinaryTree;
  THostsCache_IPv4Patterns: TStringList;
  THostsCache_IPv4Expressions: TRegularExpressionList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THostsCache_IPv6Tree: THostsCacheIPv6AddressBinaryTree;
  THostsCache_IPv6Patterns: TStringList;
  THostsCache_IPv6Expressions: TRegularExpressionList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.Initialize;

begin

  THostsCache_MemoryStore := TType1MemoryStore.Create(MEMORY_STORE_256KB_BLOCK_SIZE);

  THostsCache_FWTree := THostsCacheNameOnlyBinaryTree.Create(THostsCache_MemoryStore);
  THostsCache_FWPatterns := TStringList.Create;
  THostsCache_FWExpressions := TRegularExpressionList.Create;

  THostsCache_NXTree := THostsCacheNameOnlyBinaryTree.Create(THostsCache_MemoryStore);
  THostsCache_NXPatterns := TStringList.Create;
  THostsCache_NXExpressions := TRegularExpressionList.Create;

  THostsCache_IPv4Tree := THostsCacheIPv4AddressBinaryTree.Create(THostsCache_MemoryStore);
  THostsCache_IPv4Patterns := TStringList.Create;
  THostsCache_IPv4Expressions := TRegularExpressionList.Create;

  THostsCache_IPv6Tree := THostsCacheIPv6AddressBinaryTree.Create(THostsCache_MemoryStore);
  THostsCache_IPv6Patterns := TStringList.Create;
  THostsCache_IPv6Expressions := TRegularExpressionList.Create;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.LoadFromFile(const FileName: String);

begin

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'THostsCache.LoadFromFile: Loading hosts cache items...');

  THostsCache_FWExpressions.BeginUpdate; THostsCache_FWPatterns.BeginUpdate;
  THostsCache_NXExpressions.BeginUpdate; THostsCache_NXPatterns.BeginUpdate;

  THostsCache_IPv4Expressions.BeginUpdate; THostsCache_IPv4Patterns.BeginUpdate;
  THostsCache_IPv6Expressions.BeginUpdate; THostsCache_IPv6Patterns.BeginUpdate;

  Self.InternalLoadFromFile(FileName);

  THostsCache_IPv6Patterns.EndUpdate; THostsCache_IPv6Expressions.EndUpdate;
  THostsCache_IPv4Patterns.EndUpdate; THostsCache_IPv4Expressions.EndUpdate;

  THostsCache_NXPatterns.EndUpdate; THostsCache_NXExpressions.EndUpdate;
  THostsCache_FWPatterns.EndUpdate; THostsCache_FWExpressions.EndUpdate;

  if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'THostsCache.LoadFromFile: Done loading hosts cache items.');

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function THostsCache.FindFWHostsEntry(const HostName: String): Boolean;

var
  ListIndex: Integer;

begin

  if (THostsCache_FWTree.Find(HostName)) then begin

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

class function THostsCache.FindNXHostsEntry(const HostName: String): Boolean;

var
  ListIndex: Integer;

begin

  if (THostsCache_NXTree.Find(HostName)) then begin

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

class function THostsCache.FindIPv4HostsEntry(const HostName: String; var IPv4Address: TIPv4Address): Boolean;

var
  ListIndex: Integer;

begin

  if (THostsCache_IPv4Tree.Find(HostName, IPv4Address)) then begin

    Result := True; Exit;

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

class function THostsCache.FindIPv6HostsEntry(const HostName: String; var IPv6Address: TIPv6Address): Boolean;

var
  TreeData: PIPv6Address; ListIndex: Integer;

begin

  if (THostsCache_IPv6Tree.Find(HostName, TreeData)) then begin

    IPv6Address := TreeData^; Result := True; Exit;

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

class procedure THostsCache.Finalize;

begin

  THostsCache_IPv6Patterns.Free; THostsCache_IPv6Expressions.Free; THostsCache_IPv6Tree.Free;
  THostsCache_IPv4Patterns.Free; THostsCache_IPv4Expressions.Free; THostsCache_IPv4Tree.Free;

  THostsCache_NXPatterns.Free; THostsCache_NXExpressions.Free; THostsCache_NXTree.Free;
  THostsCache_FWPatterns.Free; THostsCache_FWExpressions.Free; THostsCache_FWTree.Free;

  THostsCache_MemoryStore.Free;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.InternalParseFWHostsLine(const FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer);

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

      THostsCache_FWTree.Add(HostsLineTextData);

    end;

  end else if (Pos('*', HostsLineTextData) > 0) or (Pos('?', HostsLineTextData) > 0) then begin

    THostsCache_FWPatterns.AddObject(HostsLineTextData, nil)

  end else begin

    THostsCache_FWTree.Add(HostsLineTextData);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.InternalParseNXHostsLine(const FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer);

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

      THostsCache_NXTree.Add(HostsLineTextData);

    end;

  end else if (Pos('*', HostsLineTextData) > 0) or (Pos('?', HostsLineTextData) > 0) then begin

    THostsCache_NXPatterns.AddObject(HostsLineTextData, nil)

  end else begin

    THostsCache_NXTree.Add(HostsLineTextData);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.InternalParseIPv4HostsLine(const FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer; var HostsLineAddressData: TIPv4Address);

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

      THostsCache_IPv4Tree.Add(HostsLineTextData, HostsLineAddressData);

    end;

  end else if (Pos('*', HostsLineTextData) > 0) or (Pos('?', HostsLineTextData) > 0) then begin

    THostsCache_IPv4Patterns.AddObject(HostsLineTextData, TObject(HostsLineAddressData))

  end else begin

    THostsCache_IPv4Tree.Add(HostsLineTextData, HostsLineAddressData);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.InternalParseIPv6HostsLine(const FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer; var HostsLineAddressData: TIPv6Address);

var
  HostsLineTextData: String; PHostsLineAddressData: PIPv6Address;

begin

  HostsLineTextData := Copy(FileStreamLineData, HostsLineIndexA, HostsLineIndexB - HostsLineIndexA);

  PHostsLineAddressData := THostsCache_MemoryStore.GetMemory(SizeOf(TIPv6Address)); Move(HostsLineAddressData, PHostsLineAddressData^, SizeOf(TIPv6Address));

  if (FileStreamLineData[HostsLineIndexA] = '/') then begin

    THostsCache_IPv6Expressions.Add(Copy(HostsLineTextData, 2, MaxInt), TObject(PHostsLineAddressData))

  end else if (FileStreamLineData[HostsLineIndexA] = '>') then begin

    HostsLineTextData := Copy(HostsLineTextData, 2, MaxInt);

    THostsCache_IPv6Patterns.AddObject('*.' + HostsLineTextData, TObject(PHostsLineAddressData));

    if (Pos('*', HostsLineTextData) > 0) or (Pos('?', HostsLineTextData) > 0) then THostsCache_IPv6Patterns.AddObject(HostsLineTextData, TObject(PHostsLineAddressData)) else begin

      THostsCache_IPv6Tree.Add(HostsLineTextData, PHostsLineAddressData);

    end;

  end else if (Pos('*', HostsLineTextData) > 0) or (Pos('?', HostsLineTextData) > 0) then begin

    THostsCache_IPv6Patterns.AddObject(HostsLineTextData, TObject(PHostsLineAddressData))

  end else begin

    THostsCache_IPv6Tree.Add(HostsLineTextData, PHostsLineAddressData);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.InternalLoadFromFile(const FileName: String);

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

                  Self.InternalLoadFromFile(FileNameEx);

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

                      Self.InternalParseFWHostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB);

                    end;

                    20: begin

                      Self.InternalParseNXHostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB);

                    end;

                    99: begin

                      if HostsLineAddressData.IsIPv6Address then Self.InternalParseIPv6HostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsLineAddressData.IPv6Address) else Self.InternalParseIPv4HostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsLineAddressData.IPv4Address);

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

                Self.InternalParseFWHostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB);

              end;

              20: begin

                Self.InternalParseNXHostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB);

              end;

              99: begin

                if HostsLineAddressData.IsIPv6Address then Self.InternalParseIPv6HostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsLineAddressData.IPv6Address) else Self.InternalParseIPv4HostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsLineAddressData.IPv4Address);

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

constructor TRegularExpressionList.Create;

begin

  List1 := TList.Create; List2 := TList.Create; Count := 0;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TRegularExpressionList.Add(const Expression: String; Associated: TObject);

var
  RegularExpression: TPerlRegEx;

begin

  RegularExpression := TPerlRegEx.Create; RegularExpression.RegEx := Expression; RegularExpression.Options := [preCaseLess]; RegularExpression.Compile; List1.Add(RegularExpression); List2.Add(Associated); Inc(Count);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TRegularExpressionList.ExecRegularExpression(Index: Integer; const InputStr: String): Boolean;

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

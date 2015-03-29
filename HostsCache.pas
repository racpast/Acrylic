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

type
  THostsCache = class
    public
      class procedure Initialize();
      class function  Find(HostName: String; var HostAddress: Integer): Boolean;
      class procedure LoadFromFile(FileName: String);
      class procedure Finalize();
    private
      class procedure ParseHostsLine(FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer; HostsLineAddressData: Integer; var HostsCacheListLastAdded: String; var HostsCacheListNeedsSorting: Boolean);
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Classes, IniFiles, SysUtils, StrUtils, FileStreamLineEx, IPAddress, PatternMatching, RegExpr, Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TRegExprList = class
    private
      List1         : TList;
      List2         : TList;
    public
      Count         : Integer;
      constructor     Create();
      procedure       Add(Expression: String; Associated: TObject);
      function        ExecRegExpr(Index: Integer; InputStr: String): Boolean;
      function        GetAssociatedObject(Index: Integer): TObject;
      procedure       BeginUpdate();
      procedure       EndUpdate();
      destructor      Free();
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THostsCache_List: THashedStringList;
  THostsCache_Expressions: TRegExprList; THostsCache_Patterns: TStringList; THostsCache_Exceptions: THashedStringList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.Initialize();
begin
  THostsCache_List := THashedStringList.Create; THostsCache_List.CaseSensitive := False; THostsCache_List.Duplicates := dupIgnore;
  THostsCache_Exceptions := THashedStringList.Create; THostsCache_Exceptions.CaseSensitive := False; THostsCache_Exceptions.Duplicates := dupIgnore; THostsCache_Expressions := TRegExprList.Create; THostsCache_Patterns := TStringList.Create;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function THostsCache.Find(HostName: String; var HostAddress: Integer): Boolean;
var
  ListIndex: Integer;
begin
  if (THostsCache_List.Find(HostName, ListIndex)) then begin

    HostAddress := Integer(THostsCache_List.Objects[ListIndex]); Result := True; Exit;

  end else begin

    if (THostsCache_Patterns.Count > 0) then begin

      for ListIndex := 0 to (THostsCache_Patterns.Count - 1) do begin
        if TPatternMatching.Match(PChar(HostName), PChar(THostsCache_Patterns.Strings[ListIndex])) then begin
          if not(THostsCache_Exceptions.IndexOf(HostName) > -1) then begin HostAddress := Integer(THostsCache_Patterns.Objects[ListIndex]); Result := True; Exit; end else begin Result := False; Exit; end;
        end;
      end;

    end;

    if (THostsCache_Expressions.Count > 0) then begin

      for ListIndex := 0 to (THostsCache_Expressions.Count - 1) do begin
        try
          if THostsCache_Expressions.ExecRegExpr(ListIndex, HostName) then begin
            if not(THostsCache_Exceptions.IndexOf(HostName) > -1) then begin HostAddress := Integer(THostsCache_Expressions.GetAssociatedObject(ListIndex)); Result := True; Exit; end else begin Result := False; Exit; end;
          end;
        except
        end;
      end;

    end;

  end; Result := False;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.ParseHostsLine(FileStreamLineData: String; HostsLineIndexA: Integer; HostsLineIndexB: Integer; HostsLineAddressData: Integer; var HostsCacheListLastAdded: String; var HostsCacheListNeedsSorting: Boolean);
var
  HostsLineTextData: String;
begin
  HostsLineTextData := Copy(FileStreamLineData, HostsLineIndexA, HostsLineIndexB - HostsLineIndexA);

  if (FileStreamLineData[HostsLineIndexA] = '-') then begin
    THostsCache_Exceptions.Add(Copy(HostsLineTextData, 2, MaxInt))
  end else if (FileStreamLineData[HostsLineIndexA] = '/') then begin
    THostsCache_Expressions.Add(Copy(HostsLineTextData, 2, MaxInt), TObject(HostsLineAddressData))
  end else if (FileStreamLineData[HostsLineIndexA] = '>') then begin
    HostsLineTextData := Copy(HostsLineTextData, 2, MaxInt);
    THostsCache_Patterns.AddObject('*.' + HostsLineTextData, TObject(HostsLineAddressData));
    THostsCache_List.AddObject(HostsLineTextData, TObject(HostsLineAddressData)); if (HostsLineTextData < HostsCacheListLastAdded) then HostsCacheListNeedsSorting := True; HostsCacheListLastAdded := HostsLineTextData;
  end else if (Pos('*', HostsLineTextData) > 0) or (Pos('?', HostsLineTextData) > 0) then begin
    THostsCache_Patterns.AddObject(HostsLineTextData, TObject(HostsLineAddressData))
  end else begin
    THostsCache_List.AddObject(HostsLineTextData, TObject(HostsLineAddressData)); if (HostsLineTextData < HostsCacheListLastAdded) then HostsCacheListNeedsSorting := True; HostsCacheListLastAdded := HostsLineTextData;
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.LoadFromFile(FileName: String);
var
  FileStream: TFileStream; FileStreamLineEx: TFileStreamLineEx;
  FileStreamLineData: String; FileStreamLineMoreAvailable: Boolean; FileStreamLineSize: Integer; HostsLineIndexA: Integer; HostsLineIndexB: Integer; HostsLineAddressData: Integer; HostsLineAddressDone: Boolean; HostsCacheListLastAdded: String; HostsCacheListNeedsSorting: Boolean;
begin
  if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'THostsCache.LoadFromFile: Loading hosts cache items...');

  FileStream := TFileStream.Create(FileName, fmOpenRead, fmShareDenyWrite); try

    // Create the decorator object
    FileStreamLineEx := TFileStreamLineEx.Create(FileStream);

    // Signal that we're going to do a big update
    THostsCache_List.BeginUpdate(); THostsCache_Expressions.BeginUpdate(); THostsCache_Patterns.BeginUpdate(); THostsCache_Exceptions.BeginUpdate();

    SetLength(HostsCacheListLastAdded, 0); HostsCacheListNeedsSorting := False; repeat // Until there are no more lines available

      // Read the next line from the stream
      FileStreamLineMoreAvailable := FileStreamLineEx.ReadLine(FileStreamLineData); FileStreamLineSize := Length(FileStreamLineData); if (FileStreamLineSize > 0) then begin

        HostsLineIndexA := 1;
        HostsLineIndexB := 1;

        HostsLineAddressData := 0; HostsLineAddressDone := False; while (HostsLineIndexB <= FileStreamLineSize) do begin

          case (FileStreamLineData[HostsLineIndexB]) of

            #9,
            #32:
            begin
              if (HostsLineIndexB > HostsLineIndexA) then begin

                if HostsLineAddressDone then begin

                  Self.ParseHostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsLineAddressData, HostsCacheListLastAdded, HostsCacheListNeedsSorting);

                end else begin

                  HostsLineAddressData := TIPAddress.Parse(Copy(FileStreamLineData, HostsLineIndexA, HostsLineIndexB - HostsLineIndexA));
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

            Self.ParseHostsLine(FileStreamLineData, HostsLineIndexA, HostsLineIndexB, HostsLineAddressData, HostsCacheListLastAdded, HostsCacheListNeedsSorting);

          end;

        end;

      end;

    until not(FileStreamLineMoreAvailable);

    // Sort the lists now to improve search later
    if (HostsCacheListNeedsSorting) then THostsCache_List.Sort; THostsCache_Exceptions.Sort;

    // Signal that the big update is done
    THostsCache_Exceptions.EndUpdate(); THostsCache_Patterns.EndUpdate(); THostsCache_Expressions.EndUpdate(); THostsCache_List.EndUpdate();

  finally

    FileStream.Free;

  end;

  if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'THostsCache.LoadFromFile: Loaded ' + IntToStr(THostsCache_List.Count) + ' ' + IfThen(HostsCacheListNeedsSorting, 'unordered', 'sorted') + ' hostnames, ' + IntToStr(THostsCache_Expressions.Count) + ' regexes, ' + IntToStr(THostsCache_Patterns.Count) + ' patterns and ' + IntToStr(THostsCache_Exceptions.Count) + ' exceptions successfully.');
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.Finalize();
begin
  THostsCache_Patterns.Free; THostsCache_Expressions.Free; THostsCache_Exceptions.Free; THostsCache_List.Free;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TRegExprList.Create();
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

procedure TRegExprList.BeginUpdate();
begin
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TRegExprList.EndUpdate();
begin
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TRegExprList.Free();
var
  Index: Integer;
begin
  List2.Free; for Index := 0 to (Count - 1) do TRegExpr(List1[Index]).Free; List1.Free;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
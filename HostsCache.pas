
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
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SysUtils, Classes, IniFiles, FileStreamLineEx, RegExpr, PatternMatching, IPAddress;

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
  THostsCache_Exceptions: THashedStringList; THostsCache_Expressions: TRegExprList; THostsCache_Patterns: TStringList;

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

class procedure THostsCache.LoadFromFile(FileName: String);
var
  FileStream: TFileStream; FileStreamLineEx: TFileStreamLineEx;
  FileStreamLineData: String; FileStreamLineMoreAvailable: Boolean; FileStreamLineSize: Integer; HostsLineIndexA: Integer; HostsLineIndexB: Integer; HostsLineTextData: String; HostsLineAddressData: Integer; HostsLineAddressDone: Boolean;
begin
  // Create the stream object
  FileStream := TFileStream.Create(FileName, fmOpenRead, fmShareDenyWrite); try

    // Create the decorator object
    FileStreamLineEx := TFileStreamLineEx.Create(FileStream);

    // Signal that we're going to do a big update
    THostsCache_List.BeginUpdate(); THostsCache_Expressions.BeginUpdate(); THostsCache_Patterns.BeginUpdate(); THostsCache_Exceptions.BeginUpdate();

    repeat // Until there are no more lines available

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

                  HostsLineTextData := Copy(FileStreamLineData, HostsLineIndexA, HostsLineIndexB - HostsLineIndexA);
                  if (FileStreamLineData[HostsLineIndexA] = '-') then THostsCache_Exceptions.Add(Copy(HostsLineTextData, 2, MaxInt)) else if (FileStreamLineData[HostsLineIndexA] = '/') then THostsCache_Expressions.Add(Copy(HostsLineTextData, 2, MaxInt), TObject(HostsLineAddressData)) else if (Pos('*', HostsLineTextData) > 0) or (Pos('?', HostsLineTextData) > 0) then THostsCache_Patterns.AddObject(HostsLineTextData, TObject(HostsLineAddressData)) else THostsCache_List.AddObject(HostsLineTextData, TObject(HostsLineAddressData));

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

            HostsLineTextData := Copy(FileStreamLineData, HostsLineIndexA, HostsLineIndexB - HostsLineIndexA);
            if (FileStreamLineData[HostsLineIndexA] = '-') then THostsCache_Exceptions.Add(Copy(HostsLineTextData, 2, MaxInt)) else if (FileStreamLineData[HostsLineIndexA] = '/') then THostsCache_Expressions.Add(Copy(HostsLineTextData, 2, MaxInt), TObject(HostsLineAddressData)) else if (Pos('*', HostsLineTextData) > 0) or (Pos('?', HostsLineTextData) > 0) then THostsCache_Patterns.AddObject(HostsLineTextData, TObject(HostsLineAddressData)) else THostsCache_List.AddObject(HostsLineTextData, TObject(HostsLineAddressData));

          end;

        end;

      end;

    until not(FileStreamLineMoreAvailable);

    // Signal that the big update is done
    THostsCache_Exceptions.EndUpdate(); THostsCache_Patterns.EndUpdate(); THostsCache_Expressions.EndUpdate(); THostsCache_List.EndUpdate();

    // Set some of the lists as sorted
    THostsCache_List.Sorted := True; THostsCache_Exceptions.Sorted := True;

  finally

    // Close the stream
    FileStream.Free;

  end;
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

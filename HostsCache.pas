
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
    private
      class procedure Add(HostName: String; HostAddress: Integer; HostExceptions: String);
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
  SysUtils, Classes, IniFiles, FileStreamLineEx, HostsLineParser, PatternMatching;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THostsCache_List: THashedStringList;
  THostsCache_Patterns: TStringList; THostsCache_Exceptions: THashedStringList;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.Initialize();
begin
  THostsCache_List := THashedStringList.Create; THostsCache_List.CaseSensitive := False; THostsCache_List.Duplicates := dupIgnore;
  THostsCache_Patterns := TStringList.Create; THostsCache_Exceptions := THashedStringList.Create; THostsCache_Exceptions.CaseSensitive := False; THostsCache_Exceptions.Duplicates := dupIgnore;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.Add(HostName: String; HostAddress: Integer; HostExceptions: String);
var
  Offset: Integer;
begin
  if (Pos('*', HostName) > 0) or (Pos('?', HostName) > 0) then begin // If it's a pattern...

    // Add it to the list
    THostsCache_Patterns.AddObject(HostName, TObject(HostAddress));

    if (Length(HostExceptions) > 0) then begin // If there are exceptions...
      Offset := 1; while (Offset < Length(HostExceptions)) do begin // Then parse & add them...

        if (HostExceptions[Offset] = ',') then begin
          if (Offset > 1) then THostsCache_Exceptions.Add(Copy(HostExceptions, 1, Offset - 1)); Delete(HostExceptions, 1, Offset); Offset := 1;
        end else begin
          Inc(Offset);
        end;

      end; THostsCache_Exceptions.Add(HostExceptions);
    end;

  end else begin // Not a pattern
    THostsCache_List.AddObject(HostName, TObject(HostAddress));
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function THostsCache.Find(HostName: String; var HostAddress: Integer): Boolean;
var
  HostIndex: Integer;
begin
  if (THostsCache_List.Find(HostName, HostIndex)) then begin
    HostAddress := Integer(THostsCache_List.Objects[HostIndex]); Result := True;
  end else if (THostsCache_Patterns.Count > 0) then begin

    Result := False; for HostIndex := 0 to (THostsCache_Patterns.Count - 1) do begin
      if TPatternMatching.Match(PChar(HostName), PChar(THostsCache_Patterns.Strings[HostIndex])) then begin

        if not(THostsCache_Exceptions.IndexOf(HostName) > -1) then begin
          HostAddress := Integer(THostsCache_Patterns.Objects[HostIndex]); Result := True; Break;
        end else begin
          Result := False; Break;
        end;

      end;
    end;

  end else begin // No more to try...
    Result := False;
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THostsCache.LoadFromFile(FileName: String);
var
  FileStream: TFileStream; FileStreamLineEx: TFileStreamLineEx;
  Line: String; MoreLinesAvailable: Boolean; HostName: String; HostAddress: Integer; HostExceptions: String;
begin
  // Create the stream object
  FileStream := TFileStream.Create(FileName, fmOpenRead, fmShareDenyWrite); try

    // Create the decorator object
    FileStreamLineEx := TFileStreamLineEx.Create(FileStream);

    // Signal that we're going to do a big update
    THostsCache_List.BeginUpdate(); THostsCache_Patterns.BeginUpdate(); THostsCache_Exceptions.BeginUpdate();

    repeat // Until there are no more lines available

      // Read the next line from the stream
      MoreLinesAvailable := FileStreamLineEx.ReadLine(Line);

      // If the line contains a valid host name and host address then add it to the list
      if (THostsLineParser.Parse(Line, HostName, HostAddress, HostExceptions)) then Self.Add(HostName, HostAddress, HostExceptions);

    until not(MoreLinesAvailable);

    // Signal that the big update is done
    THostsCache_Exceptions.EndUpdate(); THostsCache_Patterns.EndUpdate(); THostsCache_List.EndUpdate();

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
  THostsCache_Exceptions.Free; THostsCache_Patterns.Free; THostsCache_List.Free;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

unit
  WebServer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Windows, SysUtils, Winsock, SyncObjs, Lzo, Shared, FileCtrl;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  MAX_GET_PARAMS =     8;    // MAX GET PARAMETERS
  WINDOW_SIZE    =  1510;    // TCP/IP PACKET SIZE (WINDOW)
  RECV_TIMEOUT   =    30;    // RECEIVE TIMEOUT IN TENTHS OF SECOND
  SEND_TIMEOUT   =    30;    // SEND TIMEOUT IN TENTHS OF SECOND

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  WebServerRunning: Boolean;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  WebServerArchiveName: String;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function HttpServer(Port: Integer): Integer; safecall; far;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  Semaphore: TCriticalSection;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure HttpSplitRequest(Request: String; var Method, Url, Version: String);
var
  j: Integer;
begin
  SetLength(Url, 0);
  SetLength(Method, 0);
  SetLength(Version, 0);
  j := Pos(#32, Request); if (j > 0) then begin
    Method := Copy(Request, 1, j - 1); Delete(Request, 1, j);
    j := Pos(#32, Request); if (j > 0) then begin
      Url := Copy(Request, 1, j - 1); Delete(Request, 1, j); Version := Request;
    end;
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure HttpSplitUrl(Url: String; var UrlBody, UrlParams: String);
var
  j: Integer;
begin
  j := Pos(#63, Url); if (j > 0) then begin
    UrlBody := Copy(Url, 1, j - 1); UrlParams := Copy(Url, j + 1, Length(Url));
  end else begin
    UrlBody := Url; SetLength(UrlParams, 0);
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure HttpSplitParams(var UrlParams: String; var Params: Array of String; Limit: Integer);
var
  i, j: Integer;
begin
  SetLength(Params[0], 0);
  i := 0; for j := 1 to Length(UrlParams) do case UrlParams[j] of
    #61: SetLength(Params[i], 0);
    #38: if (i < Limit) then begin Inc(i); SetLength(Params[i], 0) end;
    else Params[i] := Params[i] + UrlParams[j];
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function UrlPathFilter(UrlBody: String): String;
begin
  UrlBody := StringReplace(UrlBody, '\', '/', [rfReplaceAll]);

  while (Copy(UrlBody, 1, 1) = '/') do UrlBody := Copy(UrlBody, 2, Length(UrlBody) - 1);
  while (Copy(UrlBody, Length(UrlBody), 1) = '/') do UrlBody := Copy(UrlBody, 1, Length(UrlBody) - 1);

  Result := UrlBody;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function ExtractUrlExt(UrlBody: String): String;
var
  UrlExt: String;
  ParamPos: Integer;
begin
  UrlExt := ExtractFileExt(UrlBody);
  ParamPos := Pos('?', UrlExt); if (ParamPos > 0) then UrlExt := Copy(UrlExt, 1, ParamPos - 1);
  ParamPos := Pos('#', UrlExt); if (ParamPos > 0) then UrlExt := Copy(UrlExt, 1, ParamPos - 1);
  Result := UrlExt;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function GetMimeTypeByExtension(Ext: String): String;
begin
  Ext := LowerCase(Ext);
  if (Ext = '.htm' ) then Result := 'text/html'
  else if (Ext = '.html') then Result := 'text/html'
  else if (Ext = '.jpeg') then Result := 'image/jpeg'
  else if (Ext = '.jpg' ) then Result := 'image/jpg'
  else if (Ext = '.gif' ) then Result := 'image/gif'
  else if (Ext = '.png' ) then Result := 'image/png'
  else if (Ext = '.bmp' ) then Result := 'image/bmp'
  else if (Ext = '.js'  ) then Result := 'application/x-javascript'
  else if (Ext = '.css' ) then Result := 'text/css'
  else if (Ext = '.midi') then Result := 'audio/midi'
  else if (Ext = '.mid' ) then Result := 'audio/midi'
  else if (Ext = '.xml' ) then Result := 'application/xml'
  else if (Ext = '.swf' ) then Result := 'application/x-shockwave-flash'
  else if (Ext = '.pdf' ) then Result := 'application/pdf'
  else if (Ext = '.ps'  ) then Result := 'application/postscript'
  else if (Ext = '.mp3' ) then Result := 'audio/mpeg'
  else if (Ext = '.wav' ) then Result := 'audio/wav'
  else if (Ext = '.gz'  ) then Result := 'application/x-gzip'
  else if (Ext = '.tgz' ) then Result := 'application/x-gzip'
  else if (Ext = '.zip' ) then Result := 'application/zip'
  else Result := '*/*';
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function FindItem(UrlBody: String; var Position: Cardinal): Boolean;
var
  Found: Boolean;
begin
  UrlBody := LowerCase(UrlBody);
  Position := 0; Found := False; while (Position < ListSize) and not(Found) do begin
    Found := (UrlBody = LowerCase(List[Position].Name)); if not(Found) then Inc(Position);
  end; Result := Found;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure HttpAgentDispatcher(var UrlBody, OutputStr: String; var OutputLen: Integer; var MimeType: String; var Params: Array of String);
var
  Buffer: PByteArray;
  Position, BytesRead, BytesDecompressed: Cardinal;
begin
  // Filter...
  UrlBody := UrlPathFilter(UrlBody);

  // If item found...
  if FindItem(UrlBody, Position) then begin

    // Red semaphore...
    Semaphore.Acquire;

    // Allocating memory...
    OutputLen := List[Position].Size; SetLength(OutputStr, OutputLen);

    // Going to the appropriate position in the archive...
    SetFilePointer(Archive, List[Position].Position, nil, FILE_BEGIN);

    // If the file is compressed...
    if ((List[Position].Compressed > 0) and (List[Position].Compressed < List[Position].Size)) then begin

      // Allocating memory...
      GetMem(Buffer, List[Position].Compressed);

      // Reading and decompressing data...
      ReadFile(Archive, Buffer^, List[Position].Compressed, BytesRead, nil);
      lzo1x_decompress(Buffer, BytesRead, @OutputStr[1], BytesDecompressed, nil);

      // Deallocating memory...
      FreeMem(Buffer, List[Position].Compressed);

    end else begin

      // Reading data from the archive...
      ReadFile(Archive, OutputStr[1], OutputLen, BytesRead, nil);

    end;

    // Setting mime type...
    MimeType := GetMimeTypeByExtension(ExtractUrlExt(UrlBody));

    // Green semaphore...
    Semaphore.Release;

  end else begin

    // Defining error message...
    OutputStr := 'Cannot find the specified page: ' + UrlBody;
    OutputLen := Length(OutputStr);

    // Setting mime type...
    MimeType := 'text/plain';

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function HttpAgent(Sok: Integer): Integer; safecall; far;
var
  Done: Boolean;
  Tmv: Timeval; Fds: TFDSet;
  Window: Array [0..(WINDOW_SIZE - 1)] of Char;
  Params: Array [0..(MAX_GET_PARAMS - 1)] of String;
  Request, Method, Url, Version, UrlBody, UrlParams, OutputStr, OutputHeader, MimeType: String;
  j, Bytes, OutputLen, WindowLen: Integer;
begin
  SetLength(Request, 0); Done := false;
  Tmv.tv_sec := (RECV_TIMEOUT div 10); Tmv.tv_usec := 100000 * (RECV_TIMEOUT mod 10); repeat
    Bytes := 0; Fds.fd_count := 1; Fds.fd_array[0] := Sok;
    if (Select(0, @Fds, nil, nil, @Tmv) > 0) then Bytes := Recv(Sok, Window, WINDOW_SIZE, 0);
    for j := 0 to (Bytes - 1) do case Window[j] of
      #13: ;
      #10: begin Done := True; break end;
      else Request := Request + Window[j];
    end;
  until (Bytes < 1) or Done;

  if (Done) then begin
    HttpSplitRequest(Request, Method, Url, Version); if (Method = 'GET') then begin
      HttpSplitUrl(Url, UrlBody, UrlParams);
      HttpSplitParams(UrlParams, Params, MAX_GET_PARAMS);
      HttpAgentDispatcher(UrlBody, OutputStr, OutputLen, MimeType, Params);
      OutputHeader := Version + ' 200 OK'#13#10'Content-Type: ' + MimeType + #13#10'Content-Length: ' + IntToStr(OutputLen) + #13#10#13#10;
      Inc(OutputLen, Length(OutputHeader)); Insert(OutputHeader, OutputStr, 1);
      Tmv.tv_sec := (SEND_TIMEOUT div 10); Tmv.tv_usec := 100000 * (SEND_TIMEOUT mod 10); j := 1; repeat
        Bytes := 0; Fds.fd_count := 1; Fds.fd_array[0] := Sok;
        if (Select(0, nil, @Fds, nil, @Tmv) > 0) then begin
          WindowLen := (OutputLen - j + 1); if (WindowLen > WINDOW_SIZE) then WindowLen := WINDOW_SIZE;
          Bytes := Send(Sok, OutputStr[j], WindowLen, 0); if (Bytes > 0) then Inc(j, Bytes);
        end;
      until (Bytes < 1) or (j > OutputLen);
    end;
  end;

  Shutdown(Sok, 1);
  CloseSocket(Sok);

  ExitThread(0);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function HttpServer(Port: Integer): Integer; safecall; far;
var
  Id: Cardinal;
  NameSize: Word;
  BytesRead: Cardinal;
  Sok, Act: TSocket;
  Sin: TSockAddrIn;
  WSA: TWSAData;
begin
  // Updating state...
  WebServerRunning := True;

  // Opening source archive...
  Archive := CreateFile(PChar(WebServerArchiveName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0); if (Archive <> INVALID_HANDLE_VALUE) then begin

    // Getting footer offset...
    ReadFile(Archive, ArchiveSize, SizeOf(ArchiveSize), BytesRead, nil);

    // Positioning at footer offset...
    SetFilePointer(Archive, ArchiveSize, nil, FILE_BEGIN);

    // Getting list items...
    ListSize := 0; repeat
      ReadFile(Archive, List[ListSize].Size, SizeOf(List[ListSize].Size), BytesRead, nil); if (BytesRead = SizeOf(List[ListSize].Size)) then begin

        // Reading item size and position...
        ReadFile(Archive, List[ListSize].Compressed, SizeOf(List[ListSize].Compressed), BytesRead, nil);
        ReadFile(Archive, List[ListSize].Position, SizeOf(List[ListSize].Position), BytesRead, nil);
        ReadFile(Archive, NameSize, SizeOf(NameSize), BytesRead, nil);

        // Reading item name...
        SetLength(List[ListSize].Name, NameSize);
        ReadFile(Archive, List[ListSize].Name[1], NameSize, BytesRead, nil);

        // Next item...
        Inc(ListSize);

      end else begin
        Break;
      end;
    until false;

    // Positioning at the beginning of the archive...
    SetFilePointer(Archive, 0, nil, FILE_BEGIN);

    // Initializing winsock...
    WSAStartup(257, WSA);

    // Initializing connection...
    Sin.sin_family := AF_INET;
    Sin.sin_port := htons(Port);
    Sin.sin_addr.S_addr := htonl(INADDR_ANY);

    // Initializing critical section...
    Semaphore := TCriticalSection.Create;

    // Listening for incoming connections...
    Sok := Socket(AF_INET, SOCK_STREAM, 0); if (Sok <> INVALID_SOCKET) then begin
      if (Bind(Sok, Sin, SizeOf(TSockAddrIn)) = 0) then repeat
        if (Listen(Sok, SOMAXCONN) = 0) then begin
          Act := Accept(Sok, nil, nil);
          if (Act <> INVALID_SOCKET) then CreateThread(nil, 0, @HttpAgent, Pointer(Act), 0, Id);
        end;
      until False;
      Shutdown(Sok, 1);
      CloseSocket(Sok);
    end;

    // Finalizing critical section...
    Semaphore.Free;

    // Finalizing winsock...
    WSACleanup;

    // Closing archive...
    CloseHandle(Archive);

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

initialization
  WebServerRunning := False;
end.
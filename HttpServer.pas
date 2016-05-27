// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  HttpServer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Classes,
  SysUtils,
  CommunicationChannels,
  Configuration;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  THttpServer = class(TThread)
    public
      class function  GetInstance: THttpServer;
      class procedure StartInstance;
      class procedure StopInstance;
    public
      constructor Create;
      procedure   Execute; override;
    private
      procedure   HandleHttpRequest(IncomingCommunicationChannel: TIPv4TcpCommunicationChannel; Request: Pointer; RequestLen: Integer; var Response: Pointer; var ResponseLen: Integer);
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Windows,
  MemoryManager,
  Tracer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  MAX_HTTP_BUFFER_LEN = 65536;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  HTTP_SERVER_MAX_BLOCK_TIME = 3037;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  HTTP_SERVER_REQUEST_RECEIVE_TIMEOUT = 1013;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  THttpServer_Instance: THttpServer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function THttpServer.GetInstance;
begin
  Result := THttpServer_Instance;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THttpServer.StartInstance;
begin
  THttpServer_Instance := THttpServer.Create; THttpServer_Instance.Resume;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure THttpServer.StopInstance;
begin
  THttpServer_Instance.Terminate; THttpServer_Instance.WaitFor; THttpServer_Instance.Free;
end;
// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor THttpServer.Create;
begin
  inherited Create(True); FreeOnTerminate := False;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure THttpServer.HandleHttpRequest(IncomingCommunicationChannel: TIPv4TcpCommunicationChannel; Request: Pointer; RequestLen: Integer; var Response: Pointer; var ResponseLen: Integer);
var
  RequestText: String; ResponseText: String;
begin
  if TIPv4AddressUtility.IsLocalHost(IncomingCommunicationChannel.RemoteAddress) or TConfiguration.IsAllowedAddress(TIPv4AddressUtility.ToString(IncomingCommunicationChannel.RemoteAddress)) then begin

    SetLength(RequestText, RequestLen); Move(Request^, RequestText[1], RequestLen);

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'THttpServer.HandleHttpRequest: HTTP request received from address ' + TIPv4AddressUtility.ToString(IncomingCommunicationChannel.RemoteAddress) + ':' + IntToStr(IncomingCommunicationChannel.RemotePort) + ' as follows:' + #13#10 + RequestText);

    if (Pos('GET /favicon.ico HTTP/', RequestText) > 0) then begin

      ResponseText := 'HTTP/1.1 404 Not Found' + #13#10 + 'Content-Length: 0' + #13#10 + 'Connection: close' + #13#10 + #13#10; ResponseLen := Length(ResponseText); Move(ResponseText[1], Response^, ResponseLen);

    end else if (Pos('Accept: text/css', RequestText) > 0) then begin

      ResponseText := 'HTTP/1.1 200 OK' + #13#10 + 'Content-Type: text/css' + #13#10 + 'Content-Length: 0' + #13#10 + 'Connection: close' + #13#10 + #13#10; ResponseLen := Length(ResponseText); Move(ResponseText[1], Response^, ResponseLen);

    end else if (Pos('Accept: text/html', RequestText) > 0) then begin

      ResponseText := '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>Acrylic DNS Proxy</title></head><body><h1>Acrylic DNS Proxy</h1><p>This content has been provided by Acrylic DNS Proxy.</p></body></html>'; ResponseText := 'HTTP/1.1 200 OK' + #13#10 + 'Content-Type: text/html; charset=utf-8' + #13#10 + 'Content-Length: ' + IntToStr(Length(ResponseText)) + #13#10 + 'Connection: close' + #13#10 + #13#10 + ResponseText; ResponseLen := Length(ResponseText); Move(ResponseText[1], Response^, ResponseLen);

    end else if (Pos('Accept: application/javascript', RequestText) > 0) or (Pos('Accept: */*', RequestText) > 0) then begin

      ResponseText := 'HTTP/1.1 200 OK' + #13#10 + 'Content-Length: 0' + #13#10 + 'Connection: close' + #13#10 + #13#10; ResponseLen := Length(ResponseText); Move(ResponseText[1], Response^, ResponseLen);

    end else if (Pos('Accept: image/webp,image/*', RequestText) > 0) or (Pos('Accept: image/png', RequestText) > 0) or (Pos('Accept: image/*', RequestText) > 0) then begin

      ResponseText := #$89#$50#$4e#$47#$0d#$0a#$1a#$0a#$00#$00#$00#$0d#$49#$48#$44#$52#$00#$00#$00#$01#$00#$00#$00#$01#$08#$02#$00#$00#$00#$90#$77#$53#$de#$00#$00#$00#$0c#$49#$44#$41#$54#$08#$d7#$63#$f8#$ff#$ff#$3f#$00#$05#$fe#$02#$fe#$dc#$cc#$59#$e7#$00#$00#$00#$00#$49#$45#$4e#$44#$ae#$42#$60#$82; ResponseText := 'HTTP/1.1 200 OK' + #13#10 + 'Content-Type: ' + 'image/png' + #13#10 + 'Content-Length: ' + IntToStr(Length(ResponseText)) + #13#10 + 'Connection: close' + #13#10 + #13#10 + ResponseText; ResponseLen := Length(ResponseText); Move(ResponseText[1], Response^, ResponseLen);

    end else begin

      ResponseText := 'HTTP/1.1 404 Not Found' + #13#10 + 'Content-Length: 0' + #13#10 + 'Connection: close' + #13#10 + #13#10; ResponseLen := Length(ResponseText); Move(ResponseText[1], Response^, ResponseLen);

    end;

    IncomingCommunicationChannel.Send(Response, ResponseLen);

  end else begin

    if TTracer.IsEnabled then TTracer.Trace(TracePriorityInfo, 'THttpServer.HandleHttpRequest: Unexpected HTTP request received from address ' + TIPv4AddressUtility.ToString(IncomingCommunicationChannel.RemoteAddress) + ':' + IntToStr(IncomingCommunicationChannel.RemotePort) + '.');

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure THttpServer.Execute;
var
  ServerCommunicationChannel: TIPv4TcpCommunicationChannel; IncomingCommunicationChannel: TIPv4TcpCommunicationChannel; Request: Pointer; RequestLen: Integer; Response: Pointer; ResponseLen: Integer;
begin
  ServerCommunicationChannel := TIPv4TcpCommunicationChannel.Create;

  try

    ServerCommunicationChannel.Bind(TConfiguration.GetHttpServerConfiguration.BindingAddress, TConfiguration.GetHttpServerConfiguration.BindingPort);

    try

      TMemoryManager.GetMemory(Request, MAX_HTTP_BUFFER_LEN);

      try

        TMemoryManager.GetMemory(Response, MAX_HTTP_BUFFER_LEN);

        try

          ServerCommunicationChannel.Listen;

          repeat

            IncomingCommunicationChannel := ServerCommunicationChannel.Accept(HTTP_SERVER_MAX_BLOCK_TIME); if (IncomingCommunicationChannel <> nil) then begin

              try

                if IncomingCommunicationChannel.Receive(HTTP_SERVER_REQUEST_RECEIVE_TIMEOUT, MAX_HTTP_BUFFER_LEN, Request, RequestLen) then begin

                  Self.HandleHttpRequest(IncomingCommunicationChannel, Request, RequestLen, Response, ResponseLen);

                end;

              finally

                IncomingCommunicationChannel.Free;

              end;

            end;

          until Terminated;

        finally

          TMemoryManager.FreeMemory(Response, MAX_HTTP_BUFFER_LEN);

        end;

      finally

        TMemoryManager.FreeMemory(Request, MAX_HTTP_BUFFER_LEN);

      end;

    finally

      // Nothing do to

    end;

  finally

    ServerCommunicationChannel.Free;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

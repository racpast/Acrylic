// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  Resolver;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Classes;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TResolver = class(TThread)
    private
      Buffer    : Pointer;
      BufferLen : Integer;
      Output    : Pointer;
      OutputLen : Integer;
    private
      function    GetIdFromPacket(Buffer: Pointer): Word;
      procedure   SetIdIntoPacket(Value: Word; Buffer: Pointer);
    private
      function    GetWordFromPacket(Buffer: Pointer; Offset: Integer; BufferLen: Integer): Word;
      function    GetIntegerFromPacket(Buffer: Pointer; Offset: Integer; BufferLen: Integer): Integer;
    private
      procedure   SetStringIntoPacket(Value: String; Buffer: Pointer; var Offset: Integer; BufferLen: Integer);
      function    GetStringFromPacket(Value: String; Buffer: Pointer; var OffsetL1: Integer; var OffsetLX: Integer; Level: Integer; BufferLen: Integer): String;
    private
      procedure   BuildNegativeResponsePacketFromHostName(HostName: String; Buffer: Pointer; var BufferLen: Integer);
      procedure   BuildPositiveResponsePacketFromHostNameAndAddress(HostName: String; HostAddress: Integer; Buffer: Pointer; var BufferLen: Integer);
    private
      procedure   GetHostNameAndQueryTypeFromRequestPacket(Buffer: Pointer; BufferLen: Integer; var HostName: String; var QueryType: Word);
    private
      function    PrintGenericPacketBytesAsStringFromPacket(Buffer: Pointer; BufferLen: Integer): String;
      function    PrintGenericPacketBytesAsStringFromPacketWithOffset(Buffer: Pointer; BufferLen: Integer; Offset: Integer; NumBytes: Integer): String;
    private
      function    PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer: Pointer; BufferLen: Integer; IncludePacketBytesAlways: Boolean): String;
      function    PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer: Pointer; BufferLen: Integer; IncludePacketBytesAlways: Boolean): String;
    private
      function    PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer: Pointer; BufferLen: Integer; IncludePacketBytesAlways: Boolean): String;
      function    PrintResponsePacketDescriptionAsLegacyStringFromPacket(Buffer: Pointer; BufferLen: Integer; IncludePacketBytesAlways: Boolean): String;
    private
      function    IsFailureResponsePacket(Buffer: Pointer; BufferLen: Integer): Boolean;
      function    IsNegativeResponsePacket(Buffer: Pointer; BufferLen: Integer): Boolean;
    public
      constructor Create();
      destructor  Destroy(); override;
      procedure   Execute(); override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Math, SysUtils, Configuration, Tracer, ClientServerSocket, Digest, SessionCache, AddressCache, HostsCache, HitLogger, Performance, QueryTypeUtils, Statistics, IPAddress;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TResolver.Create();
begin
  inherited Create(True);

  // Want to free by hand
  FreeOnTerminate := False;

  // Allocate memory buffers
  GetMem(Buffer, MAX_DNS_BUFFER_LEN); GetMem(Output, MAX_DNS_BUFFER_LEN);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TResolver.Destroy();
begin
  // Deallocate memory buffers
  FreeMem(Output, MAX_DNS_BUFFER_LEN); FreeMem(Buffer, MAX_DNS_BUFFER_LEN);

  inherited Destroy();
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TResolver.GetIdFromPacket(Buffer: Pointer): Word;
begin
  Result := (PByteArray(Buffer)^[0] shl 8) + PByteArray(Buffer)^[1];
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TResolver.SetIdIntoPacket(Value: Word; Buffer: Pointer);
begin
  PByteArray(Buffer)^[0] := Value shr 8; PByteArray(Buffer)^[1] := Value and 255;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TResolver.GetWordFromPacket(Buffer: Pointer; Offset: Integer; BufferLen: Integer): Word;
begin
  Result := (PByteArray(Buffer)^[Offset] shl 8) + PByteArray(Buffer)^[Offset + 1];
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TResolver.GetIntegerFromPacket(Buffer: Pointer; Offset: Integer; BufferLen: Integer): Integer;
begin
  Result := (PByteArray(Buffer)^[Offset] shl 24) + (PByteArray(Buffer)^[Offset + 1] shl 16) + (PByteArray(Buffer)^[Offset + 2] shl 8) + PByteArray(Buffer)^[Offset + 3];
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TResolver.GetStringFromPacket(Value: String; Buffer: Pointer; var OffsetL1: Integer; var OffsetLX: Integer; Level: Integer; BufferLen: Integer): String;
var
  Index: Integer;
begin
  if (OffsetLX < BufferLen) then begin
    if (PByteArray(Buffer)^[OffsetLX] > 0) then begin
      if ((PByteArray(Buffer)^[OffsetLX] and $C0) > 0) then begin

        if ((OffsetLX + 1) < BufferLen) then begin

          // Update the offsets (first and other levels)
          if (Level = 1) then Inc(OffsetL1, 2); OffsetLX := ((PByteArray(Buffer)^[OffsetLX] and $1F) shl 8) + PByteArray(Buffer)^[OffsetLX + 1];

          // Call the function recursively
          Value := GetStringFromPacket(Value, Buffer, OffsetL1, OffsetLX, Level + 1, BufferLen);

        end else begin
          if (Level = 1) then Inc(OffsetL1); Inc(OffsetLX);
        end;

      end else if ((OffsetLX + PByteArray(Buffer)^[OffsetLX] + 1) < BufferLen) then begin

        // Add the domain separator (a dot)
        if (Value <> '') then Value := Value + '.';

        // Add the domain one character at a time
        for Index := 1 to PByteArray(Buffer)^[OffsetLX] do Value := Value + Char(PByteArray(Buffer)^[OffsetLX + Index]);

        // Update the offsets (first and other levels)
        if (Level = 1) then Inc(OffsetL1, PByteArray(Buffer)^[OffsetLX] + 1); Inc(OffsetLX, PByteArray(Buffer)^[OffsetLX] + 1);

        // Call the function recursively
        Value := GetStringFromPacket(Value, Buffer, OffsetL1, OffsetLX, Level, BufferLen);

      end;
    end else begin

      // Update the offsets (first and other levels)
      if (Level = 1) then Inc(OffsetL1); Inc(OffsetLX);

    end;
  end; Result := Value;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TResolver.SetStringIntoPacket(Value: String; Buffer: Pointer; var Offset: Integer; BufferLen: Integer);
var
  PIndex: Integer; CIndex: Integer;
begin
  PIndex := 0;

  for CIndex := 1 to Length(Value) do begin // Write the string into the packet

    if (Value[CIndex] <> '.') then begin
      PByteArray(Buffer)^[Offset + PIndex + 1] := Byte(Value[CIndex]); Inc(PIndex);
    end else begin
      PByteArray(Buffer)^[Offset] := PIndex; Inc(Offset, PIndex + 1); PIndex := 0;
    end;

  end;

  // Update the part length into the packet
  PByteArray(Buffer)^[Offset] := PIndex; Inc(Offset, PIndex + 1);

  // Last character must be zero
  PByteArray(Buffer)^[Offset] := $00;

  Inc(Offset);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TResolver.GetHostNameAndQueryTypeFromRequestPacket(Buffer: Pointer; BufferLen: Integer; var HostName: String; var QueryType: Word);
var
  OffsetL1: Integer; OffsetLX: Integer;
begin
  OffsetL1 := $0C; OffsetLX := OffsetL1; HostName := GetStringFromPacket('', Buffer, OffsetL1, OffsetLX, 1, BufferLen); QueryType := GetWordFromPacket(Buffer, OffsetL1, BufferLen);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TResolver.BuildNegativeResponsePacketFromHostName(HostName: String; Buffer: Pointer; var BufferLen: Integer);
var
  Offset: Integer;
begin
  // Set the header
  PByteArray(Buffer)^[$00] := $00; // Query ID (LSB)
  PByteArray(Buffer)^[$01] := $00; // Query ID (LSB)
  PByteArray(Buffer)^[$02] := $85; // QRESP1=1, OPCODE4=0, AUTH1=1, TRUNC1=0, RECURSD1=1
  PByteArray(Buffer)^[$03] := $83; // RECURSA1=0, RESERV3=0, RESPCODE4=3
  PByteArray(Buffer)^[$04] := $00; // NQUESTIONS (MSB)
  PByteArray(Buffer)^[$05] := $01; // NQUESTIONS (LSB)
  PByteArray(Buffer)^[$06] := $00; // NANSWERSRR (MSB)
  PByteArray(Buffer)^[$07] := $00; // NANSWERSRR (LSB)
  PByteArray(Buffer)^[$08] := $00; // NAUTHORIRR (MSB)
  PByteArray(Buffer)^[$09] := $00; // NAUTHORIRR (LSB)
  PByteArray(Buffer)^[$0A] := $00; // NADDITIORR (MSB)
  PByteArray(Buffer)^[$0B] := $00; // NADDITIORR (LSB)

  // Initialize the offset
  Offset := $0C;

  // Set the question name
  SetStringIntoPacket(HostName, Buffer, Offset, BufferLen);

  // Set the question additional info
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset); // QUERYTYPE (MSB)
  PByteArray(Buffer)^[Offset] := $01; Inc(Offset); // QUERYTYPE (LSB)
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset); // QUERYCLASS (MSB)
  PByteArray(Buffer)^[Offset] := $01; Inc(Offset); // QUERYCLASS (LSB)

  // Set the packet length
  BufferLen := Offset;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TResolver.BuildPositiveResponsePacketFromHostNameAndAddress(HostName: String; HostAddress: Integer; Buffer: Pointer; var BufferLen: Integer);
var
  Offset: Integer;
begin
  // Set the header
  PByteArray(Buffer)^[$00] := $00; // Query ID (LSB)
  PByteArray(Buffer)^[$01] := $00; // Query ID (LSB)
  PByteArray(Buffer)^[$02] := $85; // QRESP1=1, OPCODE4=0, AUTH1=1, TRUNC1=0, RECURSD1=1
  PByteArray(Buffer)^[$03] := $80; // RECURSA1=1, RESERV3=0, RESCODE4=0
  PByteArray(Buffer)^[$04] := $00; // NQUESTIONS (MSB)
  PByteArray(Buffer)^[$05] := $01; // NQUESTIONS (LSB)
  PByteArray(Buffer)^[$06] := $00; // NANSWERSRR (MSB)
  PByteArray(Buffer)^[$07] := $01; // NANSWERSRR (LSB)
  PByteArray(Buffer)^[$08] := $00; // NAUTHORIRR (MSB)
  PByteArray(Buffer)^[$09] := $00; // NAUTHORIRR (LSB)
  PByteArray(Buffer)^[$0A] := $00; // NADDITIORR (MSB)
  PByteArray(Buffer)^[$0B] := $00; // NADDITIORR (LSB)

  // Initialize the offset
  Offset := $0C;

  // Set the question name
  SetStringIntoPacket(HostName, Buffer, Offset, BufferLen);

  // Set the question additional info
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset); // QUERYTYPE (MSB)
  PByteArray(Buffer)^[Offset] := $01; Inc(Offset); // QUERYTYPE (LSB)
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset); // QUERYCLASS (MSB)
  PByteArray(Buffer)^[Offset] := $01; Inc(Offset); // QUERYCLASS (LSB)

  // Set the answer reference informations
  PByteArray(Buffer)^[Offset] := $C0; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $0C; Inc(Offset);

  // Set the answer additional informations
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset); // QUERYTYPE (MSB)
  PByteArray(Buffer)^[Offset] := $01; Inc(Offset); // QUERYTYPE (LSB)
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset); // QUERYCLASS (MSB)
  PByteArray(Buffer)^[Offset] := $01; Inc(Offset); // QUERYCLASS (LSB)
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset); // TTL (MSB)
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset); // TTL
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset); // TTL
  PByteArray(Buffer)^[Offset] := $20; Inc(Offset); // TTL (LSB)

  // Set the answer length
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset); // MSB
  PByteArray(Buffer)^[Offset] := $04; Inc(Offset); // LSB

  // Set the answer contents
  Move(HostAddress, PByteArray(Buffer)^[Offset], 4); Inc(Offset, 4);

  // Set the packet length
  BufferLen := Offset;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TResolver.PrintGenericPacketBytesAsStringFromPacket(Buffer: Pointer; BufferLen: Integer): String;
var
  Index: Integer;
begin
  Result := 'Z='; for Index := 0 to BufferLen - 1 do Result := Result + IntToHex(PByteArray(Buffer)^[Index], 2);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TResolver.PrintGenericPacketBytesAsStringFromPacketWithOffset(Buffer: Pointer; BufferLen: Integer; Offset: Integer; NumBytes: Integer): String;
var
  Index: Integer;
begin
  SetLength(Result, 0); for Index := Offset to Min(BufferLen - 1, Offset + NumBytes - 1) do Result := Result + IntToHex(PByteArray(Buffer)^[Index], 2);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TResolver.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer: Pointer; BufferLen: Integer; IncludePacketBytesAlways: Boolean): String;
var
    HostName: String; QueryType: Word;
begin
  // Get the host name and query type from the request
  Self.GetHostNameAndQueryTypeFromRequestPacket(Buffer, BufferLen, HostName, QueryType);

  if (IncludePacketBytesAlways) then Result := 'Q=' + HostName + ';T=' + TQueryTypeUtils.ToString(QueryType) + ';' + Self.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) else Result := 'Q=' + HostName + ';T=' + TQueryTypeUtils.ToString(QueryType);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TResolver.PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer: Pointer; BufferLen: Integer; IncludePacketBytesAlways: Boolean): String;
var
  FValue: String; AValue: String; BValue: String; OffsetL1: Integer; OffsetLX: Integer; RCode: Byte; QdCnt: Word; AnCnt: Word; Index: Integer; AnTyp: Word; AnDta: Word;
begin
  RCode := PByteArray(Buffer)^[$03] and $0f;

  QdCnt := GetWordFromPacket(Buffer, $04, BufferLen);
  AnCnt := GetWordFromPacket(Buffer, $06, BufferLen);

  if (RCode = 0) and (QdCnt = 1) and (AnCnt > 0) then begin // We are only able to understand this

    // Initialize
    SetLength(FValue, 0);

    // Read the first question
    OffsetL1 := $0C; OffsetLX := OffsetL1; AValue := GetStringFromPacket('', Buffer, OffsetL1, OffsetLX, 1, BufferLen); Inc(OffsetL1, 4);

    // Update the packet description
    FValue := 'Q=' + AValue;

    for Index := 1 to AnCnt do begin

      if (OffsetL1 < BufferLen) then begin

        OffsetLX := OffsetL1; AValue := GetStringFromPacket('', Buffer, OffsetL1, OffsetLX, 1, BufferLen);

        if ((OffsetL1 + 10) <= BufferLen) then begin

          AnTyp := GetWordFromPacket(Buffer, OffsetL1, BufferLen); Inc(OffsetL1, 8);
          AnDta := GetWordFromPacket(Buffer, OffsetL1, BufferLen); Inc(OffsetL1, 2);

          if (AnDta > 0) and ((OffsetL1 + AnDta) <= BufferLen) then begin

            FValue := FValue + ';T[' + IntToStr(Index) + ']=' + TQueryTypeUtils.ToString(AnTyp);

            case AnTyp of

              QueryTypeUtils.QUERY_TYPE_A:

                if (AnDta = 4) then begin

                  // Read the answer contents
                  BValue := TIPAddress.ToString(GetIntegerFromPacket(Buffer, OffsetL1, BufferLen));

                  // Update the packet description
                  FValue := FValue + ';A[' + IntToStr(Index) + ']=' + AValue + '>' + BValue;

                end else begin

                  FValue := FValue + ';A[' + IntToStr(Index) + ']=' + AValue + '>' + Self.PrintGenericPacketBytesAsStringFromPacketWithOffset(Buffer, BufferLen, OffsetL1, AnDta);

                end;

              else

                FValue := FValue + ';A[' + IntToStr(Index) + ']=' + AValue + '>' + Self.PrintGenericPacketBytesAsStringFromPacketWithOffset(Buffer, BufferLen, OffsetL1, AnDta);

            end; Inc(OffsetL1, AnDta);

          end else begin
            Break;
          end;

        end else begin
          Break;
        end;

      end else begin
        Break;
      end;

    end;

    if (IncludePacketBytesAlways) then Result := FValue + ';' + Self.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) else Result := FValue;

  end else begin
    Result := Self.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen);
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TResolver.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer: Pointer; BufferLen: Integer; IncludePacketBytesAlways: Boolean): String;
var
    HostName: String; QueryType: Word;
begin
  // Get the host name and query type from the request
  Self.GetHostNameAndQueryTypeFromRequestPacket(Buffer, BufferLen, HostName, QueryType);

  Result := HostName;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TResolver.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Buffer: Pointer; BufferLen: Integer; IncludePacketBytesAlways: Boolean): String;
var
  FValue: String; AValue: String; BValue: String; OffsetL1: Integer; OffsetLX: Integer; RCode: Byte; QdCnt: Word; AnCnt: Word; Index: Integer; AnTyp: Word; AnDta: Word;
begin
  RCode := PByteArray(Buffer)^[$03] and $0f;

  QdCnt := GetWordFromPacket(Buffer, $04, BufferLen);
  AnCnt := GetWordFromPacket(Buffer, $06, BufferLen);

  if (RCode = 0) and (QdCnt = 1) and (AnCnt > 0) then begin // We are only able to understand this

    // Initialize
    SetLength(FValue, 0);

    // Read the first question
    OffsetL1 := $0C; OffsetLX := OffsetL1; AValue := GetStringFromPacket('', Buffer, OffsetL1, OffsetLX, 1, BufferLen); Inc(OffsetL1, 4);

    // Update the packet description
    FValue := 'Q=' + AValue;

    for Index := 1 to AnCnt do begin

      if (OffsetL1 < BufferLen) then begin

        OffsetLX := OffsetL1; AValue := GetStringFromPacket('', Buffer, OffsetL1, OffsetLX, 1, BufferLen);

        if ((OffsetL1 + 10) <= BufferLen) then begin

          AnTyp := GetWordFromPacket(Buffer, OffsetL1, BufferLen); Inc(OffsetL1, 8);
          AnDta := GetWordFromPacket(Buffer, OffsetL1, BufferLen); Inc(OffsetL1, 2);

          if (AnDta > 0) and ((OffsetL1 + AnDta) <= BufferLen) then begin

            case AnTyp of

              QueryTypeUtils.QUERY_TYPE_A:

                if (AnDta = 4) then begin

                  // Read the answer contents
                  BValue := TIPAddress.ToString(GetIntegerFromPacket(Buffer, OffsetL1, BufferLen));

                  // Update the packet description
                  FValue := FValue + ';A=' + AValue + '>' + BValue;

                end else begin

                  FValue := FValue + ';A=' + AValue + '>' + Self.PrintGenericPacketBytesAsStringFromPacketWithOffset(Buffer, BufferLen, OffsetL1, AnDta);

                end;

              else

                FValue := FValue + ';A=' + AValue + '>' + Self.PrintGenericPacketBytesAsStringFromPacketWithOffset(Buffer, BufferLen, OffsetL1, AnDta);

            end; Inc(OffsetL1, AnDta);

          end else begin
            Break;
          end;

        end else begin
          Break;
        end;

      end else begin
        Break;
      end;

    end;

    Result := FValue;

  end else begin
    Result := Self.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen);
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TResolver.IsFailureResponsePacket(Buffer: Pointer; BufferLen: Integer): Boolean;
var
  RCode: Byte;
begin
  RCode := PByteArray(Buffer)^[$03] and $0f; Result := not((RCode = 0) or (RCode = 3));
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TResolver.IsNegativeResponsePacket(Buffer: Pointer; BufferLen: Integer): Boolean;
var
  RCode: Byte;
begin
  RCode := PByteArray(Buffer)^[$03] and $0f; Result := (RCode = 3);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TResolver.Execute;
var
  ClientServerSocket: TClientServerSocket;
  Arrival: TDateTime; ArrivalExt: Double; Address: Integer; AltAddress: Integer; Port: Word; AltPort: Word; SessionId: Word; RequestHash: Int64; SilentUpdate: Boolean; CacheException: Boolean; HostName: String; QueryType: Word; DnsIndex: Integer; Forwarded: Boolean;
begin
  TClientServerSocket.Initialize();

  try
    ClientServerSocket := nil; try

      // Bind the socket to the specified address and port
      ClientServerSocket := TClientServerSocket.Create(TConfiguration.GetLocalBindingAddress(), TConfiguration.GetLocalBindingPort());

      repeat // Working cycle

        // If there is a packet available
        if ClientServerSocket.ReceiveFrom(RESOLVER_THREAD_MAX_BLOCK_TIME, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen, Address, Port) then begin

          // If the packet is not too small or large
          if (Self.BufferLen >= MIN_DNS_PACKET_LEN) and (Self.BufferLen <= MAX_DNS_PACKET_LEN) then begin

            // Low res
            Arrival := Now;

            // Mark the packet arrival time
            ArrivalExt := TPerformance.GetInstantValue();

            // If it's a response coming from one of the DNS servers
            if ((Address = TConfiguration.GetServerConfiguration(0).Address) and (Port = TConfiguration.GetServerConfiguration(0).Port)) or
               ((Address = TConfiguration.GetServerConfiguration(1).Address) and (Port = TConfiguration.GetServerConfiguration(1).Port)) or
               ((Address = TConfiguration.GetServerConfiguration(2).Address) and (Port = TConfiguration.GetServerConfiguration(2).Port)) or
               ((Address = TConfiguration.GetServerConfiguration(3).Address) and (Port = TConfiguration.GetServerConfiguration(3).Port)) or
               ((Address = TConfiguration.GetServerConfiguration(4).Address) and (Port = TConfiguration.GetServerConfiguration(4).Port)) or
               ((Address = TConfiguration.GetServerConfiguration(5).Address) and (Port = TConfiguration.GetServerConfiguration(5).Port)) or
               ((Address = TConfiguration.GetServerConfiguration(6).Address) and (Port = TConfiguration.GetServerConfiguration(6).Port)) or
               ((Address = TConfiguration.GetServerConfiguration(7).Address) and (Port = TConfiguration.GetServerConfiguration(7).Port)) or
               ((Address = TConfiguration.GetServerConfiguration(8).Address) and (Port = TConfiguration.GetServerConfiguration(8).Port)) or
               ((Address = TConfiguration.GetServerConfiguration(9).Address) and (Port = TConfiguration.GetServerConfiguration(9).Port)) then begin

              // Get the id field from the packet
              SessionId := Self.GetIdFromPacket(Self.Buffer);

              // Trace the event if a tracer is enabled
              if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' received from server ' + TIPAddress.ToString(Address) + ':' + IntToStr(Port) + ' [' + Self.PrintResponsePacketDescriptionAsNormalStringFromPacket(Self.Buffer, Self.BufferLen, True) + '].');

              if not(Self.IsFailureResponsePacket(Self.Buffer, Self.BufferLen)) then begin // If the response is not a failure

                // If the item exists in the session cache
                if TSessionCache.Extract(SessionId, RequestHash, AltAddress, AltPort, SilentUpdate, CacheException) then begin

                  if CacheException then begin // If it's a response to a cache exception request

                    if not(Self.IsNegativeResponsePacket(Self.Buffer, Self.BufferLen)) then begin // If the response is not negative

                      // Clear the item
                      TSessionCache.Delete(SessionId);

                      // Forward the packet to the client
                      ClientServerSocket.SendTo(Self.Buffer, Self.BufferLen, AltAddress, AltPort);

                      // Trace the event if a tracer is enabled
                      if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TIPAddress.ToString(AltAddress) + ':' + IntToStr(AltPort) + ' as positive.');

                      // Trace the event into the hit log if enabled
                      if THitLogger.IsEnabled() and (Pos('R', TConfiguration.GetHitLogFileWhat()) > 0) then begin if (TConfiguration.GetHitLogFileMode() = 'Legacy') then THitLogger.AddHit(Arrival, 'R', Address, Self.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Self.Buffer, Self.BufferLen, False)) else THitLogger.AddHit(Arrival, 'R', Address, Self.PrintResponsePacketDescriptionAsNormalStringFromPacket(Self.Buffer, Self.BufferLen, False)); end;

                    end else begin // The response is negative!

                      if ((Address = TConfiguration.GetServerConfiguration(0).Address) and not(TConfiguration.GetServerConfiguration(0).IgnoreNegativeResponsesFromServer)) or
                         ((Address = TConfiguration.GetServerConfiguration(1).Address) and not(TConfiguration.GetServerConfiguration(1).IgnoreNegativeResponsesFromServer)) or
                         ((Address = TConfiguration.GetServerConfiguration(2).Address) and not(TConfiguration.GetServerConfiguration(2).IgnoreNegativeResponsesFromServer)) or
                         ((Address = TConfiguration.GetServerConfiguration(3).Address) and not(TConfiguration.GetServerConfiguration(3).IgnoreNegativeResponsesFromServer)) or
                         ((Address = TConfiguration.GetServerConfiguration(4).Address) and not(TConfiguration.GetServerConfiguration(4).IgnoreNegativeResponsesFromServer)) or
                         ((Address = TConfiguration.GetServerConfiguration(5).Address) and not(TConfiguration.GetServerConfiguration(5).IgnoreNegativeResponsesFromServer)) or
                         ((Address = TConfiguration.GetServerConfiguration(6).Address) and not(TConfiguration.GetServerConfiguration(6).IgnoreNegativeResponsesFromServer)) or
                         ((Address = TConfiguration.GetServerConfiguration(7).Address) and not(TConfiguration.GetServerConfiguration(7).IgnoreNegativeResponsesFromServer)) or
                         ((Address = TConfiguration.GetServerConfiguration(8).Address) and not(TConfiguration.GetServerConfiguration(8).IgnoreNegativeResponsesFromServer)) or
                         ((Address = TConfiguration.GetServerConfiguration(9).Address) and not(TConfiguration.GetServerConfiguration(9).IgnoreNegativeResponsesFromServer)) then begin

                        // Clear the item
                        TSessionCache.Delete(SessionId);

                        // Forward the packet to the client
                        ClientServerSocket.SendTo(Self.Buffer, Self.BufferLen, AltAddress, AltPort);

                        // Trace the event if a tracer is enabled
                        if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TIPAddress.ToString(AltAddress) + ':' + IntToStr(AltPort) + ' as negative.');

                        // Trace the event into the hit log if enabled
                        if THitLogger.IsEnabled() and (Pos('R', TConfiguration.GetHitLogFileWhat()) > 0) then begin if (TConfiguration.GetHitLogFileMode() = 'Legacy') then THitLogger.AddHit(Arrival, 'R', Address, Self.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Self.Buffer, Self.BufferLen, False)) else THitLogger.AddHit(Arrival, 'R', Address, Self.PrintResponsePacketDescriptionAsNormalStringFromPacket(Self.Buffer, Self.BufferLen, False)); end;

                      end else begin

                        // Trace the event if a tracer is enabled
                        if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' discarded as negative.');

                      end;

                    end;

                  end else if SilentUpdate then begin // If it's a response to a silent update request

                    if not(Self.IsNegativeResponsePacket(Self.Buffer, Self.BufferLen)) then begin // If the response is not negative

                      // Clear the item
                      TSessionCache.Delete(SessionId);

                      if not TConfiguration.GetAddressCacheDisabled() then begin

                        // Put the item into the address cache
                        Self.SetIdIntoPacket(0, Self.Buffer); TAddressCache.Add(Arrival, RequestHash, Self.Buffer, Self.BufferLen, False);

                        // Trace the event if a tracer is enabled
                        if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' put into the address cache as positive silent update.');

                      end;

                      // Trace the event into the hit log if enabled
                      if THitLogger.IsEnabled() and (Pos('U', TConfiguration.GetHitLogFileWhat()) > 0) then begin if (TConfiguration.GetHitLogFileMode() = 'Legacy') then THitLogger.AddHit(Arrival, 'U', Address, Self.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Self.Buffer, Self.BufferLen, False)) else THitLogger.AddHit(Arrival, 'U', Address, Self.PrintResponsePacketDescriptionAsNormalStringFromPacket(Self.Buffer, Self.BufferLen, False)); end;

                    end else begin // The response is negative!

                      // Trace the event if a tracer is enabled
                      if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + ' discarded as negative silent update.');

                    end;

                  end else begin // It's a response to a standard request!

                    if not(IsNegativeResponsePacket(Self.Buffer, Self.BufferLen)) then begin // If the response is not negative

                      // Clear the item
                      TSessionCache.Delete(SessionId);

                      // Forward the packet to the client
                      ClientServerSocket.SendTo(Self.Buffer, Self.BufferLen, AltAddress, AltPort);

                      if not TConfiguration.GetAddressCacheDisabled() then begin

                        // Put the item into the address cache
                        Self.SetIdIntoPacket(0, Self.Buffer); TAddressCache.Add(Arrival, RequestHash, Self.Buffer, Self.BufferLen, False);

                        // Trace the event if a tracer is enabled
                        if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TIPAddress.ToString(AltAddress) + ':' + IntToStr(AltPort) + ' and put into the address cache as positive.');

                      end else begin

                        // Trace the event if a tracer is enabled
                        if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TIPAddress.ToString(AltAddress) + ':' + IntToStr(AltPort) + ' as positive.');

                      end;

                      // Trace the event into the hit log if enabled
                      if THitLogger.IsEnabled() and (Pos('R', TConfiguration.GetHitLogFileWhat()) > 0) then begin if (TConfiguration.GetHitLogFileMode() = 'Legacy') then THitLogger.AddHit(Arrival, 'R', Address, Self.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Self.Buffer, Self.BufferLen, False)) else THitLogger.AddHit(Arrival, 'R', Address, Self.PrintResponsePacketDescriptionAsNormalStringFromPacket(Self.Buffer, Self.BufferLen, False)); end;

                    end else begin // The response is negative!

                      if ((Address = TConfiguration.GetServerConfiguration(0).Address) and not(TConfiguration.GetServerConfiguration(0).IgnoreNegativeResponsesFromServer)) or
                         ((Address = TConfiguration.GetServerConfiguration(1).Address) and not(TConfiguration.GetServerConfiguration(1).IgnoreNegativeResponsesFromServer)) or
                         ((Address = TConfiguration.GetServerConfiguration(2).Address) and not(TConfiguration.GetServerConfiguration(2).IgnoreNegativeResponsesFromServer)) or
                         ((Address = TConfiguration.GetServerConfiguration(3).Address) and not(TConfiguration.GetServerConfiguration(3).IgnoreNegativeResponsesFromServer)) or
                         ((Address = TConfiguration.GetServerConfiguration(4).Address) and not(TConfiguration.GetServerConfiguration(4).IgnoreNegativeResponsesFromServer)) or
                         ((Address = TConfiguration.GetServerConfiguration(5).Address) and not(TConfiguration.GetServerConfiguration(5).IgnoreNegativeResponsesFromServer)) or
                         ((Address = TConfiguration.GetServerConfiguration(6).Address) and not(TConfiguration.GetServerConfiguration(6).IgnoreNegativeResponsesFromServer)) or
                         ((Address = TConfiguration.GetServerConfiguration(7).Address) and not(TConfiguration.GetServerConfiguration(7).IgnoreNegativeResponsesFromServer)) or
                         ((Address = TConfiguration.GetServerConfiguration(8).Address) and not(TConfiguration.GetServerConfiguration(8).IgnoreNegativeResponsesFromServer)) or
                         ((Address = TConfiguration.GetServerConfiguration(9).Address) and not(TConfiguration.GetServerConfiguration(9).IgnoreNegativeResponsesFromServer)) then begin

                        // Clear the item
                        TSessionCache.Delete(SessionId);

                        // Forward the packet to the client
                        ClientServerSocket.SendTo(Self.Buffer, Self.BufferLen, AltAddress, AltPort);

                        if not TConfiguration.GetAddressCacheDisabled() then begin

                          // Put the item into the address cache
                          Self.SetIdIntoPacket(0, Self.Buffer); TAddressCache.Add(Arrival, RequestHash, Self.Buffer, Self.BufferLen, True);

                          // Trace the event if a tracer is enabled
                          if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TIPAddress.ToString(AltAddress) + ':' + IntToStr(AltPort) + ' and put into the address cache as negative.');

                        end else begin

                          // Trace the event if a tracer is enabled
                          if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TIPAddress.ToString(AltAddress) + ':' + IntToStr(AltPort) + ' as negative.');

                        end;

                        // Trace the event into the hit log if enabled
                        if THitLogger.IsEnabled() and (Pos('R', TConfiguration.GetHitLogFileWhat()) > 0) then begin if (TConfiguration.GetHitLogFileMode() = 'Legacy') then THitLogger.AddHit(Arrival, 'R', Address, Self.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Self.Buffer, Self.BufferLen, False)) else THitLogger.AddHit(Arrival, 'R', Address, Self.PrintResponsePacketDescriptionAsNormalStringFromPacket(Self.Buffer, Self.BufferLen, False)); end;

                      end else begin

                        // Trace the event if a tracer is enabled
                        if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' discarded as negative.');

                      end;

                    end;

                  end;

                end else begin // The item has not been found in the session cache!

                  // Trace the event if a tracer is enabled
                  if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' discarded because no session cache entry matched.');

                end;

              end else begin // The response is a failure

                // Trace the event if a tracer is enabled
                if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' discarded as failure.');

              end;

              // Update performance stats if enabled
              if TStatistics.IsEnabled() then begin if (Address = TConfiguration.GetServerConfiguration(0).Address) then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalExt, True, 0, SessionId)
                                               else if (Address = TConfiguration.GetServerConfiguration(1).Address) then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalExt, True, 1, SessionId)
                                               else if (Address = TConfiguration.GetServerConfiguration(2).Address) then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalExt, True, 2, SessionId)
                                               else if (Address = TConfiguration.GetServerConfiguration(3).Address) then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalExt, True, 3, SessionId)
                                               else if (Address = TConfiguration.GetServerConfiguration(4).Address) then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalExt, True, 4, SessionId)
                                               else if (Address = TConfiguration.GetServerConfiguration(5).Address) then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalExt, True, 5, SessionId)
                                               else if (Address = TConfiguration.GetServerConfiguration(6).Address) then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalExt, True, 6, SessionId)
                                               else if (Address = TConfiguration.GetServerConfiguration(7).Address) then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalExt, True, 7, SessionId)
                                               else if (Address = TConfiguration.GetServerConfiguration(8).Address) then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalExt, True, 8, SessionId)
                                               else if (Address = TConfiguration.GetServerConfiguration(9).Address) then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalExt, True, 9, SessionId);
                                              end;

            // If it's a request coming from one of the DNS clients
            end else if (Address = LOCALHOST_ADDRESS) or TConfiguration.IsAllowedAddress(TIPAddress.ToString(Address)) then begin

              // Get the id field from the packet
              SessionId := Self.GetIdFromPacket(Self.Buffer);

              // Get the host name and query type from the request
              Self.GetHostNameAndQueryTypeFromRequestPacket(Buffer, BufferLen, HostName, QueryType);

              // Trace the event if a tracer is enabled
              if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Request  ID ' + FormatCurr('00000', SessionId) + ' received from client ' + TIPAddress.ToString(Address) + ':' + IntToStr(Port) + ' [' + Self.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer, BufferLen, True) + '].');

              if TConfiguration.IsBlackException(HostName) then begin // If a black exception

                // Build a standard response
                Self.BuildPositiveResponsePacketFromHostNameAndAddress(HostName, LOCALHOST_ADDRESS, Self.Output, Self.OutputLen);

                // Send the response to the client
                Self.SetIdIntoPacket(SessionId, Self.Output); ClientServerSocket.SendTo(Self.Output, Self.OutputLen, Address, Port);

                // Trace the event if a tracer is enabled
                if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TIPAddress.ToString(Address) + ':' + IntToStr(Port) + ' as black exception.');

                // Trace the event into the hit log if enabled
                if THitLogger.IsEnabled() and (Pos('B', TConfiguration.GetHitLogFileWhat()) > 0) then begin if (TConfiguration.GetHitLogFileMode() = 'Legacy') then THitLogger.AddHit(Arrival, 'B', Address, Self.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Self.Buffer, Self.BufferLen, False)) else THitLogger.AddHit(Arrival, 'B', Address, Self.PrintRequestPacketDescriptionAsNormalStringFromPacket(Self.Buffer, Self.BufferLen, False)); end;

                // Update performance stats if enabled
                if TStatistics.IsEnabled() then TStatistics.IncTotalRequestsResolvedThroughOtherWays();

              end else if THostsCache.Find(HostName, AltAddress) and ((QueryType = QueryTypeUtils.QUERY_TYPE_A) or (QueryType = QueryTypeUtils.QUERY_TYPE_AAAA)) then begin // If the host name exists in the hosts cache and the query type is A (IPv4) or AAAA (IPv6)

                // Build a standard response
                Self.BuildPositiveResponsePacketFromHostNameAndAddress(HostName, AltAddress, Self.Output, Self.OutputLen);

                // Send the response to the client
                Self.SetIdIntoPacket(SessionId, Self.Output); ClientServerSocket.SendTo(Self.Output, Self.OutputLen, Address, Port);

                // Trace the event if a tracer is enabled
                if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TIPAddress.ToString(Address) + ':' + IntToStr(Port) + ' directly from hosts cache.');

                // Trace the event into the hit log if enabled
                if THitLogger.IsEnabled() and (Pos('H', TConfiguration.GetHitLogFileWhat()) > 0) then begin if (TConfiguration.GetHitLogFileMode() = 'Legacy') then THitLogger.AddHit(Arrival, 'H', Address, Self.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Self.Buffer, Self.BufferLen, False)) else THitLogger.AddHit(Arrival, 'H', Address, Self.PrintRequestPacketDescriptionAsNormalStringFromPacket(Self.Buffer, Self.BufferLen, False)); end;

                // Update performance stats if enabled
                if TStatistics.IsEnabled() then TStatistics.IncTotalRequestsResolvedThroughHostsFile();

              end else if TConfiguration.IsCacheException(HostName) then begin // If the host name is configured as a cache exception

                // We need to know if the request has been forwarded to at least one DNS server or not
                Forwarded := False;

                for DnsIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin // For every DNS server
                  if (TConfiguration.GetServerConfiguration(DnsIndex).Address <> -1) then begin // If it has been configured
                    if TConfiguration.IsHostNameAffinityMatch(HostName, TConfiguration.GetServerConfiguration(DnsIndex).HostNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, TConfiguration.GetServerConfiguration(DnsIndex).QueryTypeAffinityMask) then begin

                      Forwarded := True;

                      // Forward the request to the server
                      ClientServerSocket.SendTo(Self.Buffer, Self.BufferLen, TConfiguration.GetServerConfiguration(DnsIndex).Address, TConfiguration.GetServerConfiguration(DnsIndex).Port);

                      // Update performance stats if enabled
                      if TStatistics.IsEnabled() then TStatistics.IncTotalResponsesAndMeasureFlyTime(TPerformance.GetInstantValue(), False, DnsIndex, SessionId);

                      // Trace the event if a tracer is enabled
                      if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Request  ID ' + FormatCurr('00000', SessionId) + ' forwarded to server ' + TIPAddress.ToString(TConfiguration.GetServerConfiguration(DnsIndex).Address) + ':' + IntToStr(TConfiguration.GetServerConfiguration(DnsIndex).Port) + ' as cache exception.');

                    end;
                  end else begin
                    Break;
                  end;
                end;

                if Forwarded then begin

                  // Insert the item into the session cache
                  Self.SetIdIntoPacket(0, Self.Buffer); TSessionCache.Insert(SessionId, RequestHash, Address, Port, False, True);

                  // Trace the event into the hit log if enabled
                  if THitLogger.IsEnabled() and (Pos('F', TConfiguration.GetHitLogFileWhat()) > 0) then begin if (TConfiguration.GetHitLogFileMode() = 'Legacy') then THitLogger.AddHit(Arrival, 'F', Address, Self.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Self.Buffer, Self.BufferLen, False)) else THitLogger.AddHit(Arrival, 'F', Address, Self.PrintRequestPacketDescriptionAsNormalStringFromPacket(Self.Buffer, Self.BufferLen, False)); end;

                  // Update performance stats if enabled
                  if TStatistics.IsEnabled() then TStatistics.IncTotalRequestsForwarded();

                end else begin

                  // Build a negative response
                  Self.BuildNegativeResponsePacketFromHostName(HostName, Self.Output, Self.OutputLen);

                  // Send the response to the client
                  Self.SetIdIntoPacket(SessionId, Self.Output); ClientServerSocket.SendTo(Self.Output, Self.OutputLen, Address, Port);

                  // Trace the event if a tracer is enabled
                  if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TIPAddress.ToString(Address) + ':' + IntToStr(Port) + ' directly as negative.');

                end;

              end else begin // The host name is neither in the hosts cache nor within the cache exceptions

                if not TConfiguration.GetAddressCacheDisabled() then begin

                  // Gonna check by hash if the request exists in the address cache
                  Self.SetIdIntoPacket(0, Self.Buffer); RequestHash := TDigest.ComputeCRC64(Self.Buffer, Self.BufferLen); Self.SetIdIntoPacket(SessionId, Self.Buffer);

                  case TAddressCache.Find(Arrival, RequestHash, Self.Output, Self.OutputLen) of

                    RecentEnough: begin // The address cache item is recent

                      // Send the response to the client
                      Self.SetIdIntoPacket(SessionId, Self.Output); ClientServerSocket.SendTo(Self.Output, Self.OutputLen, Address, Port);

                      // Trace the event if a tracer is enabled
                      if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TIPAddress.ToString(Address) + ':' + IntToStr(Port) + ' directly from address cache [' + Self.PrintResponsePacketDescriptionAsNormalStringFromPacket(Self.Output, Self.OutputLen, True) + '].');

                      // Trace the event into the hit log if enabled
                      if THitLogger.IsEnabled() and (Pos('C', TConfiguration.GetHitLogFileWhat()) > 0) then begin if (TConfiguration.GetHitLogFileMode() = 'Legacy') then THitLogger.AddHit(Arrival, 'C', Address, Self.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Self.Buffer, Self.BufferLen, False)) else THitLogger.AddHit(Arrival, 'C', Address, Self.PrintRequestPacketDescriptionAsNormalStringFromPacket(Self.Buffer, Self.BufferLen, False)); end;

                      // Update performance stats if enabled
                      if TStatistics.IsEnabled() then TStatistics.IncTotalRequestsResolvedThroughCache();

                    end;

                    NeedsUpdate: begin // The address cache item needs a silent update

                      // Send the response to the client
                      Self.SetIdIntoPacket(SessionId, Self.Output); ClientServerSocket.SendTo(Self.Output, Self.OutputLen, Address, Port);

                      // Trace the event if a tracer is enabled
                      if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TIPAddress.ToString(Address) + ':' + IntToStr(Port) + ' directly from address cache [' + Self.PrintResponsePacketDescriptionAsNormalStringFromPacket(Self.Output, Self.OutputLen, True) + '].');

                      // We need to know if the request has been forwarded to at least one DNS server or not
                      Forwarded := False;

                      for DnsIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin // For every DNS server
                        if (TConfiguration.GetServerConfiguration(DnsIndex).Address <> -1) then begin // If it has been configured
                          if TConfiguration.IsHostNameAffinityMatch(HostName, TConfiguration.GetServerConfiguration(DnsIndex).HostNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, TConfiguration.GetServerConfiguration(DnsIndex).QueryTypeAffinityMask) then begin

                            Forwarded := True;

                            // Forward the request to the server
                            ClientServerSocket.SendTo(Self.Buffer, Self.BufferLen, TConfiguration.GetServerConfiguration(DnsIndex).Address, TConfiguration.GetServerConfiguration(DnsIndex).Port);

                            // Update performance stats if enabled
                            if TStatistics.IsEnabled() then TStatistics.IncTotalResponsesAndMeasureFlyTime(TPerformance.GetInstantValue(), False, DnsIndex, SessionId);

                            // Trace the event if a tracer is enabled
                            if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Request  ID ' + FormatCurr('00000', SessionId) + ' forwarded to server ' + TIPAddress.ToString(TConfiguration.GetServerConfiguration(DnsIndex).Address) + ':' + IntToStr(TConfiguration.GetServerConfiguration(DnsIndex).Port) + ' as silent update.');

                          end;
                        end else begin
                          Break;
                        end;
                      end;

                      if Forwarded then begin

                        // Put the item into the session cache
                        Self.SetIdIntoPacket(0, Self.Buffer); TSessionCache.Insert(SessionId, RequestHash, Address, Port, True, False);

                        // Trace the event into the hit log if enabled
                        if THitLogger.IsEnabled() and (Pos('C', TConfiguration.GetHitLogFileWhat()) > 0) then begin if (TConfiguration.GetHitLogFileMode() = 'Legacy') then THitLogger.AddHit(Arrival, 'C', Address, Self.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Self.Buffer, Self.BufferLen, False)) else THitLogger.AddHit(Arrival, 'C', Address, Self.PrintRequestPacketDescriptionAsNormalStringFromPacket(Self.Buffer, Self.BufferLen, False)); end;

                        // Update performance stats if enabled
                        if TStatistics.IsEnabled() then TStatistics.IncTotalRequestsResolvedThroughCache();

                      end;

                    end;

                    NotFound: begin // The item is not in the address cache

                      // We need to know if the request has been forwarded to at least one DNS server or not
                      Forwarded := False;

                      for DnsIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin // For every DNS server
                        if (TConfiguration.GetServerConfiguration(DnsIndex).Address <> -1) then begin // If it's been configured
                          if TConfiguration.IsHostNameAffinityMatch(HostName, TConfiguration.GetServerConfiguration(DnsIndex).HostNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, TConfiguration.GetServerConfiguration(DnsIndex).QueryTypeAffinityMask) then begin

                            Forwarded := True;

                            // Forward the request to the server
                            ClientServerSocket.SendTo(Self.Buffer, Self.BufferLen, TConfiguration.GetServerConfiguration(DnsIndex).Address, TConfiguration.GetServerConfiguration(DnsIndex).Port);

                            // Update performance stats if enabled
                            if TStatistics.IsEnabled() then TStatistics.IncTotalResponsesAndMeasureFlyTime(TPerformance.GetInstantValue(), False, DnsIndex, SessionId);

                            // Trace the event if a tracer is enabled
                            if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Request  ID ' + FormatCurr('00000', SessionId) + ' forwarded to server ' + TIPAddress.ToString(TConfiguration.GetServerConfiguration(DnsIndex).Address) + ':' + IntToStr(TConfiguration.GetServerConfiguration(DnsIndex).Port) + '.');

                          end;
                        end else begin
                          Break;
                        end;
                      end;

                      if Forwarded then begin

                        // Insert the item into the session cache
                        Self.SetIdIntoPacket(0, Self.Buffer); TSessionCache.Insert(SessionId, RequestHash, Address, Port, False, False);

                        // Trace the event into the hit log if enabled
                        if THitLogger.IsEnabled() and (Pos('F', TConfiguration.GetHitLogFileWhat()) > 0) then begin if (TConfiguration.GetHitLogFileMode() = 'Legacy') then THitLogger.AddHit(Arrival, 'F', Address, Self.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Self.Buffer, Self.BufferLen, False)) else THitLogger.AddHit(Arrival, 'F', Address, Self.PrintRequestPacketDescriptionAsNormalStringFromPacket(Self.Buffer, Self.BufferLen, False)); end;

                        // Update performance stats if enabled
                        if TStatistics.IsEnabled() then TStatistics.IncTotalRequestsForwarded();

                      end else begin

                        // Build a negative response
                        Self.BuildNegativeResponsePacketFromHostName(HostName, Self.Output, Self.OutputLen);

                        // Send the response to the client
                        Self.SetIdIntoPacket(SessionId, Self.Output); ClientServerSocket.SendTo(Self.Output, Self.OutputLen, Address, Port);

                        // Trace the event if a tracer is enabled
                        if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TIPAddress.ToString(Address) + ':' + IntToStr(Port) + ' directly as negative.');

                      end;

                    end;

                  end;

                end else begin // The address cache has been disabled

                  // We need to know if the request has been forwarded to at least one DNS server or not
                  Forwarded := False;

                  for DnsIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin // For every DNS server
                    if (TConfiguration.GetServerConfiguration(DnsIndex).Address <> -1) then begin // If it's been configured
                      if TConfiguration.IsHostNameAffinityMatch(HostName, TConfiguration.GetServerConfiguration(DnsIndex).HostNameAffinityMask) and TConfiguration.IsQueryTypeAffinityMatch(QueryType, TConfiguration.GetServerConfiguration(DnsIndex).QueryTypeAffinityMask) then begin

                        Forwarded := True;

                        // Forward the request to the server
                        ClientServerSocket.SendTo(Self.Buffer, Self.BufferLen, TConfiguration.GetServerConfiguration(DnsIndex).Address, TConfiguration.GetServerConfiguration(DnsIndex).Port);

                        // Update performance stats if enabled
                        if TStatistics.IsEnabled() then TStatistics.IncTotalResponsesAndMeasureFlyTime(TPerformance.GetInstantValue(), False, DnsIndex, SessionId);

                        // Trace the event if a tracer is enabled
                        if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Request  ID ' + FormatCurr('00000', SessionId) + ' forwarded to server ' + TIPAddress.ToString(TConfiguration.GetServerConfiguration(DnsIndex).Address) + ':' + IntToStr(TConfiguration.GetServerConfiguration(DnsIndex).Port) + '.');

                      end;
                    end else begin
                      Break;
                    end;
                  end;

                  if Forwarded then begin

                    // Insert the item into the session cache
                    Self.SetIdIntoPacket(0, Self.Buffer); TSessionCache.Insert(SessionId, RequestHash, Address, Port, False, False);

                    // Trace the event into the hit log if enabled
                    if THitLogger.IsEnabled() and (Pos('F', TConfiguration.GetHitLogFileWhat()) > 0) then begin if (TConfiguration.GetHitLogFileMode = 'Legacy') then THitLogger.AddHit(Arrival, 'F', Address, Self.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Self.Buffer, Self.BufferLen, False)) else THitLogger.AddHit(Arrival, 'F', Address, Self.PrintRequestPacketDescriptionAsNormalStringFromPacket(Self.Buffer, Self.BufferLen, False)); end;

                    // Update performance stats if enabled
                    if TStatistics.IsEnabled() then TStatistics.IncTotalRequestsForwarded();

                  end else begin

                    // Build a negative response
                    Self.BuildNegativeResponsePacketFromHostName(HostName, Self.Output, Self.OutputLen);

                    // Send the response to the client
                    Self.SetIdIntoPacket(SessionId, Self.Output); ClientServerSocket.SendTo(Self.Output, Self.OutputLen, Address, Port);

                    // Trace the event if a tracer is enabled
                    if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TIPAddress.ToString(Address) + ':' + IntToStr(Port) + ' directly as negative.');

                  end;

                end;

              end;

              // Update performance stats if enabled
              if TStatistics.IsEnabled() then TStatistics.IncTotalRequestsReceived();

            end else begin // It's a spurious packet coming from the infinite

              // Trace the event if a tracer is enabled
              if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Unexpected packet received from address ' + TIPAddress.ToString(Address) + ':' + IntToStr(Port) + ' [' + Self.PrintGenericPacketBytesAsStringFromPacket(Self.Buffer, Self.BufferLen) + '].');

              // Update performance stats if enabled
              if TStatistics.IsEnabled() then TStatistics.IncTotalPacketsDiscarded();

            end;

          end else begin // It's a spurious packet coming from the infinite

            // Trace the event if a tracer is enabled
            if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Malformed packet received from address ' + TIPAddress.ToString(Address) + ':' + IntToStr(Port) + ' [' + Self.PrintGenericPacketBytesAsStringFromPacket(Self.Buffer, Self.BufferLen) + '].');

            // Update performance stats if enabled
            if TStatistics.IsEnabled() then TStatistics.IncTotalPacketsDiscarded();

          end;

        end else begin // Good place for low priority operations here

          // If enabled flush the hit log and the stats log of any pending data
          if THitLogger.IsEnabled() then THitLogger.FlushPendingHitsToDisk(); if TStatistics.IsEnabled() then TStatistics.FlushStatisticsToDisk();

        end;

      until Terminated;

      // If enabled flush the hit log and the stats log of any pending data
      if THitLogger.IsEnabled() then THitLogger.FlushPendingHitsToDisk(); if TStatistics.IsEnabled() then TStatistics.FlushStatisticsToDisk();

    finally

      // Free the socket
      if (ClientServerSocket <> nil) then ClientServerSocket.Free;

      TClientServerSocket.Finalize();

    end;

  except // In case of an exception

    // Trace the event if a tracer is enabled
    on E: Exception do if (TTracer.IsEnabled()) then TTracer.Trace(TracePriorityError, 'TResolver.Execute: ' + E.Message);

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
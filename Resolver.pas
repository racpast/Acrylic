
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
      function    PrintRequestPacketHostNameAsStringFromPacket(Buffer: Pointer; BufferLen: Integer): String;
      procedure   BuildResponsePacketFromHostNameAndAddress(HostName: String; HostAddress: Integer; Buffer: Pointer; var BufferLen: Integer);
      function    PrintResponsePacketDescriptionAsStringFromPacket(Buffer: Pointer; BufferLen: Integer): String;
    private
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
  SysUtils, Configuration, Tracer, ClientServerSocket, Digest, SessionCache, AddressCache, HostsCache, HitLogger, Performance, Statistics, IPAddress;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TResolver.Create();
begin
  inherited Create(True);

  // Want to free the thread by hand...
  FreeOnTerminate := False;

  // Allocate memory buffers
  GetMem(Buffer, MAX_DNS_BUFFER_LEN);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TResolver.Destroy();
begin
  // Deallocate memory buffers
  FreeMem(Buffer, MAX_DNS_BUFFER_LEN);

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
        if (Length(Value) > 0) then Value := Value + '.';

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
  // Init
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

  // Increment the offset
  Inc(Offset);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TResolver.PrintRequestPacketHostNameAsStringFromPacket(Buffer: Pointer; BufferLen: Integer): String;
var
  OffsetL1: Integer; OffsetLX: Integer;
begin
  OffsetL1 := REQ_HOST_NAME_OFFSET; OffsetLX := OffsetL1; Result := GetStringFromPacket('', Buffer, OffsetL1, OffsetLX, 1, BufferLen);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TResolver.BuildResponsePacketFromHostNameAndAddress(HostName: String; HostAddress: Integer; Buffer: Pointer; var BufferLen: Integer);
var
  Offset: Integer;
begin
  // Set the header
  PByteArray(Buffer)^[00] := $00; // Query ID (LSB)
  PByteArray(Buffer)^[01] := $00; // Query ID (LSB)
  PByteArray(Buffer)^[02] := $85; // QRESP1=1, OPCODE4=0, AUTH1=1, TRUNC1=0, RECURSD1=1
  PByteArray(Buffer)^[03] := $80; // RECURSA1=1, RESERV3=0, RESCODE4=0
  PByteArray(Buffer)^[04] := $00; // NQUESTIONS (MSB)
  PByteArray(Buffer)^[05] := $01; // NQUESTIONS (LSB)
  PByteArray(Buffer)^[06] := $00; // NANSWERSRR (MSB)
  PByteArray(Buffer)^[07] := $01; // NANSWERSRR (LSB)
  PByteArray(Buffer)^[08] := $00; // NAUTHORIRR (MSB)
  PByteArray(Buffer)^[09] := $00; // NAUTHORIRR (LSB)
  PByteArray(Buffer)^[10] := $00; // NADDITIORR (MSB)
  PByteArray(Buffer)^[11] := $00; // NADDITIORR (LSB)

  // Initialize the offset
  Offset := REQ_HOST_NAME_OFFSET;

  // Set the question name
  SetStringIntoPacket(HostName, Buffer, Offset, BufferLen);

  // Set the question additional info
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset); // QUERYTYPE (MSB)
  PByteArray(Buffer)^[Offset] := $01; Inc(Offset); // QUERYTYPE (LSB)
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset); // QUERYCLASS (MSB)
  PByteArray(Buffer)^[Offset] := $01; Inc(Offset); // QUERYCLASS (LSB)

  // Set the answer reference informations
  PByteArray(Buffer)^[Offset] := $C0; Inc(Offset);
  PByteArray(Buffer)^[Offset] := REQ_HOST_NAME_OFFSET; Inc(Offset);

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

function TResolver.PrintResponsePacketDescriptionAsStringFromPacket(Buffer: Pointer; BufferLen: Integer): String;
var
  FValue: String; AValue: String; BValue: String; OffsetL1: Integer; OffsetLX: Integer; QdCount: Word; AnCount: Word; Index: Integer; AnType: Word; AnData: Word;
begin
  QdCount := GetWordFromPacket(Buffer, 04, BufferLen);
  AnCount := GetWordFromPacket(Buffer, 06, BufferLen);

  if (QdCount = 1) and (AnCount > 0) then begin // We are only able to understand this...

    // Initialize
    SetLength(FValue, 0);

    // Read the first question
    OffsetL1 := REQ_HOST_NAME_OFFSET; OffsetLX := OffsetL1; AValue := GetStringFromPacket('', Buffer, OffsetL1, OffsetLX, 1, BufferLen); Inc(OffsetL1, 4);

    // Update the packet description
    FValue := 'Q=' + AValue;

    for Index := 1 to AnCount do begin

      if (OffsetL1 < BufferLen) then begin

        // Read the answer name
        OffsetLX := OffsetL1; AValue := GetStringFromPacket('', Buffer, OffsetL1, OffsetLX, 1, BufferLen);

        if ((OffsetL1 + 10) <= BufferLen) then begin

          // Read the answer properties
          AnType := GetWordFromPacket(Buffer, OffsetL1, BufferLen); Inc(OffsetL1, 8);
          AnData := GetWordFromPacket(Buffer, OffsetL1, BufferLen); Inc(OffsetL1, 2);

          if (AnData > 0) and ((OffsetL1 + AnData) <= BufferLen) then begin

            case AnType of

              $0001: // A record

                if (AnData = 4) then begin

                  // Read the answer contents
                  BValue := TIPAddress.ToString(GetIntegerFromPacket(Buffer, OffsetL1, BufferLen));

                  // Update the packet description
                  FValue := FValue + ';A=' + AValue + '>' + BValue;

                end;

            end; Inc(OffsetL1, AnData);

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
    Result := '?=' + IntToHex(PByteArray(Buffer)^[00], 2) + IntToHex(PByteArray(Buffer)^[01], 2) + IntToHex(PByteArray(Buffer)^[02], 2) + IntToHex(PByteArray(Buffer)^[03], 2) + IntToHex(PByteArray(Buffer)^[04], 2) + IntToHex(PByteArray(Buffer)^[05], 2) + IntToHex(PByteArray(Buffer)^[06], 2) + IntToHex(PByteArray(Buffer)^[07], 2) + IntToHex(PByteArray(Buffer)^[08], 2) + IntToHex(PByteArray(Buffer)^[09], 2) + IntToHex(PByteArray(Buffer)^[10], 2) + IntToHex(PByteArray(Buffer)^[11], 2) + '...';
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function TResolver.IsNegativeResponsePacket(Buffer: Pointer; BufferLen: Integer): Boolean;
begin
  Result := not((PByteArray(Buffer)^[03] and $0f) = 0);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TResolver.Execute;
var
  ClientServerSocket: TClientServerSocket;
  Arrival: TDateTime; ArrivalEx: Double; Address: Integer; AltAddress: Integer; Port: Word; AltPort: Word; SessionId: Word; RequestHash: Int64; SilentUpdate: Boolean; CacheException: Boolean; HostName: String; DnsIndex: Integer;
begin
  // Initialize network
  TClientServerSocket.Initialize();

  try
    // Initialize socket
    ClientServerSocket := nil; try

      // Bind the socket to the specified address and port
      ClientServerSocket := TClientServerSocket.Create(TConfiguration.GetLocalBindingAddress(), TConfiguration.GetLocalBindingPort());
    
      repeat // Working cycle
    
        // If there is a packet available...
        if ClientServerSocket.ReceiveFrom(RESOLVER_THREAD_MAX_BLOCK_TIME, MAX_DNS_BUFFER_LEN, Self.Buffer, Self.BufferLen, Address, Port) then begin

          // If the packet is not too small or large...
          if (Self.BufferLen >= MIN_DNS_PACKET_LEN) and (Self.BufferLen <= MAX_DNS_PACKET_LEN) then begin

            Arrival := Now;

            // Mark the packet arrival time
            ArrivalEx := TPerformance.GetInstantValue();

            // Get the id field from the packet
            SessionId := Self.GetIdFromPacket(Self.Buffer);

            // If it's a response coming from one of the DNS servers...
            if ((Address = TConfiguration.GetServerAddress(0)) or (Address = TConfiguration.GetServerAddress(1)) or (Address = TConfiguration.GetServerAddress(2))) then begin

              // Trace the event if a tracer is enabled
              if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' received from server ' + TIPAddress.ToString(Address) + ':' + IntToStr(Port) + '.');

              // If the item exists in the session cache...
              if TSessionCache.Extract(SessionId, RequestHash, AltAddress, AltPort, SilentUpdate, CacheException) then begin

                if CacheException then begin // If it's a response to a cache exception request...

                  // Forward the packet to the client
                  ClientServerSocket.SendTo(Self.Buffer, Self.BufferLen, AltAddress, AltPort);

                  // Trace the event if a tracer is enabled
                  if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TIPAddress.ToString(AltAddress) + ':' + IntToStr(AltPort) + '.');

                end else if SilentUpdate then begin // If it's a response to a silent update request...

                  if not(Self.IsNegativeResponsePacket(Self.Buffer, Self.BufferLen)) then begin // If the response is not negative...

                    // Clear the id field of the packet
                    Self.SetIdIntoPacket(0, Self.Buffer);

                    // Insert the item into the address cache
                    TAddressCache.Add(Arrival, RequestHash, Self.Buffer, Self.BufferLen, False);

                    // Trace the event if a tracer is enabled
                    if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' put into the address cache as positive silent update.');

                  end else begin // The response is negative!

                    // Trace the event if a tracer is enabled
                    if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + ' discarded as negative silent update.');

                  end;

                end else begin // It's a response to a standard request!

                  // Forward the packet to the client
                  ClientServerSocket.SendTo(Self.Buffer, Self.BufferLen, AltAddress, AltPort);

                  if not(IsNegativeResponsePacket(Self.Buffer, Self.BufferLen)) then begin // If the response is not negative...

                    // Clear the id field of the packet
                    Self.SetIdIntoPacket(0, Self.Buffer);

                    // Insert the item into the address cache
                    TAddressCache.Add(Arrival, RequestHash, Self.Buffer, Self.BufferLen, False);

                    // Trace the event if a tracer is enabled
                    if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TIPAddress.ToString(AltAddress) + ':' + IntToStr(AltPort) + ' and put into the address cache as positive.');

                  end else begin // The response is negative!

                    // Clear the id field of the packet
                    Self.SetIdIntoPacket(0, Self.Buffer);

                    // Insert the item into the address cache
                    TAddressCache.Add(Arrival, RequestHash, Self.Buffer, Self.BufferLen, True);

                    // Trace the event if a tracer is enabled
                    if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TIPAddress.ToString(AltAddress) + ':' + IntToStr(AltPort) + ' and put into the address cache as negative.');

                  end;

                end;

                // Trace the event into the hit log if enabled
                if THitLogger.IsEnabled() and (Pos('R', TConfiguration.GetHitLogFileWhat()) > 0) then THitLogger.AddHit(Arrival, 'R', Address, Self.PrintResponsePacketDescriptionAsStringFromPacket(Self.Buffer, Self.BufferLen));

              end else begin // The item has not been found in the session cache!

                // Trace the event if a tracer is enabled
                if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' discarded because no session cache entry matched.');

              end;

              // Update performance statistics if enabled
              if TStatistics.IsEnabled() then begin if (Address = TConfiguration.GetServerAddress(0)) then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalEx, True, 0, SessionId) else if (Address = TConfiguration.GetServerAddress(1)) then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalEx, True, 1, SessionId) else if (Address = TConfiguration.GetServerAddress(2)) then TStatistics.IncTotalResponsesAndMeasureFlyTime(ArrivalEx, True, 2, SessionId); end;

            // Else if it's a request coming from one of the DNS clients...
            end else if (Address = LOCALHOST_ADDRESS) or TConfiguration.IsAllowedAddress(TIPAddress.ToString(Address)) then begin

              // Get the host name from the request
              HostName := Self.PrintRequestPacketHostNameAsStringFromPacket(Buffer, BufferLen);

              // Trace the event if a tracer is enabled
              if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Request  ID ' + FormatCurr('00000', SessionId) + ' received from client ' + TIPAddress.ToString(Address) + ':' + IntToStr(Port) + ' regarding "' + HostName + '".');

              if TConfiguration.IsBlackException(HostName) then begin // If not a white exception...

                // Build a standard response
                Self.BuildResponsePacketFromHostNameAndAddress(HostName, LOCALHOST_ADDRESS, Self.Buffer, Self.BufferLen);

                // Send the response to the client
                Self.SetIdIntoPacket(SessionId, Self.Buffer); ClientServerSocket.SendTo(Self.Buffer, Self.BufferLen, Address, Port);

                // Trace the event if a tracer is enabled
                if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TIPAddress.ToString(Address) + ':' + IntToStr(Port) + ' as black exception.');

                // Trace the event into the hit log if enabled
                if THitLogger.IsEnabled() and (Pos('B', TConfiguration.GetHitLogFileWhat()) > 0) then THitLogger.AddHit(Arrival, 'B', Address, HostName);

                // Update performance statistics if enabled
                if TStatistics.IsEnabled() then TStatistics.IncTotalRequestsResolvedThroughOtherWays();

              end else if THostsCache.Find(HostName, AltAddress) then begin // If the host name exists in the hosts cache...

                // Build a standard response
                Self.BuildResponsePacketFromHostNameAndAddress(HostName, AltAddress, Self.Buffer, Self.BufferLen);

                // Send the response to the client
                Self.SetIdIntoPacket(SessionId, Self.Buffer); ClientServerSocket.SendTo(Self.Buffer, Self.BufferLen, Address, Port);

                // Trace the event if a tracer is enabled
                if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TIPAddress.ToString(Address) + ':' + IntToStr(Port) + ' directly from hosts cache.');

                // Trace the event into the hit log if enabled
                if THitLogger.IsEnabled() and (Pos('H', TConfiguration.GetHitLogFileWhat()) > 0) then THitLogger.AddHit(Arrival, 'H', Address, HostName);

                // Update performance statistics if enabled
                if TStatistics.IsEnabled() then TStatistics.IncTotalRequestsResolvedThroughHostsFile();

              end else if TConfiguration.IsCacheException(HostName) then begin // If the host name is configured as a cache exception...

                for DnsIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin // For every DNS server...
                  if (TConfiguration.GetServerAddress(DnsIndex) <> -1) then begin // If it's been configured...

                    // Forward the request to the server
                    ClientServerSocket.SendTo(Self.Buffer, Self.BufferLen, TConfiguration.GetServerAddress(DnsIndex), TConfiguration.GetServerPort(DnsIndex));

                    // Update performance data if enabled
                    if TStatistics.IsEnabled() then TStatistics.IncTotalResponsesAndMeasureFlyTime(TPerformance.GetInstantValue(), False, DnsIndex, SessionId);

                    // Trace the event if a tracer is enabled
                    if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Request  ID ' + FormatCurr('00000', SessionId) + ' forwarded to server ' + TIPAddress.ToString(TConfiguration.GetServerAddress(DnsIndex)) + ':' + IntToStr(TConfiguration.GetServerPort(DnsIndex)) + ' as cache exception.');

                  end else begin
                    Break;
                  end;
                end;

                // Clear the id field of the packet
                Self.SetIdIntoPacket(0, Self.Buffer);

                // Insert the item into the session cache
                TSessionCache.Insert(SessionId, RequestHash, Address, Port, False, True);

                // Trace the event into the hit log if enabled
                if THitLogger.IsEnabled() and (Pos('F', TConfiguration.GetHitLogFileWhat()) > 0) then THitLogger.AddHit(Arrival, 'F', Address, HostName);

                // Update performance statistics if enabled
                if TStatistics.IsEnabled() then TStatistics.IncTotalRequestsForwarded();

              end else begin // The host name is neither in the hosts cache nor within the cache exceptions...

                // Clear the id field of the packet
                Self.SetIdIntoPacket(0, Self.Buffer);

                // Compute the request hash and save it
                RequestHash := TDigest.ComputeCRC64(Self.Buffer, Self.BufferLen);

                // Check if the request exists in the address cache...
                case TAddressCache.Find(Arrival, RequestHash, Self.Buffer, Self.BufferLen) of

                  RecentEnough: begin // The address cache item is recent...

                    // Set the id field of the packet
                    Self.SetIdIntoPacket(SessionId, Self.Buffer);

                    // Send the response to the client
                    ClientServerSocket.SendTo(Self.Buffer, Self.BufferLen, Address, Port);

                    // Trace the event if a tracer is enabled
                    if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TIPAddress.ToString(Address) + ':' + IntToStr(Port) + ' directly from address cache.');

                    // Trace the event into the hit log if enabled
                    if THitLogger.IsEnabled() and (Pos('C', TConfiguration.GetHitLogFileWhat()) > 0) then THitLogger.AddHit(Arrival, 'C', Address, HostName);

                    // Update performance statistics if enabled
                    if TStatistics.IsEnabled() then TStatistics.IncTotalRequestsResolvedThroughCache();

                  end; NeedsUpdate: begin // The address cache item needs a silent update...

                    // Set the id field of the packet
                    Self.SetIdIntoPacket(SessionId, Self.Buffer);

                    // Send the response to the client
                    ClientServerSocket.SendTo(Self.Buffer, Self.BufferLen, Address, Port);

                    // Trace the event if a tracer is enabled
                    if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Response ID ' + FormatCurr('00000', SessionId) + ' sent to client ' + TIPAddress.ToString(Address) + ':' + IntToStr(Port) + ' directly from address cache.');

                    for DnsIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin // For every DNS server...
                      if (TConfiguration.GetServerAddress(DnsIndex) <> -1) then begin // If it's been configured...

                        // Forward the request to the server
                        ClientServerSocket.SendTo(Self.Buffer, Self.BufferLen, TConfiguration.GetServerAddress(DnsIndex), TConfiguration.GetServerPort(DnsIndex));

                        // Update performance data if enabled
                        if TStatistics.IsEnabled() then TStatistics.IncTotalResponsesAndMeasureFlyTime(TPerformance.GetInstantValue(), False, DnsIndex, SessionId);

                        // Trace the event if a tracer is enabled
                        if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Request  ID ' + FormatCurr('00000', SessionId) + ' forwarded to server ' + TIPAddress.ToString(TConfiguration.GetServerAddress(DnsIndex)) + ':' + IntToStr(TConfiguration.GetServerPort(DnsIndex)) + ' as silent update.');

                      end else begin
                        Break;
                      end;
                    end;

                    // Clear the id field of the packet
                    Self.SetIdIntoPacket(0, Self.Buffer);

                    // Insert the item into the session cache
                    TSessionCache.Insert(SessionId, RequestHash, Address, Port, True, False);

                    // Trace the event into the hit log if enabled
                    if THitLogger.IsEnabled() and (Pos('C', TConfiguration.GetHitLogFileWhat()) > 0) then THitLogger.AddHit(Arrival, 'C', Address, HostName);

                    // Update performance statistics if enabled
                    if TStatistics.IsEnabled() then TStatistics.IncTotalRequestsResolvedThroughCache();

                  end; NotFound: begin // The item is not in the address cache...

                    // Set the id field of the packet
                    Self.SetIdIntoPacket(SessionId, Self.Buffer);
                    
                    for DnsIndex := 0 to (Configuration.MAX_NUM_DNS_SERVERS - 1) do begin // For every DNS server...
                      if (TConfiguration.GetServerAddress(DnsIndex) <> -1) then begin // If it's been configured...

                        // Forward the request to the server
                        ClientServerSocket.SendTo(Self.Buffer, Self.BufferLen, TConfiguration.GetServerAddress(DnsIndex), TConfiguration.GetServerPort(DnsIndex));

                        // Update performance data if enabled
                        if TStatistics.IsEnabled() then TStatistics.IncTotalResponsesAndMeasureFlyTime(TPerformance.GetInstantValue(), False, DnsIndex, SessionId);

                        // Trace the event if a tracer is enabled
                        if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Request  ID ' + FormatCurr('00000', SessionId) + ' forwarded to server ' + TIPAddress.ToString(TConfiguration.GetServerAddress(DnsIndex)) + ':' + IntToStr(TConfiguration.GetServerPort(DnsIndex)) + '.');

                      end else begin
                        Break;
                      end;
                    end;

                    // Clear the id field of the packet
                    Self.SetIdIntoPacket(0, Self.Buffer);

                    // Insert the item into the session cache
                    TSessionCache.Insert(SessionId, RequestHash, Address, Port, False, False);

                    // Trace the event into the hit log if enabled
                    if THitLogger.IsEnabled() and (Pos('F', TConfiguration.GetHitLogFileWhat()) > 0) then THitLogger.AddHit(Arrival, 'F', Address, HostName);

                    // Update performance statistics if enabled
                    if TStatistics.IsEnabled() then TStatistics.IncTotalRequestsForwarded();

                  end;

                end;

              end;

              // Update performance statistics if enabled
              if TStatistics.IsEnabled() then TStatistics.IncTotalRequestsReceived();

            end else begin // It's a spurious packet coming from the infinite

              // Trace the event if a tracer is enabled
              if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Unexpected packet received from address ' + TIPAddress.ToString(Address) + ':' + IntToStr(Port) + '.');

              // Update performance statistics if enabled
              if TStatistics.IsEnabled() then TStatistics.IncTotalPacketsDiscarded();

            end;

          end else begin // It's a spurious packet coming from the infinite

            // Trace the event if a tracer is enabled
            if TTracer.IsEnabled() then TTracer.Trace(TracePriorityInfo, 'TResolver.Execute: Malformed packet received from address ' + TIPAddress.ToString(Address) + ':' + IntToStr(Port) + '.');

            // Update performance statistics if enabled
            if TStatistics.IsEnabled() then TStatistics.IncTotalPacketsDiscarded();

          end;
    
        end else begin // Good place for low priority operations here...

          // If enabled flush the hit log and the stats log of any pending data
          if THitLogger.IsEnabled() then THitLogger.FlushPendingHitsToDisk(); if TStatistics.IsEnabled() then TStatistics.FlushStatisticsToDisk();

        end;

      until Terminated;

      // If enabled flush the hit log and the stats log of any pending data
      if THitLogger.IsEnabled() then THitLogger.FlushPendingHitsToDisk(); if TStatistics.IsEnabled() then TStatistics.FlushStatisticsToDisk();

    finally

      // Free the socket
      if (ClientServerSocket <> nil) then ClientServerSocket.Free;

      // Finalize network
      TClientServerSocket.Finalize();
      
    end;
  
  except // In case of an exception...

    // Trace the event if a tracer is enabled
    on E: Exception do if (TTracer.IsEnabled()) then TTracer.Trace(TracePriorityError, 'TResolver.Execute: ' + E.Message);

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.


// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TClientServerSocketUnitTest = class(TAbstractUnitTest)
    private
      ObjectA   : TClientServerSocket;
      ObjectB   : TClientServerSocket;
      BufferA   : PByteArray;
      BufferB   : PByteArray;
    public
      constructor Create();
      procedure   ExecuteTest(); override;
      destructor  Destroy(); override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor TClientServerSocketUnitTest.Create();
begin
  // Call base
  inherited Create;

  // Initialize locals
  GetMem(BufferA, MAX_DNS_BUFFER_LEN); FillChar(BufferA^, MAX_DNS_BUFFER_LEN, $80);
  GetMem(BufferB, MAX_DNS_BUFFER_LEN); FillChar(BufferB^, MAX_DNS_BUFFER_LEN, $00);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TClientServerSocketUnitTest.ExecuteTest();
var
  n, i, j, a: Integer; p, pA, pB: Word;
begin
  // Initialize the class
  TClientServerSocket.Initialize;

  for n := 1 to 1000 do begin // For the specified number of "coupled" ports...

    // Choose the ports
    pA := Random(8192) + 8192;
    pB := Random(8192) + pA + 1;

	  // Create needed objects
	  ObjectA := TClientServerSocket.Create(0, pA);
	  ObjectB := TClientServerSocket.Create(0, pB);

	  // Repeat send and receive
	  for i := 1 to MAX_DNS_PACKET_LEN do begin
	
	    // Init packet
	    FillChar(BufferB^, (1 + i), $80);

	    // Send packet
	    ObjectA.SendTo(BufferA, (1 + i), LOCALHOST_ADDRESS, pB);

	    // Receive packet
	    if not(ObjectB.ReceiveFrom(50, MAX_DNS_BUFFER_LEN, BufferB, j, a, p)) then raise FailedUnitTestException.Create;

	    // Check received packet
	    if (a <> LOCALHOST_ADDRESS) or (p <> pA) or (j <> (1 + i)) or not(CompareMem(BufferA, BufferB, (1 + i))) then raise FailedUnitTestException.Create;

	    // Init packet
	    FillChar(BufferB^, (1 + i), $80);

	    // Send packet
	    ObjectB.SendTo(BufferA, (1 + i), LOCALHOST_ADDRESS, pA);

	    // Receive packet
	    if not(ObjectA.ReceiveFrom(50, MAX_DNS_BUFFER_LEN, BufferB, j, a, p)) then raise FailedUnitTestException.Create;

	    // Check received packet
	    if (a <> LOCALHOST_ADDRESS) or (p <> pB) or (j <> (1 + i)) or not(CompareMem(BufferA, BufferB, (1 + i))) then raise FailedUnitTestException.Create;

	  end;

	  // Free objects
	  ObjectB.Free;
	  ObjectA.Free;

  end;

  // Finalize the class
  TClientServerSocket.Finalize;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor TClientServerSocketUnitTest.Destroy();
begin
  // Finalize locals
  FreeMem(BufferA, MAX_DNS_BUFFER_LEN);
  FreeMem(BufferB, MAX_DNS_BUFFER_LEN);

  // Call base
  inherited Destroy;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------



// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  THostsCacheUnitTest = class(TAbstractUnitTest)
    public
      constructor  Create();
      procedure    ExecuteTest(); override;
      destructor   Destroy(); override;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

constructor THostsCacheUnitTest.Create();
begin
  // Call base
  inherited Create;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure THostsCacheUnitTest.ExecuteTest();
var
  i, j: Integer; Address: Integer; HostsStream: TFileStream; HostsLine: String; const KHostsItems = 500;
begin
  // Load configuration
  TConfiguration.Initialize();

  // Open a stream to build a hosts file
  HostsStream := TFileStream.Create(ClassName + '.tmp', fmCreate);

  for i := 0 to (KHostsItems - 1) do begin // Massive item production...

    // Fill a block of host items
    SetLength(HostsLine, 0); for j := 0 to 999 do HostsLine := HostsLine + IntToStr((1000 * i + j) and 255) + '.' + IntToStr(((1000 * i + j) shr 8) and 255) + '.' + IntToStr(((1000 * i + j) shr 16) and 255) + '.' + IntToStr((1000 * i + j) shr 24) + #32 + 'HOSTNAME-' + IntToStr((1000 * i + j)) + #13#10;

    // Write the block of host items to disk
    HostsStream.Write(HostsLine[1], Length(HostsLine));

  end;

  // Close the stream
  HostsStream.Free();

  // Initialize class
  THostsCache.Initialize;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Start loading cache...');

  // Load the cache from file
  THostsCache.LoadFromFile(ClassName + '.tmp');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Start searching items...');

  for i := 0 to (KHostsItems - 1) do begin

    for j := 0 to 999 do begin

      // Search the item by name
      if not(THostsCache.Find('HOSTNAME-' + IntToStr(1000 * i + j), Address)) then raise FailedUnitTestException.Create;

      // Check the item's returned address
      if (Address <> (1000 * i + j)) then raise FailedUnitTestException.Create;

    end;

  end;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  // Try to look for a nonexistant item
  if THostsCache.Find('NONEXISTANT', Address) then raise FailedUnitTestException.Create;

  // Finalize class and configuration
  THostsCache.Finalize(); TConfiguration.Finalize();
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor THostsCacheUnitTest.Destroy();
begin
  // Call base
  inherited Destroy;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

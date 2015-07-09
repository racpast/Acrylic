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
  inherited Create;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure THostsCacheUnitTest.ExecuteTest();
var
  i, j: Integer; Address: Integer; HostsStream: TFileStream; HostsLine: String; const KHostsItems = 1000;
begin
  // Open a stream to build a hosts file
  HostsStream := TFileStream.Create(ClassName + '.tmp', fmCreate);

  for i := 0 to (KHostsItems - 1) do begin // Massive item production...

    // Fill a block of host items
    SetLength(HostsLine, 0); for j := 0 to 999 do HostsLine := HostsLine + IntToStr((1000 * i + j) and 255) + '.' + IntToStr(((1000 * i + j) shr 8) and 255) + '.' + IntToStr(((1000 * i + j) shr 16) and 255) + '.' + IntToStr((1000 * i + j) shr 24) + #32 + 'HOSTNAME-' + FormatCurr('000000000', (1000 * i + j)) + '-A' + #32 + 'HOSTNAME-' + FormatCurr('000000000', (1000 * i + j)) + '-B' + #13#10;

    // Write the block of host items to disk
    HostsStream.Write(HostsLine[1], Length(HostsLine));

  end;

  // Add patterns to the list
  HostsLine := '127.0.0.1 >PATTERN1-127-0-0-1 -NO.PATTERN1-127-0-0-1' + #13#10; HostsStream.Write(HostsLine[1], Length(HostsLine));
  HostsLine := '127.0.0.1 >PATTERN2-127-0-0-1.* -NO.PATTERN2-127-0-0-1.TEST' + #13#10; HostsStream.Write(HostsLine[1], Length(HostsLine));
  HostsLine := '127.0.0.1 *.PATTERN3-127-0-0-1.* -NO.PATTERN3-127-0-0-1.TEST' + #13#10; HostsStream.Write(HostsLine[1], Length(HostsLine));

  // Add regular expressions to the list
  HostsLine := '127.0.0.1 /^.*\.REGEXP1-127-0-0-1\..*$ -NO.REGEXP1-127-0-0-1.TEST' + #13#10; HostsStream.Write(HostsLine[1], Length(HostsLine));

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
      if not(THostsCache.Find('HOSTNAME-' + FormatCurr('000000000', (1000 * i + j)) + '-A', Address) and (Address = (1000 * i + j))) or not(THostsCache.Find('HOSTNAME-' + FormatCurr('000000000', (1000 * i + j)) + '-B', Address) and (Address = (1000 * i + j))) then raise FailedUnitTestException.Create;

    end;

  end;

  // Test the pattern engine (1)
  if not(THostsCache.Find('PATTERN1-127-0-0-1', Address) and (Address = LOCALHOST_ADDRESS)) or not(THostsCache.Find('pattern1-127-0-0-1', Address) and (Address = LOCALHOST_ADDRESS)) or THostsCache.Find('NO.PATTERN1-127-0-0-1', Address) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('MATCH.PATTERN1-127-0-0-1', Address) and (Address = LOCALHOST_ADDRESS)) or not(THostsCache.Find('match.pattern1-127-0-0-1', Address) and (Address = LOCALHOST_ADDRESS)) or THostsCache.Find('NO.PATTERN1-127-0-0-1', Address) then raise FailedUnitTestException.Create;

  // Test the pattern engine (2)
  if not(THostsCache.Find('PATTERN2-127-0-0-1.TEST', Address) and (Address = LOCALHOST_ADDRESS)) or not(THostsCache.Find('pattern2-127-0-0-1.test', Address) and (Address = LOCALHOST_ADDRESS)) or THostsCache.Find('NO.PATTERN2-127-0-0-1.TEST', Address) then raise FailedUnitTestException.Create;
  if not(THostsCache.Find('MATCH.PATTERN2-127-0-0-1.TEST', Address) and (Address = LOCALHOST_ADDRESS)) or not(THostsCache.Find('match.pattern2-127-0-0-1.test', Address) and (Address = LOCALHOST_ADDRESS)) or THostsCache.Find('NO.PATTERN2-127-0-0-1.TEST', Address) then raise FailedUnitTestException.Create;

  // Test the pattern engine (3)
  if not(THostsCache.Find('MATCH.PATTERN3-127-0-0-1.TEST', Address) and (Address = LOCALHOST_ADDRESS)) or not(THostsCache.Find('match.pattern3-127-0-0-1.test', Address) and (Address = LOCALHOST_ADDRESS)) or THostsCache.Find('NO.PATTERN3-127-0-0-1.TEST', Address) then raise FailedUnitTestException.Create;

  // Test the regular expression engine (1)
  if not(THostsCache.Find('MATCH.REGEXP1-127-0-0-1.TEST', Address) and (Address = LOCALHOST_ADDRESS)) or not(THostsCache.Find('match.regexp1-127-0-0-1.test', Address) and (Address = LOCALHOST_ADDRESS)) or THostsCache.Find('NO.REGEXP1-127-0-0-1.TEST', Address) then raise FailedUnitTestException.Create;

  // Try to look for a nonexistant item
  if THostsCache.Find('NONEXISTANT', Address) then raise FailedUnitTestException.Create;

  TTracer.Trace(TracePriorityInfo, Self.ClassName + ': Done.');

  // Finalize class
  THostsCache.Finalize();
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

destructor THostsCacheUnitTest.Destroy();
begin
  inherited Destroy;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------
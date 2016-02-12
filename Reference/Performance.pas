function MeasurePerformance(NoInnerCycles: Cardinal; NoOuterCycles: Cardinal): Double;
var
  i, j: Cardinal; ElapsedTime: Double;
begin
  ElapsedTime := 0;

  // Any initialization goes here:
  // -----------------------------

  for i := 1 to NoOuterCycles do begin

    TStopwatch.Start;

    for j := 1 to NoInnerCycles do begin

      // The instructions to be measured go here:
      // ----------------------------------------

    end;

    TStopwatch.Stop;

    ElapsedTime := ElapsedTime + TStopwatch.GetElapsedTime;

  end;

  Result := ElapsedTime;
end;
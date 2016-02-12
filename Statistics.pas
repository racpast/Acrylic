// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  Statistics;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TStatistics = class
    public
      class function  IsEnabled: Boolean;
    public
      class procedure IncTotalPacketsDiscarded;
      class procedure IncTotalRequestsReceived;
      class procedure IncTotalRequestsForwarded;
      class procedure IncTotalRequestsResolvedThroughCache;
      class procedure IncTotalRequestsResolvedThroughHostsFile;
      class procedure IncTotalRequestsResolvedThroughOtherWays;
    public
      class procedure IncTotalResponsesAndMeasureFlyTime(Arrival: Double; Response: Boolean; DnsIndex: Integer; SessionId: Word);
    public
      class procedure FlushStatisticsToDisk;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SysUtils, Windows, Configuration;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TStatistics_Changed: Boolean;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TStatistics_StartTime: TDateTime;
  TStatistics_CurrentTime: TDateTime;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TStatistics_TotalPacketsDiscarded: Cardinal;
  TStatistics_TotalRequestsReceived: Cardinal;
  TStatistics_TotalRequestsForwarded: Cardinal;
  TStatistics_TotalRequestsResolvedThroughCache: Cardinal;
  TStatistics_TotalRequestsResolvedThroughHostsFile: Cardinal;
  TStatistics_TotalRequestsResolvedThroughOtherWays: Cardinal;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TStatistics_TotalFlyTimesMeasuredFromDns: Array [0..(MAX_NUM_DNS_SERVERS - 1)] of Double;
  TStatistics_TotalResponsesReceivedFromDns: Array [0..(MAX_NUM_DNS_SERVERS - 1)] of Cardinal;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  TStatistics_SingleFlyTimesMeasuredFromDnsVal: Array [0..(MAX_NUM_DNS_SERVERS - 1), 0..65535] of Double;
  TStatistics_SingleFlyTimesMeasuredFromDnsFlg: Array [0..(MAX_NUM_DNS_SERVERS - 1), 0..65535] of Boolean;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TStatistics.IsEnabled: Boolean;
begin
  Result := TConfiguration.GetStatsLogFileName <> '';
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TStatistics.IncTotalPacketsDiscarded;
begin
  Inc(TStatistics_TotalPacketsDiscarded); TStatistics_Changed := True;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TStatistics.IncTotalRequestsReceived;
begin
  Inc(TStatistics_TotalRequestsReceived); TStatistics_Changed := True;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TStatistics.IncTotalRequestsForwarded;
begin
  Inc(TStatistics_TotalRequestsForwarded); TStatistics_Changed := True;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TStatistics.IncTotalRequestsResolvedThroughCache;
begin
  Inc(TStatistics_TotalRequestsResolvedThroughCache); TStatistics_Changed := True;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TStatistics.IncTotalRequestsResolvedThroughHostsFile;
begin
  Inc(TStatistics_TotalRequestsResolvedThroughHostsFile); TStatistics_Changed := True;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TStatistics.IncTotalRequestsResolvedThroughOtherWays;
begin
  Inc(TStatistics_TotalRequestsResolvedThroughOtherWays); TStatistics_Changed := True;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TStatistics.IncTotalResponsesAndMeasureFlyTime(Arrival: Double; Response: Boolean; DnsIndex: Integer; SessionId: Word);
var
  Elapsed: Double;
begin
  if Response then begin

    if TStatistics_SingleFlyTimesMeasuredFromDnsFlg[DnsIndex, SessionId] then begin

      // Calculate elapsed
      Elapsed := Arrival - TStatistics_SingleFlyTimesMeasuredFromDnsVal[DnsIndex, SessionId];

      // Update the number of responses, fly times and flag
      Inc(TStatistics_TotalResponsesReceivedFromDns[DnsIndex]); TStatistics_TotalFlyTimesMeasuredFromDns[DnsIndex] := TStatistics_TotalFlyTimesMeasuredFromDns[DnsIndex] + Elapsed; TStatistics_Changed := True; TStatistics_SingleFlyTimesMeasuredFromDnsFlg[DnsIndex, SessionId] := False;

    end;

  end else begin

    // Update the arrival value and flag
    TStatistics_SingleFlyTimesMeasuredFromDnsVal[DnsIndex, SessionId] := Arrival; TStatistics_SingleFlyTimesMeasuredFromDnsFlg[DnsIndex, SessionId] := True;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TStatistics.FlushStatisticsToDisk;
var
  Handle: THandle; Data: String; Written: Cardinal; DnsIndex: Integer;
begin
  if TStatistics_Changed then begin

    // Init data
    SetLength(Data, 0);

    // Get current time
    TStatistics_CurrentTime := Now;

    Data := Data + 'StartTime                             : ' + FormatDateTime('yyyy-mm-dd HH:nn:ss', TStatistics_StartTime) + #13#10;
    Data := Data + 'CurrentTime                           : ' + FormatDateTime('yyyy-mm-dd HH:nn:ss', TStatistics_CurrentTime) + #13#10;

    Data := Data + 'TotalPacketsDiscarded                 : ' + IntToStr(TStatistics_TotalPacketsDiscarded) + #13#10;
    Data := Data + 'TotalRequestsReceived                 : ' + IntToStr(TStatistics_TotalRequestsReceived) + #13#10;
    Data := Data + 'TotalRequestsForwarded                : ' + IntToStr(TStatistics_TotalRequestsForwarded) + #13#10;
    Data := Data + 'TotalRequestsResolvedThroughCache     : ' + IntToStr(TStatistics_TotalRequestsResolvedThroughCache) + #13#10;
    Data := Data + 'TotalRequestsResolvedThroughHostsFile : ' + IntToStr(TStatistics_TotalRequestsResolvedThroughHostsFile) + #13#10;
    Data := Data + 'TotalRequestsResolvedThroughOtherWays : ' + IntToStr(TStatistics_TotalRequestsResolvedThroughOtherWays) + #13#10;

    for DnsIndex := 0 to (MAX_NUM_DNS_SERVERS - 1) do begin
      if (TStatistics_TotalResponsesReceivedFromDns[DnsIndex] > 0) then Data := Data + 'TotalResponsesReceivedFromDns' + Format('%.2d', [DnsIndex + 1]) + '       : ' + IntToStr(TStatistics_TotalResponsesReceivedFromDns[DnsIndex]) + #13#10 + 'MeanResponseTimeOfDns' + Format('%.2d', [DnsIndex + 1]) + '               : ' + FormatCurr('0.0', 1000.0 * (TStatistics_TotalFlyTimesMeasuredFromDns[DnsIndex] / TStatistics_TotalResponsesReceivedFromDns[DnsIndex])) + ' ms' + #13#10 else Data := Data + 'TotalResponsesReceivedFromDns' + Format('%.2d', [DnsIndex + 1]) + '       : ' + IntToStr(TStatistics_TotalResponsesReceivedFromDns[DnsIndex]) + #13#10 + 'MeanResponseTimeOfDns' + Format('%.2d', [DnsIndex + 1]) + '               : ?' + #13#10;
    end;

    Handle := CreateFile(PChar(TConfiguration.GetStatsLogFileName), GENERIC_WRITE, FILE_SHARE_READ, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_ARCHIVE, 0); if (Handle <> INVALID_HANDLE_VALUE) then begin
      WriteFile(Handle, Data[1], Length(Data), Written, nil); CloseHandle(Handle);
    end;

    TStatistics_Changed := False;

  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

initialization

  TStatistics_StartTime:= Now;

  TStatistics_Changed := False;

  TStatistics_TotalPacketsDiscarded := 0;
  TStatistics_TotalRequestsReceived := 0;
  TStatistics_TotalRequestsForwarded := 0;
  TStatistics_TotalRequestsResolvedThroughCache := 0;
  TStatistics_TotalRequestsResolvedThroughHostsFile := 0;
  TStatistics_TotalRequestsResolvedThroughOtherWays := 0;

  FillChar(TStatistics_TotalResponsesReceivedFromDns, 0, SizeOf(TStatistics_TotalResponsesReceivedFromDns));
  FillChar(TStatistics_SingleFlyTimesMeasuredFromDnsFlg, 0, SizeOf(TStatistics_SingleFlyTimesMeasuredFromDnsFlg));

end.
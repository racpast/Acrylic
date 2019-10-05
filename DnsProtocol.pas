// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  DnsProtocol;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  CommunicationChannels;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  MIN_DNS_PACKET_LEN = 16;
  MAX_DNS_PACKET_LEN = 4096;
  MAX_DNS_BUFFER_LEN = 65536;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  DNS_QUERY_TYPE_A          = $0001;
  DNS_QUERY_TYPE_NS         = $0002;
  DNS_QUERY_TYPE_CNAME      = $0005;
  DNS_QUERY_TYPE_SOA        = $0006;
  DNS_QUERY_TYPE_PTR        = $000C;
  DNS_QUERY_TYPE_MX         = $000F;
  DNS_QUERY_TYPE_TXT        = $0010;
  DNS_QUERY_TYPE_AAAA       = $001C;
  DNS_QUERY_TYPE_SRV        = $0021;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TDnsProtocol = (UdpProtocol, TcpProtocol, Socks5Protocol);

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TDnsQueryTypeUtility = class
    public
      class function Parse(const Text: String): Word;
      class function ToString(Value: Word): String;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TDnsProtocolUtility = class
    public
      class function  ParseDnsProtocol(const Text: String): TDnsProtocol;
    private
      class function  GetWordFromPacket(Buffer: Pointer; Offset: Integer; BufferLen: Integer): Word;
      class function  GetIPv4AddressFromPacket(Buffer: Pointer; Offset: Integer; BufferLen: Integer): TIPv4Address;
      class function  GetIPv6AddressFromPacket(Buffer: Pointer; Offset: Integer; BufferLen: Integer): TIPv6Address;
    public
      class function  GetStringFromPacket(Value: String; Buffer: Pointer; var OffsetL1: Integer; var OffsetLX: Integer; Level: Integer; BufferLen: Integer): String; overload;
      class function  GetStringFromPacket(Buffer: Pointer; var OffsetL1: Integer; var OffsetLX: Integer; BufferLen: Integer): String; overload;
      class function  GetStringFromPacket(Buffer: Pointer; var OffsetL1: Integer; BufferLen: Integer): String; overload;
      class procedure SetStringIntoPacket(const Value: String; Buffer: Pointer; var Offset: Integer; BufferLen: Integer);
    public
      class function  GetIdFromPacket(Buffer: Pointer): Word;
      class procedure SetIdIntoPacket(Value: Word; Buffer: Pointer);
    public
      class procedure GetDomainNameAndQueryTypeFromRequestPacket(Buffer: Pointer; BufferLen: Integer; var DomainName: String; var QueryType: Word);
    public
      class function  IsPrivateReverseLookup(const DomainName: String): Boolean;
    public
      class procedure BuildNegativeResponsePacket(const DomainName: String; QueryType: Word; Buffer: Pointer; var BufferLen: Integer);
      class procedure BuildPositiveResponsePacket(const DomainName: String; QueryType: Word; Buffer: Pointer; var BufferLen: Integer); overload;
      class procedure BuildPositiveResponsePacket(const DomainName: String; QueryType: Word; HostAddress: TDualIPAddress; TimeToLive: Integer; Buffer: Pointer; var BufferLen: Integer); overload;
    public
      class procedure BuildPositiveIPv4ResponsePacket(const DomainName: String; QueryType: Word; HostAddress: TIPv4Address; TimeToLive: Integer; Buffer: Pointer; var BufferLen: Integer);
      class procedure BuildPositiveIPv6ResponsePacket(const DomainName: String; QueryType: Word; HostAddress: TIPv6Address; TimeToLive: Integer; Buffer: Pointer; var BufferLen: Integer);
    public
      class function  PrintGenericPacketBytesAsStringFromPacket(Buffer: Pointer; BufferLen: Integer): String;
      class function  PrintGenericPacketBytesAsStringFromPacketWithOffset(Buffer: Pointer; BufferLen: Integer; Offset: Integer; NumBytes: Integer): String;
    public
      class function  PrintResponsePacketDescriptionAsStringFromPacket(Buffer: Pointer; BufferLen: Integer; IncludePacketBytesAlways: Boolean): String;
      class function  PrintRequestPacketDescriptionAsStringFromPacket(const DomainName: String; QueryType: Word; Buffer: Pointer; BufferLen: Integer; IncludePacketBytesAlways: Boolean): String;
    public
      class function  IsFailureResponsePacket(Buffer: Pointer; BufferLen: Integer): Boolean;
      class function  IsNegativeResponsePacket(Buffer: Pointer; BufferLen: Integer): Boolean;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Math,
  SysUtils,
  CommonUtils;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsQueryTypeUtility.Parse(const Text: String): Word;

begin

       if (Text = 'A'    ) then Result := DNS_QUERY_TYPE_A
  else if (Text = 'AAAA' ) then Result := DNS_QUERY_TYPE_AAAA
  else if (Text = 'CNAME') then Result := DNS_QUERY_TYPE_CNAME
  else if (Text = 'MX'   ) then Result := DNS_QUERY_TYPE_MX
  else if (Text = 'NS'   ) then Result := DNS_QUERY_TYPE_NS
  else if (Text = 'PTR'  ) then Result := DNS_QUERY_TYPE_PTR
  else if (Text = 'SOA'  ) then Result := DNS_QUERY_TYPE_SOA
  else if (Text = 'SRV'  ) then Result := DNS_QUERY_TYPE_SRV
  else if (Text = 'TXT'  ) then Result := DNS_QUERY_TYPE_TXT
  else                          Result := StrToIntDef(Text, 0);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsQueryTypeUtility.ToString(Value: Word): String;

begin

  case Value of
    DNS_QUERY_TYPE_A    : Result := 'A';
    DNS_QUERY_TYPE_AAAA : Result := 'AAAA';
    DNS_QUERY_TYPE_CNAME: Result := 'CNAME';
    DNS_QUERY_TYPE_MX   : Result := 'MX';
    DNS_QUERY_TYPE_NS   : Result := 'NS';
    DNS_QUERY_TYPE_PTR  : Result := 'PTR';
    DNS_QUERY_TYPE_SOA  : Result := 'SOA';
    DNS_QUERY_TYPE_SRV  : Result := 'SRV';
    DNS_QUERY_TYPE_TXT  : Result := 'TXT';
    else                  Result := IntToStr(Value);
  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsProtocolUtility.ParseDnsProtocol(const Text: String): TDnsProtocol;

var
  UpperCaseText: String;

begin

  UpperCaseText := UpperCase(Text); if (UpperCaseText = 'SOCKS5') then Result := Socks5Protocol else if (UpperCaseText = 'TCP') then Result := TcpProtocol else Result := UdpProtocol;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsProtocolUtility.GetIdFromPacket(Buffer: Pointer): Word;

begin

  Result := (PByteArray(Buffer)^[0] shl 8) + PByteArray(Buffer)^[1];

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsProtocolUtility.SetIdIntoPacket(Value: Word; Buffer: Pointer);

begin

  PByteArray(Buffer)^[0] := Value shr 8; PByteArray(Buffer)^[1] := Value and 255;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsProtocolUtility.GetWordFromPacket(Buffer: Pointer; Offset: Integer; BufferLen: Integer): Word;

begin

  Result := (PByteArray(Buffer)^[Offset] shl 8) + PByteArray(Buffer)^[Offset + 1];

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsProtocolUtility.GetIPv4AddressFromPacket(Buffer: Pointer; Offset: Integer; BufferLen: Integer): TIPv4Address;

begin

  Result := (PByteArray(Buffer)^[Offset] shl 24) + (PByteArray(Buffer)^[Offset + 1] shl 16) + (PByteArray(Buffer)^[Offset + 2] shl 8) + PByteArray(Buffer)^[Offset + 3];

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsProtocolUtility.GetIPv6AddressFromPacket(Buffer: Pointer; Offset: Integer; BufferLen: Integer): TIPv6Address;

var
  IPv6Address: TIPv6Address;

begin

  Move(PByteArray(Buffer)^[Offset], IPv6Address, SizeOf(TIPv6Address)); Result := IPv6Address;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsProtocolUtility.GetStringFromPacket(Value: String; Buffer: Pointer; var OffsetL1: Integer; var OffsetLX: Integer; Level: Integer; BufferLen: Integer): String;

var
  Index: Integer;

begin

  if (OffsetLX < BufferLen) then begin

    if (PByteArray(Buffer)^[OffsetLX] > 0) then begin

      if ((PByteArray(Buffer)^[OffsetLX] and $C0) > 0) then begin

        if ((OffsetLX + 1) < BufferLen) then begin

          if (Level = 1) then Inc(OffsetL1, 2); OffsetLX := ((PByteArray(Buffer)^[OffsetLX] and $1F) shl 8) + PByteArray(Buffer)^[OffsetLX + 1];

          Value := TDnsProtocolUtility.GetStringFromPacket(Value, Buffer, OffsetL1, OffsetLX, Level + 1, BufferLen);

        end else begin

          if (Level = 1) then Inc(OffsetL1); Inc(OffsetLX);

        end;

      end else if ((OffsetLX + PByteArray(Buffer)^[OffsetLX] + 1) < BufferLen) then begin

        if (Value <> '') then Value := Value + '.';

        for Index := 1 to PByteArray(Buffer)^[OffsetLX] do Value := Value + Char(PByteArray(Buffer)^[OffsetLX + Index]);

        if (Level = 1) then Inc(OffsetL1, PByteArray(Buffer)^[OffsetLX] + 1); Inc(OffsetLX, PByteArray(Buffer)^[OffsetLX] + 1);

        Value := TDnsProtocolUtility.GetStringFromPacket(Value, Buffer, OffsetL1, OffsetLX, Level, BufferLen);

      end;

    end else begin

      if (Level = 1) then Inc(OffsetL1); Inc(OffsetLX);

    end;

  end;

  Result := Value;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsProtocolUtility.GetStringFromPacket(Buffer: Pointer; var OffsetL1: Integer; var OffsetLX: Integer; BufferLen: Integer): String;

begin

  Result := TDnsProtocolUtility.GetStringFromPacket('', Buffer, OffsetL1, OffsetLX, 1, BufferLen);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsProtocolUtility.GetStringFromPacket(Buffer: Pointer; var OffsetL1: Integer; BufferLen: Integer): String;

var
  OffsetLX: Integer;

begin

  OffsetLX := OffsetL1; Result := TDnsProtocolUtility.GetStringFromPacket(Buffer, OffsetL1, OffsetLX, BufferLen);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsProtocolUtility.SetStringIntoPacket(const Value: String; Buffer: Pointer; var Offset: Integer; BufferLen: Integer);

var
  PIndex: Integer; CIndex: Integer;

begin

  PIndex := 0;

  for CIndex := 1 to Length(Value) do begin

    if (Value[CIndex] <> '.') then begin

      PByteArray(Buffer)^[Offset + PIndex + 1] := Byte(Value[CIndex]); Inc(PIndex);

    end else begin

      PByteArray(Buffer)^[Offset] := PIndex; Inc(Offset, PIndex + 1); PIndex := 0;

    end;

  end;

  PByteArray(Buffer)^[Offset] := PIndex; Inc(Offset, PIndex + 1);

  PByteArray(Buffer)^[Offset] := $00; Inc(Offset);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsProtocolUtility.GetDomainNameAndQueryTypeFromRequestPacket(Buffer: Pointer; BufferLen: Integer; var DomainName: String; var QueryType: Word);

var
  OffsetL1: Integer;

begin

  OffsetL1 := $0C; DomainName := TDnsProtocolUtility.GetStringFromPacket(Buffer, OffsetL1, BufferLen); QueryType := TDnsProtocolUtility.GetWordFromPacket(Buffer, OffsetL1, BufferLen);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function  TDnsProtocolUtility.IsPrivateReverseLookup(const DomainName: String): Boolean;

var
  DomainNameLength: Integer; AddressText: String; AddressTextLength: Integer;

begin

  Result := False;

  DomainNameLength := Length(DomainName); if (DomainNameLength >= 20) and (DomainNameLength <= 28) then begin

    if CommonUtils.StringEndsWith(DomainName, DomainNameLength, '.in-addr.arpa', 13) then begin

      AddressText := Copy(DomainName, 1, DomainNameLength - 13); AddressTextLength := Length(AddressText);

      Result := CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.168.192', 8) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.254.169', 8) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.16.172', 7) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.17.172', 7) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.18.172', 7) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.19.172', 7) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.20.172', 7) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.21.172', 7) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.22.172', 7) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.23.172', 7) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.24.172', 7) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.25.172', 7) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.26.172', 7) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.27.172', 7) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.28.172', 7) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.29.172', 7) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.30.172', 7) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.31.172', 7) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.127', 4) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.10', 3) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.0', 2) or
                (AddressText = '255.255.255.255');

    end;

  end else if (DomainNameLength >= 72) then begin

    if CommonUtils.StringEndsWith(DomainName, DomainNameLength, '.ip6.arpa', 9) then begin

      AddressText := Copy(DomainName, 1, DomainNameLength - 9); AddressTextLength := Length(AddressText);

      Result := (AddressText = '1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0') or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.8.e.f', 6) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.9.e.f', 6) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.a.e.f', 6) or
                CommonUtils.StringEndsWith(AddressText, AddressTextLength, '.b.e.f', 6) or
                (AddressText = '0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0');

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsProtocolUtility.BuildNegativeResponsePacket(const DomainName: String; QueryType: Word; Buffer: Pointer; var BufferLen: Integer);

var
  Offset: Integer;

begin

  PByteArray(Buffer)^[$00] := $00;
  PByteArray(Buffer)^[$01] := $00;
  PByteArray(Buffer)^[$02] := $85;
  PByteArray(Buffer)^[$03] := $83;
  PByteArray(Buffer)^[$04] := $00;
  PByteArray(Buffer)^[$05] := $01;
  PByteArray(Buffer)^[$06] := $00;
  PByteArray(Buffer)^[$07] := $00;
  PByteArray(Buffer)^[$08] := $00;
  PByteArray(Buffer)^[$09] := $00;
  PByteArray(Buffer)^[$0A] := $00;
  PByteArray(Buffer)^[$0B] := $00;

  Offset := $0C;

  TDnsProtocolUtility.SetStringIntoPacket(DomainName, Buffer, Offset, BufferLen);

  PByteArray(Buffer)^[Offset] := QueryType shr $08; Inc(Offset);
  PByteArray(Buffer)^[Offset] := QueryType and $FF; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $01; Inc(Offset);

  BufferLen := Offset;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsProtocolUtility.BuildPositiveResponsePacket(const DomainName: String; QueryType: Word; Buffer: Pointer; var BufferLen: Integer);

var
  Offset: Integer;

begin

  PByteArray(Buffer)^[$00] := $00;
  PByteArray(Buffer)^[$01] := $00;
  PByteArray(Buffer)^[$02] := $85;
  PByteArray(Buffer)^[$03] := $80;
  PByteArray(Buffer)^[$04] := $00;
  PByteArray(Buffer)^[$05] := $01;
  PByteArray(Buffer)^[$06] := $00;
  PByteArray(Buffer)^[$07] := $00;
  PByteArray(Buffer)^[$08] := $00;
  PByteArray(Buffer)^[$09] := $00;
  PByteArray(Buffer)^[$0A] := $00;
  PByteArray(Buffer)^[$0B] := $00;

  Offset := $0C;

  TDnsProtocolUtility.SetStringIntoPacket(DomainName, Buffer, Offset, BufferLen);

  PByteArray(Buffer)^[Offset] := QueryType shr $08; Inc(Offset);
  PByteArray(Buffer)^[Offset] := QueryType and $FF; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $01; Inc(Offset);

  BufferLen := Offset;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsProtocolUtility.BuildPositiveIPv4ResponsePacket(const DomainName: String; QueryType: Word; HostAddress: TIPv4Address; TimeToLive: Integer; Buffer: Pointer; var BufferLen: Integer);

var
  Offset: Integer;

begin

  PByteArray(Buffer)^[$00] := $00;
  PByteArray(Buffer)^[$01] := $00;
  PByteArray(Buffer)^[$02] := $85;
  PByteArray(Buffer)^[$03] := $80;
  PByteArray(Buffer)^[$04] := $00;
  PByteArray(Buffer)^[$05] := $01;
  PByteArray(Buffer)^[$06] := $00;
  PByteArray(Buffer)^[$07] := $01;
  PByteArray(Buffer)^[$08] := $00;
  PByteArray(Buffer)^[$09] := $00;
  PByteArray(Buffer)^[$0A] := $00;
  PByteArray(Buffer)^[$0B] := $00;

  Offset := $0C;

  TDnsProtocolUtility.SetStringIntoPacket(DomainName, Buffer, Offset, BufferLen);

  PByteArray(Buffer)^[Offset] := QueryType shr $08; Inc(Offset);
  PByteArray(Buffer)^[Offset] := QueryType and $FF; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $01; Inc(Offset);

  PByteArray(Buffer)^[Offset] := $C0; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $0C; Inc(Offset);

  PByteArray(Buffer)^[Offset] := QueryType shr $08; Inc(Offset);
  PByteArray(Buffer)^[Offset] := QueryType and $FF; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $01; Inc(Offset);

  PByteArray(Buffer)^[Offset] := TimeToLive shr $18; Inc(Offset);
  PByteArray(Buffer)^[Offset] := TimeToLive shr $10 and $FF; Inc(Offset);
  PByteArray(Buffer)^[Offset] := TimeToLive shr $08 and $FF; Inc(Offset);
  PByteArray(Buffer)^[Offset] := TimeToLive and $FF; Inc(Offset);

  PByteArray(Buffer)^[Offset] := $00; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $04; Inc(Offset);

  Move(HostAddress, PByteArray(Buffer)^[Offset], 4); Inc(Offset, 4);

  BufferLen := Offset;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsProtocolUtility.BuildPositiveIPv6ResponsePacket(const DomainName: String; QueryType: Word; HostAddress: TIPv6Address; TimeToLive: Integer; Buffer: Pointer; var BufferLen: Integer);

var
  Offset: Integer;

begin

  PByteArray(Buffer)^[$00] := $00;
  PByteArray(Buffer)^[$01] := $00;
  PByteArray(Buffer)^[$02] := $85;
  PByteArray(Buffer)^[$03] := $80;
  PByteArray(Buffer)^[$04] := $00;
  PByteArray(Buffer)^[$05] := $01;
  PByteArray(Buffer)^[$06] := $00;
  PByteArray(Buffer)^[$07] := $01;
  PByteArray(Buffer)^[$08] := $00;
  PByteArray(Buffer)^[$09] := $00;
  PByteArray(Buffer)^[$0A] := $00;
  PByteArray(Buffer)^[$0B] := $00;

  Offset := $0C;

  TDnsProtocolUtility.SetStringIntoPacket(DomainName, Buffer, Offset, BufferLen);

  PByteArray(Buffer)^[Offset] := QueryType shr $08; Inc(Offset);
  PByteArray(Buffer)^[Offset] := QueryType and $FF; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $01; Inc(Offset);

  PByteArray(Buffer)^[Offset] := $C0; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $0C; Inc(Offset);

  PByteArray(Buffer)^[Offset] := QueryType shr $08; Inc(Offset);
  PByteArray(Buffer)^[Offset] := QueryType and $FF; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $01; Inc(Offset);

  PByteArray(Buffer)^[Offset] := TimeToLive shr $18; Inc(Offset);
  PByteArray(Buffer)^[Offset] := TimeToLive shr $10 and $FF; Inc(Offset);
  PByteArray(Buffer)^[Offset] := TimeToLive shr $08 and $FF; Inc(Offset);
  PByteArray(Buffer)^[Offset] := TimeToLive and $FF; Inc(Offset);

  PByteArray(Buffer)^[Offset] := $00; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $10; Inc(Offset);

  Move(HostAddress, PByteArray(Buffer)^[Offset], 16); Inc(Offset, 16);

  BufferLen := Offset;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsProtocolUtility.BuildPositiveResponsePacket(const DomainName: String; QueryType: Word; HostAddress: TDualIPAddress; TimeToLive: Integer; Buffer: Pointer; var BufferLen: Integer);

begin

  if HostAddress.IsIPv6Address then TDnsProtocolUtility.BuildPositiveIPv6ResponsePacket(DomainName, QueryType, HostAddress.IPv6Address, TimeToLive, Buffer, BufferLen) else TDnsProtocolUtility.BuildPositiveIPv4ResponsePacket(DomainName, QueryType, HostAddress.IPv4Address, TimeToLive, Buffer, BufferLen);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer: Pointer; BufferLen: Integer): String;

var
  Index: Integer;

begin

  Result := 'Z='; for Index := 0 to BufferLen - 1 do Result := Result + CommonUtils.ByteToHex2[PByteArray(Buffer)^[Index]];

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacketWithOffset(Buffer: Pointer; BufferLen: Integer; Offset: Integer; NumBytes: Integer): String;

var
  Index: Integer;

begin

  SetLength(Result, 0); for Index := Offset to Min(BufferLen - 1, Offset + NumBytes - 1) do Result := Result + CommonUtils.ByteToHex2[PByteArray(Buffer)^[Index]];

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsProtocolUtility.PrintRequestPacketDescriptionAsStringFromPacket(const DomainName: String; QueryType: Word; Buffer: Pointer; BufferLen: Integer; IncludePacketBytesAlways: Boolean): String;

begin

  if (IncludePacketBytesAlways) then Result := 'Q[1]=' + DomainName + ';T[1]=' + TDnsQueryTypeUtility.ToString(QueryType) + ';' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) else Result := 'Q[1]=' + DomainName + ';T[1]=' + TDnsQueryTypeUtility.ToString(QueryType);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsProtocolUtility.PrintResponsePacketDescriptionAsStringFromPacket(Buffer: Pointer; BufferLen: Integer; IncludePacketBytesAlways: Boolean): String;

var
  FValue: String; AValue: String; BValue: String; OffsetL1: Integer; RCode: Byte; QdCnt: Word; AnCnt: Word; Index: Integer; AnTyp: Word; AnDta: Word;

begin

  RCode := PByteArray(Buffer)^[$03] and $0F;

  QdCnt := TDnsProtocolUtility.GetWordFromPacket(Buffer, $04, BufferLen);
  AnCnt := TDnsProtocolUtility.GetWordFromPacket(Buffer, $06, BufferLen);

  FValue := 'RC=' + IntToStr(RCode) + ';QDC=' + IntToStr(QdCnt) + ';ANC=' + IntToStr(AnCnt);

  if (RCode = 0) and (QdCnt = 1) and (AnCnt > 0) then begin // We are only able to understand this

    OffsetL1 := $0C; AValue := TDnsProtocolUtility.GetStringFromPacket(Buffer, OffsetL1, BufferLen); Inc(OffsetL1, 4);

    FValue := FValue + ';' + 'Q[1]=' + AValue;

    for Index := 1 to AnCnt do begin

      if (OffsetL1 < BufferLen) then begin

        AValue := TDnsProtocolUtility.GetStringFromPacket(Buffer, OffsetL1, BufferLen);

        if ((OffsetL1 + 10) <= BufferLen) then begin

          AnTyp := TDnsProtocolUtility.GetWordFromPacket(Buffer, OffsetL1, BufferLen); Inc(OffsetL1, 8);
          AnDta := TDnsProtocolUtility.GetWordFromPacket(Buffer, OffsetL1, BufferLen); Inc(OffsetL1, 2);

          FValue := FValue + ';T[' + IntToStr(Index) + ']=' + TDnsQueryTypeUtility.ToString(AnTyp);

          if (AnDta > 0) then begin

            if ((OffsetL1 + AnDta) <= BufferLen) then begin

              case AnTyp of

                DNS_QUERY_TYPE_A:

                  if (AnDta = 4) then begin

                    BValue := TIPv4AddressUtility.ToString(TDnsProtocolUtility.GetIPv4AddressFromPacket(Buffer, OffsetL1, BufferLen));

                    FValue := FValue + ';A[' + IntToStr(Index) + ']=' + AValue + '>' + BValue;

                    Inc(OffsetL1, AnDta);

                  end else begin

                    FValue := FValue + ';A[' + IntToStr(Index) + ']=' + AValue + '>' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacketWithOffset(Buffer, BufferLen, OffsetL1, AnDta);

                    Inc(OffsetL1, AnDta);

                  end;

                DNS_QUERY_TYPE_AAAA:

                  if (AnDta = 16) then begin

                    BValue := TIPv6AddressUtility.ToString(TDnsProtocolUtility.GetIPv6AddressFromPacket(Buffer, OffsetL1, BufferLen));

                    FValue := FValue + ';A[' + IntToStr(Index) + ']=' + AValue + '>' + BValue;

                    Inc(OffsetL1, AnDta);

                  end else begin

                    FValue := FValue + ';A[' + IntToStr(Index) + ']=' + AValue + '>' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacketWithOffset(Buffer, BufferLen, OffsetL1, AnDta);

                    Inc(OffsetL1, AnDta);

                  end;

                DNS_QUERY_TYPE_CNAME,
                DNS_QUERY_TYPE_PTR:

                  begin

                    BValue := TDnsProtocolUtility.GetStringFromPacket(Buffer, OffsetL1, BufferLen);

                    FValue := FValue + ';A[' + IntToStr(Index) + ']=' + AValue + '>' + BValue;

                  end;

                else begin

                  FValue := FValue + ';A[' + IntToStr(Index) + ']=' + AValue + '>' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacketWithOffset(Buffer, BufferLen, OffsetL1, AnDta);

                  Inc(OffsetL1, AnDta);

                end;

              end;

            end else begin

              FValue := FValue + ';A[' + IntToStr(Index) + ']=' + AValue + '>NULL';

              Break;

            end;

          end else begin

            FValue := FValue + ';A[' + IntToStr(Index) + ']=' + AValue + '>NULL';

          end;

        end else begin

          Break;

        end;

      end else begin

        Break;

      end;

    end;

    if (IncludePacketBytesAlways) then Result := FValue + ';' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) else Result := FValue;

  end else begin

    Result := FValue + ';' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsProtocolUtility.IsFailureResponsePacket(Buffer: Pointer; BufferLen: Integer): Boolean;

var
  RCode: Byte;

begin

  RCode := PByteArray(Buffer)^[$03] and $0F; Result := not((RCode = 0) or (RCode = 3));

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsProtocolUtility.IsNegativeResponsePacket(Buffer: Pointer; BufferLen: Integer): Boolean;

var
  RCode: Byte;

begin

  RCode := PByteArray(Buffer)^[$03] and $0F; Result := (RCode = 3);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

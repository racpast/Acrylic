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
  DNS_QUERY_TYPE_MD         = $0003;
  DNS_QUERY_TYPE_MF         = $0004;
  DNS_QUERY_TYPE_CNAME      = $0005;
  DNS_QUERY_TYPE_SOA        = $0006;
  DNS_QUERY_TYPE_MB         = $0007;
  DNS_QUERY_TYPE_MG         = $0008;
  DNS_QUERY_TYPE_MR         = $0009;
  DNS_QUERY_TYPE_NULL       = $000A;
  DNS_QUERY_TYPE_WKS        = $000B;
  DNS_QUERY_TYPE_PTR        = $000C;
  DNS_QUERY_TYPE_HINFO      = $000D;
  DNS_QUERY_TYPE_MINFO      = $000E;
  DNS_QUERY_TYPE_MX         = $000F;
  DNS_QUERY_TYPE_TXT        = $0010;
  DNS_QUERY_TYPE_RP         = $0011;
  DNS_QUERY_TYPE_AFSDB      = $0012;
  DNS_QUERY_TYPE_X25        = $0013;
  DNS_QUERY_TYPE_ISDN       = $0014;
  DNS_QUERY_TYPE_RT         = $0015;
  DNS_QUERY_TYPE_NSAP       = $0016;
  DNS_QUERY_TYPE_NSAPPTR    = $0017;
  DNS_QUERY_TYPE_SIG        = $0018;
  DNS_QUERY_TYPE_KEY        = $0019;
  DNS_QUERY_TYPE_PX         = $001A;
  DNS_QUERY_TYPE_GPOS       = $001B;
  DNS_QUERY_TYPE_AAAA       = $001C;
  DNS_QUERY_TYPE_LOC        = $001D;
  DNS_QUERY_TYPE_NXT        = $001E;
  DNS_QUERY_TYPE_EID        = $001F;
  DNS_QUERY_TYPE_NIMLOC     = $0020;
  DNS_QUERY_TYPE_SRV        = $0021;
  DNS_QUERY_TYPE_ATMA       = $0022;
  DNS_QUERY_TYPE_NAPTR      = $0023;
  DNS_QUERY_TYPE_KX         = $0024;
  DNS_QUERY_TYPE_CERT       = $0025;
  DNS_QUERY_TYPE_A6         = $0026;
  DNS_QUERY_TYPE_DNAME      = $0027;
  DNS_QUERY_TYPE_SINK       = $0028;
  DNS_QUERY_TYPE_OPT        = $0029;
  DNS_QUERY_TYPE_APL        = $002A;
  DNS_QUERY_TYPE_DS         = $002B;
  DNS_QUERY_TYPE_SSHFP      = $002C;
  DNS_QUERY_TYPE_IPSECKEY   = $002D;
  DNS_QUERY_TYPE_RRSIG      = $002E;
  DNS_QUERY_TYPE_NSEC       = $002F;
  DNS_QUERY_TYPE_DNSKEY     = $0030;
  DNS_QUERY_TYPE_DHCID      = $0031;
  DNS_QUERY_TYPE_NSEC3      = $0032;
  DNS_QUERY_TYPE_NSEC3PARAM = $0033;
  DNS_QUERY_TYPE_TLSA       = $0034;
  DNS_QUERY_TYPE_HIP        = $0037;
  DNS_QUERY_TYPE_NINFO      = $0038;
  DNS_QUERY_TYPE_RKEY       = $0039;
  DNS_QUERY_TYPE_TALINK     = $003A;
  DNS_QUERY_TYPE_CDS        = $003B;
  DNS_QUERY_TYPE_CDNSKEY    = $003C;
  DNS_QUERY_TYPE_OPENPGPKEY = $003D;
  DNS_QUERY_TYPE_CSYNC      = $003E;
  DNS_QUERY_TYPE_SPF        = $0063;
  DNS_QUERY_TYPE_UINFO      = $0064;
  DNS_QUERY_TYPE_UID        = $0065;
  DNS_QUERY_TYPE_GID        = $0066;
  DNS_QUERY_TYPE_UNSPEC     = $0067;
  DNS_QUERY_TYPE_NID        = $0068;
  DNS_QUERY_TYPE_L32        = $0069;
  DNS_QUERY_TYPE_L64        = $006A;
  DNS_QUERY_TYPE_LP         = $006B;
  DNS_QUERY_TYPE_EUI48      = $006C;
  DNS_QUERY_TYPE_EUI64      = $006D;
  DNS_QUERY_TYPE_ADDRS      = $00F8;
  DNS_QUERY_TYPE_TKEY       = $00F9;
  DNS_QUERY_TYPE_TSIG       = $00FA;
  DNS_QUERY_TYPE_IXFR       = $00FB;
  DNS_QUERY_TYPE_AXFR       = $00FC;
  DNS_QUERY_TYPE_MAILB      = $00FD;
  DNS_QUERY_TYPE_MAILA      = $00FE;
  DNS_QUERY_TYPE_ALL        = $00FF;
  DNS_QUERY_TYPE_URI        = $0100;
  DNS_QUERY_TYPE_CAA        = $0101;
  DNS_QUERY_TYPE_TA         = $8000;
  DNS_QUERY_TYPE_DLV        = $8001;
  DNS_QUERY_TYPE_WINS       = $FF01;
  DNS_QUERY_TYPE_WINSR      = $FF02;

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
      class function Parse(Text: String): Word;
      class function ToString(Value: Word): String;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TDnsProtocolUtility = class
    public
      class function  ParseDnsProtocol(Text: String): TDnsProtocol;
    private
      class function  GetWordFromPacket(Buffer: Pointer; Offset: Integer; BufferLen: Integer): Word;
      class function  GetIPv4AddressFromPacket(Buffer: Pointer; Offset: Integer; BufferLen: Integer): TIPv4Address;
      class function  GetIPv6AddressFromPacket(Buffer: Pointer; Offset: Integer; BufferLen: Integer): TIPv6Address;
      class function  GetStringFromPacket(Value: String; Buffer: Pointer; var OffsetL1: Integer; var OffsetLX: Integer; Level: Integer; BufferLen: Integer): String; overload;
      class function  GetStringFromPacket(Buffer: Pointer; var OffsetL1: Integer; var OffsetLX: Integer; BufferLen: Integer): String; overload;
      class function  GetStringFromPacket(Buffer: Pointer; var OffsetL1: Integer; BufferLen: Integer): String; overload;
      class procedure SetStringIntoPacket(Value: String; Buffer: Pointer; var Offset: Integer; BufferLen: Integer);
    public
      class function  GetIdFromPacket(Buffer: Pointer): Word;
      class procedure SetIdIntoPacket(Value: Word; Buffer: Pointer);
    public
      class procedure GetDomainNameAndQueryTypeFromRequestPacket(Buffer: Pointer; BufferLen: Integer; var DomainName: String; var QueryType: Word);
    public
      class procedure BuildNegativeResponsePacket(DomainName: String; QueryType: Word; Buffer: Pointer; var BufferLen: Integer);
      class procedure BuildPositiveResponsePacket(DomainName: String; QueryType: Word; Buffer: Pointer; var BufferLen: Integer); overload;
      class procedure BuildPositiveResponsePacket(DomainName: String; QueryType: Word; HostAddress: TDualIPAddress; TimeToLive: Integer; Buffer: Pointer; var BufferLen: Integer); overload;
    public
      class procedure BuildPositiveIPv4ResponsePacket(DomainName: String; QueryType: Word; HostAddress: TIPv4Address; TimeToLive: Integer; Buffer: Pointer; var BufferLen: Integer);
      class procedure BuildPositiveIPv6ResponsePacket(DomainName: String; QueryType: Word; HostAddress: TIPv6Address; TimeToLive: Integer; Buffer: Pointer; var BufferLen: Integer);
    public
      class function  PrintGenericPacketBytesAsStringFromPacket(Buffer: Pointer; BufferLen: Integer): String;
      class function  PrintGenericPacketBytesAsStringFromPacketWithOffset(Buffer: Pointer; BufferLen: Integer; Offset: Integer; NumBytes: Integer): String;
    public
      class function  PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer: Pointer; BufferLen: Integer; IncludePacketBytesAlways: Boolean): String;
      class function  PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer: Pointer; BufferLen: Integer; IncludePacketBytesAlways: Boolean): String;
      class function  PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer: Pointer; BufferLen: Integer; IncludePacketBytesAlways: Boolean): String;
      class function  PrintResponsePacketDescriptionAsLegacyStringFromPacket(Buffer: Pointer; BufferLen: Integer; IncludePacketBytesAlways: Boolean): String;
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
  SysUtils;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsQueryTypeUtility.Parse(Text: String): Word;

begin

       if (Text = 'A'          ) then Result := DNS_QUERY_TYPE_A
  else if (Text = 'NS'         ) then Result := DNS_QUERY_TYPE_NS
  else if (Text = 'MD'         ) then Result := DNS_QUERY_TYPE_MD
  else if (Text = 'MF'         ) then Result := DNS_QUERY_TYPE_MF
  else if (Text = 'CNAME'      ) then Result := DNS_QUERY_TYPE_CNAME
  else if (Text = 'SOA'        ) then Result := DNS_QUERY_TYPE_SOA
  else if (Text = 'MB'         ) then Result := DNS_QUERY_TYPE_MB
  else if (Text = 'MG'         ) then Result := DNS_QUERY_TYPE_MG
  else if (Text = 'MR'         ) then Result := DNS_QUERY_TYPE_MR
  else if (Text = 'NULL'       ) then Result := DNS_QUERY_TYPE_NULL
  else if (Text = 'WKS'        ) then Result := DNS_QUERY_TYPE_WKS
  else if (Text = 'PTR'        ) then Result := DNS_QUERY_TYPE_PTR
  else if (Text = 'HINFO'      ) then Result := DNS_QUERY_TYPE_HINFO
  else if (Text = 'MINFO'      ) then Result := DNS_QUERY_TYPE_MINFO
  else if (Text = 'MX'         ) then Result := DNS_QUERY_TYPE_MX
  else if (Text = 'TXT'        ) then Result := DNS_QUERY_TYPE_TXT
  else if (Text = 'RP'         ) then Result := DNS_QUERY_TYPE_RP
  else if (Text = 'AFSDB'      ) then Result := DNS_QUERY_TYPE_AFSDB
  else if (Text = 'X25'        ) then Result := DNS_QUERY_TYPE_X25
  else if (Text = 'ISDN'       ) then Result := DNS_QUERY_TYPE_ISDN
  else if (Text = 'RT'         ) then Result := DNS_QUERY_TYPE_RT
  else if (Text = 'NSAP'       ) then Result := DNS_QUERY_TYPE_NSAP
  else if (Text = 'NSAPPTR'    ) then Result := DNS_QUERY_TYPE_NSAPPTR
  else if (Text = 'SIG'        ) then Result := DNS_QUERY_TYPE_SIG
  else if (Text = 'KEY'        ) then Result := DNS_QUERY_TYPE_KEY
  else if (Text = 'PX'         ) then Result := DNS_QUERY_TYPE_PX
  else if (Text = 'GPOS'       ) then Result := DNS_QUERY_TYPE_GPOS
  else if (Text = 'AAAA'       ) then Result := DNS_QUERY_TYPE_AAAA
  else if (Text = 'LOC'        ) then Result := DNS_QUERY_TYPE_LOC
  else if (Text = 'NXT'        ) then Result := DNS_QUERY_TYPE_NXT
  else if (Text = 'EID'        ) then Result := DNS_QUERY_TYPE_EID
  else if (Text = 'NIMLOC'     ) then Result := DNS_QUERY_TYPE_NIMLOC
  else if (Text = 'SRV'        ) then Result := DNS_QUERY_TYPE_SRV
  else if (Text = 'ATMA'       ) then Result := DNS_QUERY_TYPE_ATMA
  else if (Text = 'NAPTR'      ) then Result := DNS_QUERY_TYPE_NAPTR
  else if (Text = 'KX'         ) then Result := DNS_QUERY_TYPE_KX
  else if (Text = 'CERT'       ) then Result := DNS_QUERY_TYPE_CERT
  else if (Text = 'A6'         ) then Result := DNS_QUERY_TYPE_A6
  else if (Text = 'DNAME'      ) then Result := DNS_QUERY_TYPE_DNAME
  else if (Text = 'SINK'       ) then Result := DNS_QUERY_TYPE_SINK
  else if (Text = 'OPT'        ) then Result := DNS_QUERY_TYPE_OPT
  else if (Text = 'APL'        ) then Result := DNS_QUERY_TYPE_APL
  else if (Text = 'DS'         ) then Result := DNS_QUERY_TYPE_DS
  else if (Text = 'SSHFP'      ) then Result := DNS_QUERY_TYPE_SSHFP
  else if (Text = 'IPSECKEY'   ) then Result := DNS_QUERY_TYPE_IPSECKEY
  else if (Text = 'RRSIG'      ) then Result := DNS_QUERY_TYPE_RRSIG
  else if (Text = 'NSEC'       ) then Result := DNS_QUERY_TYPE_NSEC
  else if (Text = 'DNSKEY'     ) then Result := DNS_QUERY_TYPE_DNSKEY
  else if (Text = 'DHCID'      ) then Result := DNS_QUERY_TYPE_DHCID
  else if (Text = 'NSEC3'      ) then Result := DNS_QUERY_TYPE_NSEC3
  else if (Text = 'NSEC3PARAM' ) then Result := DNS_QUERY_TYPE_NSEC3PARAM
  else if (Text = 'TLSA'       ) then Result := DNS_QUERY_TYPE_TLSA
  else if (Text = 'HIP'        ) then Result := DNS_QUERY_TYPE_HIP
  else if (Text = 'NINFO'      ) then Result := DNS_QUERY_TYPE_NINFO
  else if (Text = 'RKEY'       ) then Result := DNS_QUERY_TYPE_RKEY
  else if (Text = 'TALINK'     ) then Result := DNS_QUERY_TYPE_TALINK
  else if (Text = 'CDS'        ) then Result := DNS_QUERY_TYPE_CDS
  else if (Text = 'CDNSKEY'    ) then Result := DNS_QUERY_TYPE_CDNSKEY
  else if (Text = 'OPENPGPKEY' ) then Result := DNS_QUERY_TYPE_OPENPGPKEY
  else if (Text = 'CSYNC'      ) then Result := DNS_QUERY_TYPE_CSYNC
  else if (Text = 'SPF'        ) then Result := DNS_QUERY_TYPE_SPF
  else if (Text = 'UINFO'      ) then Result := DNS_QUERY_TYPE_UINFO
  else if (Text = 'UID'        ) then Result := DNS_QUERY_TYPE_UID
  else if (Text = 'GID'        ) then Result := DNS_QUERY_TYPE_GID
  else if (Text = 'UNSPEC'     ) then Result := DNS_QUERY_TYPE_UNSPEC
  else if (Text = 'NID'        ) then Result := DNS_QUERY_TYPE_NID
  else if (Text = 'L32'        ) then Result := DNS_QUERY_TYPE_L32
  else if (Text = 'L64'        ) then Result := DNS_QUERY_TYPE_L64
  else if (Text = 'LP'         ) then Result := DNS_QUERY_TYPE_LP
  else if (Text = 'EUI48'      ) then Result := DNS_QUERY_TYPE_EUI48
  else if (Text = 'EUI64'      ) then Result := DNS_QUERY_TYPE_EUI64
  else if (Text = 'ADDRS'      ) then Result := DNS_QUERY_TYPE_ADDRS
  else if (Text = 'TKEY'       ) then Result := DNS_QUERY_TYPE_TKEY
  else if (Text = 'TSIG'       ) then Result := DNS_QUERY_TYPE_TSIG
  else if (Text = 'IXFR'       ) then Result := DNS_QUERY_TYPE_IXFR
  else if (Text = 'AXFR'       ) then Result := DNS_QUERY_TYPE_AXFR
  else if (Text = 'MAILB'      ) then Result := DNS_QUERY_TYPE_MAILB
  else if (Text = 'MAILA'      ) then Result := DNS_QUERY_TYPE_MAILA
  else if (Text = 'ALL'        ) then Result := DNS_QUERY_TYPE_ALL
  else if (Text = 'URI'        ) then Result := DNS_QUERY_TYPE_URI
  else if (Text = 'CAA'        ) then Result := DNS_QUERY_TYPE_CAA
  else if (Text = 'TA'         ) then Result := DNS_QUERY_TYPE_TA
  else if (Text = 'DLV'        ) then Result := DNS_QUERY_TYPE_DLV
  else if (Text = 'WINS'       ) then Result := DNS_QUERY_TYPE_WINS
  else if (Text = 'WINSR'      ) then Result := DNS_QUERY_TYPE_WINSR
  else                                Result := 0;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsQueryTypeUtility.ToString(Value: Word): String;

begin

  case Value of
    DNS_QUERY_TYPE_A          : Result := 'A';
    DNS_QUERY_TYPE_NS         : Result := 'NS';
    DNS_QUERY_TYPE_MD         : Result := 'MD';
    DNS_QUERY_TYPE_MF         : Result := 'MF';
    DNS_QUERY_TYPE_CNAME      : Result := 'CNAME';
    DNS_QUERY_TYPE_SOA        : Result := 'SOA';
    DNS_QUERY_TYPE_MB         : Result := 'MB';
    DNS_QUERY_TYPE_MG         : Result := 'MG';
    DNS_QUERY_TYPE_MR         : Result := 'MR';
    DNS_QUERY_TYPE_NULL       : Result := 'NULL';
    DNS_QUERY_TYPE_WKS        : Result := 'WKS';
    DNS_QUERY_TYPE_PTR        : Result := 'PTR';
    DNS_QUERY_TYPE_HINFO      : Result := 'HINFO';
    DNS_QUERY_TYPE_MINFO      : Result := 'MINFO';
    DNS_QUERY_TYPE_MX         : Result := 'MX';
    DNS_QUERY_TYPE_TXT        : Result := 'TXT';
    DNS_QUERY_TYPE_RP         : Result := 'RP';
    DNS_QUERY_TYPE_AFSDB      : Result := 'AFSDB';
    DNS_QUERY_TYPE_X25        : Result := 'X25';
    DNS_QUERY_TYPE_ISDN       : Result := 'ISDN';
    DNS_QUERY_TYPE_RT         : Result := 'RT';
    DNS_QUERY_TYPE_NSAP       : Result := 'NSAP';
    DNS_QUERY_TYPE_NSAPPTR    : Result := 'NSAPPTR';
    DNS_QUERY_TYPE_SIG        : Result := 'SIG';
    DNS_QUERY_TYPE_KEY        : Result := 'KEY';
    DNS_QUERY_TYPE_PX         : Result := 'PX';
    DNS_QUERY_TYPE_GPOS       : Result := 'GPOS';
    DNS_QUERY_TYPE_AAAA       : Result := 'AAAA';
    DNS_QUERY_TYPE_LOC        : Result := 'LOC';
    DNS_QUERY_TYPE_NXT        : Result := 'NXT';
    DNS_QUERY_TYPE_EID        : Result := 'EID';
    DNS_QUERY_TYPE_NIMLOC     : Result := 'NIMLOC';
    DNS_QUERY_TYPE_SRV        : Result := 'SRV';
    DNS_QUERY_TYPE_ATMA       : Result := 'ATMA';
    DNS_QUERY_TYPE_NAPTR      : Result := 'NAPTR';
    DNS_QUERY_TYPE_KX         : Result := 'KX';
    DNS_QUERY_TYPE_CERT       : Result := 'CERT';
    DNS_QUERY_TYPE_A6         : Result := 'A6';
    DNS_QUERY_TYPE_DNAME      : Result := 'DNAME';
    DNS_QUERY_TYPE_SINK       : Result := 'SINK';
    DNS_QUERY_TYPE_OPT        : Result := 'OPT';
    DNS_QUERY_TYPE_APL        : Result := 'APL';
    DNS_QUERY_TYPE_DS         : Result := 'DS';
    DNS_QUERY_TYPE_SSHFP      : Result := 'SSHFP';
    DNS_QUERY_TYPE_IPSECKEY   : Result := 'IPSECKEY';
    DNS_QUERY_TYPE_RRSIG      : Result := 'RRSIG';
    DNS_QUERY_TYPE_NSEC       : Result := 'NSEC';
    DNS_QUERY_TYPE_DNSKEY     : Result := 'DNSKEY';
    DNS_QUERY_TYPE_DHCID      : Result := 'DHCID';
    DNS_QUERY_TYPE_NSEC3      : Result := 'NSEC3';
    DNS_QUERY_TYPE_NSEC3PARAM : Result := 'NSEC3PARAM';
    DNS_QUERY_TYPE_TLSA       : Result := 'TLSA';
    DNS_QUERY_TYPE_HIP        : Result := 'HIP';
    DNS_QUERY_TYPE_NINFO      : Result := 'NINFO';
    DNS_QUERY_TYPE_RKEY       : Result := 'RKEY';
    DNS_QUERY_TYPE_TALINK     : Result := 'TALINK';
    DNS_QUERY_TYPE_CDS        : Result := 'CDS';
    DNS_QUERY_TYPE_CDNSKEY    : Result := 'CDNSKEY';
    DNS_QUERY_TYPE_OPENPGPKEY : Result := 'OPENPGPKEY';
    DNS_QUERY_TYPE_CSYNC      : Result := 'CSYNC';
    DNS_QUERY_TYPE_SPF        : Result := 'SPF';
    DNS_QUERY_TYPE_UINFO      : Result := 'UINFO';
    DNS_QUERY_TYPE_UID        : Result := 'UID';
    DNS_QUERY_TYPE_GID        : Result := 'GID';
    DNS_QUERY_TYPE_UNSPEC     : Result := 'UNSPEC';
    DNS_QUERY_TYPE_NID        : Result := 'NID';
    DNS_QUERY_TYPE_L32        : Result := 'L32';
    DNS_QUERY_TYPE_L64        : Result := 'L64';
    DNS_QUERY_TYPE_LP         : Result := 'LP';
    DNS_QUERY_TYPE_EUI48      : Result := 'EUI48';
    DNS_QUERY_TYPE_EUI64      : Result := 'EUI64';
    DNS_QUERY_TYPE_ADDRS      : Result := 'ADDRS';
    DNS_QUERY_TYPE_TKEY       : Result := 'TKEY';
    DNS_QUERY_TYPE_TSIG       : Result := 'TSIG';
    DNS_QUERY_TYPE_IXFR       : Result := 'IXFR';
    DNS_QUERY_TYPE_AXFR       : Result := 'AXFR';
    DNS_QUERY_TYPE_MAILB      : Result := 'MAILB';
    DNS_QUERY_TYPE_MAILA      : Result := 'MAILA';
    DNS_QUERY_TYPE_ALL        : Result := 'ALL';
    DNS_QUERY_TYPE_URI        : Result := 'URI';
    DNS_QUERY_TYPE_CAA        : Result := 'CAA';
    DNS_QUERY_TYPE_TA         : Result := 'TA';
    DNS_QUERY_TYPE_DLV        : Result := 'DLV';
    DNS_QUERY_TYPE_WINS       : Result := 'WINS';
    DNS_QUERY_TYPE_WINSR      : Result := 'WINSR';
    else                        Result := IntToStr(Value);
  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsProtocolUtility.ParseDnsProtocol(Text: String): TDnsProtocol;

var
  InvariantText: String;

begin

  InvariantText := UpperCase(Text); if (InvariantText = 'SOCKS5') then Result := Socks5Protocol else if (InvariantText = 'TCP') then Result := TcpProtocol else Result := UdpProtocol;

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

  end; Result := Value;

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

class procedure TDnsProtocolUtility.SetStringIntoPacket(Value: String; Buffer: Pointer; var Offset: Integer; BufferLen: Integer);

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

  PByteArray(Buffer)^[Offset] := $00;

  Inc(Offset);

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

class procedure TDnsProtocolUtility.BuildNegativeResponsePacket(DomainName: String; QueryType: Word; Buffer: Pointer; var BufferLen: Integer);

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
  PByteArray(Buffer)^[Offset] := QueryType and $ff; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $01; Inc(Offset);

  BufferLen := Offset;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsProtocolUtility.BuildPositiveResponsePacket(DomainName: String; QueryType: Word; Buffer: Pointer; var BufferLen: Integer);

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
  PByteArray(Buffer)^[Offset] := QueryType and $ff; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $01; Inc(Offset);

  BufferLen := Offset;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsProtocolUtility.BuildPositiveIPv4ResponsePacket(DomainName: String; QueryType: Word; HostAddress: TIPv4Address; TimeToLive: Integer; Buffer: Pointer; var BufferLen: Integer);

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
  PByteArray(Buffer)^[Offset] := QueryType and $ff; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $01; Inc(Offset);

  PByteArray(Buffer)^[Offset] := $C0; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $0C; Inc(Offset);

  PByteArray(Buffer)^[Offset] := QueryType shr $08; Inc(Offset);
  PByteArray(Buffer)^[Offset] := QueryType and $ff; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $01; Inc(Offset);

  PByteArray(Buffer)^[Offset] := TimeToLive shr $18; Inc(Offset);
  PByteArray(Buffer)^[Offset] := TimeToLive shr $10 and $ff; Inc(Offset);
  PByteArray(Buffer)^[Offset] := TimeToLive shr $08 and $ff; Inc(Offset);
  PByteArray(Buffer)^[Offset] := TimeToLive and $ff; Inc(Offset);

  PByteArray(Buffer)^[Offset] := $00; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $04; Inc(Offset);

  Move(HostAddress, PByteArray(Buffer)^[Offset], 4); Inc(Offset, 4);

  BufferLen := Offset;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsProtocolUtility.BuildPositiveIPv6ResponsePacket(DomainName: String; QueryType: Word; HostAddress: TIPv6Address; TimeToLive: Integer; Buffer: Pointer; var BufferLen: Integer);

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
  PByteArray(Buffer)^[Offset] := QueryType and $ff; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $01; Inc(Offset);

  PByteArray(Buffer)^[Offset] := $C0; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $0C; Inc(Offset);

  PByteArray(Buffer)^[Offset] := QueryType shr $08; Inc(Offset);
  PByteArray(Buffer)^[Offset] := QueryType and $ff; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $00; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $01; Inc(Offset);

  PByteArray(Buffer)^[Offset] := TimeToLive shr $18; Inc(Offset);
  PByteArray(Buffer)^[Offset] := TimeToLive shr $10 and $ff; Inc(Offset);
  PByteArray(Buffer)^[Offset] := TimeToLive shr $08 and $ff; Inc(Offset);
  PByteArray(Buffer)^[Offset] := TimeToLive and $ff; Inc(Offset);

  PByteArray(Buffer)^[Offset] := $00; Inc(Offset);
  PByteArray(Buffer)^[Offset] := $10; Inc(Offset);

  Move(HostAddress, PByteArray(Buffer)^[Offset], 16); Inc(Offset, 16);

  BufferLen := Offset;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class procedure TDnsProtocolUtility.BuildPositiveResponsePacket(DomainName: String; QueryType: Word; HostAddress: TDualIPAddress; TimeToLive: Integer; Buffer: Pointer; var BufferLen: Integer);

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

  Result := 'Z='; for Index := 0 to BufferLen - 1 do Result := Result + IntToHex(PByteArray(Buffer)^[Index], 2);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacketWithOffset(Buffer: Pointer; BufferLen: Integer; Offset: Integer; NumBytes: Integer): String;

var
  Index: Integer;

begin

  SetLength(Result, 0); for Index := Offset to Min(BufferLen - 1, Offset + NumBytes - 1) do Result := Result + IntToHex(PByteArray(Buffer)^[Index], 2);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsProtocolUtility.PrintRequestPacketDescriptionAsNormalStringFromPacket(Buffer: Pointer; BufferLen: Integer; IncludePacketBytesAlways: Boolean): String;

var
  DomainName: String; QueryType: Word;

begin

  TDnsProtocolUtility.GetDomainNameAndQueryTypeFromRequestPacket(Buffer, BufferLen, DomainName, QueryType);

  if (IncludePacketBytesAlways) then Result := 'Q[1]=' + DomainName + ';T[1]=' + TDnsQueryTypeUtility.ToString(QueryType) + ';' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen) else Result := 'Q[1]=' + DomainName + ';T[1]=' + TDnsQueryTypeUtility.ToString(QueryType);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsProtocolUtility.PrintResponsePacketDescriptionAsNormalStringFromPacket(Buffer: Pointer; BufferLen: Integer; IncludePacketBytesAlways: Boolean): String;

var
  FValue: String; AValue: String; BValue: String; OffsetL1: Integer; RCode: Byte; QdCnt: Word; AnCnt: Word; Index: Integer; AnTyp: Word; AnDta: Word;

begin

  RCode := PByteArray(Buffer)^[$03] and $0f;

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

class function TDnsProtocolUtility.PrintRequestPacketDescriptionAsLegacyStringFromPacket(Buffer: Pointer; BufferLen: Integer; IncludePacketBytesAlways: Boolean): String;

var
  DomainName: String; QueryType: Word;

begin

  TDnsProtocolUtility.GetDomainNameAndQueryTypeFromRequestPacket(Buffer, BufferLen, DomainName, QueryType); Result := DomainName;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsProtocolUtility.PrintResponsePacketDescriptionAsLegacyStringFromPacket(Buffer: Pointer; BufferLen: Integer; IncludePacketBytesAlways: Boolean): String;

var
  FValue: String; AValue: String; BValue: String; OffsetL1: Integer; RCode: Byte; QdCnt: Word; AnCnt: Word; Index: Integer; AnTyp: Word; AnDta: Word;

begin

  RCode := PByteArray(Buffer)^[$03] and $0f;

  QdCnt := TDnsProtocolUtility.GetWordFromPacket(Buffer, $04, BufferLen);
  AnCnt := TDnsProtocolUtility.GetWordFromPacket(Buffer, $06, BufferLen);

  if (RCode = 0) and (QdCnt = 1) and (AnCnt > 0) then begin // We are only able to understand this

    SetLength(FValue, 0);

    OffsetL1 := $0C; AValue := TDnsProtocolUtility.GetStringFromPacket(Buffer, OffsetL1, BufferLen); Inc(OffsetL1, 4);

    FValue := 'Q=' + AValue;

    for Index := 1 to AnCnt do begin

      if (OffsetL1 < BufferLen) then begin

        AValue := TDnsProtocolUtility.GetStringFromPacket(Buffer, OffsetL1, BufferLen);

        if ((OffsetL1 + 10) <= BufferLen) then begin

          AnTyp := TDnsProtocolUtility.GetWordFromPacket(Buffer, OffsetL1, BufferLen); Inc(OffsetL1, 8);
          AnDta := TDnsProtocolUtility.GetWordFromPacket(Buffer, OffsetL1, BufferLen); Inc(OffsetL1, 2);

          if (AnDta > 0) and ((OffsetL1 + AnDta) <= BufferLen) then begin

            case AnTyp of

              DNS_QUERY_TYPE_A:

                if (AnDta = 4) then begin

                  BValue := TIPv4AddressUtility.ToString(TDnsProtocolUtility.GetIPv4AddressFromPacket(Buffer, OffsetL1, BufferLen));

                  FValue := FValue + ';A=' + AValue + '>' + BValue;

                end else begin

                  FValue := FValue + ';A=' + AValue + '>' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacketWithOffset(Buffer, BufferLen, OffsetL1, AnDta);

                end;

              else

                FValue := FValue + ';A=' + AValue + '>' + TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacketWithOffset(Buffer, BufferLen, OffsetL1, AnDta);

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

    Result := TDnsProtocolUtility.PrintGenericPacketBytesAsStringFromPacket(Buffer, BufferLen);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsProtocolUtility.IsFailureResponsePacket(Buffer: Pointer; BufferLen: Integer): Boolean;

var
  RCode: Byte;

begin

  RCode := PByteArray(Buffer)^[$03] and $0f; Result := not((RCode = 0) or (RCode = 3));

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDnsProtocolUtility.IsNegativeResponsePacket(Buffer: Pointer; BufferLen: Integer): Boolean;

var
  RCode: Byte;

begin

  RCode := PByteArray(Buffer)^[$03] and $0f; Result := (RCode = 3);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

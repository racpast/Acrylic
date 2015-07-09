// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  QueryTypeUtils;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  QUERY_TYPE_A          = $0001;
  QUERY_TYPE_NS         = $0002;
  QUERY_TYPE_MD         = $0003;
  QUERY_TYPE_MF         = $0004;
  QUERY_TYPE_CNAME      = $0005;
  QUERY_TYPE_SOA        = $0006;
  QUERY_TYPE_MB         = $0007;
  QUERY_TYPE_MG         = $0008;
  QUERY_TYPE_MR         = $0009;
  QUERY_TYPE_NULL       = $000A;
  QUERY_TYPE_WKS        = $000B;
  QUERY_TYPE_PTR        = $000C;
  QUERY_TYPE_HINFO      = $000D;
  QUERY_TYPE_MINFO      = $000E;
  QUERY_TYPE_MX         = $000F;
  QUERY_TYPE_TXT        = $0010;
  QUERY_TYPE_RP         = $0011;
  QUERY_TYPE_AFSDB      = $0012;
  QUERY_TYPE_X25        = $0013;
  QUERY_TYPE_ISDN       = $0014;
  QUERY_TYPE_RT         = $0015;
  QUERY_TYPE_NSAP       = $0016;
  QUERY_TYPE_NSAPPTR    = $0017;
  QUERY_TYPE_SIG        = $0018;
  QUERY_TYPE_KEY        = $0019;
  QUERY_TYPE_PX         = $001A;
  QUERY_TYPE_GPOS       = $001B;
  QUERY_TYPE_AAAA       = $001C;
  QUERY_TYPE_LOC        = $001D;
  QUERY_TYPE_NXT        = $001E;
  QUERY_TYPE_EID        = $001F;
  QUERY_TYPE_NIMLOC     = $0020;
  QUERY_TYPE_SRV        = $0021;
  QUERY_TYPE_ATMA       = $0022;
  QUERY_TYPE_NAPTR      = $0023;
  QUERY_TYPE_KX         = $0024;
  QUERY_TYPE_CERT       = $0025;
  QUERY_TYPE_A6         = $0026;
  QUERY_TYPE_DNAME      = $0027;
  QUERY_TYPE_SINK       = $0028;
  QUERY_TYPE_OPT        = $0029;
  QUERY_TYPE_APL        = $002A;
  QUERY_TYPE_DS         = $002B;
  QUERY_TYPE_SSHFP      = $002C;
  QUERY_TYPE_IPSECKEY   = $002D;
  QUERY_TYPE_RRSIG      = $002E;
  QUERY_TYPE_NSEC       = $002F;
  QUERY_TYPE_DNSKEY     = $0030;
  QUERY_TYPE_DHCID      = $0031;
  QUERY_TYPE_NSEC3      = $0032;
  QUERY_TYPE_NSEC3PARAM = $0033;
  QUERY_TYPE_TLSA       = $0034;
  QUERY_TYPE_HIP        = $0037;
  QUERY_TYPE_NINFO      = $0038;
  QUERY_TYPE_RKEY       = $0039;
  QUERY_TYPE_TALINK     = $003A;
  QUERY_TYPE_CDS        = $003B;
  QUERY_TYPE_CDNSKEY    = $003C;
  QUERY_TYPE_OPENPGPKEY = $003D;
  QUERY_TYPE_CSYNC      = $003E;
  QUERY_TYPE_SPF        = $0063;
  QUERY_TYPE_UINFO      = $0064;
  QUERY_TYPE_UID        = $0065;
  QUERY_TYPE_GID        = $0066;
  QUERY_TYPE_UNSPEC     = $0067;
  QUERY_TYPE_NID        = $0068;
  QUERY_TYPE_L32        = $0069;
  QUERY_TYPE_L64        = $006A;
  QUERY_TYPE_LP         = $006B;
  QUERY_TYPE_EUI48      = $006C;
  QUERY_TYPE_EUI64      = $006D;
  QUERY_TYPE_ADDRS      = $00F8;
  QUERY_TYPE_TKEY       = $00F9;
  QUERY_TYPE_TSIG       = $00FA;
  QUERY_TYPE_IXFR       = $00FB;
  QUERY_TYPE_AXFR       = $00FC;
  QUERY_TYPE_MAILB      = $00FD;
  QUERY_TYPE_MAILA      = $00FE;
  QUERY_TYPE_ALL        = $00FF;
  QUERY_TYPE_URI        = $0100;
  QUERY_TYPE_CAA        = $0101;
  QUERY_TYPE_TA         = $8000;
  QUERY_TYPE_DLV        = $8001;
  QUERY_TYPE_WINS       = $FF01;
  QUERY_TYPE_WINSR      = $FF02;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TQueryTypeUtils = class
    public
      class function Parse(Text: String): Word;
      class function ToString(Value: Word): String;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SysUtils, WinSock;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TQueryTypeUtils.Parse(Text: String): Word;
begin
       if (Text = 'A'          ) then Result := QUERY_TYPE_A
  else if (Text = 'NS'         ) then Result := QUERY_TYPE_NS
  else if (Text = 'MD'         ) then Result := QUERY_TYPE_MD
  else if (Text = 'MF'         ) then Result := QUERY_TYPE_MF
  else if (Text = 'CNAME'      ) then Result := QUERY_TYPE_CNAME
  else if (Text = 'SOA'        ) then Result := QUERY_TYPE_SOA
  else if (Text = 'MB'         ) then Result := QUERY_TYPE_MB
  else if (Text = 'MG'         ) then Result := QUERY_TYPE_MG
  else if (Text = 'MR'         ) then Result := QUERY_TYPE_MR
  else if (Text = 'NULL'       ) then Result := QUERY_TYPE_NULL
  else if (Text = 'WKS'        ) then Result := QUERY_TYPE_WKS
  else if (Text = 'PTR'        ) then Result := QUERY_TYPE_PTR
  else if (Text = 'HINFO'      ) then Result := QUERY_TYPE_HINFO
  else if (Text = 'MINFO'      ) then Result := QUERY_TYPE_MINFO
  else if (Text = 'MX'         ) then Result := QUERY_TYPE_MX
  else if (Text = 'TXT'        ) then Result := QUERY_TYPE_TXT
  else if (Text = 'RP'         ) then Result := QUERY_TYPE_RP
  else if (Text = 'AFSDB'      ) then Result := QUERY_TYPE_AFSDB
  else if (Text = 'X25'        ) then Result := QUERY_TYPE_X25
  else if (Text = 'ISDN'       ) then Result := QUERY_TYPE_ISDN
  else if (Text = 'RT'         ) then Result := QUERY_TYPE_RT
  else if (Text = 'NSAP'       ) then Result := QUERY_TYPE_NSAP
  else if (Text = 'NSAPPTR'    ) then Result := QUERY_TYPE_NSAPPTR
  else if (Text = 'SIG'        ) then Result := QUERY_TYPE_SIG
  else if (Text = 'KEY'        ) then Result := QUERY_TYPE_KEY
  else if (Text = 'PX'         ) then Result := QUERY_TYPE_PX
  else if (Text = 'GPOS'       ) then Result := QUERY_TYPE_GPOS
  else if (Text = 'AAAA'       ) then Result := QUERY_TYPE_AAAA
  else if (Text = 'LOC'        ) then Result := QUERY_TYPE_LOC
  else if (Text = 'NXT'        ) then Result := QUERY_TYPE_NXT
  else if (Text = 'EID'        ) then Result := QUERY_TYPE_EID
  else if (Text = 'NIMLOC'     ) then Result := QUERY_TYPE_NIMLOC
  else if (Text = 'SRV'        ) then Result := QUERY_TYPE_SRV
  else if (Text = 'ATMA'       ) then Result := QUERY_TYPE_ATMA
  else if (Text = 'NAPTR'      ) then Result := QUERY_TYPE_NAPTR
  else if (Text = 'KX'         ) then Result := QUERY_TYPE_KX
  else if (Text = 'CERT'       ) then Result := QUERY_TYPE_CERT
  else if (Text = 'A6'         ) then Result := QUERY_TYPE_A6
  else if (Text = 'DNAME'      ) then Result := QUERY_TYPE_DNAME
  else if (Text = 'SINK'       ) then Result := QUERY_TYPE_SINK
  else if (Text = 'OPT'        ) then Result := QUERY_TYPE_OPT
  else if (Text = 'APL'        ) then Result := QUERY_TYPE_APL
  else if (Text = 'DS'         ) then Result := QUERY_TYPE_DS
  else if (Text = 'SSHFP'      ) then Result := QUERY_TYPE_SSHFP
  else if (Text = 'IPSECKEY'   ) then Result := QUERY_TYPE_IPSECKEY
  else if (Text = 'RRSIG'      ) then Result := QUERY_TYPE_RRSIG
  else if (Text = 'NSEC'       ) then Result := QUERY_TYPE_NSEC
  else if (Text = 'DNSKEY'     ) then Result := QUERY_TYPE_DNSKEY
  else if (Text = 'DHCID'      ) then Result := QUERY_TYPE_DHCID
  else if (Text = 'NSEC3'      ) then Result := QUERY_TYPE_NSEC3
  else if (Text = 'NSEC3PARAM' ) then Result := QUERY_TYPE_NSEC3PARAM
  else if (Text = 'TLSA'       ) then Result := QUERY_TYPE_TLSA
  else if (Text = 'HIP'        ) then Result := QUERY_TYPE_HIP
  else if (Text = 'NINFO'      ) then Result := QUERY_TYPE_NINFO
  else if (Text = 'RKEY'       ) then Result := QUERY_TYPE_RKEY
  else if (Text = 'TALINK'     ) then Result := QUERY_TYPE_TALINK
  else if (Text = 'CDS'        ) then Result := QUERY_TYPE_CDS
  else if (Text = 'CDNSKEY'    ) then Result := QUERY_TYPE_CDNSKEY
  else if (Text = 'OPENPGPKEY' ) then Result := QUERY_TYPE_OPENPGPKEY
  else if (Text = 'CSYNC'      ) then Result := QUERY_TYPE_CSYNC
  else if (Text = 'SPF'        ) then Result := QUERY_TYPE_SPF
  else if (Text = 'UINFO'      ) then Result := QUERY_TYPE_UINFO
  else if (Text = 'UID'        ) then Result := QUERY_TYPE_UID
  else if (Text = 'GID'        ) then Result := QUERY_TYPE_GID
  else if (Text = 'UNSPEC'     ) then Result := QUERY_TYPE_UNSPEC
  else if (Text = 'NID'        ) then Result := QUERY_TYPE_NID
  else if (Text = 'L32'        ) then Result := QUERY_TYPE_L32
  else if (Text = 'L64'        ) then Result := QUERY_TYPE_L64
  else if (Text = 'LP'         ) then Result := QUERY_TYPE_LP
  else if (Text = 'EUI48'      ) then Result := QUERY_TYPE_EUI48
  else if (Text = 'EUI64'      ) then Result := QUERY_TYPE_EUI64
  else if (Text = 'ADDRS'      ) then Result := QUERY_TYPE_ADDRS
  else if (Text = 'TKEY'       ) then Result := QUERY_TYPE_TKEY
  else if (Text = 'TSIG'       ) then Result := QUERY_TYPE_TSIG
  else if (Text = 'IXFR'       ) then Result := QUERY_TYPE_IXFR
  else if (Text = 'AXFR'       ) then Result := QUERY_TYPE_AXFR
  else if (Text = 'MAILB'      ) then Result := QUERY_TYPE_MAILB
  else if (Text = 'MAILA'      ) then Result := QUERY_TYPE_MAILA
  else if (Text = 'ALL'        ) then Result := QUERY_TYPE_ALL
  else if (Text = 'URI'        ) then Result := QUERY_TYPE_URI
  else if (Text = 'CAA'        ) then Result := QUERY_TYPE_CAA
  else if (Text = 'TA'         ) then Result := QUERY_TYPE_TA
  else if (Text = 'DLV'        ) then Result := QUERY_TYPE_DLV
  else if (Text = 'WINS'       ) then Result := QUERY_TYPE_WINS
  else if (Text = 'WINSR'      ) then Result := QUERY_TYPE_WINSR
  else                                Result := 0;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TQueryTypeUtils.ToString(Value: Word): String;
begin
  case Value of
    QUERY_TYPE_A          : Result := 'A';
    QUERY_TYPE_NS         : Result := 'NS';
    QUERY_TYPE_MD         : Result := 'MD';
    QUERY_TYPE_MF         : Result := 'MF';
    QUERY_TYPE_CNAME      : Result := 'CNAME';
    QUERY_TYPE_SOA        : Result := 'SOA';
    QUERY_TYPE_MB         : Result := 'MB';
    QUERY_TYPE_MG         : Result := 'MG';
    QUERY_TYPE_MR         : Result := 'MR';
    QUERY_TYPE_NULL       : Result := 'NULL';
    QUERY_TYPE_WKS        : Result := 'WKS';
    QUERY_TYPE_PTR        : Result := 'PTR';
    QUERY_TYPE_HINFO      : Result := 'HINFO';
    QUERY_TYPE_MINFO      : Result := 'MINFO';
    QUERY_TYPE_MX         : Result := 'MX';
    QUERY_TYPE_TXT        : Result := 'TXT';
    QUERY_TYPE_RP         : Result := 'RP';
    QUERY_TYPE_AFSDB      : Result := 'AFSDB';
    QUERY_TYPE_X25        : Result := 'X25';
    QUERY_TYPE_ISDN       : Result := 'ISDN';
    QUERY_TYPE_RT         : Result := 'RT';
    QUERY_TYPE_NSAP       : Result := 'NSAP';
    QUERY_TYPE_NSAPPTR    : Result := 'NSAPPTR';
    QUERY_TYPE_SIG        : Result := 'SIG';
    QUERY_TYPE_KEY        : Result := 'KEY';
    QUERY_TYPE_PX         : Result := 'PX';
    QUERY_TYPE_GPOS       : Result := 'GPOS';
    QUERY_TYPE_AAAA       : Result := 'AAAA';
    QUERY_TYPE_LOC        : Result := 'LOC';
    QUERY_TYPE_NXT        : Result := 'NXT';
    QUERY_TYPE_EID        : Result := 'EID';
    QUERY_TYPE_NIMLOC     : Result := 'NIMLOC';
    QUERY_TYPE_SRV        : Result := 'SRV';
    QUERY_TYPE_ATMA       : Result := 'ATMA';
    QUERY_TYPE_NAPTR      : Result := 'NAPTR';
    QUERY_TYPE_KX         : Result := 'KX';
    QUERY_TYPE_CERT       : Result := 'CERT';
    QUERY_TYPE_A6         : Result := 'A6';
    QUERY_TYPE_DNAME      : Result := 'DNAME';
    QUERY_TYPE_SINK       : Result := 'SINK';
    QUERY_TYPE_OPT        : Result := 'OPT';
    QUERY_TYPE_APL        : Result := 'APL';
    QUERY_TYPE_DS         : Result := 'DS';
    QUERY_TYPE_SSHFP      : Result := 'SSHFP';
    QUERY_TYPE_IPSECKEY   : Result := 'IPSECKEY';
    QUERY_TYPE_RRSIG      : Result := 'RRSIG';
    QUERY_TYPE_NSEC       : Result := 'NSEC';
    QUERY_TYPE_DNSKEY     : Result := 'DNSKEY';
    QUERY_TYPE_DHCID      : Result := 'DHCID';
    QUERY_TYPE_NSEC3      : Result := 'NSEC3';
    QUERY_TYPE_NSEC3PARAM : Result := 'NSEC3PARAM';
    QUERY_TYPE_TLSA       : Result := 'TLSA';
    QUERY_TYPE_HIP        : Result := 'HIP';
    QUERY_TYPE_NINFO      : Result := 'NINFO';
    QUERY_TYPE_RKEY       : Result := 'RKEY';
    QUERY_TYPE_TALINK     : Result := 'TALINK';
    QUERY_TYPE_CDS        : Result := 'CDS';
    QUERY_TYPE_CDNSKEY    : Result := 'CDNSKEY';
    QUERY_TYPE_OPENPGPKEY : Result := 'OPENPGPKEY';
    QUERY_TYPE_CSYNC      : Result := 'CSYNC';
    QUERY_TYPE_SPF        : Result := 'SPF';
    QUERY_TYPE_UINFO      : Result := 'UINFO';
    QUERY_TYPE_UID        : Result := 'UID';
    QUERY_TYPE_GID        : Result := 'GID';
    QUERY_TYPE_UNSPEC     : Result := 'UNSPEC';
    QUERY_TYPE_NID        : Result := 'NID';
    QUERY_TYPE_L32        : Result := 'L32';
    QUERY_TYPE_L64        : Result := 'L64';
    QUERY_TYPE_LP         : Result := 'LP';
    QUERY_TYPE_EUI48      : Result := 'EUI48';
    QUERY_TYPE_EUI64      : Result := 'EUI64';
    QUERY_TYPE_ADDRS      : Result := 'ADDRS';
    QUERY_TYPE_TKEY       : Result := 'TKEY';
    QUERY_TYPE_TSIG       : Result := 'TSIG';
    QUERY_TYPE_IXFR       : Result := 'IXFR';
    QUERY_TYPE_AXFR       : Result := 'AXFR';
    QUERY_TYPE_MAILB      : Result := 'MAILB';
    QUERY_TYPE_MAILA      : Result := 'MAILA';
    QUERY_TYPE_ALL        : Result := 'ALL';
    QUERY_TYPE_URI        : Result := 'URI';
    QUERY_TYPE_CAA        : Result := 'CAA';
    QUERY_TYPE_TA         : Result := 'TA';
    QUERY_TYPE_DLV        : Result := 'DLV';
    QUERY_TYPE_WINS       : Result := 'WINS';
    QUERY_TYPE_WINSR      : Result := 'WINSR';
    else                    Result := IntToStr(Value);
  end;
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  WinHttp;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  WINHTTP_DLL = 'WINHTTP.DLL';

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  WINHTTP_ACCESS_TYPE_NO_PROXY = 1;
  WINHTTP_ACCESS_TYPE_DEFAULT_PROXY = 0;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  WINHTTP_FLAG_SECURE = $800000;
  WINHTTP_FLAG_BYPASS_PROXY_CACHE = $100;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  WINHTTP_OPTION_DISABLE_FEATURE = $3F;
  WINHTTP_OPTION_ENABLE_HTTP_PROTOCOL = $85;
  WINHTTP_DISABLE_KEEP_ALIVE = $08;
  WINHTTP_PROTOCOL_FLAG_HTTP2 = $01;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function WinHttpOpen(pwszUserAgent: PWideChar; dwAccessType: Cardinal; pwszProxyName, pwszProxyBypass: PWideChar; dwFlags: Cardinal): Pointer; stdcall; external WINHTTP_DLL;
function WinHttpConnect(hInternet: Pointer; pswzServerName: PWideChar; nServerPort: Word; dwReserved: Cardinal): Pointer; stdcall; external WINHTTP_DLL;
function WinHttpOpenRequest(hInternet: Pointer; pwszVerb: PWideChar; pwszObjectName: PWideChar; pwszVersion: PWideChar; pwszReferer: PWideChar; ppwszAcceptTypes: PWideChar; dwFlags: Cardinal): Pointer; stdcall; external WINHTTP_DLL;
function WinHttpSetOption(hInternet: Pointer; dwOption: Cardinal; lpBuffer: Pointer; dwBufferLength: Cardinal): Boolean; stdcall; external WINHTTP_DLL;
function WinHttpQueryOption(hInternet: Pointer; dwOption: Cardinal; var lpBuffer: Pointer; var lpdwBufferLength: Cardinal): Boolean; stdcall; external WINHTTP_DLL;
function WinHttpSendRequest(hInternet: Pointer; pwszHeaders: PWideChar; dwHeadersLength: Cardinal; lpOptional: Pointer; dwOptionalLength: Cardinal; dwTotalLength: Cardinal; dwContext: Cardinal): Boolean; stdcall; external WINHTTP_DLL;
function WinHttpReceiveResponse(hInternet: Pointer; lpReserved: Pointer): Boolean; stdcall; external WINHTTP_DLL;
function WinHttpReadData(hInternet: Pointer; lpBuffer: Pointer; dwNumberOfBytesToRead: Cardinal; var lpdwNumberOfBytesRead: Cardinal): Boolean; stdcall; external WINHTTP_DLL;
function WinHttpCloseHandle(hInternet: Pointer): Boolean; stdcall; external WINHTTP_DLL;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

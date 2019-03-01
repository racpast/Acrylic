// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  MD5;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

// (C) Copyright 2002-2017 Wolfgang Ehrhardt
//
// This software is provided 'as-is', without any express or implied warranty.
// In no event will the authors be held liable for any damages arising from
// the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software in
//    a product, an acknowledgment in the product documentation would be
//    appreciated but is not required.
//
// 2. Altered source versions must be plainly marked as such, and must not be
//    misrepresented as being the original software.
//
// 3. This notice may not be removed or altered from any source distribution.

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

// In accordance with the above license I declare that the source code in
// this unit has been adapted by me (Massimo Fabiano) from the original code.

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TMD5Digest = packed Array [0..15] of Byte;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TMD5 = class
    public
      class function Compute(Buffer: Pointer; Size: Integer): TMD5Digest;
      class function Compare(MD5Digest1, MD5Digest2: TMD5Digest): Integer;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

{$define CONST}
{$define Q_OPT}
{$define X_OPT}
{$define N_OPT}
{$define BASM}
{$define V7PLUS}

{$ifdef VER10}
{$define BIT16}
{$define BASM16}
{$define WINCRT}
{$define G_OPT}
{$undef  CONST}
{$undef  Q_OPT}
{$undef  V7PLUS}
{$endif}

{$ifdef VER15}
{$define BIT16}
{$define BASM16}
{$define WINCRT}
{$define G_OPT}
{$undef  CONST}
{$undef  Q_OPT}
{$undef  V7PLUS}
{$endif}

{$ifdef VER50}
{$define BIT16}
{$define VER5X}
{$undef  BASM}
{$undef  CONST}
{$undef  Q_OPT}
{$undef  X_OPT}
{$undef  V7PLUS}
{$endif}

{$ifdef VER55}
{$define BIT16}
{$define VER5X}
{$undef  BASM}
{$undef  CONST}
{$undef  Q_OPT}
{$undef  X_OPT}
{$undef  V7PLUS}
{$endif}

{$ifdef VER60}
{$define BIT16}
{$undef  CONST}
{$undef  Q_OPT}
{$define G_OPT}
{$define BASM16}
{$undef  V7PLUS}
{$endif}

{$ifdef VER70}
{$define BIT16}
{$define G_OPT}
{$define BASM16}
{$endif}

{$ifdef VER80}
{$define BIT16}
{$define G_OPT}
{$define BASM16}
{$define WINCRT}
{$define RESULT}
{$endif}

{$ifdef VER90}
{$define DELPHI}
{$endif}

{$ifdef VER93}
{$define DELPHI}
{$endif}

{$ifdef VER100}
{$define DELPHI}
{$define HAS_ASSERT}
{$define HAS_OUT}
{$endif}

{$ifdef VER110}
{$define DELPHI}
{$define HAS_OUT}
{$endif}

{$ifdef VER120}
{$define DELPHI}
{$define D4PLUS}
{$endif}

{$ifdef VER125}
{$define DELPHI}
{$define D4PLUS}
{$endif}

{$ifdef VER130}
{$define DELPHI}
{$define D4PLUS}
{$endif}

{$ifdef VER140}
{$define DELPHI}
{$define D4PLUS}
{$endif}

{$ifdef VER150}
{$define DELPHI}
{$define D4PLUS}
{$define HAS_UNSAFE}
{$define HAS_UINT64}
{$endif}

{$ifdef VER170}
{$define DELPHI}
{$define D4PLUS}
{$define HAS_INLINE}
{$define HAS_UNSAFE}
{$define HAS_UINT64}
{$endif}

{$ifdef VER180}
{$define DELPHI}
{$define D4PLUS}
{$define HAS_INLINE}
{$define HAS_UNSAFE}
{$define HAS_UINT64}
{$endif}

{$ifdef VER200}
{$define DELPHI}
{$define D12PLUS}
{$endif}

{$ifdef VER210}
{$define DELPHI}
{$define D12PLUS}
{$endif}

{$ifdef VER220}
{$define DELPHI}
{$define D12PLUS}
{$endif}

{$ifdef VER230}
{$define DELPHI}
{$define D12PLUS}
{$define UNIT_SCOPE}
{$endif}

{$ifdef VER240}
{$define DELPHI}
{$define D12PLUS}
{$define UNIT_SCOPE}
{$endif}

{$ifdef VER250}
{$define DELPHI}
{$define D12PLUS}
{$define UNIT_SCOPE}
{$endif}

{$ifdef VER260}
{$define DELPHI}
{$define D12PLUS}
{$define UNIT_SCOPE}
{$endif}

{$ifdef VER270}
{$define DELPHI}
{$define D12PLUS}
{$define UNIT_SCOPE}
{$endif}

{$ifdef VER280}
{$define DELPHI}
{$define D12PLUS}
{$define UNIT_SCOPE}
{$endif}

{$ifdef VER290}
{$define DELPHI}
{$define D12PLUS}
{$define D22PLUS}
{$define UNIT_SCOPE}
{$endif}

{$ifdef VER300}
{$define DELPHI}
{$define D12PLUS}
{$define D22PLUS}
{$define UNIT_SCOPE}
{$endif}

{$ifdef VER310}
{$define DELPHI}
{$define D12PLUS}
{$define D22PLUS}
{$define UNIT_SCOPE}
{$endif}

{$ifdef VER320}
{$define DELPHI}
{$define D12PLUS}
{$define D22PLUS}
{$define UNIT_SCOPE}
{$endif}

{$ifdef CONDITIONALEXPRESSIONS}
{$ifndef D4PLUS}
{$define D4PLUS}
{$endif}
{$define HAS_MSG}
{$define HAS_XTYPES}
{$ifdef CPUX64}
{$define BIT64}
{$endif}
{$endif}

{$ifdef VER70}
{$ifdef WINDOWS}
{$define WINCRT}
{$endif}
{$endif}

{$ifdef VirtualPascal}
{$define G_OPT}
{$define RESULT}
{$define LoadArgs}
{$endif}

{$ifdef WIN32}
{$define J_OPT}
{$endif}

{$ifdef BIT64}
{$define J_OPT}
{$endif}

{$ifdef FPC}
{$define FPC_ProcVar}
{$define ABSTRACT}
{$define HAS_XTYPES}
{$define HAS_OVERLOAD}
{$undef N_OPT}
{$ifdef VER1}
{$undef  J_OPT}
{$define HAS_INT64}
{$define HAS_CARD32}
{$define HAS_MSG}
{$define HAS_ASSERT}
{$ifndef VER1_0}
{$define StrictLong}
{$else}
{$define LoadArgs}
{$endif}
{$endif}
{$ifdef VER2}
{$define FPC2Plus}
{$define HAS_ASSERT}
{$define HAS_INT64}
{$define HAS_CARD32}
{$define HAS_MSG}
{$define HAS_INLINE}
{$define StrictLong}
{$ifdef FPC_OBJFPC}
{$define DEFAULT}
{$endif}
{$ifdef FPC_DELPHI}
{$define DEFAULT}
{$endif}
{$ifndef VER2_0}
{$ifndef VER2_1}
{$define HAS_UINT64}
{$endif}
{$define HAS_DENORM_LIT}
{$endif}
{$ifdef VER2_7_1}
{$define FPC271or3}
{$endif}
{$ifdef VER2_6_2}
{$define HAS_INTXX}
{$endif}
{$ifdef VER2_6_4}
{$define HAS_INTXX}
{$define HAS_PINTXX}
{$endif}
{$endif}
{$ifdef VER3}
{$define FPC2Plus}
{$define FPC271or3}
{$define HAS_ASSERT}
{$define HAS_INT64}
{$define HAS_CARD32}
{$define HAS_MSG}
{$define HAS_INLINE}
{$define HAS_UINT64}
{$define HAS_DENORM_LIT}
{$define StrictLong}
{$define HAS_INTXX}
{$define HAS_PINTXX}
{$ifdef FPC_OBJFPC}
{$define DEFAULT}
{$endif}
{$ifdef FPC_DELPHI}
{$define DEFAULT}
{$endif}
{$endif}

{$ifdef FPC_OBJFPC}
{$define RESULT}
{$define HAS_OUT}
{$endif}
{$ifdef FPC_DELPHI}
{$define RESULT}
{$define HAS_OUT}
{$undef FPC_ProcVar}
{$endif}
{$ifdef FPC_TP}
{$undef FPC_ProcVar}
{$endif}
{$ifdef FPC_GPC}
{$undef FPC_ProcVar}
{$endif}
{$ifdef CPU64}
{$define BIT64}
{$endif}
{$ifdef CPUARM}
{$define EXT64}
{$define PurePascal}
{$endif}
{$endif}

{$ifdef __TMT__}
{$undef N_OPT}
{$define RESULT}
{$define HAS_INT64}
{$define LoadArgs}
{$ifdef __WIN32__}
{$define WIN32}
{$endif}
{$endif}

{$ifndef BIT16}
{$define Bit32or64}
{$ifndef BIT64}
{$define BIT32}
{$endif}
{$endif}

{$ifdef BIT16}
{$ifdef WINDOWS}
{$define WIN16}
{$endif}
{$endif}

{$ifdef Delphi}
{$define RESULT}
{$define ABSTRACT}
{$define HAS_DENORM_LIT}
{$endif}

{$ifdef D12Plus}
{$ifndef D4PLUS}
{$define D4PLUS}
{$endif}
{$define HAS_INLINE}
{$define HAS_UNSAFE}
{$define HAS_UINT64}
{$define HAS_INTXX}
{$endif}

{$ifdef D4Plus}
{$define HAS_OUT}
{$define HAS_INT64}
{$define HAS_CARD32}
{$define StrictLong}
{$define HAS_ASSERT}
{$define DEFAULT}
{$define HAS_OVERLOAD}
{$endif}

{$ifdef WIN32}
{$define WIN32or64}
{$ifndef VirtualPascal}
{$define APPCONS}
{$endif}
{$endif}

{$ifdef WIN64}
{$define BIT64}
{$define WIN32or64}
{$define EXT64}
{$define APPCONS}
{$endif}

{$ifdef BIT64}
{$undef BASM}
{$endif}

{$ifndef FPC}
{$B-}
{$endif}

{$ifdef FPC}
{$ifdef CPUI386}
{$ASMmode intel}
{$endif}
{$goto on}
{$endif}

{$ifdef VirtualPascal}
{$ifndef debug}
{&Optimise+,SmartLink+,Speed+}
{$endif}
{$endif}

{$ifdef G_OPT}
{$G+}
{$endif}

{$ifdef Q_OPT}
{$Q-}
{$endif}

{$ifdef debug}
{$R+,S+}
{$else}
{$R-,S-}
{$endif}

{$ifdef SIMULATE_EXT64}
{$define EXT64}
{$endif}

{$ifdef BIT16}
{$F-}
{$endif}

{$ifopt A+}{$define Align_on}{$endif}
{$ifopt B+}{$define BoolEval_on}{$endif}
{$ifopt D+}{$define DebugInfo_on}{$endif}
{$ifopt I+}{$define IOChecks_on}{$endif}
{$ifopt R+}{$define RangeChecks_on}{$endif}
{$ifopt V+}{$define VarStringChecks_on}{$endif}

{$ifdef Q_OPT}
{$ifopt P+}{$define OpenStrings_on}{$endif}
{$ifopt Q+}{$define OverflowChecks_on}{$endif}
{$endif}

{$ifdef X_OPT}
{$ifopt X+}{$define ExtendedSyntax_on}{$endif}
{$ifopt X-}{$undef  RESULT}{$endif}
{$endif}

{$ifdef CONDITIONALEXPRESSIONS}
{$warn SYMBOL_PLATFORM OFF}
{$warn SYMBOL_DEPRECATED OFF}
{$warn SYMBOL_LIBRARY OFF}
{$warn UNIT_DEPRECATED OFF}
{$warn UNIT_LIBRARY OFF}
{$warn UNIT_PLATFORM OFF}
{$ifdef HAS_UNSAFE}
{$warn UNSAFE_TYPE OFF}
{$warn UNSAFE_CODE OFF}
{$warn UNSAFE_CAST OFF}
{$endif}
{$endif}

{$ifdef BIT64}
{$ifndef PurePascal}
{$define PurePascal}
{$endif}
{$endif}

{$ifdef BIT16}
type
  Int8 = ShortInt;
  Int16 = Integer;
  Int32 = Longint;
  UInt8 = Byte;
  UInt16 = Word;
  UInt32 = Longint;

  Smallint = Integer;
  Shortstring = string;

  pByte = ^Byte;
  pBoolean = ^Boolean;
  pShortInt = ^ShortInt;
  pWord = ^Word;
  pSmallInt = ^SmallInt;
  pLongint = ^Longint;
{$else}
{$ifndef HAS_INTXX}
type
  Int8 = ShortInt;
  Int16 = SmallInt;
  Int32 = Longint;
  UInt8 = Byte;
  UInt16 = Word;
{$ifdef HAS_CARD32}
  UInt32 = Cardinal;
{$else}
  UInt32 = Longint;
{$endif}
{$endif}
{$ifndef HAS_XTYPES}
type
  pByte = ^Byte;
  pBoolean = ^Boolean;
  pShortInt = ^ShortInt;
  pWord = ^Word;
  pSmallInt = ^SmallInt;
  pLongint = ^Longint;
{$endif}
{$ifdef FPC}{$ifdef VER1_0}
type
  pBoolean = ^Boolean;
  pShortInt = ^ShortInt;
{$endif}{$endif}
{$endif}

type
  Str255 = string[255];
  Str127 = string[127];

type
{$ifndef HAS_PINTXX}
  pInt8 = ^Int8;
  pInt16 = ^Int16;
  pInt32 = ^Int32;
  pUInt8 = ^UInt8;
  pUInt16 = ^UInt16;
  pUInt32 = ^UInt32;
{$endif}
  pStr255 = ^Str255;
  pStr127 = ^Str127;

{$ifdef BIT16}
{$ifdef V7Plus}
type
  BString = string[255];
  pBString = ^BString;
  char8 = char;
  pchar8 = pchar;
{$else}
type
  BString = string[255];
  pBString = ^BString;
  char8 = char;
  pchar8 = ^char;
{$endif}
{$else}
{$ifdef UNICODE}
type
  BString = AnsiString;
  pBString = pAnsiString;
  char8 = AnsiChar;
  pchar8 = pAnsiChar;
{$else}
type
  BString = AnsiString;
  pBString = pAnsiString;
  char8 = AnsiChar;
  pchar8 = pAnsiChar;
{$endif}
{$endif}

{$ifdef V7Plus}
type
  Ptr2Inc = pByte;
{$else}
type
  Ptr2Inc = Longint;
{$endif}

{$ifdef FPC}
{$ifdef VER1}
type __P2I = LongInt;
{$else}
type __P2I = PtrUInt;
{$endif}
{$else}
{$ifdef BIT64}
type __P2I = NativeInt;
{$else}
type __P2I = LongInt;
{$endif}
{$endif}

{$ifdef EXT64}
type Extended = Double;
{$else}
{$ifdef SIMULATE_EXT64}
type Extended = Double;
{$endif}
{$endif}

const
  MaxBlockLen = 128;
  MaxDigestLen = 64;
  MaxStateLen = 16;
  MaxOIDLen = 11;

type
  THashState = packed Array [0..MaxStateLen-1] of LongInt;
  THashBuffer = packed Array [0..MaxBlockLen-1] of Byte;
  THashDigest = packed Array [0..MaxDigestLen-1] of Byte;
  PHashDigest = ^THashDigest;
  THashBuf32 = packed Array [0..MaxBlockLen  div 4 -1] of LongInt;
  THashDig32 = packed Array [0..MaxDigestLen div 4 -1] of LongInt;
  THMacBuffer = packed Array [0..143] of Byte;

const
  HASHCTXSIZE = 448;

type
  THashContext = packed record
                   Hash: THashState;
                   MLen: packed Array [0..3] of LongInt;
                   Buffer: THashBuffer;
                   Index: LongInt;
                   Fill2: packed Array [213..HASHCTXSIZE] of Byte;
                 end;

type
  TOID_Vec = packed Array [1..MaxOIDLen] of LongInt;
  POID_Vec = ^TOID_Vec;

const
  BitAPI_Mask: Array [0..7] of Byte = ($00,$80,$C0,$E0,$F0,$F8,$FC,$FE);
  BitAPI_PBit: Array [0..7] of Byte = ($80,$40,$20,$10,$08,$04,$02,$01);

{$ifdef BIT16}
{$F-}
{$endif}

const
  MD5_BlockLen  = 64;

const
  MD5_OID : TOID_Vec = (1, 2, 840, 113549, 2, 5, -1, -1, -1, -1, -1);

{$ifdef StrictLong}
{$warnings off}
{$R-}
{$endif}

const
  T : Array [0..63] of LongInt = ($d76aa478, $e8c7b756, $242070db, $c1bdceee, $f57c0faf, $4787c62a, $a8304613, $fd469501, $698098d8, $8b44f7af, $ffff5bb1, $895cd7be, $6b901122, $fd987193, $a679438e, $49b40821, $f61e2562, $c040b340, $265e5a51, $e9b6c7aa, $d62f105d, $02441453, $d8a1e681, $e7d3fbc8, $21e1cde6, $c33707d6, $f4d50d87, $455a14ed, $a9e3e905, $fcefa3f8, $676f02d9, $8d2a4c8a, $fffa3942, $8771f681, $6d9d6122, $fde5380c, $a4beea44, $4bdecfa9, $f6bb4b60, $bebfbc70, $289b7ec6, $eaa127fa, $d4ef3085, $04881d05, $d9d4d039, $e6db99e5, $1fa27cf8, $c4ac5665, $f4292244, $432aff97, $ab9423a7, $fc93a039, $655b59c3, $8f0ccc92, $ffeff47d, $85845dd1, $6fa87e4f, $fe2ce6e0, $a3014314, $4e0811a1, $f7537e82, $bd3af235, $2ad7d2bb, $eb86d391);

{$ifdef StrictLong}
{$warnings on}
{$ifdef RangeChecks_on}
{$R+}
{$endif}
{$endif}

{$i-}

{$ifndef BIT16}

{$ifdef PurePascal}

procedure UpdateLen(var whi, wlo: LongInt; BLen: LongInt);

var
  tmp: int64;

begin
  tmp := int64(cardinal(wlo))+Blen;
  wlo := LongInt(tmp and $FFFFFFFF);
  Inc(whi,LongInt(tmp shr 32));
end;

{$else}

procedure UpdateLen(var whi, wlo: LongInt; BLen: LongInt);

begin

  asm
    mov  edx, [wlo]
    mov  ecx, [whi]
    mov  eax, [Blen]
    add  [edx], eax
    adc  dword ptr [ecx], 0
  end;

end;

{$endif}

procedure MD5Transform(var Hash: THashState; const Buffer: THashBuf32);

var
  A, B, C, D: LongInt;

begin

  A := Hash[0];
  B := Hash[1];
  C := Hash[2];
  D := Hash[3];

  Inc(A, Buffer[ 0] + T[ 0] + (D xor (B and (C xor D)))); A := A shl  7 or A shr 25 + B;
  Inc(D, Buffer[ 1] + T[ 1] + (C xor (A and (B xor C)))); D := D shl 12 or D shr 20 + A;
  Inc(C, Buffer[ 2] + T[ 2] + (B xor (D and (A xor B)))); C := C shl 17 or C shr 15 + D;
  Inc(B, Buffer[ 3] + T[ 3] + (A xor (C and (D xor A)))); B := B shl 22 or B shr 10 + C;
  Inc(A, Buffer[ 4] + T[ 4] + (D xor (B and (C xor D)))); A := A shl  7 or A shr 25 + B;
  Inc(D, Buffer[ 5] + T[ 5] + (C xor (A and (B xor C)))); D := D shl 12 or D shr 20 + A;
  Inc(C, Buffer[ 6] + T[ 6] + (B xor (D and (A xor B)))); C := C shl 17 or C shr 15 + D;
  Inc(B, Buffer[ 7] + T[ 7] + (A xor (C and (D xor A)))); B := B shl 22 or B shr 10 + C;
  Inc(A, Buffer[ 8] + T[ 8] + (D xor (B and (C xor D)))); A := A shl  7 or A shr 25 + B;
  Inc(D, Buffer[ 9] + T[ 9] + (C xor (A and (B xor C)))); D := D shl 12 or D shr 20 + A;
  Inc(C, Buffer[10] + T[10] + (B xor (D and (A xor B)))); C := C shl 17 or C shr 15 + D;
  Inc(B, Buffer[11] + T[11] + (A xor (C and (D xor A)))); B := B shl 22 or B shr 10 + C;
  Inc(A, Buffer[12] + T[12] + (D xor (B and (C xor D)))); A := A shl  7 or A shr 25 + B;
  Inc(D, Buffer[13] + T[13] + (C xor (A and (B xor C)))); D := D shl 12 or D shr 20 + A;
  Inc(C, Buffer[14] + T[14] + (B xor (D and (A xor B)))); C := C shl 17 or C shr 15 + D;
  Inc(B, Buffer[15] + T[15] + (A xor (C and (D xor A)))); B := B shl 22 or B shr 10 + C;

  Inc(A, Buffer[ 1] + T[16] + (C xor (D and (B xor C)))); A := A shl  5 or A shr 27 + B;
  Inc(D, Buffer[ 6] + T[17] + (B xor (C and (A xor B)))); D := D shl  9 or D shr 23 + A;
  Inc(C, Buffer[11] + T[18] + (A xor (B and (D xor A)))); C := C shl 14 or C shr 18 + D;
  Inc(B, Buffer[ 0] + T[19] + (D xor (A and (C xor D)))); B := B shl 20 or B shr 12 + C;
  Inc(A, Buffer[ 5] + T[20] + (C xor (D and (B xor C)))); A := A shl  5 or A shr 27 + B;
  Inc(D, Buffer[10] + T[21] + (B xor (C and (A xor B)))); D := D shl  9 or D shr 23 + A;
  Inc(C, Buffer[15] + T[22] + (A xor (B and (D xor A)))); C := C shl 14 or C shr 18 + D;
  Inc(B, Buffer[ 4] + T[23] + (D xor (A and (C xor D)))); B := B shl 20 or B shr 12 + C;
  Inc(A, Buffer[ 9] + T[24] + (C xor (D and (B xor C)))); A := A shl  5 or A shr 27 + B;
  Inc(D, Buffer[14] + T[25] + (B xor (C and (A xor B)))); D := D shl  9 or D shr 23 + A;
  Inc(C, Buffer[ 3] + T[26] + (A xor (B and (D xor A)))); C := C shl 14 or C shr 18 + D;
  Inc(B, Buffer[ 8] + T[27] + (D xor (A and (C xor D)))); B := B shl 20 or B shr 12 + C;
  Inc(A, Buffer[13] + T[28] + (C xor (D and (B xor C)))); A := A shl  5 or A shr 27 + B;
  Inc(D, Buffer[ 2] + T[29] + (B xor (C and (A xor B)))); D := D shl  9 or D shr 23 + A;
  Inc(C, Buffer[ 7] + T[30] + (A xor (B and (D xor A)))); C := C shl 14 or C shr 18 + D;
  Inc(B, Buffer[12] + T[31] + (D xor (A and (C xor D)))); B := B shl 20 or B shr 12 + C;

  Inc(A, Buffer[ 5] + T[32] + (B xor C xor D)); A := A shl  4 or A shr 28 + B;
  Inc(D, Buffer[ 8] + T[33] + (A xor B xor C)); D := D shl 11 or D shr 21 + A;
  Inc(C, Buffer[11] + T[34] + (D xor A xor B)); C := C shl 16 or C shr 16 + D;
  Inc(B, Buffer[14] + T[35] + (C xor D xor A)); B := B shl 23 or B shr  9 + C;
  Inc(A, Buffer[ 1] + T[36] + (B xor C xor D)); A := A shl  4 or A shr 28 + B;
  Inc(D, Buffer[ 4] + T[37] + (A xor B xor C)); D := D shl 11 or D shr 21 + A;
  Inc(C, Buffer[ 7] + T[38] + (D xor A xor B)); C := C shl 16 or C shr 16 + D;
  Inc(B, Buffer[10] + T[39] + (C xor D xor A)); B := B shl 23 or B shr  9 + C;
  Inc(A, Buffer[13] + T[40] + (B xor C xor D)); A := A shl  4 or A shr 28 + B;
  Inc(D, Buffer[ 0] + T[41] + (A xor B xor C)); D := D shl 11 or D shr 21 + A;
  Inc(C, Buffer[ 3] + T[42] + (D xor A xor B)); C := C shl 16 or C shr 16 + D;
  Inc(B, Buffer[ 6] + T[43] + (C xor D xor A)); B := B shl 23 or B shr  9 + C;
  Inc(A, Buffer[ 9] + T[44] + (B xor C xor D)); A := A shl  4 or A shr 28 + B;
  Inc(D, Buffer[12] + T[45] + (A xor B xor C)); D := D shl 11 or D shr 21 + A;
  Inc(C, Buffer[15] + T[46] + (D xor A xor B)); C := C shl 16 or C shr 16 + D;
  Inc(B, Buffer[ 2] + T[47] + (C xor D xor A)); B := B shl 23 or B shr  9 + C;

  Inc(A, Buffer[ 0] + T[48] + (C xor (B or not D))); A := A shl  6 or A shr 26 + B;
  Inc(D, Buffer[ 7] + T[49] + (B xor (A or not C))); D := D shl 10 or D shr 22 + A;
  Inc(C, Buffer[14] + T[50] + (A xor (D or not B))); C := C shl 15 or C shr 17 + D;
  Inc(B, Buffer[ 5] + T[51] + (D xor (C or not A))); B := B shl 21 or B shr 11 + C;
  Inc(A, Buffer[12] + T[52] + (C xor (B or not D))); A := A shl  6 or A shr 26 + B;
  Inc(D, Buffer[ 3] + T[53] + (B xor (A or not C))); D := D shl 10 or D shr 22 + A;
  Inc(C, Buffer[10] + T[54] + (A xor (D or not B))); C := C shl 15 or C shr 17 + D;
  Inc(B, Buffer[ 1] + T[55] + (D xor (C or not A))); B := B shl 21 or B shr 11 + C;
  Inc(A, Buffer[ 8] + T[56] + (C xor (B or not D))); A := A shl  6 or A shr 26 + B;
  Inc(D, Buffer[15] + T[57] + (B xor (A or not C))); D := D shl 10 or D shr 22 + A;
  Inc(C, Buffer[ 6] + T[58] + (A xor (D or not B))); C := C shl 15 or C shr 17 + D;
  Inc(B, Buffer[13] + T[59] + (D xor (C or not A))); B := B shl 21 or B shr 11 + C;
  Inc(A, Buffer[ 4] + T[60] + (C xor (B or not D))); A := A shl  6 or A shr 26 + B;
  Inc(D, Buffer[11] + T[61] + (B xor (A or not C))); D := D shl 10 or D shr 22 + A;
  Inc(C, Buffer[ 2] + T[62] + (A xor (D or not B))); C := C shl 15 or C shr 17 + D;
  Inc(B, Buffer[ 9] + T[63] + (D xor (C or not A))); B := B shl 21 or B shr 11 + C;

  Inc(Hash[0], A);
  Inc(Hash[1], B);
  Inc(Hash[2], C);
  Inc(Hash[3], D);

end;

{$else}

{$ifdef BASM16}

procedure UpdateLen(var whi, wlo: LongInt; BLen: LongInt); assembler;

asm
          les   di,[wlo]
  db $66; mov   ax,Word ptr [BLen]
  db $66; sub   dx,dx
  db $66; add   es:[di],ax
          les   di,[whi]
  db $66; adc   es:[di],dx
end;

function LRot32(X: LongInt; c: Word): LongInt;

inline
(
  $59/              { pop    cx      }
  $66/$58/          { pop    eax     }
  $66/$D3/$C0/      { rol    eax,cl  }
  $66/$8B/$D0/      { mov    edx,eax }
  $66/$C1/$EA/$10   { shr    edx,16  }
);

{$else}

procedure UpdateLen(var whi, wlo: LongInt; BLen: LongInt);

inline
(
  $58/                  { pop  ax            }
  $5A/                  { pop  dx            }
  $5B/                  { pop  bx            }
  $07/                  { pop  es            }
  $26/$01/$07/          { add  es:[bx],ax    }
  $26/$11/$57/$02/      { adc  es:[bx+02],dx }
  $5B/                  { pop  bx            }
  $07/                  { pop  es            }
  $26/$83/$17/$00/      { adc  es:[bx],0     }
  $26/$83/$57/$02/$00   { adc  es:[bx+02],0  }
);

function LRot32(X: LongInt; c: Word): LongInt;

inline
(
  $59/           {   pop    cx    }
  $58/           {   pop    ax    }
  $5A/           {   pop    dx    }

  $83/$F9/$10/   {   cmp    cx,16 }
  $72/$06/       {   jb     L     }
  $92/           {   xchg   dx,ax }
  $83/$E9/$10/   {   sub    cx,16 }
  $74/$09/       {   je     X     }

  $2B/$DB/       { S:sub    bx,bx }
  $D1/$D0/       { L:rcl    ax,1  }
  $D1/$D2/       {   rcl    dx,1  }
  $13/$C3/       {   adc    ax,bx }
  $49/           {   Dec    cx    }
  $75/$F7        {   jne    L     }
);               { X:             }

{$endif BASM16}

const
  PX: Array [0..63] of Word = ( 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1, 6, 11, 0, 5, 10, 15, 4, 9, 14, 3, 8, 13, 2, 7, 12, 5, 8, 11, 14, 1, 4, 7, 10, 13, 0, 3, 6, 9, 12, 15, 2, 0, 7, 14, 5, 12, 3, 10, 1, 8, 15, 6, 13, 4, 11, 2, 9);

procedure MD5Transform(var Hash: THashState;{$ifdef CONST} const{$else} var{$endif} Buffer: THashBuf32);

var
  A, B, C, D: LongInt; i, k: Integer;

begin

  A := Hash[0];
  B := Hash[1];
  C := Hash[2];
  D := Hash[3];

  k := 0;

  for i := 0 to 3 do begin
    Inc(A, Buffer[k] + T[k] + (D xor (B and (C xor D)))); A := LRot32(A,  7) + B; Inc(k);
    Inc(D, Buffer[k] + T[k] + (C xor (A and (B xor C)))); D := LRot32(D, 12) + A; Inc(k);
    Inc(C, Buffer[k] + T[k] + (B xor (D and (A xor B)))); C := LRot32(C, 17) + D; Inc(k);
    Inc(B, Buffer[k] + T[k] + (A xor (C and (D xor A)))); B := LRot32(B, 22) + C; Inc(k);
  end;

  for i := 0 to 3 do begin
    Inc(A, Buffer[PX[k]] + T[k] + (C xor (D and (B xor C)))); A := LRot32(A,  5) + B; Inc(k);
    Inc(D, Buffer[PX[k]] + T[k] + (B xor (C and (A xor B)))); D := LRot32(D,  9) + A; Inc(k);
    Inc(C, Buffer[PX[k]] + T[k] + (A xor (B and (D xor A)))); C := LRot32(C, 14) + D; Inc(k);
    Inc(B, Buffer[PX[k]] + T[k] + (D xor (A and (C xor D)))); B := LRot32(B, 20) + C; Inc(k);
  end;

  for i := 0 to 3 do begin
    Inc(A, Buffer[PX[k]] + T[k] + (B xor C xor D)); A := LRot32(A,  4) + B; Inc(k);
    Inc(D, Buffer[PX[k]] + T[k] + (A xor B xor C)); D := LRot32(D, 11) + A; Inc(k);
    Inc(C, Buffer[PX[k]] + T[k] + (D xor A xor B)); C := LRot32(C, 16) + D; Inc(k);
    Inc(B, Buffer[PX[k]] + T[k] + (C xor D xor A)); B := LRot32(B, 23) + C; Inc(k);
  end;

  for i := 0 to 3 do begin
    Inc(A, Buffer[PX[k]] + T[k] + (C xor (B or not D))); A := LRot32(A,  6) + B; Inc(k);
    Inc(D, Buffer[PX[k]] + T[k] + (B xor (A or not C))); D := LRot32(D, 10) + A; Inc(k);
    Inc(C, Buffer[PX[k]] + T[k] + (A xor (D or not B))); C := LRot32(C, 15) + D; Inc(k);
    Inc(B, Buffer[PX[k]] + T[k] + (D xor (C or not A))); B := LRot32(B, 21) + C; Inc(k);
  end;

  Inc(Hash[0], A);
  Inc(Hash[1], B);
  Inc(Hash[2], C);
  Inc(Hash[3], D);

end;

{$endif}

procedure MD5Init(var Context: THashContext);
begin
  fillchar(Context,SizeOf(Context),0);
  with Context do begin
     Hash[0] := LongInt($67452301);
     Hash[1] := LongInt($EFCDAB89);
     Hash[2] := LongInt($98BADCFE);
     Hash[3] := LongInt($10325476);
  end;
end;

procedure MD5UpdateXL(var Context: THashContext; Msg: Pointer; Len: LongInt);
var
  i: Integer;
begin
  if Len<=$1FFFFFFF then UpdateLen(Context.MLen[1], Context.MLen[0], Len shl 3)
  else begin
    for i:=1 to 8 do UpdateLen(Context.MLen[1], Context.MLen[0], Len)
  end;

  while Len > 0 do begin
    Context.Buffer[Context.Index]:= pByte(Msg)^;
    Inc(Ptr2Inc(Msg));
    Inc(Context.Index);
    Dec(Len);
    if Context.Index=MD5_BlockLen then begin
      Context.Index:= 0;
      MD5Transform(Context.Hash, THashBuf32(Context.Buffer));
      while Len>=MD5_BlockLen do begin
        MD5Transform(Context.Hash, THashBuf32(Msg^));
        Inc(Ptr2Inc(Msg),MD5_BlockLen);
        Dec(Len,MD5_BlockLen);
      end;
    end;
  end;
end;

procedure MD5Update(var Context: THashContext; Msg: Pointer; Len: Word);
begin
  MD5UpdateXL(Context, Msg, Len);
end;

procedure MD5FinalBitsEx(var Context: THashContext; var Digest: THashDigest; BData: Byte; bitlen: Integer);
var
  i: Integer;
begin
  if (bitlen>0) and (bitlen<=7) then begin
    Context.Buffer[Context.Index]:= (BData and BitAPI_Mask[bitlen]) or BitAPI_PBit[bitlen];
    UpdateLen(Context.MLen[1], Context.MLen[0], bitlen);
  end
  else Context.Buffer[Context.Index]:= $80;

  for i:=Context.Index+1 to 63 do Context.Buffer[i] := 0;
  if Context.Index>= 56 then begin
    MD5Transform(Context.Hash, THashBuf32(Context.Buffer));
    fillchar(Context.Buffer,56,0);
  end;
  THashBuf32(Context.Buffer)[14] := Context.MLen[0];
  THashBuf32(Context.Buffer)[15] := Context.MLen[1];
  MD5Transform(Context.Hash, THashBuf32(Context.Buffer));
  Move(Context.Hash,Digest,SizeOf(Digest));
  fillchar(Context,SizeOf(Context),0);
end;

procedure MD5FinalBits(var Context: THashContext; var Digest: TMD5Digest; BData: Byte; bitlen: Integer);
var
  tmp: THashDigest;
begin
  MD5FinalBitsEx(Context, tmp, BData, bitlen);
  Move(tmp, Digest, SizeOf(Digest));
end;

procedure MD5FinalEx(var Context: THashContext; var Digest: THashDigest);
begin
  MD5FinalBitsEx(Context,Digest,0,0);
end;

procedure MD5Final(var Context: THashContext; var Digest: TMD5Digest);
var
  tmp: THashDigest;
begin
  MD5FinalBitsEx(Context, tmp, 0, 0);
  Move(tmp, Digest, SizeOf(Digest));
end;

procedure MD5FullXL(var Digest: TMD5Digest; Msg: Pointer; Len: LongInt);
var
  Context: THashContext;
begin
  MD5Init(Context);
  MD5UpdateXL(Context, Msg, Len);
  MD5Final(Context, Digest);
end;

procedure MD5Full(var Digest: TMD5Digest; Msg: Pointer; Len: Word);
begin
  MD5FullXL(Digest, Msg, Len);
end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TMD5.Compute(Buffer: Pointer; Size: Integer): TMD5Digest;

var
  MD5Digest: TMD5Digest;

begin

  if (Size <= 65536) then MD5Full(MD5Digest, Buffer, Size) else MD5FullXL(MD5Digest, Buffer, Size); Result := MD5Digest;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TMD5.Compare(MD5Digest1, MD5Digest2: TMD5Digest): Integer;

begin

  if (MD5Digest1[ 0] > MD5Digest2[ 0]) then begin Result := -1; Exit; end else if (MD5Digest1[ 0] < MD5Digest2[ 0]) then begin Result := 1; Exit; end;
  if (MD5Digest1[ 1] > MD5Digest2[ 1]) then begin Result := -1; Exit; end else if (MD5Digest1[ 1] < MD5Digest2[ 1]) then begin Result := 1; Exit; end;
  if (MD5Digest1[ 2] > MD5Digest2[ 2]) then begin Result := -1; Exit; end else if (MD5Digest1[ 2] < MD5Digest2[ 2]) then begin Result := 1; Exit; end;
  if (MD5Digest1[ 3] > MD5Digest2[ 3]) then begin Result := -1; Exit; end else if (MD5Digest1[ 3] < MD5Digest2[ 3]) then begin Result := 1; Exit; end;
  if (MD5Digest1[ 4] > MD5Digest2[ 4]) then begin Result := -1; Exit; end else if (MD5Digest1[ 4] < MD5Digest2[ 4]) then begin Result := 1; Exit; end;
  if (MD5Digest1[ 5] > MD5Digest2[ 5]) then begin Result := -1; Exit; end else if (MD5Digest1[ 5] < MD5Digest2[ 5]) then begin Result := 1; Exit; end;
  if (MD5Digest1[ 6] > MD5Digest2[ 6]) then begin Result := -1; Exit; end else if (MD5Digest1[ 6] < MD5Digest2[ 6]) then begin Result := 1; Exit; end;
  if (MD5Digest1[ 7] > MD5Digest2[ 7]) then begin Result := -1; Exit; end else if (MD5Digest1[ 7] < MD5Digest2[ 7]) then begin Result := 1; Exit; end;
  if (MD5Digest1[ 8] > MD5Digest2[ 8]) then begin Result := -1; Exit; end else if (MD5Digest1[ 8] < MD5Digest2[ 8]) then begin Result := 1; Exit; end;
  if (MD5Digest1[ 9] > MD5Digest2[ 9]) then begin Result := -1; Exit; end else if (MD5Digest1[ 9] < MD5Digest2[ 9]) then begin Result := 1; Exit; end;
  if (MD5Digest1[10] > MD5Digest2[10]) then begin Result := -1; Exit; end else if (MD5Digest1[10] < MD5Digest2[10]) then begin Result := 1; Exit; end;
  if (MD5Digest1[11] > MD5Digest2[11]) then begin Result := -1; Exit; end else if (MD5Digest1[11] < MD5Digest2[11]) then begin Result := 1; Exit; end;
  if (MD5Digest1[12] > MD5Digest2[12]) then begin Result := -1; Exit; end else if (MD5Digest1[12] < MD5Digest2[12]) then begin Result := 1; Exit; end;
  if (MD5Digest1[13] > MD5Digest2[13]) then begin Result := -1; Exit; end else if (MD5Digest1[13] < MD5Digest2[13]) then begin Result := 1; Exit; end;
  if (MD5Digest1[14] > MD5Digest2[14]) then begin Result := -1; Exit; end else if (MD5Digest1[14] < MD5Digest2[14]) then begin Result := 1; Exit; end;
  if (MD5Digest1[15] > MD5Digest2[15]) then begin Result := -1; Exit; end else if (MD5Digest1[15] < MD5Digest2[15]) then begin Result := 1; Exit; end;

  Result := 0;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

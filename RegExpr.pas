{
 TRegExpr class library
 Delphi Regular Expressions

 Copyright (c) 1999-2004 Andrey V. Sorokin, St.Petersburg, Russia

 You may use this software in any kind of development,
 including comercial, redistribute, and modify it freely,
 under the following restrictions :

 1. This software is provided as it is, without any kind of
    warranty given. Use it at Your own risk.The author is not
    responsible for any consequences of use of this software.

 2. The origin of this software may not be mispresented, You
    must not claim that You wrote the original software. If
    You use this software in any kind of product, it would be
    appreciated that there in a information box, or in the
    documentation would be an acknowledgement like

     Partial Copyright (c) 2004 Andrey V. Sorokin
                                http://RegExpStudio.com
                                mailto:anso@mail.ru

 3. You may not have any income from distributing this source
    (or altered version of it) to other developers. When You
    use this product in a comercial package, the source may
    not be charged seperatly.

 4. Altered versions must be plainly marked as such, and must
    not be misrepresented as being the original software.

 5. RegExp Studio application and all the visual components as
    well as documentation is not part of the TRegExpr library
    and is not free for usage.

                                    mailto:anso@mail.ru
                                    http://RegExpStudio.com
                                    http://anso.da.ru/
}
unit RegExpr;
interface
{$IFDEF VER80} Sorry, TRegExpr is for 32-bits Delphi only. Delphi 1 is not supported (and whos really care today?!). {$ENDIF}
{$IFDEF VER90} {$DEFINE D2} {$ENDIF}
{$IFDEF VER93} {$DEFINE D2} {$ENDIF}
{$IFDEF VER100} {$DEFINE D3} {$DEFINE D2} {$ENDIF}
{$IFDEF VER110} {$DEFINE D4} {$DEFINE D3} {$DEFINE D2} {$ENDIF}
{$IFDEF VER120} {$DEFINE D4} {$DEFINE D3} {$DEFINE D2} {$ENDIF}
{$IFDEF VER130} {$DEFINE D5} {$DEFINE D4} {$DEFINE D3} {$DEFINE D2} {$ENDIF}
{$IFDEF VER140} {$DEFINE D6} {$DEFINE D5} {$DEFINE D4} {$DEFINE D3} {$DEFINE D2} {$ENDIF}
{$IFDEF VER150} {$DEFINE D7} {$DEFINE D6} {$DEFINE D5} {$DEFINE D4} {$DEFINE D3} {$DEFINE D2} {$ENDIF}
{$BOOLEVAL OFF}
{$EXTENDEDSYNTAX ON}
{$LONGSTRINGS ON}
{$OPTIMIZATION ON}
{$IFDEF D6}
{$WARN SYMBOL_PLATFORM OFF}
{$ENDIF}
{$IFDEF D7}
{$WARN UNSAFE_CAST OFF}
{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CODE OFF}
{$ENDIF}
{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}
{.$DEFINE Unicode}
{$DEFINE RegExpPCodeDump}
{$IFNDEF FPC}
{$DEFINE reRealExceptionAddr}
{$ENDIF}
{$DEFINE ComplexBraces}
{$IFNDEF Unicode}
{$DEFINE UseSetOfChar}
{$ENDIF}
{$IFDEF UseSetOfChar}
{$DEFINE UseFirstCharSet}
{$ENDIF}
{$IFDEF D3} {$DEFINE UseAsserts} {$ENDIF}
{$IFDEF FPC} {$DEFINE UseAsserts} {$ENDIF}
{$IFDEF D4} {$DEFINE DefParam} {$ENDIF}
{$IFDEF D5} {$DEFINE OverMeth} {$ENDIF}
{$IFDEF FPC} {$DEFINE OverMeth} {$ENDIF}
uses
Classes, SysUtils;
type
{$IFDEF Unicode}
PRegExprChar = PWideChar;
RegExprString = WideString;
REChar = WideChar;
{$ELSE}
PRegExprChar = PChar;
RegExprString = AnsiString;
REChar = Char;
{$ENDIF}
TREOp = REChar;
PREOp = ^TREOp;
TRENextOff = integer;
PRENextOff = ^TRENextOff;
TREBracesArg = integer;
PREBracesArg = ^TREBracesArg;
const
REOpSz = SizeOf (TREOp) div SizeOf (REChar);
RENextOffSz = SizeOf (TRENextOff) div SizeOf (REChar);
REBracesArgSz = SizeOf (TREBracesArg) div SizeOf (REChar);
type
TRegExprInvertCaseFunction = function (const Ch : REChar) : REChar of object;
const
EscChar = '\';
RegExprModifierI : boolean = False;
RegExprModifierR : boolean = True;
RegExprModifierS : boolean = True;
RegExprModifierG : boolean = True;
RegExprModifierM : boolean = False;
RegExprModifierX : boolean = False;
RegExprSpaceChars : RegExprString = ' '#$9#$A#$D#$C;
RegExprWordChars : RegExprString = '0123456789' + 'abcdefghijklmnopqrstuvwxyz' + 'ABCDEFGHIJKLMNOPQRSTUVWXYZ_';
RegExprLineSeparators : RegExprString = #$d#$a{$IFDEF Unicode}+#$b#$c#$2028#$2029#$85{$ENDIF};
RegExprLinePairedSeparator : RegExprString = #$d#$a;
const
NSUBEXP = 15;
NSUBEXPMAX = 255;
MaxBracesArg = $7FFFFFFF - 1;
{$IFDEF ComplexBraces}
LoopStackMax = 10;
{$ENDIF}
TinySetLen = 3;
type
{$IFDEF UseSetOfChar}
PSetOfREChar = ^TSetOfREChar;
TSetOfREChar = set of REChar;
{$ENDIF}
TRegExpr = class;
TRegExprReplaceFunction = function (ARegExpr : TRegExpr): string
of object;
TRegExpr = class
private
startp : array [0 .. NSUBEXP - 1] of PRegExprChar;
endp : array [0 .. NSUBEXP - 1] of PRegExprChar;
{$IFDEF ComplexBraces}
LoopStack : array [1 .. LoopStackMax] of integer;
LoopStackIdx : integer;
{$ENDIF}
regstart : REChar;
reganch : REChar;
regmust : PRegExprChar;
regmlen : integer;
{$IFDEF UseFirstCharSet}
FirstCharSet : TSetOfREChar;
{$ENDIF}
reginput : PRegExprChar;
fInputStart : PRegExprChar;
fInputEnd : PRegExprChar;
regparse : PRegExprChar;
regnpar : integer;
regdummy : char;
regcode : PRegExprChar;
regsize : integer;
regexpbeg : PRegExprChar;
fExprIsCompiled : boolean;
programm : PRegExprChar;
fExpression : PRegExprChar;
fInputString : PRegExprChar;
fLastError : integer;
fModifiers : integer;
fCompModifiers : integer;
fProgModifiers : integer;
fSpaceChars : RegExprString;
fWordChars : RegExprString;
fInvertCase : TRegExprInvertCaseFunction;
fLineSeparators : RegExprString;
fLinePairedSeparatorAssigned : boolean;
fLinePairedSeparatorHead, fLinePairedSeparatorTail : REChar;
{$IFNDEF Unicode}
fLineSeparatorsSet : set of REChar;
{$ENDIF}
procedure InvalidateProgramm;
function IsProgrammOk : boolean;
function GetExpression : RegExprString;
procedure SetExpression (const s : RegExprString);
function GetModifierStr : RegExprString;
class function ParseModifiersStr (const AModifiers : RegExprString;
var AModifiersInt : integer) : boolean;
procedure SetModifierStr (const AModifiers : RegExprString);
function GetModifier (AIndex : integer) : boolean;
procedure SetModifier (AIndex : integer; ASet : boolean);
procedure Error (AErrorID : integer); virtual;
function CompileRegExpr (exp : PRegExprChar) : boolean;
procedure Tail (p : PRegExprChar; val : PRegExprChar);
procedure OpTail (p : PRegExprChar; val : PRegExprChar);
function EmitNode (op : TREOp) : PRegExprChar;
procedure EmitC (b : REChar);
procedure InsertOperator (op : TREOp; opnd : PRegExprChar; sz : integer);
function ParseReg (paren : integer; var flagp : integer) : PRegExprChar;
function ParseBranch (var flagp : integer) : PRegExprChar;
function ParsePiece (var flagp : integer) : PRegExprChar;
function ParseAtom (var flagp : integer) : PRegExprChar;
function GetCompilerErrorPos : integer;
{$IFDEF UseFirstCharSet}
procedure FillFirstCharSet (prog : PRegExprChar);
{$ENDIF}
function regrepeat (p : PRegExprChar; AMax : integer) : integer;
function regnext (p : PRegExprChar) : PRegExprChar;
function MatchPrim (prog : PRegExprChar) : boolean;
function ExecPrim (AOffset: integer) : boolean;
{$IFDEF RegExpPCodeDump}
function DumpOp (op : REChar) : RegExprString;
{$ENDIF}
function GetSubExprMatchCount : integer;
function GetMatchPos (Idx : integer) : integer;
function GetMatchLen (Idx : integer) : integer;
function GetMatch (Idx : integer) : RegExprString;
function GetInputString : RegExprString;
procedure SetInputString (const AInputString : RegExprString);
{$IFNDEF UseSetOfChar}
function StrScanCI (s : PRegExprChar; ch : REChar) : PRegExprChar;
{$ENDIF}
procedure SetLineSeparators (const AStr : RegExprString);
procedure SetLinePairedSeparator (const AStr : RegExprString);
function GetLinePairedSeparator : RegExprString;
public
constructor Create;
destructor Destroy; override;
class function VersionMajor : integer;
class function VersionMinor : integer;
property Expression : RegExprString read GetExpression write SetExpression;
property ModifierStr : RegExprString read GetModifierStr write SetModifierStr;
property ModifierI : boolean index 1 read GetModifier write SetModifier;
property ModifierR : boolean index 2 read GetModifier write SetModifier;
property ModifierS : boolean index 3 read GetModifier write SetModifier;
property ModifierG : boolean index 4 read GetModifier write SetModifier;
property ModifierM : boolean index 5 read GetModifier write SetModifier;
property ModifierX : boolean index 6 read GetModifier write SetModifier;
function Exec (const AInputString : RegExprString) : boolean; {$IFDEF OverMeth} overload;
{$IFNDEF FPC}
function Exec : boolean; overload;
{$ENDIF}
function Exec (AOffset: integer) : boolean; overload;
{$ENDIF}
function ExecNext : boolean;
function ExecPos (AOffset: integer {$IFDEF DefParam}= 1{$ENDIF}) : boolean;
property InputString : RegExprString read GetInputString write SetInputString;
function Substitute (const ATemplate : RegExprString) : RegExprString;
procedure Split (AInputStr : RegExprString; APieces : TStrings);
function Replace (AInputStr : RegExprString;
const AReplaceStr : RegExprString;
AUseSubstitution : boolean{$IFDEF DefParam}= False{$ENDIF})
: RegExprString; {$IFDEF OverMeth} overload;
function Replace (AInputStr : RegExprString;
AReplaceFunc : TRegExprReplaceFunction)
: RegExprString; overload;
{$ENDIF}
function ReplaceEx (AInputStr : RegExprString;
AReplaceFunc : TRegExprReplaceFunction)
: RegExprString;
property SubExprMatchCount : integer read GetSubExprMatchCount;
property MatchPos [Idx : integer] : integer read GetMatchPos;
property MatchLen [Idx : integer] : integer read GetMatchLen;
property Match [Idx : integer] : RegExprString read GetMatch;
function LastError : integer;
function ErrorMsg (AErrorID : integer) : RegExprString; virtual;
property CompilerErrorPos : integer read GetCompilerErrorPos;
property SpaceChars : RegExprString read fSpaceChars write fSpaceChars;
property WordChars : RegExprString read fWordChars write fWordChars;
property LineSeparators : RegExprString read fLineSeparators write SetLineSeparators;
property LinePairedSeparator : RegExprString read GetLinePairedSeparator write SetLinePairedSeparator;
class function InvertCaseFunction (const Ch : REChar) : REChar;
property InvertCase : TRegExprInvertCaseFunction read fInvertCase write fInvertCase;
procedure Compile;
{$IFDEF RegExpPCodeDump}
function Dump : RegExprString;
{$ENDIF}
end;
ERegExpr = class (Exception)
public
ErrorCode : integer;
CompilerErrorPos : integer;
end;
const
RegExprInvertCaseFunction : TRegExprInvertCaseFunction = {$IFDEF FPC} nil {$ELSE} TRegExpr.InvertCaseFunction{$ENDIF};
function ExecRegExpr (const ARegExpr, AInputStr : RegExprString) : boolean;
procedure SplitRegExpr (const ARegExpr, AInputStr : RegExprString; APieces : TStrings);
function ReplaceRegExpr (const ARegExpr, AInputStr, AReplaceStr : RegExprString;
AUseSubstitution : boolean{$IFDEF DefParam}= False{$ENDIF}) : RegExprString;
function QuoteRegExprMetaChars (const AStr : RegExprString) : RegExprString;
function RegExprSubExpressions (const ARegExpr : string;
ASubExprs : TStrings; AExtendedSyntax : boolean{$IFDEF DefParam}= False{$ENDIF}) : integer;
implementation
uses
Windows;
const
TRegExprVersionMajor : integer = 0;
TRegExprVersionMinor : integer = 952;
MaskModI = 1;
MaskModR = 2;
MaskModS = 4;
MaskModG = 8;
MaskModM = 16;
MaskModX = 32;
{$IFDEF Unicode}
XIgnoredChars = ' '#9#$d#$a;
{$ELSE}
XIgnoredChars = [' ', #9, #$d, #$a];
{$ENDIF}
{$IFDEF Unicode}
function StrPCopy (Dest: PRegExprChar; const Source: RegExprString): PRegExprChar;
var
i, Len : Integer;
begin
Len := length (Source);
for i := 1 to Len do
Dest [i - 1] := Source [i];
Dest [Len] := #0;
Result := Dest;
end;
function StrLCopy (Dest, Source: PRegExprChar; MaxLen: Cardinal): PRegExprChar;
var i: Integer;
begin
for i := 0 to MaxLen - 1 do
Dest [i] := Source [i];
Result := Dest;
end;
function StrLen (Str: PRegExprChar): Cardinal;
begin
Result:=0;
while Str [result] <> #0
do Inc (Result);
end;
function StrPos (Str1, Str2: PRegExprChar): PRegExprChar;
var n: Integer;
begin
Result := nil;
n := Pos (RegExprString (Str2), RegExprString (Str1));
if n = 0
then EXIT;
Result := Str1 + n - 1;
end;
function StrLComp (Str1, Str2: PRegExprChar; MaxLen: Cardinal): Integer;
var S1, S2: RegExprString;
begin
S1 := Str1;
S2 := Str2;
if Copy (S1, 1, MaxLen) > Copy (S2, 1, MaxLen)
then Result := 1
else
if Copy (S1, 1, MaxLen) < Copy (S2, 1, MaxLen)
then Result := -1
else Result := 0;
end;
function StrScan (Str: PRegExprChar; Chr: WideChar): PRegExprChar;
begin
Result := nil;
while (Str^ <> #0) and (Str^ <> Chr)
do Inc (Str);
if (Str^ <> #0)
then Result := Str;
end;
{$ENDIF}
function ExecRegExpr (const ARegExpr, AInputStr : RegExprString) : boolean;
var r : TRegExpr;
begin
r := TRegExpr.Create;
try
r.Expression := ARegExpr;
Result := r.Exec (AInputStr);
finally r.Free;
end;
end;
procedure SplitRegExpr (const ARegExpr, AInputStr : RegExprString; APieces : TStrings);
var r : TRegExpr;
begin
APieces.Clear;
r := TRegExpr.Create;
try
r.Expression := ARegExpr;
r.Split (AInputStr, APieces);
finally r.Free;
end;
end;
function ReplaceRegExpr (const ARegExpr, AInputStr, AReplaceStr : RegExprString;
AUseSubstitution : boolean{$IFDEF DefParam}= False{$ENDIF}) : RegExprString;
begin
with TRegExpr.Create do try
Expression := ARegExpr;
Result := Replace (AInputStr, AReplaceStr, AUseSubstitution);
finally Free;
end;
end;
function QuoteRegExprMetaChars (const AStr : RegExprString) : RegExprString;
const
RegExprMetaSet : RegExprString = '^$.[()|?+*'+EscChar+'{' + ']}';
var
i, i0, Len : integer;
begin
Result := '';
Len := length (AStr);
i := 1;
i0 := i;
while i <= Len do begin
if Pos (AStr [i], RegExprMetaSet) > 0 then begin
Result := Result + System.Copy (AStr, i0, i - i0) + EscChar + AStr [i];
i0 := i + 1;
end;
inc (i);
end;
Result := Result + System.Copy (AStr, i0, MaxInt);
end;
function RegExprSubExpressions (const ARegExpr : string;
ASubExprs : TStrings; AExtendedSyntax : boolean{$IFDEF DefParam} = False{$ENDIF}) : integer;
type
TStackItemRec = record
SubExprIdx : integer;
StartPos : integer;
end;
TStackArray = packed array [0 .. NSUBEXPMAX - 1] of TStackItemRec;
var
Len, SubExprLen : integer;
i, i0 : integer;
Modif : integer;
Stack : ^TStackArray;
StackIdx, StackSz : integer;
begin
Result := 0;
ASubExprs.Clear;
Len := length (ARegExpr);
StackSz := 1;
for i := 1 to Len do
if ARegExpr [i] = '('
then inc (StackSz);
GetMem (Stack, SizeOf (TStackItemRec) * StackSz);
try
StackIdx := 0;
i := 1;
while (i <= Len) do begin
case ARegExpr [i] of
'(': begin
if (i < Len) and (ARegExpr [i + 1] = '?') then begin
inc (i, 2);
i0 := i;
while (i <= Len) and (ARegExpr [i] <> ')')
do inc (i);
if i > Len
then Result := -1
else
if TRegExpr.ParseModifiersStr (System.Copy (ARegExpr, i, i - i0), Modif)
then AExtendedSyntax := (Modif and MaskModX) <> 0;
end
else begin
ASubExprs.Add ('');
with Stack [StackIdx] do begin
SubExprIdx := ASubExprs.Count - 1;
StartPos := i;
end;
inc (StackIdx);
end;
end;
')': begin
if StackIdx = 0
then Result := i
else begin
dec (StackIdx);
with Stack [StackIdx] do begin
SubExprLen := i - StartPos + 1;
ASubExprs.Objects [SubExprIdx] := TObject (StartPos or (SubExprLen ShL 16));
ASubExprs [SubExprIdx] := System.Copy (
ARegExpr, StartPos + 1, SubExprLen - 2);
end;
end;
end;
EscChar: inc (i);
'[': begin
i0 := i;
inc (i);
if ARegExpr [i] = ']'
then inc (i);
while (i <= Len) and (ARegExpr [i] <> ']') do
if ARegExpr [i] = EscChar
then inc (i, 2)
else inc (i);
if (i > Len) or (ARegExpr [i] <> ']')
then Result := - (i0 + 1);
end;
'#': if AExtendedSyntax then begin
while (i <= Len) and (ARegExpr [i] <> #$d) and (ARegExpr [i] <> #$a)
do inc (i);
while (i + 1 <= Len) and ((ARegExpr [i + 1] = #$d) or (ARegExpr [i + 1] = #$a))
do inc (i);
end;
end;
inc (i);
end;
if StackIdx <> 0
then Result := -1;
if (ASubExprs.Count = 0)
or ((integer (ASubExprs.Objects [0]) and $FFFF) <> 1)
or (((integer (ASubExprs.Objects [0]) ShR 16) and $FFFF) <> Len)
then ASubExprs.InsertObject (0, ARegExpr, TObject ((Len ShL 16) or 1));
finally FreeMem (Stack);
end;
end;
const
MAGIC = TREOp (216);
EEND = TREOp (0);
BOL = TREOp (1);
EOL = TREOp (2);
ANY = TREOp (3);
ANYOF = TREOp (4);
ANYBUT = TREOp (5);
BRANCH = TREOp (6);
BACK = TREOp (7);
EXACTLY = TREOp (8);
NOTHING = TREOp (9);
STAR = TREOp (10);
PLUS = TREOp (11);
ANYDIGIT = TREOp (12);
NOTDIGIT = TREOp (13);
ANYLETTER = TREOp (14);
NOTLETTER = TREOp (15);
ANYSPACE = TREOp (16);
NOTSPACE = TREOp (17);
BRACES = TREOp (18);
COMMENT = TREOp (19);
EXACTLYCI = TREOp (20);
ANYOFCI = TREOp (21);
ANYBUTCI = TREOp (22);
LOOPENTRY = TREOp (23);
LOOP = TREOp (24);
ANYOFTINYSET= TREOp (25);
ANYBUTTINYSET=TREOp (26);
ANYOFFULLSET= TREOp (27);
BSUBEXP = TREOp (28);
BSUBEXPCI = TREOp (29);
STARNG = TREOp (30);
PLUSNG = TREOp (31);
BRACESNG = TREOp (32);
LOOPNG = TREOp (33);
BOLML = TREOp (34);
EOLML = TREOp (35);
ANYML = TREOp (36);
BOUND = TREOp (37);
NOTBOUND = TREOp (38);
OPEN = TREOp (39);
CLOSE = TREOp (ord (OPEN) + NSUBEXP);
const
reeOk = 0;
reeCompNullArgument = 100;
reeCompRegexpTooBig = 101;
reeCompParseRegTooManyBrackets = 102;
reeCompParseRegUnmatchedBrackets = 103;
reeCompParseRegUnmatchedBrackets2 = 104;
reeCompParseRegJunkOnEnd = 105;
reePlusStarOperandCouldBeEmpty = 106;
reeNestedSQP = 107;
reeBadHexDigit = 108;
reeInvalidRange = 109;
reeParseAtomTrailingBackSlash = 110;
reeNoHexCodeAfterBSlashX = 111;
reeHexCodeAfterBSlashXTooBig = 112;
reeUnmatchedSqBrackets = 113;
reeInternalUrp = 114;
reeQPSBFollowsNothing = 115;
reeTrailingBackSlash = 116;
reeRarseAtomInternalDisaster = 119;
reeBRACESArgTooBig = 122;
reeBracesMinParamGreaterMax = 124;
reeUnclosedComment = 125;
reeComplexBracesNotImplemented = 126;
reeUrecognizedModifier = 127;
reeBadLinePairedSeparator = 128;
reeRegRepeatCalledInappropriately = 1000;
reeMatchPrimMemoryCorruption = 1001;
reeMatchPrimCorruptedPointers = 1002;
reeNoExpression = 1003;
reeCorruptedProgram = 1004;
reeNoInpitStringSpecified = 1005;
reeOffsetMustBeGreaterThen0 = 1006;
reeExecNextWithoutExec = 1007;
reeGetInputStringWithoutInputString = 1008;
reeDumpCorruptedOpcode = 1011;
reeModifierUnsupported = 1013;
reeLoopStackExceeded = 1014;
reeLoopWithoutEntry = 1015;
reeBadPCodeImported = 2000;
function TRegExpr.ErrorMsg (AErrorID : integer) : RegExprString;
begin
case AErrorID of
reeOk: Result := 'No errors';
reeCompNullArgument: Result := 'TRegExpr(comp): Null Argument';
reeCompRegexpTooBig: Result := 'TRegExpr(comp): Regexp Too Big';
reeCompParseRegTooManyBrackets: Result := 'TRegExpr(comp): ParseReg Too Many ()';
reeCompParseRegUnmatchedBrackets: Result := 'TRegExpr(comp): ParseReg Unmatched ()';
reeCompParseRegUnmatchedBrackets2: Result := 'TRegExpr(comp): ParseReg Unmatched ()';
reeCompParseRegJunkOnEnd: Result := 'TRegExpr(comp): ParseReg Junk On End';
reePlusStarOperandCouldBeEmpty: Result := 'TRegExpr(comp): *+ Operand Could Be Empty';
reeNestedSQP: Result := 'TRegExpr(comp): Nested *?+';
reeBadHexDigit: Result := 'TRegExpr(comp): Bad Hex Digit';
reeInvalidRange: Result := 'TRegExpr(comp): Invalid [] Range';
reeParseAtomTrailingBackSlash: Result := 'TRegExpr(comp): Parse Atom Trailing \';
reeNoHexCodeAfterBSlashX: Result := 'TRegExpr(comp): No Hex Code After \x';
reeHexCodeAfterBSlashXTooBig: Result := 'TRegExpr(comp): Hex Code After \x Is Too Big';
reeUnmatchedSqBrackets: Result := 'TRegExpr(comp): Unmatched []';
reeInternalUrp: Result := 'TRegExpr(comp): Internal Urp';
reeQPSBFollowsNothing: Result := 'TRegExpr(comp): ?+*{ Follows Nothing';
reeTrailingBackSlash: Result := 'TRegExpr(comp): Trailing \';
reeRarseAtomInternalDisaster: Result := 'TRegExpr(comp): RarseAtom Internal Disaster';
reeBRACESArgTooBig: Result := 'TRegExpr(comp): BRACES Argument Too Big';
reeBracesMinParamGreaterMax: Result := 'TRegExpr(comp): BRACE Min Param Greater then Max';
reeUnclosedComment: Result := 'TRegExpr(comp): Unclosed (?#Comment)';
reeComplexBracesNotImplemented: Result := 'TRegExpr(comp): If you want take part in beta-testing BRACES ''{min,max}'' and non-greedy ops ''*?'', ''+?'', ''??'' for complex cases - remove ''.'' from {.$DEFINE ComplexBraces}';
reeUrecognizedModifier: Result := 'TRegExpr(comp): Urecognized Modifier';
reeBadLinePairedSeparator: Result := 'TRegExpr(comp): LinePairedSeparator must countain two different chars or no chars at all';
reeRegRepeatCalledInappropriately: Result := 'TRegExpr(exec): RegRepeat Called Inappropriately';
reeMatchPrimMemoryCorruption: Result := 'TRegExpr(exec): MatchPrim Memory Corruption';
reeMatchPrimCorruptedPointers: Result := 'TRegExpr(exec): MatchPrim Corrupted Pointers';
reeNoExpression: Result := 'TRegExpr(exec): Not Assigned Expression Property';
reeCorruptedProgram: Result := 'TRegExpr(exec): Corrupted Program';
reeNoInpitStringSpecified: Result := 'TRegExpr(exec): No Input String Specified';
reeOffsetMustBeGreaterThen0: Result := 'TRegExpr(exec): Offset Must Be Greater Then 0';
reeExecNextWithoutExec: Result := 'TRegExpr(exec): ExecNext Without Exec[Pos]';
reeGetInputStringWithoutInputString: Result := 'TRegExpr(exec): GetInputString Without InputString';
reeDumpCorruptedOpcode: Result := 'TRegExpr(dump): Corrupted Opcode';
reeLoopStackExceeded: Result := 'TRegExpr(exec): Loop Stack Exceeded';
reeLoopWithoutEntry: Result := 'TRegExpr(exec): Loop Without LoopEntry !';
reeBadPCodeImported: Result := 'TRegExpr(misc): Bad p-code imported';
else Result := 'Unknown error';
end;
end;
function TRegExpr.LastError : integer;
begin
Result := fLastError;
fLastError := reeOk;
end;
class function TRegExpr.VersionMajor : integer;
begin
Result := TRegExprVersionMajor;
end;
class function TRegExpr.VersionMinor : integer;
begin
Result := TRegExprVersionMinor;
end;
constructor TRegExpr.Create;
begin
inherited;
programm := nil;
fExpression := nil;
fInputString := nil;
regexpbeg := nil;
fExprIsCompiled := false;
ModifierI := RegExprModifierI;
ModifierR := RegExprModifierR;
ModifierS := RegExprModifierS;
ModifierG := RegExprModifierG;
ModifierM := RegExprModifierM;
SpaceChars := RegExprSpaceChars;
WordChars := RegExprWordChars;
fInvertCase := RegExprInvertCaseFunction;
fLineSeparators := RegExprLineSeparators;
LinePairedSeparator := RegExprLinePairedSeparator;
end;
destructor TRegExpr.Destroy;
begin
if programm <> nil
then FreeMem (programm);
if fExpression <> nil
then FreeMem (fExpression);
if fInputString <> nil
then FreeMem (fInputString);
end;
class function TRegExpr.InvertCaseFunction (const Ch : REChar) : REChar;
begin
{$IFDEF Unicode}
if Ch >= #128
then Result := Ch
else
{$ENDIF}
begin
Result := {$IFDEF FPC}AnsiUpperCase (Ch) [1]{$ELSE} REChar (CharUpper (PChar (Ch))){$ENDIF};
if Result = Ch
then Result := {$IFDEF FPC}AnsiLowerCase (Ch) [1]{$ELSE} REChar (CharLower (PChar (Ch))){$ENDIF};
end;
end;
function TRegExpr.GetExpression : RegExprString;
begin
if fExpression <> nil
then Result := fExpression
else Result := '';
end;
procedure TRegExpr.SetExpression (const s : RegExprString);
var
Len : integer;
begin
if (s <> fExpression) or not fExprIsCompiled then begin
fExprIsCompiled := false;
if fExpression <> nil then begin
FreeMem (fExpression);
fExpression := nil;
end;
if s <> '' then begin
Len := length (s);
GetMem (fExpression, (Len + 1) * SizeOf (REChar));
{$IFDEF Unicode}
StrPCopy (fExpression, Copy (s, 1, Len));
{$ELSE}
StrLCopy (fExpression, PRegExprChar (s), Len);
{$ENDIF Unicode}
InvalidateProgramm;
end;
end;
end;
function TRegExpr.GetSubExprMatchCount : integer;
begin
if Assigned (fInputString) then begin
Result := NSUBEXP - 1;
while (Result > 0) and ((startp [Result] = nil)
or (endp [Result] = nil))
do dec (Result);
end
else Result := -1;
end;
function TRegExpr.GetMatchPos (Idx : integer) : integer;
begin
if (Idx >= 0) and (Idx < NSUBEXP) and Assigned (fInputString)
and Assigned (startp [Idx]) and Assigned (endp [Idx]) then begin
Result := (startp [Idx] - fInputString) + 1;
end
else Result := -1;
end;
function TRegExpr.GetMatchLen (Idx : integer) : integer;
begin
if (Idx >= 0) and (Idx < NSUBEXP) and Assigned (fInputString)
and Assigned (startp [Idx]) and Assigned (endp [Idx]) then begin
Result := endp [Idx] - startp [Idx];
end
else Result := -1;
end;
function TRegExpr.GetMatch (Idx : integer) : RegExprString;
begin
if (Idx >= 0) and (Idx < NSUBEXP) and Assigned (fInputString)
and Assigned (startp [Idx]) and Assigned (endp [Idx])
then SetString (Result, startp [idx], endp [idx] - startp [idx])
else Result := '';
end;
function TRegExpr.GetModifierStr : RegExprString;
begin
Result := '-';
if ModifierI
then Result := 'i' + Result
else Result := Result + 'i';
if ModifierR
then Result := 'r' + Result
else Result := Result + 'r';
if ModifierS
then Result := 's' + Result
else Result := Result + 's';
if ModifierG
then Result := 'g' + Result
else Result := Result + 'g';
if ModifierM
then Result := 'm' + Result
else Result := Result + 'm';
if ModifierX
then Result := 'x' + Result
else Result := Result + 'x';
if Result [length (Result)] = '-'
then System.Delete (Result, length (Result), 1);
end;
class function TRegExpr.ParseModifiersStr (const AModifiers : RegExprString;
var AModifiersInt : integer) : boolean;
var
i : integer;
IsOn : boolean;
Mask : integer;
begin
Result := true;
IsOn := true;
Mask := 0;
for i := 1 to length (AModifiers) do
if AModifiers [i] = '-'
then IsOn := false
else begin
if Pos (AModifiers [i], 'iI') > 0
then Mask := MaskModI
else if Pos (AModifiers [i], 'rR') > 0
then Mask := MaskModR
else if Pos (AModifiers [i], 'sS') > 0
then Mask := MaskModS
else if Pos (AModifiers [i], 'gG') > 0
then Mask := MaskModG
else if Pos (AModifiers [i], 'mM') > 0
then Mask := MaskModM
else if Pos (AModifiers [i], 'xX') > 0
then Mask := MaskModX
else begin
Result := false;
EXIT;
end;
if IsOn
then AModifiersInt := AModifiersInt or Mask
else AModifiersInt := AModifiersInt and not Mask;
end;
end;
procedure TRegExpr.SetModifierStr (const AModifiers : RegExprString);
begin
if not ParseModifiersStr (AModifiers, fModifiers)
then Error (reeModifierUnsupported);
end;
function TRegExpr.GetModifier (AIndex : integer) : boolean;
var
Mask : integer;
begin
Result := false;
case AIndex of
1: Mask := MaskModI;
2: Mask := MaskModR;
3: Mask := MaskModS;
4: Mask := MaskModG;
5: Mask := MaskModM;
6: Mask := MaskModX;
else begin
Error (reeModifierUnsupported);
EXIT;
end;
end;
Result := (fModifiers and Mask) <> 0;
end;
procedure TRegExpr.SetModifier (AIndex : integer; ASet : boolean);
var
Mask : integer;
begin
case AIndex of
1: Mask := MaskModI;
2: Mask := MaskModR;
3: Mask := MaskModS;
4: Mask := MaskModG;
5: Mask := MaskModM;
6: Mask := MaskModX;
else begin
Error (reeModifierUnsupported);
EXIT;
end;
end;
if ASet
then fModifiers := fModifiers or Mask
else fModifiers := fModifiers and not Mask;
end;
procedure TRegExpr.InvalidateProgramm;
begin
if programm <> nil then begin
FreeMem (programm);
programm := nil;
end;
end;
procedure TRegExpr.Compile;
begin
if fExpression = nil then begin
Error (reeNoExpression);
EXIT;
end;
CompileRegExpr (fExpression);
end;
function TRegExpr.IsProgrammOk : boolean;
{$IFNDEF Unicode}
var
i : integer;
{$ENDIF}
begin
Result := false;
if fModifiers <> fProgModifiers
then InvalidateProgramm;
{$IFNDEF Unicode}
fLineSeparatorsSet := [];
for i := 1 to length (fLineSeparators)
do System.Include (fLineSeparatorsSet, fLineSeparators [i]);
{$ENDIF}
if programm = nil
then Compile;
if programm = nil
then EXIT
else if programm [0] <> MAGIC
then Error (reeCorruptedProgram)
else Result := true;
end;
procedure TRegExpr.Tail (p : PRegExprChar; val : PRegExprChar);
var
scan : PRegExprChar;
temp : PRegExprChar;
begin
if p = @regdummy
then EXIT;
scan := p;
REPEAT
temp := regnext (scan);
if temp = nil
then BREAK;
scan := temp;
UNTIL false;
if val < scan
then PRENextOff (scan + REOpSz)^ := - (scan - val)
else PRENextOff (scan + REOpSz)^ := val - scan;
end;
procedure TRegExpr.OpTail (p : PRegExprChar; val : PRegExprChar);
begin
if (p = nil) or (p = @regdummy) or (PREOp (p)^ <> BRANCH)
then EXIT;
Tail (p + REOpSz + RENextOffSz, val);
end;
function TRegExpr.EmitNode (op : TREOp) : PRegExprChar;
begin
Result := regcode;
if Result <> @regdummy then begin
PREOp (regcode)^ := op;
inc (regcode, REOpSz);
PRENextOff (regcode)^ := 0;
inc (regcode, RENextOffSz);
end
else inc (regsize, REOpSz + RENextOffSz);
end;
procedure TRegExpr.EmitC (b : REChar);
begin
if regcode <> @regdummy then begin
regcode^ := b;
inc (regcode);
end
else inc (regsize);
end;
procedure TRegExpr.InsertOperator (op : TREOp; opnd : PRegExprChar; sz : integer);
var
src, dst, place : PRegExprChar;
i : integer;
begin
if regcode = @regdummy then begin
inc (regsize, sz);
EXIT;
end;
src := regcode;
inc (regcode, sz);
dst := regcode;
while src > opnd do begin
dec (dst);
dec (src);
dst^ := src^;
end;
place := opnd;
PREOp (place)^ := op;
inc (place, REOpSz);
for i := 1 + REOpSz to sz do begin
place^ := #0;
inc (place);
end;
end;
function strcspn (s1 : PRegExprChar; s2 : PRegExprChar) : integer;
var scan1, scan2 : PRegExprChar;
begin
Result := 0;
scan1 := s1;
while scan1^ <> #0 do begin
scan2 := s2;
while scan2^ <> #0 do
if scan1^ = scan2^
then EXIT
else inc (scan2);
inc (Result);
inc (scan1)
end;
end;
const
HASWIDTH = 01;
SIMPLE = 02;
SPSTART = 04;
WORST = 0;
META : array [0 .. 12] of REChar = ('^', '$', '.', '[', '(', ')', '|', '?', '+', '*', EscChar, '{', #0);
{$IFDEF Unicode}
RusRangeLo : array [0 .. 33] of REChar = (#$430,#$431,#$432,#$433,#$434,#$435,#$451,#$436,#$437, #$438,#$439,#$43A,#$43B,#$43C,#$43D,#$43E,#$43F, #$440,#$441,#$442,#$443,#$444,#$445,#$446,#$447, #$448,#$449,#$44A,#$44B,#$44C,#$44D,#$44E,#$44F,#0);
RusRangeHi : array [0 .. 33] of REChar = (#$410,#$411,#$412,#$413,#$414,#$415,#$401,#$416,#$417, #$418,#$419,#$41A,#$41B,#$41C,#$41D,#$41E,#$41F, #$420,#$421,#$422,#$423,#$424,#$425,#$426,#$427, #$428,#$429,#$42A,#$42B,#$42C,#$42D,#$42E,#$42F,#0);
RusRangeLoLow = #$430{'à'};
RusRangeLoHigh = #$44F{'ÿ'};
RusRangeHiLow = #$410{'À'};
RusRangeHiHigh = #$42F{'ß'};
{$ELSE}
RusRangeLo = 'àáâãäåžæçèéêëìíîïðñòóôõö÷øùúûüýþÿ';
RusRangeHi = 'ÀÁÂÃÄÅšÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞß';
RusRangeLoLow = 'à';
RusRangeLoHigh = 'ÿ';
RusRangeHiLow = 'À';
RusRangeHiHigh = 'ß';
{$ENDIF}
function TRegExpr.CompileRegExpr (exp : PRegExprChar) : boolean;
var
scan, longest : PRegExprChar;
len : cardinal;
flags : integer;
begin
Result := false;
regparse := nil;
regexpbeg := exp;
try
if programm <> nil then begin
FreeMem (programm);
programm := nil;
end;
if exp = nil then begin
Error (reeCompNullArgument);
EXIT;
end;
fProgModifiers := fModifiers;
fCompModifiers := fModifiers;
regparse := exp;
regnpar := 1;
regsize := 0;
regcode := @regdummy;
EmitC (MAGIC);
if ParseReg (0, flags) = nil
then EXIT;
GetMem (programm, regsize * SizeOf (REChar));
fCompModifiers := fModifiers;
regparse := exp;
regnpar := 1;
regcode := programm;
EmitC (MAGIC);
if ParseReg (0, flags) = nil
then EXIT;
{$IFDEF UseFirstCharSet}
FirstCharSet := [];
FillFirstCharSet (programm + REOpSz);
{$ENDIF}
regstart := #0;
reganch := #0;
regmust := nil;
regmlen := 0;
scan := programm + REOpSz;
if PREOp (regnext (scan))^ = EEND then begin
scan := scan + REOpSz + RENextOffSz;
if PREOp (scan)^ = EXACTLY
then regstart := (scan + REOpSz + RENextOffSz)^
else if PREOp (scan)^ = BOL
then inc (reganch);
if (flags and SPSTART) <> 0 then begin
longest := nil;
len := 0;
while scan <> nil do begin
if (PREOp (scan)^ = EXACTLY)
and (strlen (scan + REOpSz + RENextOffSz) >= len) then begin
longest := scan + REOpSz + RENextOffSz;
len := strlen (longest);
end;
scan := regnext (scan);
end;
regmust := longest;
regmlen := len;
end;
end;
Result := true;
finally begin
if not Result
then InvalidateProgramm;
regexpbeg := nil;
fExprIsCompiled := Result;
end;
end;
end;
function TRegExpr.ParseReg (paren : integer; var flagp : integer) : PRegExprChar;
var
ret, br, ender : PRegExprChar;
parno : integer;
flags : integer;
SavedModifiers : integer;
begin
Result := nil;
flagp := HASWIDTH;
parno := 0;
SavedModifiers := fCompModifiers;
if paren <> 0 then begin
if regnpar >= NSUBEXP then begin
Error (reeCompParseRegTooManyBrackets);
EXIT;
end;
parno := regnpar;
inc (regnpar);
ret := EmitNode (TREOp (ord (OPEN) + parno));
end
else ret := nil;
br := ParseBranch (flags);
if br = nil then begin
Result := nil;
EXIT;
end;
if ret <> nil
then Tail (ret, br)
else ret := br;
if (flags and HASWIDTH) = 0
then flagp := flagp and not HASWIDTH;
flagp := flagp or flags and SPSTART;
while (regparse^ = '|') do begin
inc (regparse);
br := ParseBranch (flags);
if br = nil then begin
Result := nil;
EXIT;
end;
Tail (ret, br);
if (flags and HASWIDTH) = 0
then flagp := flagp and not HASWIDTH;
flagp := flagp or flags and SPSTART;
end;
if paren <> 0
then ender := EmitNode (TREOp (ord (CLOSE) + parno))
else ender := EmitNode (EEND);
Tail (ret, ender);
br := ret;
while br <> nil do begin
OpTail (br, ender);
br := regnext (br);
end;
if paren <> 0 then
if regparse^ <> ')' then begin
Error (reeCompParseRegUnmatchedBrackets);
EXIT;
end
else inc (regparse);
if (paren = 0) and (regparse^ <> #0) then begin
if regparse^ = ')'
then Error (reeCompParseRegUnmatchedBrackets2)
else Error (reeCompParseRegJunkOnEnd);
EXIT;
end;
fCompModifiers := SavedModifiers;
Result := ret;
end;
function TRegExpr.ParseBranch (var flagp : integer) : PRegExprChar;
var
ret, chain, latest : PRegExprChar;
flags : integer;
begin
flagp := WORST;
ret := EmitNode (BRANCH);
chain := nil;
while (regparse^ <> #0) and (regparse^ <> '|')
and (regparse^ <> ')') do begin
latest := ParsePiece (flags);
if latest = nil then begin
Result := nil;
EXIT;
end;
flagp := flagp or flags and HASWIDTH;
if chain = nil
then flagp := flagp or flags and SPSTART
else Tail (chain, latest);
chain := latest;
end;
if chain = nil
then EmitNode (NOTHING);
Result := ret;
end;
function TRegExpr.ParsePiece (var flagp : integer) : PRegExprChar;
function parsenum (AStart, AEnd : PRegExprChar) : TREBracesArg;
begin
Result := 0;
if AEnd - AStart + 1 > 8 then begin
Error (reeBRACESArgTooBig);
EXIT;
end;
while AStart <= AEnd do begin
Result := Result * 10 + (ord (AStart^) - ord ('0'));
inc (AStart);
end;
if (Result > MaxBracesArg) or (Result < 0) then begin
Error (reeBRACESArgTooBig);
EXIT;
end;
end;
var
op : REChar;
NonGreedyOp, NonGreedyCh : boolean;
TheOp : TREOp;
NextNode : PRegExprChar;
flags : integer;
BracesMin, Bracesmax : TREBracesArg;
p, savedparse : PRegExprChar;
procedure EmitComplexBraces (ABracesMin, ABracesMax : TREBracesArg;
ANonGreedyOp : boolean);
{$IFDEF ComplexBraces}
var
off : integer;
{$ENDIF}
begin
{$IFNDEF ComplexBraces}
Error (reeComplexBracesNotImplemented);
{$ELSE}
if ANonGreedyOp
then TheOp := LOOPNG
else TheOp := LOOP;
InsertOperator (LOOPENTRY, Result, REOpSz + RENextOffSz);
NextNode := EmitNode (TheOp);
if regcode <> @regdummy then begin
off := (Result + REOpSz + RENextOffSz)
- (regcode - REOpSz - RENextOffSz);
PREBracesArg (regcode)^ := ABracesMin;
inc (regcode, REBracesArgSz);
PREBracesArg (regcode)^ := ABracesMax;
inc (regcode, REBracesArgSz);
PRENextOff (regcode)^ := off;
inc (regcode, RENextOffSz);
end
else inc (regsize, REBracesArgSz * 2 + RENextOffSz);
Tail (Result, NextNode);
if regcode <> @regdummy then
Tail (Result + REOpSz + RENextOffSz, NextNode);
{$ENDIF}
end;
procedure EmitSimpleBraces (ABracesMin, ABracesMax : TREBracesArg;
ANonGreedyOp : boolean);
begin
if ANonGreedyOp
then TheOp := BRACESNG
else TheOp := BRACES;
InsertOperator (TheOp, Result, REOpSz + RENextOffSz + REBracesArgSz * 2);
if regcode <> @regdummy then begin
PREBracesArg (Result + REOpSz + RENextOffSz)^ := ABracesMin;
PREBracesArg (Result + REOpSz + RENextOffSz + REBracesArgSz)^ := ABracesMax;
end;
end;
begin
Result := ParseAtom (flags);
if Result = nil
then EXIT;
op := regparse^;
if not ((op = '*') or (op = '+') or (op = '?') or (op = '{')) then begin
flagp := flags;
EXIT;
end;
if ((flags and HASWIDTH) = 0) and (op <> '?') then begin
Error (reePlusStarOperandCouldBeEmpty);
EXIT;
end;
case op of
'*': begin
flagp := WORST or SPSTART;
NonGreedyCh := (regparse + 1)^ = '?';
NonGreedyOp := NonGreedyCh or ((fCompModifiers and MaskModG) = 0);
if (flags and SIMPLE) = 0 then begin
if NonGreedyOp
then EmitComplexBraces (0, MaxBracesArg, NonGreedyOp)
else begin
InsertOperator (BRANCH, Result, REOpSz + RENextOffSz);
OpTail (Result, EmitNode (BACK));
OpTail (Result, Result);
Tail (Result, EmitNode (BRANCH));
Tail (Result, EmitNode (NOTHING));
end
end
else begin
if NonGreedyOp
then TheOp := STARNG
else TheOp := STAR;
InsertOperator (TheOp, Result, REOpSz + RENextOffSz);
end;
if NonGreedyCh
then inc (regparse);
end; { of case '*'}
'+': begin
flagp := WORST or SPSTART or HASWIDTH;
NonGreedyCh := (regparse + 1)^ = '?';
NonGreedyOp := NonGreedyCh or ((fCompModifiers and MaskModG) = 0);
if (flags and SIMPLE) = 0 then begin
if NonGreedyOp
then EmitComplexBraces (1, MaxBracesArg, NonGreedyOp)
else begin
NextNode := EmitNode (BRANCH);
Tail (Result, NextNode);
Tail (EmitNode (BACK), Result);
Tail (NextNode, EmitNode (BRANCH));
Tail (Result, EmitNode (NOTHING));
end
end
else begin
if NonGreedyOp
then TheOp := PLUSNG
else TheOp := PLUS;
InsertOperator (TheOp, Result, REOpSz + RENextOffSz);
end;
if NonGreedyCh
then inc (regparse);
end; { of case '+'}
'?': begin
flagp := WORST;
NonGreedyCh := (regparse + 1)^ = '?';
NonGreedyOp := NonGreedyCh or ((fCompModifiers and MaskModG) = 0);
if NonGreedyOp then begin
if (flags and SIMPLE) = 0
then EmitComplexBraces (0, 1, NonGreedyOp)
else EmitSimpleBraces (0, 1, NonGreedyOp);
end
else begin
InsertOperator (BRANCH, Result, REOpSz + RENextOffSz);
Tail (Result, EmitNode (BRANCH));
NextNode := EmitNode (NOTHING);
Tail (Result, NextNode);
OpTail (Result, NextNode);
end;
if NonGreedyCh
then inc (regparse);
end; { of case '?'}
'{': begin
savedparse := regparse;
inc (regparse);
p := regparse;
while Pos (regparse^, '0123456789') > 0
do inc (regparse);
if (regparse^ <> '}') and (regparse^ <> ',') or (p = regparse) then begin
regparse := savedparse;
flagp := flags;
EXIT;
end;
BracesMin := parsenum (p, regparse - 1);
if regparse^ = ',' then begin
inc (regparse);
p := regparse;
while Pos (regparse^, '0123456789') > 0
do inc (regparse);
if regparse^ <> '}' then begin
regparse := savedparse;
EXIT;
end;
if p = regparse
then BracesMax := MaxBracesArg
else BracesMax := parsenum (p, regparse - 1);
end
else BracesMax := BracesMin;
if BracesMin > BracesMax then begin
Error (reeBracesMinParamGreaterMax);
EXIT;
end;
if BracesMin > 0
then flagp := WORST;
if BracesMax > 0
then flagp := flagp or HASWIDTH or SPSTART;
NonGreedyCh := (regparse + 1)^ = '?';
NonGreedyOp := NonGreedyCh or ((fCompModifiers and MaskModG) = 0);
if (flags and SIMPLE) <> 0
then EmitSimpleBraces (BracesMin, BracesMax, NonGreedyOp)
else EmitComplexBraces (BracesMin, BracesMax, NonGreedyOp);
if NonGreedyCh
then inc (regparse);
end; { of case '{'}
end; { of case op}
inc (regparse);
if (regparse^ = '*') or (regparse^ = '+') or (regparse^ = '?') or (regparse^ = '{') then begin
Error (reeNestedSQP);
EXIT;
end;
end;
function TRegExpr.ParseAtom (var flagp : integer) : PRegExprChar;
var
ret : PRegExprChar;
flags : integer;
RangeBeg, RangeEnd : REChar;
CanBeRange : boolean;
len : integer;
ender : REChar;
begmodfs : PRegExprChar;
{$IFDEF UseSetOfChar}
RangePCodeBeg : PRegExprChar;
RangePCodeIdx : integer;
RangeIsCI : boolean;
RangeSet : TSetOfREChar;
RangeLen : integer;
RangeChMin, RangeChMax : REChar;
{$ENDIF}
procedure EmitExactly (ch : REChar);
begin
if (fCompModifiers and MaskModI) <> 0
then ret := EmitNode (EXACTLYCI)
else ret := EmitNode (EXACTLY);
EmitC (ch);
EmitC (#0);
flagp := flagp or HASWIDTH or SIMPLE;
end;
procedure EmitStr (const s : RegExprString);
var i : integer;
begin
for i := 1 to length (s)
do EmitC (s [i]);
end;
function HexDig (ch : REChar) : integer;
begin
Result := 0;
if (ch >= 'a') and (ch <= 'f')
then ch := REChar (ord (ch) - (ord ('a') - ord ('A')));
if (ch < '0') or (ch > 'F') or ((ch > '9') and (ch < 'A')) then begin
Error (reeBadHexDigit);
EXIT;
end;
Result := ord (ch) - ord ('0');
if ch >= 'A'
then Result := Result - (ord ('A') - ord ('9') - 1);
end;
function EmitRange (AOpCode : REChar) : PRegExprChar;
begin
{$IFDEF UseSetOfChar}
case AOpCode of
ANYBUTCI, ANYBUT:
Result := EmitNode (ANYBUTTINYSET);
else
Result := EmitNode (ANYOFTINYSET);
end;
case AOpCode of
ANYBUTCI, ANYOFCI:
RangeIsCI := True;
else
RangeIsCI := False;
end;
RangePCodeBeg := regcode;
RangePCodeIdx := regsize;
RangeLen := 0;
RangeSet := [];
RangeChMin := #255;
RangeChMax := #0;
{$ELSE}
Result := EmitNode (AOpCode);
{$ENDIF}
end;
{$IFDEF UseSetOfChar}
procedure EmitRangeCPrim (b : REChar);
begin
if b in RangeSet
then EXIT;
inc (RangeLen);
if b < RangeChMin
then RangeChMin := b;
if b > RangeChMax
then RangeChMax := b;
Include (RangeSet, b);
end;
{$ENDIF}
procedure EmitRangeC (b : REChar);
{$IFDEF UseSetOfChar}
var
Ch : REChar;
{$ENDIF}
begin
CanBeRange := false;
{$IFDEF UseSetOfChar}
if b <> #0 then begin
EmitRangeCPrim (b);
if RangeIsCI
then EmitRangeCPrim (InvertCase (b));
end
else begin
{$IFDEF UseAsserts}
Assert (RangeLen > 0, 'TRegExpr.ParseAtom(subroutine EmitRangeC): empty range');
Assert (RangeChMin <= RangeChMax, 'TRegExpr.ParseAtom(subroutine EmitRangeC): RangeChMin > RangeChMax');
{$ENDIF}
if RangeLen <= TinySetLen then begin
if regcode = @regdummy then begin
regsize := RangePCodeIdx + TinySetLen;
EXIT;
end;
regcode := RangePCodeBeg;
for Ch := RangeChMin to RangeChMax do
if Ch in RangeSet then begin
regcode^ := Ch;
inc (regcode);
end;
while regcode < RangePCodeBeg + TinySetLen do begin
regcode^ := RangeChMax;
inc (regcode);
end;
end
else begin
if regcode = @regdummy then begin
regsize := RangePCodeIdx + SizeOf (TSetOfREChar);
EXIT;
end;
if (RangePCodeBeg - REOpSz - RENextOffSz)^ = ANYBUTTINYSET
then RangeSet := [#0 .. #255] - RangeSet;
PREOp (RangePCodeBeg - REOpSz - RENextOffSz)^ := ANYOFFULLSET;
regcode := RangePCodeBeg;
Move (RangeSet, regcode^, SizeOf (TSetOfREChar));
inc (regcode, SizeOf (TSetOfREChar));
end;
end;
{$ELSE}
EmitC (b);
{$ENDIF}
end;
procedure EmitSimpleRangeC (b : REChar);
begin
RangeBeg := b;
EmitRangeC (b);
CanBeRange := true;
end;
procedure EmitRangeStr (const s : RegExprString);
var i : integer;
begin
for i := 1 to length (s)
do EmitRangeC (s [i]);
end;
function UnQuoteChar (var APtr : PRegExprChar) : REChar;
begin
case APtr^ of
't': Result := #$9;
'n': Result := #$a;
'r': Result := #$d;
'f': Result := #$c;
'a': Result := #$7;
'e': Result := #$1b;
'x': begin
Result := #0;
inc (APtr);
if APtr^ = #0 then begin
Error (reeNoHexCodeAfterBSlashX);
EXIT;
end;
if APtr^ = '{' then begin
REPEAT
inc (APtr);
if APtr^ = #0 then begin
Error (reeNoHexCodeAfterBSlashX);
EXIT;
end;
if APtr^ <> '}' then begin
if (Ord (Result)
ShR (SizeOf (REChar) * 8 - 4)) and $F <> 0 then begin
Error (reeHexCodeAfterBSlashXTooBig);
EXIT;
end;
Result := REChar ((Ord (Result) ShL 4) or HexDig (APtr^));
end
else BREAK;
UNTIL False;
end
else begin
Result := REChar (HexDig (APtr^));
inc (APtr);
if APtr^ = #0 then begin
Error (reeNoHexCodeAfterBSlashX);
EXIT;
end;
Result := REChar ((Ord (Result) ShL 4) or HexDig (APtr^));
end;
end;
else Result := APtr^;
end;
end;
begin
Result := nil;
flagp := WORST;
inc (regparse);
case (regparse - 1)^ of
'^': if ((fCompModifiers and MaskModM) = 0)
or ((fLineSeparators = '') and not fLinePairedSeparatorAssigned)
then ret := EmitNode (BOL)
else ret := EmitNode (BOLML);
'$': if ((fCompModifiers and MaskModM) = 0)
or ((fLineSeparators = '') and not fLinePairedSeparatorAssigned)
then ret := EmitNode (EOL)
else ret := EmitNode (EOLML);
'.':
if (fCompModifiers and MaskModS) <> 0 then begin
ret := EmitNode (ANY);
flagp := flagp or HASWIDTH or SIMPLE;
end
else begin
ret := EmitNode (ANYML);
flagp := flagp or HASWIDTH;
end;
'[': begin
if regparse^ = '^' then begin
if (fCompModifiers and MaskModI) <> 0
then ret := EmitRange (ANYBUTCI)
else ret := EmitRange (ANYBUT);
inc (regparse);
end
else
if (fCompModifiers and MaskModI) <> 0
then ret := EmitRange (ANYOFCI)
else ret := EmitRange (ANYOF);
CanBeRange := false;
if (regparse^ = ']') then begin
EmitSimpleRangeC (regparse^);
inc (regparse);
end;
while (regparse^ <> #0) and (regparse^ <> ']') do begin
if (regparse^ = '-')
and ((regparse + 1)^ <> #0) and ((regparse + 1)^ <> ']')
and CanBeRange then begin
inc (regparse);
RangeEnd := regparse^;
if RangeEnd = EscChar then begin
{$IFDEF Unicode}
if (ord ((regparse + 1)^) < 256)
and (char ((regparse + 1)^)
in ['d', 'D', 's', 'S', 'w', 'W']) then begin
{$ELSE}
if (regparse + 1)^ in ['d', 'D', 's', 'S', 'w', 'W'] then begin
{$ENDIF}
EmitRangeC ('-');
CONTINUE;
end;
inc (regparse);
RangeEnd := UnQuoteChar (regparse);
end;
if ((fCompModifiers and MaskModR) <> 0)
and (RangeBeg = RusRangeLoLow) and (RangeEnd = RusRangeLoHigh) then begin
EmitRangeStr (RusRangeLo);
end
else if ((fCompModifiers and MaskModR) <> 0)
and (RangeBeg = RusRangeHiLow) and (RangeEnd = RusRangeHiHigh) then begin
EmitRangeStr (RusRangeHi);
end
else if ((fCompModifiers and MaskModR) <> 0)
and (RangeBeg = RusRangeLoLow) and (RangeEnd = RusRangeHiHigh) then begin
EmitRangeStr (RusRangeLo);
EmitRangeStr (RusRangeHi);
end
else begin
if RangeBeg > RangeEnd then begin
Error (reeInvalidRange);
EXIT;
end;
inc (RangeBeg);
EmitRangeC (RangeEnd);
while RangeBeg < RangeEnd do begin
EmitRangeC (RangeBeg);
inc (RangeBeg);
end;
end;
inc (regparse);
end
else begin
if regparse^ = EscChar then begin
inc (regparse);
if regparse^ = #0 then begin
Error (reeParseAtomTrailingBackSlash);
EXIT;
end;
case regparse^ of
'd': EmitRangeStr ('0123456789');
'w': EmitRangeStr (WordChars);
's': EmitRangeStr (SpaceChars);
else EmitSimpleRangeC (UnQuoteChar (regparse));
end; { of case}
end
else EmitSimpleRangeC (regparse^);
inc (regparse);
end;
end; { of while}
EmitRangeC (#0);
if regparse^ <> ']' then begin
Error (reeUnmatchedSqBrackets);
EXIT;
end;
inc (regparse);
flagp := flagp or HASWIDTH or SIMPLE;
end;
'(': begin
if regparse^ = '?' then begin
if (regparse + 1)^ = '#' then begin
inc (regparse, 2);
while (regparse^ <> #0) and (regparse^ <> ')')
do inc (regparse);
if regparse^ <> ')' then begin
Error (reeUnclosedComment);
EXIT;
end;
inc (regparse);
ret := EmitNode (COMMENT);
end
else begin
inc (regparse);
begmodfs := regparse;
while (regparse^ <> #0) and (regparse^ <> ')')
do inc (regparse);
if (regparse^ <> ')')
or not ParseModifiersStr (copy (begmodfs, 1, (regparse - begmodfs)), fCompModifiers) then begin
Error (reeUrecognizedModifier);
EXIT;
end;
inc (regparse);
ret := EmitNode (COMMENT);
end;
end
else begin
ret := ParseReg (1, flags);
if ret = nil then begin
Result := nil;
EXIT;
end;
flagp := flagp or flags and (HASWIDTH or SPSTART);
end;
end;
#0, '|', ')': begin
Error (reeInternalUrp);
EXIT;
end;
'?', '+', '*': begin
Error (reeQPSBFollowsNothing);
EXIT;
end;
EscChar: begin
if regparse^ = #0 then begin
Error (reeTrailingBackSlash);
EXIT;
end;
case regparse^ of
'b': ret := EmitNode (BOUND);
'B': ret := EmitNode (NOTBOUND);
'A': ret := EmitNode (BOL);
'Z': ret := EmitNode (EOL);
'd': begin
ret := EmitNode (ANYDIGIT);
flagp := flagp or HASWIDTH or SIMPLE;
end;
'D': begin
ret := EmitNode (NOTDIGIT);
flagp := flagp or HASWIDTH or SIMPLE;
end;
's': begin
{$IFDEF UseSetOfChar}
ret := EmitRange (ANYOF);
EmitRangeStr (SpaceChars);
EmitRangeC (#0);
{$ELSE}
ret := EmitNode (ANYSPACE);
{$ENDIF}
flagp := flagp or HASWIDTH or SIMPLE;
end;
'S': begin
{$IFDEF UseSetOfChar}
ret := EmitRange (ANYBUT);
EmitRangeStr (SpaceChars);
EmitRangeC (#0);
{$ELSE}
ret := EmitNode (NOTSPACE);
{$ENDIF}
flagp := flagp or HASWIDTH or SIMPLE;
end;
'w': begin
{$IFDEF UseSetOfChar}
ret := EmitRange (ANYOF);
EmitRangeStr (WordChars);
EmitRangeC (#0);
{$ELSE}
ret := EmitNode (ANYLETTER);
{$ENDIF}
flagp := flagp or HASWIDTH or SIMPLE;
end;
'W': begin
{$IFDEF UseSetOfChar}
ret := EmitRange (ANYBUT);
EmitRangeStr (WordChars);
EmitRangeC (#0);
{$ELSE}
ret := EmitNode (NOTLETTER);
{$ENDIF}
flagp := flagp or HASWIDTH or SIMPLE;
end;
'1' .. '9': begin
if (fCompModifiers and MaskModI) <> 0
then ret := EmitNode (BSUBEXPCI)
else ret := EmitNode (BSUBEXP);
EmitC (REChar (ord (regparse^) - ord ('0')));
flagp := flagp or HASWIDTH or SIMPLE;
end;
else EmitExactly (UnQuoteChar (regparse));
end; { of case}
inc (regparse);
end;
else begin
dec (regparse);
if ((fCompModifiers and MaskModX) <> 0) and
((regparse^ = '#')
or ({$IFDEF Unicode}StrScan (XIgnoredChars, regparse^) <> nil
{$ELSE}regparse^ in XIgnoredChars{$ENDIF})) then begin
if regparse^ = '#' then begin
while (regparse^ <> #0) and (regparse^ <> #$d) and (regparse^ <> #$a)
do inc (regparse);
while (regparse^ = #$d) or (regparse^ = #$a)
do inc (regparse);
end
else begin
while {$IFDEF Unicode}StrScan (XIgnoredChars, regparse^) <> nil
{$ELSE}regparse^ in XIgnoredChars{$ENDIF}
do inc (regparse);
end;
ret := EmitNode (COMMENT);
end
else begin
len := strcspn (regparse, META);
if len <= 0 then
if regparse^ <> '{' then begin
Error (reeRarseAtomInternalDisaster);
EXIT;
end
else len := strcspn (regparse + 1, META) + 1;
ender := (regparse + len)^;
if (len > 1)
and ((ender = '*') or (ender = '+') or (ender = '?') or (ender = '{'))
then dec (len);
flagp := flagp or HASWIDTH;
if len = 1
then flagp := flagp or SIMPLE;
if (fCompModifiers and MaskModI) <> 0
then ret := EmitNode (EXACTLYCI)
else ret := EmitNode (EXACTLY);
while (len > 0)
and (((fCompModifiers and MaskModX) = 0) or (regparse^ <> '#')) do begin
if ((fCompModifiers and MaskModX) = 0) or not (
{$IFDEF Unicode}StrScan (XIgnoredChars, regparse^) <> nil
{$ELSE}regparse^ in XIgnoredChars{$ENDIF} )
then EmitC (regparse^);
inc (regparse);
dec (len);
end;
EmitC (#0);
end; { of if not comment}
end; { of case else}
end; { of case}
Result := ret;
end;
function TRegExpr.GetCompilerErrorPos : integer;
begin
Result := 0;
if (regexpbeg = nil) or (regparse = nil)
then EXIT;
Result := regparse - regexpbeg;
end;
{$IFNDEF UseSetOfChar}
function TRegExpr.StrScanCI (s : PRegExprChar; ch : REChar) : PRegExprChar;
begin
while (s^ <> #0) and (s^ <> ch) and (s^ <> InvertCase (ch))
do inc (s);
if s^ <> #0
then Result := s
else Result := nil;
end;
{$ENDIF}
function TRegExpr.regrepeat (p : PRegExprChar; AMax : integer) : integer;
var
scan : PRegExprChar;
opnd : PRegExprChar;
TheMax : integer;
{Ch,} InvCh : REChar;
sestart, seend : PRegExprChar;
begin
Result := 0;
scan := reginput;
opnd := p + REOpSz + RENextOffSz;
TheMax := fInputEnd - scan;
if TheMax > AMax
then TheMax := AMax;
case PREOp (p)^ of
ANY: begin
Result := TheMax;
inc (scan, Result);
end;
EXACTLY: begin
while (Result < TheMax) and (opnd^ = scan^) do begin
inc (Result);
inc (scan);
end;
end;
EXACTLYCI: begin
while (Result < TheMax) and (opnd^ = scan^) do begin
inc (Result);
inc (scan);
end;
if Result < TheMax then begin
InvCh := InvertCase (opnd^);
while (Result < TheMax) and
((opnd^ = scan^) or (InvCh = scan^)) do begin
inc (Result);
inc (scan);
end;
end;
end;
BSUBEXP: begin
sestart := startp [ord (opnd^)];
if sestart = nil
then EXIT;
seend := endp [ord (opnd^)];
if seend = nil
then EXIT;
REPEAT
opnd := sestart;
while opnd < seend do begin
if (scan >= fInputEnd) or (scan^ <> opnd^)
then EXIT;
inc (scan);
inc (opnd);
end;
inc (Result);
reginput := scan;
UNTIL Result >= AMax;
end;
BSUBEXPCI: begin
sestart := startp [ord (opnd^)];
if sestart = nil
then EXIT;
seend := endp [ord (opnd^)];
if seend = nil
then EXIT;
REPEAT
opnd := sestart;
while opnd < seend do begin
if (scan >= fInputEnd) or
((scan^ <> opnd^) and (scan^ <> InvertCase (opnd^)))
then EXIT;
inc (scan);
inc (opnd);
end;
inc (Result);
reginput := scan;
UNTIL Result >= AMax;
end;
ANYDIGIT:
while (Result < TheMax) and
(scan^ >= '0') and (scan^ <= '9') do begin
inc (Result);
inc (scan);
end;
NOTDIGIT:
while (Result < TheMax) and
((scan^ < '0') or (scan^ > '9')) do begin
inc (Result);
inc (scan);
end;
{$IFNDEF UseSetOfChar}
ANYLETTER:
while (Result < TheMax) and
(Pos (scan^, fWordChars) > 0)
{ ((scan^ >= 'a') and (scan^ <= 'z') !! I've forgotten (>='0') and (<='9')
or (scan^ >= 'A') and (scan^ <= 'Z') or (scan^ = '_'))} do begin
inc (Result);
inc (scan);
end;
NOTLETTER:
while (Result < TheMax) and
(Pos (scan^, fWordChars) <= 0)
{ not ((scan^ >= 'a') and (scan^ <= 'z') !! I've forgotten (>='0') and (<='9')
or (scan^ >= 'A') and (scan^ <= 'Z')
or (scan^ = '_'))} do begin
inc (Result);
inc (scan);
end;
ANYSPACE:
while (Result < TheMax) and
(Pos (scan^, fSpaceChars) > 0) do begin
inc (Result);
inc (scan);
end;
NOTSPACE:
while (Result < TheMax) and
(Pos (scan^, fSpaceChars) <= 0) do begin
inc (Result);
inc (scan);
end;
{$ENDIF}
ANYOFTINYSET: begin
while (Result < TheMax) and
((scan^ = opnd^) or (scan^ = (opnd + 1)^)
or (scan^ = (opnd + 2)^)) do begin
inc (Result);
inc (scan);
end;
end;
ANYBUTTINYSET: begin
while (Result < TheMax) and
(scan^ <> opnd^) and (scan^ <> (opnd + 1)^)
and (scan^ <> (opnd + 2)^) do begin
inc (Result);
inc (scan);
end;
end;
{$IFDEF UseSetOfChar}
ANYOFFULLSET: begin
while (Result < TheMax) and
(scan^ in PSetOfREChar (opnd)^) do begin
inc (Result);
inc (scan);
end;
end;
{$ELSE}
ANYOF:
while (Result < TheMax) and
(StrScan (opnd, scan^) <> nil) do begin
inc (Result);
inc (scan);
end;
ANYBUT:
while (Result < TheMax) and
(StrScan (opnd, scan^) = nil) do begin
inc (Result);
inc (scan);
end;
ANYOFCI:
while (Result < TheMax) and (StrScanCI (opnd, scan^) <> nil) do begin
inc (Result);
inc (scan);
end;
ANYBUTCI:
while (Result < TheMax) and (StrScanCI (opnd, scan^) = nil) do begin
inc (Result);
inc (scan);
end;
{$ENDIF}
else begin
Result := 0;
Error (reeRegRepeatCalledInappropriately);
EXIT;
end;
end; { of case}
reginput := scan;
end;
function TRegExpr.regnext (p : PRegExprChar) : PRegExprChar;
var offset : TRENextOff;
begin
if p = @regdummy then begin
Result := nil;
EXIT;
end;
offset := PRENextOff (p + REOpSz)^;
if offset = 0
then Result := nil
else Result := p + offset;
end;
function TRegExpr.MatchPrim (prog : PRegExprChar) : boolean;
var
scan : PRegExprChar;
next : PRegExprChar;
len : integer;
opnd : PRegExprChar;
no : integer;
save : PRegExprChar;
nextch : REChar;
BracesMin, BracesMax : integer;
{$IFDEF ComplexBraces}
SavedLoopStack : array [1 .. LoopStackMax] of integer;
SavedLoopStackIdx : integer;
{$ENDIF}
begin
Result := false;
scan := prog;
while scan <> nil do begin
len := PRENextOff (scan + 1)^;
if len = 0
then next := nil
else next := scan + len;
case scan^ of
NOTBOUND, BOUND:
if (scan^ = BOUND)
xor (
((reginput = fInputStart) or (Pos ((reginput - 1)^, fWordChars) <= 0))
and (reginput^ <> #0) and (Pos (reginput^, fWordChars) > 0)
or
(reginput <> fInputStart) and (Pos ((reginput - 1)^, fWordChars) > 0)
and ((reginput^ = #0) or (Pos (reginput^, fWordChars) <= 0)))
then EXIT;
BOL: if reginput <> fInputStart
then EXIT;
EOL: if reginput^ <> #0
then EXIT;
BOLML: if reginput > fInputStart then begin
nextch := (reginput - 1)^;
if (nextch <> fLinePairedSeparatorTail)
or ((reginput - 1) <= fInputStart)
or ((reginput - 2)^ <> fLinePairedSeparatorHead)
then begin
if (nextch = fLinePairedSeparatorHead)
and (reginput^ = fLinePairedSeparatorTail)
then EXIT;
if
{$IFNDEF Unicode}
not (nextch in fLineSeparatorsSet)
{$ELSE}
(pos (nextch, fLineSeparators) <= 0)
{$ENDIF}
then EXIT;
end;
end;
EOLML: if reginput^ <> #0 then begin
nextch := reginput^;
if (nextch <> fLinePairedSeparatorHead)
or ((reginput + 1)^ <> fLinePairedSeparatorTail)
then begin
if (nextch = fLinePairedSeparatorTail)
and (reginput > fInputStart)
and ((reginput - 1)^ = fLinePairedSeparatorHead)
then EXIT;
if
{$IFNDEF Unicode}
not (nextch in fLineSeparatorsSet)
{$ELSE}
(pos (nextch, fLineSeparators) <= 0)
{$ENDIF}
then EXIT;
end;
end;
ANY: begin
if reginput^ = #0
then EXIT;
inc (reginput);
end;
ANYML: begin
if (reginput^ = #0)
or ((reginput^ = fLinePairedSeparatorHead)
and ((reginput + 1)^ = fLinePairedSeparatorTail))
or {$IFNDEF Unicode} (reginput^ in fLineSeparatorsSet)
{$ELSE} (pos (reginput^, fLineSeparators) > 0) {$ENDIF}
then EXIT;
inc (reginput);
end;
ANYDIGIT: begin
if (reginput^ = #0) or (reginput^ < '0') or (reginput^ > '9')
then EXIT;
inc (reginput);
end;
NOTDIGIT: begin
if (reginput^ = #0) or ((reginput^ >= '0') and (reginput^ <= '9'))
then EXIT;
inc (reginput);
end;
{$IFNDEF UseSetOfChar}
ANYLETTER: begin
if (reginput^ = #0) or (Pos (reginput^, fWordChars) <= 0)
then EXIT;
inc (reginput);
end;
NOTLETTER: begin
if (reginput^ = #0) or (Pos (reginput^, fWordChars) > 0)
then EXIT;
inc (reginput);
end;
ANYSPACE: begin
if (reginput^ = #0) or not (Pos (reginput^, fSpaceChars) > 0)
then EXIT;
inc (reginput);
end;
NOTSPACE: begin
if (reginput^ = #0) or (Pos (reginput^, fSpaceChars) > 0)
then EXIT;
inc (reginput);
end;
{$ENDIF}
EXACTLYCI: begin
opnd := scan + REOpSz + RENextOffSz;
if (opnd^ <> reginput^)
and (InvertCase (opnd^) <> reginput^)
then EXIT;
len := strlen (opnd);
no := len;
save := reginput;
while no > 1 do begin
inc (save);
inc (opnd);
if (opnd^ <> save^)
and (InvertCase (opnd^) <> save^)
then EXIT;
dec (no);
end;
inc (reginput, len);
end;
EXACTLY: begin
opnd := scan + REOpSz + RENextOffSz;
if opnd^ <> reginput^
then EXIT;
len := strlen (opnd);
no := len;
save := reginput;
while no > 1 do begin
inc (save);
inc (opnd);
if opnd^ <> save^
then EXIT;
dec (no);
end;
inc (reginput, len);
end;
BSUBEXP: begin
no := ord ((scan + REOpSz + RENextOffSz)^);
if startp [no] = nil
then EXIT;
if endp [no] = nil
then EXIT;
save := reginput;
opnd := startp [no];
while opnd < endp [no] do begin
if (save >= fInputEnd) or (save^ <> opnd^)
then EXIT;
inc (save);
inc (opnd);
end;
reginput := save;
end;
BSUBEXPCI: begin
no := ord ((scan + REOpSz + RENextOffSz)^);
if startp [no] = nil
then EXIT;
if endp [no] = nil
then EXIT;
save := reginput;
opnd := startp [no];
while opnd < endp [no] do begin
if (save >= fInputEnd) or
((save^ <> opnd^) and (save^ <> InvertCase (opnd^)))
then EXIT;
inc (save);
inc (opnd);
end;
reginput := save;
end;
ANYOFTINYSET: begin
if (reginput^ = #0) or
((reginput^ <> (scan + REOpSz + RENextOffSz)^)
and (reginput^ <> (scan + REOpSz + RENextOffSz + 1)^)
and (reginput^ <> (scan + REOpSz + RENextOffSz + 2)^))
then EXIT;
inc (reginput);
end;
ANYBUTTINYSET: begin
if (reginput^ = #0) or
(reginput^ = (scan + REOpSz + RENextOffSz)^)
or (reginput^ = (scan + REOpSz + RENextOffSz + 1)^)
or (reginput^ = (scan + REOpSz + RENextOffSz + 2)^)
then EXIT;
inc (reginput);
end;
{$IFDEF UseSetOfChar}
ANYOFFULLSET: begin
if (reginput^ = #0)
or not (reginput^ in PSetOfREChar (scan + REOpSz + RENextOffSz)^)
then EXIT;
inc (reginput);
end;
{$ELSE}
ANYOF: begin
if (reginput^ = #0) or (StrScan (scan + REOpSz + RENextOffSz, reginput^) = nil)
then EXIT;
inc (reginput);
end;
ANYBUT: begin
if (reginput^ = #0) or (StrScan (scan + REOpSz + RENextOffSz, reginput^) <> nil)
then EXIT;
inc (reginput);
end;
ANYOFCI: begin
if (reginput^ = #0) or (StrScanCI (scan + REOpSz + RENextOffSz, reginput^) = nil)
then EXIT;
inc (reginput);
end;
ANYBUTCI: begin
if (reginput^ = #0) or (StrScanCI (scan + REOpSz + RENextOffSz, reginput^) <> nil)
then EXIT;
inc (reginput);
end;
{$ENDIF}
NOTHING: ;
COMMENT: ;
BACK: ;
Succ (OPEN) .. TREOp (Ord (OPEN) + NSUBEXP - 1) : begin
no := ord (scan^) - ord (OPEN);
save := startp [no];
startp [no] := reginput;
Result := MatchPrim (next);
if not Result
then startp [no] := save;
EXIT;
end;
Succ (CLOSE) .. TREOp (Ord (CLOSE) + NSUBEXP - 1): begin
no := ord (scan^) - ord (CLOSE);
save := endp [no];
endp [no] := reginput;
Result := MatchPrim (next);
if not Result
then endp [no] := save;
EXIT;
end;
BRANCH: begin
if (next^ <> BRANCH)
then next := scan + REOpSz + RENextOffSz
else begin
REPEAT
save := reginput;
Result := MatchPrim (scan + REOpSz + RENextOffSz);
if Result
then EXIT;
reginput := save;
scan := regnext (scan);
UNTIL (scan = nil) or (scan^ <> BRANCH);
EXIT;
end;
end;
{$IFDEF ComplexBraces}
LOOPENTRY: begin
no := LoopStackIdx;
inc (LoopStackIdx);
if LoopStackIdx > LoopStackMax then begin
Error (reeLoopStackExceeded);
EXIT;
end;
save := reginput;
LoopStack [LoopStackIdx] := 0;
Result := MatchPrim (next);
LoopStackIdx := no;
if Result
then EXIT;
reginput := save;
EXIT;
end;
LOOP, LOOPNG: begin
if LoopStackIdx <= 0 then begin
Error (reeLoopWithoutEntry);
EXIT;
end;
opnd := scan + PRENextOff (scan + REOpSz + RENextOffSz + 2 * REBracesArgSz)^;
BracesMin := PREBracesArg (scan + REOpSz + RENextOffSz)^;
BracesMax := PREBracesArg (scan + REOpSz + RENextOffSz + REBracesArgSz)^;
save := reginput;
if LoopStack [LoopStackIdx] >= BracesMin then begin
if scan^ = LOOP then begin
if LoopStack [LoopStackIdx] < BracesMax then begin
inc (LoopStack [LoopStackIdx]);
no := LoopStackIdx;
Result := MatchPrim (opnd);
LoopStackIdx := no;
if Result
then EXIT;
reginput := save;
end;
dec (LoopStackIdx);
Result := MatchPrim (next);
if not Result
then reginput := save;
EXIT;
end
else begin
Result := MatchPrim (next);
if Result
then EXIT
else reginput := save;
if LoopStack [LoopStackIdx] < BracesMax then begin
inc (LoopStack [LoopStackIdx]);
no := LoopStackIdx;
Result := MatchPrim (opnd);
LoopStackIdx := no;
if Result
then EXIT;
reginput := save;
end;
dec (LoopStackIdx);
EXIT;
end
end
else begin
inc (LoopStack [LoopStackIdx]);
no := LoopStackIdx;
Result := MatchPrim (opnd);
LoopStackIdx := no;
if Result
then EXIT;
dec (LoopStack [LoopStackIdx]);
reginput := save;
EXIT;
end;
end;
{$ENDIF}
STAR, PLUS, BRACES, STARNG, PLUSNG, BRACESNG: begin
nextch := #0;
if next^ = EXACTLY
then nextch := (next + REOpSz + RENextOffSz)^;
BracesMax := MaxInt;
if (scan^ = STAR) or (scan^ = STARNG)
then BracesMin := 0
else if (scan^ = PLUS) or (scan^ = PLUSNG)
then BracesMin := 1
else begin
BracesMin := PREBracesArg (scan + REOpSz + RENextOffSz)^;
BracesMax := PREBracesArg (scan + REOpSz + RENextOffSz + REBracesArgSz)^;
end;
save := reginput;
opnd := scan + REOpSz + RENextOffSz;
if (scan^ = BRACES) or (scan^ = BRACESNG)
then inc (opnd, 2 * REBracesArgSz);
if (scan^ = PLUSNG) or (scan^ = STARNG) or (scan^ = BRACESNG) then begin
BracesMax := regrepeat (opnd, BracesMax);
no := BracesMin;
while no <= BracesMax do begin
reginput := save + no;
if (nextch = #0) or (reginput^ = nextch) then begin
{$IFDEF ComplexBraces}
System.Move (LoopStack, SavedLoopStack, SizeOf (LoopStack));
SavedLoopStackIdx := LoopStackIdx;
{$ENDIF}
if MatchPrim (next) then begin
Result := true;
EXIT;
end;
{$IFDEF ComplexBraces}
System.Move (SavedLoopStack, LoopStack, SizeOf (LoopStack));
LoopStackIdx := SavedLoopStackIdx;
{$ENDIF}
end;
inc (no);
end; { of while}
EXIT;
end
else begin
no := regrepeat (opnd, BracesMax);
while no >= BracesMin do begin
if (nextch = #0) or (reginput^ = nextch) then begin
{$IFDEF ComplexBraces}
System.Move (LoopStack, SavedLoopStack, SizeOf (LoopStack));
SavedLoopStackIdx := LoopStackIdx;
{$ENDIF}
if MatchPrim (next) then begin
Result := true;
EXIT;
end;
{$IFDEF ComplexBraces}
System.Move (SavedLoopStack, LoopStack, SizeOf (LoopStack));
LoopStackIdx := SavedLoopStackIdx;
{$ENDIF}
end;
dec (no);
reginput := save + no;
end; { of while}
EXIT;
end;
end;
EEND: begin
Result := true;
EXIT;
end;
else begin
Error (reeMatchPrimMemoryCorruption);
EXIT;
end;
end; { of case scan^}
scan := next;
end; { of while scan <> nil}
Error (reeMatchPrimCorruptedPointers);
end;
{$IFDEF UseFirstCharSet}
procedure TRegExpr.FillFirstCharSet (prog : PRegExprChar);
var
scan : PRegExprChar;
next : PRegExprChar;
opnd : PRegExprChar;
min_cnt : integer;
begin
scan := prog;
while scan <> nil do begin
next := regnext (scan);
case PREOp (scan)^ of
BSUBEXP, BSUBEXPCI: begin
FirstCharSet := [#0 .. #255];
EXIT;
end;
BOL, BOLML: ;
EOL, EOLML: begin
Include (FirstCharSet, #0);
if ModifierM
then begin
opnd := PRegExprChar (LineSeparators);
while opnd^ <> #0 do begin
Include (FirstCharSet, opnd^);
inc (opnd);
end;
end;
EXIT;
end;
BOUND, NOTBOUND: ;
ANY, ANYML: begin
FirstCharSet := [#0 .. #255];
EXIT;
end;
ANYDIGIT: begin
FirstCharSet := FirstCharSet + ['0' .. '9'];
EXIT;
end;
NOTDIGIT: begin
FirstCharSet := FirstCharSet + ([#0 .. #255] - ['0' .. '9']);
EXIT;
end;
EXACTLYCI: begin
Include (FirstCharSet, (scan + REOpSz + RENextOffSz)^);
Include (FirstCharSet, InvertCase ((scan + REOpSz + RENextOffSz)^));
EXIT;
end;
EXACTLY: begin
Include (FirstCharSet, (scan + REOpSz + RENextOffSz)^);
EXIT;
end;
ANYOFFULLSET: begin
FirstCharSet := FirstCharSet + PSetOfREChar (scan + REOpSz + RENextOffSz)^;
EXIT;
end;
ANYOFTINYSET: begin
Include (FirstCharSet, (scan + REOpSz + RENextOffSz)^);
Include (FirstCharSet, (scan + REOpSz + RENextOffSz + 1)^);
Include (FirstCharSet, (scan + REOpSz + RENextOffSz + 2)^);
EXIT;
end;
ANYBUTTINYSET: begin
FirstCharSet := FirstCharSet + ([#0 .. #255] - [
(scan + REOpSz + RENextOffSz)^, (scan + REOpSz + RENextOffSz + 1)^, (scan + REOpSz + RENextOffSz + 2)^]);
EXIT;
end;
NOTHING: ;
COMMENT: ;
BACK: ;
Succ (OPEN) .. TREOp (Ord (OPEN) + NSUBEXP - 1) : begin
FillFirstCharSet (next);
EXIT;
end;
Succ (CLOSE) .. TREOp (Ord (CLOSE) + NSUBEXP - 1): begin
FillFirstCharSet (next);
EXIT;
end;
BRANCH: begin
if (PREOp (next)^ <> BRANCH)
then next := scan + REOpSz + RENextOffSz
else begin
REPEAT
FillFirstCharSet (scan + REOpSz + RENextOffSz);
scan := regnext (scan);
UNTIL (scan = nil) or (PREOp (scan)^ <> BRANCH);
EXIT;
end;
end;
{$IFDEF ComplexBraces}
LOOPENTRY: begin
FillFirstCharSet (next);
EXIT;
end;
LOOP, LOOPNG: begin
opnd := scan + PRENextOff (scan + REOpSz + RENextOffSz + REBracesArgSz * 2)^;
min_cnt := PREBracesArg (scan + REOpSz + RENextOffSz)^;
FillFirstCharSet (opnd);
if min_cnt = 0
then FillFirstCharSet (next);
EXIT;
end;
{$ENDIF}
STAR, STARNG:
FillFirstCharSet (scan + REOpSz + RENextOffSz);
PLUS, PLUSNG: begin
FillFirstCharSet (scan + REOpSz + RENextOffSz);
EXIT;
end;
BRACES, BRACESNG: begin
opnd := scan + REOpSz + RENextOffSz + REBracesArgSz * 2;
min_cnt := PREBracesArg (scan + REOpSz + RENextOffSz)^;
FillFirstCharSet (opnd);
if min_cnt > 0
then EXIT;
end;
EEND: begin
FirstCharSet := [#0 .. #255];
EXIT;
end;
else begin
Error (reeMatchPrimMemoryCorruption);
EXIT;
end;
end; { of case scan^}
scan := next;
end; { of while scan <> nil}
end;
{$ENDIF}
function TRegExpr.Exec (const AInputString : RegExprString) : boolean;
begin
InputString := AInputString;
Result := ExecPrim (1);
end;
{$IFDEF OverMeth}
{$IFNDEF FPC}
function TRegExpr.Exec : boolean;
begin
Result := ExecPrim (1);
end;
{$ENDIF}
function TRegExpr.Exec (AOffset: integer) : boolean;
begin
Result := ExecPrim (AOffset);
end;
{$ENDIF}
function TRegExpr.ExecPos (AOffset: integer {$IFDEF DefParam}= 1{$ENDIF}) : boolean;
begin
Result := ExecPrim (AOffset);
end;
function TRegExpr.ExecPrim (AOffset: integer) : boolean;
procedure ClearMatchs;
var i : integer;
begin
for i := 0 to NSUBEXP - 1 do begin
startp [i] := nil;
endp [i] := nil;
end;
end; { of procedure ClearMatchs;
..............................................................}
function RegMatch (str : PRegExprChar) : boolean;
begin
reginput := str;
Result := MatchPrim (programm + REOpSz);
if Result then begin
startp [0] := str;
endp [0] := reginput;
end;
end; { of function RegMatch
..............................................................}
var
s : PRegExprChar;
StartPtr: PRegExprChar;
InputLen : integer;
begin
Result := false;
ClearMatchs;
if not IsProgrammOk
then EXIT;
if not Assigned (fInputString) then begin
Error (reeNoInpitStringSpecified);
EXIT;
end;
InputLen := length (fInputString);
if AOffset < 1 then begin
Error (reeOffsetMustBeGreaterThen0);
EXIT;
end;
if AOffset > (InputLen + 1)
then EXIT;
StartPtr := fInputString + AOffset - 1;
if regmust <> nil then begin
s := StartPtr;
REPEAT
s := StrScan (s, regmust [0]);
if s <> nil then begin
if StrLComp (s, regmust, regmlen) = 0
then BREAK;
inc (s);
end;
UNTIL s = nil;
if s = nil
then EXIT;
end;
fInputStart := fInputString;
fInputEnd := fInputString + InputLen;
{$IFDEF ComplexBraces}
LoopStackIdx := 0;
{$ENDIF}
if reganch <> #0 then begin
Result := RegMatch (StartPtr);
EXIT;
end;
s := StartPtr;
if regstart <> #0 then
REPEAT
s := StrScan (s, regstart);
if s <> nil then begin
Result := RegMatch (s);
if Result
then EXIT
else ClearMatchs;
inc (s);
end;
UNTIL s = nil
else begin
repeat
{$IFDEF UseFirstCharSet}
if s^ in FirstCharSet
then Result := RegMatch (s);
{$ELSE}
Result := RegMatch (s);
{$ENDIF}
if Result or (s^ = #0)
then EXIT
else ClearMatchs;
inc (s);
until false;
(* optimized and fixed by Martin Fuller - empty strings
were not allowed to pass thru in UseFirstCharSet mode
{$IFDEF UseFirstCharSet}
while s^ <> #0 do begin
if s^ in FirstCharSet
then Result := RegMatch (s);
if Result
then EXIT;
inc (s);
end;
{$ELSE}
REPEAT
Result := RegMatch (s);
if Result
then EXIT;
inc (s);
UNTIL s^ = #0;
{$ENDIF}
*)
end;
end;
function TRegExpr.ExecNext : boolean;
var offset : integer;
begin
Result := false;
if not Assigned (startp[0]) or not Assigned (endp[0]) then begin
Error (reeExecNextWithoutExec);
EXIT;
end;
Offset := endp [0] - fInputString + 1;
if endp [0] = startp [0]
then inc (Offset);
Result := ExecPrim (Offset);
end;
function TRegExpr.GetInputString : RegExprString;
begin
if not Assigned (fInputString) then begin
Error (reeGetInputStringWithoutInputString);
EXIT;
end;
Result := fInputString;
end;
procedure TRegExpr.SetInputString (const AInputString : RegExprString);
var
Len : integer;
i : integer;
begin
for i := 0 to NSUBEXP - 1 do begin
startp [i] := nil;
endp [i] := nil;
end;
Len := length (AInputString);
if Assigned (fInputString) and (Length (fInputString) <> Len) then begin
FreeMem (fInputString);
fInputString := nil;
end;
if not Assigned (fInputString)
then GetMem (fInputString, (Len + 1) * SizeOf (REChar));
{$IFDEF Unicode}
StrPCopy (fInputString, Copy (AInputString, 1, Len));
{$ELSE}
StrLCopy (fInputString, PRegExprChar (AInputString), Len);
{$ENDIF}
{
fInputString : string;
fInputStart, fInputEnd : PRegExprChar;
SetInputString:
fInputString := AInputString;
UniqueString (fInputString);
fInputStart := PChar (fInputString);
Len := length (fInputString);
fInputEnd := PRegExprChar (integer (fInputStart) + Len); ??
!! startp/endp âñå ðàâíî áóäåò îïàñíî èñïîëüçîâàòü ?
}
end;
procedure TRegExpr.SetLineSeparators (const AStr : RegExprString);
begin
if AStr <> fLineSeparators then begin
fLineSeparators := AStr;
InvalidateProgramm;
end;
end;
procedure TRegExpr.SetLinePairedSeparator (const AStr : RegExprString);
begin
if length (AStr) = 2 then begin
if AStr [1] = AStr [2] then begin
Error (reeBadLinePairedSeparator);
EXIT;
end;
if not fLinePairedSeparatorAssigned
or (AStr [1] <> fLinePairedSeparatorHead)
or (AStr [2] <> fLinePairedSeparatorTail) then begin
fLinePairedSeparatorAssigned := true;
fLinePairedSeparatorHead := AStr [1];
fLinePairedSeparatorTail := AStr [2];
InvalidateProgramm;
end;
end
else if length (AStr) = 0 then begin
if fLinePairedSeparatorAssigned then begin
fLinePairedSeparatorAssigned := false;
InvalidateProgramm;
end;
end
else Error (reeBadLinePairedSeparator);
end;
function TRegExpr.GetLinePairedSeparator : RegExprString;
begin
if fLinePairedSeparatorAssigned then begin
{$IFDEF Unicode}
Result := fLinePairedSeparatorHead;
Result := Result + fLinePairedSeparatorTail;
{$ELSE}
Result := fLinePairedSeparatorHead + fLinePairedSeparatorTail;
{$ENDIF}
end
else Result := '';
end;
function TRegExpr.Substitute (const ATemplate : RegExprString) : RegExprString;
var
TemplateLen : integer;
TemplateBeg, TemplateEnd : PRegExprChar;
p, p0, ResultPtr : PRegExprChar;
ResultLen : integer;
n : integer;
Ch : REChar;
function ParseVarName (var APtr : PRegExprChar) : integer;
const
Digits = ['0' .. '9'];
var
p : PRegExprChar;
Delimited : boolean;
begin
Result := 0;
p := APtr;
Delimited := (p < TemplateEnd) and (p^ = '{');
if Delimited
then inc (p);
if (p < TemplateEnd) and (p^ = '&')
then inc (p)
else
while (p < TemplateEnd) and
{$IFDEF Unicode}
(ord (p^) < 256) and (char (p^) in Digits)
{$ELSE}
(p^ in Digits)
{$ENDIF}
do begin
Result := Result * 10 + (ord (p^) - ord ('0'));
inc (p);
end;
if Delimited then
if (p < TemplateEnd) and (p^ = '}')
then inc (p)
else p := APtr;
if p = APtr
then Result := -1;
APtr := p;
end;
begin
if not IsProgrammOk
then EXIT;
if not Assigned (fInputString) then begin
Error (reeNoInpitStringSpecified);
EXIT;
end;
TemplateLen := length (ATemplate);
if TemplateLen = 0 then begin
Result := '';
EXIT;
end;
TemplateBeg := pointer (ATemplate);
TemplateEnd := TemplateBeg + TemplateLen;
ResultLen := 0;
p := TemplateBeg;
while p < TemplateEnd do begin
Ch := p^;
inc (p);
if Ch = '$'
then n := ParseVarName (p)
else n := -1;
if n >= 0 then begin
if (n < NSUBEXP) and Assigned (startp [n]) and Assigned (endp [n])
then inc (ResultLen, endp [n] - startp [n]);
end
else begin
if (Ch = EscChar) and (p < TemplateEnd)
then inc (p);
inc (ResultLen);
end;
end;
if ResultLen = 0 then begin
Result := '';
EXIT;
end;
SetString (Result, nil, ResultLen);
ResultPtr := pointer (Result);
p := TemplateBeg;
while p < TemplateEnd do begin
Ch := p^;
inc (p);
if Ch = '$'
then n := ParseVarName (p)
else n := -1;
if n >= 0 then begin
p0 := startp [n];
if (n < NSUBEXP) and Assigned (p0) and Assigned (endp [n]) then
while p0 < endp [n] do begin
ResultPtr^ := p0^;
inc (ResultPtr);
inc (p0);
end;
end
else begin
if (Ch = EscChar) and (p < TemplateEnd) then begin
Ch := p^;
inc (p);
end;
ResultPtr^ := Ch;
inc (ResultPtr);
end;
end;
end;
procedure TRegExpr.Split (AInputStr : RegExprString; APieces : TStrings);
var PrevPos : integer;
begin
PrevPos := 1;
if Exec (AInputStr) then
REPEAT
APieces.Add (System.Copy (AInputStr, PrevPos, MatchPos [0] - PrevPos));
PrevPos := MatchPos [0] + MatchLen [0];
UNTIL not ExecNext;
APieces.Add (System.Copy (AInputStr, PrevPos, MaxInt));
end;
function TRegExpr.Replace (AInputStr : RegExprString; const AReplaceStr : RegExprString;
AUseSubstitution : boolean{$IFDEF DefParam}= False{$ENDIF}) : RegExprString;
var
PrevPos : integer;
begin
Result := '';
PrevPos := 1;
if Exec (AInputStr) then
REPEAT
Result := Result + System.Copy (AInputStr, PrevPos, MatchPos [0] - PrevPos);
if AUseSubstitution
then Result := Result + Substitute (AReplaceStr)
else Result := Result + AReplaceStr;
PrevPos := MatchPos [0] + MatchLen [0];
UNTIL not ExecNext;
Result := Result + System.Copy (AInputStr, PrevPos, MaxInt);
end;
function TRegExpr.ReplaceEx (AInputStr : RegExprString;
AReplaceFunc : TRegExprReplaceFunction)
: RegExprString;
var
PrevPos : integer;
begin
Result := '';
PrevPos := 1;
if Exec (AInputStr) then
REPEAT
Result := Result + System.Copy (AInputStr, PrevPos, MatchPos [0] - PrevPos) + AReplaceFunc (Self);
PrevPos := MatchPos [0] + MatchLen [0];
UNTIL not ExecNext;
Result := Result + System.Copy (AInputStr, PrevPos, MaxInt);
end;
{$IFDEF OverMeth}
function TRegExpr.Replace (AInputStr : RegExprString;
AReplaceFunc : TRegExprReplaceFunction)
: RegExprString;
begin
ReplaceEx (AInputStr, AReplaceFunc);
end;
{$ENDIF}
{$IFDEF RegExpPCodeDump}
function TRegExpr.DumpOp (op : TREOp) : RegExprString;
begin
case op of
BOL: Result := 'BOL';
EOL: Result := 'EOL';
BOLML: Result := 'BOLML';
EOLML: Result := 'EOLML';
BOUND: Result := 'BOUND';
NOTBOUND: Result := 'NOTBOUND';
ANY: Result := 'ANY';
ANYML: Result := 'ANYML';
ANYLETTER: Result := 'ANYLETTER';
NOTLETTER: Result := 'NOTLETTER';
ANYDIGIT: Result := 'ANYDIGIT';
NOTDIGIT: Result := 'NOTDIGIT';
ANYSPACE: Result := 'ANYSPACE';
NOTSPACE: Result := 'NOTSPACE';
ANYOF: Result := 'ANYOF';
ANYBUT: Result := 'ANYBUT';
ANYOFCI: Result := 'ANYOF/CI';
ANYBUTCI: Result := 'ANYBUT/CI';
BRANCH: Result := 'BRANCH';
EXACTLY: Result := 'EXACTLY';
EXACTLYCI: Result := 'EXACTLY/CI';
NOTHING: Result := 'NOTHING';
COMMENT: Result := 'COMMENT';
BACK: Result := 'BACK';
EEND: Result := 'END';
BSUBEXP: Result := 'BSUBEXP';
BSUBEXPCI: Result := 'BSUBEXP/CI';
Succ (OPEN) .. TREOp (Ord (OPEN) + NSUBEXP - 1):
Result := Format ('OPEN[%d]', [ord (op) - ord (OPEN)]);
Succ (CLOSE) .. TREOp (Ord (CLOSE) + NSUBEXP - 1):
Result := Format ('CLOSE[%d]', [ord (op) - ord (CLOSE)]);
STAR: Result := 'STAR';
PLUS: Result := 'PLUS';
BRACES: Result := 'BRACES';
{$IFDEF ComplexBraces}
LOOPENTRY: Result := 'LOOPENTRY';
LOOP: Result := 'LOOP';
LOOPNG: Result := 'LOOPNG';
{$ENDIF}
ANYOFTINYSET: Result:= 'ANYOFTINYSET';
ANYBUTTINYSET:Result:= 'ANYBUTTINYSET';
{$IFDEF UseSetOfChar}
ANYOFFULLSET: Result:= 'ANYOFFULLSET';
{$ENDIF}
STARNG: Result := 'STARNG';
PLUSNG: Result := 'PLUSNG';
BRACESNG: Result := 'BRACESNG';
else Error (reeDumpCorruptedOpcode);
end; {of case op}
Result := ':' + Result;
end;
function TRegExpr.Dump : RegExprString;
var
s : PRegExprChar;
op : TREOp;
next : PRegExprChar;
i : integer;
Diff : integer;
{$IFDEF UseSetOfChar}
Ch : REChar;
{$ENDIF}
begin
if not IsProgrammOk
then EXIT;
op := EXACTLY;
Result := '';
s := programm + REOpSz;
while op <> EEND do begin
op := s^;
Result := Result + Format ('%2d%s', [s - programm, DumpOp (s^)]);
next := regnext (s);
if next = nil
then Result := Result + ' (0)'
else begin
if next > s
then Diff := next - s
else Diff := - (s - next);
Result := Result + Format (' (%d) ', [(s - programm) + Diff]);
end;
inc (s, REOpSz + RENextOffSz);
if (op = ANYOF) or (op = ANYOFCI) or (op = ANYBUT) or (op = ANYBUTCI)
or (op = EXACTLY) or (op = EXACTLYCI) then begin
while s^ <> #0 do begin
Result := Result + s^;
inc (s);
end;
inc (s);
end;
if (op = ANYOFTINYSET) or (op = ANYBUTTINYSET) then begin
for i := 1 to TinySetLen do begin
Result := Result + s^;
inc (s);
end;
end;
if (op = BSUBEXP) or (op = BSUBEXPCI) then begin
Result := Result + ' \' + IntToStr (Ord (s^));
inc (s);
end;
{$IFDEF UseSetOfChar}
if op = ANYOFFULLSET then begin
for Ch := #0 to #255 do
if Ch in PSetOfREChar (s)^ then
if Ch < ' '
then Result := Result + '#' + IntToStr (Ord (Ch))
else Result := Result + Ch;
inc (s, SizeOf (TSetOfREChar));
end;
{$ENDIF}
if (op = BRACES) or (op = BRACESNG) then begin
Result := Result + Format ('{%d,%d}', [PREBracesArg (s)^, PREBracesArg (s + REBracesArgSz)^]);
inc (s, REBracesArgSz * 2);
end;
{$IFDEF ComplexBraces}
if (op = LOOP) or (op = LOOPNG) then begin
Result := Result + Format (' -> (%d) {%d,%d}', [
(s - programm - (REOpSz + RENextOffSz)) + PRENextOff (s + 2 * REBracesArgSz)^, PREBracesArg (s)^, PREBracesArg (s + REBracesArgSz)^]);
inc (s, 2 * REBracesArgSz + RENextOffSz);
end;
{$ENDIF}
Result := Result + #$d#$a;
end;
if regstart <> #0
then Result := Result + 'start ' + regstart;
if reganch <> #0
then Result := Result + 'anchored ';
if regmust <> nil
then Result := Result + 'must have ' + regmust;
{$IFDEF UseFirstCharSet}
Result := Result + #$d#$a'FirstCharSet:';
for Ch := #0 to #255 do
if Ch in FirstCharSet
then begin
if Ch < ' '
then Result := Result + '#' + IntToStr(Ord(Ch))
else Result := Result + Ch;
end;
{$ENDIF}
Result := Result + #$d#$a;
end;
{$ENDIF}
{$IFDEF reRealExceptionAddr}
{$OPTIMIZATION ON}
{$ENDIF}
procedure TRegExpr.Error (AErrorID : integer);
{$IFDEF reRealExceptionAddr}
function ReturnAddr : pointer;
asm
mov eax,[ebp+4]
end;
{$ENDIF}
var
e : ERegExpr;
begin
fLastError := AErrorID;
if AErrorID < 1000
then e := ERegExpr.Create (ErrorMsg (AErrorID) + ' (pos ' + IntToStr (CompilerErrorPos) + ')')
else e := ERegExpr.Create (ErrorMsg (AErrorID));
e.ErrorCode := AErrorID;
e.CompilerErrorPos := CompilerErrorPos;
raise e
{$IFDEF reRealExceptionAddr}
At ReturnAddr;
{$ENDIF}
end;
(*
PCode persistence:
FirstCharSet
programm, regsize
regstart
reganch
regmust, regmlen
fExprIsCompiled
*)
{$IFDEF FPC}
initialization
RegExprInvertCaseFunction := TRegExpr.InvertCaseFunction;
{$ENDIF}
end.
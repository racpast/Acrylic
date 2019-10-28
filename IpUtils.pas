// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  IpUtils;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  PIPv4Address = ^TIPv4Address;
  TIPv4Address = Integer;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  PIPv6Address = ^TIPv6Address;
  TIPv6Address = Array [0..15] of Byte;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  PDualIPAddress = ^TDualIPAddress;
  TDualIPAddress = packed record
    IsIPv6Address: Boolean;
    case Integer of
      0: (IPv4Address: TIPv4Address);
      1: (IPv6Address: TIPv6Address);
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  ANY_IPV4_ADDRESS: TIPv4Address = $00000000;
  ANY_IPV6_ADDRESS: TIPv6Address = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

const
  LOCALHOST_IPV4_ADDRESS: TIPv4Address = $100007F;
  LOCALHOST_IPV6_ADDRESS: TIPv6Address = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv4AddressUtility = class
    public
      class function Parse(Text: String): Integer;
      class function ToString(Address: TIPv4Address): String;
      class function IsLocalHost(Address: TIPv4Address): Boolean;
      class function AreEqual(Address1, Address2: TIPv4Address): Boolean;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TIPv6AddressUtility = class
    public
      class function Parse(Text: String): TIPv6Address;
      class function ToString(Address: TIPv6Address): String;
      class function IsLocalHost(Address: TIPv6Address): Boolean;
      class function AreEqual(Address1, Address2: TIPv6Address): Boolean;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TDualIPAddressUtility = class
    public
      class function Parse(Text: String): TDualIPAddress;
      class function ToString(Address: TDualIPAddress): String;
      class function IsLocalHost(Address: TDualIPAddress): Boolean;
      class function AreEqual(Address1, Address2: TDualIPAddress): Boolean;
      class function CreateFromIPv4Address(Address: TIPv4Address): TDualIPAddress;
      class function CreateFromIPv6Address(Address: TIPv6Address): TDualIPAddress;
  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  SysUtils;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure LowLevelIPv4AddressParse(Text: String; var Address: TIPv4Address);

var
  PartIndex, SepAt: Integer; PartText: String; PartValue: Word; ValResult: Integer;

begin

  Address := 0;

  if (Text = '0.0.0.0') then Exit else if (Text = '127.0.0.1') then begin Address := LOCALHOST_IPV4_ADDRESS; Exit; end else begin

    PartIndex := 0; while (Text <> '') and (PartIndex < 4) do begin

      SepAt := Pos('.', Text); if (SepAt > 0) then begin PartText := Copy(Text, 1, SepAt - 1); Delete(Text, 1, SepAt); end else begin PartText := Text; Text := ''; end; if (PartText <> '') then begin

        Val(PartText, PartValue, ValResult);

        Inc(Address, PartValue shl (8 * PartIndex));

      end; Inc(PartIndex);

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function LowLevelIPv4AddressToString(var Address: TIPv4Address): String;

begin

  Result := IntToStr(Address and $ff) + '.' + IntToStr((Address shr 8) and $ff) + '.' + IntToStr((Address shr 16) and $ff) + '.' + IntToStr(Address shr 24);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure LowLevelIPv6AddressParse(Text: String; var Address: TIPv6Address);

var
  PartIndex, SepAt, GapAt: Integer; PartText: String; PartValue: Word; ValResult: Integer;

begin

  FillChar(Address, SizeOf(TIPv6Address), 0);

  if (Text = '::') then Exit else if (Text = '::1') then begin Address[15] := 1; Exit; end else begin

    PartIndex := 0; GapAt := -1; while (Text <> '') and (PartIndex < 16) do begin

      SepAt := Pos(':', Text); if (SepAt > 0) then begin PartText := Copy(Text, 1, SepAt - 1); Delete(Text, 1, SepAt); end else begin PartText := Text; Text := ''; end; if (PartText <> '') then begin

        Val('$' + PartText, PartValue, ValResult);

        Address[PartIndex] := PartValue shr $08; Inc(PartIndex);
        Address[PartIndex] := PartValue and $ff; Inc(PartIndex);

      end else begin

        if (GapAt = -1) then GapAt := PartIndex;

      end;

    end;

    if (GapAt > -1) and (GapAt < 14) then begin

      Move(Address[GapAt], Address[16 + GapAt - PartIndex], PartIndex - GapAt); FillChar(Address[GapAt], 16 - PartIndex, 0);

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function LowLevelIPv6AddressToString(var Address: TIPv6Address): String;

begin

  Result := IntToHex((Address[0] shl 8) + Address[1], 1) + ':' + IntToHex((Address[2] shl 8) + Address[3], 1) + ':' + IntToHex((Address[4] shl 8) + Address[5], 1) + ':' + IntToHex((Address[6] shl 8) + Address[7], 1) + ':' + IntToHex((Address[8] shl 8) + Address[9], 1) + ':' + IntToHex((Address[10] shl 8) + Address[11], 1) + ':' + IntToHex((Address[12] shl 8) + Address[13], 1) + ':' + IntToHex((Address[14] shl 8) + Address[15], 1);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TIPv4AddressUtility.Parse(Text: String): TIPv4Address;

var
  IPv4Address: TIPv4Address;

begin

  LowLevelIPv4AddressParse(Text, IPv4Address); Result := IPv4Address;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TIPv4AddressUtility.ToString(Address: TIPv4Address): String;

begin

  Result := LowLevelIPv4AddressToString(Address);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TIPv4AddressUtility.IsLocalHost(Address: TIPv4Address): Boolean;

begin

  Result := TIPv4AddressUtility.AreEqual(Address, LOCALHOST_IPV4_ADDRESS);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TIPv4AddressUtility.AreEqual(Address1, Address2: TIPv4Address): Boolean;

begin

  Result := (Address1 = Address2);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TIPv6AddressUtility.Parse(Text: String): TIPv6Address;

var
  IPv6Address: TIPv6Address;

begin

  LowLevelIPv6AddressParse(Text, IPv6Address); Result := IPv6Address;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TIPv6AddressUtility.ToString(Address: TIPv6Address): String;

begin

  Result := LowLevelIPv6AddressToString(Address);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TIPv6AddressUtility.IsLocalHost(Address: TIPv6Address): Boolean;

begin

  Result := TIPv6AddressUtility.AreEqual(Address, LOCALHOST_IPV6_ADDRESS);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TIPv6AddressUtility.AreEqual(Address1, Address2: TIPv6Address): Boolean;

begin

  Result := (Address1[0] = Address2[0]) and (Address1[1] = Address2[1]) and (Address1[2] = Address2[2]) and (Address1[3] = Address2[3]) and (Address1[4] = Address2[4]) and (Address1[5] = Address2[5]) and (Address1[6] = Address2[6]) and (Address1[7] = Address2[7]) and (Address1[8] = Address2[8]) and (Address1[9] = Address2[9]) and (Address1[10] = Address2[10]) and (Address1[11] = Address2[11]) and (Address1[12] = Address2[12]) and (Address1[13] = Address2[13]) and (Address1[14] = Address2[14]) and (Address1[15] = Address2[15]);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDualIPAddressUtility.Parse(Text: String): TDualIPAddress;

var
  DualIPAddress: TDualIPAddress;

begin

  if (Pos(':', Text) > 0) then begin DualIPAddress.IPv6Address := TIPv6AddressUtility.Parse(Text); DualIPAddress.IsIPv6Address := True; end else begin DualIPAddress.IPv4Address := TIPv4AddressUtility.Parse(Text); DualIPAddress.IsIPv6Address := False; end; Result := DualIPAddress;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDualIPAddressUtility.ToString(Address: TDualIPAddress): String;

begin

  if Address.IsIPv6Address then Result := TIPv6AddressUtility.ToString(Address.IPv6Address) else Result := TIPv4AddressUtility.ToString(Address.IPv4Address);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDualIPAddressUtility.IsLocalHost(Address: TDualIPAddress): Boolean;

begin

  Result := (Address.IsIPv6Address and TIPv6AddressUtility.IsLocalHost(Address.IPv6Address)) or (not Address.IsIPv6Address and TIPv4AddressUtility.IsLocalHost(Address.IPv4Address));

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDualIPAddressUtility.AreEqual(Address1, Address2: TDualIPAddress): Boolean;

begin

  if Address1.IsIPv6Address then Result := Address2.IsIPv6Address and TIPv6AddressUtility.AreEqual(Address1.IPv6Address, Address2.IPv6Address) else Result := not Address2.IsIPv6Address and TIPv4AddressUtility.AreEqual(Address1.IPv4Address, Address2.IPv4Address);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDualIPAddressUtility.CreateFromIPv4Address(Address: TIPv4Address): TDualIPAddress;

var
  DualIPAddress: TDualIPAddress;

begin

  DualIPAddress.IPv4Address := Address; DualIPAddress.IsIPv6Address := False; Result := DualIPAddress;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

class function TDualIPAddressUtility.CreateFromIPv6Address(Address: TIPv6Address): TDualIPAddress;

var
  DualIPAddress: TDualIPAddress;

begin

  DualIPAddress.IPv6Address := Address; DualIPAddress.IsIPv6Address := True; Result := DualIPAddress;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.
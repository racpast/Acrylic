// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  AcrylicUISettings;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

interface

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Windows,
  SysUtils,
  Messages,
  Classes,
  Graphics;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function  Load(var EditorFont: TFont): Boolean;
procedure Save(EditorFont: TFont);

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  IniFiles,
  AcrylicUIUtils;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function
  Load(var EditorFont: TFont): Boolean;

var
  AcrylicUIIniFilePath: String; IniFile: TIniFile;

begin

  AcrylicUIIniFilePath := AcrylicUIUtils.GetAcrylicUIIniFilePath;

  if FileExists(AcrylicUIIniFilePath) then begin

    IniFile := TIniFile.Create(AcrylicUIIniFilePath);

    EditorFont.Name := IniFile.ReadString('MainForm', 'EditorFontName', 'Courier New');
    EditorFont.Size := IniFile.ReadInteger('MainForm', 'EditorFontSize', 10);
    EditorFont.Color := IniFile.ReadInteger('MainForm', 'EditorFontColor', 0);

    EditorFont.Style := [];

    if IniFile.ReadBool('MainForm', 'EditorFontStyleBold', False) then EditorFont.Style := EditorFont.Style + [fsBold];
    if IniFile.ReadBool('MainForm', 'EditorFontStyleItalic', False) then EditorFont.Style := EditorFont.Style + [fsItalic];
    if IniFile.ReadBool('MainForm', 'EditorFontStyleUnderline', False) then EditorFont.Style := EditorFont.Style + [fsUnderline];
    if IniFile.ReadBool('MainForm', 'EditorFontStyleStrikeOut', False) then EditorFont.Style := EditorFont.Style + [fsStrikeOut];

    IniFile.Free;

    Result := True;

  end else begin

    Result := False;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure Save(EditorFont: TFont);

var
  AcrylicUIIniFilePath: String; IniFile: TIniFile;

begin

  AcrylicUIIniFilePath := AcrylicUIUtils.GetAcrylicUIIniFilePath;

  IniFile := TIniFile.Create(AcrylicUIIniFilePath);

  IniFile.WriteString('MainForm', 'EditorFontName', EditorFont.Name);
  IniFile.WriteInteger('MainForm', 'EditorFontSize', EditorFont.Size);
  IniFile.WriteInteger('MainForm', 'EditorFontColor', EditorFont.Color);
  IniFile.WriteBool('MainForm', 'EditorFontStyleBold', fsBold in EditorFont.Style);
  IniFile.WriteBool('MainForm', 'EditorFontStyleItalic', fsItalic in EditorFont.Style);
  IniFile.WriteBool('MainForm', 'EditorFontStyleUnderline', fsUnderline in EditorFont.Style);
  IniFile.WriteBool('MainForm', 'EditorFontStyleStrikeOut', fsStrikeOut in EditorFont.Style);

  IniFile.Free;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

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
  Graphics,
  Controls,
  Forms;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

function  Load(MainForm: TForm; EditorFont: TFont): Boolean;
procedure Save(MainForm: TForm; EditorFont: TFont);

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
  Load(MainForm: TForm; EditorFont: TFont): Boolean;

var
  AcrylicUIIniFilePath: String; IniFile: TIniFile;

begin

  AcrylicUIIniFilePath := AcrylicUIUtils.GetAcrylicUIIniFilePath;

  if FileExists(AcrylicUIIniFilePath) then begin

    IniFile := TIniFile.Create(AcrylicUIIniFilePath);

    MainForm.WindowState := TWindowState(IniFile.ReadInteger('MainForm', 'WindowState', Integer(MainForm.WindowState)));

    if (MainForm.WindowState = wsNormal) then begin

      MainForm.Left := IniFile.ReadInteger('MainForm', 'Left', MainForm.Left);
      MainForm.Top := IniFile.ReadInteger('MainForm', 'Top', MainForm.Top);
      MainForm.Width := IniFile.ReadInteger('MainForm', 'Width', MainForm.Width);
      MainForm.Height := IniFile.ReadInteger('MainForm', 'Height', MainForm.Height);

    end;

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

procedure Save(MainForm: TForm; EditorFont: TFont);

var
  AcrylicUIIniFilePath: String; IniFile: TIniFile;

begin

  AcrylicUIIniFilePath := AcrylicUIUtils.GetAcrylicUIIniFilePath;

  IniFile := TIniFile.Create(AcrylicUIIniFilePath);

  IniFile.WriteInteger('MainForm', 'WindowState', Integer(MainForm.WindowState));

  IniFile.WriteInteger('MainForm', 'Left', MainForm.Left);
  IniFile.WriteInteger('MainForm', 'Top', MainForm.Top);
  IniFile.WriteInteger('MainForm', 'Width', MainForm.Width);
  IniFile.WriteInteger('MainForm', 'Height', MainForm.Height);

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

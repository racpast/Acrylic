// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  AcrylicUIMain;

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
  Forms,
  Menus,
  StdCtrls,
  ComCtrls,
  ExtCtrls,
  ShellApi,
  Dialogs,
  AcrylicUIUtils,
  AcrylicUISettings,
  AcrylicUIRegExTester;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TMainForm = class(TForm)

    Timer: TTimer;

    MainMenu: TMainMenu;
    Memo: TMemo;
    StatusBar: TStatusBar;

    OpenDialog: TOpenDialog;
    FontDialog: TFontDialog;

    FileMainMenuItem: TMenuItem;
    FileOpenMainMenuItem: TMenuItem;
    FileOpenAcrylicConfigurationMainMenuItem: TMenuItem;
    FileOpenAcrylicHostsMainMenuItem: TMenuItem;
    FileSaveMainMenuItem: TMenuItem;
    FileExitMainMenuItem: TMenuItem;

    ActionsMainMenuItem: TMenuItem;
    ActionsInstallAcrylicServiceMainMenuItem: TMenuItem;
    ActionsUninstallAcrylicServiceMainMenuItem: TMenuItem;
    ActionsStartAcrylicServiceMainMenuItem: TMenuItem;
    ActionsStopAcrylicServiceMainMenuItem: TMenuItem;
    ActionsRestartAcrylicServiceMainMenuItem: TMenuItem;
    ActionsPurgeAcrylicCacheDataMainMenuItem: TMenuItem;
    ActionsActivateAcrylicDebugLogMainMenuItem: TMenuItem;
    ActionsDeactivateAcrylicDebugLogMainMenuItem: TMenuItem;
    ActionsViewCurrentAcrylicDebugLogMainMenuItem: TMenuItem;
    ActionsOpenAcrylicFolderinFileExplorerMainMenuItem: TMenuItem;

    SettingsMainMenuItem: TMenuItem;
    SettingsSetEditorFontMainMenuItem: TMenuItem;

    ToolsMainMenuItem: TMenuItem;
    ToolsRegExTesterMainMenuItem: TMenuItem;

    HelpMainMenuItem: TMenuItem;
    HelpAcrylicHomePageMainMenuItem: TMenuItem;
    HelpAboutAcrylicMainMenuItem: TMenuItem;

    procedure TimerTimer(Sender: TObject);

    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);

    procedure FileOpenMainMenuItemClick(Sender: TObject);
    procedure FileOpenAcrylicConfigurationMainMenuItemClick(Sender: TObject);
    procedure FileOpenAcrylicHostsMainMenuItemClick(Sender: TObject);
    procedure FileSaveMainMenuItemClick(Sender: TObject);
    procedure FileExitMainMenuItemClick(Sender: TObject);

    procedure ActionsInstallAcrylicServiceMainMenuItemClick(Sender: TObject);
    procedure ActionsUninstallAcrylicServiceMainMenuItemClick(Sender: TObject);
    procedure ActionsStartAcrylicServiceMainMenuItemClick(Sender: TObject);
    procedure ActionsStopAcrylicServiceMainMenuItemClick(Sender: TObject);
    procedure ActionsRestartAcrylicServiceMainMenuItemClick(Sender: TObject);
    procedure ActionsPurgeAcrylicCacheDataMainMenuItemClick(Sender: TObject);
    procedure ActionsActivateAcrylicDebugLogMainMenuItemClick(Sender: TObject);
    procedure ActionsDeactivateAcrylicDebugLogMainMenuItemClick(Sender: TObject);
    procedure ActionsViewCurrentAcrylicDebugLogMainMenuItemClick(Sender: TObject);
    procedure ActionsOpenAcrylicFolderinFileExplorerMainMenuItemClick(Sender: TObject);

    procedure SettingsSetEditorFontMainMenuItemClick(Sender: TObject);

    procedure ToolsRegExTesterMainMenuItemClick(Sender: TObject);

    procedure HelpAcrylicHomePageMainMenuItemClick(Sender: TObject);
    procedure HelpAboutAcrylicMainMenuItemClick(Sender: TObject);

  private

    MemoFilePath: String;

    AcrylicServiceIsRunning: NBoolean;
    AcrylicServiceIsInstalled: NBoolean;
    AcrylicServiceDebugLogIsEnabled: NBoolean;

  private

    procedure UpdateStatusInfo(Text: String);
    procedure UpdateStatusError(Text: String);

  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  MainForm: TMainForm;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

implementation

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

{$R *.dfm}

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.TimerTimer(Sender: TObject);

begin

  try

    if AcrylicUIUtils.AcrylicServiceIsInstalled then Self.AcrylicServiceIsInstalled := NTrue else Self.AcrylicServiceIsInstalled := NFalse;

  except

    Self.AcrylicServiceIsInstalled := NUnspecified;

  end;

  if (Self.AcrylicServiceIsInstalled = NTrue) then begin

    Self.ActionsInstallAcrylicServiceMainMenuItem.Enabled := False;
    Self.ActionsUninstallAcrylicServiceMainMenuItem.Enabled := True;

  end else if (Self.AcrylicServiceIsInstalled = NFalse) then begin

    Self.ActionsInstallAcrylicServiceMainMenuItem.Enabled := True;
    Self.ActionsUninstallAcrylicServiceMainMenuItem.Enabled := False;

  end else begin

    Self.ActionsInstallAcrylicServiceMainMenuItem.Enabled := False;
    Self.ActionsUninstallAcrylicServiceMainMenuItem.Enabled := False;

  end;

  try

    if AcrylicUIUtils.AcrylicServiceIsRunning then Self.AcrylicServiceIsRunning := NTrue else Self.AcrylicServiceIsRunning := NFalse;

  except

    Self.AcrylicServiceIsRunning := NUnspecified;

  end;

  if (Self.AcrylicServiceIsRunning = NTrue) then begin

    Self.ActionsStopAcrylicServiceMainMenuItem.Enabled := True;
    Self.ActionsStartAcrylicServiceMainMenuItem.Enabled := False;
    Self.ActionsRestartAcrylicServiceMainMenuItem.Enabled := True;
    Self.ActionsPurgeAcrylicCacheDataMainMenuItem.Enabled := True;

  end else if (Self.AcrylicServiceIsRunning = NFalse) then begin

    Self.ActionsStopAcrylicServiceMainMenuItem.Enabled := False;
    Self.ActionsStartAcrylicServiceMainMenuItem.Enabled := True;
    Self.ActionsRestartAcrylicServiceMainMenuItem.Enabled := False;
    Self.ActionsPurgeAcrylicCacheDataMainMenuItem.Enabled := True;

  end else begin

    Self.ActionsStopAcrylicServiceMainMenuItem.Enabled := False;
    Self.ActionsStartAcrylicServiceMainMenuItem.Enabled := False;
    Self.ActionsRestartAcrylicServiceMainMenuItem.Enabled := False;
    Self.ActionsPurgeAcrylicCacheDataMainMenuItem.Enabled := False;

  end;

  if (Self.AcrylicServiceIsInstalled = NTrue) then begin

    if (Self.AcrylicServiceIsRunning = NTrue) then begin

      Self.Text := Application.Title + ' (Service Installed & Running)';

    end else if (Self.AcrylicServiceIsRunning = NFalse) then begin

      Self.Text := Application.Title + ' (Service Installed & Not Running)';

    end else begin

      Self.Text := Application.Title + ' (Service Installed)';

    end;

  end else if (Self.AcrylicServiceIsInstalled = NFalse) then begin

    if (Self.AcrylicServiceIsRunning = NTrue) then begin

      Self.Text := Application.Title + ' (Service Not Installed & Running)';

    end else if (Self.AcrylicServiceIsRunning = NFalse) then begin

      Self.Text := Application.Title + ' (Service Not Installed & Not Running)';

    end else begin

      Self.Text := Application.Title + ' (Service Not Installed)';

    end;

  end else begin

    if (Self.AcrylicServiceIsRunning = NTrue) then begin

      Self.Text := Application.Title + ' (Service Running)';

    end else if (Self.AcrylicServiceIsRunning = NFalse) then begin

      Self.Text := Application.Title + ' (Service Not Running)';

    end else begin

      Self.Text := Application.Title;

    end;

  end;

  try

    if AcrylicUIUtils.AcrylicServiceDebugLogIsEnabled then Self.AcrylicServiceDebugLogIsEnabled := NTrue else Self.AcrylicServiceDebugLogIsEnabled := NFalse;

  except

    Self.AcrylicServiceDebugLogIsEnabled := NUnspecified;

  end;

  if (Self.AcrylicServiceDebugLogIsEnabled = NTrue) then begin

    Self.ActionsActivateAcrylicDebugLogMainMenuItem.Enabled := False;
    Self.ActionsDeactivateAcrylicDebugLogMainMenuItem.Enabled := True;
    Self.ActionsViewCurrentAcrylicDebugLogMainMenuItem.Enabled := True;

  end else if (Self.AcrylicServiceDebugLogIsEnabled = NFalse) then begin

    Self.ActionsActivateAcrylicDebugLogMainMenuItem.Enabled := True;
    Self.ActionsDeactivateAcrylicDebugLogMainMenuItem.Enabled := False;
    Self.ActionsViewCurrentAcrylicDebugLogMainMenuItem.Enabled := False;

  end else begin

    Self.ActionsActivateAcrylicDebugLogMainMenuItem.Enabled := False;
    Self.ActionsDeactivateAcrylicDebugLogMainMenuItem.Enabled := False;
    Self.ActionsViewCurrentAcrylicDebugLogMainMenuItem.Enabled := False;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.FormCreate(Sender: TObject);

var
  EditorFont: TFont;

begin

  Self.Caption := Application.Title;

  try

    if (Screen.Fonts.IndexOf('Consolas') >= 0) then begin

      Self.Memo.Font.Name  := 'Consolas';
      Self.Memo.Font.Size  := 10;
      Self.Memo.Font.Color := 0;
      Self.Memo.Font.Style := [fsBold];

    end;

    EditorFont := Self.Memo.Font;

    if AcrylicUISettings.Load(EditorFont) then begin

      Self.Memo.Font := EditorFont;

    end;

  except

  end;

  Self.UpdateStatusInfo(AcrylicUIUtils.GetAcrylicWelcomeString);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);

begin

  if Self.Memo.Visible and (Self.MemoFilePath <> '') and Self.Memo.Modified then begin

    if (MessageBox(0, PChar(Self.MemoFilePath + #13#10 + #13#10 + 'There are unsaved changes in the editor.' + #13#10 + #13#10 + 'Are you sure that you want to exit?'), 'Exit Confirmation Request', MB_ICONQUESTION or MB_YESNO) = IDYES) then begin

      CanClose := True;

    end else begin

      CanClose := False;

    end;

  end else begin

    CanClose := True;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);

begin

  try

    AcrylicUISettings.Save(Self.Memo.Font);

  except

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.UpdateStatusInfo(Text: String);

begin

  Self.StatusBar.SimpleText := Text; Application.ProcessMessages;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.UpdateStatusError(Text: String);

begin

  Self.StatusBar.SimpleText := Text; Application.ProcessMessages;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.FileOpenMainMenuItemClick(Sender: TObject);

begin

  OpenDialog.Title := 'Open...';
  OpenDialog.Filter := 'All files|*.*';
  OpenDialog.InitialDir := ExtractFilePath(ParamStr(0));

  if OpenDialog.Execute then begin

    Self.MemoFilePath := OpenDialog.FileName;

    Self.Memo.Lines.LoadFromFile(OpenDialog.FileName);
    Self.Memo.Modified := False;
    Self.Memo.Visible := True;

    Self.FileSaveMainMenuItem.Enabled := True;

    Self.UpdateStatusInfo('You are now editing the file "' + OpenDialog.FileName + '".');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.FileOpenAcrylicConfigurationMainMenuItemClick(Sender: TObject);

var
  AcrylicConfigurationFilePath: String;

begin

  AcrylicConfigurationFilePath := AcrylicUIUtils.GetAcrylicConfigurationFilePath;

  if FileExists(AcrylicConfigurationFilePath) then begin

    Self.MemoFilePath := AcrylicConfigurationFilePath;

    Self.Memo.Lines.LoadFromFile(AcrylicConfigurationFilePath);
    Self.Memo.Modified := False;
    Self.Memo.Visible := True;

    Self.FileSaveMainMenuItem.Enabled := True;

    Self.UpdateStatusInfo('You are now editing the file "' + AcrylicConfigurationFilePath + '".');

  end else begin

    Self.UpdateStatusError('An error occurred while opening the file "' + AcrylicConfigurationFilePath + '".');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.FileOpenAcrylicHostsMainMenuItemClick(Sender: TObject);

var
  AcrylicHostsFilePath: String;

begin

  AcrylicHostsFilePath := AcrylicUIUtils.GetAcrylicHostsFilePath;

  if FileExists(AcrylicHostsFilePath) then begin

    Self.MemoFilePath := AcrylicHostsFilePath;

    Self.Memo.Lines.LoadFromFile(AcrylicHostsFilePath);
    Self.Memo.Modified := False;
    Self.Memo.Visible := True;

    Self.FileSaveMainMenuItem.Enabled := True;

    Self.UpdateStatusInfo('You are now editing the file "' + AcrylicHostsFilePath + '".');

  end else begin

    Self.UpdateStatusError('An error occurred while opening the file "' + AcrylicHostsFilePath + '".');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.FileSaveMainMenuItemClick(Sender: TObject);

begin

  if Self.Memo.Visible and (Self.MemoFilePath <> '') then begin

    Self.UpdateStatusInfo('Saving changes to file "' + Self.MemoFilePath + '"...');

    try

      Self.Memo.Lines.SaveToFile(Self.MemoFilePath);
      Self.Memo.Modified := False;

    except

      Self.UpdateStatusError('An error occurred while saving changes to file "' + Self.MemoFilePath + '".');

      Exit;

    end;

    Self.UpdateStatusInfo('Changes saved to file "' + Self.MemoFilePath + '" successfully.');

    if (Self.AcrylicServiceIsRunning = NTrue) then begin

      if (MessageBox(0, 'After the changes you need to restart the Acrylic service in order to see their effects.' + #13#10 + #13#10 + 'Do you want to do it now?', 'Acrylic Service Restart Needed', MB_ICONQUESTION or MB_YESNO) = IDYES) then begin

        Self.UpdateStatusInfo('Stopping the Acrylic service...');

        if not AcrylicUIUtils.StopAcrylicService then begin

          Self.UpdateStatusError('An error occurred while restarting the Acrylic service.');

          Exit;

        end;

        Self.UpdateStatusInfo('Starting the Acrylic service...');

        if not AcrylicUIUtils.StartAcrylicService then begin

          Self.UpdateStatusError('An error occurred while restarting the Acrylic service.');

          Exit;

        end;

        Self.UpdateStatusInfo('The Acrylic service has been restarted successfully.');

      end;

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.FileExitMainMenuItemClick(Sender: TObject);

begin

  Self.Close;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.ActionsInstallAcrylicServiceMainMenuItemClick(Sender: TObject);

begin

  if (Self.AcrylicServiceIsInstalled = NFalse) then begin

    Self.UpdateStatusInfo('Installing the Acrylic service...');

    if not AcrylicUIUtils.InstallAcrylicService then begin

       Self.UpdateStatusError('An error occurred while installing the Acrylic service.');

       Exit;

    end;

    Self.UpdateStatusInfo('The Acrylic service has been installed successfully.');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.ActionsUninstallAcrylicServiceMainMenuItemClick(Sender: TObject);

begin

  if (Self.AcrylicServiceIsInstalled = NTrue) then begin

    Self.UpdateStatusInfo('Uninstalling the Acrylic service...');

    if not AcrylicUIUtils.UninstallAcrylicService then begin

      Self.UpdateStatusError('An error occurred while uninstalling the Acrylic service.');

      Exit;

    end;

    Self.UpdateStatusInfo('The Acrylic service has been uninstalled successfully.');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.ActionsStartAcrylicServiceMainMenuItemClick(Sender: TObject);

begin

  if (Self.AcrylicServiceIsRunning = NFalse) then begin

    Self.UpdateStatusInfo('Starting the Acrylic service...');

    if not AcrylicUIUtils.StartAcrylicService then begin

       Self.UpdateStatusError('An error occurred while starting the Acrylic service.');

       Exit;

    end;

    Self.UpdateStatusInfo('The Acrylic service has been started successfully.');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.ActionsStopAcrylicServiceMainMenuItemClick(Sender: TObject);

begin

  if (Self.AcrylicServiceIsRunning = NTrue) then begin

    Self.UpdateStatusInfo('Stopping the Acrylic service...');

    if not AcrylicUIUtils.StopAcrylicService then begin

      Self.UpdateStatusError('An error occurred while stopping the Acrylic service.');

      Exit;

    end;

    Self.UpdateStatusInfo('The Acrylic service has been stopped successfully.');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.ActionsRestartAcrylicServiceMainMenuItemClick(Sender: TObject);

begin

  if (Self.AcrylicServiceIsRunning = NTrue) then begin

    Self.UpdateStatusInfo('Stopping the Acrylic service...');

    if not AcrylicUIUtils.StopAcrylicService then begin

      Self.UpdateStatusError('An error occurred while restarting the Acrylic service.');

      Exit;

    end;

    Self.UpdateStatusInfo('Starting the Acrylic service...');

    if not AcrylicUIUtils.StartAcrylicService then begin

       Self.UpdateStatusError('An error occurred while restarting the Acrylic service.');

      Exit;

    end;

    Self.UpdateStatusInfo('The Acrylic service has been restarted successfully.');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.ActionsPurgeAcrylicCacheDataMainMenuItemClick(Sender: TObject);

var
  AcrylicCacheFilePath: String;

begin

  AcrylicCacheFilePath := AcrylicUIUtils.GetAcrylicCacheFilePath;

  if (Self.AcrylicServiceIsRunning = NTrue) then begin

    Self.UpdateStatusInfo('Stopping the Acrylic service...');

    if not AcrylicUIUtils.StopAcrylicService then begin

      Self.UpdateStatusError('An error occurred while purging Acrylic cache data.');

      Exit;

    end;

    if FileExists(AcrylicCacheFilePath) then begin

      Self.UpdateStatusInfo('Removing the Acrylic cache file...');

      DeleteFile(PChar(AcrylicCacheFilePath));

    end;

    Self.UpdateStatusInfo('Starting the Acrylic service...');

    if not AcrylicUIUtils.StartAcrylicService then begin

       Self.UpdateStatusError('An error occurred while purging Acrylic cache data.');

       Exit;

    end;

    Self.UpdateStatusInfo('Acrylic cache data has been purged successfully.');

  end else if (Self.AcrylicServiceIsRunning = NFalse) then begin

    if FileExists(AcrylicCacheFilePath) then begin

      Self.UpdateStatusInfo('Removing the Acrylic cache file...');

      DeleteFile(PChar(AcrylicCacheFilePath));

    end;

    Self.UpdateStatusInfo('Acrylic cache data has been purged successfully.');

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.ActionsActivateAcrylicDebugLogMainMenuItemClick(Sender: TObject);

begin

  if (Self.AcrylicServiceDebugLogIsEnabled = NFalse) then begin

    if (Self.AcrylicServiceIsRunning = NTrue) then begin

      Self.UpdateStatusInfo('Stopping the Acrylic service...');

      if not AcrylicUIUtils.StopAcrylicService then begin

        Self.UpdateStatusError('An error occurred while activating the Acrylic debug log.');

        Exit;

      end;

      Self.UpdateStatusInfo('Touching the Acrylic debug log...');

      AcrylicUIUtils.CreateAcrylicServiceDebugLog;

      Self.UpdateStatusInfo('Starting the Acrylic service...');

      if not AcrylicUIUtils.StartAcrylicService then begin

        Self.UpdateStatusError('An error occurred while activating the Acrylic debug log.');

        Exit;

      end;

      Self.UpdateStatusInfo('The Acrylic debug log has been activated successfully.');

    end else if (Self.AcrylicServiceIsRunning = NFalse) then begin

      Self.UpdateStatusInfo('Touching the Acrylic debug log...');

      AcrylicUIUtils.CreateAcrylicServiceDebugLog;

      Self.UpdateStatusInfo('The Acrylic debug log has been activated successfully.');

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.ActionsDeactivateAcrylicDebugLogMainMenuItemClick(Sender: TObject);

begin

  if (Self.AcrylicServiceDebugLogIsEnabled = NTrue) then begin

    if (Self.AcrylicServiceIsRunning = NTrue) then begin

      Self.UpdateStatusInfo('Stopping the Acrylic service...');

      if not AcrylicUIUtils.StopAcrylicService then begin

        Self.UpdateStatusError('An error occurred while deactivating the Acrylic debug log.');

        Exit;

      end;

      Self.UpdateStatusInfo('Removing the Acrylic debug log...');

      AcrylicUIUtils.RemoveAcrylicServiceDebugLog;

      Self.UpdateStatusInfo('Starting the Acrylic service...');

      if not AcrylicUIUtils.StartAcrylicService then begin

        Self.UpdateStatusError('An error occurred while deactivating the Acrylic debug log.');

        Exit;

      end;

      Self.UpdateStatusInfo('The Acrylic debug log has been deactivated successfully.');

    end else if (Self.AcrylicServiceIsRunning = NFalse) then begin

      Self.UpdateStatusInfo('Removing the Acrylic debug log...');

      AcrylicUIUtils.RemoveAcrylicServiceDebugLog;

      Self.UpdateStatusInfo('The Acrylic debug log has been deactivated successfully.');

    end;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.ActionsViewCurrentAcrylicDebugLogMainMenuItemClick(Sender: TObject);

var
  AcrylicDebugLogFilePath: String;

begin

  if (Self.AcrylicServiceDebugLogIsEnabled = NTrue) then begin

    AcrylicDebugLogFilePath := AcrylicUIUtils.GetAcrylicDebugLogFilePath;

    WinExec(PChar('Notepad.exe "' + AcrylicDebugLogFilePath + '"'), SW_NORMAL);

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.ActionsOpenAcrylicFolderinFileExplorerMainMenuItemClick(Sender: TObject);

var
  AcrylicDirectoryPath: String;

begin

  AcrylicDirectoryPath := AcrylicUIUtils.GetAcrylicDirectoryPath;

  WinExec(PChar('Explorer.exe "' + AcrylicDirectoryPath + '"'), SW_NORMAL);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.SettingsSetEditorFontMainMenuItemClick(Sender: TObject);

begin

  FontDialog.Font := Self.Memo.Font;

  if FontDialog.Execute then begin

    Self.Memo.Font := FontDialog.Font;

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.ToolsRegExTesterMainMenuItemClick(Sender: TObject);

var
  MyForm: TRegExTesterForm;

begin

  MyForm := TRegExTesterForm.Create(nil);
  MyForm.ShowModal;
  MyForm.Free;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.HelpAcrylicHomePageMainMenuItemClick(Sender: TObject);

begin

  ShellExecute(Self.Handle, 'open', 'https://mayakron.altervista.org/acrylic.php', nil, nil, SW_NORMAL);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TMainForm.HelpAboutAcrylicMainMenuItemClick(Sender: TObject);

begin

  MessageBox(0, PChar(AcrylicUIUtils.GetAcrylicDescriptionString), 'About Acrylic', MB_ICONINFORMATION or MB_OK);

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

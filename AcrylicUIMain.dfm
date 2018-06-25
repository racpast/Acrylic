object MainForm: TMainForm
  Left = 298
  Top = 136
  Width = 800
  Height = 480
  Caption = 'Acrylic DNS Proxy UI'
  Color = clBtnFace
  Constraints.MinHeight = 480
  Constraints.MinWidth = 800
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu
  OldCreateOrder = False
  Position = poDefault
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object StatusBar: TStatusBar
    Left = 0
    Top = 398
    Width = 784
    Height = 23
    Panels = <>
    SimplePanel = True
    SizeGrip = False
  end
  object Memo: TMemo
    Left = 0
    Top = 0
    Width = 784
    Height = 398
    Align = alClient
    Ctl3D = False
    Font.Charset = ANSI_CHARSET
    Font.Color = clBlack
    Font.Height = -12
    Font.Name = 'Courier New'
    Font.Style = [fsBold]
    ParentCtl3D = False
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 1
    Visible = False
    WantTabs = True
  end
  object MainMenu: TMainMenu
    AutoHotkeys = maManual
    Left = 3
    Top = 4
    object FileMainMenuItem: TMenuItem
      Caption = '&File'
      object FileOpenMainMenuItem: TMenuItem
        Caption = '&Open...'
        ShortCut = 16463
        OnClick = FileOpenMainMenuItemClick
      end
      object FileOpenAcrylicConfigurationMainMenuItem: TMenuItem
        Caption = 'Open Acrylic &Configuration'
        ShortCut = 16496
        OnClick = FileOpenAcrylicConfigurationMainMenuItemClick
      end
      object FileOpenAcrylicHostsMainMenuItem: TMenuItem
        Caption = 'Open Acrylic &Hosts'
        ShortCut = 16497
        OnClick = FileOpenAcrylicHostsMainMenuItemClick
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object FileSaveMainMenuItem: TMenuItem
        Caption = '&Save'
        Enabled = False
        ShortCut = 16467
        OnClick = FileSaveMainMenuItemClick
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object FileExitMainMenuItem: TMenuItem
        Caption = 'E&xit'
        ShortCut = 32883
        OnClick = FileExitMainMenuItemClick
      end
    end
    object ActionsMainMenuItem: TMenuItem
      Caption = '&Actions'
      object ActionsInstallAcrylicServiceMainMenuItem: TMenuItem
        Caption = '&Install Acrylic Service'
        OnClick = ActionsInstallAcrylicServiceMainMenuItemClick
      end
      object ActionsUninstallAcrylicServiceMainMenuItem: TMenuItem
        Caption = '&Uninstall Acrylic Service'
        OnClick = ActionsUninstallAcrylicServiceMainMenuItemClick
      end
      object N7: TMenuItem
        Caption = '-'
      end
      object ActionsStartAcrylicServiceMainMenuItem: TMenuItem
        Caption = 'St&art Acrylic Service'
        Enabled = False
        OnClick = ActionsStartAcrylicServiceMainMenuItemClick
      end
      object ActionsStopAcrylicServiceMainMenuItem: TMenuItem
        Caption = 'St&op Acrylic Service'
        Enabled = False
        OnClick = ActionsStopAcrylicServiceMainMenuItemClick
      end
      object ActionsRestartAcrylicServiceMainMenuItem: TMenuItem
        Caption = '&Restart Acrylic Service'
        Enabled = False
        OnClick = ActionsRestartAcrylicServiceMainMenuItemClick
      end
      object N3: TMenuItem
        Caption = '-'
      end
      object ActionsPurgeAcrylicCacheDataMainMenuItem: TMenuItem
        Caption = '&Purge Acrylic Cache Data'
        OnClick = ActionsPurgeAcrylicCacheDataMainMenuItemClick
      end
      object N4: TMenuItem
        Caption = '-'
      end
      object ActionsActivateAcrylicDebugLogMainMenuItem: TMenuItem
        Caption = 'A&ctivate Acrylic Debug Log'
        Enabled = False
        OnClick = ActionsActivateAcrylicDebugLogMainMenuItemClick
      end
      object ActionsDeactivateAcrylicDebugLogMainMenuItem: TMenuItem
        Caption = 'D&eactivate Acrylic Debug Log'
        Enabled = False
        OnClick = ActionsDeactivateAcrylicDebugLogMainMenuItemClick
      end
      object N5: TMenuItem
        Caption = '-'
      end
      object ActionsViewCurrentAcrylicDebugLogMainMenuItem: TMenuItem
        Caption = 'View Current Acrylic De&bug Log'
        Enabled = False
        OnClick = ActionsViewCurrentAcrylicDebugLogMainMenuItemClick
      end
      object N9: TMenuItem
        Caption = '-'
      end
      object ActionsOpenAcrylicFolderinFileExplorerMainMenuItem: TMenuItem
        Caption = 'Open Acrylic &Folder in File Explorer'
        OnClick = ActionsOpenAcrylicFolderinFileExplorerMainMenuItemClick
      end
    end
    object SettingsMainMenuItem: TMenuItem
      Caption = 'Se&ttings'
      object SettingsSetEditorFontMainMenuItem: TMenuItem
        Caption = 'Set Editor &Font...'
        OnClick = SettingsSetEditorFontMainMenuItemClick
      end
    end
    object ToolsMainMenuItem: TMenuItem
      Caption = '&Tools'
      object ToolsRegExTesterMainMenuItem: TMenuItem
        Caption = '&RegEx Tester'
        OnClick = ToolsRegExTesterMainMenuItemClick
      end
    end
    object HelpMainMenuItem: TMenuItem
      Caption = '&Help'
      object HelpAcrylicHomePageMainMenuItem: TMenuItem
        Caption = 'Acrylic &Home Page'
        OnClick = HelpAcrylicHomePageMainMenuItemClick
      end
      object N6: TMenuItem
        Caption = '-'
      end
      object HelpAboutAcrylicMainMenuItem: TMenuItem
        Caption = '&About Acrylic'
        OnClick = HelpAboutAcrylicMainMenuItemClick
      end
    end
  end
  object Timer: TTimer
    OnTimer = TimerTimer
    Left = 33
    Top = 4
  end
  object FontDialog: TFontDialog
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Left = 63
    Top = 4
  end
  object OpenDialog: TOpenDialog
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 93
    Top = 4
  end
end

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

program
  AcrylicUI;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

uses
  Forms,
  AcrylicUIMain in 'AcrylicUIMain.pas',
  AcrylicUIUtils in 'AcrylicUIUtils.pas',
  AcrylicUISettings in 'AcrylicUISettings.pas',
  AcrylicUIRegExTester in 'AcrylicUIRegExTester.pas',
  AcrylicVersionInfo in 'AcrylicVersionInfo.pas';

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

{$R *.res}

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

begin

  if (ParamStr(1) = 'InstallAcrylicService') then begin

    AcrylicUIUtils.InstallAcrylicService;

    AcrylicUIUtils.StartAcrylicService;

    Exit;

  end;

  if (ParamStr(1) = 'StartAcrylicService') then begin

    if not AcrylicUIUtils.AcrylicServiceIsRunning then begin

      AcrylicUIUtils.StartAcrylicService;

    end;

    Exit;

  end;

  if (ParamStr(1) = 'StopAcrylicService') then begin

    if AcrylicUIUtils.AcrylicServiceIsRunning then begin

      AcrylicUIUtils.StopAcrylicService;

    end;

    Exit;

  end;

  if (ParamStr(1) = 'RestartAcrylicService') then begin

    if AcrylicUIUtils.AcrylicServiceIsRunning then begin

      AcrylicUIUtils.StopAcrylicService;

    end;

    AcrylicUIUtils.StartAcrylicService;

    Exit;

  end;

  if (ParamStr(1) = 'PurgeAcrylicCacheData') then begin

    if AcrylicUIUtils.AcrylicServiceIsRunning then begin

      AcrylicUIUtils.StopAcrylicService;

      AcrylicUIUtils.RemoveAcrylicCacheFile;

      AcrylicUIUtils.StartAcrylicService;

    end else begin

      AcrylicUIUtils.RemoveAcrylicCacheFile;

    end;

    Exit;

  end;

  if (ParamStr(1) = 'ActivateAcrylicDebugLog') then begin

    if AcrylicUIUtils.AcrylicServiceIsRunning then begin

      AcrylicUIUtils.StopAcrylicService;

      AcrylicUIUtils.CreateAcrylicServiceDebugLog;

      AcrylicUIUtils.StartAcrylicService;

    end else begin

      AcrylicUIUtils.CreateAcrylicServiceDebugLog;

    end;

    Exit;

  end;

  if (ParamStr(1) = 'DeactivateAcrylicDebugLog') then begin

    if AcrylicUIUtils.AcrylicServiceIsRunning then begin

      AcrylicUIUtils.StopAcrylicService;

      AcrylicUIUtils.RemoveAcrylicServiceDebugLog;

      AcrylicUIUtils.StartAcrylicService;

    end else begin

      AcrylicUIUtils.CreateAcrylicServiceDebugLog;

    end;

    Exit;

  end;

  if (ParamStr(1) = 'UninstallAcrylicService') then begin

    if AcrylicUIUtils.AcrylicServiceIsRunning then begin

      AcrylicUIUtils.StopAcrylicService;

    end;

    AcrylicUIUtils.UninstallAcrylicService;

    Exit;

  end;

  Application.Initialize; Application.Title := 'Acrylic DNS Proxy UI';

  Application.CreateForm(TMainForm, MainForm);

  Application.CreateForm(TRegExTesterForm, RegExTesterForm);

  Application.Run;

end.

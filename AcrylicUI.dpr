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
  AcrylicUIRegExTester in 'AcrylicUIRegExTester.pas';

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

  if (ParamStr(1) = 'UninstallAcrylicService') then begin

    AcrylicUIUtils.UninstallAcrylicService;

    Exit;

  end;

  Application.Initialize; Application.Title := 'Acrylic DNS Proxy UI';

  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TRegExTesterForm, RegExTesterForm);

  Application.Run;

end.

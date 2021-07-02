// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

unit
  AcrylicUIDomainNameAffinityMaskTester;

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
  Classes,
  Controls,
  Forms,
  StdCtrls,
  AcrylicUIUtils;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

type
  TDomainNameAffinityMaskTesterForm = class(TForm)

    lblDomainName: TLabel;
    txtDomainName: TEdit;
    lblAffinityMask: TLabel;
    txtAffinityMask: TEdit;
    lblResult: TLabel;
    btnTest: TButton;

    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    procedure btnTestClick(Sender: TObject);

  end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

var
  DomainNameAffinityMaskTesterForm: TDomainNameAffinityMaskTesterForm;

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

procedure TDomainNameAffinityMaskTesterForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

begin

  if (Key = 27) then Self.ModalResult := mrCancel;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

procedure TDomainNameAffinityMaskTesterForm.btnTestClick(Sender: TObject);

begin

  try

    if AcrylicUIUtils.TestDomainNameAffinityMask(txtDomainName.Text, txtAffinityMask.Text) then begin

      lblResult.Caption := 'Match: YES.';

    end else begin

      lblResult.Caption := 'Match: NO.';

    end;

  except

    lblResult.Caption := 'Invalid affinity mask specified.';

  end;

end;

// --------------------------------------------------------------------------
//
// --------------------------------------------------------------------------

end.

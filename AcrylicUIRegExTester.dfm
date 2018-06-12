object RegExTesterForm: TRegExTesterForm
  Left = 383
  Top = 194
  BorderStyle = bsDialog
  Caption = 'RegEx Tester'
  ClientHeight = 163
  ClientWidth = 460
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object lblDomainName: TLabel
    Left = 14
    Top = 12
    Width = 185
    Height = 13
    Caption = '&Domain name: (e.g. www.google.com)'
  end
  object lblRegEx: TLabel
    Left = 14
    Top = 58
    Width = 245
    Height = 13
    Caption = '&Regular expression: (e.g. (?<!cdn\.)google\.com$)'
  end
  object lblResult: TLabel
    Left = 14
    Top = 120
    Width = 346
    Height = 13
    Caption = 
      'Enter a domain name, a regular expression and click on the Test ' +
      'button.'
  end
  object txtDomainName: TEdit
    Left = 14
    Top = 28
    Width = 428
    Height = 21
    TabOrder = 0
  end
  object txtRegEx: TEdit
    Left = 14
    Top = 74
    Width = 428
    Height = 21
    TabOrder = 1
  end
  object btnTestRegEx: TButton
    Left = 367
    Top = 115
    Width = 75
    Height = 25
    Caption = '&Test!'
    Default = True
    TabOrder = 2
    OnClick = btnTestRegExClick
  end
end

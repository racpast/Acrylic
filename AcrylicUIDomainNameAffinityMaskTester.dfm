object DomainNameAffinityMaskTesterForm: TDomainNameAffinityMaskTesterForm
  Left = 383
  Top = 194
  BorderStyle = bsDialog
  Caption = 'Domain Name Affinity Mask Tester'
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
  object lblAffinityMask: TLabel
    Left = 14
    Top = 58
    Width = 185
    Height = 13
    Caption = '&Affinity mask: (e.g. ^*.com;^*.org;*)'
  end
  object lblResult: TLabel
    Left = 14
    Top = 120
    Width = 324
    Height = 13
    Caption = 
      'Enter a domain name, an affinity mask and click on the Test butt' +
      'on.'
  end
  object txtDomainName: TEdit
    Left = 14
    Top = 28
    Width = 428
    Height = 21
    TabOrder = 0
  end
  object txtAffinityMask: TEdit
    Left = 14
    Top = 74
    Width = 428
    Height = 21
    TabOrder = 1
  end
  object btnTest: TButton
    Left = 367
    Top = 115
    Width = 75
    Height = 25
    Caption = '&Test!'
    Default = True
    TabOrder = 2
    OnClick = btnTestClick
  end
end

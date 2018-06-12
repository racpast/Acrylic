object AcrylicDNSProxySvc: TAcrylicDNSProxySvc
  OldCreateOrder = False
  AllowPause = False
  DisplayName = 'Acrylic DNS Proxy'
  AfterInstall = ServiceAfterInstall
  OnShutdown = ServiceShutdown
  OnStart = ServiceStart
  OnStop = ServiceStop
  Left = 556
  Top = 266
  Height = 150
  Width = 215
end

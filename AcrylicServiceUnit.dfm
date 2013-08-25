object AcrylicController: TAcrylicController
  OldCreateOrder = False
  AllowPause = False
  DisplayName = 'Acrylic DNS Proxy Service'
  OnShutdown = ServiceShutdown
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 150
  Width = 215
end
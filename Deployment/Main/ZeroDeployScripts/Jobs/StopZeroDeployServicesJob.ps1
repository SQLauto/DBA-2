

    Write-Host "Stopping Zero Deploy Rig"
    #Stop AppFabric cache
    import-module DistributedCacheAdministration
    use-cachecluster
    stop-cachecluster

    #Stop FAE Services
    Stop-Process -processname PipelineHost -Force
    Stop-Process -processname EngineControllerHost -Force
    Stop-Process -processname ServiceBusProxyService -Force
    #Stop PARE Services
    Stop-Process -processname AuthorisationGatewayServiceHost -Force
    Stop-Process -processname EodControllerServiceHost -Force
    Stop-Process -processname IdraServiceHost -Force
    Stop-Process -processname DirectPaymentServiceHost -Force
    Stop-Process -processname SettlementValidationResultFileServiceHost -Force
    Stop-Process -processname StatusListServiceHost -Force
    Stop-Process -processname RefundFileServiceHost -Force
    Stop-Process -processname RevenueStatusListFileServiceHost -Force
    Stop-Process -processname SettlementResponseFileServiceHost -Force
    Stop-Process -processname TapFileServiceHost -Force
    Stop-Process -processname TravelDayRevisionServiceHost -Force
    #Stop Notifications Services
    Stop-Process -processname Tfl.Ft.Notifications.FileProcessor.WindowsService -Force
    Stop-Process -processname SendEmailService -Force
    Stop-Process -processname ControllerService -Force
    #Stop Ad-hoc Services (if running)
    Stop-Process -processname Tfl.Ft.Fae.TravelDayRevisionExporter -Force
    Stop-Process -processname SettlementApplication	 -Force
    #Stop Masterdata Services (if running)
    Stop-Process -processname MasterData.MaximumJourneyTimeService -Force
    Stop-Process -processname MasterData.FareService -Force
	Stop-Process -processname Tfl.Ft.OyBO.FileProcessor.Host -Force
	Stop-Process -processname Tfl.Ft.OyBO.AzureMobileUploader.Host -Force

    #Kill IIS Express
    taskkill /IM IISExpress.exe

	Start-Process "..\..\..\FAE\main\Code\PipelineHost\bin\Release\PipelineHost.exe" 
	Start-Process "..\..\..\FAE\main\Code\EngineControllerHost\bin\Release\EngineControllerHost.exe" 
	Start-Process "..\..\..\FAE\main\Code\ServiceBusProxyService\bin\Release\ServiceBusProxyService.exe" 

	Start-Process "..\..\..\PARE\main\Code\Pare.Authorisation.GatewayService\bin\Release\Authorisation.GatewayService.exe"

	Start-Process "..\..\..\PARE\main\Code\Pare.DirectPaymentService\bin\Release\Pare.DirectPaymentService.exe"
	Start-Process "..\..\..\PARE\main\Code\Pare.EodControllerService\bin\Release\EodControllerService.exe"

	Start-Process "..\..\..\PARE\main\Code\Pare.SettlementValidationResultFileProcessingService\bin\Release\Pare.SettlementValidationResultFileProcessingService.exe"
	Start-Process "..\..\..\PARE\main\Code\Pare.StatusListService\bin\Release\Pare.StatusListService.exe"

	Start-Process "..\..\..\PARE\main\Code\ResponseFileProcessorService\bin\Release\ResponseFileProcessorService.exe"

	Start-Process "..\..\..\PARE\main\Code\SettlementFileResponseService\bin\Release\SettlementFileResponseService.exe"
	Start-Process "..\..\..\PARE\main\Code\TapFileProcessorService\bin\Release\TapFileProcessorService.exe"
	Start-Process "..\..\..\PARE\main\Code\TravelDayRevisionService\bin\Release\TravelDayRevisionService.exe"
	Start-Process "..\..\..\PARE\main\Code\IdraService\bin\Release\IdraService.exe"


	Start-Process "..\..\..\PARE\main\Code\Pare.ChargeCalculationService\bin\Release\Pare.ChargeCalculationService.exe" #doesn't seem to start
	Start-Process "..\..\..\PARE\main\Code\Pare.RiskAssessmentService\bin\Release\RiskAssessment.Service.exe" #doesn't seem to start
	Start-Process "..\..\..\PARE\main\Code\RevenueStatusListFileService\bin\Release\RevenueStatusListFileService.exe" #doesn't seem to start
	Start-Process "..\..\..\PARE\main\Code\RefundFileService\bin\Release\RefundFileService.exe" #errors

	Start-Process "..\..\..\OyBO\main\Code\Tfl.Ft.OyBO.FileProcessor.Host\bin\Release\Tfl.Ft.OyBO.FileProcessor.Host.exe" 
	Start-Process "..\..\..\OyBO\main\Code\Tfl.Ft.OyBO.AzureMobileUploader.Host\bin\Release\Tfl.Ft.OyBO.AzureMobileUploader.Host.exe" 
	
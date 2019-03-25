REM Start AppFabric Cache (assumes FAEIntraday cache has already been created)
Powershell.exe -executionpolicy Unrestricted -File .\StartAppFabricCache.ps1

REM Start FTP Windows services (assumes PARE, FAE and Notifications have all been built from Source in Release mode)
start .\console2\console.exe -c ".\ZD_ConsoleConfig_SRC.xml" ^
-w "FTP Services hosted in Topshelf" ^
-ts 2000 ^
-t "OyBO Transaction File Processor" ^
-t "OyBO Azure Uploader" ^
-t "MjtService" ^
-t "FareService" ^ 
-t "RevenueStatusListFileServiceHost" ^
-t "SettlementResponseFileServiceHost" ^
-t "TapFileServiceHost" ^
-t "TravelDayRevisionServiceHost" ^
-t "Tfl.Ft.Notifications.FileProcessor.WindowsService" ^
-t "SendEmailService" ^
-t "AuthorisationGatewayServiceHost" ^
-t "EodControllerServiceHost" ^
-t "IdraServiceHost" ^
-t "DirectPaymentServiceHost" ^
-t "SettlementValidationResultFileServiceHost" ^
-t "StatusListServiceHost" ^
-t "RefundFileServiceHost" ^
-t "PipelineHost" ^
-t "EngineControllerHost" ^
-t "PcsMockServiceHost" ^
-t "RiskAssessmentServiceHost" ^
-t "ChargeCalculationServiceHost" ^
-t "SDM.ControllerService" /c

REM Start IIS Express (assumes CSC, PARE, FAE and Notifications sites and services have all been built from Source)
"%PROGRAMFILES%\IIS Express\iisexpress.exe" /config:ZD_ApplicationHost_SRC.config /apppool:Clr4IntegratedAppPool









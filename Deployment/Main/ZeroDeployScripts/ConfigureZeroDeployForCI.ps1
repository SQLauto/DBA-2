param(
    [array]$components=@('CASC', 'PARE', 'CommonServicesTracking', 'CommonServicesMonitor', 'FAE', 'MasterData', 'Autogration', 'SDM', 'OyBO'),
    [string]$autogrationDbPrefix= "Autogration_", 
	[string]$server = "localhost",
    [string]$workspaceBasePath = "..\..\..\", 
	[string]$zeroDeploymentPath = $env:ZeroDeployPath
)
Write-Host $zeroDeploymentPath

#No longer required as we now specify the applicationhost.config to be used with the instance of IIS Express
#function ConfigureIisExpress {
#}

function ConfigureWebConfigs {
    Set-Location $root
    #$appConfigPath = Resolve-Path '..\..\..\CACC\Main\CSC.Data.Entity.IntegrationTests\App.config'
	$webDataAccessConfigPaths = @( 
		$zeroDeploymentPath + '\CACC\_PublishedWebsites\CSC Web\web.config';
		$zeroDeploymentPath + '\CACC\_PublishedWebsites\CSC.MockServices\web.config';
		$zeroDeploymentPath + '\CACC\_PublishedWebsites\CSC.Support.Web\web.config';
		$zeroDeploymentPath + '\CACC\_PublishedWebsites\CSC.Webservice.Customer\web.config';
		$zeroDeploymentPath + '\CACC\_PublishedWebsites\CSC.Webservice.External.Authorisation\web.config';
		$zeroDeploymentPath + '\CACC\_PublishedWebsites\CSC.Webservice.External.Customer\web.config';
		$zeroDeploymentPath + '\CACC\_PublishedWebsites\CSC.Webservice.External.TokenStatus\web.config';
		$zeroDeploymentPath + '\CACC\_PublishedWebsites\CSC.Webservice.Lookup\web.config';
		$zeroDeploymentPath + '\CACC\_PublishedWebsites\Casc.Customer.Service\web.config';
		$zeroDeploymentPath + '\CACC\_PublishedWebsites\Casc.Card.Service\web.config';
	)

	foreach($configPath in $webDataAccessConfigPaths) {
		try{
			Write-Host "RESOLVING $configPath"
			$appConfigPath = Resolve-Path($configPath)
			$newDbName = $autogrationDbPrefix + 'CSCWebSSO'
			Write-Host "NEW_DB_NAME $newDbName"
			
			ModifyConnectionString `
				-path $appConfigPath `
				-xpath "//connectionStrings/add[@name = 'CSC']/@connectionString" `
				-newproperties @{'Data Source' = $server; 'Initial Catalog'=$newDbName}	
			
			ModifyConnectionString `
				-path $appConfigPath `
				-xpath "//connectionStrings/add[@name = 'CustomerDbContext']/@connectionString" `
				-newproperties @{'Data Source' = $server; 'Initial Catalog'=$newDbName}
			
			ModifyConnectionString `
				-path $appConfigPath `
				-xpath "//connectionStrings/add[@name = 'PaymentCardDbContext']/@connectionString" `
				-newproperties @{'Data Source' = $server; 'Initial Catalog'=$newDbName}	
			
			ModifyConnectionString `
				-path $appConfigPath `
				-xpath "//connectionStrings/add[@name = 'ReadOnlyDbContext']/@connectionString" `
				-newproperties @{'Data Source' = $server; 'Initial Catalog'=$newDbName}		

			#Configure Web Services
			ConfigureWebServices -path $appConfigPath 
				
			ModifySiteUrls -path $appConfigPath 
				
			
		}
		catch{
			Write-host "SOME ERROR :("
		}
		
		try{
			$appConfig = [Xml](Get-Content -Path $appConfigPath)
			Write-Host "SET $newDbName as DB name in $appConfigPath"
			#re-configure EF to use SQL Server instance instead of local Express instance. Must be already deployed.
			$appConfig.configuration.entityFramework.defaultConnectionFactory.Type = 'System.Data.Entity.Infrastructure.SqlConnectionFactory, EntityFramework'
			$appConfig.configuration.entityFramework.providers.provider.invariantName = 'System.Data.SqlClient'
			$appConfig.configuration.entityFramework.providers.provider.type = 'System.Data.Entity.SqlServer.SqlProviderServices, EntityFramework.SqlServer'
		}
		catch{
		}
		finally{
			$appConfig.Save($appConfigPath)
		}
		Write-Host "MODIFIED $appConfigPath"
	}
	
	#Switch off ReCaptcha for testing
	$webConfigPath = $zeroDeploymentPath + '\CACC\_PublishedWebsites\CSC Web\web.config'
	$recaptchaXpath = "//Captcha/add[@key='Captcha']/@value"
	ModifyConfigValue `
			-path $webConfigPath `
			-xpath $recaptchaXpath `
			-newValue "false"
			
	$cacheManagerXpath = "//CacheManager/add[@key='EnableCacheManagerCaching']/@value"
	ModifyConfigValue `
			-path $webConfigPath `
			-xpath $cacheManagerXpath `
			-newValue "false"
	
	$emailDirectoryXpath = "//Email/add[@key='EmailDirectory']/@value"
	ModifyConfigValue `
			-path $webConfigPath `
			-xpath $emailDirectoryXpath `
			-newValue "D:\TFL\CACC\emailqueue"
}

function ConfigureWebServices {
	param(
        [string] $path = $(throw, 'Missing path parameter')
    )
	
	$services = @{ 
        "ILookupWebService" = "http://localhost:8708/LookupWebService.svc" ;
		"ITravelTokenService" ="http://localhost:65534/TravelTokenService.svc" ;
		"IBillingSummaryService" ="http://localhost:65534/v2/BillingSummaryService.svc" ;
		"IJourneyUsageService" ="http://localhost:7435/v2/JourneyUsageService.svc" ;
		"IManualCorrectionService" ="http://localhost:7435/V2/ManualCorrectionService.svc" ;
		"IDirectPaymentService" ="http://localhost:65534/DirectPaymentService.svc" ;
		"JourneyUsageApiServiceBaseUrl" ="http://localhost:57413/" ;	
		"CSCBaseAddress" ="http://localhost:24354/api/";
		"ICSCSupportService" = "http://localhost:2893/CSCSupportService.svc" ;
		"IDenyListService" = "http://localhost:2893/DenyListService.svc" ;
    }
	
	foreach ($service in $services.GetEnumerator())
	{
		try{
			$serviceName = $service.Name
			$xpath = "//add[@key = '$serviceName']"
			

			ModifyConfigValue `
				-path $path `
				-xpath $xpath `
				-newValue $service.Value
		}
		catch{
			Write-Host "ERROR WRITING CONFIG"
			Write-Host $xpath
			Write-Host $service.Value
		}
	}
}

function ModifySiteUrls {
	
	param(
        [string] $path = $(throw, 'Missing path parameter')
    )
	
	Write-Host "UPDATING SITE URLS"
	
	$sites = @{ 
        "CascValidateUrl" = "http://localhost:8222/homepage/validate" ;
		"CasValidateUrl" = "http://localhost:8080/homepage/validate" ;
		"CascSignOutUrl" = "http://localhost:8222/Homepage/LogOff" ;
		"CascHomePageUrl" = "http://localhost:8222/" ;
		"RegistrationSuccessReturnURL" = "http://localhost:8222/" ;
		"PaymentGatewayReturnBaseUrl" = "http://localhost:8222" ;	
		"CascHomepage" ="http://localhost:8222/dashboard";
		"SsoLoginErrorUrl" = "http://localhost:8222/" ;
		"PdfBaseUrl" = "http://localhost:8222/" ;
    }
	
	foreach ($site in $sites.GetEnumerator())
	{
		try{
			
			$siteName = $site.Name
			$xpath = "//add[@key = '$siteName']"
			Write-Host "Updating $siteName to " $site.Value
			

			ModifyConfigValue `
				-path $path `
				-xpath $xpath `
				-newValue $site.Value
		}
		catch{
			Write-Host "ERROR WRITING CONFIG"
			Write-Host $xpath
			Write-Host $site.Value
		}
	}
}

function ConfigureOyBOEnvironment {
	$fileProcessorHostConfigPath="$zeroDeploymentPath\OyBO\Tfl.Ft.OyBo.FileProcessor.Host.exe.config"
	$mdSettingsServiceUrlAppSettingXpath="//FileProcessorSettings/add[@key='SettingsServiceUrl']/@value"
	$mdSsettingsServiceUrlValue="http://localhost:8734/"
	ModifyConfigValue `
				-path $fileProcessorHostConfigPath `
				-xpath $mdSettingsServiceUrlAppSettingXpath `
				-newValue $mdSsettingsServiceUrlValue
}

function ConfigureFaeEnvironment {
	#
	#Write-host "Setting permissions for FAE config files under source control"
	#attrib -r -s "..\..\..\FAE\Main\Code\JourneyUsageService\connectionstrings.config"
	#attrib -r -s "..\..\..\FAE\Main\Code\Tfl.Ft.Fae.JourneyUsage.ApiService\web.config" 
	
    $faeDbName = $autogrationDbPrefix + 'fae'
	$pareDbName = $autogrationDbPrefix + 'pare'

	$faeConnectionStringPaths = @( 
		 "$zeroDeploymentPath\FAE\connectionstrings.config" ;
         "$zeroDeploymentPath\FAE\EngineControllerHost.exe.config" ;
         "$zeroDeploymentPath\FAE\PipelineHost.exe.config" ;
		 "$zeroDeploymentPath\FAE\_PublishedWebsites\JourneyUsageService\connectionstrings.config" ;
		 "$zeroDeploymentPath\FAE\_PublishedWebsites\Tfl.Ft.Fae.JourneyUsage.ApiService\connectionstrings.config";
	)
    
	foreach ($connectionStringsConfigPath in $faeConnectionStringPaths)
	{
		attrib -r -s $connectionStringsConfigPath
		
		ModifyConnectionString `
				-path $connectionStringsConfigPath `
				-xpath "//connectionStrings/add[@name = 'PareDataAccessConnectionString']/@connectionString" `
				-newproperties @{'Data Source' = $server; 'Initial Catalog'=$pareDbName}
		
		ModifyConnectionString `
				-path $connectionStringsConfigPath `
				-xpath "//connectionStrings/add[@name = 'CommonDataAreaConnectionString']/@connectionString" `
				-newproperties @{'Data Source' = $server; 'Initial Catalog'=$faeDbName}	
		
		ModifyConnectionString `
				-path $connectionStringsConfigPath `
				-xpath "//connectionStrings/add[@name = 'ConfigurationEntities']/@connectionString" `
				-newproperties @{'Data Source' = $server; 'Initial Catalog'=$faeDbName}	
		
		ModifyConnectionString `
				-path $connectionStringsConfigPath `
				-xpath "//connectionStrings/add[@name = 'ReportingConnectionString']/@connectionString" `
				-newproperties @{'Data Source' = $server; 'Initial Catalog'=$faeDbName}	
		
		ModifyConnectionString `
				-path $connectionStringsConfigPath `
				-xpath "//connectionStrings/add[@name = 'BaseData_Publish_FAE_Entity']/@connectionString" `
				-newproperties @{'Data Source' = 'TDC2FAEC02V01\VINS001'; 'Initial Catalog' = 'BaseData_Publish_v20_0'}	
	}
	
	#ServiceBus uses port 9000, so change EngineControllerHost service to use port 9500 instead
	$engineControllerHostConfigPath="$zeroDeploymentPath\FAE\EngineControllerHost.exe.config"
	$serviceBaseAddressXpath="//services/service[@name='System.ServiceModel.Routing.RoutingService']/host/baseAddresses/add/@baseAddress"
	$serviceBaseAddress="http://*:9500/router"
	ModifyConfigValue `
				-path $engineControllerHostConfigPath `
				-xpath $serviceBaseAddressXpath `
				-newValue $serviceBaseAddress

    #Correct EngineControllerHost settings for local rig
    $slot0AddressHostXpath = "//enginecontroller/addresses/addAddress[@slotIndex='0']/@hostname"
    $slot1AddressXpath = "//enginecontroller/addresses/addAddress[@slotIndex='1']"
    $slot2AddressXpath = "//enginecontroller/addresses/addAddress[@slotIndex='2']"
    ModifyConfigValue `
				-path $engineControllerHostConfigPath `
				-xpath $slot0AddressHostXpath `
				-newValue "localhost"
    DeleteConfigElement `
				-path $engineControllerHostConfigPath `
				-xpath $slot1AddressXpath 
    DeleteConfigElement `
				-path $engineControllerHostConfigPath `
				-xpath $slot2AddressXpath 

	$faeAppSettingsConfigPath="$zeroDeploymentPath\FAE\appSettings.config"
	ModifyConfigValue `
				-path $faeAppSettingsConfigPath `
				-xpath $serviceBusConnectionStringXpath `
				-newValue "Endpoint=sb://localhost/ServiceBusDefaultNamespace;StsEndpoint=https://localhost:9355/ServiceBusDefaultNamespace;RuntimePort=9354;ManagementPort=9355;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=8GnqmnAXdBulAAtItbAPGk237ymGYUgUoUn/9bfyinI=" 

    #Correct Pipeline config for local rig
    $pipelineConfigPath="$zeroDeploymentPath\FAE\PipelineHost.exe.config"
	$dataCacheServiceAccountXpath="//dataCacheClient/@dataCacheServiceAccountType"
	$dataCacheServiceAccountType="SystemAccount"
	ModifyConfigValue `
				-path $pipelineConfigPath `
				-xpath $dataCacheServiceAccountXpath `
				-newValue $dataCacheServiceAccountType

    $dataCacheHostnameXpath="//dataCacheClient/hosts/host/@name"
	$dataCacheHostname="localhost"
	ModifyConfigValue `
				-path $pipelineConfigPath `
				-xpath $dataCacheHostnameXpath `
				-newValue $dataCacheHostname
				
	#Configure Masterdata services (self-hosted) for autogration
	$mjtServiceUrlAppSettingXpath="//appSettings/add[@key='MjtServiceUrl']/@value"
	$mjtServiceUrlValue="http://localhost:8731/"
	ModifyConfigValue `
				-path $pipelineConfigPath `
				-xpath $mjtServiceUrlAppSettingXpath `
				-newValue $mjtServiceUrlValue
				
	$faresServiceUrlAppSettingXpath="//appSettings/add[@key='FaresServiceUrl']/@value"
	$faresServiceUrlValue="http://localhost:8732/"
	ModifyConfigValue `
				-path $pipelineConfigPath `
				-xpath $faresServiceUrlAppSettingXpath `
				-newValue $faresServiceUrlValue

    $settingsServiceUrlAppSettingXpath="//appSettings/add[@key='SettingsServiceUrl']/@value"
	$settingsServiceUrlValue="http://localhost:8734/"
	ModifyConfigValue `
				-path $pipelineConfigPath `
				-xpath $settingsServiceUrlAppSettingXpath `
				-newValue $settingsServiceUrlValue
				
	#<add key="MjtServiceUrl" value="http://10.107.248.106:8731/" />  
    #<add key="MjtApiVersion" value="1" />
    #<add key="FaresServiceUrl" value="http://10.107.248.106:8732/" />
    
}

function ConfigureNotificationAppConfigs {

	$NotificationDataAccessConfigPaths = @( 
		$zeroDeploymentPath + '\Notifications\Tfl.Ft.Notifications.FileProcessor.WindowsService.exe.config';
		$zeroDeploymentPath + '\Notifications\SendEmailService.exe.config';
	)

    $newDbName = $autogrationDbPrefix + 'NotificationProcessorDb'

	foreach($dataAccessConfigPath in $NotificationDataAccessConfigPaths) {
		Write-Host "Updating Notification data access connection string in $notificationDataAccessConfigPath"
	    $connectionStringsConfigPath = Resolve-Path $dataAccessConfigPath
		#CheckoutFile -path $connectionStringsConfigPath -workspaceKey 'PARE'

        ModifyConnectionString `
            -path $connectionStringsConfigPath `
            -xpath "//connectionStrings/add[@name = 'NotificationConnectionString']/@connectionString" `
            -newproperties @{'Data Source' = $server; 'Initial Catalog'=$newDbName}
	}	
}

function ConfigureAutogrationAppConfigs {

	$faeDbName = $autogrationDbPrefix + 'FAE'
	$pareDbName = $autogrationDbPrefix + 'PARE'
	$cscDbName = $autogrationDbPrefix + 'CSCWebSSO'
	$notificationsDbName = $autogrationDbPrefix + 'NotificationProcessorDb'
	$sdmDbName = $autogrationDbPrefix + 'SDM'

    $autogrationAppConfigPath = Resolve-Path '..\..\..\integration\Main\Code\Autogration.AcceptanceTests\app.config'
	sp $autogrationAppConfigPath IsReadOnly $false
	
	ModifyConnectionString `
            -path $autogrationAppConfigPath `
            -xpath "//connectionStrings/add[@name = 'Pare']/@connectionString" `
            -newproperties @{'Data Source' = $server; 'Initial Catalog'=$pareDbName}
	
	ModifyConnectionString `
            -path $autogrationAppConfigPath `
            -xpath "//connectionStrings/add[@name = 'FAE']/@connectionString" `
            -newproperties @{'Data Source' = $server; 'Initial Catalog'=$faeDbName}	
	
	ModifyConnectionString `
            -path $autogrationAppConfigPath `
            -xpath "//connectionStrings/add[@name = 'CASC']/@connectionString" `
            -newproperties @{'Data Source' = $server; 'Initial Catalog'=$cscDbName}
			
	ModifyConnectionString `
            -path $autogrationAppConfigPath `
            -xpath "//connectionStrings/add[@name = 'Notifications']/@connectionString" `
            -newproperties @{'Data Source' = $server; 'Initial Catalog'=$notificationsDbName}
			
	ModifyConnectionString `
            -path $autogrationAppConfigPath `
            -xpath "//connectionStrings/add[@name = 'SDMContext']/@connectionString" `
            -newproperties @{'Data Source' = $server; 'Initial Catalog'=$sdmDbName; 'Integrated Security'='True'; 'MultipleActiveResultSets'='True'}
			

	$localAutogrationAppConfigPath = Resolve-Path '..\..\..\integration\Main\Code\Autogration.AcceptanceTests\localAutogration.config'
    sp $localAutogrationAppConfigPath IsReadOnly $false
	
	#No longer need this if using CI build in Autogration folder			
	$SsoMockResponsesBasePath = Resolve-Path "$zeroDeploymentPath\CACC\_PublishedWebsites\CSC.MockServices\MockResponses\Sso\Webservices"
	ModifyConfigValue `
				-path $localAutogrationAppConfigPath `
				-xpath "//add[@key = 'SsoMockResponsesBasePath']" `
				-newValue $SsoMockResponsesBasePath
				
	$TravelDayRevisionExporterExePath = Resolve-Path "$zeroDeploymentPath\FAE\Tfl.Ft.Fae.TravelDayRevisionExporter.exe"
	ModifyConfigValue `
				-path $localAutogrationAppConfigPath `
				-xpath "//add[@key = 'TravelDayRevisionExporterExePath']" `
				-newValue $TravelDayRevisionExporterExePath
				
	$SettlementApplicationExePath = Resolve-Path "$zeroDeploymentPath\PARE\SettlementApplication.exe"
	ModifyConfigValue `
				-path $localAutogrationAppConfigPath `
				-xpath "//add[@key = 'SettlementApplicationExePath']" `
				-newValue $SettlementApplicationExePath

	$DebtRecoveryApplicationExePath = Resolve-Path "$zeroDeploymentPath\PARE\DebtRecoveryApplication.exe"
	ModifyConfigValue `
				-path $localAutogrationAppConfigPath `
				-xpath "//add[@key = 'DebtRecoveryApplicationExePath']" `
				-newValue $DebtRecoveryApplicationExePath
				
	ModifyConfigValue `
				-path $localAutogrationAppConfigPath `
				-xpath "//add[@key = 'CscSitePort']" `
				-newValue "8222"
	
	ModifyConfigValue `
				-path $localAutogrationAppConfigPath `
				-xpath "//add[@key = 'TargetPlatform']" `
				-newValue "ZeroDeploy"
				
	ModifyConfigValue `
				-path $localAutogrationAppConfigPath `
				-xpath "//add[@key = 'AgentSitePort']" `
				-newValue "8080"
	
	#can't use real SSO in ZeroDeployment
	ModifyConfigValue `
				-path $localAutogrationAppConfigPath `
				-xpath "//add[@key = 'UseRealSso']" `
				-newValue "false"
	
	#attrib +r +s $autogrationAppConfigPath
	$postDeploymentConfigPath = Resolve-Path '..\..\..\integration\Main\Code\Autogration.AcceptanceTests\PostDeploymentTests.config'
    sp $postDeploymentConfigPath IsReadOnly $false
	
	ModifyConfigValue `
				-path $postDeploymentConfigPath `
				-xpath "//add[@key = 'Testing.TargetPlatform']" `
				-newValue "Current_Domain"
	ModifyConfigValue `
				-path $postDeploymentConfigPath `
				-xpath "//add[@key = 'Testing.RigName']" `
				-newValue "ZeroDeployment FTP running on localhost"
	ModifyConfigValue `
				-path $postDeploymentConfigPath `
				-xpath "//add[@key = 'Testing.RigConfigLocation']" `
				-newValue "..\..\..\..\..\..\Deployment\Main\Code\Deploy\Scripts"
	ModifyConfigValue `
				-path $postDeploymentConfigPath `
				-xpath "//add[@key = 'Testing.RigConfigFile']" `
				-newValue "LocalRig.xml"
			
    #Copy the config files to the bin debug folder to avoid having to do it manually (can't set to "Copy Always" in csproj as it breaks the automated deploy and test builds)
	$postDeploymentConfigBinFolderPath = Resolve-Path '..\..\..\integration\Main\Code\Autogration.AcceptanceTests'
	$localAutogrationAppConfigBinFolderPath = Resolve-Path '..\..\..\integration\Main\Code\Autogration.AcceptanceTests'
	mkdir "$postDeploymentConfigBinFolderPath\bin\Debug" -Force
	mkdir "$localAutogrationAppConfigBinFolderPath\bin\Debug" -Force
	cp $postDeploymentConfigPath "$postDeploymentConfigBinFolderPath\bin\Debug\PostDeploymentTests.config"
	cp $localAutogrationAppConfigPath "$localAutogrationAppConfigBinFolderPath\bin\Debug\localAutogration.config"
}

function ConfigurePareEnvironment {

	#Create the required configs
	cd $zeroDeploymentPath\PARE

    Set-Location $root

	$pareDataAccessConfigPaths = @( 
		$zeroDeploymentPath + '\PARE\_PublishedWebsites\CSCSupportService\connectionstrings.config';
		$zeroDeploymentPath + '\PARE\_PublishedWebsites\MasterDataMockWebApi\localMasterData.config';
		$zeroDeploymentPath + '\PARE\_PublishedWebsites\Pare.TravelTokenService\connectionstrings.config';
		$zeroDeploymentPath + '\PARE\AuthorisationGatewayServiceHost.exe.config';
		$zeroDeploymentPath + '\PARE\PcsMockServiceHost.exe.config';
		$zeroDeploymentPath + '\PARE\DebtRecoveryApplication.exe.config';
		$zeroDeploymentPath + '\PARE\DirectPaymentServiceHost.exe.config';
		$zeroDeploymentPath + '\PARE\EodControllerServiceHost.exe.config';
		$zeroDeploymentPath + '\PARE\FaeMockService.exe.config';
		$zeroDeploymentPath + '\PARE\IdraServiceHost.exe.config';
		$zeroDeploymentPath + '\PARE\OysterFileTool.exe.config';
		$zeroDeploymentPath + '\PARE\OysterTapImporterService.exe.config';
		$zeroDeploymentPath + '\PARE\OysterTapPlayerService.exe.config';
		$zeroDeploymentPath + '\PARE\Pare.DirectPaymentWcfService.dll.config';
		$zeroDeploymentPath + '\PARE\Pare.RequestFullStatusList.exe.config';
		$zeroDeploymentPath + '\PARE\RefundFileService.exe.config';
		$zeroDeploymentPath + '\PARE\RefundFileServiceHost.exe.config';
		$zeroDeploymentPath + '\PARE\RevenueStatusListFileService.exe.config';
		$zeroDeploymentPath + '\PARE\RevenueStatusListFileServiceHost.exe.config';
		$zeroDeploymentPath + '\PARE\SettlementApplication.exe.config';
		$zeroDeploymentPath + '\PARE\SettlementResponseFileServiceHost.exe.config';
		$zeroDeploymentPath + '\PARE\SettlementValidationResultFileServiceHost.exe.config';
		$zeroDeploymentPath + '\PARE\StatusListMaintenance.exe.config';
		$zeroDeploymentPath + '\PARE\StatusListServiceHost.exe.config';
		$zeroDeploymentPath + '\PARE\TapFileServiceHost.exe.config';
		$zeroDeploymentPath + '\PARE\TravelDayRevisionServiceHost.exe.config';
		$zeroDeploymentPath + '\PARE\VerifyTapData.exe.config';
		$zeroDeploymentPath + '\PARE\ChargeCalculationServiceHost.exe.config';
		$zeroDeploymentPath + '\PARE\RiskAssessmentServiceHost.exe.config';
		)

    $newDbName = $autogrationDbPrefix + 'pare'

	foreach($pareDataAccessConfigPath in $pareDataAccessConfigPaths) {
		try{
			Write-Host "Updating PareDataAccess connection string in $pareDataAccessConfigPath"
			$connectionStringsConfigPath = Resolve-Path $pareDataAccessConfigPath
			#CheckoutFile -path $connectionStringsConfigPath -workspaceKey 'PARE'

			ModifyConnectionString `
				-path $connectionStringsConfigPath `
				-xpath "//connectionStrings/add[@name = 'PareDataAccessConnectionString']/@connectionString" `
				-newproperties @{'Data Source' = $server; 'Initial Catalog'=$newDbName}
		}
		catch {
		}
	}
	
	#Update EodController settings
	Set-Location $root
	$EoDConfigPath = $zeroDeploymentPath + '\PARE\EodControllerServiceHost.exe.config'
	attrib -r $EoDConfigPath
	#UpdateOrInsert <add key="ReleaseDelayedAfter" value="00:00:00"/>
	$xpath = "//add[@key= 'ReleaseDelayedAfter']"
	ModifyConfigValue `
			-path $EoDConfigPath `
			-xpath $xpath `
			-newValue "00:00:00"

	#UpdateOrInsert <add key="RealTapChargeValidationPeriodInHours" value="720" />
	$xpath = "//add[@key= 'RealTapChargeValidationPeriodInHours']"
	ModifyConfigValue `
			-path $EoDConfigPath `
			-xpath $xpath `
			-newValue "720"			
			
	#Update Idra settings
	Set-Location $root
	$IdraConfigPath = $zeroDeploymentPath + '\PARE\IdraServiceHost.exe.config'
	attrib -r $IdraConfigPath
	$xpath = "//add[@key= 'AdhocAuthorisationCountLimit']"
	ModifyConfigValue `
			-path $IdraConfigPath `
			-xpath $xpath `
			-newValue "20"			
	$xpath = "//add[@key= 'AdhocAuthorisationTimeVarianceLimit']"
	ModifyConfigValue `
			-path $IdraConfigPath `
			-xpath $xpath `
			-newValue "0"	

	#Update RiskAssessmentServiceHost
	$RiskAssessmentConfigPath = $zeroDeploymentPath + '\PARE\RiskAssessmentServiceHost.exe.config'
	attrib -r $RiskAssessmentConfigPath
	ModifyConfigValue `
			-path $RiskAssessmentConfigPath `
			-xpath "//unity/container/register[@type='Tfl.Ft.Pare.Queue.Timer.ITimerQueueCache, Pare.Queue.Timer']/@mapTo" `
			-newValue "Tfl.Ft.Pare.PreProduction.RiskAssessment.WcfService.PreProductionTimerQueueCache, PreProduction.RiskAssessment.WcfService"		
	ModifyConfigValue `
			-path $RiskAssessmentConfigPath `
			-xpath "//unity/container/register[@type='IRiskAssessmentWcfService']/@mapTo" `
			-newValue "Tfl.Ft.Pare.PreProduction.RiskAssessment.WcfService.PreProductionRiskAssessmentWcfService, PreProduction.RiskAssessment.WcfService"		
	ModifyConfigValue `
			-path $RiskAssessmentConfigPath `
			-xpath "//system.serviceModel/services/service[@name='Tfl.Ft.Pare.RiskAssessment.WcfService.RiskAssessmentWcfService']/endpoint/@contract" `
			-newValue "Tfl.Ft.Pare.PreProduction.RiskAssessment.WcfService.Contract.IRiskAssessmentWcfService"		
	ModifyConfigValue `
			-path $RiskAssessmentConfigPath `
			-xpath "//system.serviceModel/services/service[@name='Tfl.Ft.Pare.RiskAssessment.WcfService.RiskAssessmentWcfService']/@name" `
			-newValue "Tfl.Ft.Pare.PreProduction.RiskAssessment.WcfService.PreProductionRiskAssessmentWcfService"		

	#Update TravelTokenService
	$TravelTokenServiceConfigPath = $zeroDeploymentPath + '\PARE\_PublishedWebsites\Pare.TravelTokenService\web.config'
	attrib -r $TravelTokenServiceConfigPath
	ModifyConfigValue `
			-path $TravelTokenServiceConfigPath `
			-xpath "//appSettings/add[@key='RiskAssessmentWcfService']/@value" `
			-newValue "http://localhost:8708/Pare.RiskAssessment.WcfService/RiskAssessmentWcfService/"		
}
 
function ConfigureNotificationsConfigs {

	$notificationProcessorDbName = $autogrationDbPrefix + 'NotificationProcessorDb'
	$cscDbName = $autogrationDbPrefix + 'CSCWebSSO'

	
	$sendEmailServiceConfigPath = $zeroDeploymentPath + '\Notifications\SendEmailService.exe.config'
	ModifyConnectionString `
            -path $sendEmailServiceConfigPath `
            -xpath "//connectionStrings/add[@name = 'NotificationsEntities']/@connectionString" `
			-newproperties @{'Data Source' = $server; 'Initial Catalog'=$notificationProcessorDbName}
	ModifyConnectionString `
            -path $sendEmailServiceConfigPath `
            -xpath "//connectionStrings/add[@name = 'CustomerCareEntities']/@connectionString" `
			-newproperties @{'Data Source' = $server; 'Initial Catalog'=$cscDbName}

	$emailTemplateXpath = "//appSettings/add[@key='emailTemplateFilePath']/@value"
	ModifyConfigValue `
			-path $sendEmailServiceConfigPath `
			-xpath $emailTemplateXpath `
			-newValue "D:\tfl\Notifications\EmailNotification\NotificationFileProcessSSIS\Templates"
	
	$emailDropFolderXpath = "//smtp/specifiedPickupDirectory/@pickupDirectoryLocation"
	ModifyConfigValue `
			-path $sendEmailServiceConfigPath `
			-xpath $emailDropFolderXpath `
			-newValue "D:\TFL\Notifications\EmailDrop"
		
	# Update Notification File Processor config
	$notificationProcessorConfigPath = $zeroDeploymentPath + '\Notifications\Tfl.Ft.Notifications.FileProcessor.WindowsService.exe.config'
	ModifyConnectionString `
            -path $notificationProcessorConfigPath `
            -xpath "//connectionStrings/add[@name = 'NotificationConnectionString']/@connectionString" `
			-newproperties @{'Data Source' = $server; 'Initial Catalog'=$notificationProcessorDbName}

	$notificationFileProcesorDirectoriesXpath = "//appSettings//add[@key='NotificationFileProcessorDirectories']/@value"
	ModifyConfigValue `
			-path $notificationProcessorConfigPath `
			-xpath $notificationFileProcesorDirectoriesXpath `
			-newValue "D:\TFL\Notifications\EmailNotification\NotificationFileProcessor\"

    del "$zeroDeploymentPath\Notifications\Ninject.Web.*"
}

function ConfigureSdmConfigs {

    $sbr = Get-SBAuthorizationRule -Namespace 'ServiceBusDefaultNamespace'
	$sdmDatabaseName = $autogrationDbPrefix + 'SDM'
	
	$sdmControllerServiceConfigPath = $zeroDeploymentPath + '\SDM\ControllerService.exe.config'
	ModifyConnectionString `
            -path $sdmControllerServiceConfigPath `
            -xpath "//connectionStrings/add[@name = 'SDMContext']/@connectionString" `
			-newproperties @{'Data Source' = $server; 'Initial Catalog'=$sdmDatabaseName; 'Integrated Security'='True'; 'MultipleActiveResultSets'='True'}

	$serviceBusConnectionStringXpath = "//appSettings/add[@key='Microsoft.ServiceBus.ConnectionString']/@value"
	ModifyConfigValue `
			-path $sdmControllerServiceConfigPath `
			-xpath $serviceBusConnectionStringXpath `
			-newValue $sbr.ConnectionString	
	
	#FAE ServiceBus ConnectionString Update
	$engineControllerHostConfigPath="$zeroDeploymentPath\FAE\appSettings.config"
	ModifyConfigValue `
				-path $engineControllerHostConfigPath `
				-xpath $serviceBusConnectionStringXpath `
				-newValue $sbr.ConnectionString	

	
	#Web configs
	$sdmWebConnectionStringPath = $zeroDeploymentPath + '\SDM\_PublishedWebsites\CSC.SDM.Services\web.config'
	ModifyConnectionString `
				-path $sdmWebConnectionStringPath `
				-xpath "//connectionStrings/add[@name = 'SDMContext']/@connectionString" `
				-newproperties @{'Data Source' = $server; 'Initial Catalog'=$sdmDatabaseName; 'Integrated Security'='True'; 'MultipleActiveResultSets'='True'}
		
	#Todo: add MockSSO database configs for MockSSO site?
}

function ConfigureMasterDataConfigs {
    $mjtServiceConfigPath = $zeroDeploymentPath + '\MasterData\MasterData.MaximumJourneyTimeService.exe.config'
	
	$mjtDataRootXpath = "//appSettings/add[@key='tfl.masterdata.api.dataRoot']/@value"
	ModifyConfigValue `
			-path $mjtServiceConfigPath `
			-xpath $mjtDataRootXpath `
			-newValue "D:\FMJTAssets\MjtData"


	$fareDataRootXpath = "//appSettings/add[@key='tfl.masterdata.api.dataRoot']/@value"
	$fareServiceConfigPath = $zeroDeploymentPath + '\MasterData\MasterData.FareService.exe.config'
	ModifyConfigValue `
			-path $fareServiceConfigPath `
			-xpath $fareDataRootXpath `
			-newValue "D:\FMJTAssets\FaresData"

	$masterDataSqlServerInstance = "localhost"
	$projectionStoreDatabase = "Autogration_MasterData_ProjectionStore"
	$masterDataApiConfigPath = $zeroDeploymentPath + '\MasterData\_PublishedWebsites\MasterData.WebApi\Web.config'
		
	ModifyConnectionString `
		-path $masterDataApiConfigPath `
		-xpath "//connectionStrings/add[@name = 'MasterDatabaseContext']/@connectionString" `
		-newproperties @{'Data Source' = $masterDataSqlServerInstance; 'Database'=$projectionStoreDatabase;} `
}
 
function ModifyConnectionString {
	param(
        [string] $path = $(throw, 'Missing path parameter'),
        [string] $xpath = $(throw, 'Missing xpath parameter'),
        [hashtable] $newproperties,
		[string[]] $propertiesToRemove
    )

    $xmlContent = [xml](Get-Content -Path $path)

    Add-Type -AssemblyName System.Data.Entity
    $outerBuilder = $null
    $innerBuilder = $null

   
	$xmlContent.SelectNodes($xpath) | foreach { 

        #An EF connectionstring will have a nested SQL connection string
        if($_.value -like '*metadata*') {
            $outerBuilder = New-Object System.Data.EntityClient.EntityConnectionStringBuilder -ArgumentList $_.value
            $innerBuilder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder -ArgumentList $outerBuilder.ProviderConnectionString
        }
        else {
            $outerBuilder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder -ArgumentList $_.value
            $innerBuilder = $outerBuilder
        }

        foreach ($prop in $newproperties.GetEnumerator()) {
            $innerBuilder.Add($prop.Name, $prop.Value)
			
        }

		if ($propertiesToRemove.count -gt 0) {
			foreach ($propertyToRemove in $propertiesToRemove.GetEnumerator()){
				 $innerBuilder.Remove($propertyToRemove)
			}
		}

        if($_.value -like '*metadata*') {
            $outerBuilder.set_ProviderConnectionString($innerBuilder.ConnectionString)
        }

        $_.value = $outerBuilder.ConnectionString
    }
   	$xmlContent.Save($path)
}

function ModifyConfigValue {
	param(
        [string] $path = $(throw, 'Missing path parameter'),
        [string] $xpath = $(throw, 'Missing xpath parameter'),
        [string] $newValue
    )
	 $xmlContent = [xml](Get-Content -Path $path)

	 $xmlContent.SelectNodes($xpath) | foreach { 
		Write-Host "Current value - " $_.value
		$_.value = $newValue
		$xmlContent.Save($path)
		Write-Host "New value to - $newValue"
	 }
}

function DeleteConfigElement {
	param(
        [string] $path = $(throw, 'Missing path parameter'),
        [string] $xpath = $(throw, 'Missing xpath parameter')
    )
	 $xmlContent = [xml](Get-Content -Path $path)
    try
    {
        $node = $xmlContent.SelectSingleNode($xpath)
        $node.ParentNode.RemoveChild($node)
        $xmlContent.Save($path)	
    } 
    catch
    {
        #if it doens't exist, don't delete it
    }
}

function ConfigureZeroDeploymentConfigs {
    $script:root = Resolve-Path $(Join-path $workspaceBasePath 'Deployment\Main\ZeroDeployScripts')
    Set-Location $root

    (gc .\ZD_ConsoleConfig_CI.xml).replace('%ZeroDeployPath%', $zeroDeploymentPath) | sc .\ZD_ConsoleConfig_CI.xml
    (gc .\ZD_ApplicationHost_CI.config).replace('%ZeroDeployPath%', $zeroDeploymentPath) | sc .\ZD_ApplicationHost_CI.config 
}

function Main {

    $script:root = Resolve-Path $(Join-path $workspaceBasePath 'Deployment\Main\ZeroDeployScripts')

    Set-Location $root
	
	Write-Host "Configuring FAE applications"
	ConfigureFaeEnvironment

	Write-Host "Configuring OyBO configs"
	ConfigureOyBOEnvironment
	
	Write-Host "Configuring PARE applications"
	ConfigurePareEnvironment
	
	Write-Host "Configuring Notifications applications"
	ConfigureNotificationsConfigs
	
	Write-Host "Configuring SDM applications"
	ConfigureSdmConfigs
	
	Write-Host "Configuring Web configs"
	ConfigureWebConfigs
	
	Write-Host "Configuring MasterData configs"
	ConfigureMasterDataConfigs

	Write-Host "Configuring Autogration config"
	ConfigureAutogrationAppConfigs
	
	Write-Host "Configuring ZeroDeploy configs"
	ConfigureZeroDeploymentConfigs
		
	#ConfigureNotificationAppConfigs
	#Config Mock services no longer required as not using MockResponses under source control
	#ConfigureMockServices
	#ConfigureIisExpress
}

Main
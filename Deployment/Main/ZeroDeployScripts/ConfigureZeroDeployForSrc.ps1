param(
    [array]$components=@('CASC', 'PARE', 'CommonServicesTracking', 'CommonServicesMonitor', 'FAE', 'MasterData', 'Autogration'),
    [string]$developerPrefix= "Autogration" + '_', 
	#[string]$developerPrefix=$env:USERNAME + '_',
	[string]$server = 'localhost',
    [string]$workspaceBasePath = "..\..\..\", #"D:\SRC\FTSprint52\Autogration"
	[string]$zeroDeploymentWorkspace = "FTSprint52"
)


function ConfigureIisExpress {

	#we load the site hostname,port and local disk paths from these xml files
    $cascSites = @{
        'CSC.Webservice.Lookup' = 'CSC-Webservice-Lookup.xml';
        'CSC.Webservice.External.TokenStatus' = 'CSC-Webservice-External-TokenStatus.xml';
        'CSC.Webservice.External.Authorisation' = 'CSC-Webservice-External-Authorisation.xml' ;
        'CSC.Webservice.External.Customer' = 'CSC-Webservice-External-Customer.xml' ;
        'CSC Web' = 'CSC-Web.xml';
        'CSC.MockServices' = 'CSC-MockServices.xml';
        'CSC.Webservice.Customer' = 'CSC-Webservice-Customer.xml';
		'CSC.Support.Web' = 'CSC.Support.Web.xml';
		
		#PARE Web Services
		'Pare.TravelTokenInfoService' = 'Pare.TravelTokenInfoService.xml';
		'Pare.TravelTokenService' = 'Pare.TravelTokenService.xml';
		'CSCSupportService' = 'CSCSupportService.xml';
		'MasterDataMockWebApi' = 'MasterDataMockWebApi.xml' #:52414
		
		#FAE Web Services
		'JourneyUsageService' = 'JourneyUsageService.xml';
		'Tfl.Ft.Fae.JourneyUsage.ApiService' = 'Tfl.Ft.Fae.JourneyUsage.ApiService.xml';
    }

    $applicationHostConfigPath = "C:\Users\$env:USERNAME\My Documents\IISExpress\config\applicationhost.config"
	sp $applicationHostConfigPath IsReadOnly $false

    $cfg = [Xml](Get-Content -Path $applicationHostConfigPath)

	#Configure the sites that already exist
    foreach($site in $cfg.'configuration'.'system.applicationHost'.'sites'.'site') {
        if($cascSites.Contains($site.Name)) {
			$resolvedPath = Resolve-Path($workspaceBasePath)
			$path = $([System.IO.Path]::Combine($resolvedPath, 'Deployment\Main\ZeroDeployScripts\iis_express\', $cascSites[$site.Name]))
            $newXml = [xml](Get-Content $path)
			$physicalPath = Resolve-Path( $newXml.'site'.'application'.'virtualDirectory'.'physicalPath'.ToString() )
			$newUrl = $newXml.'site'.'bindings'.'binding'.'bindingInformation'.ToString()
			$siteNodeXpath = [string]'//site[@name="{0}"]' -f $site.Name
			$siteNode = $cfg.SelectSingleNode($siteNodeXpath)
			$siteNode.'bindings'.'binding'.'bindingInformation' = $newUrl 
			$siteNode.'application'.'virtualDirectory'.'physicalPath' = $physicalPath.ToString()
            $cascSites.Remove($site.Name)
			$siteName = $site.Name
			Write-Host "Updated $siteName to URL " $newUrl
		}
    }
	
	#Now add the missing sites
	foreach($siteName in $cascSites.Keys) {
			$resolvedPath = Resolve-Path($workspaceBasePath)
			$path = $([System.IO.Path]::Combine($resolvedPath, 'Deployment\Main\ZeroDeployScripts\iis_express\', $cascSites[$siteName]))
			$siteXml = [xml](Get-Content $path)
			#Update relative path to absolute path
			$physicalPath = Resolve-Path( $siteXml.'site'.'application'.'virtualDirectory'.'physicalPath'.ToString() )
			$siteXml.'site'.'application'.'virtualDirectory'.'physicalPath' = $physicalPath.ToString()
			$cfg.'configuration'.'system.applicationHost'.'sites'.AppendChild($cfg.ImportNode($siteXml.SelectSingleNode("//site"), $true))
	}

	$cfg.Save($applicationHostConfigPath)
	Write-Host "UPDATED $applicationHostConfigPath"	
}

function ConfigureWebConfigs {
    Set-Location $root
    #$appConfigPath = Resolve-Path '..\..\..\CACC\Main\CSC.Data.Entity.IntegrationTests\App.config'
	$webDataAccessConfigPaths = @( 
		'..\..\..\CACC\Main\CSC MockServices\web.config',
		'..\..\..\CACC\Main\CSC.Webservice.Lookup\web.config',
		'..\..\..\CACC\Main\CSC.Webservice.External.Customer\web.config',
		'..\..\..\CACC\Main\CSC.Webservice.External.TokenStatus\web.config',
		'..\..\..\CACC\Main\CSC.Webservice.External.Authorisation\web.config',
		'..\..\..\CACC\Main\CSC Web\web.config',
		'..\..\..\CACC\Main\CSC.Webservice.Customer\web.config',
		'..\..\..\CACC\Main\CSC.Support.Web\web.config'
		#'..\..\..\CACC\Main\CSC.Data.Entity.IntegrationTests\App.config'
		)

	foreach($configPath in $webDataAccessConfigPaths) {
		try{
			Write-Host "RESOLVING $configPath"
			$appConfigPath = Resolve-Path($configPath)
			attrib -r -s $appConfigPath
			$newDbName = $developerPrefix + 'CSCWebSSO'
			Write-Host "NEW_DB_NAME $newDbName"
		
			
			ModifyConnectionString `
				-path $appConfigPath `
				-xpath "//connectionStrings/add[@name = 'CSC']/@connectionString" `
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
	$webConfigPath = Resolve-Path '..\..\..\CACC\Main\CSC Web\web.config'
	$recaptchaXpath = "//Captcha/add[@key='Captcha']/@value"
	ModifyConfigValue `
			-path $webConfigPath `
			-xpath $recaptchaXpath `
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
		"IJourneyUsageService" ="http://localhost:7435/JourneyUsageService.svc" ;
		"IManualCorrectionService" ="http://localhost:7435/V2/ManualCorrectionService.svc" ;
		"IDirectPaymentService" ="http://localhost:65534/DirectPaymentService.svc" ;
		"JourneyUsageApiServiceBaseUrl" ="http://localhost:57413/" ;	
		"CSCBaseAddress" ="http://localhost:24354/api/";
		"ICSCSupportService" = "http://localhost:2893/CSCSupportService.svc" ;
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

function ConfigureFaeEnvironment {
	
	Write-host "Setting permissions for FAE config files under source control"
	attrib -r -s "..\..\..\FAE\Main\Code\JourneyUsageService\web.config"
	attrib -r -s "..\..\..\FAE\Main\Code\Tfl.Ft.Fae.JourneyUsage.ApiService\web.config" 
	
    $faeDbName = $developerPrefix + 'fae'
	$pareDbName = $developerPrefix + 'pare'

	$faeConnectionStringPaths = @( 
		 "..\..\..\FAE\main\Code\PipelineHost\bin\Release\connectionstrings.config" 
		 "..\..\..\FAE\main\Code\EngineControllerHost\bin\Release\connectionstrings.config" 
		 "..\..\..\FAE\Main\Code\Tfl.Ft.Fae.TravelDayRevisionExporter\bin\Release\connectionstrings.config" 
		 "..\..\..\FAE\Main\Code\JourneyUsageService\web.config" 
		 "..\..\..\FAE\Main\Code\Tfl.Ft.Fae.JourneyUsage.ApiService\web.config"
	)
    
	foreach ($connectionStringsConfigPath in $faeConnectionStringPaths)
	{
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
	
	copy "..\..\..\FAE\main\Code\PipelineHost\bin\Release\connectionstrings.config" "..\..\..\FAE\Main\Code\JourneyUsageService\connectionstrings.config" 
	copy "..\..\..\FAE\main\Code\PipelineHost\bin\Release\connectionstrings.config"	"..\..\..\FAE\Main\Code\Tfl.Ft.Fae.JourneyUsage.ApiService\connectionstrings.config"
	
	#ServiceBus uses port 9000, so change EngineControllerHost service to use port 9500 instead
	$engineControllerHostConfigPath="..\..\..\FAE\main\Code\EngineControllerHost\bin\Release\EngineControllerHost.exe.config"
	$serviceBaseAddressXpath="//services/service[@name='System.ServiceModel.Routing.RoutingService']/host/baseAddresses/add/@baseAddress"
	$serviceBaseAddress="http://*:9500/router"
	ModifyConfigValue `
				-path $engineControllerHostConfigPath `
				-xpath $serviceBaseAddressXpath `
				-newValue $serviceBaseAddress
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

function ConfigureNotificationAppConfigs {

	$NotificationDataAccessConfigPaths = @( 
		'..\..\..\Notifications\Main\Code\Notifications\Email Notification\Tfl.Ft.Notifications.FileProcessor.WindowsService\bin\Release\Tfl.Ft.Notifications.FileProcessor.WindowsService.exe.config',
		'..\..\..\Notifications\Main\Code\Notifications\Email Notification\SendEmailService\bin\Release\SendEmailService.exe.config'
	)

    $newDbName = $developerPrefix + 'NotificationProcessorDb'

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

	$faeDbName = $developerPrefix + 'FAE'
	$pareDbName = $developerPrefix + 'PARE'
	$cscDbName = $developerPrefix + 'CSCWebSSO'
	$notificationsDbName = $developerPrefix + 'NotificationProcessorDb'

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
            -newproperties @{'Data Source' = $server; 'Initial Catalog'=$sdmDatabaseName; 'Integrated Security'='True'; 'MultipleActiveResultSets'='True'}
				

	$localAutogrationAppConfigPath = Resolve-Path '..\..\..\integration\Main\Code\Autogration.AcceptanceTests\localAutogration.config'
    sp $localAutogrationAppConfigPath IsReadOnly $false
	
	#$SsoMockResponsesBasePath = Resolve-Path "..\..\..\cacc\Main\CSC MockServices\MockResponses\Sso\Webservices"
	$SsoMockResponsesBasePath = "D:\Autogration\MockResponses\Sso\Webservices"
	ModifyConfigValue `
				-path $localAutogrationAppConfigPath `
				-xpath "//add[@key = 'SsoMockResponsesBasePath']" `
				-newValue $SsoMockResponsesBasePath
				
	$TravelDayRevisionExporterExePath = Resolve-Path "..\..\..\FAE\Main\Code\Tfl.Ft.Fae.TravelDayRevisionExporter\bin\Release\Tfl.Ft.Fae.TravelDayRevisionExporter.exe"
	ModifyConfigValue `
				-path $localAutogrationAppConfigPath `
				-xpath "//add[@key = 'TravelDayRevisionExporterExePath']" `
				-newValue $TravelDayRevisionExporterExePath
				
	$SettlementApplicationExePath = Resolve-Path "..\..\..\PARE\Main\Code\Pare.SettlementApplication\bin\Release\SettlementApplication.exe"
	ModifyConfigValue `
				-path $localAutogrationAppConfigPath `
				-xpath "//add[@key = 'SettlementApplicationExePath']" `
				-newValue $SettlementApplicationExePath
				
	ModifyConfigValue `
				-path $localAutogrationAppConfigPath `
				-xpath "//add[@key = 'CscSitePort']" `
				-newValue "8222"
				
	ModifyConfigValue `
				-path $localAutogrationAppConfigPath `
				-xpath "//add[@key = 'AgentSitePort']" `
				-newValue "8080"
	
	#attrib +r +s $autogrationAppConfigPath
			
}

function ConfigurePareAppConfigs {

	Copy-Item  ..\..\..\PARE\Main\Code\Pare.Authorisation.GatewayService\bin\Release\Authorisation.GatewayService.exe.config ..\..\..\PARE\Main\Code\TestServiceHosts\AuthorisationGatewayServiceHost\bin\Release\AuthorisationGatewayServiceHost.exe.config;
	Copy-Item  ..\..\..\PARE\Main\Code\Pare.DirectPaymentService\bin\Release\Pare.DirectPaymentService.exe.config ..\..\..\PARE\Main\Code\TestServiceHosts\DirectPaymentServiceHost\bin\Release\DirectPaymentServiceHost.exe.config;
	Copy-Item  ..\..\..\PARE\Main\Code\Pare.EodControllerService\bin\Release\EodControllerService.exe.config ..\..\..\PARE\Main\Code\TestServiceHosts\EodControllerServiceHost\bin\Release\EodControllerServiceHost.exe.config;
	Copy-Item  ..\..\..\PARE\Main\Code\IdraService\bin\Release\IdraService.exe.config ..\..\..\PARE\Main\Code\TestServiceHosts\IdraServiceHost\bin\Release\IdraServiceHost.exe.config;
	Copy-Item  ..\..\..\PARE\Main\Code\RefundFileService\bin\Release\RefundFileService.exe.config ..\..\..\PARE\Main\Code\TestServiceHosts\RefundFileServiceHost\bin\Release\RefundFileServiceHost.exe.config;
	Copy-Item  ..\..\..\PARE\Main\Code\RevenueStatusListFileService\bin\Release\RevenueStatusListFileService.exe.config ..\..\..\PARE\Main\Code\TestServiceHosts\RevenueStatusListFileServiceHost\bin\Release\RevenueStatusListFileServiceHost.exe.config;
	Copy-Item  ..\..\..\PARE\Main\Code\SettlementFileResponseService\bin\Release\SettlementFileResponseService.exe.config ..\..\..\PARE\Main\Code\TestServiceHosts\SettlementResponseFileServiceHost\bin\Release\SettlementResponseFileServiceHost.exe.config;
	Copy-Item  ..\..\..\PARE\Main\Code\Pare.SettlementValidationResultFileProcessingService\bin\Release\Pare.SettlementValidationResultFileProcessingService.exe.config ..\..\..\PARE\Main\Code\TestServiceHosts\SettlementValidationResultFileServiceHost\bin\Release\SettlementValidationResultFileServiceHost.exe.config;
	Copy-Item  ..\..\..\PARE\Main\Code\Pare.StatusListService\bin\Release\Pare.StatusListService.exe.config ..\..\..\PARE\Main\Code\TestServiceHosts\StatusListServiceHost\bin\Release\StatusListServiceHost.exe.config;
	Copy-Item  ..\..\..\PARE\Main\Code\TapFileProcessorService\bin\Release\TapFileProcessorService.exe.config ..\..\..\PARE\Main\Code\TestServiceHosts\TapFileServiceHost\bin\Release\TapFileServiceHost.exe.config;
	Copy-Item  ..\..\..\PARE\Main\Code\TravelDayRevisionService\bin\Release\TravelDayRevisionService.exe.config ..\..\..\PARE\Main\Code\TestServiceHosts\TravelDayRevisionServiceHost\bin\Release\TravelDayRevisionServiceHost.exe.config;

	$pareDataAccessConfigPaths = @( 
		'..\..\..\PARE\Main\Code\Pre-Production\OysterFileTool\bin\Release\OysterFileTool.exe.config',
		'..\..\..\PARE\Main\Code\Pre-Production\OysterTapImporterService\bin\Release\OysterTapImporterService.exe.config',
		'..\..\..\PARE\Main\Code\Pre-Production\OysterTapPlayerService\bin\Release\OysterTapPlayerService.exe.config',
		'..\..\..\PARE\Main\Code\Pare.SettlementApplication\bin\Release\SettlementApplication.exe.config',
		'..\..\..\PARE\Main\Code\Pare.RequestFullStatusList\bin\Release\Pare.RequestFullStatusList.exe.config',
		'..\..\..\PARE\Main\Code\RevenueStatusListFileService\bin\Release\RevenueStatusListFileService.exe.config',
		'..\..\..\PARE\Main\Code\Pare.SLM\bin\Release\StatusListMaintenance.exe.config',
		'..\..\..\PARE\Main\Code\FaeMockService\bin\Release\FaeMockService.exe.config',
		'..\..\..\PARE\Main\Code\Pare.DirectPaymentWcfService\bin\Release\Pare.DirectPaymentWcfService.dll.config',
		'..\..\..\PARE\Main\Code\Pare.GapsInTaps\bin\Release\VerifyTapData.exe.config'
		'..\..\..\PARE\main\Code\Pare.TravelTokenInfoService\connectionstrings.config'
		'..\..\..\PARE\Main\Code\Pare.TravelTokenService\connectionstrings.config'
		'..\..\..\PARE\main\Code\MasterDataMockWebApi\localMasterData.config'
		'..\..\..\PARE\main\Code\CSCSupportService\connectionstrings.config'
		'..\..\..\PARE\Main\Code\DebtRecoveryApplication\bin\Release\DebtRecoveryApplication.exe.config'
		'..\..\..\PARE\Main\Code\DebtRecoveryApplication\bin\Release\DebtRecoveryApplication.exe.config'
		'..\..\..\PARE\Main\Code\RefundFileService\bin\Release\RefundFileService.exe.config'

		'..\..\..\PARE\Main\Code\TestServiceHosts\RevenueStatusListFileServiceHost\bin\Release\RevenueStatusListFileServiceHost.exe.config',
		'..\..\..\PARE\Main\Code\TestServiceHosts\RefundFileServiceHost\bin\Release\RefundFileServiceHost.exe.config',
		'..\..\..\PARE\Main\Code\TestServiceHosts\IdraServiceHost\bin\Release\IdraServiceHost.exe.config',
		'..\..\..\PARE\Main\Code\TestServiceHosts\TravelDayRevisionServiceHost\bin\Release\TravelDayRevisionServiceHost.exe.config'
		'..\..\..\PARE\Main\Code\TestServiceHosts\TapFileServiceHost\bin\Release\TapFileServiceHost.exe.config',
		'..\..\..\PARE\Main\Code\TestServiceHosts\SettlementResponseFileServiceHost\bin\Release\SettlementResponseFileServiceHost.exe.config',		
		'..\..\..\PARE\Main\Code\TestServiceHosts\StatusListServiceHost\bin\Release\StatusListServiceHost.exe.config',
		'..\..\..\PARE\Main\Code\TestServiceHosts\SettlementValidationResultFileServiceHost\bin\Release\SettlementValidationResultFileServiceHost.exe.config',
		'..\..\..\PARE\Main\Code\TestServiceHosts\EodControllerServiceHost\bin\Release\EodControllerServiceHost.exe.config',
		'..\..\..\PARE\Main\Code\TestServiceHosts\DirectPaymentServiceHost\bin\Release\DirectPaymentServiceHost.exe.config',
		'..\..\..\PARE\Main\Code\TestServiceHosts\AuthorisationGatewayServiceHost\bin\Release\AuthorisationGatewayServiceHost.exe.config'
		)

    $newDbName = $developerPrefix + 'pare'

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
	
	#Update connectionString for MasterDataMockWebApi
	$MasterDataMockWebApiConfigPath = '..\..\..\PARE\Main\Code\MasterDataMockWebApi\localMasterData.config'
	$connectionStringsConfigPath = Resolve-Path $MasterDataMockWebApiConfigPath
	ModifyConnectionString `
            -path $connectionStringsConfigPath `
            -xpath "//connectionStrings/add[@name = 'MasterDataContext']/@connectionString" `
			-newproperties @{'Data Source' = $server; 'Initial Catalog'=$newDbName}
			
	#Update webservice URL for MasterDataMockWebApi
	$settlementApplicationConfigPath = '..\..\..\PARE\Main\Code\Pare.SettlementApplication\bin\Release\SettlementApplication.exe.config'
	$masterDataMockWebApiUrl = "http://localhost:52414/api/"
	$xpath = "//masterDataSettings/@endPoint"

	ModifyConfigValue `
		-path $settlementApplicationConfigPath `
		-xpath $xpath `
		-newValue $masterDataMockWebApiUrl
		
	#Update EodController settings
	Set-Location $root
	$EoDConfigPath = Resolve-Path '..\..\..\PARE\Main\Code\TestServiceHosts\EodControllerServiceHost\bin\Release\EodControllerServiceHost.exe.config'
	attrib -r $EoDConfigPath
	#UpdateOrInsert <add key="ReleaseDelayedAfter" value="00:00:00"/>
	$xpath = "//add[@key= 'ReleaseDelayedAfter']"
	ModifyConfigValue `
			-path $EoDConfigPath `
			-xpath $xpath `
			-newValue "00:00:00"	
			
	#Update Idra settings
	Set-Location $root
	$IdraConfigPath = Resolve-Path '..\..\..\PARE\Main\Code\TestServiceHosts\IdraServiceHost\bin\Release\IdraServiceHost.exe.config'
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
}

 
function ConfigureNotificationsConfigs {

	$notificationProcessorDbName = $developerPrefix + 'NotificationProcessorDb'
	$cscDbName = $developerPrefix + 'CSCWebSSO'

	# Update Send Email Service config
	$sendEmailServiceConfigPath = Resolve-Path '..\..\..\Notifications\Main\Code\Notifications\Email Notification\SendEmailService\bin\Release\SendEmailService.exe.config'
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
			-xpath $emailTemplateXpath `
			-newValue "D:\TFL\Notifications\EmailDrop"
		
	# Update Notification File Processor config
	$notificationProcessorConfigPath = Resolve-Path '..\..\..\Notifications\Main\Code\Notifications\Email Notification\Tfl.Ft.Notifications.FileProcessor.WindowsService\bin\Release\Tfl.Ft.Notifications.FileProcessor.WindowsService.exe.config'
	ModifyConnectionString `
            -path $notificationProcessorConfigPath `
            -xpath "//connectionStrings/add[@name = 'NotificationConnectionString']/@connectionString" `
			-newproperties @{'Data Source' = $server; 'Initial Catalog'=$notificationProcessorDbName}

	$notificationFileProcesorDirectoriesXpath = "//appSettings//add[@key='NotificationFileProcessorDirectories']/@value"
	ModifyConfigValue `
			-path $notificationProcessorConfigPath `
			-xpath $notificationFileProcesorDirectoriesXpath `
			-newValue "D:\TFL\Notifications\EmailNotification\NotificationFileProcessor\"

}

 function ConfigureMockServices {
	#Copy files
	$origin = Resolve-Path '..\..\..\cacc\Main\CSC MockServices\MockResponses'
	$destination = "D:\Autogration"
	Copy-Item $origin $destination -recurse -force
	
	#Make files writeable
	cd "D:\Autogration\MockResponses\"
	Get-ChildItem . –Recurse –File | Foreach {$_.IsReadOnly = $false}
	
	#Update Mock Services config
	Set-Location $root
	$mockServiceConfigPath = Resolve-Path '..\..\..\CACC\Main\CSC MockServices\web.config'
	attrib -r $mockServiceConfigPath
	#UpdateOrInsert <add key="MockResponseBaseDirectory" value="D:\Autogration\MockResponses\"/>
	$xpath = "//add[@key= 'MockResponseBaseDirectory']"
	ModifyConfigValue `
			-path $mockServiceConfigPath `
			-xpath $xpath `
			-newValue "D:\Autogration\MockResponses\"

 }
  
function ConfigureMasterDataAppConfigs {
    $mjtServiceConfigPath = $zeroDeploymentPath + '..\..\..\Main\Code\MasterDataV2\MasterData.MaximumJourneyTimeService\MasterData.MaximumJourneyTimeService.exe.config'
	
	$mjtDataRootXpath = "//appSettings/add[@key='tfl.masterdata.api.dataRoot']/@value"
	ModifyConfigValue `
			-path $mjtServiceConfigPath `
			-xpath $mjtDataRootXpath `
			-newValue "D:\FMJTAssets\MjtData"

	$fareDataRootXpath = "//appSettings/add[@key='tfl.masterdata.api.dataRoot']/@value"
	$fareServiceConfigPath = '..\..\..\Main\Code\MasterDataV2\MasterData.FareService\MasterData.FareService.exe.config'
	ModifyConfigValue `
			-path $fareServiceConfigPath `
			-xpath $fareDataRootXpath `
			-newValue "D:\FMJTAssets\FaresData"

	$masterDataSqlServerInstance = "localhost"
	$projectionStoreDatabase = "Autogration_MasterData_ProjectionStore"
	$masterDataApiConfigPath = '..\..\..\Main\Code\MasterDataV2\MasterData.WebApi\Web.config'
		
	ModifyConnectionString `
		-path $masterDataApiConfigPath `
		-xpath "//connectionStrings/add[@name = 'MasterDatabaseContext']/@connectionString" `
		-newproperties @{'Data Source' = $masterDataSqlServerInstance; 'Database'=$projectionStoreDatabase;} `
}
 
function ModifyConnectionString {
	param(
        [string] $path = $(throw, 'Missing path parameter'),
        [string] $xpath = $(throw, 'Missing xpath parameter'),
        [hashtable] $newproperties
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


function Main {

    $script:root = Resolve-Path $(Join-path $workspaceBasePath 'Deployment\Main\ZeroDeployScripts')

    Set-Location $root
	
	Write-Host "Configuring FAE applications"
	ConfigureFaeEnvironment
	ConfigurePareAppConfigs
	ConfigureNotificationsConfigs
	ConfigureMockServices
	
	ConfigureIisExpress
	ConfigureWebConfigs
	#ConfigureNotificationAppConfigs
	ConfigureMasterDataAppConfigs
	
	ConfigureAutogrationAppConfigs
	
	ConfigureSdmConfigs
}

Main
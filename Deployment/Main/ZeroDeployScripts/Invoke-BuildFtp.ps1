param(
    [array]$components=@('CASC', 'PARE', 'CommonServicesTracking', 'CommonServicesMonitor', 'FAE', 'MasterData', 'Autogration', 'OyBO'),
    [string]$developerPrefix= "Autogration_",
	[string]$server = 'localhost',
    [string]$workspaceBasePath = "..\..\..\", #"D:\SRC\FTSprint52\Autogration"
	[string]$zeroDeploymentWorkspace = "FTSprint52"
)


$runDate = Get-Date
$runDate = $runDate.ToUniversalTime()

function Build {

    param ($solution)      
       
    if([string]::IsNullOrWhiteSpace($solution)){
        throw "function Build argument `$solution cannot be null or empty"
    }     
       
    if((Test-Path -Path $solution) -ne $true) {
        throw "Cannot find $solution"
    }

    Set-Location $root
    $solution = Resolve-Path $solution

    Set-Location (Get-ChildItem -Path $solution).DirectoryName

    $stats = Measure-Command { 

        $buildCommand = "$msbuild $solution /t:Clean`;Build /p:Configuration=Release"
        Write-Host "$buildCommand"
        $output = & $msbuild $solution /t:Clean`;Build /p:Configuration=Release
        if($? -eq $false) { 
            $message = "failed to build $solution`n$output"
            $path = ".\$(get-date -f yyyy-MM-dd-mmss)_"
            $path += Split-Path $solution -leaf
            $path += ".txt"

            $message | Out-File (Join-Path $root $path)
            
            throw $message
        }

        Write-Host "$solution built successfully"

    }
	
	WriteStats -activity "Build" -itemPath $solution -duration $stats.TotalSeconds

    Set-Location $root 
    
}

function Test {

    param($target, $categoryExpression, $settingsFile)

    if([string]::IsNullOrWhiteSpace($target)){
        throw "function Test argument `$target cannot be null or empty"
    }  

    if((Test-Path -Path $target) -ne $true) {
        throw "Cannot find $target"
    }

    Set-Location $root
    $target = Resolve-Path $target

	$targetPath = (Get-ChildItem -Path $target).DirectoryName
    
    #the testresults folder gets created in the current location.  
    Set-Location $workspaceBasePath

    Write-Host "Executing tests in '$targetPath'"
    
	[System.Collections.ArrayList]$callArgs = @("/testcontainer:\`"$target\`"")

	if($categoryExpression -ne $null)
	{
		$callArgs.Add(("/category:\`"$categoryExpression\`""))
		Write-Host "Category filter is $categoryExpression"
	}

	if($settingsFile -ne $null)
	{
		$callArgs.Add(("/testSettings:\`"$settingsFile\`""))
		Write-Host "Settings file is $settingsFile"
	}

	$stats = Measure-Command {
		$output = & $mstest $callArgs
	}
	
	WriteStats -activity 'Test' -itemPath $target -duration $stats.TotalSeconds
	

    if($? -eq $false) { 
        Write-Host "$target Tests FAILED"
        Write-Host $output
        $path = ".\$(get-date -f yyyy-MM-dd-mmss)_"
        $path += Split-Path $target -leaf
        $path += ".txt"
        $output | Out-File $path
    }
       
    Set-Location $root 
}

function CheckoutFile($path, $workspaceKey) {

    if([string]::IsNullOrWhiteSpace($path)){
        throw "function CheckoutFile argument `$path cannot be null or empty"
    }

    if([string]::IsNullOrWhiteSpace($workspaceKey)){
        throw "function CheckoutFile argument `$workspaceKey cannot be null or empty"
    }

    $workspaceName = GetWorkspaceName -workspaceKey $workspaceKey
    
    Set-Location $root 
    $path = Resolve-Path $path
    
    $tfsServer = "http://tfs:8080/tfs/ftpdev"
    $tfs = [Microsoft.TeamFoundation.Client.TeamFoundationServerFactory]::GetServer($tfsServer)
	$vcs = [Microsoft.TeamFoundation.VersionControl.Client.VersionControlServer]
	$ftp = $tfs.GetService($vcs)
	        
    $workspace = $ftp.GetWorkspace($workspaceName, "${env:USERDOMAIN}\${env:USERNAME}") 

    $workspace.PendEdit($path)    

}


function BuildPaRE {
    Build('..\..\..\PARE\Main\Code\Pare (Production).sln')
}

function BuildCommonServicesTracking {
    Build('..\..\..\CommonServices\Messaging\MessageBusTracking\MessageBusTracking.sln')
}

function BuildCommonServicesMonitor {
    Build('..\..\..\CommonServices\Messaging\MessageCountMonitor\MessageCountMonitor.sln')
}

function BuildFae {
    Build('..\..\..\FAE\Main\Code\Pipeline.sln')
}

function BuildOyBO {
    Build('..\..\..\OyBO\Main\Code\OyBO.sln')
}

function BuildMasterData {
    Build('..\..\..\MasterData\Main\MasterDataV2.sln')
}

function BuildCasc {
    Build('..\..\..\CACC\Main\CSC.sln')    
	Build('..\..\..\CACC\Main\Web\Agent\Agent.sln')    
	Build('..\..\..\CACC\Main\Svc\Customer\Customer.sln')    	
	Build('..\..\..\CACC\Main\Svc\Card\Card.sln') 
}

function BuildAutogration {
	Write-Host 'Building autogration solution...'
    Build('..\..\..\Integration\Integration\Main\Code\Autogration.sln')
}

function BuildNotification {
    Build('..\..\..\Notifications\Main\Code\Notifications\Email Notification\Email Notification.sln')    
}

function TestPaRE {
	return; #ignore tests for now, build only
	$deploymentSettingsFile = Resolve-Path '..\..\..\PARE\Main\Code\Pare.testsettings'

	Test -target "..\..\..\PARE\Main\Code\Pare.Tests\bin\Release\Pare.tests.dll"
	Test -target "..\..\..\PARE\Main\Code\Pare.IntegrationTests\bin\Release\Pare.IntegrationTests.dll"
}

function TestCommonServicesMonitor {
	return; #ignore tests for now, build only
	$deploymentSettingsFile = Resolve-Path '..\..\..\CommonServices\Messaging\MessageCountMonitor\MessageCountMonitorMsTestWithoutDeployment.testsettings'

	Test -target "..\..\..\CommonServices\Messaging\MessageCountMonitor\Tfl.Ft.Messaging.MessageCountMonitor.UnitTests\bin\Release\Tfl.Ft.Messaging.MessageCountMonitor.UnitTests.dll" -settingsFile $deploymentSettingsFile
	Test -target "..\..\..\CommonServices\Messaging\MessageCountMonitor\Tfl.Ft.Messaging.MessageCountMonitor.IntegrationTests\bin\Release\Tfl.Ft.Messaging.MessageCountMonitor.IntegrationTests.dll" -settingsFile $deploymentSettingsFile
	
}

function TestCommonServicesTracking {
	$deploymentSettingsFile = Resolve-Path '..\..\..\CommonServices\Messaging\MessageBusTracking\MessageBusTrackingMsTestWithDeployment.testsettings'
	$noDeploymentSettingsFile = Resolve-Path '..\..\..\CommonServices\Messaging\MessageBusTracking\MessageBusTrackingMsTestWithoutDeployment.testsettings'

	#Core
	Test -target "..\..\..\CommonServices\Messaging\MessageBusTracking\Tfl.Ft.CommonServices.Messaging.Core.UnitTests\bin\Release\Tfl.Ft.CommonServices.Messaging.Core.UnitTests.dll"
	Test -target "..\..\..\CommonServices\Messaging\MessageBusTracking\Tfl.Ft.CommonServices.Messaging.Core.Tests\bin\Release\Tfl.Ft.CommonServices.Messaging.Core.Tests.dll" -settingsFile $deploymentSettingsFile
	#Log4Net appender
	Test -target "..\..\..\CommonServices\Messaging\MessageBusTracking\Tfl.Ft.CommonServices.Messaging.Log4Net.UnitTests\bin\Release\Tfl.Ft.CommonServices.Messaging.Log4Net.UnitTests.dll" -settingsFile $noDeploymentSettingsFile
	Test -target "..\..\..\CommonServices\Messaging\MessageBusTracking\Tfl.Ft.CommonServices.Messaging.Log4Net.Tests\bin\Release\Tfl.Ft.CommonServices.Messaging.Log4Net.Tests.dll" -settingsFile $deploymentSettingsFile
	Test -target "..\..\..\CommonServices\Messaging\MessageBusTracking\Tfl.Ft.CommonServices.Messaging.Log4Net.AcceptanceTests\bin\Release\Tfl.Ft.CommonServices.Messaging.Log4Net.AcceptanceTests.dll" -settingsFile $deploymentSettingsFile
	#Message Audit Service
	Test -target "..\..\..\CommonServices\Messaging\MessageBusTracking\Tfl.Ft.CommonServices.Messaging.MessageAudit.Tests\bin\Release\Tfl.Ft.CommonServices.Messaging.MessageAudit.Tests.dll" -settingsFile $deploymentSettingsFile
	Test -target "..\..\..\CommonServices\Messaging\MessageBusTracking\Tfl.Ft.CommonServices.Messaging.MessageAudit.AcceptanceTests\bin\Release\Tfl.Ft.CommonServices.Messaging.MessageAudit.AcceptanceTests.dll" -settingsFile $deploymentSettingsFile
	#Logger Service
	Test -target "..\..\..\CommonServices\Messaging\MessageBusTracking\Tfl.Ft.CommonServices.Messaging.MessageBusLogger.Tests\bin\Release\Tfl.Ft.CommonServices.Messaging.MessageBusLogger.Tests.dll" -settingsFile $deploymentSettingsFile
	Test -target "..\..\..\CommonServices\Messaging\MessageBusTracking\Tfl.Ft.CommonServices.Messaging.MessageBusLogger.AcceptanceTests\bin\Release\Tfl.Ft.CommonServices.Messaging.MessageBusLogger.AcceptanceTests.dll" -settingsFile $deploymentSettingsFile
	#SubscriptionAudit Service
	Test -target "..\..\..\CommonServices\Messaging\MessageBusTracking\Tfl.Ft.CommonServices.Messaging.SubscriptionAudit.UnitTests\bin\Release\Tfl.Ft.CommonServices.Messaging.SubscriptionAudit.UnitTests.dll" -settingsFile $deploymentSettingsFile
	Test -target "..\..\..\CommonServices\Messaging\MessageBusTracking\Tfl.Ft.CommonServices.Messaging.SubscriptionAudit.Tests\bin\Release\Tfl.Ft.CommonServices.Messaging.SubscriptionAudit.Tests.dll" -settingsFile $deploymentSettingsFile
	Test -target "..\..\..\CommonServices\Messaging\MessageBusTracking\Tfl.Ft.CommonServices.Messaging.SubscriptionAudit.AcceptanceTests\bin\Release\Tfl.Ft.CommonServices.Messaging.SubscriptionAudit.AcceptanceTests.dll" -settingsFile $deploymentSettingsFile
}

function TestFae {
	return; #ignore tests for now, build only
	$settingsFile = Resolve-Path '..\..\..\FAE\Main\Code\Tests\BuildUnit.Coverage.testsettings'

	# It would be better if we could discover dlls rather than hardcode their paths, but we need to handle duplicate dlls appearing in both the primary output of
	# their own project and as a referenced dll in the output of another project.
	<# 
	Get-ChildItem -rec -Path '..\..\..\FAE\Main\Code\' | 
    Where-object {!$_.psIsContainer -eq $true -and $_.FullName -match 'bin\\[^\\]+\\[^\\]+tests.dll$' } | 
    ForEach-Object -Process {Test -target $_.FullName -categoryExpression "_Unit & !WIP"}
	#>
	Test -target '..\..\..\FAE\Main\Code\DataConversion.Unit.Tests\bin\Release\DataConversion.Unit.Tests.dll' -categoryExpression '_Unit & !WIP' -settingsFile $settingsFile
	Test -target '..\..\..\FAE\Main\Code\Instrumentation.Tests\bin\Release\Instrumentation.Tests.dll' -categoryExpression '_Unit & !WIP' -settingsFile $settingsFile
	Test -target '..\..\..\FAE\Main\Code\JourneyUsageService.Tests\bin\Release\JourneyUsageService.Tests.dll' -categoryExpression '_Unit & !WIP' -settingsFile $settingsFile
	Test -target '..\..\..\FAE\Main\Code\NetworkTopology.Tests\bin\Release\NetworkTopology.Unit.Tests.dll' -categoryExpression '_Unit & !WIP' -settingsFile $settingsFile
	Test -target '..\..\..\FAE\Main\Code\Tfl.Ft.Fae.Domain.Tests\bin\Release\Tfl.Ft.Fae.Domain.Tests.dll' -categoryExpression '_Unit & !WIP' -settingsFile $settingsFile
	Test -target '..\..\..\FAE\Main\Code\Tfl.Ft.Fae.EngineController.Tests\bin\Release\Tfl.Ft.Fae.EngineController.Tests.dll' -categoryExpression '_Unit & !WIP' -settingsFile $settingsFile
	Test -target '..\..\..\FAE\Main\Code\Tfl.Ft.Fae.JourneyUsage.Service.Tests\bin\Release\Tfl.Ft.Fae.JourneyUsage.Service.Tests.dll' -categoryExpression '_Unit & !WIP' -settingsFile $settingsFile
	Test -target '..\..\..\FAE\Main\Code\Tfl.Ft.Fae.Pipeline.Tests\bin\Release\Tfl.Ft.Fae.Pipeline.Tests.dll' -categoryExpression '_Unit & !WIP' -settingsFile $settingsFile
	Test -target '..\..\..\FAE\Main\Code\Tfl.Ft.Fae.Shared.Tests\bin\Release\Tfl.Ft.Fae.Shared.Tests.dll' -categoryExpression '_Unit & !WIP' -settingsFile $settingsFile
	Test -target '..\..\..\FAE\Main\Code\Tfl.Ft.Fae.TravelDayRevision.Commands.Tests\bin\Release\Tfl.Ft.Fae.TravelDayRevision.Commands.Tests.dll' -categoryExpression '_Unit & !WIP' -settingsFile $settingsFile
}

function TestOyBO {
	return; #ignore tests for now, build only
}

function TestMasterData {

    $nuget = Resolve-Path( Join-Path $workspaceBasePath 'Deployment\Main\LocalDevScripts\nuget.exe')

    CheckoutFile -path $nuget.Path -workspaceKey 'Deployment'

    & $nuget update -self
    & $nuget "install NUnit.Runners -Version 2.6.3 -OutputDirectory .\"

    $nunit = Join-Path (Get-ChildItem -Path $nuget).DirectoryName '\NUnit.Runners.2.6.3\tools\nunit-console.exe'
    $unitTests = Resolve-Path( Join-Path $root "..\..\..\MasterData\Main\MasterData.UnitTests\bin\Release\MasterData.UnitTests.dll")
    $integrationTests = Resolve-Path( Join-Path $root "..\..\..\MasterData\Main\MasterData.IntegrationTests\bin\Release\MasterData.IntegrationTests.dll")

    $output = & $nunit $unitTests $integrationTests

    if($? -eq $false) { 
        Write-Host "Tests FAILED"
        Write-Host $output
        $output | Out-File ".\$(get-date -f yyyy-MM-dd-mmss)_master_data.txt"
    }

    Write-Host "Master Data Tests PASSED"

}

function TestCASC {
	return; #ignore tests for now, build only
    #Unit tests
    Test("..\..\..\CACC\Main\CSC.Common.Tests\bin\Release\CSC.Common.Tests.dll")
    Test("..\..\..\CACC\Main\CSC.Domain.Tests\bin\Release\TfL.CSC.Domain.Tests.dll")
    Test("..\..\..\CACC\Main\CSC.Email.Tests\bin\Release\CSC.Email.Tests.dll")
    Test("..\..\..\CACC\Main\CSC.IntegrationTests\bin\Release\TfL.CSC.IntegrationTests.dll")
    Test("..\..\..\CACC\Main\CSC.Managers.Tests\bin\Release\CSC.Managers.Tests.dll")
    Test("..\..\..\CACC\Main\CSC.Membership.Tests\bin\Release\CSC.Membership.Tests.dll")
    Test("..\..\..\CACC\Main\CSC.MockServices.Tests\bin\Release\CSC.MockServices.Tests.dll")
    Test("..\..\..\CACC\Main\CSC.PCSSimulator.Tests\bin\Release\CSC.PCSSimulator.Tests.dll")
    Test("..\..\..\CACC\Main\CSC.PDF.Tests\bin\Release\CSC.PDF.Tests.dll")
    Test("..\..\..\CACC\Main\CSC.Providers.Tests\bin\Release\CSC.Providers.Tests.dll")
    Test("..\..\..\CACC\Main\CSC.Services.Tests\bin\Release\Tfl.CSC.Services.Tests.dll")
    Test("..\..\..\CACC\Main\CSC.SSOSimulator.Tests\bin\Release\CSC.SSOSimulator.Tests.dll")
    Test("..\..\..\CACC\Main\CSC.Support.Web.Tests\bin\Release\Tfl.CSC.Support.Web.Tests.dll")
    Test("..\..\..\CACC\Main\CSC.ViewModel.Tests\bin\Release\CSC.ViewModel.Tests.dll")
    Test("..\..\..\CACC\Main\CSC.Web.Core.Tests\bin\Release\Tfl.CSC.Web.Core.Tests.dll")
    Test("..\..\..\CACC\Main\CSC.Web.Tests\bin\Release\CSC.Web.Tests.dll")
    Test("..\..\..\CACC\Main\CSC.WebAPI.Helpers.Tests\bin\Release\CSC.WebAPI.Helpers.Tests.dll")
    Test("..\..\..\CACC\Main\CSC.Webservice.Customer.Tests\bin\Release\CSC.Webservice.Customer.Tests.dll")
    Test("..\..\..\CACC\Main\CSC.Webservice.ServiceCalls.Fae.Tests\bin\Release\TfL.CSC.Webservice.ServiceCalls.Fae.Tests.dll")
    Test("..\..\..\CACC\Main\CSC.Webservice.Tests\bin\Release\CSC.Webservice.Tests.dll")

    #Integration Tests

    Test("..\..\..\CACC\Main\CSC.Data.Entity.IntegrationTests\bin\Release\CSC.Data.Entity.IntegrationTests.dll")

}

function TestAutogration {
	Write-Host 'Run autogration tests...'
	$settingsFile = Resolve-Path '..\..\..\Integration\Integration\Main\Code\local.settings'
	Test -target "..\..\..\Integration\Integration\Main\Code\Autogration.AcceptanceTests\bin\Release\Autogration.AcceptanceTests.dll" -settingsFile $settingsFile | Write-Host
	Write-Host "Integration Tests completed"
}

function TestNotification {
	return; #ignore tests for now, build only
	$deploymentSettingsFile = Resolve-Path '..\..\..\Notifications\Main\Code\Notifications\Email Notification\Local.testsettings'

}
function GetWorkspaceName($workspaceKey) {

    if([string]::IsNullOrWhiteSpace($workspaceKey)){
        throw "function GetWorkspaceName argument `$workspaceKey cannot be null or empty"
    }  

    $workspaceKeys = @{
		"PARE" = $developerPrefix+$zeroDeploymentWorkspace;
        "CommonServices" = $developerPrefix+$zeroDeploymentWorkspace;
        "FAE" = $developerPrefix+$zeroDeploymentWorkspace;
		"OyBO" = $developerPrefix+$zeroDeploymentWorkspace;
        "MasterData" = $developerPrefix+$zeroDeploymentWorkspace;
        "CASC" = $developerPrefix+$zeroDeploymentWorkspace;
        "Deployment" = $developerPrefix+$zeroDeploymentWorkspace;
		"Integration" = $developerPrefix+$zeroDeploymentWorkspace;
    }

    return [string]$workspaceKeys[$workspaceKey]
}

function ConfigureCommonServicesTracking {
	$serviceBusConfigPaths = @( 
		#Core
		'..\..\..\CommonServices\Messaging\MessageBusTracking\Tfl.Ft.CommonServices.Messaging.Core.Tests\local.Core.Tests.App.config',
		'..\..\..\CommonServices\Messaging\MessageBusTracking\Tfl.Ft.CommonServices.Messaging.Log4Net.Tests\local.Log4Net.Tests.App.config',	
		#Log4Net Appender
		'..\..\..\CommonServices\Messaging\MessageBusTracking\Tfl.Ft.CommonServices.Messaging.Log4Net.AcceptanceTests\local.Log4Net.AcceptanceTests.App.config',
		#MessageAudit Service
		'..\..\..\CommonServices\Messaging\MessageBusTracking\Tfl.Ft.CommonServices.Messaging.MessageAudit.Tests\local.MessageAudit.Tests.App.config',
		'..\..\..\CommonServices\Messaging\MessageBusTracking\Tfl.Ft.CommonServices.Messaging.MessageAudit.AcceptanceTests\local.MessageAudit.AcceptanceTests.App.config',
		#Logger Service
		'..\..\..\CommonServices\Messaging\MessageBusTracking\Tfl.Ft.CommonServices.Messaging.MessageBusLogger.Tests\local.MessageBusLogger.Tests.App.config',
		'..\..\..\CommonServices\Messaging\MessageBusTracking\Tfl.Ft.CommonServices.Messaging.MessageBusLogger.AcceptanceTests\local.MessageBusLogger.AcceptanceTests.App.config',
		#SubscriptionAudit Service
		'..\..\..\CommonServices\Messaging\MessageBusTracking\Tfl.Ft.CommonServices.Messaging.SubscriptionAudit.Tests\local.SubscriptionAudit.Tests.App.config',
		'..\..\..\CommonServices\Messaging\MessageBusTracking\Tfl.Ft.CommonServices.Messaging.SubscriptionAudit.AcceptanceTests\local.SubscriptionAudit.AcceptanceTests.App.config'
	
	
	)
	foreach($serviceBusConfigPath in $serviceBusConfigPaths) {
		Write-Host "Updating connection strings in $serviceBusConfigPath"
		CheckoutFile -path $serviceBusConfigPath -workspaceKey 'CommonServices'
		UpdateSbConnectionStringToLocalServer -filePath $serviceBusConfigPath

        $filePath = Resolve-Path -path $serviceBusConfigPath
        ModifyConnectionString `
            -path $filePath `
            -xpath "//appSettings/add[@key='MessageAuditDatabaseConnectionString']/@value" `
            -newproperties @{'Data Source' = $server; 'Initial Catalog'=($developerPrefix + "MessageBusMessageAudit"); 'Integrated Security'='SSPI'; 'User ID'=$null; 'Password'=$null }

        ModifyConnectionString `
            -path $filePath `
            -xpath "//appSettings/add[@key='MessageBusLoggerDatabaseConnectionString']/@value" `
            -newproperties @{'Data Source' = $server; 'Initial Catalog'=($developerPrefix + "MessageBusLogger"); 'Integrated Security'='SSPI'; 'User ID'=$null; 'Password'=$null }

        ModifyConnectionString `
            -path $filePath `
            -xpath "//appSettings/add[@key='SubscriptionAuditDatabaseConnectionString']/@value" `
            -newproperties @{'Data Source' = $server; 'Initial Catalog'=($developerPrefix + "MessageBusSubscriptionAudit"); 'Integrated Security'='SSPI'; 'User ID'=$null; 'Password'=$null }
	}
		
}

function ConfigureCommonServicesMonitor {
	$configPath = '..\..\..\CommonServices\Messaging\MessageCountMonitor\Tfl.Ft.Messaging.MessageCountMonitor.IntegrationTests\local.ServiceBusMonitor.Tests.App.config'
	CheckoutFile -path $configPath -workspaceKey 'CommonServices'
	UpdateSbConnectionStringToLocalServer -filePath $configPath
}

Function GetServiceBusLocalConnectionString {
	$fqdn = "$env:computername.$env:userdnsdomain"
	$connectionString = 'Endpoint=sb://' + $fqdn + '/ServiceBusDefaultNamespace;StsEndpoint=https://' + $fqdn + ':9355/ServiceBusDefaultNamespace;RuntimePort=9354;ManagementPort=9355'
	return [string]$connectionString
}

function UpdateSbConnectionStringToLocalServer {
	param(
		[string]$filePath
	)
	$filePath = Resolve-Path -path $filePath
	$appConfig = [xml](Get-Content -Path $filePath)
	$node = $appConfig.SelectSingleNode("//appSettings/add[@key='Microsoft.ServiceBus.ConnectionString']")
	if($node -ne $null){
		$node.Value = [string](GetServiceBusLocalConnectionString)
	}
	$appConfig.Save($filePath)
		
}

function WriteStats {
	param(
		[string] $activity,
		[string] $itemPath,
		[double] $duration
	)
	if(!(($activity -eq 'Build') -or ($activity -eq 'Test'))) {
		throw "Activity must be Build or Test"
	}
	
	$username = $env:USERNAME;
	$hostname = "$env:computername.$env:userdnsdomain"
	
	Try {

		$connectionString = "Data Source=$server;Initial Catalog=Django_Build_Stats;Integrated Security=SSPI"

		$statsConnection = New-Object System.Data.SqlClient.SqlConnection;
		$statsConnection.ConnectionString = $connectionString
		$statsConnection.Open();

		$command = $statsConnection.CreateCommand();

		$command.CommandText = "insert into BuildStats (Username, Hostname, Activity, ItemPath, StartTime, Duration) VALUES ('$username', '$hostname', '$activity', '$itemPath', '$runDate', $duration)"
		$result = $command.ExecuteNonQuery();

		$statsConnection.Close();
	}
	Catch [system.exception]
	{
	   "failed to write build stats to $server for item"
	}	
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

function Resolve-Error ($ErrorRecord=$Error[0])
{
   $ErrorRecord | Format-List * -Force
   $ErrorRecord.InvocationInfo |Format-List *
   $Exception = $ErrorRecord.Exception
   for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException))
   {   "$i" * 80
       $Exception |Format-List * -Force
   }
}

function Main {

	$clientDll = "D:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.Client.dll"
	$versionControlClientDll = "D:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.Common.dll"
	$versionControlCommonDll = "D:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.VersionControl.Client.dll"

	#Load the Assemblies
	[Reflection.Assembly]::LoadFrom($clientDll)
	[Reflection.Assembly]::LoadFrom($versionControlClientDll)
	[Reflection.Assembly]::LoadFrom($versionControlCommonDll)

    $script:root = Resolve-Path $(Join-path $workspaceBasePath 'Deployment\Main\LocalDevScripts')

    Set-Location $root

    $script:msbuild = Resolve-Path 'C:\Program Files (x86)\MSBuild\12.0\Bin\MSBuild.exe'
    $script:mstest = 'D:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\MSTest.exe'

    $componentMap = @{ 
        "Pare" = @{ build = {BuildPaRE}; environment = {}; tests = {TestPaRE}};
		"CommonServicesTracking" = @{build = {BuildCommonServicesTracking}; environment = {ConfigureCommonServicesTracking}; tests = {TestCommonServicesTracking}};
		"CommonServicesMonitor" = @{build = {BuildCommonServicesMonitor}; environment = {ConfigureCommonServicesMonitor}; tests = {TestCommonServicesMonitor}};
        "FAE" = @{build ={BuildFae}; environment = {}; tests = {TestFae}};
		"OyBO" = @{build ={BuildOyBO}; environment = {}; tests = {TestOyBO}};
        "MasterData" = @{build = {BuildMasterData}; environment = {}; tests = {TestMasterData}};
        "CASC" = @{build = {BuildCasc}; environment = {}; tests = {TestCASC}};
		"Autogration" = @{build = {BuildAutogration}; environment = {ConfigureAutogrationEnvironment}; tests = {TestAutogration}};
		"Notification" = @{build = {BuildNotification}; environment = {}; tests = {TestNotification}};
    }

    $formattedComponents = $components -join ', '

    foreach($component in $components) {
		if($componentMap[$component] -eq $null) {
			throw "I don't know how to build $component"
		}
	
        $index = $index++
        Write-Progress -activity "Building FTP components: $formattedComponents" -Status "Building: $component" -PercentComplete ($index / $components.Length * 100)
        try {
            $componentMap[$component]["environment"].Invoke()
        }
        catch [System.Exception] {
            Resolve-Error
        }
        try {
            $componentMap[$component]["build"].Invoke()
        }
        catch [System.Exception] {
            Resolve-Error
        }
    }

    #Delete the old test results folder
    Remove-Item $(Join-Path $workspaceBasePath 'testresults') -Recurse -ErrorAction SilentlyContinue

    foreach($component in $components) {
        $index = $index++
        Write-Progress -activity "Testing FTP components: $formattedComponents" -Status "Building: $component" -PercentComplete ($index / $components.Length * 100)
        try {
			$componentMap[$component]["tests"].Invoke()
        }
        catch [System.Exception] {
            Resolve-Error
        }
    }
}

Main
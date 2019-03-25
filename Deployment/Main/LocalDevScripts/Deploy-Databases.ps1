#requires -Version 3.0

param (
	[string]$workspaceBasePath = "D:\src\FT\",
	[array]$databasesToDeploy = @('PARE','FAE', 'CASC', 'CommonServices', 'MasterData'),
	[string]$developerPrefix = $env:USERNAME + "_",
	[string]$server = 'TDC2SQL005'
)


function DeployPare {
	Write-Progress -activity "Deploying PARE database"
	cd $PSScriptRoot
	$dbName = $developerPrefix + "PARE"
	$deploymentScript = Join-Path -Path $workspaceBasePath "\PARE\PaRE\Main\Code\Pare.Database\Dev\DevDeployIncrementalUpgrade.ps1"
	$argumentList = "-serverName " + $server + " -databaseName " + $dbName

	$output = Invoke-Expression "$deploymentScript $argumentList"
	if($? -ne $true) {
		echo $output
		throw "PARE Deployment Failed"
	}
}

function DeployFae {
	Write-Progress -activity "Deploying FAE database"
	cd $PSScriptRoot
	$dbName = $developerPrefix + "FAE"
	$deploymentScript = Join-Path -Path $workspaceBasePath "\FAE\Main\FAE\Main\Code\FAE.DataMigrationScripts\CreateDatabase.ps1"
	$argumentList = "-dbServer " + $server + " -dbName " + $dbName

	$output = Invoke-Expression "$deploymentScript $argumentList"
	if($? -ne $true) {
		echo $output
		throw "FAE Deployment Failed"
	}
}

function DeployCommonServices {
	Write-Progress -activity "Deploying CommonServices database"
	$scriptPath = Join-Path -Path $workspaceBasePath 'CommonServices\Messaging\MessageBusTracking\Databases\Dev'
	cd $scriptPath
	$deploymentScript = Join-Path -Path $scriptPath 'DeployAll.ps1'
	$argumentList = "-serverName " + $server + " -developerPrefix " + $developerPrefix
	
	$output = Invoke-Expression "$deploymentScript $argumentList"
	if($? -ne $true) {
		echo $output
		throw "CommonServices Deployment Failed"
	}
	cd $PSScriptRoot
}

function DeployCascBaseLine {
	Write-Progress -activity "Deploying CASC database" -status "Deploying Brixton Baseline"
	cd $PSScriptRoot
	
	$dbName = $developerPrefix + "CSCWebSSO"
	$scriptPath = Join-Path -Path $workspaceBasePath '\CASC\CACC\Main\CSC SQL Server Database\Brixton\CleanMachineDb.ps1'
	$argumentList = @("-server", $server, "-DatabaseName", $dbName, "-DefaultDataPath", "H:\Data", "-DefaultLogPath", "H:\Data", "-DefaultFilePrefix", $dbName, "-scriptPath", "D:\SRC\FT\CASC\CACC\Main\CSC SQL Server Database\Brixton\")

	$output = Invoke-Expression "& `"$scriptPath`" $argumentList"
	if($? -ne $true) {
		echo $output
		throw "CASC Baseline Deployment Failed"
	}
}

function DeployCascPatching {
	Write-Progress -activity "Deploying CASC database" -status "Deploying Patching Scripts"
	cd $PSScriptRoot
	
	$dbName = $developerPrefix + "CSCWebSSO"
	$scriptPath = Join-Path -Path $workspaceBasePath '\CASC\CACC\Main\CSC SQL Server Database\DevDeploy.ps1'
	$argumentList = @("-serverName", $server, "-databaseName", $dbName)
	
	$output = Invoke-Expression "& `"$scriptPath`" $argumentList"
	if($? -ne $true) {
		echo $output
		throw "CASC Patching Deployment Failed"
	}
}

function RegisterCascIisCache {
	cd $PSScriptRoot

	Write-Progress -activity "Deploying CASC database" -status "Enabling IIS Caching "
	$dbName = $developerPrefix + "CSCWebSSO"
	
	$registrations = @(
		"C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regsql -S $server -U CSCWeb -P CSCWeb -d $dbName -ed"
	    "C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regsql -S $server -U CSCWeb -P CSCWeb -d $dbName -et -t SecurityQuestion"
		"C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regsql -S $server -U CSCWeb -P CSCWeb -d $dbName -et -t Country"
		"C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regsql -S $server -U CSCWeb -P CSCWeb -d $dbName -et -t CustomerType"
		"C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regsql -S $server -U CSCWeb -P CSCWeb -d $dbName -et -t PaymentCardType"
		"C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regsql -S $server -U CSCWeb -P CSCWeb -d $dbName -et -t PaymentCardScheme"
		"C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regsql -S $server -U CSCWeb -P CSCWeb -d $dbName -et -t Title"
		"C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regsql -S $server -U CSCWeb -P CSCWeb -d $dbName -et -t Station"
		"C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regsql -S $server -U CSCWeb -P CSCWeb -d $dbName -et -t StationGroup"
		"C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regsql -S $server -U CSCWeb -P CSCWeb -d $dbName -et -t SSRReason"
		"C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regsql -S $server -U CSCWeb -P CSCWeb -d $dbName -et -t Mode"
		"C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regsql -S $server -U CSCWeb -P CSCWeb -d $dbName -et -t ServiceOperator"
	)
	
	foreach($registration in $registrations) {
		Write-Host "." -NoNewLine
		$output = Invoke-Expression $registration
		if($? -ne $true) {
			echo $output
			throw "IIS Registration command '$registration' failed"
		}		
	}
	Write-Host ""
}

function DeployCasc {
	Write-Progress -activity "Deploying CASC database"
	DeployCascBaseLine
	DeployCascPatching
	RegisterCascIisCache
}

function DropDb {
	param (
		[string]$server,
		[string]$dbName
	)
	Write-Host "        Dropping old DB"
	$output = & sqlcmd.exe -S $server -d master -Q "use master; declare @exists int; set @exists = (select count(*) from sys.databases where name = '$dbName'); if @exists = 1 exec('ALTER DATABASE $dbName SET SINGLE_USER WITH ROLLBACK IMMEDIATE; drop $dbName')"
	if($? -ne $true) {
		Write-Host $output
		throw "Drop database $dbName failed"
	}
	
}

function DeployMasterDataEventStore {
	Write-Progress -activity "Deploying Master Data database" -status "Deploying EventStore baseline"
	$dbName = $developerPrefix + "MasterData_EventStore"

	$env:DatabaseName = $dbName
	DropDb -server $server -dbName $dbName
	$baseLineScript = $scriptPath = Join-Path -Path $workspaceBasePath "MasterData\Main\MasterData.InfrastructureServices\DatabaseScripts\EventStore\Events_BaseLine.sql"
	$output = & sqlcmd.exe -S $server -d master -i $baseLineScript
	if($? -ne $true) {
		Write-Host $output
		throw "Deployment of Event store baseline failed"
	}
}

function DeployMasterDataLogging {
	Write-Progress -activity "Deploying Master Data database" -status "Deploying Logging baseline"
	$dbName = $developerPrefix + "MasterData_Logging"
	
	Write-Host "        Deploying baseline"
	$env:DatabaseName = $dbName
	DropDb -server $server -dbName $dbName
	$baseLineScript = $scriptPath = Join-Path -Path $workspaceBasePath "MasterData\Main\MasterData.InfrastructureServices\DatabaseScripts\Logging\Elmah_BaseLine.sql"
	$output = & sqlcmd.exe -S $server -d master -i $baseLineScript
	if($? -ne $true) {
		Write-Host $output
		throw "Deployment of Logging baseline failed"
	}	
}

function DeployMasterDataProjections {
	Write-Progress -activity "Deploying Master Data database" -status "Deploying Projections"
	$dbName = $developerPrefix + "MasterData_Projections"
	
	$infrastructureDir = Join-Path -Path $workspaceBasePath "MasterData\Main\MasterData.InfrastructureServices"
	$outputDir = Join-Path -Path $infrastructureDir "bin\Debug"
	$efMigrateExe = Join-Path -Path $workspaceBasePath "MasterData\Main\packages\EntityFramework.6.1.1\tools\Migrate.exe"
	$runMigrateExe = Join-Path -Path $outputDir "Migrate.exe"
	
	Write-Host "        Building MasterData.InfrastructureServices"
	cd $infrastructureDir
	$buildOutput = & 'C:\Program Files (x86)\MSBuild\12.0\Bin\MSBuild.exe' /t:build MasterData.InfrastructureServices.csproj
	if($? -ne $true) {
		Write-Host $buildOutput
		throw "Building MasterData.InfrastructureServices failed"
	}
	
	Write-Progress -activity "Deploying Master Data database" -status "Setting up Projections migration utilities"
	if((Test-Path $runMigrateExe) -eq $true) {
		Remove-Item $runMigrateExe -Force
	}
	Copy-Item $efMigrateExe $outputDir
	
	Write-Progress -activity "Deploying Master Data database" -status "Running Projections EF migration"
	cd $outputDir
	$migrateOutput = & $runMigrateExe MasterData.InfrastructureServices.dll /connectionString="Data Source=$server;Initial Catalog=$dbName; Integrated Security=SSPI" /connectionProviderName="System.Data.SqlClient"
	if($? -ne $true) {
		Write-Host $migrateOutput
		throw "Migration of $dbName failed"
	}
}

function DeployMasterData {
	Write-Progress -activity "Deploying Master Data database"
	DeployMasterDataEventStore
	DeployMasterDataLogging
	DeployMasterDataProjections
}

function Main {
	foreach($databaseToDeploy in $databasesToDeploy) {
		if($databaseToDeploy -eq 'PARE') {
			DeployPare
		}
		elseif ($databaseToDeploy -eq 'FAE') {
			DeployFae
		}
		elseif ($databaseToDeploy -eq 'CASC') {
			DeployCasc
		}
		elseif ($databaseToDeploy -eq 'CommonServices') {
			DeployCommonServices
		}
		elseif ($databaseToDeploy -eq 'MasterData') {
			DeployMasterData
		}
		else
		{
			throw "Sorry I don't know how to deploy database $databaseToDeploy"
		}
	}
}

Main
#requires -Version 3.0

param (
	[string]$workspaceBasePath = "..\..\..\",
	[array]$databasesToDeploy = @('MasterData','FAE','PARE','CASC','Notifications','SDM','CommonServices','OyBO'),
	[string]$autogrationPrefix = "Autogration_", 
	[string]$server = 'localhost',
    [string]$logpath = 'd:\dbdeploy-logs\',
	[string]$autogrationPath,
	[string]$workSpacePath
)

$LogDirectory = "D:\tfl\ZeroDeployment\Logs\"
$Logfile = "Database-Deployment.log"

function DeployXmlControlledDatabase {
    param (
		    [string]$name,
		    [string]$deploymentScript
	)

    Write-Progress -activity "Deploying $name database"
	cd $PSScriptRoot
	
	$argumentList = "-serverName " + $server + " -configName Configs\ZeroDeployment.xml -workspacePath `"" + $workspacePath + "`" -deploymentType ZeroDeployment" 
    Write-host "CALLING > $deploymentScript $argumentList"

    # Handle spaces in $deploymentScript path (http://serverfault.com/a/333959).
	$output = Invoke-Expression "& '$deploymentScript' $argumentList" | Out-File $($logpath + 'Autogration_' + $name + '.txt')
	if($? -ne $true) {
		echo $output
		throw "$name Deployment Failed"
	}
}

function DeployPare {
	Write-Progress -activity "Deploying PARE database"
	cd $PSScriptRoot
	$dbName = $autogrationPrefix + "PARE"
	$deploymentScript = Join-Path -Path $workspaceBasePath "\PaRE\Main\Code\Pare.Database\Dev\DevDeployIncrementalUpgrade.ps1"
	$argumentList = "-serverName " + $server + " -databaseName " + $dbName

	$output = Invoke-Expression "$deploymentScript $argumentList" | Out-File $($logpath + $dbName + '.txt')
	if($? -ne $true) {
		echo $output
		throw "PARE Deployment Failed"
	}
}

function DeployCasc {
    DeployXmlControlledDatabase -name "CASC" -deploymentScript (Join-Path -Path $autogrationPath "\CACC\CS.Database.Scripts\Dev\DevDeployIncrementalUpgrade.ps1")
}

function DeployFae {
	Write-Progress -activity "Deploying FAE database"
	cd $PSScriptRoot
	$dbName = $autogrationPrefix + "FAE"
	$deploymentScript = Join-Path -Path $workspaceBasePath "\FAE\Main\Code\FAE.DataMigrationScripts\Dev\CreateZeroDeployDatabase.ps1"
	$argumentList = "-serverName " + $server + " -databaseName " + $dbName #+ " -DefaultDataPath " + "D:\DATA\" + " -DefaultLogPath " + "D:\DATA\" 

	Write-Host "$deploymentScript $argumentList"
	$output = Invoke-Expression "$deploymentScript $argumentList" | Out-File $($logpath + $dbName + '.txt')
	if($? -ne $true) {
		echo $output
		throw "FAE Deployment Failed"
	}
}

function DeployOyBO {
	Write-Progress -activity "Deploying OyBO database"
	cd $PSScriptRoot
	$dbName = $autogrationPrefix + "OTFP"
	$deploymentScript = Join-Path -Path $workspaceBasePath "\OyBO\Main\Code\OTFP.DataMigrationScripts\Dev\CreateDatabase.ps1"
	$argumentList = "-serverName " + $server + " -databaseName " + $dbName #+ " -DefaultDataPath " + "D:\DATA\" + " -DefaultLogPath " + "D:\DATA\" 

	Write-Host "$deploymentScript $argumentList"
	$output = Invoke-Expression "$deploymentScript $argumentList" | Out-File $($logpath + $dbName + '.txt')
	if($? -ne $true) {
		echo $output
		throw "OyBO Deployment Failed"
	}
}

function DeployCommonServices {
    DeployXmlControlledDatabase -name "CommonServices" -deploymentScript (Join-Path -Path $workspaceBasePath '\CommonServices\Messaging\MessageBusTracking\Databases\Dev\DevDeployIncrementalUpgrade.ps1')
}

function DeployNotifications {
    DeployXmlControlledDatabase -name "Notifications" -deploymentScript (Join-Path -Path $workspaceBasePath "\Notifications\Main\Code\Notifications\Email Notification\DevDeploy\Deploy.ps1")
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
	$dbName = $autogrationPrefix + "MasterData_EventStore"

	$env:DatabaseName = $dbName
	DropDb -server $server -dbName $dbName
	$baseLineScript = $scriptPath = Join-Path -Path $workspaceBasePath "MasterData\Main\MasterData.InfrastructureServices\DatabaseScripts\EventStore\Events_BaseLine.sql"
	$output = & sqlcmd.exe -S $server -d master -i $baseLineScript | Out-File $($logpath + $dbName + '.txt')
	if($? -ne $true) {
		Write-Host $output
		throw "Deployment of Event store baseline failed"
	}
}

function DeployMasterDataLogging {
	Write-Progress -activity "Deploying Master Data database" -status "Deploying Logging baseline"
	$dbName = $autogrationPrefix + "MasterData_Logging"
	
	Write-Host "        Deploying baseline"
	$env:DatabaseName = $dbName
	DropDb -server $server -dbName $dbName
	$baseLineScript = $scriptPath = Join-Path -Path $workspaceBasePath "MasterData\Main\MasterData.InfrastructureServices\DatabaseScripts\Logging\Elmah_BaseLine.sql"
	$output = & sqlcmd.exe -S $server -d master -i $baseLineScript | Out-File $($logpath + $dbName + '.txt')
	if($? -ne $true) {
		Write-Host $output
		throw "Deployment of Logging baseline failed"
	}	
}

function DeployMasterDataProjections {
	Write-Progress -activity "Deploying Master Data database" -status "Deploying Projections"
	$dbName = $autogrationPrefix + "MasterData_Projections"
	
	$infrastructureDir = Join-Path -Path $workspaceBasePath "MasterData\Main\MasterData.InfrastructureServices"
	$outputDir = Join-Path -Path $infrastructureDir "bin\Debug"
	$efMigrateExe = Join-Path -Path $workspaceBasePath "MasterData\Main\packages\EntityFramework.6.1.1\tools\Migrate.exe"
	$runMigrateExe = Join-Path -Path $outputDir "Migrate.exe"
	
	Write-Host "        Building MasterData.InfrastructureServices"
	cd $infrastructureDir
	$buildOutput = & 'C:\Program Files (x86)\MSBuild\12.0\Bin\MSBuild.exe' /t:build MasterData.InfrastructureServices.csproj | Out-File $($logpath + $dbName + '.txt')
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
	$migrateOutput = & $runMigrateExe MasterData.InfrastructureServices.dll /connectionString="Data Source=$server;Initial Catalog=$dbName; Integrated Security=SSPI" /connectionProviderName="System.Data.SqlClient" | Out-File $($logpath + $dbName + '.txt')
	if($? -ne $true) {
		Write-Host $migrateOutput
		throw "Migration of $dbName failed"
	}
}

function DeployMasterData {
	Write-Progress -activity "Deploying Master Data database"
	RestoreMasterDataProjectionStore
}

function DeploySDM {
    DeployXmlControlledDatabase -name "SDM" -deploymentScript (Join-Path -Path $autogrationPath "SDM\SDM.DB.Scripts\Scripts\Dev\DevDeployIncrementalUpgrade.ps1")
}

function Log {
   [cmdletbinding()]
    param(
        [string]$messageToLog
    )
   
   $logPath = Join-Path -Path $LogDirectory $Logfile

   if (-NOT (Test-Path $LogDirectory)){

        New-Item -Path $LogDirectory -ItemType Directory
   }
   
   $messageToLog = (get-date).ToString() + $messageToLog
   Add-content $logPath -value $messageToLog
}

function RestoreMasterDataProjectionStore {
	$databaseName = $autogrationPrefix + "MasterData_ProjectionStore"
	
	Write-Progress -activity "Starting MasterData Projection Store restore"
	if ($autogrationPath -ne $null -and $autogrationPath -ne "") {
		$backUpPath =  Join-Path -Path $autogrationPath  "\MasterData\DatabaseScripts\MasterData_ProjectionStore.bak"
	}
	else {

		Write-host "Deriving master data projection store backup location"
		Log -messageToLog ("Deriving master data projection store backup location")
		#Work out what the location of the MasterData projection store back up using the expected autogration files path
		$backUpPath = DeriveProjectionStoreBackupPath -masterDataBackupPath "\MasterData\DatabaseScripts\MasterData_ProjectionStore.bak"		
	}
	
	write-host "Backup path used is $backUpPath"
	Log -messageToLog ("Restoring MasterData projection store using " + $backUpPath)
	invoke-sqlcmd -ServerInstance "." -Query "IF EXISTS (SELECT 1 FROM SYS.DATABASES WHERE NAME = 'Autogration_MasterData_ProjectionStore') BEGIN ALTER DATABASE Autogration_MasterData_ProjectionStore SET SINGLE_USER WITH ROLLBACK IMMEDIATE;Drop database Autogration_MasterData_ProjectionStore END"
	RestoreDatabase -databaseName $databaseName -backupPath $backUpPath
	
}

function DeriveProjectionStoreBackupPath{
    [cmdletbinding()]
    param(
        [string]$masterDataBackupPath="\MasterData\DatabaseScripts\MasterData_ProjectionStore.bak"
    )
    $currentPath = (Get-Item -Path ".\" -Verbose).FullName
    $splitPath = $currentPath.split("\")
    $workspacePart = $splitPath[2]

    $isWorkspaceAsExpected = ValidateWorkspaceName $workspacePart
    
    if ($isWorkspaceAsExpected -eq $false){
        $message = "Unable to derive path to the MasterData ProjectionStore back up as workspace" + $workspacePart + " does not match expected pattern "
		Log -messageToLog ("Unable to derive path to the MasterData ProjectionStore back up as workspace")
        throw $message         
    }
    else{
        
        $autogrationRoot = "D:\Autogration\" + $workspacePart
        $masterDataProjectionBackupPath = $autogrationRoot + $masterDataBackupPath
    
        if (!(Test-Path $masterDataProjectionBackupPath )){
            $message = "Unable to find the MasterData ProjectionStore back up file at " + $masterDataProjectionBackupPath 
			Log -messageToLog ("Unable to find the MasterData ProjectionStore back up file at")
            throw $message            
        }
        else{
            write-host "MasterData ProjectionStore backup found at path " $masterDataProjectionBackupPath 
            return $masterDataProjectionBackupPath 
        }
    } 
}

function ValidateWorkspaceName{
    [cmdletbinding()]
    param( 
        [Parameter(Mandatory=$true)]
        [string]$workspaceName
    )
          
    return $workspaceName -match "^ZD[0-6]+"
}

function RestoreDatabase {
[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True)]
		[String]$databaseName,
		[Parameter(Mandatory=$True)]
		[String]$backupPath,
		[String]$sqlInstanceName= "localhost"
	)

	$messageToLog = "Restoring database, name= " + $databaseName + ", path=" + $backupPath + " and instance=" + $sqlInstanceName

    write-host $messageToLog
	Log -messageToLog $messageToLog

    try {
       	
		    			 
		#Load the required assemlies SMO and SmoExtended.
		[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
		[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
 
		# Connect SQL Server.
		$sqlServer = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $sqlInstanceName
		$dbRestore = new-object ("Microsoft.SqlServer.Management.Smo.Restore")				
        $dbRestore.Database = $databaseName
        $dbRestore.Devices.AddDevice($backupPath, "File")
        $dbRestore.ReplaceDatabase = $True

        $DataFiles = $dbRestore.ReadFileList($sqlServer)
                
        ForEach ($DataRow in $DataFiles) {
            $LogicalName = $DataRow.LogicalName
            $RestoreData = New-Object("Microsoft.SqlServer.Management.Smo.RelocateFile")
            $RestoreData.LogicalFileName = $LogicalName

            if ($DataRow.Type -eq "D") {
                # Restore Data file
                $RestoreData.PhysicalFileName = $sqlServer.Information.MasterDBPath + "\" + $dbRestore.Database + ".Data.mdf"
            }
            Else {
                # Restore Log file
                $RestoreData.PhysicalFileName = $sqlServer.Information.MasterDBLogPath + "\" + $dbRestore.Database + "_Log.ldf"
            }
            [Void]$dbRestore.RelocateFiles.Add($RestoreData)
        }
		

        $dbRestore.SqlRestore($sqlServer)
 
		$messageToLog = "...SQL Database $databaseName Successfully Restored"
		Write-host $messageToLog 
		Log -messageToLog $messageToLog
	}
	catch {
		$erroredAt = Get-Date
		$message = [string]::Format("{0} Unable to restore database {1}.", $erroredAt, $databaseName)

		Log -messageToLog $message
		
		$messageToLog = "Exception Message: $($_.Exception)"
		Log -messageToLog $messageToLog	

		write-host $message
        Write-host "Exception Message: $($_.Exception)"
		
		#$host.SetShouldExit($result.ExitCode) 
		#Exit $result.ExitCode
	}
}

function Main {
    #create the directory if doesn't exist
    If (!(Test-Path $logpath)) {
        New-Item -ItemType directory -Path $logpath
    }

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
        elseif ($databaseToDeploy -eq 'Notifications') {
			DeployNotifications
		}
        elseif ($databaseToDeploy -eq 'SDM') {
			DeploySDM
		}
		elseif ($databaseToDeploy -eq 'OyBO') {
			DeployOyBO
		}
		else
		{
			throw "Sorry I don't know how to deploy database $databaseToDeploy"
		}
	}
	
	#TODO: Now run the patch scripts to set up synonyms and PARE schema & sprocs in FAE
}

$script:root = Resolve-Path $(Join-path $workspaceBasePath 'Deployment\Main\ZeroDeployScripts')
Set-Location $root
Import-Module "sqlps" -DisableNameChecking
Invoke-Sqlcmd -InputFile "PreDeployment.sql"
Main
Set-Location $root
Invoke-Sqlcmd -InputFile "PostDeployment.sql"
Invoke-Sqlcmd -InputFile "ClearState.sql"
Set-Location $root
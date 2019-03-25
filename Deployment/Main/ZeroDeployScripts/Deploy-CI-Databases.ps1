#requires -Version 3.0

param 
(
	[array] $databasesToDeploy = @('FAE', 'PARE', 'CACC', 'Notifications', 'SDM', 'OyBO'),

	[string] $autogrationPrefix = "Autogration_", 
	[string] $server = 'localhost',
    [string] $logpath = 'd:\dbdeploy-logs\',
	[string] $deploymentFolder = '..\Code\Deploy\'
)

begin
{
    Import-Module .\SetupZeroDeployFromCI-Functions.psm1 -Force
    Import-Module "sqlps" -DisableNameChecking
}

process
{
    Set-Location $PSScriptRoot
    
    #create the directory if doesn't exist
    If (!(Test-Path $logpath)) 
    {
        New-Item -ItemType directory -Path $logpath
    }

    $zeroDeployPath = (Get-ChildItem Env:ZeroDeployPath).Value

	if($databasesToDeploy -Contains "PARE") 
    {
        $dbName = $autogrationPrefix + "PARE"
        $deploymentScript = Join-Path -Path $zeroDeployPath "\PaRE\Pare.Database\Dev\DevDeployIncrementalUpgrade.ps1"
        $argumentList = "-serverName " + $server + " -databaseName " + $dbName + " -deploymentFolder " + $PSScriptRoot +"\" + $deploymentFolder

        Publish-Database -databaseName $dbName -deploymentScript $deploymentScript -argumentList $argumentList -logPath $logpath
	}

	if($databasesToDeploy -Contains "FAE") 
    {
        $dbName = $autogrationPrefix + "FAE"
    	$deploymentScript = Join-Path -Path $zeroDeployPath "\FAE\FAE.DataMigrationScripts\Dev\CreateZeroDeployDatabase.ps1"
    	$argumentList = "-serverName " + $server + " -databaseName " + $dbName + " -deploymentFolder " + $PSScriptRoot +"\" + $deploymentFolder

    	Publish-Database -databaseName $dbName -deploymentScript $deploymentScript -argumentList $argumentList -logPath $logpath
	}

	if($databasesToDeploy -Contains "OyBO") 
    {
        $dbName = $autogrationPrefix + "OTFP"
    	$deploymentScript = Join-Path -Path $zeroDeployPath "\OyBO\OTFP.DataMigrationScripts\Dev\CreateDatabase.ps1"
    	$argumentList = "-serverName " + $server + " -databaseName " + $dbName + " -deploymentProjectFolder " + $PSScriptRoot +"\" + $deploymentFolder

    	Publish-Database -databaseName $dbName -deploymentScript $deploymentScript -argumentList $argumentList -logPath $logpath
	}

	if($databasesToDeploy -Contains "CACC") 
    {
        $dbName = $autogrationPrefix + "CSCWebSSO"
        $deploymentScript = Join-Path -Path $zeroDeployPath "\cacc\CS.Database.Scripts\Dev\DevDeployIncrementalUpgrade.ps1"
    	$argumentList = "-serverName " + $server + " -configName Configs\ZeroDeployment.xml -DeployFolder " + $PSScriptRoot + "\" + $deploymentFolder

		Publish-Database -databaseName $dbName -deploymentScript $deploymentScript -argumentList $argumentList -logPath $logpath
	}

	if($databasesToDeploy -Contains "Notifications") 
    {
        $dbName = $autogrationPrefix + "NotificationProcessorDb"
        $deploymentScript = Join-Path -Path $PSScriptRoot "\..\..\..\Notifications\Main\Code\Notifications\Email Notification\DevDeploy\Database\DevDeployIncrementalUpgrade.ps1"
        $argumentList = "-serverName " + $server + " -configName Configs\ZeroDeployment.xml -workspacePath " + $PSScriptRoot + "\..\..\.."

        Publish-Database -databaseName $dbName -deploymentScript $deploymentScript -argumentList $argumentList -logPath $logpath
	}
	
    if($databasesToDeploy -Contains "SDM") 
    {
        $dbName = $autogrationPrefix + "SDM"
	    $deploymentScript = Join-Path -Path $zeroDeployPath "\SDM\SDM.DB.Scripts\Scripts\Dev\DevDeployIncrementalUpgrade.ps1"
	    $argumentList = "-serverName " + $server + " -configName Configs\ZeroDeployment.xml -deployFolder " + $PSScriptRoot + "\" + $deploymentFolder

		Publish-Database -databaseName $dbName -deploymentScript $deploymentScript -argumentList $argumentList -logPath $logpath
	}

	if($databasesToDeploy -Contains "MasterData") 
    {
		$dbName = $autogrationPrefix + "MasterData_ProjectionStore"	
		$backupDatabase =  Join-Path -Path $zeroDeployPath "\MasterData\DatabaseScripts\MasterData_ProjectionStore.bak"

		Invoke-Sqlcmd -ServerInstance "." -Query "IF EXISTS (SELECT 1 FROM SYS.DATABASES WHERE NAME = 'Autogration_MasterData_ProjectionStore') BEGIN ALTER DATABASE Autogration_MasterData_ProjectionStore SET SINGLE_USER WITH ROLLBACK IMMEDIATE;Drop database Autogration_MasterData_ProjectionStore END"
		Restore-Database -databaseName $dbName -backupPath $backupDatabase
	}
    
    Set-Location $PSScriptRoot
    Invoke-Sqlcmd -InputFile "PostDeployment.sql"
    Invoke-Sqlcmd -InputFile "ClearState.sql"
    Set-Location $PSScriptRoot
}
[cmdletbinding()]
param(
	[Parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string] $ServerName,
	[Parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string] $DatabaseName,
	[string] $Environment = "TestRig",
	[string] $Config = "TestRig.DBA",
	[string] $IntermediatePatchingFolder,
	[string] $DropFolder,
	[int] $LoopCount = 2,
	[switch] $IntermediatePatchingFolderInclude,
	[switch] $NoDropDatabase
)

#if we have passed in a DropFolder, then we will be copying parameters relative to that,
#otherwise it will be relative to local db deployment module. This handles this situation
$scriptPath = $PSScriptRoot
$solutionPath = $DropFolder #can be null

#For patching work we need access to local Parameters.  This will mean teams still need a local mapped copy of deployment parameters
#this needs to be passed into args below, to allow module to copy parameters locally (process uses local, relative parameters path to work)
$parameterFiles = @((Join-Path $scriptPath "$Config.Parameters.xml"))
Initialize-Parameters -ParameterFiles $parameterFiles -RootPath $solutionPath

#Set your parameters according to your local needs and requirements.
#You can do three types of deployment, Baseline, PatchScript or PatchingFolder. Below is an example of all three.

$createFunc = {
	$retVal = 0
    if (!$NoDropDatabase) {

        $retVal = Remove-Database -DataSource $ServerName -Database $DatabaseName
        if ($retVal -ne 0) {
            Write-Host2 -Type Failure -Message "Failed to drop database $DatabaseName from $ServerName"
            return 1
        }

        Write-Host2 -Type Success -Message "Successfully dropped database $DatabaseName, or it did not exist."

        $retVal = New-Database -DataSource $ServerName -Database $DatabaseName

        if ($retVal -ne 0) {
            Write-Host2 -Type Failure -Message "Failed to create database $DatabaseName from $ServerName"
            return 1
        }

        Write-Host2 -Type Success -Message "Successfully recreated database (in simple recovery): $DatabaseName on $ServerName"

		$DevDbLogin = Join-Path $scriptPath "DevDbLogin.sql"

		Write-Host "Create Dev Database Logins and Users"
		$retVal = Invoke-SqlCmdRunScript -ScriptToRun $DevDbLogin -TargetDatabase $DatabaseName -Datasource $ServerName
    }

	$retVal
}

$params = @{
	ServerName = $ServerName
	DatabaseName = $DatabaseName
	Environment = $Environment
	Config = $Config
    DropFolder= $DropFolder
    SqlScriptToRunSuffix = $DatabaseName
    IntermediatePatchingFolder = $IntermediatePatchingFolder
	IntermediatePatchingFolderInclude = $IntermediatePatchingFolderInclude
}



#If we have passed in drop folder, then we make use of that, and use relative path for patch folder.
#Otherwise we need to fully qualify the patch folder path. This will be determined relative to where this script
#is executing from.

if (!$solutionPath) {
    $solutionPath = Split-Path (Split-Path $scriptPath)
    
}

$patches = @(
	$createFunc
	{Invoke-LocalDatabaseDeployment @params -PatchScript "DeploymentSchema.Scripts\Patching\DeploymentSchema.Patching.sql" -Role "Deployment Schema Patching"}
	{Invoke-LocalDatabaseDeployment @params -PatchFolder (Join-Path $localDbFolder "Common\Patching\") -Role "FAE Common Patching"}
	{Invoke-LocalDatabaseDeployment @params -PatchFolder (Join-Path $solutionPath "FAE_Config.DataMigrationScripts\Common\Patching\") -Role "FAE Config Patching"}
	{Invoke-LocalDatabaseDeployment @params -PatchFolder (Join-Path $localDbFolder "Config\Patching\") -Role "FAE Specific Config Patching"}
	{Invoke-LocalDatabaseDeployment @params -PatchFolder (Join-Path $localDbFolder "RSP\Patching\") -Role "FAE Specific Config Patching"}
	#{Invoke-LocalDatabaseDeployment @params -PatchFolder (Join-Path $localDbFolder "Functional\Patching\") -Role "FAE Functional Patching"}
	{Invoke-LocalDatabaseDeployment @params -PatchFolder (Join-Path $localDbFolder "RSPFunctional\Patching\") -Role "FAE Functional Patching"}
	{Invoke-LocalDatabaseDeployment @params -PatchFolder (Join-Path $localDbFolder "DevOnly\Patching\") -Role "FAE Dev Patching"}
	{Invoke-LocalDatabaseDeployment @params -PatchFolder "Partitioning.Database\Scripts\Patching" -Role "DBA Common Partitioning"}
	{Invoke-LocalDatabaseDeployment @params -PatchFolder (Join-Path $localDbFolder "PartitioningArtefacts\Scripts\Patching") -Role "FAE Partitioning"}
	{Invoke-LocalDatabaseDeployment @params -PatchFolder (Join-Path $localDbFolder "TestPartitionConfig\Patching") -Role "FAE Test Partitioning"}
)

Invoke-UntilFail $patches
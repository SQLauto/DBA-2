[cmdletbinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $ServerName = 'localhost' ,
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$DatabaseName,
    [string]$DropFolder,
    [string] $Environment = "DbaSurveillance",
    [string] $Config = "DbaSurveillance.DB",
	[Parameter()]
	[ValidateSet("c","create","u","update", "d","delete")]
	[string] $Action ,
	[switch]$NoDropRunFile
)

#DO NOT CHANGE OR EDIT ANY OF THE FUNCTIONS OF THE SCRIPT UNTIL THE NEXT UPPCASE COMMENTS.

#if we have passed in a DropFolder, then we will be copying parameters relative to that,
#otherwise it will be relative to local db deployment module. This handles this situation
#in the case of FAE, they parameters are already in the correct location for nightly builds, so not need to copy params.
$scriptPath = $PSScriptRoot #This is the folder where we are executing
$solutionPath = $DropFolder #can be null

switch -Regex ($Action) {
    "^c(reate?)?$" {Write-Host "Starting deployment of $DatabaseName"; $Action = 'c'}
    "^u(update?)?$" {Write-Host "Starting update of $DatabaseName"; $Action = 'u'}
    "^d(elete?)?$" {Write-Host "Starting deletion of $DatabaseName"; $Action = 'd'}
	default {Write-Host2 -Type Failure -Message "Invalid Action parameter was passed."; return 1} #should never happen
}

$DataSource = $ServerName
$ServerName = $DataSource.Split("\")[0]
$InstanceName = $DataSource.Split("\")[1]


$dropFunc = {
    $retVal = 0

    $retVal = Remove-Database -DataSource $DataSource -Database $DatabaseName
    if ($retVal -ne 0) {
        Write-Host2 -Type Failure -Message "Failed to drop database $DatabaseName from $DataSource"
        return 1
    }

    Write-Host2 -Type Success -Message "Successfully dropped database $DatabaseName, or it did not exist."

    $retVal
}

if ($Action -eq 'd') {
    return & $dropFunc
}

#the override TestRig parameters are found in FAE.DataMigrationScripts folder. They are copied to the deployment folder
#overriding the TestRig parameters already there. Has less parameters, and some changes for local deployments etc.
#Our source for parameters then has to come from that folder.
$parameterFiles = @((Join-Path $scriptPath "$Config.Parameters.xml"))

Initialize-Parameters -ParameterFiles $parameterFiles -RootPath $solutionPath

$params = @{
	ServerName = $ServerName
	Instancename = $InstanceName
	DatabaseName = $DatabaseName
	Environment = $Environment
	Config = $Config
    DropFolder= $DropFolder
	NoDropRunFile = $NoDropRunFile
}

$localDbFolder = Split-Path (Split-Path $scriptPath) -Leaf #Get name of our current DB scripts folder, e.g Disruptr.DataMigrationScripts

#If we have passed in drop folder, then we make use of that, and use relative path for patch folder.
#Otherwise we need to fully qualify the patch folder path. This will be determined relative to where this script
#is executing from.
if (!$solutionPath) {
    $solutionPath = Split-Path (Split-Path $scriptPath) #go up two folders
	$localDbFolder = Join-Path $solutionPath $localDbFolder
}

# Drop DB if it already exists and is not devint
$createFunc = {

	$retVal = 0
    if ($Action -eq 'c') {

        $retVal = & $dropFunc

        if ($retVal -ne 0){
			return $retVal
		}

        $retVal = New-Database -DataSource $DataSource -Database $DatabaseName

        if ($retVal -ne 0) {
            Write-Host2 -Type Failure -Message "Failed to create database $DatabaseName from $ServerName"
            return 1
        }

        Write-Host2 -Type Success -Message "Successfully recreated database (in simple recovery): $DatabaseName on $ServerName"

        $retVal = Invoke-LocalDatabaseDeployment @params -PatchScript (Join-Path $localDbFolder "BaseLine\baseline.sql") -Role "$DatabaseName Baseline Database"
    }

	$retVal
}

$patches = @(
	$createFunc
	
	{Invoke-LocalDatabaseDeployment @params -PatchScript "DeploymentSchema.Scripts\Patching\DeploymentSchema.Patching.sql" -Role "Deployment Schema Patching"}
	{Invoke-LocalDatabaseDeployment @params -PatchFolder (Join-Path $localDbFolder "Common\Patching") -Role "$DatabaseName Common Patching"}
	{Invoke-LocalDatabaseDeployment @params -PatchFolder (Join-Path $localDbFolder "DevOnly\Patching") -Role "$DatabaseName Devonly Patching"}
	{Invoke-LocalDatabaseDeployment @params -PatchFolder "Partitioning.Database\Scripts\Patching" -Role "DBA Common Partitioning"}
	
	{Invoke-LocalDatabaseDeployment @params -PatchFolder (Join-Path $localDbFolder "PartitioningArtefacts\Scripts\Patching") -Role "DbaSurveillance Partitioning"}
	
)

Invoke-UntilFail $patches
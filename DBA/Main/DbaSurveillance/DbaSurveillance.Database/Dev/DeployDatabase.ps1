[cmdletbinding()]
param(
	[string] $serverName =  $(throw "Please specify a serverName."),
	[string] $databaseName = $(throw "Please specify a database."),
	[string] $InstanceName = $null,
	[string] $Environment = "TestRig",
	[string] $IntermediatePatchingFolder = $null,
	[bool] $IntermediatePatchingFolderInclude = $False,
	[bool] $DropDatabase = $True,
	[int] $loopCount = 2,
	[string] $DropFolder 
)


function Install-RequiredModule{
 [Cmdletbinding()]
 param(
    [Parameter(Mandatory=$true)]
    [string]$Name,
    [string]$Repository = "FTPNuget",
    [ValidateSet('CurrentUser', 'AllUsers')]
    [string]$Scope = 'CurrentUser'
 )
    $module = Get-InstalledModule -Name $Name -ErrorAction Ignore

    if($module) {
	    Find-Module -Name $Name  -Repository $Repository | Update-Module -ErrorAction Continue
    }
    else{
        Find-Module -Name $Name  -Repository $Repository | Install-Module -Scope $Scope
    }
}
function Invoke-FolderPatching {
    [Cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $folderPath
    )

    $params = @{
	PatchFolder = $folderPath
	Config = "TestRig.BaselineData"
	ServerName = $serverName
	DatabaseName = $databaseName
    InstanceName = $InstanceName
	Environment = "TestRig"
	UpgradeScript = "Patching.sql" #This is optional, if not set defaults to Patching.sql
	PatchFolderFormat = "B???_R????_" #This is optional, if not set defaults to "B???_R????_"
	PreValidationScript = "PreValidation.sql" #This is optional, if not set defaults to PreValidation.sql
	PostValidationScript = "PostValidation.sql" #This is optional, if not set defaults to PostValidation.sql
	PatchLevelDeterminationScript = "DetermineIfDatabaseIsAtThisPatchLevel.sql" #This is optional, if not set defaults to DetermineIfDatabaseIsAtThisPatchLevel.sql
    }

    if($result -eq 0) {
		$result = Invoke-LocalDatabaseDeployment @params
	}
	
	if ($result -ne 0) {
		Write-Error2 -ErrorRecord $_
        $Script:exitCode = 1
        exit
	}
}
function Invoke-ScriptPatching {
    [Cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $scriptFilePath
        )

    $params = @{
	PatchScript = $scriptFilePath
	Config = "TestRig.BaselineData"
	ServerName = $serverName
	DatabaseName = $databaseName
    InstanceName = $InstanceName
	Environment = "TestRig"
	DropDatabase = $false
	NoCreate = $true 
    }

    if($result -eq 0) {
		$result = Invoke-LocalDatabaseDeployment @params
	}
	
	if ($result -ne 0) {
		Write-Error2 -ErrorRecord $_
        $Script:exitCode = 1
        exit
	} 
}



Import-Module PackageManagement -Verbose

#Next, install the local dev db deployment module. This contains all components and scripts necessary to begin a local DB deployment
#this will in turn load other dependent modules and scripts, which the callee does not need to know about.

#Install-RequiredModule -Name "TFL.Deployment.Database"
#Install-RequiredModule -Name "TFL.Deployment.Database.Local"
#Install-RequiredModule -Name "TFL.PowerShell.Logging"

#Import relevant modules
Import-Module TFL.Deployment.Database -Force
Import-Module TFL.Deployment.Database.Local -Force
Import-Module TFL.PowerShell.Logging -Force
$loggingModule =""

$scriptpath = split-path $MyInvocation.MyCommand.Path
$dropAndRecreateModule = Join-Path $scriptPath "DropAndRecreateDatabase.ps1"


$dropFolder=[System.IO.Path]::Combine( $scriptpath, "..\..\..\..\");
#$powershellModulePath = [System.IO.Path]::Combine($dropFolder, "Deployment\Main\Code\Deploy\Scripts\Modules");
#$deploymentModule = [System.IO.Path]::Combine($powershellModulePath, "TFL.Deployment\TFL.Deployment.psm1");
#$databaseModule = [System.IO.Path]::Combine($powershellModulePath, "TFL.Deployment.Database\TFL.Deployment.Database.psm1");
#$databaseLocalModule = [System.IO.Path]::Combine($powershellModulePath, "TFL.Deployment.Database.Local\TFL.Deployment.Database.Local.psm1");


#Import-Module -Name $deploymentModule -Force -Verbose
#Import-Module -Name $databaseModule -Force -Verbose
#Import-Module -Name $databaseLocalModule -Force -Verbose



Import-Module -Name $dropAndRecreateModule -Force

if([string]::IsNullOrEmpty($InstanceName))
{
    $dataSource =  $serverName
}
else
{
	$dataSource =  $serverName +"\"+$InstanceName
}


if ($DropDatabase)
{
	$exitCode = DropAndRecreateDatabase -dataSource $dataSource -database $databaseName
	if ($exitCode -ne 0)
	{
		Write-Error2 "The database drop and recreate function failed"
		exit 1
	}
	else
	{
		Write-Host ("Successfully recreated database (in simple recovery): {0}" -f $databaseName)
	}

	
}

Remove-Module "DropAndRecreateDatabase"



#For patching work we need access to local Parameters.  This will mean teams still need a local mapped copy of deployment parameters
#this needs to be passed into args below, to allow module to copy parameters locally (process uses local, relative parameters path to work)

$parameterFiles = @((Join-Path $scriptPath "TestRig.BaselineData.Parameters.xml"), (Join-Path $scriptPath "TestRig.BaselineData.Global.Parameters.xml"))

Initialize-Parameters -ParameterFiles $parameterFiles

#Set your parameters according to your local needs and requirements.
#You can do three types of deployment, Baseline, PatchScript or PatchingFolder. Below is an example of all three.

$result = 0

###############
#Deployment Schema PatchScript - Normally always need to create deployment schema.
###############

$params = @{
	PatchScript = "DeploymentSchema.Scripts\Patching\DeploymentSchema.Patching.sql"
	Config = "TestRig.BaselineData"
	ServerName = $serverName
    InstanceName = $InstanceName
	DatabaseName =$databaseName
	Environment = $Environment
	SqlScriptToRunSuffix = $databaseName
	DropFolder = $DropFolder
}

try{
	if($result -eq 0) {
		$result = Invoke-LocalDatabaseDeployment @params #This is called splatting, and is a nicer/easier way to pass multiple parameters to a function etc.
	}
}
catch{
	Write-Error2 -ErrorRecord $_
	throw
}

###################
#Patching Folder - If using patching folders.
##################


if($result -eq 0) {
	$result_baseline = Invoke-ScriptPatching -scriptFilePath (Join-Path $scriptPath "..\Baseline\baselinedataR68.sql")
}

Write-Host (Join-Path $scriptPath "..\Common\Patching\")
Write-Host ("xxx:"+$result)

if($result -eq 0) {
	$result = Invoke-FolderPatching  -folderPath (Join-Path $scriptPath "..\Common\Patching\")
}

$result
[cmdletbinding()]
param(
	[string] $ServerName =  $(throw "Please specify a serverName."),
	[string] $DatabaseName = $(throw "Please specify a database."),
	[string] $InstanceName = $null,
	[string] $Environment = "TestRig",
	[string] $IntermediatePatchingFolder = $null,
	[bool] $IntermediatePatchingFolderInclude = $False,
	[bool] $DropDatabase = $False,
	[int] $loopCount = 2,
	[string] $DropFolder,
    [string] $InstallModules = $true
)

$scriptpath = split-path $MyInvocation.MyCommand.Path
#DO NOT CHANGE OR EDIT ANY OF THE PARTS OF THE SCRIPT UNTIL THE NEXT UPPCASE COMMENTS.
function Install-PSRepository {
 [Cmdletbinding()]
 param(
    [Parameter(Mandatory=$true)]
    [string]$Name,
    [Parameter(Mandatory=$true)]
    [string]$SourceLocation,
    [ValidateSet('Trusted', 'Untrusted')]
    [string]$InstallationPolicy = 'Trusted'
)

    $repo = Get-PSRepository -ErrorAction SilentlyContinue | Where-Object {$_.SourceLocation -like $SourceLocation}

    if($repo) {
        $Name = $repo.Name
    }

    Unregister-PSRepository -Name $Name -ErrorAction SilentlyContinue
    Register-PSRepository -Name $Name -PackageManagementProvider Nuget -SourceLocation $SourceLocation -InstallationPolicy Trusted

    $Name
}

function Install-PackageManagement{
 [Cmdletbinding()]
 param(
 )
	#the first two lines below are necessary to allow access through the proxy
	$wc = new-object system.net.webclient
	$wc.proxy.credentials = [system.net.credentialcache]::defaultnetworkcredentials
	##Test invocation
	#Invoke-Webrequest https://www.powershellgallery.com/api/v2/ -UseDefaultCredentials | Out-Null

	#This will install PowerShellGet and PackageManagement modules (currently 1.6 and 1.1.7.0 respectively)
	Install-Module -Name PowerShellGet -Force -RequiredVersion 1.6.0.0
}

function Install-InternalPackageProvider {
 [Cmdletbinding()]
 param()

    #the first two lines below are necessary to allow access through the proxy
	$wc = new-object system.net.webclient
	$wc.proxy.credentials = [system.net.credentialcache]::defaultnetworkcredentials
	##Test invocation
	#Invoke-Webrequest https://www.powershellgallery.com/api/v2/ -UseDefaultCredentials | Out-Null

	$nuget = Get-PackageProvider -Name nuget -Force -ForceBootstrap -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1
    $version = '2.8.5.208'
    if(-not $nuget -or $nuget.Version -lt [version]::Parse($version)) {
        Install-PackageProvider -Name Nuget -MinimumVersion $version -force -verbose -ForceBootstrap -Scope CurrentUser -Confirm:$False
    }

    Import-PackageProvider -Name Nuget -MinimumVersion $version -Force -ForceBootstrap
}

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
	    Find-Module -Name $Name  -Repository $Repository | Update-Module -Force -ErrorAction Continue
    }
    else{
        Find-Module -Name $Name  -Repository $Repository | Install-Module -Scope $Scope
    }
}

Install-PackageManagement

Import-Module PackageManagement

#First Register PSNuget repo if not already set
Install-InternalPackageProvider
Install-PSRepository -Name "FTPNuget" -SourceLocation "http://nugetftp.fae.tfl.local:1030/api/v2"

#Next, install the local dev db deployment module. This contains all components and scripts necessary to begin a local DB deployment
#this will in turn load other dependent modules and scripts, which the callee does not need to know about.


Install-RequiredModule -Name "TFL.Deployment.Database"
Install-RequiredModule -Name "TFL.Deployment.Database.Local"
Install-RequiredModule -Name "TFL.PowerShell.Logging"

#Import relevant modules
Import-Module TFL.PowerShell.Logging -Force
Import-Module TFL.Deployment.Database -Force
Import-Module TFL.Deployment.Database.Local -Force

#FROM THIS POINT HERE, USERS ARE ALLOWED TO MAKE CHANGES ACCORDING TO THEIR SPECIFIC NEEDS.  ADJUST PARAMETERS AND SECTIONS BELOW AS REQUIRED.
#USERS WILL PROBABLY ALWAYS NEED TO DEPLOY THE DEPLOYMENT SCHEMA AND A BASELINE SCRIPT, AND MOST OF THE TIME IT WILL USE THE PATCHING FOLDER MECHANISM


$dropAndRecreateModule = Join-Path $scriptPath "DropAndRecreateDatabase.ps1"

Import-Module -Name $dropAndRecreateModule -Force

if ($DropDatabase)
{
	$DataSource = $ServerName
	if ($InstanceName)
	{
		$DataSource = "$ServerName\$InstanceName"
	}
	$exitCode = DropAndRecreateDatabase -dataSource $DataSource -database $databaseName 
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
#this needs to be passed into arguments below, to allow module to copy parameters locally (process uses local, relative parameters path to work)

#IMPORTANT NOTE: The name of your local parameters file must match that of the config you use, e.g. TestRig.Pare.Parameters.xml

#IMPORTANT NOTE: The parameters system works on the basis of having global parameters. These are not currently set apart from Baseline as shown below but you will need to set up a dummy local
#file for this to work. The global file should be based on the config you set e.g. TestRig.Pare.Global.Parameters.xml This should be an empty definition, e.g .

	#<?xml version="1.0" encoding="utf-8"?>
	#<parameters xmlns="http://tfl.gov.uk/DeploymentConfig" />

$parameterFiles = @("D:\src\DBA_main\DBA\Main\Baseline.Database\Dev\TestRig.DBA.Global.Parameters.xml","D:\src\DBA_main\DBA\Main\Baseline.Database\Dev\TestRig.DBA.Global.Parameters.xml")

Initialize-Parameters -ParameterFiles $parameterFiles

#Set your parameters according to your local needs and requirements.
#You can do three types of deployment, Baseline, PatchScript or PatchingFolder. Below is an example of all three.




$result = 0
###############
#Deployment Schema PatchScript - Normally always need to create deployment schema.
###############

Write-Host ("###################### Deployment Schema #############################")
$params = @{
	PatchScript = "DeploymentSchema.Scripts\Patching\DeploymentSchema.Patching.sql"
	Config = "TestRig.DBA"
	ServerName = $ServerName
	DatabaseName =$DatabaseName
	InstanceName = $InstanceName
	Environment = $Environment
	SqlScriptToRunSuffix = $DatabaseName
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

function ExecutePatchFolder {
 [Cmdletbinding()]

    param(
        [Parameter(Mandatory=$true)]
        [string]$PatchFolderName
    )

    $params = @{
	PatchFolder = $PatchFolderName
	Config = "TestRig.DBA"
	ServerName = $ServerName
	DatabaseName = $DatabaseName
	InstanceName = $InstanceName
	Environment = $Environment
	SqlScriptToRunSuffix = $DatabaseName
	DropFolder = $DropFolder

	IntermediatePatchingFolder = $IntermediatePatchingFolder
	IntermediatePatchingFolderInclude = $IntermediatePatchingFolderInclude
    }

    try{
	    Write-Host "Running script now."
		$result1 = Invoke-LocalDatabaseDeployment @params #This is called splatting, and is a nicer/easier way to pass multiple parameters to a function etc.
    }
    catch{
	    Write-Error2 -ErrorRecord $_
		throw
    }
	$result1;
}

Write-Host ("###################### Common Database Role #############################")
if($result -eq 0) {
	$result = ExecutePatchFolder -PatchFolderName (Join-Path $scriptPath "..\Common\Patching\")
}

$result

##Remove-Module TFL.PowerShell.Logging -ErrorAction Ignore
##Remove-Module TFL.Deployment.Database.Local -ErrorAction Ignore
##Remove-Module TFL.Deployment.Database -ErrorAction Ignore

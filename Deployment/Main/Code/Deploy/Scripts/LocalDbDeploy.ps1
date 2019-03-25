[cmdletbinding()]
param()
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

function Install-InternalPackageProvider {
 [Cmdletbinding()]
 param()

    $nuget = Get-PackageProvider -Name nuget -Force -ForceBootstrap -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1
    $version = '2.8.5.201'
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

Import-Module PackageManagement -Verbose

#First Register PSNuget repo if not already set
Install-InternalPackageProvider
#Install-PSRepository -Name "FTPNuget Gallery" -SourceLocation "http://nugetftp.fae.tfl.local:1030/api/v2"
Install-PSRepository -Name "FTPNuget Server" -SourceLocation "http://nugetftp.fae.tfl.local:7123/nuget"

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

#For patchting work we need access to local Parameters.  This will mean teams still need a local mapped copy of deployment parameters
#this needs to be passed into args below, to allow module to copy parameters locally (process uses local, relative parameters path to work)

$parameterFiles = @("D:\src\Deployment\DevOps\Code\Deploy\Parameters\Baseline.DB.Parameters.xml","D:\src\Deployment\DevOps\Code\Deploy\Parameters\Baseline.Apps.Parameters.xml", "D:\src\Deployment\DevOps\Code\Deploy\Parameters\Baseline.Global.parameters.xml")

Initialize-Parameters -ParameterFiles $parameterFiles

#Set your parameters according to your local needs and requirements.
#You can do three types of deployment, Baseline, PatchScript or PatchingFolder. Below is an example of all three.

###############
#Baseline - To create and/or setup an initial DB. The Local.DB module can create a DB if your script does not do so. Look at params below.
###############

$result = 0

$params = @{
	#BaselineScript = "[Your Path Here]\Baseline.sql" #etc.
	BaselineScript = "D:\Src\Deployment\DevOps\Code\DeploymentBaseline\SimpleDB.Scripts\Baseline\Baseline.sql"
	Config = "Baseline"
	#Config = "TestRig.Pare"
	ServerName = "TDC2SQL005"
	DatabaseName ="SimpleDb"
	Environment = "Baseline"
	#Environment = "TestRig"
	DropDatabase = $true #Only Set this if you wish to drop DB first, which you would in a baseline.
	NoCreate = $true #Set this if you don't want the local module to auto-create the DB. If you are doing this is script you won't want this.
}

try{
	if($result -eq 0) {
		$result = Invoke-LocalDatabaseDeployment @params #This is called splatting, and is a nicer/easier way to pass multiple parameters to a function etc.
	}
}
catch{
	Write-Error2 -ErrorRecord $_
}

###############
#Deployment Schema PatchScript - Normally always need to create deployment schema.
###############

$params = @{
	#PatchScript = "[Your Path Here]\Patching.sql"
	PatchScript = "DeploymentSchema.Scripts\Patching\DeploymentSchema.Patching.sql"
	Config = "Baseline"
	ServerName = "TDC2SQL005"
	DatabaseName ="SimpleDb"
	Environment = "Baseline"
}

try{
	if($result -eq 0) {
		$result = Invoke-LocalDatabaseDeployment @params #This is called splatting, and is a nicer/easier way to pass multiple parameters to a function etc.
	}
}
catch{
	Write-Error2 -ErrorRecord $_
}

################
##PatchScript - If using a Patch script
################

$params = @{
	#PatchScript = "[Your Path Here]\Patching.sql"
	Config = "Baseline"
	ServerName = "TDC2SQL005"
	DatabaseName ="SimpleDb"
	Environment = "Baseline"
}

try{
	if($result -eq 0) {
		$result = Invoke-LocalDatabaseDeployment @params #This is called splatting, and is a nicer/easier way to pass multiple parameters to a function etc.
	}
}
catch{
	Write-Error2 -ErrorRecord $_
}

###################
#Patching Folder - If using patching folders.
##################

$params = @{
	PatchFolder = "D:\Src\Deployment\DevOps\Code\DeploymentBaseline\SimpleDB.Scripts\Patching\"
	#PatchFolder = "[Your Path Here]\SimpleDB.Scripts\Patching\"
	Config = "Baseline"
	ServerName = "TDC2SQL005"
	DatabaseName ="SimpleDb"
	Environment = "Baseline"
	UpgradeScript = "Patching.sql" #This is optional, if not set defaults to Patching.sql
	PatchFolderFormat = "B???_R????_" #This is optional, if not set defaults to "B???_R????_"
	PreValidationScript = "PreValidation.sql" #This is optional, if not set defaults to PreValidation.sql
	PostValidationScript = "PostValidation.sql" #This is optional, if not set defaults to PostValidation.sql
	PatchLevelDeterminationScript = "DetermineIfDatabaseIsAtThisPatchLevel.sql" #This is optional, if not set defaults to DetermineIfDatabaseIsAtThisPatchLevel.sql
}

try{
	Write-Host "Running script now."
	if($result -eq 0) {
		$result = Invoke-LocalDatabaseDeployment @params #This is called splatting, and is a nicer/easier way to pass multiple parameters to a function etc.
	}
}
catch{
	Write-Error2 -ErrorRecord $_
}

Remove-Module TFL.PowerShell.Logging -ErrorAction Ignore
Remove-Module TFL.Deployment.Database.Local -ErrorAction Ignore
Remove-Module TFL.Deployment.Database -ErrorAction Ignore
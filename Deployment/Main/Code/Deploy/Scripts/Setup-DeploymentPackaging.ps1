<#
.SYNOPSIS
	Initialises the Deployment packaging
.PARAMETER DeploymentConfig
    The name of the deployment configuration file used to drive the deployment.
.PARAMETER DeploymentAccount
    The name of the ServiceAccounts lookup name used to run the deployment of the package.
.PARAMETER DropFolder
    The name of the folder containing the built code artefacts.
.PARAMETER PackageName
    The name of the package to generate.
.PARAMETER Groups
    List of (Optional) groups used to filter the generated package.
.PARAMETER Machines
    List of (Optional) servers used to filter the generated package.
#>
[cmdletbinding()]
param
(
	[parameter(Mandatory=$true)]
	[alias("Config")]
	[alias("Configuration")]
	[string]$DeploymentConfig,
	[string]$DeploymentAccount,
	[parameter(Mandatory=$true)]
	[alias("BuildLocation")]
	[string]$DropFolder , #BuildLocation
	[parameter(Mandatory=$true)]
	[string]$PackageName,
	[parameter(Mandatory=$true)]
	[alias("ServiceAccountsPassword")]
	[string]$Password,
	[string]$Groups,
	[alias("Servers")]
	[string]$Machines,
	[switch]$GenerateManifest,
	[switch]$IsDatabaseDeployment
)

if($PSVersionTable.PSVersion.Major -lt 5) {
	Write-Error "You need to be running powershell 5 as a minimum to run this deployment"
	return 1
}

$modulePath = Join-Path $PSScriptRoot "Modules"

[Environment]::SetEnvironmentVariable("PSModulePath",  [Environment]::GetEnvironmentVariable("PSModulePath","Machine"))
$env:PSModulePath = "$modulePath;" + $env:PSModulePath

Import-Module TFL.PowerShell.Logging -Force -ErrorAction Stop
Import-Module TFL.Utilities -Force -ErrorAction Stop
Import-Module TFL.Deployment -Force -ErrorAction Stop

function ConvertTo-ArrayArgument{
param([string]$Source, [string]$Argument)
	$value = (![string]::IsNullOrWhiteSpace($Source)) | Get-ConditionalValue -TrueValue {$temp = $Source -split ","; " $Argument @('{0}')" -f ($temp -join "','")} -FalseValue ""
	$value
}

function Invoke-DeploymentPackaging{

	$retVal	= 0

	$deployParams = @{
		Configuration = $DeploymentConfig
		ServiceAccountsPassword = $ServiceAccountsPassword
		BuildLocation = $DropFolder
		DeploymentAccount = $DeploymentAccount
		PackageName = $PackageName
		IsDatabaseDeployment = $IsDatabaseDeployment
	}

	if($Groups){
		$deployParams.Groups = $Groups -split ","
	}

	if($Machines){
		$deployParams.Servers = $Machines -split ","
	}

	$result = Start-PackageDeployment @deployParams

	if($result)	{
		Write-Host2 -Type Success -Message "Packaging deployment against configuration $DeploymentConfig passed."
	}
	else{
		Write-Host2 -Type Failure -Message "Packaging deployment against configuration $DeploymentConfig failed."
		$retVal = 1
	}

	$retVal
}

$exitCode = 0

try{
	$exitCode = Invoke-DeploymentPackaging
}
catch{
	Write-Error2 -ErrorRecord $_
	$exitCode = 1
}

Remove-Module TFL.Deployment -ErrorAction Ignore
Remove-Module TFL.PowerShell.Logging -ErrorAction Ignore
Remove-Module TFL.Utilites -ErrorAction Ignore

$exitCode
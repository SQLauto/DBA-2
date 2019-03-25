<#
.SYNOPSIS
	Initialises the Deployment on a vCloud vApp
.PARAMETER DeploymentConfig
    The name of the deployment configuration file used to drive the deployment.
.PARAMETER Password
    The password used to decrypt service account info.
.PARAMETER DropFolder
    The name of the folder containing the built code artefacts.
.PARAMETER RigName
    The name of the the rig used when carrying out a rig deployment.
.PARAMETER PackageName
    The name of the package used when carrying out a rig deployment.
.PARAMETER DeploymentAccountName
    The name of the credential set as stored in the Service Accounts file of the account the deployment is performed with.
.PARAMETER Groups
    Comma separated list of Group names to restrict the deployment to a sub-set of roles.
.PARAMETER Machines
    Comma separated list of Server names to restrict the deployment to a sub-set of machines.
#>
param
(
	[parameter(Mandatory=$true)]
	[alias("Config")]
	[alias("Configuration")]
	[string]$DeploymentConfig,
	[parameter(Mandatory=$true)]
	[alias("ServiceAccountsPassword")]
	[string]$Password, # accounts decryption key
	[parameter(Mandatory=$true)]
	[alias("BuildLocation")]
	[string]$DropFolder, #BuildLocation
	[string]$Groups,
	[alias("Servers")]
	[string]$Machines
)

if($PSVersionTable.PSVersion.Major -lt 5) {
	Write-Error "You need to be running powershell 5 as a minimum to run this deployment"
	return 1
}

$modulePath = Join-Path $PSScriptRoot "Modules"

[Environment]::SetEnvironmentVariable("PSModulePath",  [Environment]::GetEnvironmentVariable("PSModulePath","Machine"))
$env:PSModulePath = "$modulePath;" + $env:PSModulePath

#Run in local session, as it means we don't get issues unloading binary modules if things go wrong/builds are cancelled etc.
#Enter-PSSession localhost

Import-Module TFL.PowerShell.Logging -Force -ErrorAction Stop
Import-Module TFL.Utilities -Force -ErrorAction Stop
Import-Module TFL.Deployment -Force -ErrorAction Stop

function ConvertTo-ArrayArgument{
param([string]$Source, [string]$Argument)
	$value = (![string]::IsNullOrWhiteSpace($Source)) | Get-ConditionalValue -TrueValue {$temp = $Source -split ","; " $Argument @('{0}')" -f ($temp -join "','")} -FalseValue ""
	$value
}

function Invoke-PreDeployValidation{

	$retVal	= 0

	$deployParams = @{
		Configuration = $DeploymentConfig
		ServiceAccountsPassword = $Password
		BuildLocation = $DropFolder
	}

	if($Groups){
		$deployParams.Groups = $Groups -split ","
	}

	if($Machines){
		$deployParams.Servers = $Machines -split ","
	}

	$result = Start-PreDeploymentValidation @deployParams

	if($result)	{
		Write-Host2 -Type Success -Message "Pre-Validation against configuration $DeploymentConfig passed."
	}
	else{
		Write-Host2 -Type Failure -Message "Pre-Validation against configuration $DeploymentConfig failed."
		$retVal = 1
	}

	$retVal
}

try{
	$exitCode = Invoke-PreDeployValidation
}
catch{
	Write-Error2 -ErrorRecord $_
	$exitCode = 1
}
finally{
	Remove-Module TFL.Deployment -ErrorAction Ignore
	Remove-Module TFL.PowerShell.Logging -ErrorAction Ignore
	Remove-Module TFL.Utilites -ErrorAction Ignore
	#Exit-PSSession -ErrorAction Ignore
}

$exitCode
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
    The name of the deployment partition used if doing blue/green deployments. Acts as a sub-set of machines
#>
param
(
	[parameter(Mandatory=$true)]
	[alias("Config")]
	[alias("Configuration")]
	[string]$DeploymentConfig,
	[parameter(Mandatory=$true)]
	[string]$EnvironmentType,
	[parameter(Mandatory=$true)]
	[string]$RigName,
	[parameter(Mandatory=$true)]
	[alias("ServiceAccountsPassword")]
	[string]$Password,
	[parameter(Mandatory=$true)]
	[alias("BuildLocation")]
	[string]$DropFolder,
	[string]$DeploymentAccountName		= "FAELAB\TFSBuild",
	[string]$DeploymentAccountPassword	= "vIgxmg6jvCDA1nUHWi8Xzw==",
	[string]$DeploymentServerName		= "TS-DB1",
	[string]$DeploymentServerIP,
	[string]$Groups,
	[alias("Servers")]
	[string]$Machines,
	[string]$DriveLetter = "D",
	[switch]$RemoveMappings
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

function Get-DeploymentLog{
param(
	[string]$Suffix = "Post-DeploymentValidation",
	[string]$Extension = "log",
	[switch]$NoRegister
)
	$deploymentLogFolder = Join-Path $DropFolder "Logs"

	$fileName = [System.IO.Path]::GetFileNameWithoutExtension($DeploymentConfig)

	$groupString = ""

	if($Groups){
		$groupString = "." + ($Groups -replace ",","_")
	}

	$logname = "{0}.{1}{2}.{3}" -f $Suffix, $fileName, $groupString, $Extension

	$path = Join-Path $deploymentLogFolder $logname

	Write-Host "Log file path: $path"

	if($NoRegister){
		return $path
	}

	Write-Host "Registering log file $path"

	Register-LogFile -Path $path -WithHeader #returns the logfile object
}

function Get-DeploymentMachineIP{
[cmdletbinding()]
param()

	$machineIpAddress = $null
	try
	{
		Push-Location (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent)

		[xml]$xml = Get-Content "Rigmanifest.xml"
		$rigVm = $xml.machines.machine | where {$_.name -eq $DeploymentServerName }

		if($rigVm)
		{
			$machineIpAddress = $rigVm.ipv4address

			$env:DeployMachineIP = $machineIpAddress
		}
	}finally{
		Pop-Location
	}

	(($machineIpAddress -eq $null) | Get-ConditionalValue -TrueValue $DeploymentServerIP -FalseValue $machineIpAddress)
}

function Start-CleanUp{
	param()

	if(!$RemoveMappings){
		Write-Host "Skipping removal of mapped drives."
		return
	}

	try{
		Remove-MappedDrive -ComputerName $DeploymentServerName -ComputerIpAddress $deploymentMachineIP -ShareName "$DriveLetter`$" | Out-Null
	}
	catch{
		Write-Warning "Error cleaning up mapped drives"
	}
}

function Start-Setup {
param()

	$retVal = 0

	$script:deploymentMachineIP = Get-DeploymentMachineIP

	if(!$deploymentMachineIP) {
		$retVal = 5
		return $retVal
	}

	Write-Host "Deployment Machine ($DeploymentServerName) IP Address: $script:deploymentMachineIP"

	$script:deploymentMachinePath = "\\$deploymentMachineIP\$DriveLetter`$"

	$securePassword = ConvertTo-SecureString $Password -AsPlainText -Force

	$secureDeployAccountPW = Unprotect-Password -Password $securePassword -Value $DeploymentAccountPassword -AsSecureString

	$script:deploymentCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $DeploymentAccountName,$secureDeployAccountPW

	$script:deploymentMachinePath = "\\$deploymentMachineIP\$DriveLetter`$"

	$retVal
}

function Invoke-PostDeployValidation{

	$retVal	= 0

	Write-Host "Generating Post-Deployment command string"

	$deployParams = @{
		Configuration = $DeploymentConfig
		ServiceAccountsPassword = $Password
		BuildLocation = (Join-Path $PSScriptRoot "..\..\")
		RigName = $RigName
		Credential = $script:deploymentCredentials
		RemoveMappings = $RemoveMappings
		DriveLetter = $DriveLetter
		EnvironmentType = $EnvironmentType
	}

	if($Groups){
		$deployParams.Groups = $Groups -split ","
	}

	if($Machines){
		$deployParams.Servers = $Machines -split ","
	}

	$result = Start-PostDeploymentValidation @deployParams

	if($result)	{
		Write-Host2 -Type Success -Message "Post-Deployment Validation against configuration $DeploymentConfig passed."
	}
	else{
		Write-Host2 -Type Failure -Message "Post-Deployment Validation against configuration $DeploymentConfig failed."
		$retVal = 1
	}

	$retVal
}

$exitCode = 0
$deploymentLog = Get-DeploymentLog

try{
	$exitCode = Invoke-UntilFail {Start-Setup}, {Invoke-PostDeployValidation}
}
catch{
	Write-Error2 -ErrorRecord $_
	$exitCode = 1
}
finally{
	$deploymentLog | Unregister-LogFile
	#Start-CleanUp
}

Remove-Module TFL.Deployment -ErrorAction Ignore
Remove-Module TFL.PowerShell.Logging -ErrorAction Ignore
Remove-Module TFL.Utilites -ErrorAction Ignore

$exitCode
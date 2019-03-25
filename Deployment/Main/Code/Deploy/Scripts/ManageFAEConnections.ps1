<#
.SYNOPSIS

#>

[cmdletbinding()]
param
(
	[securestring] $Password,
	[psobject[]] $Machines,
	[string] $DeploymentAccountName		= "FAELAB\TFSBuild",
    [string] $DeploymentAccountPassword	= "vIgxmg6jvCDA1nUHWi8Xzw==",
	[switch] $Open
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

function Invoke-NewMappedDrive {
param (
    [string]$IpAddress,
    [string]$Machine,
	[Management.Automation.PSCredential]$Credential
)
	Write-Host ("Caching credentials to $Machine : net use \\$IpAddress /user:" + $Credential.UserName + " <pwd>")
    New-MappedDrive -ComputerName $Machine -ComputerIpAddress $IpAddress -ShareName "D`$" -Credential $Credential | Out-Null
}

function Invoke-RemoveMappedDrive {
param (
    [string]$IpAddress,
    [string]$Machine
)
	Write-Host "Clearing up mapped net used drives."
    Remove-MappedDrive -ComputerName $Machine -ComputerIpAddress $IpAddress -ShareName "D`$" | Out-Null
}

function Open-Connections{
	[cmdletbinding()]
	param()

	Write-Host ""
	Write-Host "### Opening Net Use Connections ###"

	$success = 0
	$secureDeployAccountPW = Unprotect-Password -Password $Password -Value $DeploymentAccountPassword -AsSecureString
	$deploymentCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $DeploymentAccountName, $secureDeployAccountPW

	$machines | ForEach-Object {
		Invoke-NewMappedDrive -IpAddress $_.IPAddress -Machine $_.Name -Credential $deploymentCredentials
	}

	Write-Host "### Net use connections have been opened.###"

	$success
}

function Close-Connections{
	[cmdletbinding()]
	param()

	Write-Host ""
	Write-Host "### Closing Net Use Connections ###"

	$success = 0

	$machines | ForEach-Object {
		Invoke-RemoveMappedDrive -IpAddress $_.IPAddress -Machine $_.Name
	}

	Write-Host "### Net use connections have been closed. ###"

	$success
}

$exitCode = 0

try{
	if($Open){
		$exitCode = Open-Connections
	}
	else{
		$exitCode = Close-Connections
	}
}
catch{
	Write-Error2 -ErrorRecord $_
	$exitCode = 1
}
finally{

}

Remove-Module TFL.Deployment -ErrorAction Ignore
Remove-Module TFL.PowerShell.Logging -ErrorAction Ignore
Remove-Module TFL.Utilites -ErrorAction Ignore

$exitCode
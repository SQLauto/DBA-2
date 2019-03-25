[cmdletbinding()]
<#
	.PARAMETER ServerName
	    	The name of the target server to which you wish to deploy. Defaults to users own machine.
	.EXAMPLE

	#>
param(
	[Parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string] $ServerName,
	[Parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string] $DatabaseName
)

$buildLocation = $env:BUILD_BINARIESDIRECTORY #e.g.(D:\B\03\_work\9\b)
Write-Host "BuildLocation (DropFolder) set to $buildLocation"

$deploymentFolder = Join-Path $buildLocation "Deployment"
$scriptsFolder = Join-Path $deploymentFolder "Scripts"
$modulePath = Join-Path $scriptsFolder "Modules"

[Environment]::SetEnvironmentVariable("PSModulePath",  [Environment]::GetEnvironmentVariable("PSModulePath","Machine"));
$env:PSModulePath = "$modulePath;" + $env:PSModulePath;

#Import relevant modules
Import-Module TFL.PowerShell.Logging -Force
Import-Module TFL.Deployment.Database -Force
Import-Module TFL.Deployment.Database.Local -Force
Import-Module TFL.Utilities -Force

#param not really needed here, but keeps consistency with some of the teams scripts where module is shared so not in same folder.
$devScriptPath = $PSScriptRoot

Import-Module (Join-Path $devScriptPath 'DbDeployUtils.psm1') -Force
#FROM THIS POINT HERE, USERS ARE ALLOWED TO MAKE CHANGES ACCORDING TO THEIR SPECIFIC NEEDS.  ADJUST PARAMETERS AND SECTIONS BELOW AS REQUIRED.
#USERS WILL PROBABLY ALWAYS NEED TO DEPLOY THE DEPLOYMENT SCHEMA AND A BASELINE SCRIPT, AND MOST OF THE TIME IT WILL USE THE PATCHING FOLDER MECHANISM

$scriptTimer = [Diagnostics.Stopwatch]::StartNew()
Write-Header "Script executed by $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)" -AsSubHeader

$params = @{
    DatabaseName = (Get-DatabaseNameWithBuildId -DatabaseName $DatabaseName)
    ServerName = $ServerName
    DropFolder   = $buildLocation
	Action = 'create'
}

try {
	$exitCode = Invoke-Command -ScriptBlock {.\DevDeployCommon.ps1 @params}
}
catch{
	Write-Error2 -ErrorRecord $_
	$exitCode = 1
}
finally {
	$scriptTimer.Stop()
	Write-Header "Script completed with exit code '$exitCode'" -AsSubHeader -OutConsole -Elapsed $scriptTimer.Elapsed
}

Remove-Module DbDeployUtils -ErrorAction Ignore
Remove-Module TFL.PowerShell.Logging -ErrorAction Ignore
Remove-Module TFL.Deployment.Database.Local -ErrorAction Ignore
Remove-Module TFL.Deployment.Database -ErrorAction Ignore
Remove-Module TFL.Utilities -ErrorAction Ignore

exit $exitCode
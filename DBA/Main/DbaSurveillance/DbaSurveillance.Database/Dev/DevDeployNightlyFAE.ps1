[cmdletbinding()]
param(
	[Parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string] $ServerName,
	[Parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string] $DatabaseName
)

if(!$DestinationFolder){
    $buildLocation = $env:BUILD_BINARIESDIRECTORY #e.g.(D:\B\03\_work\9\b)
}
else{
    $buildLocation = "$env:BUILD_BINARIESDIRECTORY\$DestinationFolder"
}

$deploymentFolder = Join-Path $buildLocation "Deployment"
$scriptsFolder = Join-Path $deploymentFolder "Scripts"
$modulePath = Join-Path $scriptsFolder "Modules"

[Environment]::SetEnvironmentVariable("PSModulePath",  [Environment]::GetEnvironmentVariable("PSModulePath","Machine"));
$env:PSModulePath = "$modulePath;" + $env:PSModulePath;

Import-Module TFL.PowerShell.Logging -Force -ErrorAction Stop
Import-Module TFL.Deployment.Database -Force -ErrorAction Stop
Import-Module TFL.Deployment.Database.Local -Force -ErrorAction Stop
Import-Module TFL.Utilities -Force -ErrorAction Stop

$scriptTimer = [Diagnostics.Stopwatch]::StartNew()
Write-Header "Script executed by $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)" -AsSubHeader

$exitCode = 0

try {
	$command = ".\DevDeployIncrementalUpgradeFAE.ps1 -ServerName $ServerName -DatabaseName $DatabaseName -DropFolder $buildLocation -LoopCount 1"
	$scriptToExecute = [scriptblock]::Create($command)
	$exitCode = & $scriptToExecute
}
catch{
	Write-Error2 -ErrorRecord $_
	$exitCode = 1
}
finally {
	$scriptTimer.Stop()
	Write-Header "Script completed with exit code '$exitCode'" -AsSubHeader -OutConsole -Elapsed $scriptTimer.Elapsed
}

Remove-Module TFL.PowerShell.Logging -ErrorAction Ignore
Remove-Module TFL.Deployment.Database.Local -ErrorAction Ignore
Remove-Module TFL.Deployment.Database -ErrorAction Ignore
Remove-Module TFL.Utilities -ErrorAction Ignore

exit $exitCode
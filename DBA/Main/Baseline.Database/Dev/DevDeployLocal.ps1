[CmdletBinding()]
param
(
    [Parameter(Position=0)]
    [string]$DatabaseName,
    [Parameter()]
    [string]$ServerName = [Environment]::MachineName,
    [Parameter()][string]$SolutionPath,
    [Parameter()][string]$User=$env:USERNAME,
    [Parameter()][string]$CatalogPrefix = "_BaselineData_",
    [Parameter()][string]$Branch="main",
    [Parameter()]
    [ValidateSet("c","create","u","update", "d","delete")]
    [string]$Action,
    [switch]$NoDropRunFile
)

#DO NOT CHANGE OR EDIT ANY OF THE PARTS OF THE SCRIPT UNTIL THE NEXT UPPCASE COMMENTS.
#Import support functions module - DO NOT REMOVE THIS
if(!$SolutionPath){
	$SolutionPath = Split-Path (Split-Path $PSScriptRoot)
}

Import-Module (Join-Path $PSScriptRoot 'DbDeployUtils.psm1') -Force -ErrorAction Stop

Install-PackageManagement
Import-Module PackageManagement -Force

#First Register PSNuget repo if not already set
Install-InternalPackageProvider
Install-PSRepository

#Next, install the local dev db deployment module. This contains all components and scripts necessary to begin a local DB deployment
#this will in turn load other dependent modules and scripts, which the callee does not need to know about.
Install-RequiredModule -Name "TFL.Deployment.Database"
Install-RequiredModule -Name "TFL.Deployment.Database.Local"
Install-RequiredModule -Name "TFL.PowerShell.Logging"
Install-RequiredModule -Name "TFL.Utilities"

if(!$DatabaseName) {
    $DatabaseName = "$User$CatalogPrefix$Branch"
}

$scriptTimer = [Diagnostics.Stopwatch]::StartNew()
$logPath = (Join-Path $PSScriptRoot "DbDeployment.log")
$scriptLog = $logPath | Register-LogFile -WithHeader -Title "Deploying Database $DatabaseName"

$params = @{
    DatabaseName = $DatabaseName
    ServerName = $ServerName
    Config         = "Dev.DB"
    NoDropRunFile = $NoDropRunFile
    Action = $Action
}

try {
	$exitCode = Invoke-Command -ScriptBlock {.\DevDeployCommon.ps1 @params}
}
finally {
	$scriptTimer.Stop()
	Write-Header "Script completed with exit code '$exitCode'" -AsSubHeader -OutConsole -Elapsed $scriptTimer.Elapsed
	$scriptLog | Unregister-LogFile
}

Remove-Module DbDeployUtils -ErrorAction Ignore
Remove-Module TFL.PowerShell.Logging -ErrorAction Ignore
Remove-Module TFL.Deployment.Database.Local -ErrorAction Ignore
Remove-Module TFL.Deployment.Database -ErrorAction Ignore
Remove-Module TFL.Utilities -ErrorAction Ignore

#notepad.exe $logPath
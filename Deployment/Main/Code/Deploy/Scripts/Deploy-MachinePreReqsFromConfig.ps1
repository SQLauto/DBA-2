#Requires -Version 5.0
<#
.SYNOPSIS

.PARAMETER Machine
    A Deployment Machine object instance.
.PARAMETER SummaryLog
	A instance of a LogFile object that is used to Log summary results that is shared between machines.
.PARAMETER ModuleRelativePath
    A string indicating the relative path of where to copy PS Modules to and from.
#>
[cmdletbinding()]
param
(
	[parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
	[Deployment.Domain.Machine]$Machine,
	[TFL.PowerShell.Logging.LogFile]$SummaryLog,
	[string]$ModuleRelativePath = "TFL\PowerShell\Modules"
)

function Invoke-EnableRemoting{
[cmdletbinding()]
param()

	$retVal = 0

	if(!$EnableRemoting -or $Machine.DeploymentMachine -or $local){
		Write-Warning "Skipping enable remoting as it is disabled or we are running on a local machine."
		return $retVal
	}

	if(($Machine.PreDeployRoles.Count -eq 0) -and ($Machine.DeploymentRoles.Count -eq 0)){
		Write-Warning "Skipping enable remoting as target machine has no pre-deploy or deployment roles."
		return $retVal
	}

	$timer = [Diagnostics.Stopwatch]::StartNew()

	Write-Host "Attempting to enable remoting for server $computerName"

	if(!(Enable-Remoting $Machine)){
		$retVal = 21
	}

	$timer.Stop()

	$SummaryLog | Write-Summary -Message "Running Enable-Remoting on server $computerName." -Elapsed $timer.Elapsed -ScriptResult $retVal

	$retVal
}

function Assert-SystemVersions{
[cmdletbinding()]
param([string]$ExpectedVersion = "4.5.2", [string]$ExpectedPSVersion = "5.0")

	$retVal = 0

	if(($Machine.PreDeployRoles.Count -eq 0) -and ($Machine.DeploymentRoles.Count -eq 0)){
		return $retVal
	}

	$func = {
		Import-Module TFL.Utilities -Force -ErrorAction Stop
		Get-SystemVersionInfo
	}

	Write-Host "Asserting System Version info on $ComputerName"
	if ($local) {
		$output = Get-SystemVersionInfo
	}
	else {
		$output = Invoke-Command -ComputerName $ComputerName -ScriptBlock $func
	}

	$retVal = $output.ExitCode

	$SummaryLog | Write-Summary -Message "Running Assert-SystemVersions on server $computerName." -ScriptResult $retVal

    $retVal
}

function Test-IsPendingReboot{
[cmdletbinding()]
param()

	$retVal = 0

	if(($Machine.PreDeployRoles.Count -eq 0) -and ($Machine.DeploymentRoles.Count -eq 0)){
		return $retVal
	}

	$rebootInfo = Get-PendingReboot -ComputerName $computerName

	if($rebootInfo.RebootPending){
		$retVal = 1
		Resume-Console
		Write-Warning "Computer $computerName has a pending reboot. Deployment to this machine cannot continue."
		$rebootInfo | Out-String -Stream | Write-Host2
		Suspend-Console
	}

	if($rebootInfo.CBServicing){
		Resume-Console
		Write-Warning "Computer $computerName has a CB Servicing pending reboot. Deployment to this machine will continue, but observe for issues."
		$rebootInfo | Out-String -Stream | Write-Host2
		Suspend-Console
	}

	$SummaryLog | Write-Summary -Message "Running Test-IsPendingReboot on server $computerName." -ScriptResult $retVal

    $retVal
}

function Update-TargetModules{
[cmdletbinding()]
param()

	$retVal = 0

	if($Machine.DeploymentMachine -or $local){
		Write-Host "Skipping update of target modules on local server."
		return $retVal
	}

	if(($Machine.PreDeployRoles.Count -eq 0) -and ($Machine.DeploymentRoles.Count -eq 0)){
		return $retVal
	}

	$timer = [Diagnostics.Stopwatch]::StartNew()

	$modulePath = "$DriveLetter`:\$ModuleRelativePath"

	$uncPath = $modulePath -replace ':', '$'

	$targetModulePath = "\\$($Machine.Name)\$uncPath"

	if(!(Test-Path $targetModulePath)){
		Write-Host "Creating target module path at $targetModulePath as it does not currently exist."
		New-Item -ItemType Directory -Path $targetModulePath -Force | Out-Null
	}

	#Assert modules path
	$exits = Test-Path $targetModulePath
	Write-Host "Target path '$targetModulePath' sucessfully created: $exists"

	Write-Host "Copying PowerShell Modules to module path $targetModulePath."
	#using robocopy to copy ensures that existing files are not recopied.
	$done = Copy-ItemRobust -Path $modulePath -TargetPath $targetModulePath -Recurse

	if(!$done){
		throw "Error copying modules files to target server $($Machine.Name)."
	}

	Write-Host "Executing command to setup PowerShell modules environment path."
	$output = Invoke-Command -ComputerName $Machine.Name -FilePath (Join-Path $PSScriptRoot Set-EnvironmentModulePath.ps1) -ArgumentList $modulePath

    #check to see if call to Invoke-Command executed
    if($null -eq $output){
        throw "Failed to call Invoke-Command on Server $($Machine.Name). This could indicate an issue with PSRemoting on that server."
    }

    if($output.ErrorDetail){
		Write-Error2 $output.ErrorDetail
	}

	$retVal = $output.ExitCode

	#TODO: Test this. Occasionally there is a timing issue here, that when we call script below
	#it fails, even though there is a valid path parameter set etc. Could be path propagation issue
	#So sleep for a small amount to see if this helps.
	Start-Sleep -Seconds 5

	if($retVal -eq 0){

		#test TFL.Utilities
		$testPath = Join-Path $targetModulePath "TFL.Utilities"

		$exits = Test-Path $testPath

		Write-Host "Target TFL.Utilities module path '$testPath' exists: $exists"

		if($exits){
			$retVal = Invoke-Command -ComputerName $Machine.Name -ScriptBlock {
				$result = 0
				Set-ExecutionPolicy Unrestricted
				try{
					Import-Module TFL.Utilities -Force
					$version = Get-Module -Name TFL.Utilities | Select-Object -ExpandProperty Version
					Write-Host "TFL.Utilities Module version: $version"
				}
				catch{
					$result = 22
				}

				Remove-Module TFL.Utilities -ErrorAction Ignore

				$result
			}
		}
		else{
			$retVal = 22
		}
	}

	$timer.Stop()

	$SummaryLog | Write-Summary -Message "Running Update-TargetModules on server $ComputerName." -Elapsed $timer.Elapsed -ScriptResult $retVal

	$retVal
}

$result = 0
$computerName = $Machine.Name
$local = ($computerName -eq "localhost" -or $computerName -eq $env:COMPUTERNAME)
$runspaceId = [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId

$machineTimer = [Diagnostics.Stopwatch]::StartNew()

Write-Header "Starting Pre-Requisite roles on $computerName" -AsSubHeader
Write-Host "Running on RunspaceId $runspaceId"

try
{
	$result = Invoke-UntilFail {Invoke-EnableRemoting},{Test-IsPendingReboot},{Update-TargetModules},{Assert-SystemVersions}
}
catch [System.Exception]
{
	Write-Error2 -ErrorRecord $_
	$result = 20
}

$machineTimer.Stop()

$SummaryLog | Write-Summary -Message "Deploying Pre-Requisite roles on server $computerName." -Elapsed $machineTimer.Elapsed -ScriptResult $result
Write-Header "Ending Pre-Requisite roles on $computerName with result $result" -AsSubHeader

$result
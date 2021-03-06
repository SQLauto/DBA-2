#Requires -Version 5.0
<#
.SYNOPSIS

.PARAMETER Machine
    A Deployment SqlInstance object instance.
.PARAMETER SummaryLog
	A instance of a LogFile object that is used to Log summary results that is shared between machines.
#>
[cmdletbinding()]
param
(
	[parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
	[Deployment.Domain.SqlInstance]$SqlInstance,
	[TFL.PowerShell.Logging.LogFile]$SummaryLog
)

function Start-DeployDbRoles {
[cmdletbinding()]
param()
	$failed = $false

	$dataDeployScript = Join-Path $PSScriptRoot "TFL.DataDeploy.ps1"

	if(!(Test-Path $dataDeployScript)){
		throw "Failed to find script '$dataDeployScript'"
	}

	try{

		$results = $SqlInstance.DatabaseRoles | ForEach-Object {
			$temp = 0
			#don't process any other db roles if we get a failure
			if($failed){
				Write-Warning "Skipping deployment of role $($_) due to previous database deployment errors."
				$temp = 50
				return $temp
			}

			$params = @{
				DropFolder = $dropFolder
				ComputerName = $computerName
				Environment = $environment
				DatabaseRole = $_
				DefaultConfig = $baseConfig
				SqlScriptToRunSuffix = $SqlInstance.DisplayName
				DriveLetter = $driveLetter
                RigConfigFile = $rigConfigFile
				NoDropRunFile = $noDropRunFile
			}

			#note that mode arguments are being supplied by virtue of parent script variables.
			$result = & $dataDeployScript @params

			if($result -ne 0 -or ($LASTEXITCODE -and $LASTEXITCODE -ne 0)) {
				Write-Host2 -Type Failure -Message "Script '$dataDeployScript' on instance $($SqlInstance.DisplayName)' exited with result '$result'"
				$temp = 50
				$failed = $true
			}

			$temp
		}

		$retVal = (Test-IsNullOrEmpty $results) | Get-ConditionalValue -TrueValue 0 -FalseValue ($results | Measure-Object -Maximum).Maximum
	}
	catch {
        Write-Error2 -ErrorRecord $_
        $retVal = 50
    }

	$retVal
}

$machineTimer = [Diagnostics.Stopwatch]::StartNew()

$result = 0
$computerName = $SqlInstance.MachineName
$runspaceId = [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId

Write-Header "Starting database deployment roles on $($SqlInstance.DisplayName)" -AsSubHeader
Write-Host "Running on RunspaceId: $runspaceId"

try {
	$result = Start-DeployDbRoles
}
catch [System.Exception] {
	Write-Error2 -ErrorRecord $_
	$result = 50
}

$machineTimer.Stop()

$SummaryLog | Write-Summary -Message "Deploying database roles on $($SqlInstance.DisplayName)" -Elapsed $machineTimer.Elapsed -ScriptResult $result
Write-Header "Ending deployment of database roles on $($SqlInstance.DisplayName)." -AsSubHeader

$result
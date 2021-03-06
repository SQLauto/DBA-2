[cmdletbinding()]
param
(
	[parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
	[Deployment.Domain.Machine]$Machine,
	[TFL.PowerShell.Logging.LogFile]$SummaryLog
)

filter Assert-ServerRole {
	$configOnlyRoles = "TFL.MsiDeploy","TFL.ServiceDeploy","TFL.WebDeploy"

	if($ConfigOnly){
		$_| Where-Object { $configOnlyRoles -contains $_.Name }
	}
	else{
		$_| Where-Object { $_.Name -ne "TFL.ServerPrerequisite" }
	}
}

function Start-DeployRoles {
[cmdletbinding()]
param()

	try{

		$results = $Machine.DeploymentRoles | Assert-ServerRole | ForEach-Object {
			$localSetupScriptPath = Join-Path $PSScriptRoot ($_.Name + ".ps1")

			if (!(Test-Path $localSetupScriptPath)){
				throw "Failed to find script '$localSetupScriptPath'"
			}

			$temp = 0
			$result = & $localSetupScriptPath -ComputerName $computerName -DeployRole $_

			if($result -gt 0){
                #If a role deployment fails, we will mark deployment as failed, but will continue deployment of other roles of machine.
				Write-Host2 -Type Failure -Message "Script '$localSetupScriptPath' on server '$($Machine.Name)' exited with result '$result'"
				$temp = 40
        	}

			$temp
		}

		$retVal = (Test-IsNullOrEmpty $results) | Get-ConditionalValue -TrueValue 0 -FalseValue ($results | Measure-Object -Maximum).Maximum
	}
	catch {
        Write-Error2 -ErrorRecord $_
        $retVal = 40
    }

	$retVal
}

$machineTimer = [Diagnostics.Stopwatch]::StartNew()

$result = 0
$computerName = $Machine.Name
$runspaceId = [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId

Write-Header "Starting deployment of server roles on $computerName." -AsSubHeader
Write-Host "Running on RunspaceId $runspaceId"

try
{
		$result = Start-DeployRoles
	}
catch [System.Exception]
{
	Write-Error2 -ErrorRecord $_
	$result = 40
}

$machineTimer.Stop()

$SummaryLog | Write-Summary -Message "Deploying server roles on server $computerName." -Elapsed $machineTimer.Elapsed -ScriptResult $result
Write-Header "Ending deployment of server roles to $computerName with result $result" -AsSubHeader

$result
[cmdletbinding()]
param
(
	[parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
	[Deployment.Domain.Machine]$Machine,
	[TFL.PowerShell.Logging.LogFile]$SummaryLog
)

function Invoke-StopWindowsServices{
[cmdletbinding()]
param()

	$retVal = 0
	$failed = $false

	if($ConfigOnly){
		return $retVal
	}

	$timer = [Diagnostics.Stopwatch]::StartNew()

	$results = $Machine.PreDeploymentRoles | Where-Object {$_.RoleType -eq "WindowsService Pre-Deploy" -and $_.State -eq "Stopped" -and $_.Action -ne "Ignore"} | ForEach-Object {
		$result = 0
		#in the case of pre-reqs, if any of them fail, stop processing, as we may have depencies on each other etc.
		if($failed -gt 0){return 31}

		$serviceName = $_.ServiceName

		Write-Host "Getting Windows service status for service $serviceName on server $computerName"
		$status = Get-WindowsServiceStatus -ComputerName $computerName -Service $serviceName

		if($status.Error){
			Write-Host2 -Type Failure -Message "Failed to get Windows Service status for service $serviceName"
			$result = 31
			$failed = $true
			return $result
		}

		if(Test-IsNullOrEmpty $status.Services){
			Write-Warning "Unable to stop service $serviceName. Service was not found."
			return $result
		}

		$serviceStatus = $status.Services[0]
		Write-Host "Current state of service $serviceName is $($serviceStatus.Status) with Start Mode of $($serviceStatus.StartMode)"

		if($serviceStatus.StartMode -eq "Disabled"){
			Write-Warning "Not stopping service $serviceName on $computerName as it is currenlty disabled."
			return $result
		}

		if($_.Action -eq "Fix"){
			Write-Host "Stopping service $serviceName. If service is already stopped, nothing will happen."

			$loopCount = 0
			do{
				$output = Stop-WindowsService -ComputerName $computerName -Service @($serviceName) -TimeOut "00:00:30"

				if($output.ExitCode -ne 0){
					$loopCount++
					$output | fl Server, Error, ErrorDetail | Out-String -stream | Write-Host
					Write-Host "Unable to stop windows service. Retrying - Attempt $loopCount"
					Start-Sleep -Seconds 5
				}
				else{
					$output | Select-Object -ExpandProperty Services Server | ft DisplayName, Status -GroupBy Server -auto | Out-String -stream | Write-Host2
				}
			}While($loopCount -lt 5 -and $output.ExitCode -eq 1)
		}

		if($_.Action -eq "Fail"){
			Write-Host "Current state of service $serviceName is $($serviceStatus.Status) with Start Mode of $($serviceStatus.StartMode)"

			if($serviceStatus.Status -ne $_.State){
				Write-Host2 -Type Failure -Message "Failing deployment of service: $serviceName due not non-matching status."
				$result = 31
				$failed = $true
			}
		}

		$result
	}

	$timer.Stop()

	if(!(Test-IsNullOrEmpty $results)){
		$retVal = ($results | Measure-Object -Maximum).Maximum
		$SummaryLog | Write-Summary -Message "Running Invoke-StopWindowsServices on server $computerName." -Elapsed $timer.Elapsed -ScriptResult $retVal
	}

	$retVal
}

function Invoke-StartWindowsServices{
param()

	$retVal = 0
	$failed = $false

	if($ConfigOnly){
		return $retVal
	}

	$timer = [Diagnostics.Stopwatch]::StartNew()

	$results = $Machine.PreDeploymentRoles | Where-Object {$_.RoleType -eq "WindowsService Pre-Deploy" -and $_.State -eq "Running" -and $_.Action -ne "Ignore"} | ForEach-Object {
		$result = 0
		#in the case of pre-reqs, if any of them fail, stop processing, as we may have depencies on each other etc.
		if($failed){return 32}

		$serviceName = $_.ServiceName

		Write-Host "Getting Windows service status for service $serviceName on server $computerName"
		$status = Get-WindowsServiceStatus -ComputerName $ComputerName -Service $serviceName

		if($status.Error){
			Write-Host2 -Type Failure -Message "Failed to get Windows Service status for service: $serviceName"
			$result = 32
			$failed = $true
			return $result
		}

		if(Test-IsNullOrEmpty $status.Services){
			Write-Host2 -Type Failure -Message "Failed to get Windows Service status for service $serviceName. Service was not found."
			$result = 32
			$failed = $true
			return $result
		}

		$serviceStatus = $status.Services[0]
		Write-Host "Current state of service $serviceName is $($serviceStatus.Status) with Start Mode of $($serviceStatus.StartMode)"

		if($_.Action -eq "Fix"){
			if($serviceStatus.StartMode -eq "Disabled"){
				Write-Host2 -Type Failure -Message "Unable to start service $serviceName as it is currenlty disabled."
				$result = 32
				$failed = $true
				return $result
			}

			Write-Host "Starting service $serviceName. If service is already started, nothing will happen."

			$loopCount = 0
			do{
				$output = Start-WindowsService -ComputerName $computerName -Service @($serviceName) -TimeOut "00:00:30"

				$result = $output.ExitCode
				if($output.ExitCode -ne 0){
					$loopCount++
					$output | fl Server, Error, ErrorDetail | Out-String -stream | Write-Host
					Write-Host "Unable to start windows service. Retrying - Attempt $loopCount"
					Start-Sleep -Seconds 10
				}
				else{
					$output | Select-Object -ExpandProperty Services Server | ft DisplayName, Status -GroupBy Server -auto | Out-String -stream | Write-Host
				}
			}While($loopCount -lt 5 -and $output.ExitCode -ne 0)

			if($output.ExitCode -ne 0){
				$result = 32
				$failed = $true
			}
		}

		if($_.Action -eq "Fail"){
			if($serviceStatus.Status -ne $_.State){
				Write-Host2 -Type Failure -Message "Failing deployment of service: $serviceName due not non-matching status."
				$result = 32
			}
		}

		$result
	}

	$timer.Stop()
	if(!(Test-IsNullOrEmpty $results)){
		$retVal = ($results | Measure-Object -Maximum).Maximum
		$SummaryLog | Write-Summary -Message "Running Invoke-StartWindowsServices on server $ComputerName." -Elapsed $timer.Elapsed -ScriptResult $retVal
	}

	$retVal
}

$result = 0
$role = "Pre-Deployment"
$computerName = $Machine.Name

$machineTimer = [Diagnostics.Stopwatch]::StartNew()

Write-Header "Starting $role roles on $ComputerName" -AsSubHeader

try
{
	$result = Invoke-UntilFail {Invoke-StopWindowsServices},{Invoke-StartWindowsServices}
}
catch [System.Exception]
{
	Write-Error2 -ErrorRecord $_
	$result = 30
}

$machineTimer.Stop()

$SummaryLog | Write-Summary -Message "Deploying $role roles on server $computerName." -Elapsed $machineTimer.Elapsed -ScriptResult $result
Write-Header "Ending $role roles on $computerName with result $result" -AsSubHeader

$result
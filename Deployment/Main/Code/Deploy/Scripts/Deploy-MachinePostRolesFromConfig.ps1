[cmdletbinding()]
param
(
	[parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
	[Deployment.Domain.Machine]$Machine,
	[TFL.PowerShell.Logging.LogFile]$SummaryLog
)

function Invoke-WebServicePostDeploy{
[cmdletbinding()]
param()

	$retVal = 0
	$failed = $false

	if($ConfigOnly){
		return $retVal
	}

	$timer = [Diagnostics.Stopwatch]::StartNew()

	$func = {
		param([System.Uri]$Url, [int]$Timeout)
		$result = $false

		$request = [System.Net.WebRequest]::Create($Url)
		$request.Timeout = $Timeout*1000

		try {
			$response = $request.GetResponse();
			$code = [int]$response.StatusCode
			Write-Host "Request status code came back as: $code"
			$result = ($code -ge 200 -and $code -lt 300)

		}
		catch [System.Net.WebException] {
			$result = $false
		}

		$result
	}

	$callback = {Write-Warning "Attemping to connect to WebService.`n`r`tRetryCount: $([Environment]::GetEnvironmentVariable("PowershellScript.RetryCount","Process"))"}

	$results = $Machine.PostDeploymentRoles | Where-Object {$_.RoleType -eq "WebService Post-Deploy"} | ForEach-Object {

		$result = 0
		#in the case of post-reqs, if any of them fail, stop processing, as we may have depencies on each other etc.
		if($failed){return 63}

		$port = $_.PortNumber
		$webServicePath = $_.WebServicePath
		$timeOut = $_.TimeOut

		$webServiceUrl = New-Object -TypeName System.Uri -ArgumentList "http://$($Machine.Name)`:$port/$webServicePath"

		Write-Host "Polling WebService at $webServiceUrl."

		$loopCount = 0

		$valid = $false

		do{
			$request = [System.Net.WebRequest]::Create($webServiceUrl)
			$request.Timeout = $timeOut*1000

			try {
				$response = $request.GetResponse();
				$code = [int]$response.StatusCode
				Write-Host "Request status code came back as: $code"
				$valid = ($code -ge 200 -and $code -lt 300)
			}
			catch [System.Net.WebException] {
				$valid = $false
			}

			if(!$valid){
				$loopCount++
				Write-Host "Unable to connect to WebService $webServiceUrl. Retrying - Attempt $loopCount"
				Start-Sleep -Seconds 10
				$result = 63
			}
			else{
				Write-Host "Successfully connected to WebService Url $webServiceUrl"
				$result = 0
			}
		}While($loopCount -lt 10 -and $result -gt 0)

		if(!$valid){
			$failed = $true
		}

		$result
	}

	$timer.Stop()
	if(!(Test-IsNullOrEmpty $results)){
		$retVal = ($results | Measure-Object -Maximum).Maximum
		$deploymentSummaryLog | Write-Summary -Message "Running Invoke-WebServicePostDeploy on server $ComputerName." -Elapsed $timer.Elapsed -ScriptResult $retVal
	}

	$retVal
}

function Invoke-AppFabricPostDeploy{
[cmdletbinding()]
param()
	$retVal = 0
	if($ConfigOnly){
		return $retVal
	}

	$any = $false

	$timer = [Diagnostics.Stopwatch]::StartNew()
	$results = $Machine.PostDeploymentRoles | ? {$_.RoleType -eq "AppFabric Post-Deploy" -and $_.Action -ne "Ignore"} | % {
		$any = $true

		if($_.State -ieq "Up"){
			$output = Start-AppFabric -Computer $Machine.Name -Port $_.PortNumber -Action $_.Action
		}
		else{
			$output = Start-AppFabric -Computer $Machine.Name -Port $_.PortNumber -Action $_.Action
		}

		if($output.ExitCode -gt 0){
			$output | fl Server, Error, ErrorDetail | Out-String -stream | Write-Host
		}

		$output.ExitCode
	}
	$timer.Stop()

	$retVal = (Test-IsNullOrEmpty $results) | Get-ConditionalValue -TrueValue 0 -FalseValue ($results | Measure-Object -Maximum).Maximum

	if($retVal -ne 0){
		$retVal = 64
	}

	if($any){
		$SummaryLog | Write-Summary -Message "Running Invoke-AppFabricPostDeploy on server $ComputerName." -Elapsed $timer.Elapsed -ScriptResult $retVal
	}
	$retVal
}

function Invoke-StopWindowsServices{
[cmdletbinding()]
param()

	$retVal = 0
	$failed = $false

	if($ConfigOnly){
		return $retVal
	}

	$timer = [Diagnostics.Stopwatch]::StartNew()

	$results = $Machine.PostDeploymentRoles | Where-Object {$_.RoleType -eq "WindowsService Post-Deploy" -and $_.State -eq "Stopped" -and $_.Action -ne "Ignore"} | ForEach-Object {

		$result = 0
		#in the case of post-roles, if any of them fail, stop processing, as we may have depencies on each other etc.
		if($failed -gt 0){return 61}

		$serviceName = $_.ServiceName

		Write-Host "Getting Windows service status for service $serviceName on server $computerName"
		$status = Get-WindowsServiceStatus -ComputerName $computerName -Service $serviceName

		if($status.Error){
			Write-Host2 -Type Failure -Message "Failed to get Windows Service status for service $serviceName"
			$result = 61
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
			Write-Host "Not stopping service $serviceName on $computerName as it is currenlty disabled."
			return $result
		}

		if($_.Action -eq "Fix"){
			Write-Host "Stopping service $serviceName. If service is already stopped, nothing will happen."

			$loopCount = 0
			do{
				$output = Stop-WindowsService -ComputerName $computerName -Service @($serviceName) -TimeOut "00:00:30"

				$retVal = $output.ExitCode
				if($retVal -ne 0){
					$loopCount++
					$output | fl Server, Error, ErrorDetail | Out-String -stream | Write-Host
					Write-Host "Unable to stop windows service. Retrying - Attempt $loopCount"
					Start-Sleep -Seconds 5
				}
				else{
					$output | Select-Object -ExpandProperty Services Server | ft DisplayName, Status -GroupBy Server -auto | Out-String -stream | Write-Host
				}
			}While($loopCount -lt 5 -and $retVal -eq 1)
		}

		if($_.Action -eq "Fail"){
			Write-Host "Current state of service $serviceName is $($serviceStatus.Status) with Start Mode of $($serviceStatus.StartMode)"

			if($serviceStatus.Status -ne $_.State){
				Write-Host2 -Type Failure -Message "Failing deployment of service: $serviceName due not non-matching status."
				$result = 61
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

	$results = $Machine.PostDeploymentRoles | ? {$_.RoleType -eq "WindowsService Post-Deploy" -and $_.State -eq "Running" -and $_.Action -ne "Ignore"} | % {
		$result = 0
		#in the case of post-reqs, if any of them fail, stop processing, as we may have depencies on each other etc.
		if($failed){return 62}

		$serviceName = $_.ServiceName

		Write-Host "Getting Windows service status for service $serviceName on server $computerName"
		$status = Get-WindowsServiceStatus -ComputerName $ComputerName -Service $serviceName

		if($status.Error){
			Write-Host2 -Type Failure -Message "Failed to get Windows Service status for service: $serviceName"
			$result = 62
			$failed = $true
			return $result
		}

		if(Test-IsNullOrEmpty $status.Services){
			Write-Host2 -Type Failure -Message "Failed to get Windows Service status for service $serviceName. Service was not found."
			$result = 62
			$failed = $true
			return $result
		}

		$serviceStatus = $status.Services[0]
		Write-Host "Current state of service $serviceName is $($serviceStatus.Status) with Start Mode of $($serviceStatus.StartMode)"

		if($_.Action -eq "Fix"){
			if($serviceStatus.StartMode -eq "Disabled"){
				Write-Host2 -Type Failure -Message "Unable to start service $serviceName as it is currenlty disabled."
				$result = 62
				$failed = $true
				return $result
			}

			Write-Host "Starting service $serviceName. If service is already started, nothing will happen."

			$loopCount = 0
			do{
				$output = Start-WindowsService -ComputerName $computerName -Service @($serviceName) -TimeOut "00:00:30"

				$retVal = $output.ExitCode
				if($retVal -ne 0){
					$loopCount++
					$output | fl Server, Error, ErrorDetail | Out-String -stream | Write-Host
					Write-Host "Unable to start windows service. Retrying - Attempt $loopCount"
					Start-Sleep -Seconds 10
				}
				else{
					$output | Select-Object -ExpandProperty Services Server | ft DisplayName, Status -GroupBy Server -auto | Out-String -stream | Write-Host
				}
			}While($loopCount -lt 5 -and $retVal -eq 1)
		}

		if($_.Action -eq "Fail"){
			if($serviceStatus.Status -ne $_.State){
				Write-Host2 -Type Failure -Message "Failing deployment of service: $serviceName due not non-matching status."
				$result = 62
				$failed = $true
			}
		}
	}

	$timer.Stop()

	if(!(Test-IsNullOrEmpty $results)){
		$retVal = ($results | Measure-Object -Maximum).Maximum
		$SummaryLog | Write-Summary -Message "Running Invoke-StartWindowsServices on server $ComputerName." -Elapsed $timer.Elapsed -ScriptResult $retVal
	}

	$retVal
}

$result = 0
$role = "Post-Deployment"
$computerName = $Machine.Name
$runspaceId = [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId

$machineTimer = [Diagnostics.Stopwatch]::StartNew()

Write-Header "Starting $role roles on $computerName" -AsSubHeader
Write-Host "Running on RunspaceId $runspaceId"

try
{
	$result = Invoke-UntilFail {Invoke-AppFabricPostDeploy},{Invoke-StopWindowsServices},{Invoke-StartWindowsServices},{Invoke-WebServicePostDeploy}
}
catch [System.Exception]
{
	Write-Error2 -ErrorRecord $_
	$result = 60
}

$machineTimer.Stop()

$SummaryLog | Write-Summary -Message "Deploying $role roles on server $computerName." -Elapsed $machineTimer.Elapsed -ScriptResult $result
Write-Header "Ending $role roles on $computerName with result $result" -AsSubHeader

$result
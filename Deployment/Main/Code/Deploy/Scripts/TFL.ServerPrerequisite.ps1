[cmdletbinding()]
param
(
    [parameter(Mandatory=$true)][string]$ComputerName,
    [Deployment.Domain.Machine]$Machine
)

function Invoke-StopWindowsServices{
param()

	$Machine.PreRequisiteRoles | Where-Object {$_.State -eq "Stopped" -and $_.Action -ne "Ignore"} | ForEach-Object {

		$serviceName = $_.ServiceName
		if($_.Action -eq "Fix"){
			Write-Host "Stopping service $serviceName. If service is already stopped, nothing will happen."
			Get-Service -ComputerName $ComputerName -Name $serviceName -ErrorAction ignore | Stop-Service | Out-Null #if service name does not exists, it will ingore.
			#Wait for upto 30 secs for service to come up
			Get-Service -ComputerName $ComputerName -Name $serviceName -ErrorAction ignore | ForEach-Object { $_.WaitForStatus('Stopped', '00:00:30') | Out-Null }
		}

		if($_.Action -eq "Fail"){
			#get current status of service and determine if we need to fail
			$serviceInfo = Get-WindowsServiceInfo -ComputerName $ComputerName -Service $serviceName

			if($serviceInfo.Error){
				Write-Warning "Failed to get Windows Service status for service: $serviceName"
				$exitCode = 1
				return
			}

			#TODO: test if this array
			$serviceStatus = $serviceInfo.Services[0]
			Write-Host "Current state of service $serviceName is $($serviceStatus.Status) with Start Mode of $($serviceStatus.StartMode)"

			if($serviceStatus.Status -ne $_.State){
				Write-Warning "Failing deployment of service: $serviceName due not non-matching status."
				$exitCode = 1
			}
		}
	}
}

function Invoke-StartWindowsServices{
param()

	$Machine.PreRequisiteRoles | Where-Object {$_.State -eq "Running" -and $_.Action -ne "Ignore"} | ForEach-Object {

		$serviceName = $_.ServiceName

		#when stating services, need to take into account that it could be disabled. If disable, need to highlight and ignore.
		$serviceInfo = Get-WindowsServiceInfo -ComputerName $ComputerName -Service $serviceName

		if($serviceInfo.Error){
			Write-Warning "Failed to get Windows Service status for service: $serviceName"
			$exitCode = 1
			return
		}

		#TODO: test if this array
		$serviceStatus = $serviceInfo.Services[0]

		if($_.Action -eq "Fix"){
			if($serviceStatus.StartMode -eq "Disabled"){
				Write-Warning "Unable to stat service $serviceName as it is currenlty disabled."
				$exitCode = 1
				return
			}

			Write-Host "Starting service $serviceName. If service is already started, nothing will happen."
			Get-Service -ComputerName $ComputerName -Name $serviceName | Where-Object {$_.status -eq "stopped"} | Start-Service -ErrorAction Stop | Out-Null
			#Wait for upto 2 mins for service to come up
			Get-Service -ComputerName $ComputerName -Name $serviceName | ForEach-Object { $_.WaitForStatus('Running','00:02:00') | Out-Null }
		}

		if($_.Action -eq "Fail"){
			Write-Host "Current state of service $serviceName is $($serviceStatus.Status) with Start Mode of $($serviceStatus.StartMode)"

			if($serviceStatus.Status -ne $_.State){
				Write-Warning "Failing deployment of service: $serviceName due not non-matching status."
				$exitCode = 1
			}
		}
	}
}

$result = 0
$role = "Service Pre-Requisite"

Write-Host ""
Write-Header "Starting $($DeployRole.RoleType) role '$($DeployRole.Description)' on $ComputerName" -AsSubHeader
$timer = [Diagnostics.Stopwatch]::StartNew()

try
{
	Invoke-UntilFail {Invoke-StopWindowsServices},{Invoke-StartWindowsServices}
}
catch [System.Exception]
{
	Write-Error2 -ErrorRecord $_
	$result = 1
}

$timer.Stop()

$SummaryLog | Write-Summary -Message "ran $role role '$($DeployRole.Description)' on $ComputerName."  -Elapsed $timer.Elapsed -ScriptResult $result
Write-Header "Ending $role role '$($DeployRole.Description)' on $ComputerName" -AsSubHeader

$result
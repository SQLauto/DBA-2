[cmdletbinding()]
param(
	[string]$LogFile,
	[string]$ModulePath ,
	[string[]]$ProcessName = @("mmc","notepad","notepad++","psexesvc","powershell_ise"."powershell","cmd"),
	[string]$DriveLetter

)

if(!$LogFile){
    $LogFile = "$($DriveLetter):\Deploy\Logs\StopProcesses.log"
}

if(!$ModulePath){
	$ModulePath = "$($DriveLetter):\Deploy\Modules"
}

Set-ExecutionPolicy Unrestricted

[Environment]::SetEnvironmentVariable("PSModulePath",  [Environment]::GetEnvironmentVariable("PSModulePath","Machine"))
$env:PSModulePath = "$ModulePath;" + $env:PSModulePath

Import-Module TFL.PowerShell.Logging -Force -ErrorAction Stop

function Get-CurrentProcessId {
	$process = Get-WmiObject Win32_Process -Filter "processid='$pid'"
	$process.ParentProcessId
}

function Invoke-Main{
[cmdletbinding()]
param()
	PROCESS{

		Write-Host "Stop open processes on Rig - started"

		$ProcessName | % {
			$pName = $_
			$currentProcess = -1
			if ($pName -eq 'cmd' -or $pName -eq 'powershell') {
				$currentProcess = (Get-CurrentProcessId)
			}

			$process = Get-Process | Where-Object { $_.ProcessName -eq $pName -and $_.Id -ne $currentProcess }

			if($process){
				Write-Host "Process $pName found. Attempting stop."
				$process | ft | Out-String -Stream | Write-Host2 -NoTimestamp
				$process | Stop-Process -Force -PassThru | ? {!$_.HasExited} | Wait-Process -Timeout 30

				$process = Get-Process | Where-Object { $_.ProcessName -eq $pName -and $_.Id -ne $currentProcess }

				if($process){
					Write-Host2 -Type Failure -Message "Failed to stop process $pName"
				}
				else{
					Write-Host2 -Type Success -Message "Process $pName successfully stopped."
				}
			}
		}

		Write-Host2 -Type Success -Message "Stop open processes on rig complete."
	}
}

$result = 0

try{
	Invoke-Main
}
catch{
	Write-Error -ErrorRecord $_
	$result = 1
}

Remove-Module TFL.PowerShell.Logging -Force

$result
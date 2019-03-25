[cmdletbinding()]
param
(
	[parameter(Mandatory=$true, Position = 0)]
	[string] $RigName
)

$modulePath = Join-Path $PSScriptRoot "Modules"

[Environment]::SetEnvironmentVariable("PSModulePath",  [Environment]::GetEnvironmentVariable("PSModulePath","Machine"))
$env:PSModulePath = "$modulePath;" + $env:PSModulePath

Import-Module TFL.PowerShell.Logging -Force
Import-Module TFL.Deployment.VCloud -Force -ErrorAction Stop
Import-Module TFL.Deployment.Database -Force -ErrorAction Stop

function Write-ErrorDeploymentLog{
param(
	[int]$ErrorCode,
	[string]$LastError,
	[switch]$VCloud
)

	$logEvents = @{
		EXITCODE = $ErrorCode
		LASTERROR = "$LastError Exiting with code $ErrorCode"
	}

	if($LastException){
		$logEvents.LASTEXCEPTION = $LastException
	}

	if($LastError){
		Write-Error $LastError
	}

	Write-DeploymentLog -DeploymentLogId $script:deploymentLogId -LogEvents $logEvents -VCloud:$VCloud  | Out-Null
}

function Invoke-StopVApp {
[cmdletbinding()]
param()

	$success = $true
	try {
		Write-Host "Stopping vApp $RigName"
		$success = $script:vApp | Stop-VApp

		if($success){
			Write-Host "Stopped vApp $RigName"
		}
		else{
			Write-Warning "Failed to stop vApp $RigName"
		}
	}
	catch {
		Write-ErrorDeploymentLog -ErrorCode 2011 -LastError "Error stopping vApp rig '$RigName'." -VCloud
		Write-Error2 -ErrorRecord $_
		$success = $false
	}

	$success
}

function Start-Shutdown {
[cmdletbinding()]
param()

	$retVal = 0
	$script:vApp = Get-VApp -Name $RigName
	$vCloudDeploymentLogId = $env:VCLOUDDEPLOYMENTID

	if($script:vApp)
	{
		if(!([string]::IsNullOrEmpty($vCloudDeploymentLogId)))
		{
			Write-Host "Attempting to stop rig: $RigName and logging under id: $vCloudDeploymentLogId" 
			Write-DeploymentLog -DeploymentLogId $vCloudDeploymentLogId -LogEvents @{EVENTID = "BeginStopCiVapp"}  -VCloud | Out-Null
			
			if(-not (Invoke-StopVApp)) 
			{
				$retVal = 2011
				return $retVal
			}

			Write-DeploymentLog -DeploymentLogId $vCloudDeploymentLogId -LogEvents @{EVENTID = "EndStopCiVapp"}  -VCloud | Out-Null
		}
		else
		{
			if(-not (Invoke-StopVApp)) 
			{
				$retVal = 2011
				return $retVal
			}
		}
	}
	else
	{
		Write-Host "vApp $RigName does not exist nothing to Shutdown."
	}

	$retVal
}

$vCloudPassword = ConvertTo-SecureString "P0wer5hell" -AsPlainText -Force
$vCloudParams = @{
	Url = "https://vcloud.onelondon.tfl.local"
	Organisation = "ce_organisation_td"
	Username = "zSVCCEVcloudBuild"
	Password = $vCloudPassword
}

$exitCode = 0
Write-Host "Initialising VCloud connection...."
$vCloud = Connect-VCloud @vCloudParams

try{
	$exitCode = Start-Shutdown
}
catch{
	Write-Error2 -ErrorRecord $_
	$exitCode = 1
}
finally{
	Write-Host "Closing VCloud connection."
	$vCloud | Disconnect-VCloud
}

Remove-Module TFL.PowerShell.Logging
Remove-Module TFL.Deployment.VCloud
Remove-Module TFL.Deployment.Database

$exitCode
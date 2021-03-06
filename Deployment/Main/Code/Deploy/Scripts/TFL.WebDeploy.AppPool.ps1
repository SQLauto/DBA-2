#requires -Version 5.0
[cmdletbinding()]
param(
	[parameter(Mandatory=$true)]
	[ValidateNotNull()][string]$DeployRoleXml,
	[parameter()]
	[string]$AccountUser,
	[parameter()]
	[string]$AccountPassword
)

filter Select-Started {$_ | Where-Object {$_.state -eq 'Started' }}

$temp = @{
	'Server' = $env:COMPUTERNAME;
	'ExitCode' = 0;
}

try {
	Set-ExecutionPolicy Unrestricted
	Import-Module TFL.Deployment.Web -Force -ErrorAction Stop
	Import-Module TFL.Utilities -Force -ErrorAction Stop

	$deployRole = $DeployRoleXml | ConvertFrom-DeployRoleXml -Type Deployment.Domain.Roles.WebDeploy

	$appPoolRole = $deployRole.AppPool
	$name = $appPoolRole.Name

	$path = "IIS:\\AppPools\$name"

	if (Test-Path $path) {
        Write-Host "Web Application Pool $name already exists, updating settings."
        $appPool = Get-Item $path
    }
    else {
        Write-Host "Web Application Pool $name does not exist, creating new Application Pool."
        $appPool = New-Item $path -Force;
    }

	#always stop the AppPool
	Write-Host "Stopping AppPool $name if not already stopped."
	$appPool | Select-Started | Stop-WebAppPool
	$appPool | Select-Started | Select-Exists | Wait-StopWebAppPool | Out-Null

	Write-Host "Setting AppPool managedPipelineMode to Integrated"
	$appPool.managedPipelineMode = “Integrated”

    Write-Host "Setting AppPool managedRuntimeVersion to 4.0"
    $appPool.managedRuntimeVersion = "v4.0";

	$appPoolUser = $appPoolRole.ServiceAccount

	switch($appPoolUser) {
		"NetworkService" {
			# Configure AppPools with Network Service as the identity:
			Write-Host "Setting app pool identity to NetworkService"
			$appPool.ProcessModel.IdentityType = 2;
		}

		"ApplicationPoolIdentity" {
			# Configure AppPools with Application Pool Identity as the identity:
			Write-Host "Setting app pool identity to ApplicationPoolIdentity"
			$appPool.ProcessModel.IdentityType = 4;
		}

		default {
			if(!$AccountUser -and !$AccountPassword){
				throw "Service account and/or password are null or empty, and must be set."
			}

			# Configure AppPools with a specific user as the identity:
			Write-Host "Setting app pool identity to use service account [$AccountUser]"
			$appPool.processModel.userName = $AccountUser
            $appPool.processModel.password = $AccountPassword
            $appPool.processModel.identityType = 3;
		}
	}

    if ($appPoolRole.IdleTimeout) {
		Write-Host "Setting app pool idleTimeout to $($appPoolRole.IdleTimeout)"
        $appPool.ProcessModel.idleTimeout = [TimeSpan]::FromMinutes($appPoolRole.IdleTimeout);
    }
	if ($appPoolRole.RecycleLogEvents.Count -gt 0) {
		$events = $appPoolRole.RecycleLogEvents -join ','
		Write-Host "Setting app pool recycle event log details to $events"
		$appPool.recycling.logEventOnRecycle = $events
	}

    $appPool | Set-Item;

	# Verify
	if (Test-Path $path) {
		Write-Host "Successfully set AppPool properties";
	}
	else {
		throw "AppPool $Name does not exist. Failed to create AppPool"
	}
}
catch {
	$temp.ExitCode = 1
    $temp.Error = "An error occurred in TFL.WebDeploy.AppPool.ps1. LastExitCode: $LASTEXITCODE"
	$temp.ErrorDetail = $_
	$global:LASTEXITCODE = $null
}

[pscustomobject]$temp
[cmdletbinding()]
param
(
	[parameter(Mandatory=$true, Position = 0)]
	[string] $RigName,
	[parameter(Mandatory=$true)]
	[string] $AzureAccountPassword
)

$modulePath = Join-Path $PSScriptRoot "Modules"

[Environment]::SetEnvironmentVariable("PSModulePath",  [Environment]::GetEnvironmentVariable("PSModulePath","Machine"))
$env:PSModulePath = "$modulePath;" + $env:PSModulePath

Import-Module TFL.PowerShell.Logging -Force
Import-Module TFL.Deployment.Azure -Force -ErrorAction Stop

$exitCode = 0

try{
	$InputObject = @{
			LabName = $RigName
			Action = "Stop"
		}
	$Headers = @{
		}

	$Parameters = @{
		Password = $AzureAccountPassword
		User = "06863203-99bc-49c5-824c-9a5963ae03c9"
		Tenant = "1fbd65bf-5def-4eea-a692-a089c255346b"
		SubscriptionId = "3065ef51-6e69-4ee9-a407-b2cc275f91d6" 
		AutomationAccountName = "rig-manager"
		AutomationResourceGroup = "ftp-rig"
	}
	Write-Host "Invoking Stop-LabVM...."
	
	$exitCode = Invoke-Webhook -Token "RORYEnvtfzg%2bOdbcS%2b5maye3Yw7JW42v63XMWCqNMn8%3d" -Parameters $Parameters -InputObject $InputObject -Headers $Headers

	if($exitCode -ne 0)
	{
		$ErrorMessage = "Stop-LabVM failed."
		throw $ErrorMessage
	}
}
catch{
	Write-Error2 -ErrorRecord $_
	$exitCode = 1
}
finally{
	Remove-Module TFL.PowerShell.Logging
	Remove-Module TFL.Deployment.Azure
}

$exitCode
#File:			GenerateRigManifest.ps1
#Description:	Sample Script for testign use with new multi CI build process

Param(
	[string]$RigName,
	[string]$AzureAccountPassword,
	[string]$OutputPath
)

$exitCode = 0

$modulePath = Join-Path $PSScriptRoot "..\Scripts\Modules"
# if module path does not exists
if(-not (($env:PSModulePath -split ";") -contains $modulePath))
{
	Write-Host "Setting module path to $modulePath"
	[Environment]::SetEnvironmentVariable("PSModulePath",  [Environment]::GetEnvironmentVariable("PSModulePath","Machine"))
	$env:PSModulePath = "$modulePath;" + $env:PSModulePath
}

Import-Module TFL.Deployment.Azure -Force -ErrorAction Stop

try{
	$Parameters = @{
		Password = $AzureAccountPassword
		User = "06863203-99bc-49c5-824c-9a5963ae03c9"
		Tenant = "1fbd65bf-5def-4eea-a692-a089c255346b"
		SubscriptionId = "3065ef51-6e69-4ee9-a407-b2cc275f91d6"
	}
	$RigVM = Get-RigVM -RigName $RigName -Parameters $Parameters
	$RigMachines = @()
	foreach($RigMachine in $RigVM)
	{
		if($RigMachine.Name -ne "FAEADG001")
		{
			$properties = @{
				ComputerName = $RigMachine.Name
				IPV4Address = $RigMachine.IP
				Drives = @()
			}

			$RigMachines += New-Object -TypeName psobject -Property $properties
		}
	}

	Write-Host "Generating new RigManifest.xml"
	$output = New-Manifestfile -RigMachines $RigMachines -BuildDefinitionPath $OutputPath -RigName $RigName
	Write-Host $output
}
catch {
	Write-Error $_
	$exitCode = 1
}
finally{
	Remove-Module TFL.Deployment
	Remove-Module TFL.Deployment.Azure
}

exit $exitCode
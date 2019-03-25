[cmdletbinding()]
param
(
	[parameter(Mandatory=$true, Position = 0)]
	[string]
    $RigName,

	[parameter(Mandatory=$true)]
	[string]
    $TemplateName,

    [parameter(Mandatory=$true)]
	[string]
    $ProjectName,
	
	[parameter(Mandatory=$true)]
	[string]
    $AzureAccountPassword,

	[switch]
    $ForceRefresh
)

$RigName = $RigName -replace '\.','_'

$modulePath = Join-Path $PSScriptRoot "Modules"

if(-not (($env:PSModulePath -split ";") -contains $modulePath))
{
	[Environment]::SetEnvironmentVariable("PSModulePath",  [Environment]::GetEnvironmentVariable("PSModulePath","Machine"))
	$env:PSModulePath = "$modulePath;" + $env:PSModulePath
}

Import-Module TFL.PowerShell.Logging -Force
Import-Module TFL.Deployment.Azure -Force -ErrorAction Stop -Verbose

$exitCode = 0
Write-Host "Initialising Azure Build...."

$Servers = (Import-LocalizedData -BaseDirectory $PSScriptRoot -FileName "ProjectsRigData.psd1")

$Parameters = @{
		Password = $AzureAccountPassword
		User = "06863203-99bc-49c5-824c-9a5963ae03c9"
		Tenant = "1fbd65bf-5def-4eea-a692-a089c255346b"
		SubscriptionId = "3065ef51-6e69-4ee9-a407-b2cc275f91d6" 
		AutomationAccountName = "rig-manager"
		AutomationResourceGroup = "ftp-rig"
	}

$Headers = @{

}

$isForceRefresh = if ($ForceRefresh) {$true} else {$false}

try{
	New-RigFromTemplate -RigName $RigName -TemplateName $TemplateName -ProjectName $ProjectName -ForceRefresh $isForceRefresh `
		-Servers $Servers -Parameters $Parameters -Headers $Headers
}
catch{
	Write-Error -Message $_.Exception
	$exitCode = 1
}
finally{
	
	
}

$exitCode
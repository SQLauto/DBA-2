#.\Setup-RigTemplates.ps1 -RigName "ftp_template" -AzureAccountPassword "xw/bCW8OmJihls7MBtiCMcy3ikHbFexFFVMZEaOf5Co="
[cmdletbinding()]
param
(
	[parameter(Mandatory=$true)]
	[string]
	$RigName,

	[string]
	$ProjectName = "ftp",

	[parameter(Mandatory=$true)]
	[string]
	$ImagesResourceGroup,
	
	[parameter(Mandatory=$true)]
	[string]
	$AzureAccountPassword
)

$RigName = $RigName -replace '\.','_'

$modulePath = Join-Path $PSScriptRoot "Modules"

if(-not (($env:PSModulePath -split ";") -contains $modulePath))
{
	[Environment]::SetEnvironmentVariable("PSModulePath",  [Environment]::GetEnvironmentVariable("PSModulePath","Machine"))
	$env:PSModulePath = "$modulePath;" + $env:PSModulePath
}

Import-Module TFL.Deployment.Azure -Force -ErrorAction Stop -Verbose

$exitCode = 0
Write-Host "Reading rig_templates.psd1"

$RigData = (Import-LocalizedData -BaseDirectory $PSScriptRoot -FileName "rig_templates.psd1")

$Parameters = @{
	Password = $AzureAccountPassword
	User = "06863203-99bc-49c5-824c-9a5963ae03c9"
	Tenant = "1fbd65bf-5def-4eea-a692-a089c255346b"
	SubscriptionId = "3065ef51-6e69-4ee9-a407-b2cc275f91d6" 
	AutomationAccountName = "rig-manager"
	AutomationResourceGroup = "sso-poc-common"
}

$Headers = @{

}

try{

	$InputObject = @{
		LabName = $RigName
		Servers = $RigData
		ImagesResourceGroup = $ImagesResourceGroup
	}

	if($InputObject.RigData -eq $null)
	{
		$ErrorMessage = "No rig data found."
		throw $ErrorMessage
	}

	Write-Host "Invoking Provision-Base-Templates3 for $($InputObject.LabName)"
    Write-Warning "Please be patient, This action might take little while."
    $exitCode = Invoke-Webhook -Token "P0A2HDP0XBQhvWPJLIXe%2f%2fnXZv6Tnp4ab9Au1mGP3SM%3d" -Parameters $Parameters -InputObject $InputObject -Headers $Headers

	if($exitCode -ne 0)
	{
		$ErrorMessage = "Provision-Base-Templates failed."
		throw $ErrorMessage
	}
}
catch{
	Write-Error -Message $_.Exception
	$exitCode = 1
}
finally{	
	Remove-Module TFL.Deployment.Azure
}

$exitCode
Param(
    [ValidateNotNullOrEmpty()]
    [string]
    $LabName,

	[parameter(Mandatory=$true)]
	[string]
    $AzureAccountPassword
)

$LabName = $LabName -replace '\.','_'

$modulePath = Join-Path $PSScriptRoot "Modules"

[Environment]::SetEnvironmentVariable("PSModulePath",  [Environment]::GetEnvironmentVariable("PSModulePath","Machine"))
$env:PSModulePath = "$modulePath;" + $env:PSModulePath

Import-Module TFL.Deployment.Azure -Force -ErrorAction Stop -Verbose

$exitCode = 0


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
	    Name = $LabName
		ProjectName = "SSO"
	}

	Write-Host "Invoking Update-ProjectDSCConfig...."
	$exitCode = Invoke-Webhook -Token "x%2fGXtJ5KgZnh3KNP4f8EVHs%2fS7aaxd8sHLS61ypIbbw%3d" -Parameters $Parameters -InputObject $InputObject -Headers $Headers
}
catch
{
	Write-Error -Message $_.Exception
	$exitCode = 1
}
finally
{
	Remove-Module TFL.Deployment.Azure
}


$exitCode
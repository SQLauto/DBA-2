[cmdletbinding(DefaultParameterSetName = "Install")]
param
(
	[parameter(Mandatory=$true, Position=0)]
    [string] $ComputerName,
	[parameter(Mandatory=$true, ParameterSetName="Install")]
	[string] $MsiName,
	[parameter(Mandatory=$true, ParameterSetName="ByUpgradeCode")]
	[string] $UpgradeCode,
	[parameter(Mandatory=$true, ParameterSetName="ByProductCode")]
	[string] $ProductCode,
	[string] $DropFolder,
	[string] $DriveLetter = "D"
)

if($PSVersionTable.PSVersion.Major -lt 5) {
	Write-Error "You need to be running powershell 5 as a minimum to run this deployment"
	return 1
}

if([string]::IsNullOrEmpty($DropFolder)){
	$DropFolder = "$($DriveLetter):\Deploy\DropFolder"
}

$deploymentFolder = $PSScriptRoot | Split-Path
$modulePath = Join-Path $PSScriptRoot "Modules"

[Environment]::SetEnvironmentVariable("PSModulePath",  [Environment]::GetEnvironmentVariable("PSModulePath","Machine"))
$env:PSModulePath = "$modulePath;" + $env:PSModulePath

Import-Module TFL.PowerShell.Logging -Force -ErrorAction Stop
Import-Module TFL.Utilities -Force -ErrorAction Stop
Import-Module TFL.Deployment -Force -ErrorAction Stop

function Start-InstallVerification{
[cmdletbinding()]
param()

	$retVal = 0

	$msiPath= Join-Path $DropFolder $MsiName

	if(!(Test-Path $msiPath)){
		throw "The MSI $msiPath was not found. Skipping deployment."
	}

	Write-Host "Inspecting the MSI at $msiPath to extract MSI key."

	$msiKey = Get-MsiKey -Path $msiPath

	Write-Host "Details of inspected source msi file $MsiName"
	Write-Host "`tUpgradeCode: [$($msiKey.UpgradeCodeString)]"
	Write-Host "`tProduct Code: [$($msiKey.ProductCodeString)]"
	Write-Host "`tVersion: [$($msiKey.ProductVersion.ToString())]"
	Write-Host ""

	$func = {
		param([string]$upgradeCode)
		$result = 0
		try{

			Import-Module TFL.Deployment -Force -ErrorAction Stop

			Write-Host "Testing MSI Post deployment:"
			$expectedMsiHasBeenDeployed = Test-IsProductInstalled -UpgradeCode $upgradeCode

			if(!$expectedMsiHasBeenDeployed){
				$retVal = 1
			}
		}
		catch{
			$result = 1
		}


		$result
	}

	if ($local) {
		$retVal = & $func -UpgradeCode $msiKey.UpgradeCodeString
	}
	else {
		$retVal = Invoke-Command -ComputerName $ComputerName -ScriptBlock $func -ArgumentList $msiKey.UpgradeCodeString
	}

	$retVal
}

function Start-UninstallVerification{
[cmdletbinding()]
param()

	$retVal = 0

	$func = {
		param([string]$upgradeCode, [string]$productCode)
		$result = 0
		try{

			Import-Module TFL.Deployment -Force -ErrorAction Stop

			if($upgradeCode){
				Write-Host "Starting Uninstall verification using Upgrade Code $UpgradeCode."
				$productInstalled = Test-IsProductInstalled -UpgradeCode $upgradeCode
			}

			if($productCode){
				Write-Host "Starting Uninstall verification using Product Code $productCode."
				$productInstalled = Test-IsProductInstalled -ProductCode $productCode
			}

			if ($productInstalled) {
				$result = 1
				Write-Host "Product is installed with the specified upgrade/product code"
			}
		}
		catch{
			$result = 1
		}


		$result
	}

	if($PSCmdlet.ParameterSetName -eq "ByUpgradeCode"){
		if ($local) {
			$retVal = & $func -UpgradeCode $UpgradeCode
		}
		else {
			$retVal = Invoke-Command -ComputerName $ComputerName -ScriptBlock $func -ArgumentList $UpgradeCode
		}
	}

	if($PSCmdlet.ParameterSetName -eq "ByProductCode"){
		if ($local) {
			$retVal = & $func -ProductCode $ProductCode
		}
		else {
			$retVal = Invoke-Command -ComputerName $ComputerName -ScriptBlock $func -ArgumentList $ProductCode
		}
	}

	$retVal
}


$exitCode = 0

try{
	if($PSCmdlet.ParameterSetName -eq "Install") {
		$exitCode = Start-InstallVerification
	}
	else{
		$exitCode = Start-UninstallVerification
	}
}
catch{
	Write-Error2 -ErrorRecord $_
	$exitCode = 1
}

Remove-Module TFL.Deployment -ErrorAction Ignore
Remove-Module TFL.PowerShell.Logging -ErrorAction Ignore
Remove-Module TFL.Utilites -ErrorAction Ignore

exit $exitCode
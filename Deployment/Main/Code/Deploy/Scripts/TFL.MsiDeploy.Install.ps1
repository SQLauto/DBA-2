#requires -Version 5.0
[cmdletbinding()]
param([string]$UpgradeCode,[string]$MsiName,[string]$DeploymentPath,[hashtable]$Properties)

Import-Module TFL.Utilities -Force -ErrorAction Stop
Import-Module TFL.Deployment -Force -ErrorAction Stop

$temp = @{
	'Server' = $env:COMPUTERNAME;
	'ExitCode' = 0;
}

try {

	$msiPath= Join-Path $DeploymentPath $MsiName

	if(!(Test-Path $msiPath)){
		throw "The MSI $msiPath was not found. Skipping deployment."
	}

	Write-Host "Inspecting the MSI to extract the MSI keys."

	$msiKey = Get-MsiKey -Path $msiPath

	Write-Host "Details of inspected source msi file $MsiName are as follows:"
	Write-Host "`tUpgradeCode: [$($msiKey.UpgradeCodeString)]"
	Write-Host "`tProduct Code: [$($msiKey.ProductCodeString)]"
	Write-Host "`tVersion: [$($msiKey.ProductVersion.ToString())]"
	Write-Host ""

	#Validate all keys are valid etc, and passed in codes are correct - will throw if anything is incorrect
	Assert-ExpectedMsiKey -MsiKey $msiKey -UpgradeCode $UpgradeCode | Out-Null

	$installedProduct = Get-InstalledProduct -MsiKey $msiKey

	#ensure we are not attempting downgrade
	if($installedProduct.IsDowngrade){
		Write-Warning "You are attempting a downgrade and this is not permitted.  If this is required you must uninstall and then retry the deployment."
		$temp.ExitCode = 1
		return [pscustomobject]$temp
	}

	if($installedProduct.IsInstalled){
		Write-Host "The installer with this version is already installed, MsiExec will not been invoked."
		return [pscustomobject]$temp
	}

	Write-Host "The installer with this version is not installed"

	$installedProducts =  Get-InstalledProducts -UpgradeCode $msiKey.UpgradeCode

	if(!(Test-IsNullOrEmpty $installedProducts)){
		Write-Host "The following product version(s) are already installed:"
		$installedProducts | ForEach-Object {
			Write-Host "`tUpgrade Code: [$($_.Key.UpgradeCodeString)]"
			Write-Host "`tProduct Code: [$($_.Key.ProductCodeString)]"
			Write-Host "`tVersion: [$($_.Key.ProductVersion.ToString())]"
			Write-Host ""
		}
	}

	$propertyString = ""
	$properties.GetEnumerator() | ForEach-Object {
		$propertyString += " $($_.Name)=`"$($_.Value)`""
	}

	$installLog = Join-Path $DeploymentPath "$MsiName.Install.log"
	$command = "cmd /c msiexec.exe --% /i `"$msiPath`" /quiet /l*v `"$installLog`"$propertyString"
	Write-Host "Executing command: '$command'"

	Invoke-Expression -Command $command -ErrorAction Stop | Out-Null

	if($LASTEXITCODE){
		Write-Host "MsiExec last exit code: $LASTEXITCODE"
		if($LASTEXITCODE -eq 1638) {
			Write-Host "ERROR: The most probable reason for this is that the version installed has the same Upgrade Code and Product Code but differs in version number."
			Write-Host "THIS IS NOT ALLOWED FOR A Major Upgrade and only permissible for a minor upgrade (i.e. patch)."
			Write-Host "If this is a major upgrade then you must specify a different product code.  Suggest using '*' in WIX to autogenerate it."
		}
		else{
			Write-Host "ERROR: If the following error was seen it is most probable that the MSI differs by version only and has the same product code as an installation on the deployment server:"
			Write-Host "`t[Another version of this product is already installed. Installation of this version cannot continue.]"
		}

		throw "MsiExec failed with exit code [$LASTEXITCODE]"
	}
}
catch {
	$temp.ExitCode = 1
	$temp.Error = "An error occurred in TFL.MsiDeploy.Install.ps1."
	$temp.ErrorDetail = $_

	$rebootInfo = Get-PendingReboot

	if($rebootInfo.RebootPending){
		$temp.Error = "An error occurred in TFL.MsiDeploy.Install.ps1. Pending reboot detected."
	}

	$temp.LastExitCode = $LASTEXITCODE
	$global:LASTEXITCODE = $null
}

[pscustomobject]$temp
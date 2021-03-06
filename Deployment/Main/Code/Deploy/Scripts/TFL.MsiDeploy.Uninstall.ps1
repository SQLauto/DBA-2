#requires -Version 5.0
[cmdletbinding()]
param([string]$UpgradeCode,[string]$MsiName,[string]$DeploymentPath)

$module = Get-Module -Name TFL.Utilities
if(!$module) {
	Import-Module TFL.Utilities -Force -ErrorAction Stop
}

$module = Get-Module -Name TFL.Deployment
if(!$module) {
	Import-Module TFL.Deployment -Force -ErrorAction Stop
}

$temp = @{
	'Server' = $env:COMPUTERNAME;
	'ExitCode' = 0;
}

try {

	Write-Host "Invoking the uninstaller on $env:COMPUTERNAME"
	Write-Host "Checking for installed product using upgrade code: $UpgradeCode"

	$productInstalled = Test-IsProductInstalled -UpgradeCode $UpgradeCode

	if (!$productInstalled) {
		Write-Host "No installed Product was found with the specified upgrade code. Assuming nothing to uninstall"
	}
	else {
		Write-Host "Product is installed with expected upgrade code."
		$installedProducts = Get-InstalledProducts -UpgradeCode $UpgradeCode

		if(-not (Test-IsNullOrEmpty $installedProducts)) {
			Write-Host "The following product(s) are currently installed:"

			$installedProducts | ForEach-Object {
				Write-Host "`tUpgrade Code: [$($_.Key.UpgradeCodeString)]"
				Write-Host "`tProduct Code: [$($_.Key.ProductCodeString))]"
				Write-Host "`tVersion: [$($_.Key.ProductVersion.ToString())]"
				Write-Host ""
			}

			$installedProducts | ForEach-Object {
				$productCode = $_.Key.ProductCodeString

				Write-Host "Un-installing product using product code $productCode"
				$uninstallLog = Join-Path $DeploymentPath "$MsiName.Uninstall.log"

				$command = "cmd /c msiexec --% /x $productCode /quiet /l*v `"$uninstallLog`""
				Write-Host "Executing command: '$command'"

				Invoke-Expression -Command $command -ErrorAction Stop | Out-Null

				if($LASTEXITCODE -and $LASTEXITCODE -ne 0){
					throw "msiexec failed to remove product $productCode with exit code [$LASTEXITCODE] from uninstall"
				}

				Start-Sleep -s 5 #The installer doesn't always release the lock fast enough which can cause the subsequent install to fail

				$uninstallKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{$ProductCode}"

				if (Test-Path $uninstallKey){
					Write-Host "Deleting registry key post successful uninstall. This is to clean up due to an Microsoft bug. Deleting key: $uninstallKey"
					Remove-Item -Path $uninstallKey -recurse -Force -ErrorAction Stop
					Write-Host "Successfully deleted: $uninstallKey"
				}
			}
	    }
	}
}
catch {
	$temp.ExitCode = 1
	$temp.Error = "An error occurred in TFL.MsiDeploy.Uninstall.ps1."
	$temp.ErrorDetail = $_

	$rebootInfo = Get-PendingReboot

	if($rebootInfo.RebootPending){
		$temp.Error = "An error occurred in TFL.MsiDeploy.Uninstall.ps1. Pending reboot detected."
	}

	$temp.LastExitCode = $LASTEXITCODE
	$global:LASTEXITCODE = $null
}

[pscustomobject]$temp
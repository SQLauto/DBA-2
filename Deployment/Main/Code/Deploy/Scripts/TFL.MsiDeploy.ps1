[cmdletbinding()]
param
(
    [parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ComputerName,
    [parameter(Mandatory=$true)][ValidateNotNull()][Deployment.Domain.Roles.MsiDeploy]$DeployRole,
	[parameter()][string]$MsiAction
)

function Get-InstallerProperties{
param([string]$sourcePath)

	Write-Host "Processing Installer properties."

	$params = @{}

	$names = $DeployRole.Parameters | ForEach-Object {
		$name = $_.Name
		$value = $_.Value

		if($_.Type -eq "passwordparameter"){
			$serviceAccount = Get-ServiceAccount -Path $accountsFile -Password $Password -Account $value
			$value = $serviceAccount.DecryptedPassword
		}
		elseif($_.Type -eq "usernameparameter"){
			$serviceAccount = Get-ServiceAccount -Path $accountsFile -Password $Password -Account $value
			$value = $serviceAccount.Username
		}

		$params.Add($name, $value)

		$name
	}

	Write-Host "Validating Msi Properties from source: $sourcePath"
	$valid = Assert-ValidMsiProperties -Path $sourcePath -Name $names

	if(!$valid){
		Write-Warning "Check the WIX definition as one or more properties appear to be: (a) missing, (b) misspelt or (c) not upper case. FOR A PROPERTY TO BE PUBLIC IT MUST BE UPPER CASE in WIX."
	}

	$params
}

function Start-Uninstallation{
param()

	$retVal = 0

	if($ConfigOnly){return $retVal}

	#if Uninstall or Reinstall, perform the Uninstall
	try{
		$msiName = $DeployRole.Msi.Name
		$upgradeCode = $DeployRole.Msi.UpgradeCode

		$subScriptPath = Join-Path $PSScriptRoot "TFL.MsiDeploy.Uninstall.ps1"

		if (!(Test-Path $subScriptPath)){
			Write-Host2 -Type Failure -Message "Failed to find script '$subScriptPath'"
			$retVal = 1
			return $retVal
		}

		$deploymentPath = "$($DriveLetter):\Deployment"

		if ($local) {
			$output = & $subScriptPath -UpgradeCode $upgradeCode -MsiName $msiName -DeploymentPath $deploymentPath
		}
		else{
			$deploymentPath = "\\$ComputerName\$DriveLetter`$\Deployment"
			$output = Invoke-Command -ComputerName $ComputerName -FilePath $subScriptPath -ArgumentList $upgradeCode,$msiName,$deploymentPath
		}

		$retVal = $output.ExitCode

		$errors = $output | Select-Error

		if($errors){
			Resume-Console
			$errors | Format-List Server, Error, ErrorDetail | Out-String -Stream | Write-Host2 -ForegroundColor Red
			Suspend-Console
		}

		if ($retVal -eq 0) {
			Write-Host2 -Type Success -Message "MSI [$msiName] was successfully uninstalled on $ComputerName"
		}
		else {
			if($output.ErrorDetail){
				Write-Error2 -ErrorRecord $output.ErrorDetail -ErrorMessage $output.Error
			}
			else{
				Write-Error2 $output.Error
			}
			Write-Host2 -Type Failure -Message "Failed to uninstall MSI [$msiName] on $ComputerName"
		}
	}
	catch {
		$retVal = 1
		Write-Error2 -ErrorRecord $_
	}

	$retVal
}

function Start-Installation{
param()

	$retVal = 0

	if($ConfigOnly){return $retVal}

	try{
		$msiName = $DeployRole.Msi.Name
		$upgradeCode = $DeployRole.Msi.UpgradeCode

		$sourcePath = Join-Path $dropFolder $msiName

		if(!(Test-Path $sourcePath)) {
			Write-Host2 -Type Failure -Message "NOT DEPLOYING MSI: Unable to find source MSI $sourcePath"
			$retVal = 1
			return $retVal
		}

		$deploymentPath = "$($DriveLetter):\Deployment"
		if ($local) {
			$targetPath = $deploymentPath
		}
		else{
			$targetPath = "\\$ComputerName\$DriveLetter`$\Deployment"
		}

		$targetFile = Join-Path $targetPath $msiName

		Write-Host "Copying $msiName to $targetPath"
		New-Item $targetPath -ItemType Directory -Force | Out-Null

        #Remove MSI from Target Server First then copy across...
		if(Test-Path $targetFile) {
			Remove-Item -Path $targetFile -Force -ErrorAction stop
			if(Test-Path $targetFile) {
				Write-Host2 -Type Failure -Message "NOT DEPLOYING MSI: Unable to remove msi [$targetFile] from $ComputerName"
				$retVal = 1
				return $retVal
			}
		}

		Copy-Item $sourcePath $targetFile -Force -ErrorAction stop

		if(!(Test-Path $targetFile)) {
			Write-Host2 -Type Failure -Message "NOT DEPLOYING MSI: Unable to copy msi onto $ComputerName from Jump Server"
			$retVal = 1
			return $retVal
		}

		$subScriptPath = Join-Path $PSScriptRoot "TFL.MsiDeploy.Install.ps1"

		if (!(Test-Path $subScriptPath)){
			Write-Host2 -Type Failure -Message "Failed to find script '$subScriptPath'"
			$retVal = 1
			return $retVal
		}

		$properties = Get-InstallerProperties $sourcePath
		Write-Host "Executing script: $subScriptPath with UpgradeCode '$upgradeCode'"

		if ($local) {
			$output = & $subScriptPath -UpgradeCode $upgradeCode -MsiName $msiName -DeploymentPath $deploymentPath -Properties $properties
		}
		else {
			$output = Invoke-Command -ComputerName $ComputerName -FilePath $subScriptPath -ArgumentList $upgradeCode,$msiName,$deploymentPath,$properties
		}

		$retVal = $output.ExitCode

		$errors = $output | Select-Error

		if($errors){
			Resume-Console
			$errors | Format-List Server, Error, ErrorDetail | Out-String -Stream | Write-Host2 -ForegroundColor Red
			Suspend-Console
		}

		if ($retVal -eq 0) {
			Write-Host2 -Type Success -Message "MSI [$msiName] was successfully installed on $ComputerName"
		}
		else {
			Write-Host2 -Type Failure -Message "Failed to install MSI [$msiName] on $ComputerName"
		}
	}
	catch{
		$retVal = 1
		Resume-Console
		Write-Error2 -ErrorRecord $_
		Suspend-Console
	}

	$retVal
}

function Update-Configurations{
param()

	$retVal = 0

	try{
		Write-Host "Processing $($DeployRole.Configs.Count) config file(s)"

		$results = $DeployRole.Configs | ForEach-Object {

			$configItem = $_

			$targetPath = "\\$ComputerName\$DriveLetter`$\$($configItem.Target)"

			$parameters = @{
				DefaultConfig = $baseConfig
				OverrideConfig = $DeployRole.Configuration
				PackagePath = $dropFolder
				DropFolder = $dropFolder
				TargetPath = $targetPath
				TargetFile = $configItem.Name
				Environment = $environment
				RigName = $RigName
				RigConfigFile = $RigConfigFile
			}

			Write-Host "Updating configuration file '$($configItem.RelativePath)' with parameters:"
			$parameters | Format-List | Out-String -stream | Write-Host

			#if there are errors in method, function writes out to error stream and will return false
			#As errors are on stream, there is no need to rethrow.
			Update-ApplicationConfigFile @parameters
		}

		if($results -contains $false){
			$retVal = 1
		}
	}
	catch {
		 Write-Error2 -ErrorRecord $_
		 $retVal = 1
	}

	$retVal
}

$result = 0

if($ConfigOnly) {
	$baseString = "role $DeployRole (ConfigOnly) on $ComputerName."
}
else{
	$baseString = "role $DeployRole on $ComputerName."
}

Write-Host ""
Write-Header "Starting $baseString" -AsSubHeader

$timer = [Diagnostics.Stopwatch]::StartNew()
$local = $ComputerName -in $env:computername,"localhost"

try {

	if(!$MsiAction){
		$MsiAction = $DeployRole.Action.ToString();
	}

	switch($MsiAction){
		"Uninstall" {$result = Start-Uninstallation}
		"Install" {$result = Invoke-UntilFail {Start-Installation},{Update-Configurations}}
		"Reinstall" {$result = Invoke-UntilFail {Start-Uninstallation},{Start-Installation},{Update-Configurations}}
	}
}
catch [System.Exception] {
	$result = 1
	Write-Error2 -ErrorRecord $_
}

$timer.Stop()

$SummaryLog | Write-Summary -Message "running $baseString" -Elapsed $timer.Elapsed -ScriptResult $result
Write-Header "Ending $baseString" -AsSubHeader

$result
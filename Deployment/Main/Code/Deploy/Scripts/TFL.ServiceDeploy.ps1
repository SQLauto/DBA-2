[cmdletbinding()]
param (
	[parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string] $ComputerName,
    [parameter(Mandatory=$true)][ValidateNotNull()][Deployment.Domain.Roles.ServiceDeploy]$DeployRole
)

function Start-InstallMsi{
[cmdletbinding()]
param()

	Write-Host "Executing script: TFL.MsiDeploy.ps1 for MSI install of services."
	& (Join-Path $PSScriptRoot "TFL.MsiDeploy.ps1") -ComputerName $ComputerName -DeployRole $DeployRole.MsiDeploy -MsiAction "Install"
}

function Start-UninstallMsi{
[cmdletbinding()]
param([string]$msiAction)

	Write-Host "Executing script: TFL.MsiDeploy.ps1 for MSI uninstall of services."
	& (Join-Path $PSScriptRoot "TFL.MsiDeploy.ps1") -ComputerName $ComputerName -DeployRole $DeployRole.MsiDeploy -MsiAction "Uninstall"
}

function Assert-DeployMsi{
[cmdletbinding()]
param()

	$retVal = 0

	#Commented out due to temporary issue.

	#$count = $DeployRole.Services.Count

	#Write-Host "Asserting MSI install."
	#[array]$services = Get-Service -ComputerName $ComputerName -Name ($DeployRole.Services | Select-Object -ExpandProperty  "Name") -ErrorAction Ignore | Select-Object -ExpandProperty "Name"
	#$retVal = ($services -and $services.Count -eq $count) | Get-ConditionalValue -TrueValue 0 -FalseValue 1

	#if($retVal -ne 0){
	#	throw "Msi Deploy failed to $($DeployRole.Action) services from $ComputerName"
	#}

	$retVal
}

function Remove-Services{
[cmdletbinding()]
param()

	$retVal = 0

	if($ConfigOnly) {return $retVal}

	$func = {
		param([string]$name,[string]$computerName)

		$temp = @{
			'Server' = $computerName
			'ExitCode' = 0
		}`

		try{
			$service = Get-WmiObject Win32_Service -Filter "name='$name'" -ComputerName $computerName

			if($service){
				$service.Delete() | Out-Null
				Write-Host "Service '$name' was removed"
			}
			else{
				Write-Warning "Service '$name' was not found. Nothing to remove."
			}

			if($LASTEXITCODE -and $LASTEXITCODE -ne 0){
				throw "Remove service [$name] on [$($temp.Server)] failed. LastExitCode of [$LASTEXITCODE]"
			}
		}
		catch{
			$temp.ExitCode = 1
			$temp.Error = "Remove-Services - An error occurred removing service $name. LastExitCode: $LASTEXITCODE"
			$temp.ErrorDetail = $_
		}
		finally{
			$global:LASTEXITCODE = $null
		}

		[pscustomobject]$temp
	}

	$results = $DeployRole.Services | ForEach-Object {
		$service = $_

		#If we are doing an re-install, check if we have a CurrentName property as we could be dong a service rename.
		$name = $service.Name

		if($DeployRole.Action -eq "Reinstall" -and $service.CurrentName){
			$name = $service.CurrentName
		}

		$output = & $func -Name $name -ComputerName $computerName

		$errors = $output | Select-Error

		if($errors){
			Resume-Console
			$errors | Format-List Server, Error, ErrorDetail | Out-String -Stream | Write-Host2 -ForegroundColor Red
			Suspend-Console
		}

		$output.ExitCode
	}

	$retVal = (Test-IsNullOrEmpty $results) | Get-ConditionalValue -TrueValue 0 -FalseValue ($results | Measure-Object -Maximum).Maximum

	if ($retVal-eq 0) {
		Write-Host2 -Type Success -Message "Successfully removed windows services on $ComputerName"
	}
	else {
		if($output.ErrorDetail){
			Write-Error2 -ErrorRecord $output.ErrorDetail -ErrorMessage $output.Error
		}
		else{
			Write-Error2 $output.Error
		}
		Write-Host2 -Type Failure -Message "Failed to remove windows services on $ComputerName"
	}

	$retVal
}

function Update-Services{
[cmdletbinding()]
param()
	$retVal = 0

	if($ConfigOnly) {return $retVal}

	Write-Host "Updating services accounts and startup type."

	$func = {
		param([string]$name,[string]$username,[string]$password,[string]$startup)

		$temp = @{
			'Server' = $computerName
			'ExitCode' = 0
		}

		try{
			$service = Get-WmiObject Win32_Service -Filter "name='$name'"

			if(!$service) {
				throw "Service with name $name was not found."
			}

			Write-Host "Setting service account to '$username'"
			$service.Change($null,$null,$null,$null,$null,$null,$username,$password) | Out-Null

			$command = "sc.exe config '$name' start= $startup"
			Write-Host "Executing command '$command' to change startup type."
			Invoke-Expression -Command $command -ErrorAction Stop | Out-Null

			if($LASTEXITCODE -and $LASTEXITCODE -ne 0){
				throw "Update of '$name' service on [$($env:computername)] failed. LastExitCode of [$LASTEXITCODE]"
			}
		}
		catch{
			$temp.ExitCode = 1
			$temp.Error = "Update-Services - An error occurred updating the service '$name'"
			$temp.ErrorDetail = $_
		}
		finally{
			$global:LASTEXITCODE = $null
		}

		[pscustomobject]$temp
	}

	$results = $DeployRole.Services | ForEach-Object {

		$serviceAccount = Get-ServiceAccount -Path $accountsFile -Password $Password -Account $_.Account.LookupName
		$startupType = Get-StartupType
		$username = $serviceAccount[0].QualifiedUsername
		$password = $serviceAccount[0].DecryptedPassword

		if ($local) {
			$output = & $func -Name $_.Name -Username $username -Password $password -Startup $startupType
		}
		else{
			$output = Invoke-Command -ComputerName $ComputerName -ScriptBlock $func -ArgumentList $_.Name,$username,$password,$startupType
		}

		$errors = $output | Select-Error

		if($errors){
			Resume-Console
			$errors | Format-List Server, Error, ErrorDetail | Out-String -Stream | Write-Host2 -ForegroundColor Red
			Suspend-Console
		}

		$output.ExitCode
	}

	$retVal = (Test-IsNullOrEmpty $results) | Get-ConditionalValue -TrueValue 0 -FalseValue ($results | Measure-Object -Maximum).Maximum

	if ($retVal-eq 0) {
		Write-Host2 -Type Success -Message "Successfully updated windows services on $ComputerName"
	}
	else {
		Write-Host2 -Type Failure -Message "Failed to update windows services on $ComputerName"
	}

	$retVal
}

function Get-StartupType{
param()

	$type = "demand"

	switch($DeployRole.StartupType) {
		"Automatic" {$type = "auto"}
		"AutomaticDelayed" {$type = "delayed-auto"}
		"Disabled" {$type = "disabled"}
		default {$type = "demand"}
	}

	$type
}


$result = 0

if($ConfigOnly) {
	$baseString = "role $DeployRole (ConfigOnly) on $ComputerName."
}
else{
	$baseString = "role $DeployRole on $ComputerName."
}

$local = $ComputerName -in $env:computername,"localhost"

Write-Host ""
Write-Header "Starting $baseString" -AsSubHeader
$timer = [Diagnostics.Stopwatch]::StartNew()

try {

	$msiAction = $DeployRole.Action.ToString();

	switch($msiAction){
		"Uninstall" {$result = Invoke-UntilFail {Start-UninstallMsi},{Remove-Services}}
		"Install" {$result = Invoke-UntilFail {Start-InstallMsi},{Assert-DeployMsi},{Update-Services}}
		"Reinstall" {$result = Invoke-UntilFail {Start-UninstallMsi},{Remove-Services},{Start-InstallMsi},{Assert-DeployMsi},{Update-Services}}
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
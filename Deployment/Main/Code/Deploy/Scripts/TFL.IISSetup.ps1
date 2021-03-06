[cmdletbinding()]
param
(
	[parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()][string]$ComputerName,
	[parameter(Mandatory=$true)]
	[ValidateNotNull()]
    [Deployment.Domain.Roles.IisSetupDeploy]$DeployRole
)

function Install-WebDeploy{
[cmdletbinding()]
param()

	$retVal = 0

	$installLog = "$($DriveLetter):\Deployment\WebDeployInstall.log"
	try{
		Write-Host "Copy WebDeploy Installer onto $ComputerName"
		New-Item \\$ComputerName\$DriveLetter`$\Deployment -ItemType Directory -Force | Out-Null
		Copy-Item "$commonSoftwarePath\WebDeploy_3_0_amd64_en-US.msi" "\\$ComputerName\$DriveLetter`$\Deployment\WebDeploy_3_0_amd64_en-US.msi" -Force #-Verbose

		$retVal = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
			param($installLog, $DriveLetter)
			$result = 0
			try{

				$exits = Test-Path "$($DriveLetter):\Deployment\WebDeploy_3_0_amd64_en-US.msi"

				if(!$exits){
					$result = 2
					Write-Warning "MSI file WebDeploy_3_0_amd64_en-US.msi not found on target server."
					return $result
				}

				$command = "cmd /c msiexec /i $($DriveLetter):\Deployment\WebDeploy_3_0_amd64_en-US.msi /quiet /log $installLog"
				Write-Host "About to execute command $command"

				Invoke-Expression -Command $command | Out-Null  #-ErrorAction Stop

				if($LASTEXITCODE -and $LASTEXITCODE -ne 0){
					$result = 1
				}
			}
			catch{
				$result = 1
			}

			$result
		} -ArgumentList $installLog, $DriveLetter
	}
	catch{
		$retVal = 1
	}

	switch ($retVal) {
		0 {
			Write-Host2 -Type Success -Message "WebDeploy msi was installed successfully. See $installLog on $ComputerName"
		}
		1 {
			Write-Host2 -Type Failure -Message "WebDeploy msi was unsuccessfully installed, exited with error code $retVal. See $installLog on $ComputerName"
		}
		2 {
			Write-Host2 -Type Failure -Message "WebDeploy msi was unsuccessfully installed, exited with error code $retVal. MSI not found."
		}
	}

	$retVal
}

function Register-AspNet{
[cmdletbinding()]
param()

	$retVal = 0

	try{
		Write-Host  "Registering ASP.NET on IIS"
		$retVal = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
			$result = 0
			try{

				$command = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe -i"
				Write-Host "About to execute command $command"

				Invoke-Expression -Command $command | Out-Null  #-ErrorAction Stop

				if($LASTEXITCODE -and $LASTEXITCODE -ne 0){
					$result = 1
				}
			}
			catch{
				$result = 1
			}

			$result
		}
	}
	catch{
		$retVal = 1
	}

	if($retVal -ne 0){
		Write-Host2 -Type Failure -Message "aspnet_regiis exited with error code $retVal"
	}
	else{
		Write-Host2 -Type Success -Message "aspnet_regiis was successfully configured."
	}

	$retVal
}

function Start-Services{
[cmdletbinding()]
param()

	$retVal = 0
	try{
		$retVal = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
			$result = 0
			try{
				Write-Host "Starting service "W3SVC". If service is already started, nothing will happen."
				Get-Service -Name "W3SVC" -ErrorAction Stop | Where-Object {$_.status -eq "stopped"} | Start-Service -ErrorAction Stop | Out-Null
				#Wait for upto 10 secs for service to come up
				Get-Service -Name "W3SVC" | ForEach-Object { $_.WaitForStatus('Running', '00:00:10') | Out-Null }

				Write-Host "Starting service "WMSVC". If service is already started, nothing will happen."
				$service = Get-Service -Name "WMSVC" -ErrorAction Ignore

				if($service){
					$service | Where-Object {$_.status -eq "stopped"} | Start-Service -ErrorAction Stop | Out-Null
					#Wait for upto 10 secs for service to come up
					Get-Service -Name "WMSVC" | ForEach-Object { $_.WaitForStatus('Running', '00:00:10') | Out-Null }
				}
				else{
					Write-Warning "Service WMSVC was not found on computer $env:COMPUTERNAME"
				}

				if($LASTEXITCODE -and $LASTEXITCODE -ne 0){
					$result = 1
				}
			}
			catch{
				$result = 1
			}

			$result
		}
	}
	catch{
		Write-Error "Error getting or starting service W3SVC on computer $env:COMPUTERNAME"
		$retVal = 1
	}

	if($retVal -ne 0){
		Write-Host2 -Type Failure -Message "WWW Publishing and IIS Management services were unsuccessfully started: $retVal"
	}
	else{
		Write-Host2 -Type Success -Message "WWW Publishing and IIS Management services were successfully started"
	}

	$retVal
}

$result = 0

Write-Host ""
Write-Header "Starting role $DeployRole on $ComputerName." -AsSubHeader
$timer = [Diagnostics.Stopwatch]::StartNew()

try
{
	$result = Invoke-UntilFail {Install-WebDeploy},{Register-AspNet},{Start-Services}
}
catch [System.Exception]
{
	Write-Error2 -ErrorRecord $_
	$result = 1
}

$timer.Stop()

$SummaryLog | Write-Summary -Message "running role $DeployRole on $ComputerName."  -Elapsed $timer.Elapsed -ScriptResult $result
Write-Header "Ending role $DeployRole on $ComputerName" -AsSubHeader

$result
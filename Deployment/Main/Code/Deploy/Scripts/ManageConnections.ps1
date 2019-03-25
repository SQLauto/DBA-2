<#
.SYNOPSIS

#>

[cmdletbinding()]
param
(
	[parameter(Mandatory=$true, Position=0)]
	[ValidateNotNullOrEmpty()]
    [Alias("AppName")]
	[string] $RigName,
	[securestring] $Password,
	[string] $DeploymentAccountName		= "FAELAB\TFSBuild",
    [string] $DeploymentAccountPassword	= "vIgxmg6jvCDA1nUHWi8Xzw==",
	[switch] $Open
)

if($PSVersionTable.PSVersion.Major -lt 5) {
	Write-Error "You need to be running powershell 5 as a minimum to run this deployment"
	return 1
}

$modulePath = Join-Path $PSScriptRoot "Modules"
[Environment]::SetEnvironmentVariable("PSModulePath",  [Environment]::GetEnvironmentVariable("PSModulePath","Machine"))
$env:PSModulePath = "$modulePath;" + $env:PSModulePath

Import-Module TFL.PowerShell.Logging -Force -ErrorAction Stop
Import-Module TFL.Utilities -Force -ErrorAction Stop
Import-Module TFL.Deployment -Force -ErrorAction Stop

function Invoke-NewMappedDrive {
param (
    [string]$IpAddress,
    [string]$Machine,
	[Management.Automation.PSCredential]$Credential
)
	$result = $false
	$accountName = $Credential.UserName

	Write-Host "Caching credentials to $Machine : net use \\$IpAddress /user:$accountName <pwd>"
    $result = New-MappedDrive -ComputerName $Machine -ComputerIpAddress $IpAddress -ShareName "D$" -Credential $Credential
	
	$result
}

function Invoke-RemoveMappedDrive {
param (
    [string]$IpAddress,
    [string]$Machine
)
	$result = $false
	
	Write-Host "Clearing up mapped net used drives."
    $result = Remove-MappedDrive -ComputerName $Machine -ComputerIpAddress $IpAddress -ShareName "D$"
	
	$result
}

function Get-StartingState{
[cmdletbinding()]
param([string]$Name)

	Write-Host "Getting status of Rig $Name from VCloud."

	try {

		$script:vApp = Get-VApp -Name $Name

		$vAppStartingState = @{
			Exists    = $false
			Deployed = $false
			State    = $null
		}

		if($vApp){
			$isDeployed = $vApp.IsDeployed()
			$state = $vApp| Get-AppStatusString

			$vAppStartingState.Exists = $true
			$vAppStartingState.Deployed = $isDeployed
			$vAppStartingState.State = $state
		}
	}
	catch {
        Write-Error2 -ErrorRecord $_
	}

	$retVal = (New-Object PSObject -Property $vAppStartingState)

	Write-Host "Exists: $($retVal.Exists)"
	Write-Host "Deployed: $($retVal.Deployed)"
	Write-Host "State: $($retVal.State)"

	$retVal
}

function Open-TestingConnections{
	[cmdletbinding()]
	param()

	$retVal = 0
	
	try
	{
		$success = $true
		$secureDeployAccountPW = Unprotect-Password -Password $Password -Value $DeploymentAccountPassword -AsSecureString
		$deploymentCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $DeploymentAccountName, $secureDeployAccountPW

		Push-Location (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent)
		
		$fileName = "Rigmanifest.xml"

		$file = Get-ChildItem . | where {$_.Name -eq $fileName}

		if($file)
		{
			Write-Host "$fileName file found."
			[xml]$xml = Get-Content $fileName
			$xml.machines.machine | where {$_.name -ne ""} | ForEach-Object {
				$loopCount = 0			
					Do{
						$success = Invoke-NewMappedDrive -IpAddress $_.ipv4address -Machine $_.name -Credential $deploymentCredentials
				
						if(!$success){
							Write-Warning ("Attemping to remove connection to machine " + $_.name + ". Retrying - Attempt $loopCount")
							Start-Sleep -Seconds 12
						}
				
						$loopCount++
					}While($loopCount -lt 10 -and $success -eq $false)
		
			}
		}
		else
		{
			Write-Host "Rigmanifest.xml file not found."
			$success = $false
		}

		if(!$success){
			$retVal = 1
			Write-Error "### Failed to Remove mapped Network drives. ###"
		}
		else {
			Write-Host "### Net use connections have been closed. ###"
		}
	}finally{
		Pop-Location
	}

	return $retVal
}


function Close-TestingConnections{
	[cmdletbinding()]
	param()

	$retval = 0
	
	try
	{
		$success = $true
		Push-Location (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent)

		$fileName = "Rigmanifest.xml"

		$file = Get-ChildItem . | where {$_.Name -eq $fileName}

		if($file)
		{
			Write-Host "$fileName file found."
			[xml]$xml = Get-Content $fileName
		
			$xml.machines.machine | where {$_.name -ne ""} | ForEach-Object {
				$loopCount = 0			
					Do{
						$success = Invoke-RemoveMappedDrive -IpAddress $_.ipv4address -Machine $_.name
				
						if(!$success){
							Write-Warning ("Attemping to remove connection to machine " + $_.name + ". Retrying - Attempt $loopCount")
							Start-Sleep -Seconds 12
						}
				
						$loopCount++
					}While($loopCount -lt 10 -and $success -eq $false)
		
			}
		}		

		if(!$success){
			$retVal = 1
			Write-Error "### Failed to Remove mapped Network drives. ###"
		}
		else {
			Write-Host "### Net use connections have been closed. ###"
		}
	}finally{
		Pop-Location
	}

	return $retval
}

$exitCode = 0

try{
	if($Open){
		$exitCode = Open-TestingConnections
	}
	else{
		$exitCode = Close-TestingConnections
	}
}
catch{
	Write-Error2 -ErrorRecord $_
	$exitCode = 1
}
finally{
	
}

Remove-Module TFL.Deployment -ErrorAction Ignore
Remove-Module TFL.PowerShell.Logging -ErrorAction Ignore
Remove-Module TFL.Utilites -ErrorAction Ignore

$exitCode
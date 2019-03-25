<#
.SYNOPSIS

#>

[cmdletbinding()]
param
(
	[parameter(Mandatory=$true, Position=0)]
	[ValidateNotNullOrEmpty()]
    [Alias("vAppName")]
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
Import-Module TFL.Deployment.Database -Force -ErrorAction Stop
Import-Module TFL.Deployment.VCloud -Force -ErrorAction Stop

function Invoke-NewMappedDrive {
param (
    [string]$IpAddress,
    [string]$Machine,
	[Management.Automation.PSCredential]$Credential
)
	$result = $false
	
	Write-Host "Caching credentials to $Machine : net use \\$IpAddress /user:faelab\tfsbuild <pwd>"
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
	
	Write-Host ""
	Write-Host "### Opening Net Use Connections for Acceptance Testing on $RigName ###"
	$vAppStartingState = Get-StartingState -Name $RigName

	if(!$vAppStartingState.Exists){
		Write-Warning "Rig $RigName is not in a valid state and connections cannot be opened. Exiting."
		return 1
	}

	if(!$vAppStartingState.Deployed){
		Write-Warning "Rig $RigName is not in a valid state and connections cannot be opened. Exiting."
		return 1
	}

	$success = $true
	$secureDeployAccountPW = Unprotect-Password -Password $Password -Value $DeploymentAccountPassword -AsSecureString
	$deploymentCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $DeploymentAccountName, $secureDeployAccountPW

	$machines = $script:vApp.GetChildrenVms();

	$machines | ForEach-Object {
		$loopCount = 0
		if($_.Reference.name -ne "FAEADG001") {
			$ipAddress = Get-VAppExternalIP -VApp $script:vApp -ComputerName $_.Reference.name

			do{
				$success = Invoke-NewMappedDrive -IpAddress $ipAddress -Machine $_.Reference.name -Credential $deploymentCredentials

				if(!$success){
					Write-Warning ("Attemping to connect to machine " + $_.Reference.name + ". Retrying - Attempt $loopCount")
					Start-Sleep -Seconds 12
				}
				
				$loopCount++
			}While($loopCount -lt 10 -and $success -eq $false)
		}
	}

	if(!$success){
		$retVal = 1
		Write-Error "### Failed to Map Network drives. ###"
	}
	else {
		Write-Host "### Net use connections have been opened.###"
	}

	return $retVal
}

function Close-TestingConnections{
	[cmdletbinding()]
	param()

	$retval = 0
	
	Write-Host ""
	Write-Host "### Closing Net Use Connections for Acceptance Testing on $RigName ###"

	$vAppStartingState = Get-StartingState -Name $RigName

	if(!$vAppStartingState.Exists){
		Write-Warning "Rig $RigName is not in a valid state and connections cannot be closed. Exiting."
		return 1
	}
	if(!$vAppStartingState.Deployed){
		Write-Warning "Rig $RigName is not in a valid state and connections cannot be closed. Exiting."
		return 1
	}

	$success = $true
	

	$machines = $script:vApp.GetChildrenVms();

	$machines | ForEach-Object {
		$loopCount = 0
		if($_.Reference.name -ne "FAEADG001") {
			$ipAddress = Get-VAppExternalIP -VApp $script:vApp -ComputerName $_.Reference.name
			
			Do{
				$success = Invoke-RemoveMappedDrive -IpAddress $ipAddress -Machine $_.Reference.name
				
				if(!$success){
					Write-Warning ("Attemping to remove connection to machine " + $_.Reference.name + ". Retrying - Attempt $loopCount")
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
	

	return $retval
}

$exitCode = 0

$vCloudPassword = ConvertTo-SecureString "P0wer5hell" -AsPlainText -Force
$vCloudParams = @{
	Url = "https://vcloud.onelondon.tfl.local"
	Organisation = "ce_organisation_td"
	Username = "zSVCCEVcloudBuild"
	Password = $vCloudPassword
}

Write-Host "Loading VCloudService and Creating connection to $($vCloudParams.Url). Org: $($vCloudParams.Organisation)"
$vCloud = Connect-VCloud @vCloudParams

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
	Write-Host "Closing vCloud connection."
	$vCloud | Disconnect-VCloud
}

Remove-Module TFL.Deployment.VCloud -ErrorAction Ignore
Remove-Module TFL.Deployment -ErrorAction Ignore
Remove-Module TFL.Deployment.Database -ErrorAction Ignore
Remove-Module TFL.PowerShell.Logging -ErrorAction Ignore
Remove-Module TFL.Utilites -ErrorAction Ignore

$exitCode
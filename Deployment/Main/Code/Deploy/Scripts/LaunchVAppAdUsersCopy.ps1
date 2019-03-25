<#
.SYNOPSIS
	Makes a copy of an Active Directory Account on a rig using the deployment server
.PARAMETER Password
    The password used to decrypt service account info.
.PARAMETER RigName
    The name of the the rig used when carrying out a rig deployment.
.PARAMETER DeploymentAccountName
    The name of the deployment partition used if doing blue/green deployments. Acts as a sub-set of machines

#>
param
(
	[parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string]$RigName,
	[parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string]$Password, # accounts decryption key
	[parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string]$AccountNameToCopy,
	[parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string]$NewAccountName,
	[parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string]$DisplayAccountName,
	[string]$NewPassword,
	
	[string]$DeploymentAccountName		= "FAELAB\TFSBuild",
	[string]$DeploymentAccountPassword	= "vIgxmg6jvCDA1nUHWi8Xzw==",
	[string]$DeploymentServerName		= "TS-DB1",
	[string]$DeploymentServerIP,
	[string]$Environment				= "Baseline"

)

if($PSVersionTable.PSVersion.Major -lt 5) {
	Write-Error "You need to be running powershell 5 as a minimum to run this deployment"
	return 1
}

$modulePath = Join-Path $PSScriptRoot "Modules"
[Environment]::SetEnvironmentVariable("PSModulePath",  [Environment]::GetEnvironmentVariable("PSModulePath","Machine"))
$env:PSModulePath = "$modulePath;" + $env:PSModulePath

Import-Module TFL.PowerShell.Logging -Force
Import-Module TFL.Deployment.VCloud -Force -ErrorAction Stop
Import-Module TFL.Utilities -Force -ErrorAction Stop


function Get-DeploymentMachineIP{
[cmdletbinding()]
param()

	$machineIpAddress = $null

	if($RigName){

		Write-Host "Rig name was passed in. Getting IP address of deployment machine from VCloud."

		try {
			Write-Host "Getting IP address of server $DeploymentServerName"

			Write-Host "Deployment machine IP address not set. Getting from VCloud."
			$vCloudPassword = ConvertTo-SecureString "P0wer5hell" -AsPlainText -Force
			$vCloudParams = @{
				Url = "https://vcloud.onelondon.tfl.local"
				Organisation = "ce_organisation_td"
				Username = "zSVCCEVcloudBuild"
				Password = $vCloudPassword
			}

			$vCloud = Connect-VCloud @vCloudParams
			$vApp = Get-VApp -Name $RigName

			Write-Host "Getting VApp Deployment Server IP"
			$machineIpAddress = $vApp | Get-VAppExternalIP -ComputerName $DeploymentServerName
			$env:DeployMachineIP = $machineIpAddress
			$vCloud | Disconnect-VCloud
		}
		catch {
			Write-Host "Error getting machine ip from vCloud for vApp '$RigName' for machine '$DeploymentServerName'." -LastException $_.Exception.Message
			return $null
		}
	}

	(($machineIpAddress -eq $null) | Get-ConditionalValue -TrueValue $DeploymentServerIP -FalseValue $machineIpAddress)
}


function Start-Setup {
param()

	$retVal = 0

	Write-Header "Starting LaunchVAppAdUsersCopy" -AsSubHeader
	Write-Host ""
    Write-Host "Arguments"
    Write-Host "`tRigName: $RigName";
	Write-Host "`tDeploymentAccountName: $DeploymentAccountName";
	Write-Host "`tDeploymentServerName: $DeploymentServerName";
	Write-Host "`tDeploymentServerIP: $DeploymentServerIP";
	Write-Host "`tEnvironment: $Environment";
	Write-Host "`tAccountNameToCopy: $AccountNameToCopy";
	Write-Host "`tNewAccountName: $NewAccountName";
	Write-Host "`tDisplayAccountName: $DisplayAccountName";
	Write-Host "`tNewPassword: $NewPassword"
    Write-Host ""

	$script:deploymentMachineIP = Get-DeploymentMachineIP

	if(!$deploymentMachineIP) {
		Write-Host "No Deployment Machine IP identified. Check config has a Deployment ServerRole."
		$retVal = 5
		return $retVal
	}

	Write-Host "Deployment Machine ($DeploymentServerName) IP Address: $script:deploymentMachineIP"

	$retVal
}



function Start-VAppCopyADUser{

	$retVal	= 0
	$adminAccountName = "FAELAB\TFSAdmin"
	[secureString] $secureAdminAccountPW = ConvertTo-SecureString "LMTF`$Adm1n" -AsPlainText -Force

	$rootPath = "D:\Deploy"
	$logPath = Join-Path $rootPath "Logs"
	$scriptsFolder = Join-Path $rootPath "DropFolder\Deployment\Scripts"

	Write-Host "Starting to copy AD user"

	# Use TFSBuild password if a new password hasn't been supplied
	if (!$NewPassword){
		Write-Host "Setting default password for new AD account as none was supplied"
		[securestring] $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
		$secureDeployAccountPW = Unprotect-Password -Password $securePassword -Value $DeploymentAccountPassword -AsSecureString
		$NewPassword = ConvertTo-String -Value $secureDeployAccountPW
	}

	$command = ("Push-Location $scriptsFolder; .\VAppAdUsersCopy.ps1" +
				" -AccountNameToCopy '$AccountNameToCopy'" +
				" -NewAccountName '$NewAccountName' " +
				" -DisplayAccountName '$DisplayAccountName' " +
				" -NewPassword '$NewPassword' " + 
				" -Enabled 1")
		
	Write-Host "Executing command:"
	Write-Host $command
	Write-Host ""

	# Establish Admin credentials to run this script
	$adminCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminAccountName,$secureAdminAccountPW
	$scriptToExecute = [scriptblock]::Create($command)
	Invoke-Command -ComputerName $script:deploymentMachineIP -Script $scriptToExecute -Credential $adminCredentials -Authentication Credssp -OutVariable result | Out-String -Stream | ? {!($_ -as [int])} | Write-Host

	if($result -gt 0){
		Write-Host "Failed: VAppAdUsersCopy returned with result $result. Failing copy."
		$retVal = 14
	}
	else{
		Write-Host2 -Type Success -Message "VAppAdUsersCopy.ps1 returned with result $result. AD user account copied successfully."
	}

	$retVal
}


$exitCode = 0

try{
	$exitCode = Invoke-UntilFail {Start-Setup},{Start-VAppCopyADUser}
}
catch{
	Write-Error2 -ErrorRecord $_
	$exitCode = 1
}


Remove-Module TFL.PowerShell.Logging
Remove-Module TFL.Deployment.VCloud
Remove-Module TFL.Utilities

$exitCode
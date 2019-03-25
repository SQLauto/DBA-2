#Requires -Version 5.0

<#
.SYNOPSIS
	Initialises the Deployment on a vCloud vApp
.PARAMETER DeploymentConfig
    The name of the deployment configuration file used to drive the deployment.
.PARAMETER Password
    The password used to decrypt service account info.
.PARAMETER DropFolder
    The name of the folder containing the built code artefacts.
.PARAMETER RigName
    The name of the the rig used when carrying out a rig deployment.
.PARAMETER PackageName
    The name of the package used when carrying out a rig deployment.
.PARAMETER DeploymentAccountName
    The name of the deployment partition used if doing blue/green deployments. Acts as a sub-set of machines


.PARAMETER ConfigOnly
    Switch to indicate if a configuration only deployment should be carried out.
.PARAMETER $EnableRemoting
    Switch to determine if remoting should be enabled on target machines
.PARAMETER SingleThreaded
    Switch to set for synchronous deployments. If not set, then default will be multithreaded. It will use Processor count to determine the number of threads to use
#>
[cmdletbinding()]
param
(
	[parameter(Mandatory=$true, Position=0)]
	[ValidateNotNullOrEmpty()]
	[string]$DeploymentConfig,
	[parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string]$DropFolder,
	[parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string]$EnvironmentType,
	[parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string]$RigName,
	[parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string]$PackageName,
	[parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[securestring]$Password, # accounts decryption key
	[string]$DeploymentAccountName		= "FAELAB\TFSBuild",
	[string]$DeploymentAccountPassword	= "vIgxmg6jvCDA1nUHWi8Xzw==",
	[string]$DeploymentServerName		= "TS-DB1",
	[string]$DeploymentServerIP,
	[string]$Environment				= "Baseline",
	[string]$Groups,
	[string]$Machines,
	[ValidateSet('C','D')]
	[string]$DriveLetter = "D",
	[switch]$EnableRemoting,
	[switch]$SkipFileCopy,
	[switch]$ConfigOnly,
	[switch]$SingleThreaded,
	[switch]$GetFileVersions,
	[string]$RigConfigFile = "",
	[string]$BuildNumber
)

$modulePath = Join-Path $PSScriptRoot "Modules"

[Environment]::SetEnvironmentVariable("PSModulePath",  [Environment]::GetEnvironmentVariable("PSModulePath","Machine"))
$env:PSModulePath = "$modulePath;" + $env:PSModulePath

Import-Module TFL.PowerShell.Logging -Force
Import-Module TFL.Utilities -Force -ErrorAction Stop

function Write-ErrorDeploymentLog{
param(
	[int]$ErrorCode,
	[string]$LastError,
	[string]$LastException,
	[string]$EventId = "EndSetupDeployment"
)

	$retVal = $ErrorCode

	$logEvents = @{
		EVENTID = $EventId
		SETUPDEPLOYMENTEXITCODE = $ErrorCode
		LASTERROR = "$LastError Exiting with code $ErrorCode"
	}

	if($errorMessage){
		$logEvents.LASTEXCEPTION = $LastException
	}

	Write-Host2 -Type Failure -Message $LastError

	# TODO : This need to be removed once we have DB logger converted to azure api
	if($EnvironmentType -ne "Azure")
	{
		Write-DeploymentLog -DeploymentLogId $script:deploymentLogId -LogEvents $logEvents | Out-Null
	}

	$retVal
}

function ConvertTo-ArrayArgument{
param([string]$Source, [string]$Argument)
	$value = (![string]::IsNullOrWhiteSpace($Source)) | Get-ConditionalValue -TrueValue {$temp = $Source -split ","; " $Argument @('{0}')" -f ($temp -join "','")} -FalseValue ""
	$value
}

function Get-DeploymentLog{
param(
	[string]$Suffix = "SetupDeploymentFromConfig",
	[string]$Extension = "log",
	[switch]$NoRegister
)
	$deploymentLogFolder = Join-Path $DropFolder "Logs"

	$fileName = [System.IO.Path]::GetFileNameWithoutExtension($DeploymentConfig)

	$groupString = ""

	if($Groups){
		$groupString = "." + ($Groups -join "_")
	}

	$logname = "{0}.{1}{2}.{3}" -f $Suffix, $fileName, $groupString, $Extension

	$path = Join-Path $deploymentLogFolder $logname

	Write-Host "Log file path: $path"

	if($NoRegister){
		return $path
	}

	Write-Host "Registering log file $path"

	Register-LogFile -Path $path -WithHeader #returns the logfile object
}

function Add-DeploymentServerToTrustedHost{
param([string]$DeploymentServerIP)
	Set-Item WSMan:\localhost\Client\TrustedHosts $DeploymentServerIP -Force
}

function Remove-DeploymentServerToTrustedHost{
param([string]$DeploymentServerIP)
	$newvalue = ((Get-ChildItem WSMan:\localhost\Client\TrustedHosts).Value).Replace("$DeploymentServerIP,","")
	Set-Item WSMan:\localhost\Client\TrustedHosts $newvalue -Force
}

function Get-DeploymentMachineIP{
[cmdletbinding()]
param()

	$machineIpAddress = $null

	try
	{
		#Push-Location (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent)
        Push-Location (Split-Path -Path $DropFolder -Parent)

		[xml]$xml = Get-Content "Rigmanifest.xml"
		$rigVm = $xml.machines.machine | where {$_.name -eq $DeploymentServerName }

		if($rigVm)
		{
			$machineIpAddress = $rigVm.ipv4address

			$env:DeployMachineIP = $machineIpAddress
		}
	}finally{
		Pop-Location
	}

	(($machineIpAddress -eq $null) | Get-ConditionalValue -TrueValue $DeploymentServerIP -FalseValue $machineIpAddress)
}


function Start-Setup {
param()

	$retVal = 0

	Write-Header "Starting SetUp-Deployment (2015) for $DeploymentConfig" -AsSubHeader
	Write-Host ""
    Write-Host "Arguments"
    Write-Host "`tRigRelativePath: $DeploymentConfig"
	Write-Host "`tDropFolder: $DropFolder"
    Write-Host "`tRigName: $RigName";
	Write-Host "`tPackageName: $PackageName";
	Write-Host "`tEnableRemoting: $($EnableRemoting.IsPresent)"
	Write-Host "`tConfigOnly: $($ConfigOnly.IsPresent)"
	Write-Host "`tGetFileVersions: $($GetFileVersions.IsPresent)"
    Write-Host "`tSkipFileCopy: $($SkipFileCopy.IsPresent)";
	Write-Host "`tDeploymentAccountName: $DeploymentAccountName";
	Write-Host "`tDeploymentServerName: $DeploymentServerName";
	Write-Host "`tDeploymentServerIP: $DeploymentServerIP";
	Write-Host "`tEnvironment: $Environment";
	Write-Host "`tGroups: $Groups"
	Write-Host "`tMachines: $Machines"
	Write-Host "`tDriveLetter: $DriveLetter"
	Write-Host "`tSynchronous: $($SingleThreaded.IsPresent)";
	Write-Host "`tBuildNumber: $BuildNumber"
	Write-Host "`tRigConfigFile: $RigConfigFile"
    Write-Host ""

	Write-Host "Initialise deployment logging"
	$script:deploymentLogId = Get-Random -minimum 1 -maximum ([int32]::MaxValue)

	# TODO : This need to be removed once we have DB logger converted to azure api
	if($EnvironmentType -ne "Azure")
	{
		$script:deploymentLogId = New-DeploymentLogId -RigName $RigName -PackageName $PackageName -ComputerName $env:COMPUTERNAME -ScriptName $MyInvocation.ScriptName
	}

	Write-Host "Logging deployment ID: $script:deploymentLogId"
	Write-Host ""

	Write-DeploymentLog -DeploymentLogId $script:deploymentLogId -LogEvents @{EVENTID = "BeginSetupDeployment"} | Out-Null

	$script:deploymentMachineIP = Get-DeploymentMachineIP

	if(!$deploymentMachineIP) {
		$retVal = Write-ErrorDeploymentLog -ErrorCode 5 -LastError "No Deployment Machine IP identified. Check config has a Deployment ServerRole."
		return $retVal
	}

	Write-Host "Deployment Machine ($DeploymentServerName) IP Address: $script:deploymentMachineIP"

	$secureDeployAccountPW = Unprotect-Password -Password $Password -Value $DeploymentAccountPassword -AsSecureString

	$script:deploymentCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $DeploymentAccountName,$secureDeployAccountPW

	$script:deploymentMachinePath = "\\$deploymentMachineIP\$DriveLetter`$"

	$retVal
}

function Stop-ExternaProcesses{
param()

	Write-Host "Stopping CMD, MMC and Notepad Processes on $RigName"

	$retVal = 0

	$stopProcessPSFile = Join-Path $PSScriptRoot "StopProcesses-OnRig.ps1"

	if(!(Test-Path $StopProcessPSFile)){
		$retVal = Write-ErrorDeploymentLog -ErrorCode 8 -LastError "Failed to find script to stop proceses on rig '$RigName'."
		return $retVal
	}

	#Create a temporary folder for processing stop logs etc.
	$guid = New-ShortGuid -AsString

	$tempPath = Join-Path $script:deploymentMachinePath $guid
	$tempModulePath = Join-Path $tempPath "Modules"

	New-Item -ItemType Directory -Path $tempPath,$tempModulePath | Out-Null

	$psLoggingPath = Join-Path $modulePath "TFL.PowerShell.Logging"

	Copy-Item -Path $psLoggingPath -Destination $tempModulePath -Force -Recurse

	Invoke-Command -ComputerName $script:deploymentMachineIP -FilePath $stopProcessPSFile -Credential $script:deploymentCredentials -ArgumentList "$($DriveLetter):\$guid\StopProcesses.log", "$($DriveLetter):\$guid\Modules" -Authentication Credssp -OutVariable result | Out-String -Stream | ? {!($_ -as [int])} | Write-Host

	if($result -gt 0){
		$retVal = Write-ErrorDeploymentLog -ErrorCode 8001 -LastError "Failed to execute script to stop proceses on rig '$RigName'."
		return $retVal
	}

	if(Test-Path $tempPath){
		Write-Host "Removing Temp StopProcess path '$tempPath'"
		Remove-Item -Path $tempPath -Recurse -Force | Out-Null
	}

	$retVal
}

function Start-FileCopy{

	$retVal = 0

	if($SkipFileCopy){
		Write-Host ""
		Write-Host "! Skipping Deployment File Copy !"
		Write-Host ""
		return $retVal
	}

	Write-Host "Starting File Copy and extraction of packages"

	$deployPath = Join-path $script:deploymentMachinePath "Deploy"
	$deployDropFolder = Join-Path $deployPath "DropFolder"
	$logFolder = Join-Path $deployPath "Logs"

	Write-Host "Testing existence of deploy folder '$deployPath'"

	if(Test-Path $deployPath){
		Write-Host "Removing previous deployment(s)"

		#delete current deployment folder if exists
		if(Test-Path $deployDropFolder){
			Remove-Item $deployDropFolder -Recurse -Force
		}

		if(Test-Path $deployDropFolder) {
			$retVal = Write-ErrorDeploymentLog -ErrorCode 10 -LastError "Failed to remove previous deployment."
			return $retVal
		}

		Write-Host "Archiving existing log folders"

		Backup-Folder -Path $logFolder -TargetPath (Join-Path $deployPath "LogArchives") -ArchiveCount 5 -Move
	}
	else{
		Write-Host "Deploy folder not found. Creating '$deployPath' folder on deployment server"
		New-Item -Path $deployPath -Type Directory -Force | Out-Null
		New-Item -Path $logFolder -Type Directory -Force | Out-Null
	}

	Write-Host "Creating DropFolder '$deployDropFolder'"
	New-Item -Path $deployDropFolder -Type Directory -Force | Out-Null

	Write-Host "Copying package $PackageName to $deployDropFolder on deployment server"

	$sourcePackage = Join-Path $DropFolder $PackageName
	$targetPackage = Join-Path $deployDropFolder $PackageName

	Copy-Item -Path $sourcePackage -Destination $targetPackage -Recurse -Force

	if(-not (Test-Path $targetPackage)) {
		$retVal = Write-ErrorDeploymentLog -ErrorCode 11 -LastError "Failed to copy package to $RigName, failing deployment."
		return $retVal
	}

	$localPackagePath = Join-Path "D:\Deploy\DropFolder" $PackageName
	$localDestinationPath = "D:\Deploy\DropFolder"
	Write-Host "Extracting package $PackageName to $deployDropFolder"
	$command = "Expand-Archive -Path $localPackagePath -DestinationPath $localDestinationPath -Force"
	$scriptBlock = [ScriptBlock]::Create($command)
	Invoke-Command -ComputerName $script:deploymentMachineIP -ScriptBlock $scriptBlock -Authentication Credssp -Credential $script:deploymentCredentials -OutVariable $result | Out-String -Stream | ? {!($_ -as [int])} | Write-Host

	# new for Dynamic Config; copy RigManifest onto rig.
    $sourceManifest = Join-Path $DropFolder "..\RigManifest.xml"
    $targetManifest = Join-Path $deployDropFolder "..\RigManifest.xml"
	Write-Host "Copying RigManifest.xml to $targetManifest on deployment server"
    Copy-Item -Path $sourceManifest -Destination $targetManifest -Recurse -Force

	if(-not (Test-Path $targetManifest)) {
		Write-ErrorDeploymentLog -ErrorCode 11 -LastError "Failed to copy RigManifest to $RigName, failing deployment."
		$retVal = 11
		return $retVal
	}

	#Make local modules available throught the deployment process machine
	$sourcePath = "$($DriveLetter):\Deploy\DropFolder"
	$scriptsFolder = Join-Path $sourcePath "Deployment\Scripts"
	$targetModulePath = "$($DriveLetter):\TFL\Powershell\Modules"

	$command = ("Push-Location $scriptsFolder; .\Update-LocalModules.ps1 -Path $sourcePath -TargetModulePath $targetModulePath -ExcludeList 'TFL.Deployment.Database.Local'; Pop-Location")

	Write-Host "Executing command:"
	Write-Host $command
	Write-Host ""

	$scriptToExecute = [scriptblock]::Create($command)

	Invoke-Command -ComputerName $script:deploymentMachineIP -Script $scriptToExecute -Credential $script:deploymentCredentials -Authentication Credssp | Out-Null

	$retVal
}

function Start-GetFileVersions{
param([int]$Result = 0, [string]$GroupsString, [string]$MachineString)

	if(!$GetFileVersions){
		Write-Host "Skipping Get-FileVersions."
		return $Result
	}

	$rootPath = "$($DriveLetter):\Deploy"
	$logPath = Join-Path $rootPath "Logs"
	$scriptsFolder = Join-Path $rootPath "DropFolder\Deployment\Scripts"

	Write-Host "Generating Get-FileVersions command string"

	$command = ("Push-Location $scriptsFolder; .\Get-FileVersions.ps1 -DeploymentConfig '$DeploymentConfig' $groupsString $machinesString -FileVersionFolder $logPath -NoDisplay; Pop-Location")

	Write-Host "Executing command:"
	Write-Host $command
	Write-Host ""

	$scriptToExecute = [scriptblock]::Create($command)

	Write-Header "Getting FileVersions for deployment" -AsSubHeader

	Suspend-Logging $deploymentLog

	Invoke-Command -ComputerName $script:deploymentMachineIP -Script $scriptToExecute -Credential $script:deploymentCredentials -Authentication Credssp -OutVariable retVal | Out-String -Stream | ? {!($_ -as [int])} | Write-Host

	#if we have failed return that result, else return the result passed in from calling function
	if($retVal -ne 0){
		return $retVal
	}

	$Result
}

function Start-DeployRig{
param()

	$retVal	= 0

	$rootPath = "$($DriveLetter):\Deploy"
	$logPath = Join-Path $rootPath "Logs"
	$scriptsFolder = Join-Path $rootPath "DropFolder\Deployment\Scripts"

	Write-Host "Generating deployment command string"

	$groupsString = ConvertTo-ArrayArgument $Groups "-Groups"
	$machinesString = ConvertTo-ArrayArgument $Machines "-Machines"

	$enableRemotingString = $EnableRemoting.IsPresent | Get-ConditionalValue -TrueValue " -EnableRemoting" -FalseValue ""
	$configOnlyString = $ConfigOnly.IsPresent | Get-ConditionalValue -TrueValue " -ConfigOnly" -FalseValue ""
	$singleThreadedOnlyString = $SingleThreaded.IsPresent | Get-ConditionalValue -TrueValue " -SingleThreaded" -FalseValue ""

	#TODO: Use SecureString throughtout scripts for encryption password - passdown the chain.
	$clearTextPw = ConvertTo-String -Value $Password

	$command = ("Push-Location $scriptsFolder; .\Deploy-RigFromConfig2.ps1" +
			" -DeploymentConfig '$DeploymentConfig'" +
			" -Password '$clearTextPw'" + $groupsString + $machinesString +
			" -DeploymentLogFolder '$logPath'" + $enableRemotingString + $configOnlyString + $singleThreadedOnlyString +
			" -RigName '$RigName' -PackageName '$PackageName'" +
			" -DeploymentLogId $script:deploymentLogId -RigDeployment",
			" -DriveLetter '$DriveLetter'",
			" -RigConfigFile '$RigConfigFile'",
			" -BuildNumber '$BuildNumber'")

	Write-Host "Executing command:"
	Write-Host $command
	Write-Host ""

	$scriptToExecute = [scriptblock]::Create($command)

	Write-Header "Starting Deploy-RigFromConfig2 for $DeploymentConfig" -AsSubHeader

	Suspend-Logging $deploymentLog

	Invoke-Command -ComputerName $script:deploymentMachineIP -Script $scriptToExecute -Credential $script:deploymentCredentials -Authentication Credssp -OutVariable result | Out-String -Stream | ? {!($_ -as [int])} | Write-Host

	Resume-Logging $deploymentLog

	$deploymentMachineLogPath = Join-Path "\\$deploymentMachineIP" ($logPath -replace "$($DriveLetter):","$DriveLetter`$")

	Write-Host ""
	Write-Host "Copying deployment logs from $deploymentMachineLogPath to $DropFolder\Logs"

	Copy-Item -Path $deploymentMachineLogPath -Destination $DropFolder\Logs -Filter "*.log" -Recurse -Force -Container:$false

	if($result -gt 0){
		$retVal = Write-ErrorDeploymentLog -ErrorCode 14 -LastError "Deploy-RigFromConfig2 returned with result $result. Failing deployment."
	}
	else{
		Write-Host2 -Type Success -Message "Deploy-RigFromConfig2 returned with result $result. Deployment was successful."
	}

	Write-Host ""
	Write-Header "End Deploy-RigFromConfig2 for $DeploymentConfig" -AsSubHeader

	#return result of Get-FileVersions if relevant, or the result of this function
	Start-GetFileVersions -Result $retVal -GroupsString $groupsString -MachineString $machinesString
}

$exitCode = 0
$deploymentLog = Get-DeploymentLog

try{
	$exitCode = Invoke-UntilFail {Start-Setup},{Stop-ExternaProcesses},{Start-FileCopy},{Start-DeployRig}
}
catch{
	Write-Error2 -ErrorRecord $_
	$exitCode = 1
}
finally{
	$deploymentLog | Unregister-LogFile
}

Remove-Module TFL.PowerShell.Logging
Remove-Module TFL.Utilities

$exitCode

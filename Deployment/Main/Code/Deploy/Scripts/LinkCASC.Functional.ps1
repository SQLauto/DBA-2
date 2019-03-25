<#
.SYNOPSIS
	Linking script used by the CASC team for linking functional rigs.
.PARAMETER RigName
    The name of the vCloud rig to target for linking.
.PARAMETER FTPWebAlias

.PARAMETER DeploymentAccountName
    The qualified username used for deployments.
.PARAMETER DeploymentAccountPassword
    The (encrypted) password corresponding to the deployment account.
.PARAMETER Password
    The password used to decrypt encrypted deployment account passwords. If set to null or empty, assumes deployment account password is not encrypted.
.PARAMETER LocalHostTag
    The tag used for matching against localhost.
.PARAMETER ContactlessLocalTag
    The tag used for matching against contactless localhost.
.PARAMETER FTPWebIP
    Used to directly assign the IP address of the target FTP Web server. Cab be used if vCloud is slow.
.SWITCH IsLocal
	Used when running locally to ensure net use connections have been created.
#>

[cmdletbinding()]
param
(
    [parameter(Mandatory=$true, Position=0)]
	[ValidateNotNullOrEmpty()]
    [Alias("vAppName")]
	[string] $RigName,
    [string] $FTPWebAlias,
    [string] $DeploymentAccountName		= "FAELAB\TFSBuild",
    [string] $DeploymentAccountPassword	= "vIgxmg6jvCDA1nUHWi8Xzw==",
    [string] $Password = "Olymp1c`$2012",
	[string] $LocalHostTag ="localhost",
	[string] $ContactlessLocalTag ="contactless.local",
	 # Option to bypass vCloud while the API is unusably slow.
    [string]$FTPWebIP = "",
	[switch]$IsLocal,
	[string]$DriveLetter = "D"
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

function Start-MapDrive {
param (
    [string]$IpAddress,
    [string]$Machine,
	[Management.Automation.PSCredential]$Credential
)
	Write-Host "Caching credentials to $Machine : net use \\$IpAddress /user:faelab\tfsbuild <pwd>"
    New-MappedDrive -ComputerName $Machine -ComputerIpAddress $IpAddress -ShareName "$DriveLetter`$" -Credential $Credential | Out-Null
    $IpAddress
}

function Start-RemoveMapDrive {
param (
    [string]$IpAddress,
    [string]$Machine
)
	Write-Host "Clearing up mapped net used drives."
    Remove-MappedDrive -ComputerName $Machine -ComputerIpAddress $IpAddress -ShareName "$DriveLetter`$" | Out-Null
}

function Get-StartingState{
[cmdletbinding()]
param([string]$Name, [switch]$Oyster)

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

function Write-StandardReplacements {
param(
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [object]$ToConfig
)
	$CACCIPTag = '$CASCSiteIP' # TS-CAS1 is turned into this   - not found explicitly in Stabilisation build

    [xml]$config = $ToConfig
    #Write-Host "Replacing 'TS-CAS1' with CACCIPTag ($CACCIPTag)"
    #$config = $config.Replace("TS-CAS1",$CACCIPTag)

    Write-Host "Replacing $count instances of CACCIPTag ($CACCIPTag) with FTPWebReference ($script:FTPWebReference)"
    $config.InnerXml = $config.InnerXml.Replace($CACCIPTag, $script:FTPWebReference)
    $config.InnerXml = $config.InnerXml.Replace($LocalHostTag, $script:FTPWebReference)

	$config
}

function Update-ConfigFilesForLinking {
param([string]$ServerIP, [string]$ConfigFile, [string]$ApplicationPath)

    $rootPath = "\\$ServerIP\$DriveLetter`$\TFL\$ApplicationPath"
    $configPath = Join-Path $rootPath $ConfigFile

    if(!(Test-Path $configPath)){
        Write-Host "Root path $rootPath or file $ConfigFile does not exist."
        return $null
    }

	Write-Host "Modifying $ApplicationPath Service config"
    if (!(Test-Path "$configPath.original")) {
        Write-Host "Creating config .original file as one does not exist."
		[xml]$configTxt = Get-Content $configPath
        $configTxt.Save("$configPath.original")
    }

	Write-Host "Creating config .bak file."
    $configTxt = Get-Content "$configPath.original"
	[xml]$configXml = $configTxt
	$configXml.Save("$configPath.bak")

    (New-Object PSObject -Property @{'Path' = $configPath;'Content' = $configTxt})
}

function Update-ConfigFiles{
param([string]$ServerIP, [string]$ConfigFile, [string]$ApplicationPath, [switch]$Optional)

	$configInfo = Update-ConfigFilesForLinking -ServerIP $ServerIP -ConfigFile $ConfigFile -ApplicationPath $ApplicationPath

    if($configInfo -eq $null -or $configInfo.Content -eq $null){
        if($Optional){
            return $null
        }
        else {
            throw "TERMINATING: Install path not found for non-optional config '$rootPath', exiting with code 5"
        }
    }

    $configTxt = $configInfo.Content
   	$configPath = $configInfo.Path
	$configTxt = Write-StandardReplacements -ToConfig $configTxt

	[xml]$xmlText = $configTxt
	$xmlText.Save($configPath)

    Write-Host "$configPath updated."
	Write-Host ""

	$(New-Object PSObject -Property @{'Path' = $configPath;'Content' = [xml]$xmlText})
}

function Update-Ftp{
param()

	$retVal = 0

    Write-Host "Updating CASC config"
    $serverIP = $machines.Item("TS-CAS1")
    $configFile = "Web.config"
    $binaryPath = "CACC\CSCPortal"

    Update-ConfigFiles -ServerIP $serverIP -ConfigFile $ConfigFile -ApplicationPath $binaryPath | Out-Null

    Write-Host "Updating CAS config"
    $binaryPath = "CACC\CSCSupport"
    Update-ConfigFiles -ServerIP $serverIP -ConfigFile $ConfigFile -ApplicationPath $binaryPath | Out-Null

	Write-Host "Updating CASC Mock Services config"
    $binaryPath = "CACC\MockServices"
    Update-ConfigFiles -ServerIP $serverIP -ConfigFile $ConfigFile -ApplicationPath $binaryPath | Out-Null

	$retVal
}
function Start-Linking{
[cmdletbinding()]
param()

	Write-Host ""
    Write-Host "### Starting Post-Deployment Configuration of External Rig References (link script) ###"
    Write-Host "### "
    Write-Host "### on $RigName"
    Write-Host ""
	$vAppStartingState = Get-StartingState -Name $RigName

	if(!$vAppStartingState.Exists){
		Write-Warning "Rig $RigName is not in a valid start state and linking cannot continue. Exiting."
		return 1
	}

    $retVal = 0

	$securePassword = ConvertTo-SecureString $Password -AsPlainText -Force

	$secureDeployAccountPW = Unprotect-Password -Password $securePassword -Value $DeploymentAccountPassword -AsSecureString

	$deploymentCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $DeploymentAccountName,$secureDeployAccountPW

    $machines_ = @{
		"TS-CAS1" = $FTPWebIP
	}

	$machines_.Keys | ForEach-Object {
		$ipaddress = $machines_.Item($_)

		if(!$ipaddress){
			$ipaddress = Get-VAppExternalIP -VApp $script:vApp -ComputerName $_
			$machines.Add($_, $ipaddress)
		}
		else{
			$machines.Add($_, $ipaddress)
		}

		Write-Host "$_ : $ipaddress"

		if($IsLocal.IsPresent) {
			Start-MapDrive -IpAddress $ipaddress -Machine $_ -Credential $deploymentCredentials
		}
	}

	$script:FTPWebReference = ([string]::IsNullOrEmpty($FTPWebAlias)) | Get-ConditionalValue -TrueValue $machines.Item("TS-CAS1") -FalseValue $FTPWebAlias

    $retVal = Update-Ftp

    $end = Get-Date
    Write-Host "### Post-Deployment Configuration (link script) Complete at $end###"
    Write-Host "###"

	$retVal
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
$script:machines = @{}

try{
	$exitCode = Start-Linking
}
catch{
	Write-Error2 -ErrorRecord $_
	$exitCode = 1
}
finally{
	Write-Host "Closing VCloud connection."
	$vCloud | Disconnect-VCloud

	if($IsLocal.IsPresent) {
		#tidyup mapped drives
		$machines.Keys | ForEach-Object {
			$ipaddress = $machines.Item($_)
			Start-RemoveMapDrive -IpAddress $ipaddress -Machine $_
		}
	}
}

Remove-Module TFL.Deployment.VCloud -ErrorAction Ignore
Remove-Module TFL.Deployment -ErrorAction Ignore
Remove-Module TFL.Deployment.Database -ErrorAction Ignore
Remove-Module TFL.PowerShell.Logging -ErrorAction Ignore
Remove-Module TFL.Utilites -ErrorAction Ignore

$exitCode

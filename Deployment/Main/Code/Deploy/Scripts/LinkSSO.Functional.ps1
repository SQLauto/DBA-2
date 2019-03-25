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
	Use when running locally on Dev Machine to cache credentials.
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
	 # Option to bypass vCloud while the API is unusably slow.
    [string]$FTPWebIP = "",
	[string]$FTPDbIP = "",
	[switch]$IsLocal,
	[string]$DriveLetter ="D",

	# Adding tactical prior to dynamic config
	# SsoRedirectWhiteListUrls, DefaultSsoRedirectProtectedUrl, DefaultSsoRedirectPublicUrl
	[string]$SsoRedirectWhiteListUrls = "",
	[string]$DefaultSsoRedirectProtectedUrl = "",
	[string]$DefaultSsoRedirectPublicUrl = ""
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
    $config = $ToConfig
    Write-Host "Replacing 'TS-CAS1' with  $script:FTPWebReference"
    $config = $config.Replace("TS-CAS1", $script:FTPWebReference)

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
	
	# From FTPSSO Link Script fo rexplicit values
    #if(!$UseDummyOyster){
    #    $configInfo.Content `
	#	| Update-ConfigValue -AppSettingKey "OysterBaseUrl"	-Value "http://$script:OysterServiceReference`:81/" `
    #    | Update-ConfigValue -AppSettingKey "MockOyster"	-Value "false" | Out-Null
    #}
	if (![string]::IsNullOrEmpty($SsoRedirectWhiteListUrls))
	{
		$existingRedirectUrls = Get-ConfigValue -AppSettingKey "SsoRedirectWhiteListUrls"
		$configInfo.Content | Update-ConfigValue -AppSettingKey "SsoRedirectWhiteListUrls" -Value ($existingRedirectUrls + ";" + $SsoRedirectWhiteListUrls)
	}
	if (![string]::IsNullOrEmpty($DefaultSsoRedirectProtectedUrl))
	{
		$configInfo.Content | Update-ConfigValue -AppSettingKey "$DefaultSsoRedirectProtectedUrl" -Value $DefaultSsoRedirectProtectedUrl
	}
	if (![string]::IsNullOrEmpty($DefaultSsoRedirectPublicUrl))
	{
		$configInfo.Content | Update-ConfigValue -AppSettingKey "$DefaultSsoRedirectPublicUrl" -Value $DefaultSsoRedirectPublicUrl
	}

	[xml]$xmlText = $configTxt
	$xmlText.Save($configPath)

    Write-Host "$configPath updated."
	Write-Host ""

	$(New-Object PSObject -Property @{'Path' = $configPath;'Content' = $xmlText})
}

function Update-ConfigValue {
[cmdletbinding()]
param(
    [parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateNotNull()]
    [xml] $Content,
	[string]$ConfigSection = "appSettings",
	[parameter(Mandatory=$true)]
    [string]$AppSettingKey,
    [parameter(Mandatory=$true)]
    [AllowEmptyString()]
    [string]$Value
)

    Write-Host "Setting $AppSettingKey to '$Value'"
    $set = "configuration/$ConfigSection/add[@key='$AppSettingKey']/@value"
	$Content.SelectNodes($set) | ForEach-Object {$_.Value = $Value }

	$Content
}

function Update-Sso{
param()

	$retVal = 0

    Write-Host "Updating SSO Web config"
    $serverIP = $machines.Item("TS-CAS1")
    $configFile = "Web.config"
    $binaryPath = "SSO\Website"

    Update-ConfigFiles -ServerIP $serverIP -ConfigFile $ConfigFile -ApplicationPath $binaryPath | Out-Null

	#Update SSO DB values
	$serverIP = $machines.Item("TS-DB1")
	$datasource = Get-DataSource -Computer $serverIP -InstanceName "Inst3"
    Write-Host "Updating SingleSignOn Database on $datasource"

	 $connectionString = Get-ConnectionString -TargetDatabase "SingleSignOn" -DataSource $datasource -UseSqlAuth -Username "TFSBuild" -Password "LMTF`$Bu1ld"

    # Customer Self Care (Customer Portal) = A3AC81D4-80E8-4427-B348-A3D028DFDBE7
    $cmdText = "EXEC [dbo].[ProductUpdate]
        @validateUrl = 'http://$serverIP/HomePage/Validate',
        @signoutUrl = 'http://$serverIP/HomePage/LogOff',
        @homeUrl = 'http://$serverIP',
        @defaultUrl = NULL,
        @productToken = 'A3AC81D4-80E8-4427-B348-A3D028DFDBE7',
        @protectedUrl = 'http://$serverIP/Dashboard';
        update products set RegistrationUrl = 'http://$serverIP/Registration/NewRegistration' where ProductToken = 'A3AC81D4-80E8-4427-B348-A3D028DFDBE7';"

    $success = $connectionString | Invoke-ExecuteNonQuery -CommandText $cmdText

	# Customer Self Care Support (Admin Portal) = 6687E912-D120-461E-9DA9-3C0288629F4F
    $cmdText = "EXEC [dbo].[ProductUpdate]
        @validateUrl = 'http://$serverIP`:8080/Account/Validate',
        @signoutUrl = 'http://$serverIP`:8080/Account/LogOff',
        @homeUrl = 'http://$serverIP`:8080',
        @defaultUrl = NULL,
        @productToken = '6687E912-D120-461E-9DA9-3C0288629F4F',
        @protectedUrl = 'http://$serverIP`:8080/Customer/Find';"

    $success = $connectionString | Invoke-ExecuteNonQuery -CommandText $cmdText

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
		"TS-DB1" = $FTPDbIP
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

	if($FTPWebAlias){
		$machines.Item("TS-CAS1") = $FTPWebAlias
	}

    $retVal = Update-Sso

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
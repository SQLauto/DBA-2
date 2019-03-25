<# 
.SYNOPSIS
	LinkOysterToFTP.VC.ps1
    This script is used to replace dummy Oyster values with real ones. A lot of code ripped from LINKSSOFTPRigs.VC.2015.ps1.
    Can supply rig names for FTP rig and Oyster Rig to make these changes during a release
.PARAMETER FTPRigname
    Name of rig used when carrying out rig deployment (If not provided, you need to provide FTPWebReference and SSOWebReference)
.PARAMETER OysterRigname
    Name of the Oyster vApp (If not provided, you need to include OysterWebReference and OysterServiceReference)
.PARAMETER FTPWebReference 
    IP for CASC website (on integration this is TS-CAS1)
.PARAMETER SSOWebReference
    IP for SSO website (on intergration this is TS-DB2)
.PARAMETER SSONotificationReference
	IP for Notification reference (on integration this is TS-CIS1)
.PARAMETER OysterWebReference
	IP for the Oyster website
.PARAMETER OysterServiceReference
	IP for the Oyster services
.EXAMPLE
	Link Oyster and FTP using rignames
	.\LinkOysterToFTP.VC.ps1 -FTPRigName "FTP.Main.RTN" -OysterRigName "Oyster.Rig"
.EXAMPLE
	Link Oyster and FTP using IPs
	.\LinkOysterToFTP.VC.ps1 -FTPWebReference "10.107.248.46" -SSOWebReference "10.107.249.48" -SSONotificationReference "10.107.248.154" -OysterWebReference "10.10.10.10" -OysterServiceReference "11.11.110.111"
.EXAMPLE
	Overriding Dynamic Config
	.\LinkOysterToFTP.VC.ps1 -FTPRigName "FTP.Main.RTN" -SSOWebReference "10.10.10.10" -OverrideDynamicConfig
#>
[cmdletbinding()]
param
(    
    [string] $FTPWebReference,    
    [string] $SSOWebReference,
    [string] $SSONotificationReference,
    [Alias("FTPvAppName")]
    [string]$FTPRigName, 
    [Alias("OystervAppName")]
    [string] $OysterRigName,
    [string] $OysterWebReference,
    [string] $OysterServiceReference,
    [string] $OysterServicePassword,
    [string] $DriveLetter = "D",
    [string] $DeploymentAccountName = "FAELAB\TFSBuild",
    [string] $DeploymentAccountPassword	= "vIgxmg6jvCDA1nUHWi8Xzw==",
    [string] $Password, #Encryption password
	

    # Must be supplied when running on a Dev Machine to ensure credentials are cache for connectivity
    [switch]$IsLocal,

	# For FOAM rigs when connecting to a component outside of a rig
	[switch] $OverrideDynamicConfig
)

#region Pre requisite checks
if($PSVersionTable.PSVersion.Major -lt 5) {
	Write-Error "You need to be running powershell 5 as a minimum to run this deployment"
	return 1
}
if(!$FTPWebReference -and !$SSOWebReference -and !$FTPRigName -and !$OysterRigName -and !$OysterWebReference -and !$OysterServiceReference) {
    Write-Error "You need to supply rignames or IPs for Oyster and FTP to run this script"
    return 1
}

if(!$Password) {
    Write-Error "You must supply the password to continue"
    return 1
}

if($OverrideDynamicConfig -eq $true -and !$FTPRigName){
	Write-Error "When overwriting config values, please supply the name of the rig you wish to change"
	return 1
}

if($FTPRigName -and $OverrideDynamicConfig -eq $true -and $FTPWebReference -or $SSOWebReference -or $SSONotificationReference){
	Write-Host "Rigname and IPs both found, will do dynamic config override"
	$Script:FTPWebReferenceOverride = $FTPWebReference
	$Script:SSOWebReferenceOverride = $SSOWebReference
}
#endregion

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

		if($Oyster){
			$script:vAppOyster = Get-VApp -Name $Name
		}
		else{
			$script:vApp = Get-VApp -Name $Name
		}

		$vAppStartingState = @{
			Exists    = $false
			Deployed = $false
			State    = $null
		}

		if($script:vApp){
			$isDeployed = $script:vApp.IsDeployed()
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

#region Updating Config files
function Write-StandardReplacements {
param(
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [object]$ToConfig
)
    
	$OysterWebTag = '$OysterWebReference'
    $OysterSvcTag = '$OysterServiceReference'
    [xml]$config = $ToConfig

    if($OverrideDynamicConfig  -eq $true){
		if($Script:FTPWebReferenceOverride){
			Write-Host "FTP Web override found, replacing $FTPWebReference with $Script:FTPWebReferenceOverride"
			$config.InnerXml = $config.InnerXml.Replace($FTPWebReference, $Script:FTPWebReferenceOverride)
		}
		if($Script:SSOWebReferenceOverride){
			Write-Host "SSO Site override found, replacing $SSOWebReference with $Script:SSOWebReferenceOverride"
			$config.InnerXml = $config.InnerXml.Replace($SSOWebReference, $Script:SSOWebReferenceOverride)
		}
	}

    Write-Host "Replacing OysterWebTag ($OysterWebTag) with OysterWebReference ($OysterWebReference)"
    $config.InnerXml = $config.InnerXml.Replace($OysterWebTag, $OysterWebReference)

    Write-Host "Replacing OysterSvcTag ($OysterSvcTag) with OysterServiceReference ($OysterServiceReference)"
    $config.InnerXml = $config.InnerXml.Replace($OysterSvcTag, $OysterServiceReference)

	$config
}

function Update-ConfigFilesForInsertion {
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

	$configInfo = Update-ConfigFilesForInsertion -ServerIP $ServerIP -ConfigFile $ConfigFile -ApplicationPath $ApplicationPath

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
#endregion

#Main Function
function Insert-RealOysterValues{
[cmdletbinding()]
param()

    $retval = 0
    $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
	$secureDeployAccountPW = Unprotect-Password -Password $securePassword -Value $DeploymentAccountPassword -AsSecureString
	$deploymentCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $DeploymentAccountName,$secureDeployAccountPW

    if($FTPRigName){
        Write-Host ""
        Write-Host "### Starting update of real Oyster values on $FTPRigName using the oyster vApp $OysterRigName or using the IPs $OysterWebReference and $OysterServiceReference"
        Write-Host ""

        $vAppStartingState = Get-StartingState -Name $FTPRigName

        if(!$vAppStartingState.Exists){
				Write-Warning "Rig $FTPRigName is not in a valid start state and linking cannot continue. Exiting."
				return 1
		}
    
        $machines_ = @{
            "TS-CAS1" = $FTPWebReference
            "TS-DB2" = $SSOWebReference
            "TS-CIS1" = $SSONotificationReference
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
        }
    }

    if(!$FTPWebReference){
        $FTPWebReference = $machines.Item("TS-CAS1")
        if($IsLocal.IsPresent){
            Start-MapDrive -IpAddress $FTPWebReference -Machine "TS-CAS1" -Credential $deploymentCredentials
        }
    }
    if(!$SSOWebReference){
        $SSOWebReference = $machines.Item("TS-DB2")
        if($IsLocal.IsPresent){
            Start-MapDrive -IpAddress $SSOWebReference -Machine "TS-DB2" -Credential $deploymentCredentials
        }
    }
    if(!$SSONotificationReference){
        $SSONotificationReference = $machines.Item("TS-CIS1")
        if($IsLocal.IsPresent){
            Start-MapDrive -IpAddress $SSONotificationReference -Machine "TS-CIS1" -Credential $deploymentCredentials
        }
    }
    

    if($OysterRigName){
        $vAppStartingState = Get-StartingState -Name $OysterRigName -Oyster

        if(!$vAppStartingState.Exists){
				Write-Warning "Rig $OysterRigName is not in a valid start state and linking cannot continue. Exiting."
				return 1
		}

        $OysterWebIP = Get-VAppExternalIP -VApp $script:vAppOyster -ComputerName "Oyster_Template"
        Write-Host "Using Oyster Rig: $OysterRigName ($OysterWebIP)"       
    }
    if(!$OysterWebReference){
       $OysterWebReference = $OysterWebIP
    }
    if(!$OysterServiceReference){
       $OysterServiceReference = $OysterWebIP
    }

    #### CASC CONFIG ####

    Write-Host "Updating CASC Config"
    $serverIP = $FTPWebReference
    $configFile = "Web.config"
    $binaryPath = "CACC\CSCPortal"

    $configInfo = Update-ConfigFiles -ServerIP $serverIP -ConfigFile $configFile -ApplicationPath $binaryPath

    if($OysterServicePassword){
        $configInfo.Content | Update-ConfigValue -AppSettingKey "OysterServicePassword" -ConfigSection "OysterService" -Value $OysterServicePassword | Out-Null
    }

    $configInfo.Content | Update-ConfigValue -ConfigSection "OysterWebsite" -AppSettingKey "OysterBaseUrl" -Value "http://$OysterWebReference" | Out-Null
    $configInfo.Content | Update-ConfigValue -ConfigSection "OysterService" -AppSettingKey "GetOysterCardForUserUrlV2"  -Value "http://$OysterServiceReference`/GetOysterCardForUserV2" | Out-Null

    $configInfo.Content.Save($configInfo.Path)
    Write-Host "$($configInfo.Path) updated"	

    #### SSO CONFIG ####
    $serverIP = $SSOWebReference
    $binaryPath = "SSO\Website"
    $configInfo = Update-ConfigFiles -ServerIP $serverIP -ConfigFile $configFile -ApplicationPath $binaryPath

    $configInfo.Content.Save($configInfo.Path)
    Write-Host "$($configInfo.Path) updated"	
    
    $binaryPath = "SSO\SingleSignOnServices"
    $configInfo = Update-ConfigFiles -ServerIP $serverIP -ConfigFile $ConfigFile -ApplicationPath $binaryPath

    $configInfo.Content | Update-ConfigValue -AppSettingKey "OysterBaseUrl" -Value "http://$OysterServiceReference`:81/"
    $configInfo.Content | Update-ConfigValue -AppSettingKey "MockOyster" -Value "false" | Out-Null

    #### SSO Notification worker service ####
    $serverIP = $SSONotificationReference
    $configFile = "Customer.Change.NotificationWorker.exe.config"
    $binaryPath = "SSO\Customer.Change.NotificationWorkerOyster"

    if(!(Test-Path "\\$serverIP\$DriveLetter`$\TFL\$binaryPath\")){
       Write-Host "SSO Customer Change Notification Worker Service - Oyster was not found, skipping"
    }
    else{
        $configInfo = Update-ConfigFiles -ServerIP $SSONotificationReference -ConfigFile $configFile -ApplicationPath $binaryPath -Optional

        if ($configInfo -ne $null)
        {
			if($OysterWebReference) {
                $configInfo.Content | Update-ConfigValue -AppSettingKey "OysterBaseUrl"  -Value "http://$OysterWebReference" | Out-Null
            }

            if($OysterServicePassword) {
                $configInfo.Content | Update-ConfigValue -AppSettingKey "OysterAuthPassword"  -Value $OysterServicePassword | Out-Null
            }

	        $configInfo.Content.Save($configInfo.Path)
            Write-Host "$($configInfo.Path) updated"		    
        }
    }

    #### SSO Database (Product table) Update ####

    $serverIP = $SSOWebReference
    Write-Host "Modifying SSO Database Product table"
    $datasource = Get-DataSource -Computer $serverIP -InstanceName "Inst3"
    Write-Host "Updating SingleSignOn Database one $datasource"

    $connectionString = Get-ConnectionString -TargetDatabase "SingleSignOn" -DataSource $datasource -UseSqlAuth -Username "SingleSignOn" -Password "ss0w3Bus3r"

    $cmdText = " exec [dbo].[ProductUpdate]
                        @validateUrl = NULL,
                        @signoutUrl = 'http://$OysterWebReference/oyster/oysterlogout.do',
                        @homeUrl = 'login',
                        @defaultUrl = 'http://$OysterWebReference/oyster/entry.do',
                        @productToken = '8EAD5CF4-4624-4389-B90C-B1FD1937BF1F',
                        @protectedUrl = 'http://$OysterWebReference/oyster/showCards.do?_o=KTaO6YfdBpIdcN8DLNDKgw%3D%3D' "                         

    $success = $connectionString | Invoke-ExecuteNonQuery -CommandText $cmdText

    if(!$success){
        return 1
    }
    Write-Host "SSO Database Updated"

    Write-Host "Updating Oyster values into FTP configs complete"

    $retval
}


$exitcode = 0

$vCloudPassword = ConvertTo-SecureString "P0wer5hell" -AsPlainText -Force
$vCloudParams = @{
	Url = "https://vcloud.onelondon.tfl.local"
	Organisation = "ce_organisation_td"
	Username = "zSVCCEVcloudBuild"
	Password = $vCloudPassword
}

if($FTPRigName -or $OysterRigName){
    Write-Host "Loading VCloudService and Creating connection to $($vCloudParams.Url). Org: $($vCloudParams.Organisation)"
    $vCloud = Connect-VCloud @vCloudParams   
}

$script:machines = @{}

try{
    $exitCode = Insert-RealOysterValues
}
catch{
    Write-Error2 -ErrorRecord $_
}
finally{
    if($FTPRigName -or $OysterRigName){
        Write-Host "Closing VCloud connection"
        $vCloud | Disconnect-VCloud
    }

    if($IsLocal.IsPresent -and $script:machines){
        $machines.Keys | ForEach-Object {
            $ipaddress = $script:machines.Item($_)
            Start-RemoveMapDrive -IpAddress $ipaddress -Machine $_
        }
    }

    Write-Host "Config files have been updated"
}

Remove-Module TFL.Deployment.VCloud -ErrorAction Ignore
Remove-Module TFL.Deployment -ErrorAction Ignore
Remove-Module TFL.Deployment.Database -ErrorAction Ignore
Remove-Module TFL.PowerShell.Logging -ErrorAction Ignore
Remove-Module TFL.Utilites -ErrorAction Ignore

$exitCode
<#
.SYNOPSIS
	This script is for configuring FTP and SSO in a vCloud Integration Rig with SSO on DB2, and must be run against an integration vApp.
	It cannot be used to stub SSO
.PARAMETER DeploymentConfig
    The name of the deployment configuration file used to drive the deployment.
.PARAMETER Password
    The password used to decrypt service account info.
.PARAMETER DeploymentLogFolder
    The name of the folder where deployment logs will be created.
.PARAMETER Groups
    An array of group names to limit what deployment groups should be deployed
.PARAMETER Machines
    An array of server names to that will be used to filter the deployment target machines.
.PARAMETER ConfigOnly
    Switch to indicate if a configuration only deployment should be carried out.
.PARAMETER $EnableRemoting
    Switch to determine if remoting should be enabled on target machines
.PARAMETER SingleThreaded
    Switch to set for synchronous deployments. If not set, then default will be multithreaded. It will use Processor count to determine the number of threads to use
.PARAMETER RigDeployment
    Switch to indicate whether a rig deployment is being performed. Setting this is important as it allows DataBase logging
.PARAMETER RigName
    The name of the the rig used when carrying out a rig deployment.
.PARAMETER PackageName
    The name of the package used when carrying out a rig deployment.
.PARAMETER DeploymentLogId
    The deployment logging ID used when carrying out a rig deployment.
.SWITCH IsLocal
	Use when running locally to turn on caching of credentials for connectivity.
#>

[cmdletbinding()]
param
(
    # [parameter(Mandatory=$true, Position=0)]
	# [ValidateNotNullOrEmpty()]
    [Alias("vAppName")]
	[string] $RigName, # NO DEFAULT
    [string] $FTPWebAlias,
    [string] $SSOWebSiteAlias,
    [string] $SSOWebServiceAlias,
	[string] $OysterRig,
    [string] $OysterWebSiteAlias,
    [string] $OysterWebServiceAlias,
    [string] $OysterServicePassword,
    [string] $DeploymentAccountName		= "FAELAB\TFSBuild",
    [string] $DeploymentAccountPassword	= "vIgxmg6jvCDA1nUHWi8Xzw==",
    [string] $DevelopmentModeOn = "false",
    [string] $Password = "Olymp1c`$2012",
    [string] $AzureUploader_StorageConnStr = '', # DEFAULT = "DefaultEndpointsProtocol=https;AccountName=otfp;AccountKey=+D1voWVu1PdFtqnYEJ5vy09Ek2DoyrvbLcRiCiL7GUbWD6PJNTWCFLigjBB4UJRePu+zhfCmbpspvE9SyJF7mg==", # optional but does need a default
    [string] $AzureUploader_ContainerName = "inbox", # optional but does need a default
	[string] $DriveLetter = "D",
    [string] $AzureUploader_KeyVaultSecretUri = "", # 'https://mobileapistableipp001.vault.azure.net/secrets/StorageConnectionString', # DEFAULT = "",
    [string] $AzureUploader_AzureKeyVaultClientId = "", # 'b7de1e56-6017-45cc-a31e-4bdc4a00830a', # DEFAULT = "",
    [string] $AzureUploader_CertificateThumbprint = "", # '5F9E1EB7956FFA79AA3AC471E1BA35CDC6C5D96C', # DEFAULT = "",

    # Option to bypass vCloud while the API is unusably slow.
    [string]$FTPWebIP = "",
    [string]$FTPCisIP = "",
    [string]$FTPDbIP  = "",
    [string]$FTPDb2IP = "",
    [string]$FTPSASIP = "",
    [string]$FtpOtfpIP = "",
    [string]$FTP_AzUPLDR_IP = "",

	# Must be supplied when running on a Dev Machine to ensure credentials are cache for connectivity
	[switch]$IsLocal
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

	$CACCIPTag = '$CASCSiteIP'                        # TS-CAS1 is turned into this   - not found explicitly in Stabilisation build
	$SSOIPTag = '$SsoWebSiteIP'                  # CASC_CSCWebConfigSsoWebsiteBaseUrl, SSO_Website_BaseUrl
	$SSOServiceIPTag = '$SsoWebServiceFacadeIP'  # CASC_CSCWebConfigSsoServiceBaseUrl, CASC_CSCWebConfigGetOysterCardForUserUrl, SSO_Service_BaseUrl

    $OysterWebTag = '$OysterWebReference'
    $OysterSvcTag = '$OysterServiceReference'

	#$SSOServiceIP = "TS-DB2:8081" # Replaces $SSOServiceIPTag
	$AzureUploader_StorageConnStrTag = '$AzureUploader_StorageConnStr'
    $AzureUploader_ContainerNameTag = '$AzureUploader_ContainerName'
    $AzureUploader_KeyVaultSecretUriTag = '$OyBO_AzureUploader_KeyVaultSecretUri'
    $AzureUploader_CertificateThumbprintTag = '$OyBO_AzureUploader_CertificateThumbprint'
    $AzureUploader_AzureKeyVaultClientIdTag = '$OyBO_AzureUploader_AzureKeyVaultClientId'


    [xml]$config = $ToConfig

    # DO NOT DO THIS TS-CAS1 REPLACEMENT TO PLACEHOLDER

    #Write-Host "Replacing 'TS-CAS1' with CACCIPTag ($CACCIPTag)"
    #$config.InnerXml = $config.InnerXml.Replace("TS-CAS1",$CACCIPTag)

    Write-Host "Replacing $count instances of CACCIPTag ($CACCIPTag) with FTPWebReference ($script:FTPWebReference)"
    $config.InnerXml = $config.InnerXml.Replace($CACCIPTag, $script:FTPWebReference)

    Write-Host "Replacing SSOIPTag ($SSOIPTag) with SSOWebReference ($script:SSOWebReference)"
    $config.InnerXml = $config.InnerXml.Replace($SSOIPTag, $script:SSOWebReference)

    Write-Host "Replacing SSOServiceIPTag ($SSOServiceIPTag) with SSOWebServiceReference ($SSOWebServiceReference)"
    $config.InnerXml = $config.InnerXml.Replace($SSOServiceIPTag, $SSOWebServiceReference)

    Write-Host "Replacing OysterWebTag ($OysterWebTag) with OysterWebReference ($script:OysterWebReference)"
    $config.InnerXml = $config.InnerXml.Replace($OysterWebTag, $script:OysterWebReference)

    Write-Host "Replacing OysterSvcTag ($OysterSvcTag) with OysterServiceReference ($script:OysterServiceReference)"
    $config.InnerXml = $config.InnerXml.Replace($OysterSvcTag, $script:OysterServiceReference)

    `Write-Host "Replacing: $AzureUploader_StorageConnStrTag with: $AzureUploader_StorageConnStr"
    $config.InnerXml = $config.InnerXml.Replace($AzureUploader_StorageConnStrTag, $AzureUploader_StorageConnStr)

    Write-Host "Replacing: $AzureUploader_ContainerNameTag with: $AzureUploader_ContainerName"
    $config.InnerXml = $config.InnerXml.Replace($AzureUploader_ContainerNameTag,$AzureUploader_ContainerName)

    Write-Host "Replacing: $AzureUploader_KeyVaultSecretUriTag with: $AzureUploader_KeyVaultSecretUri"
    $config.InnerXml = $config.InnerXml.Replace($AzureUploader_KeyVaultSecretUriTag,$AzureUploader_KeyVaultSecretUri)

    Write-Host "Replacing: $AzureUploader_AzureKeyVaultClientIdTag with: $AzureUploader_AzureKeyVaultClientId"
    $config.InnerXml = $config.InnerXml.Replace($AzureUploader_AzureKeyVaultClientIdTag,$AzureUploader_AzureKeyVaultClientId)

    Write-Host "Replacing: $AzureUploader_CertificateThumbprintTag with: $AzureUploader_CertificateThumbprint"
    $config.InnerXml = $config.InnerXml.Replace($AzureUploader_CertificateThumbprintTag,$AzureUploader_CertificateThumbprint)

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


function Update-Ftp{
param([switch]$UseDummyOyster)

	$retVal = 0

    Write-Host "Updating CASC config"
    $serverIP = $machines.Item("TS-CAS1")
    $configFile = "Web.config"
    $binaryPath = "CACC\CSCPortal"

    $configInfo = Update-ConfigFiles -ServerIP $serverIP -ConfigFile $ConfigFile -ApplicationPath $binaryPath

	if(!$UseDummyOyster)
    {
        if(![string]::IsNullOrEmpty($OysterServicePassword))
        {
            $configInfo.Content | Update-ConfigValue -AppSettingKey "OysterServicePassword" -ConfigSection "OysterService" -Value $OysterServicePassword | Out-Null
        }

        $configInfo.Content | Update-ConfigValue -ConfigSection "OysterWebsite" -AppSettingKey "OysterBaseUrl"  -Value "http://$OysterWebReference" | Out-Null
        $configInfo.Content | Update-ConfigValue -ConfigSection "OysterService" -AppSettingKey "GetOysterCardForUserUrlV2"  -Value "http://$OysterServiceReference/GetOysterCardForUserV2" | Out-Null
    }

	$configInfo.Content.Save($configInfo.Path)
    Write-Host "$($configInfo.Path) updated"
	Write-Host ""

    Write-Host "Updating CAS config"
    $binaryPath = "CACC\CSCSupport"
    Update-ConfigFiles -ServerIP $serverIP -ConfigFile $ConfigFile -ApplicationPath $binaryPath | Out-Null

    Write-Host "Updating CASC Customer Service config"
    $binaryPath = "CACC\CSCCustomerService"
	Update-ConfigFiles -ServerIP $serverIP -ConfigFile $ConfigFile -ApplicationPath $binaryPath | Out-Null

    Write-Host "Updating CASC Mock Services config"
    $binaryPath = "CACC\MockServices"
    Update-ConfigFiles -ServerIP $serverIP -ConfigFile $ConfigFile -ApplicationPath $binaryPath | Out-Null

    Write-Host "Updating SDM Portal config"
    $binaryPath = "SDM\SDMPortal"
    Update-ConfigFiles -ServerIP $serverIP -ConfigFile $ConfigFile -ApplicationPath $binaryPath | Out-Null

	#### OyBO AzureMobileUploader Config ####
	$configFile = "Tfl.Ft.OyBo.AzureMobileUploader.Host.exe.config"
    $binaryPath = "AzureMobileUploader"
    Update-ConfigFiles -ServerIP $serverIP -ConfigFile $ConfigFile -ApplicationPath $binaryPath | Out-Null

    #### OyBO Transaction File Processor Config ####
    $serverIP = $machines.Item("TS-OYBO1")
	$configFile = "Tfl.Ft.OyBo.FileProcessor.Host.exe.config"
    $binaryPath = "OTFP"
    Update-ConfigFiles -ServerIP $serverIP -ConfigFile $ConfigFile -ApplicationPath $binaryPath | Out-Null

    #### Notifications Image Url
    $serverIP = $machines.Item("TS-SAS1")
    $configFile = "SendEmailService.exe.config"
    $binaryPath = "Notifications\SendMailService"
    Update-ConfigFiles -ServerIP $serverIP -ConfigFile $ConfigFile -ApplicationPath $binaryPath | Out-Null

	$retVal
}

function Update-SSO{
param([switch]$UseDummyOyster)

    $retVal = 0

    #### SSO Configs ####
    $serverIP = $machines.Item("TS-DB2")
    $configFile = "Web.config"
    $binaryPath = "SSO\Website"

    $configInfo = Update-ConfigFiles -ServerIP $serverIP -ConfigFile $ConfigFile -ApplicationPath $binaryPath

    $configInfo.Content.Save($configInfo.Path)
    Write-Host "$($configInfo.Path) updated"
	Write-Host ""

    #### SSO Service Web Config ####
    $binaryPath = "SSO\SingleSignOnServices"
    $configInfo = Update-ConfigFiles -ServerIP $serverIP -ConfigFile $ConfigFile -ApplicationPath $binaryPath

    if(!$UseDummyOyster){
        $configInfo.Content `
		| Update-ConfigValue -AppSettingKey "OysterBaseUrl"	-Value "http://$script:OysterServiceReference`:81/" `
        | Update-ConfigValue -AppSettingKey "MockOyster"	-Value "false" | Out-Null
    }

    #### SSO Customer Change Notification Worker Service - Oyster ####
    $serverIP = $script:SSOCISIP # $SSONotificationWorkerReference
    $configFile = "Customer.Change.NotificationWorker.exe.config"
    $binaryPath = "SSO\Customer.Change.NotificationWorkerOyster"

    if (!(Test-Path "\\$serverIP\$DriveLetter`$\TFL\$binaryPath\")) {
        Write-Host "SSO Customer Change Notification Worker Service - Oyster was not found - skipping"
    }
    else {
        Write-Host "Modifying SSO Customer Change Notification Worker Service - Oyster config"

        $configInfo = Update-ConfigFiles -ServerIP $SSOCISIP -ConfigFile $configFile -ApplicationPath $binaryPath -Optional

        if ($configInfo -ne $null)
        {
			if($script:OysterWebReference) {
                $configInfo.Content | Update-ConfigValue -AppSettingKey "OysterBaseUrl"  -Value "http://$script:OysterWebReference" | Out-Null
            }

            if($script:OysterServicePassword) {
                $configInfo.Content | Update-ConfigValue -AppSettingKey "OysterAuthPassword"  -Value $script:OysterServicePassword | Out-Null
            }

	        $configInfo.Content.Save($configInfo.Path)
            Write-Host "$($configInfo.Path) updated"
		    Write-Host ""
        }
    }

	####
    #### SSO Customer Change Notification Worker Service - Travel Alerts ####   No Instance Deployed in FTP INT
    ####

    $retVal
}

function Update-SsoDb{
[cmdletbinding()]
param()

    $retVal = 0
    $serverIP = $machines.Item("TS-DB2")

    #### SSO Database (Product table) Update ####
    Write-Host "Modifying SSO Database Product table"
    $datasource = Get-DataSource -Computer $serverIP -InstanceName "Inst3"
    Write-Host "Updating SingleSignOn Database on $datasource"

    $connectionString = Get-ConnectionString -TargetDatabase "SingleSignOn" -DataSource $datasource -UseSqlAuth -Username "SingleSignOn" -Password "ss0w3Bus3r"

    # 4 Customer Self Care	= A3AC81D4-80E8-4427-B348-A3D028DFDBE7
    $cmdText = "EXEC [dbo].[ProductUpdate]
        @validateUrl = 'http://$script:FTPWebReference/HomePage/Validate',
        @signoutUrl = 'http://$script:FTPWebReference/HomePage/LogOff',
        @homeUrl = 'http://$script:FTPWebReference',
        @defaultUrl = NULL,
        @productToken = 'A3AC81D4-80E8-4427-B348-A3D028DFDBE7',
        @protectedUrl = 'http://$script:FTPWebReference/Dashboard';
        update products set RegistrationUrl = 'http://$script:FTPWebReference/Registration/NewRegistration' where ProductToken = 'A3AC81D4-80E8-4427-B348-A3D028DFDBE7';"

    $success = $connectionString | Invoke-ExecuteNonQuery -CommandText $cmdText

    if(!$success){
        return 1
    }

    # 7 Customer Self Care Support	6687E912-D120-461E-9DA9-3C0288629F4F
    $cmdText = "EXEC [dbo].[ProductUpdate]
        @validateUrl = 'http://$script:FTPWebReference`:8080/Account/Validate',
        @signoutUrl = 'http://$script:FTPWebReference`:8080/Account/LogOff',
        @homeUrl = 'http://$script:FTPWebReference`:8080',
        @defaultUrl = NULL,
        @productToken = '6687E912-D120-461E-9DA9-3C0288629F4F',
        @protectedUrl = 'http://$script:FTPWebReference`:8080/Customer/Find';"
        #update products set RegistrationUrl = 'http://$script:FTPWebReference/Registration/NewRegistration' where ProductToken = 'A3AC81D4-80E8-4427-B348-A3D028DFDBE7'; "

    $success = $connectionString | Invoke-ExecuteNonQuery -CommandText $cmdText

    if(!$success){
        return 1
    }

    # 1 SSO 88B73293-96A1-4131-97F5-20026B7FB2D9
    $cmdText = "IF (select count(*) from dbo.Products where ProductToken = '88B73293-96A1-4131-97F5-20026B7FB2D9') = 1
                BEGIN
                EXEC [dbo].[ProductUpdate]
                    @validateUrl = null,
                    @signoutUrl = null,
                    @homeUrl = 'http://$script:SSOWebReference',
                    @defaultUrl = null,
                    @productToken = '88B73293-96A1-4131-97F5-20026B7FB2D9',
                    @protectedUrl = 'http://$script:FTPWebReference/Dashboard'
                END; "

    $success = $connectionString | Invoke-ExecuteNonQuery -CommandText $cmdText

    if(!$success){
        return 1
    }

    # 9 SDM Portal 2F31D3EF-7EA9-4378-88D0-9A92EF8E9634
    # update Products set ProtectedUrl='http://' + @CASC_IP + '/Dashboard' , LoginUrl='http://' + @SSO_IP where ProductName='SSO'
    $cmdText = "IF (select count(*) from dbo.Products where ProductToken = '2f31d3ef-7ea9-4378-88d0-9a92ef8e9634') = 1
                BEGIN
                EXEC [dbo].[ProductUpdate] @validateUrl = 'http://$script:FTPWebReference`:8081/Account/Validate',
                    @signoutUrl = 'http://$script:FTPWebReference`:8081/Account/SsoSignOut',
                    @homeUrl = 'http://$script:FTPWebReference`:8081',
                    @defaultUrl = null ,
                    @productToken = '2f31d3ef-7ea9-4378-88d0-9a92ef8e9634'
                END; "

    $success = $connectionString | Invoke-ExecuteNonQuery -CommandText $cmdText

    if(!$success){
        return 1
    }

    # Banner table to be updated:
    $cmdText = "UPDATE [SingleSignOn].[dbo].[Banners]
                SET [ValidToDate]=DATEADD(y,10,getdate())
                WHERE Id=1; "

    $success = $connectionString | Invoke-ExecuteNonQuery -CommandText $cmdText

    if(!$success){
        return 1
    }

    if(!$useDummyOyster) {
        $cmdText = " exec [dbo].[ProductUpdate]
                        @validateUrl = NULL,
                        @signoutUrl = 'http://$script:OysterWebReference/oyster/oysterlogout.do',
                        @homeUrl = 'login',
                        @defaultUrl = 'http://$script:OysterWebReference/oyster/entry.do',
                        @productToken = '8EAD5CF4-4624-4389-B90C-B1FD1937BF1F',
                        @protectedUrl = 'http://$script:OysterWebReference/oyster/showCards.do?_o=KTaO6YfdBpIdcN8DLNDKgw%3D%3D'
                        END; "
    }
    else {
        $cmdText = " exec [dbo].[ProductUpdate] NULL, '$script:SSOErrorPage', '$script:SSOErrorPage',null,'8EAD5CF4-4624-4389-B90C-B1FD1937BF1F'"
    }

    $success = $connectionString | Invoke-ExecuteNonQuery -CommandText $cmdText

    if(!$success){
        return 1
    }

    Write-Host "SSO Database Updated."
    Write-Host ""

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

    $script:OysterWebTag = '$OysterWebReference'
    $script:OysterSvcTag = '$OysterServiceReference'

    $machines_ = @{
		"TS-CAS1" = $FTPWebIP
		"TS-CIS1" = $FTPCisIP
		"TS-DB1" = $FTPDbIP
		"TS-DB2" = $FTPDb2IP
		"TS-SAS1" = $FTPSASIP
		"TS-OYBO1" = $FtpOtfpIP
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
	$script:SSOWebReference = ([string]::IsNullOrEmpty($SSOWebSiteAlias)) | Get-ConditionalValue -TrueValue $machines.Item("TS-DB2") -FalseValue $SSOWebSiteAlias
	$script:SSOWebServiceReference = ([string]::IsNullOrEmpty($SSOWebServiceAlias)) | Get-ConditionalValue -TrueValue $machines.Item("TS-DB2") -FalseValue $SSOWebServiceAlias


    $script:SSOCISIP = $machines.Item("TS-CIS1") # For notification workers

	$script:SSONotificationWorkerReference = $SSOCISIP
    $script:SSOErrorPage = "http://$script:SSOWebReference/error"

	$useDummyOyster = $true

	if(![string]::IsNullOrEmpty($OysterRig)){
		$useDummyOyster = $false
	}

	if((![string]::IsNullOrEmpty($OysterWebSiteAlias)) -or (![string]::IsNullOrEmpty($OysterWebServiceAlias))) {
        $useDummyOyster = $false

        if(([string]::IsNullOrEmpty($OysterWebSiteAlias)) -or ([string]::IsNullOrEmpty($OysterWebServiceAlias))) {
		    Write-Warning "If specifying an Oyster Web Alias, you must specify them for both Web and Service. Even if they are the same"
		    return 1;
        }
    }

    if(!$useDummyOyster)
    {
        if ($OysterRig)
        {
			$vAppStartingState = Get-StartingState -Name $OysterRig -Oyster

			if(!$vAppStartingState.Exists){
				Write-Warning "Rig $OysterRig is not in a valid start state and linking cannot continue. Exiting."
				return 1
			}

			$OysterWebIP = Get-VAppExternalIP -VApp $script:vAppOyster -ComputerName "Oyster_Template"

			Write-Host "Using Oyster Rig: $OysterRig ($OysterWebIP)"

            $script:OysterWebReference = $OysterWebIP
            if (![string]::IsNullOrEmpty($OysterWebAlias)) {
                $script:OysterWebReference = $OysterWebAlias
            }

    		$script:OysterServiceReference = $OysterWebIP
            $script:OysterSvcIP = $OysterWebIP
        }
        else {
	        $script:OysterWebReference = $OysterWebSiteAlias
	        $script:OysterServiceReference = $OysterWebServiceAlias
            Write-Host "Oyster References: Web - $script:OysterWebReference Services - $script:OysterServiceReference"
        }
	}

    $retVal = Update-Ftp -UseDummyOyster:$useDummyOyster

	if($retVal -ne 0){
		return $retVal
	}

    $retVal = Update-SSO -UseDummyOyster:$useDummyOyster

	if($retVal -ne 0){
		return $retVal
	}

    $retVal = Update-SsoDb

	if($retVal -ne 0){
		return $retVal
	}

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

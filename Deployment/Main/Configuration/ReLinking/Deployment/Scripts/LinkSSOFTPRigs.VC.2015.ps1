param
(             
    [string] $vAppName = $(throw 'vAppName parameter is required'), # 'FTM.Stabilisation.RTN', # 
    
    [string] $FTPWebAlias,
    [string] $SSOWebSiteAlias,		# "VIP_SSO_WEB",       #optional
    [string] $SSOWebServiceAlias,	# "VIP_SSO_WEBSERVICE",       #optional

	[string] $OysterRig, 
    [string] $OysterWebSiteAlias,		# "VIP_OYS_WEB",       #optional
    [string] $OysterWebServiceAlias,	# "VIP_OYS_WEBSERVICE",       #optional
    [string] $OysterServicePassword,	# "OYSPWD",

    [string] $DevelopmentModeOn = "false",
    [string] $Password = "LMTF`$Bu1ld",
    [bool]   $TurnOff_EnableCacheManagerCaching = $true,

    [string] $AzureUploader_StorageConnStr = "DefaultEndpointsProtocol=https;AccountName=otfp;AccountKey=+D1voWVu1PdFtqnYEJ5vy09Ek2DoyrvbLcRiCiL7GUbWD6PJNTWCFLigjBB4UJRePu+zhfCmbpspvE9SyJF7mg==", # optional but does need a default
    [string] $AzureUploader_ContainerName = "inbox", # optional but does need a default

    [string] $AzureUploader_KeyVaultSecretUri = "", 
    [string] $AzureUploader_AzureKeyVaultClientId = "", 
    [string] $AzureUploader_CertificateThumbprint = "",

    # Option to bypass vCloud while the API is unusably slow.
    [string]$FTPWebIP = "",
    [string]$FTPCisIP = "",
    [string]$FTPDbIP  = "",
    [string]$FTPDb2IP = "",
    [string]$FTPSASIP = "",
    [string]$FTP_OTFP_IP = "",
    [string]$FTP_AzUPLDR_IP = ""
)

########################################################################
#
#  This script is for configuring FTP and SSO in a vCloud Integration Rig with SSO on DB2
#
#  This script must be run against an integration vApp.
#  
#  It cannot be used to stub SSO   
#
########################################################################

function main
{
    [string] $CACCIPTag = '$CASCSiteIP'                        # TS-CAS1 is turned into this   - not found explicitly in Stabilisation build
    [string] $SSOIPTag = '$SsoWebSiteIP:Port'                  # CASC_CSCWebConfigSsoWebsiteBaseUrl, SSO_Website_BaseUrl
    [string] $SSOServiceIPTag = '$SsoWebServiceFacadeIP:Port'  # CASC_CSCWebConfigSsoServiceBaseUrl, CASC_CSCWebConfigGetOysterCardForUserUrl, SSO_Service_BaseUrl
    [string] $OysterWebTag = '$OysterWebReference'
    [string] $OysterSvcTag = '$OysterServiceReference'
    [string] $AzureUploader_StorageConnStrTag = '$AzureUploader_StorageConnStr'
    [string] $AzureUploader_ContainerNameTag = '$AzureUploader_ContainerName'
    [string] $AzureUploader_KeyVaultSecretUriTag = '$OyBO_AzureUploader_KeyVaultSecretUriForAzureBlobStorage'
    [string] $AzureUploader_CertificateThumbprintTag = '$OyBO_AzureUploader_CertificateThumbprint'
    [string] $AzureUploader_AzureKeyVaultClientIdTag = '$OyBO_AzureUploader_AzureKeyVaultClientId'
    
    Write-Output ""
    Write-Output "### Starting Post-Deployment Configuration of External Rig References (link script) ###"  # "### Starting link of SSO, FTP and Oyster Rigs  ###"
    Write-Output "### "
    Write-Output "### on $vAppName"
    Write-Output ""

  try
  {	
	Write-Output "Loading Deployment.Utils"

    $scriptpath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)
    $assemblyPath = join-path $scriptpath "..\Tools\DeploymentTool\"
	[System.Reflection.Assembly]::LoadFrom("$assemblyPath\Deployment.Utils.dll");
    Write-Output ""

	#$DBLogger = New-Object -TypeName Deployment.Utils.Logging.DeploymentDatabaseLogging
	#$DBLogger.Initialise_vCloudEventLog($vAppName, $myinvocation.scriptname, $env:COMPUTERNAME, "")

	Write-Output "Initialising VCLoud Module for use"
	$vCloudUrl = 'https://vcloud.onelondon.tfl.local'
	$vCloudOrg = 'ce_organisation_td'
	$vCloudUser = 'zSVCCEVcloudBuild'
	$vCloudPassword = 'P0wer5hell'

	Write-Output "Loading VCloudService and Creating connection to $vCloudUrl. Org: $vCloudOrg"
	$vCloudService = New-Object -TypeName Deployment.Utils.VirtualPlatform.VCloud.VCloudService
	$vCloudService.Initialise_vCloudSession($vCloudUrl, $vCloudOrg, $vCloudUser, $vCloudPassword) | Out-Host
	Write-Output ""

    ### Connect to FTP vApp
    $vApp = $vCloudService.GetVapp($vAppName)
	if($vApp -ne $null)
    {
        $exitCode = 3
        try 
		{
            $machine = "TS-CAS1";
            if ([string]::IsNullOrEmpty($FTPWebIP)) { $FTPWebIP = $vCloudService.Get_vCloudMachineIpAddress($machine, $vAppName) }
            Cache-Creds -ip $FTPWebIP -Password $Password -Machine $machine -Name "FTPWebIP"

            $FTP_AzUPLDR_IP = $FTPWebIP
            Cache-Creds -ip $FTP_AzUPLDR_IP -Password $Password -Machine $machine -Name "FTP_AzUPLDR_IP"

            $machine = "TS-CIS1";
			if ([string]::IsNullOrEmpty($FTPCisIP)) { $FTPCisIP = $vCloudService.Get_vCloudMachineIpAddress($machine, $vAppName) }
            Cache-Creds -ip $FTPCisIP -Password $Password -Machine $machine -Name "FTPCisIP"

            $machine = "TS-DB1";
            if ([string]::IsNullOrEmpty($FTPDbIP)) { $FTPDbIP = $vCloudService.Get_vCloudMachineIpAddress($machine, $vAppName) }
            Cache-Creds -ip $FTPDbIP -Password $Password -Machine $machine -Name "FTPDbIP"

            $machine = "TS-DB2";
            if ([string]::IsNullOrEmpty($FTPDb2IP)) { $FTPDb2IP = $vCloudService.Get_vCloudMachineIpAddress($machine, $vAppName) }
            Cache-Creds -ip $FTPDb2IP -Password $Password -Machine $machine -Name "FTPDb2IP"

            $machine = "TS-SAS1";
			if ([string]::IsNullOrEmpty($FTPSASIP)) { $FTPSASIP = $vCloudService.Get_vCloudMachineIpAddress($machine, $vAppName) }
            Cache-Creds -ip $FTPSASIP -Password $Password -Machine $machine -Name "FTPSASIP"
            
            $machine = "TS-SBUS1";
			if ([string]::IsNullOrEmpty($FTP_OTFP_IP)) { $FTP_OTFP_IP = $vCloudService.Get_vCloudMachineIpAddress($machine, $vAppName) }
            Cache-Creds -ip $FTP_OTFP_IP -Password $Password -Machine $machine -Name "FTP_OTFP_IP"
		}
		catch 
        {
		    Write-Error "TERMINATING: Error getting machine details for '$machine' from vCloud in vApp '$vAppName', exiting with code $exitCode" 
		    Exit $exitCode;
		}

        # Override IP with VIP alias - mainly for Cubic rigs where we have to mimic thier named DNS entries
        [string] $FTPWebReference = if (![string]::IsNullOrEmpty($FTPWebAlias)) { $FTPWebAlias } else { $FTPWebIP };
    }
    else
    {
        throw "FTP rig $vAppName does not exist"
    }

    # Set SSO References
    if (![string]::IsNullOrEmpty($SSOWebSiteAlias))
    {
        $SSOWebReference = $SSOWebSiteAlias
    } 
    else 
    {
        $SSOWebReference = $FTPDb2IP
    }
    if (![string]::IsNullOrEmpty($SSOWebServiceAlias))
    {
        $SSOWebServiceReference = $SSOWebServiceAlias
    } 
    else 
    {
        $SSOWebServiceReference = $FTPDb2IP
    }
    $SSOWebIP = $FTPDb2IP # for connect to machine to  do replacements - not for actual replacements
    $SSOCISIP = $FTPCisIP # For notification workers 

    $SSOServiceIP = ("TS-DB2:8081"); # Replaces $SSOServiceIPTag

	$SSONotificationWorkerReference = $FTPCisIP; 
    $SSODBIP = $FTPDb2IP;	# For Products Table Updates Only
   
    $SSOAFhost = "TS-DB2"
    $SSOErrorPage = "http://$SSOWebReference/error"
    

    #####
    ## Oyster or Dummy
    #####
    $useDummyOyster = $true;
    if(![string]::IsNullOrEmpty($OysterRig))
    {
        $useDummyOyster = $false
    }
    if((![string]::IsNullOrEmpty($OysterWebSiteAlias)) -or (![string]::IsNullOrEmpty($OysterWebServiceAlias)))
    {
        $useDummyOyster = $false
        
        if(([string]::IsNullOrEmpty($OysterWebSiteAlias)) -or ([string]::IsNullOrEmpty($OysterWebServiceAlias)))
        {
		    Write-Warning "If specifying an Oyster Web Alias, you must specify them for both Web and Service. Even if they are the same"
		    Exit 4;
        }
    }

	if($useDummyOyster)
	{
		Write-Output "No Oyster rig specified, using dummy values for Oyster"
	    $OysterWebIP = "dummy"
	    $OysterSvcIP = "dummy"
	}
	else
	{
        if (![string]::IsNullOrEmpty($OysterRig))
        {
            $vApp_oyster = $vCloudService.GetVapp($OysterRig);
    	    if ($vApp_oyster -ne $null)
    	    {
    		    Write-Output "Using Oyster Rig: $OysterRig"
                # TODO Handle Bad Machine Name
    		    $OysterWebIP = $vCloudService.Get_vCloudMachineIPAddress("Oyster_Template", $OysterRig);
    
                $OysterWebReference = $OysterWebIP;
                if (![string]::IsNullOrEmpty($OysterWebAlias))
                {
                    $OysterWebReference = $OysterWebAlias
                }
    
    		    $OysterServiceReference = $OysterWebIP # Single server : Get-LabManagerMachineIPAddress $OysterRig "prod-web02";
    	    }
            else
            {
                throw "Oyster rig $OysterRig does not exist"
            }
        }
        else
        {
	        $OysterWebReference = $OysterWebSiteAlias
	        $OysterServiceReference = $OysterWebServiceAlias

            Write-Output "Oyster References;  Web: $OysterWebReference,  Services: $OysterServiceReference"
        }
	}
    # End Oyster Handling Setup

    Write-Output "FTP Web IP = $FTPWebIP"
    Write-Output "FTP SAS IP = $FTPSASIP"
    Write-Output "FTP OTFP IP = $FTP_OTFP_IP"
    Write-Output "FTP AzUPLDR IP = $FTP_AzUPLDR_IP"
    Write-Output ""
	Write-Output "SSO Web IP = $SSOWebReference"
    Write-Output "SSO DB IP  = $SSODBIP"
    Write-Output "SSO Svc IP = $SSOServiceIP"
	Write-Output "SSO CIS IP = $FTPCisIP"
    Write-Output "SSO AppFabric Host = $SSOAFhost"
    Write-Output "Error page = $SSOErrorPage"	
    Write-Output ""
    Write-Output "OOL Web Reference = $OysterWebReference"
    Write-Output "OOL Svc Reference = $OysterServiceReference"
    Write-Output ""	
	
    New-Variable -Name configTxt -Value "" -Option AllScope # Option exposes variable to all child scopes (but not parents)
    [xml] $configXML = "";
    

    #### 
    #### CASC Web Config
    ####
        $SRVR = $FTPWebIP
        $CFGFILE = "Web.config"
        $DFTLPATH = "CACC\CSCPortal"
        
        PrepareConfigFilesForLinking -ServerIP $SRVR -ConfigFile $CFGFILE -DTFLPath $DFTLPATH
        
        Apply-StandardReplacements -ToConfig $configTxt  
        
        Set-Content  "\\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE" $configTxt
        Write-Output "  \\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE written."
	    Write-Output ""

	    [xml] $configXML = Get-Content "\\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE";

        if(!$useDummyOyster)
        {
            if(![string]::IsNullOrEmpty($OysterServicePassword))
            {
                SetValue -ConfigSection "OysterService" -AppSettingKey "OysterServicePassword"  -As $OysterServicePassword -In $configXML 
            }
        }
        else
        {
            SetValue -ConfigSection "OysterWebsite" -AppSettingKey "OysterBaseUrl"            -As "http://$FTPWebReference`:8799/" -In $configXML
            SetValue -ConfigSection "OysterService" -AppSettingKey "GetOysterCardForUserUrlV2"  -As "http://TS-CAS1:8799/api/oyster" -In $configXML
        }

        ####
        #### Enable Cache Manager Caching ####
        ####
        if ($TurnOff_EnableCacheManagerCaching -eq $true)
        {
            Write-Output "TurnOff EnableCacheManagerCaching: Setting EnableCacheManagerCaching false"
            $configXML.SelectNodes("configuration/CacheManager/add[@key='EnableCacheManagerCaching']/@value") | % {$_.Value = "false" };
        } 

	    $configXML.Save("\\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE")
        Write-Output  "\\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE written"
	    Write-Output ""
       
    ####
    #### CAS Admin Config ####
    ####
        $SRVR = $FTPWebIP
        $CFGFILE = "Web.config"
        $DFTLPATH = "CACC\CSCSupport"
        
        PrepareConfigFilesForLinking -ServerIP $SRVR -ConfigFile $CFGFILE -DTFLPath $DFTLPATH
        
        Apply-StandardReplacements -ToConfig $configTxt  
        
        Set-Content  "\\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE" $configTxt
        Write-Output "  \\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE written."
	    Write-Output ""
        
    ####
    #### CASC Customer Service ####
    ####
        $SRVR = $FTPWebIP
        $CFGFILE = "Web.config"
        $DFTLPATH = "CACC\CSCCustomerService"
        
        PrepareConfigFilesForLinking -ServerIP $SRVR -ConfigFile $CFGFILE -DTFLPath $DFTLPATH
        
        Apply-StandardReplacements -ToConfig $configTxt  
        
        Set-Content  "\\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE" $configTxt
        Write-Output "  \\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE written."
	    Write-Output ""

    ####
    ####  CASC Mock Services ####
    ####
        $SRVR = $FTPWebIP
        $CFGFILE = "Web.config"
        $DFTLPATH = "CACC\MockServices"
 
        PrepareConfigFilesForLinking -ServerIP $SRVR -ConfigFile $CFGFILE -DTFLPath $DFTLPATH
		
        Apply-StandardReplacements -ToConfig $configTxt  
        
        Set-Content  "\\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE" $configTxt
        Write-Output "  \\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE written."
	    Write-Output ""

    ####
    #### SDM Portal Config ####
    ####
        $SRVR = $FTPWebIP
        $CFGFILE = "Web.config"
        $DFTLPATH = "SDM\SDMPortal"

        PrepareConfigFilesForLinking -ServerIP $SRVR -ConfigFile $CFGFILE -DTFLPath $DFTLPATH
        
        Apply-StandardReplacements -ToConfig $configTxt  
        
        Set-Content  "\\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE" $configTxt
        Write-Output "  \\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE written."
	    Write-Output ""
    
    
    ####
    #### OyBO Transaction File Processor Config ####
    ####
        $SRVR = $FTP_OTFP_IP
        $CFGFILE = "Tfl.Ft.OyBo.FileProcessor.Host.exe.config"
        $DFTLPATH = "OTFP"

        PrepareConfigFilesForLinking -ServerIP $SRVR -ConfigFile $CFGFILE -DTFLPath $DFTLPATH
        
        Apply-StandardReplacements -ToConfig $configTxt  
        
        Set-Content  "\\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE" $configTxt
        Write-Output "  \\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE written."
		Write-Output ""                 	
    
    
    ####
    #### OyBO AzureMobileUploader Config ####
    ####
        $SRVR = $FTP_AzUPLDR_IP
        $CFGFILE = "Tfl.Ft.OyBo.AzureMobileUploader.Host.exe.config"
        $DFTLPATH = "AzureMobileUploader"
        
        PrepareConfigFilesForLinking -ServerIP $SRVR -ConfigFile $CFGFILE -DTFLPath $DFTLPATH
        
        Apply-StandardReplacements -ToConfig $configTxt  
        
        Set-Content  "\\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE" $configTxt
        Write-Output "  \\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE written."
		Write-Output ""                 	
    


    ####
    #### SSO Configs ####
    ####
        $SRVR = $SSOWebIP
        $CFGFILE = "Web.config"
        $DFTLPATH = "SSO\Website"
        
        #PrepareConfigFilesForLinking -ServerIP $SSOWebIP -ConfigFile "Web.config" -DTFLPath "SSO\Website"
        PrepareConfigFilesForLinking -ServerIP $SRVR -ConfigFile $CFGFILE -DTFLPath $DFTLPATH

		[xml] $configXML = Get-Content "\\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE";	
		
    	if(!$useDummyOyster)
        {
            # Correct = http://<<Oyster website URL>>/oyster/addCard.do
            #SetValue -AppSettingKey "OysterAddExistingCardUrl"		-In $configXML -As "http://$OysterWebReference/oysterAddExistingCardUrl/unknownAtTheMinute"
            SetValue -AppSettingKey "OysterAddExistingCardUrl"		-In $configXML -As "http://$OysterWebReference/oyster/addCard.do"
                        
            SetValue -AppSettingKey "OysterAddCardExistingUserUrl"	-In $configXML -As "http://$OysterWebReference/oyster/addCard.do"
            SetValue -AppSettingKey "OysterAddCardNewUserUrl"		-In $configXML -As "http://$OysterWebReference/oyster/createUserFromCard.do"
            SetValue -AppSettingKey "OysterSiteBase"				-In $configXML -As "http://$OysterWebReference"
        }
        else
        {
            SetValue -AppSettingKey "OysterAddExistingCardUrl"		-As $SSOErrorPage -In $configXML    # $SSOErrorPage = "http://$SSOWebIP/error"
            SetValue -AppSettingKey "OysterAddCardExistingUserUrl"	-As $SSOErrorPage -In $configXML
            SetValue -AppSettingKey "OysterAddCardNewUserUrl"		-As $SSOErrorPage -In $configXML
            SetValue -AppSettingKey "OysterSiteBase"				-As $SSOErrorPage -In $configXML
        }

        SetValue -AppSettingKey "DefaultSsoRedirectProtectedUrl" -In $configXML -As "http://$FTPWebReference/dashboard" 
        SetValue -AppSettingKey "DefaultSsoRedirectPublicUrl"	 -In $configXML -As "http://$FTPWebReference/HomePage"     
        SetValue -AppSettingKey "DevelopmentModeOn"				 -In $configXML -As "$DevelopmentModeOn" 

        SetValue -AppSettingKey "PageStyleToUse"  -As "FTP" -In $configXML

        $redirectList = ""
        if ($FTPWebReference -ne $FTPWebIP)
        {
            $redirectList = $FTPWebReference + ";" + $FTPWebIP; # IP really required, DNS to be safe.
        }
        else
        {
            $redirectList = $FTPWebIP; # IP really required, DNS to be safe.
        }
        if(!$useDummyOyster)
        {
            $redirectList += ";" + $OysterWebReference + ";" + $OysterServiceReference + ";" + $OysterSvcIP # Cubic Rigs require IP's also
        }		
	    
        SetValue -AppSettingKey "SsoRedirectWhiteListUrls"	-As "$redirectList" -In $configXML

    	$configXML.Save("\\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE");
        Write-Output "  \\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE saved"
		Write-Output ""
        
        ######## 
        #### SSO Service Web Config ####
        ######## 
        $SRVR = $SSOWebIP
        $CFGFILE = "Web.config"
        $DFTLPATH = "SSO\SingleSignOnServices"
        
        PrepareConfigFilesForLinking -ServerIP $SRVR -ConfigFile $CFGFILE -DTFLPath $DFTLPATH

        [xml] $configXML = Get-Content "\\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE.original";
        
        SetValue -AppSettingKey "DevelopmentModeOn"	-As "$DevelopmentModeOn"            -In $configXML
        SetValue -AppSettingKey "EmailUrl"		    -As "http://$SSOWebReference"       -In $configXML
        SetValue -AppSettingKey "CASAdminUrl"	    -As "http://$FTPWebReference`:8080" -In $configXML
        
        if(!$useDummyOyster)
        {
            SetValue -AppSettingKey "OysterBaseUrl"	-As "http://$OysterServiceReference`:81/" 	-In $configXML
            SetValue -AppSettingKey "MockOyster"	-As "false"						-In $configXML
        }
        else
        {
            SetValue -AppSettingKey "OysterBaseUrl"	-As "$SSOErrorPage" -In $configXML
            SetValue -AppSettingKey "MockOyster"	-As "true"			-In $configXML
        }
        
        # handle AppFabric 
        if ($SSOAFhost -eq $null) # then disable
        {
            SetValue -AppSettingKey "CacheHeartbeatInterval" -As "6000000" -In $configXML
            SetValue -AppSettingKey "CacheHeartbeatEnabled"	 -As "true"    -In $configXML
        }
        else
        {
            SetValue -AppSettingKey "CacheHeartbeatInterval" -As "60000" -In $configXML
            SetValue -AppSettingKey "CacheHeartbeatEnabled"	 -As "false" -In $configXML
            $configXML.SelectNodes("configuration/dataCacheClient/hosts/host/@name") | % {$_.Value = $SSOAFhost };
        }
        
    	$configXML.Save("\\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE");
        Write-Output "  \\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE saved"
		Write-Output ""
        
        ######## 
        #### SSO Validation Service Web Config ####
        ######## 
        if ($SSOAFhost -eq $null) # then disable
        {
            $SRVR = $SSOWebIP
            $CFGFILE = "Web.config"
            $DFTLPATH = "SSO\SSOValidation"
        
            PrepareConfigFilesForLinking -ServerIP $SRVR -ConfigFile $CFGFILE -DTFLPath $DFTLPATH

            [xml] $configXML = Get-Content "\\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE.original";
            # handle AppFabric
            SetValue -AppSettingKey "CacheHeartbeatInterval"	-As "6000000" -In $configXML
            SetValue -AppSettingKey "CacheHeartbeatEnabled"	-As "true" -In $configXML
                        
		    $configXML.Save("\\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE");		
            Write-Output "  \\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE written"
		    Write-Output ""
        }

        <######## 
        #### SSO Customer Change Notification Worker Service ####
        ########       
        PrepareConfigFilesForLinking -ServerIP $SSONotificationWorkerReference -ConfigFile "Customer.Change.NotificationWorker.exe.config" -DTFLPath "SSO\Customer.Change.NotificationWorker"

        [xml] $configXML = Get-Content "\\$SSONotificationWorkerReference\d`$\TFL\SSO\Customer.Change.NotificationWorker\Customer.Change.NotificationWorker.exe.config.original";
        
        #SetValue -AppSettingKey "FtpUrl"			-As "http://$FTPWebReference`:8726/api/DataUpdate/UpdateMasterCustomer" -In $configXML
        
        $configXML.Save("\\$SSONotificationWorkerReference\d`$\TFL\SSO\Customer.Change.NotificationWorker\Customer.Change.NotificationWorker.exe.config");
        Write-Output "\\$SSONotificationWorkerReference\d`$\TFL\SSO\Customer.Change.NotificationWorker\Customer.Change.NotificationWorker.exe.config written"
		Write-Output ""#>
        
        ######## 
        #### SSO Customer Change Notification Worker Service - Oyster ####
        ######## 
        $SRVR = $SSOCISIP # $SSONotificationWorkerReference
        $CFGFILE = "Customer.Change.NotificationWorker.exe.config"
        $DFTLPATH = "SSO\Customer.Change.NotificationWorkerOyster"
        
        if (!(Test-Path "\\$SRVR\d`$\TFL\$DFTLPATH\"))
        {
            Write-Output "SSO Customer Change Notification Worker Service - Oyster was not found - skipping"
        }
        else
        {
            Write-Output "Modifying SSO Customer Change Notification Worker Service - Oyster config"

            PrepareConfigFilesForLinking -ServerIP $SSOCISIP -ConfigFile $CFGFILE -DTFLPath $DFTLPATH -Optional $true
		    
            if ($apply)
            {
                [xml] $configXML = Get-Content "\\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE.original";
               
                SetValue -AppSettingKey "SystemToNotify"	-As "Oyster"			-In $configXML
		
                # New addition (R64)
                SetValue -AppSettingKey "OysterBaseUrl"	-As "http://$OysterWebReference" -In $configXML
            
                if(![string]::IsNullOrEmpty($OysterServicePassword))
                {
                    SetValue -AppSettingKey "OysterAuthPassword"  -As $OysterServicePassword -In $configXML
                }

	            $configXML.Save("\\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE");		
                Write-Output "  \\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE written"
		        Write-Output ""
            }
        }
		
		#### 
        #### SSO Customer Change Notification Worker Service - Travel Alerts ####   No Instance Deployed in FTP INT 
        #### 

        ######## 
        #### Notifications Image Url
        ######## 
        $SRVR = $FTPSASIP
        $CFGFILE = "SendEmailService.exe.config"
        $DFTLPATH = "Notifications\SendMailService"
        
        PrepareConfigFilesForLinking -ServerIP $SRVR -ConfigFile $CFGFILE -DTFLPath $DFTLPATH
        
        Apply-StandardReplacements -ToConfig $configTxt  
        
        Set-Content  "\\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE" $configTxt
        Write-Output  "  \\$SRVR\d`$\TFL\$DFTLPATH\$CFGFILE written" 
	    Write-Output ""


        ######## 
        #### SSO Database (Product table) Update ####
        ######## 
        Write-Output "Modifying SSO Database Product table"

	    $Datasource = "$SSODBIP\Inst3"
        Write-Output "Updating SingleSignOn Database on $Datasource ..."
	    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	    $SqlConnection.ConnectionString = "Server=$Datasource;Initial Catalog=SingleSignOn;User Id=SingleSignOn;Password=ss0w3Bus3r;"
	    $SqlConnection.Open()
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	    $SqlCmd.Connection = $SqlConnection

        $cmdText = ""
        
	    #validateUrl, signoutUrl, homeUrl, defaultUrl, productToken, protectedUrl = null

        # 4 Customer Self Care	= A3AC81D4-80E8-4427-B348-A3D028DFDBE7
        $cmdText += "EXEC [dbo].[ProductUpdate] 
            @validateUrl = 'http://$FTPWebReference/HomePage/Validate', 
            @signoutUrl = 'http://$FTPWebReference/HomePage/LogOff', 
            @homeUrl = 'http://$FTPWebReference', 
            @defaultUrl = NULL,
            @productToken = 'A3AC81D4-80E8-4427-B348-A3D028DFDBE7', 
            @protectedUrl = 'http://$FTPWebReference/Dashboard'; 
            update products set RegistrationUrl = 'http://$FTPWebReference/Registration/NewRegistration' where ProductToken = 'A3AC81D4-80E8-4427-B348-A3D028DFDBE7'; "

        # 7 Customer Self Care Support	6687E912-D120-461E-9DA9-3C0288629F4F
  		$cmdText += "EXEC [dbo].[ProductUpdate] 
            @validateUrl = 'http://$FTPWebReference`:8080/Account/Validate', 
            @signoutUrl = 'http://$FTPWebReference`:8080/Account/LogOff', 
            @homeUrl = 'http://$FTPWebReference`:8080', 
            @defaultUrl = NULL,
            @productToken = '6687E912-D120-461E-9DA9-3C0288629F4F', 
            @protectedUrl = 'http://$FTPWebReference`:8080/Customer/Find'; "
            #update products set RegistrationUrl = 'http://$FTPWebReference/Registration/NewRegistration' where ProductToken = 'A3AC81D4-80E8-4427-B348-A3D028DFDBE7'; "
           
        # 1 SSO 88B73293-96A1-4131-97F5-20026B7FB2D9
        $cmdText += "IF (select count(*) from dbo.Products where ProductToken = '88B73293-96A1-4131-97F5-20026B7FB2D9') = 1
                    BEGIN
                    EXEC [dbo].[ProductUpdate] 
                        @validateUrl = null, 
                        @signoutUrl = null, 
                        @homeUrl = 'http://$SSOWebReference', 
                        @defaultUrl = null,
                        @productToken = '88B73293-96A1-4131-97F5-20026B7FB2D9', 
                        @protectedUrl = 'http://$FTPWebReference/Dashboard'
                    END; "
           
        # 9 SDM Portal 2F31D3EF-7EA9-4378-88D0-9A92EF8E9634
        # update Products set ProtectedUrl='http://' + @CASC_IP + '/Dashboard' , LoginUrl='http://' + @SSO_IP where ProductName='SSO' 
        $cmdText += "IF (select count(*) from dbo.Products where ProductToken = '2f31d3ef-7ea9-4378-88d0-9a92ef8e9634') = 1
                    BEGIN
                    EXEC [dbo].[ProductUpdate] @validateUrl = 'http://$FTPWebReference`:8081/Account/Validate', 
                        @signoutUrl = 'http://$FTPWebReference`:8081/Account/SsoSignOut', 
                        @homeUrl = 'http://$FTPWebReference`:8081',
                        @defaultUrl = null ,
                        @productToken = '2f31d3ef-7ea9-4378-88d0-9a92ef8e9634'		    
                    END; "

        # Banner table to be updated:
        $cmdText += "UPDATE [SingleSignOn].[dbo].[Banners]
                    SET [ValidToDate]=DATEADD(y,10,getdate())
                    WHERE Id=1; "

        if(!$useDummyOyster)
        {
            $cmdText += " exec [dbo].[ProductUpdate] 
                            @validateUrl = NULL, 
                            @signoutUrl = 'http://$OysterWebReference/oyster/oysterlogout.do', 
                            @homeUrl = 'login',
                            @defaultUrl = 'http://$OysterWebReference/oyster/entry.do', 
                            @productToken = '8EAD5CF4-4624-4389-B90C-B1FD1937BF1F',
							@protectedUrl = 'http://$OysterWebReference/oyster/showcards.do?_o=KTaO6YfdBpIdcN8DLNDKgw%3D%3D' "
        }
        else
        {
            $cmdText += " exec [dbo].[ProductUpdate] NULL, '$SSOErrorPage', '$SSOErrorPage',null, '8EAD5CF4-4624-4389-B90C-B1FD1937BF1F' "
        }
		
	    $SqlCmd.CommandText = $cmdText
	    $result = $SqlCmd.ExecuteNonQuery()
	    Write-Output "$result"
        Write-Output "... SSO Database Updated."         
		Write-Output ""
   


    $end = Get-Date
    Write-Output "### Post-Deployment Configuration (link script) Complete at $end###"
    Write-Output "###"

  }
  catch [System.Exception]
  {
	$error = $_.Exception.ToString()
	Write-Error "$error"

    Log-DeploymentScriptEvent -LastError "EXCEPTION in LinkSSOFTPRigs.VC.ps1" -LastException $error
	
	exit 1
  }
}


###############################################################################
#
function Apply-StandardReplacements
(
    [string]$ToConfig = $(throw 'Apply-StandardReplacements requires parameter -ToConfig')
)
{
    $config = $ToConfig

    Write-Output "  Replacing 'TS-CAS1' with CACCIPTag ($CACCIPTag)"
    $config = $config.Replace("TS-CAS1",$CACCIPTag)
    
    Write-Output "  Replacing $count instances of CACCIPTag ($CACCIPTag) with FTPWebReference ($FTPWebReference)"
    $config = $config.Replace($CACCIPTag, $FTPWebReference)
    
    Write-Output "  Replacing SSOIPTag ($SSOIPTag) with SSOWebReference ($SSOWebReference)"
    $config = $config.Replace($SSOIPTag, $SSOWebReference)
    
    write-Output "  Replacing SSOServiceIPTag ($SSOServiceIPTag) with SSOWebServiceReference ($SSOWebServiceReference)"
    $config = $config.Replace($SSOServiceIPTag, $SSOWebServiceReference)
    
    Write-Output "  Replacing OysterWebTag ($OysterWebTag) with OysterWebReference ($OysterWebReference)"
    $config = $config.Replace($OysterWebTag, $OysterWebReference)
    
    write-Output "  Replacing OysterSvcTag ($OysterSvcTag) with OysterServiceReference ($OysterServiceReference)"
    $config = $config.Replace($OysterSvcTag, $OysterServiceReference)
        		
    Write-Output "  Replacing: $AzureUploader_StorageConnStrTag : with: $AzureUploader_StorageConnStr" 
    $configTxt = $configTxt.Replace($AzureUploader_StorageConnStrTag,$AzureUploader_StorageConnStr)

    Write-Output "  Replacing: $AzureUploader_ContainerNameTag : with: $AzureUploader_ContainerName"
    $configTxt = $configTxt.Replace($AzureUploader_ContainerNameTag,$AzureUploader_ContainerName)
        		
    Write-Output "  Replacing: $AzureUploader_KeyVaultSecretUriTag : with: $AzureUploader_KeyVaultSecretUri"
    $configTxt = $configTxt.Replace($AzureUploader_KeyVaultSecretUriTag,$AzureUploader_KeyVaultSecretUri)
        		
    Write-Output "  Replacing: $AzureUploader_AzureKeyVaultClientIdTag : with: $AzureUploader_AzureKeyVaultClientId"
    $configTxt = $configTxt.Replace($AzureUploader_AzureKeyVaultClientIdTag,$AzureUploader_AzureKeyVaultClientId)
        		
    Write-Output "  Replacing: $AzureUploader_CertificateThumbprintTag : with: $AzureUploader_CertificateThumbprint"
    $configTxt = $configTxt.Replace($AzureUploader_CertificateThumbprintTag,$AzureUploader_CertificateThumbprint)
        		
    Set-Variable -Name configTxt -Scope 1 -Value $config
}


###############################################################################
#
function SetValue
(
    [string]$SetXPath = "",
    [string]$AppSettingKey = "",
    [string]$ConfigSection = "appSettings",
    [string]$As = $(throw '$As ...Value is required for SetValue function'), 
    [XML]$In = $(throw '$In ...xml is required for SetValue function')
)
{

    if ($AppSettingKey -ne "")
    {
        Write-Output "  Setting $AppSettingKey to '$As'"
        $Set = "configuration/$ConfigSection/add[@key='$AppSettingKey']/@value";
    }
    elseif ($SetXPath -ne "")
    {
        Write-Output "  Setting $SetXPath to '$As'"
        $Set = $SetXPath;
    }
    else
    {
        throw "SetXPath or AppSettingKey required for SetValue function.";
    }

	$In.SelectNodes($Set) | % {$_.Value = $As };
}

###############################################################################
#
function Cache-Creds
(
    [string]$Password,
    [string]$ip = "",
    [string]$Machine = "",
    [string]$Name = ""
)
{
    if (!(Test-Path \\$ip\D`$))
    {
		Write-Output "  caching credentials to $machine (for $Name): net use \\$ip /user:faelab\tfsbuild <pwd>"
		net use \\$ip /user:faelab\tfsbuild $Password
	}
    return $ip
}



###############################################################################
#
function PrepareConfigFilesForLinking([string]$ServerIP, [string]$ConfigFile, [string]$DTFLPath, [bool]$Optional = $false)
{
    [bool] $apply = $true
    if ($Optional)
    {
        if (!(Test-Path "\\$ServerIP\d`$\TFL\$DTFLPath\$ConfigFile.original"))
        {
            # allow ignore
            $apply = $false
        }
    }
    if ($apply)
    {
        if (Test-Path "\\$ServerIP\d`$\TFL\$DTFLPath\")
        {
            # configTxt is -Option AllScopes - sets in the parent script.
            Write-Output "Modifying $DTFLPath Service config"
            if (!(Test-Path "\\$ServerIP\d`$\TFL\$DTFLPath\$ConfigFile.original"))
            {
                $configTxt = Get-Content  "\\$ServerIP\d`$\TFL\$DTFLPath\$ConfigFile"
                Set-Content  "\\$ServerIP\d`$\TFL\$DTFLPath\$ConfigFile.original" $configTxt            
            }

            $configTxt = Get-Content  "\\$ServerIP\d`$\TFL\$DTFLPath\$ConfigFile.original"

            Set-Content  "\\$ServerIP\d`$\TFL\$DTFLPath\$ConfigFile.bak" $configTxt
        }
        else
        {
            # Error, install path not found
            $exitCode = 5
		    Write-Error "TERMINATING: Install path not found for non-optional config '\\$ServerIP\d`$\TFL\$DTFLPath\', exiting with code $exitCode"
		    Exit $exitCode;
        }
    }
}


main


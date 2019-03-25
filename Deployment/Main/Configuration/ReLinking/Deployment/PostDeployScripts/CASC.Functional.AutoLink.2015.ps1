param
(
    [string] $RigName = $(throw "RigName parameter is required"),	
    [string] $CACCTag = "TS-CAS1",	
    [string] $LocalHostTag ="localhost",
	[string] $ContactlessLocalTag ="contactless.local",
	[string] $UserName = "FAELAB\TFSBuild", 
    [string] $Password = "LMTF`$Bu1ld",
    [string] $debugDeploymentToolPath = ""   
)
function main
{
  Try
  {
	Write-Output ""
	Write-Output "### Starting Config update of CASC functional Rig for '$RigName' ###"
	Write-Output ""

	Write-Output "Loading Deployment.Utils"
    if (![string]::IsNullOrEmpty($debugDeploymentToolPath))
    {
    	$DeploymentToolPath = $debugDeploymentToolPath
    }
    else
    {
    	$DeploymentToolPath = Get-DeploymentTool
    }
    if (-not (Test-Path("$DeploymentToolPath\Deployment.Utils.dll")))
    {
        throw "Failed to locate Deployment Utils assembly at $DeploymentToolPath";
    }
    else
    {
	    [System.Reflection.Assembly]::LoadFrom((Join-Path $DeploymentToolPath "Deployment.Utils.dll"));
    }
	Write-Output ""

	Write-Output "Initialising vCloud Module for use"
	$vCloudUrl = 'https://vcloud.onelondon.tfl.local'
	$vCloudOrg = 'ce_organisation_td'
	$vCloudUser = 'zSVCCEVcloudBuild'
	$vCloudPassword = 'P0wer5hell'

	Write-Output "Loading VCloudService and Creating connection to $vCloudUrl. Org: $vCloudOrg"
	$vCloudService = New-Object -TypeName Deployment.Utils.VirtualPlatform.VCloud.VCloudService
	$vCloudService.Initialise_vCloudSession($vCloudUrl, $vCloudOrg, $vCloudUser, $vCloudPassword) | Out-Host
	Write-output "vCloud Module loaded"
	Write-Output ""

	# Connect to rig	
    $rig = $vCloudService.GetVapp($RigName);
    [bool]$MachinesAvailable = $true;
	if($rig -ne $null)
	{
		[string] $TsCasIp = $vCloudService.Get_vCloudMachineIPAddress("TS-CAS1", $RigName);
		Check-NetUse -PathToTest "\\$TsCasIp\d`$" -User $UserName -Password $Password -Retries 10 
		
		if($LASTEXITCODE -ne 0)
		{
			$MachinesAvailable = $false
		}   			
	}
	else
	{
		throw "CASC functional rig $RigName does not exist"
	}
 
	if (-not $MachinesAvailable)
	{
		throw "Unable to verify connection to target machines."
	}
    
	Write-Output "CASC Rig = $RigName"
	Write-Output "CASC CAS IP  = $TsCasIp"
    
	[string] $webconfig ="";
 
	#### 
	#### CASC Web Config
	####
	write-output "Modifying CASC Web config"
	
	$webconfig = Get-Content  "\\$TsCasIp\d`$\TFL\CACC\CSCPortal\web.config"
	Set-Content  "\\$TsCasIp\d`$\TFL\CACC\CSCPortal\web.config.bak" $webconfig
	
	[xml] $webConfigXML = Get-Content "\\$TsCasIp\d`$\TFL\CACC\CSCPortal\web.config";
	
	write-host "  Setting values"
	$webConfigXML.SelectNodes("configuration/PaymentGateway/add[@key='PaymentGatewayBaseUrl']/@value") | % {$_.Value  = $_.Value.Replace($CACCTag,$TsCasIp).Replace($LocalHostTag,$TsCasIp)};
	$webConfigXML.SelectNodes("configuration/PaymentGateway/add[@key='PaymentGatewayReturnBaseUrl']/@value") | % {$_.Value  = $_.Value.Replace($CACCTag,$TsCasIp).Replace($LocalHostTag,$TsCasIp) };
	$webConfigXML.SelectNodes("configuration/SsoWebsite/add[@key='CascHomepage']/@value") | % {$_.Value  = $_.Value.Replace($CACCTag,$TsCasIp).Replace($LocalHostTag,$TsCasIp) };
	$webConfigXML.SelectNodes("configuration/SsoWebsite/add[@key='SsoWebsiteBaseUrl']/@value") | % {$_.Value  = $_.Value.Replace($CACCTag,$TsCasIp).Replace($LocalHostTag,$TsCasIp) };
	$webConfigXML.SelectNodes("configuration/SsoWebsite/add[@key='SsoLoginErrorUrl']/@value") | % {$_.Value  = $_.Value.Replace($CACCTag,$TsCasIp).Replace($LocalHostTag,$TsCasIp) };
	$webConfigXML.SelectNodes("configuration/OysterWebsite/add[@key='OysterBaseUrl']/@value") | % {$_.Value  = $_.Value.Replace($CACCTag,$TsCasIp).Replace($LocalHostTag,$TsCasIp) };
	$webConfigXML.SelectNodes("configuration/Email/add[@key='EmailImageLocation']/@value") | % {$_.Value  = $_.Value.Replace($CACCTag,$TsCasIp).Replace($LocalHostTag,$TsCasIp) };			
	
	$webConfigXML.SelectNodes("configuration/CacheManager/add[@key='EnableCacheManagerCaching']/@value") | % {$_.Value  = $_.Value.Replace("false","true") };		
	$webConfigXML.SelectNodes("configuration/Statements/add[@key='RiskAssessedDayBoundaryToAllowUnregisteredUserAccess']/@value") | % {$_.Value  = $_.Value.Replace("7","500") };
	$webConfigXML.SelectNodes("configuration/Statements/add[@key='UnregisteredCustomerDefaultDayRange']/@value") | % {$_.Value  = $_.Value.Replace("7","500") };
	$webConfigXML.SelectNodes("configuration/Captcha/add[@key='Captcha']/@value") | % {$_.Value  = $_.Value.Replace("true","false") };
	$webConfigXML.SelectNodes("configuration/Health/add[@key='EnableAssessmentOnStart']/@value") | % {$_.Value  = $_.Value.Replace("false","true") };
		
	
	$webConfigXML.Save("\\$TsCasIp\d`$\TFL\CACC\CSCPortal\web.config")
	Write-Output  "\\$TsCasIp\d`$\TFL\CACC\CSCPortal\web.config written"
	write-output ""

	####
	#### CASC Admin Config ####
	####
	write-output "Modifying CASC Admin Portal config"

	$webconfig = Get-Content  "\\$TsCasIp\d`$\TFL\CACC\CSCSupport\web.config"
	Set-Content  "\\$TsCasIp\d`$\TFL\CACC\CSCSupport\web.config.bak" $webconfig
	
	[xml] $webConfigXML = Get-Content  "\\$TsCasIp\d`$\TFL\CACC\CSCSupport\web.config";
	
	$webConfigXML.SelectNodes("configuration/PaymentGateway/add[@key='PaymentGatewayBaseUrl']/@value") | % {$_.Value  = $_.Value.Replace($CACCTag,$TsCasIp).Replace($LocalHostTag,$TsCasIp)};
	$webConfigXML.SelectNodes("configuration/PaymentGateway/add[@key='PaymentGatewayReturnBaseUrl']/@value") | % {$_.Value  = $_.Value.Replace($CACCTag,$TsCasIp).Replace($LocalHostTag,$TsCasIp) };
	$webConfigXML.SelectNodes("configuration/SsoWebsite/add[@key='CascHomepage']/@value") | % {$_.Value  = $_.Value.Replace($CACCTag,$TsCasIp).Replace($LocalHostTag,$TsCasIp) };
	$webConfigXML.SelectNodes("configuration/SsoWebsite/add[@key='SsoWebsiteBaseUrl']/@value") | % {$_.Value  = $_.Value.Replace($CACCTag,$TsCasIp).Replace($LocalHostTag,$TsCasIp) };
	$webConfigXML.SelectNodes("configuration/SsoWebsite/add[@key='SsoLoginErrorUrl']/@value") | % {$_.Value  = $_.Value.Replace($CACCTag,$TsCasIp).Replace($LocalHostTag,$TsCasIp) };		
	$webConfigXML.SelectNodes("configuration/Email/add[@key='EmailImageLocation']/@value") | % {$_.Value  = $_.Value.Replace($CACCTag,$TsCasIp).Replace($LocalHostTag,$TsCasIp) };		
	
	$webConfigXML.SelectNodes("configuration/CacheManager/add[@key='EnableCacheManagerCaching']/@value") | % {$_.Value  = $_.Value.Replace("false","true") };		
	$webConfigXML.SelectNodes("configuration/SsoWebsite/add[@key='SsoLoginPostUrl']/@value") | % {$_.Value  = $_.Value.Replace("Login","Login/IndexAdmin").Replace("IndexAdmin/IndexAdmin","IndexAdmin") };
	$webConfigXML.SelectNodes("configuration/Health/add[@key='EnableAssessmentOnStart']/@value") | % {$_.Value  = $_.Value.Replace("false","true") };
	
	
	$webConfigXML.Save("\\$TsCasIp\d`$\TFL\CACC\CSCSupport\web.config")	
	write-output "\\$TsCasIp\d`$\TFL\CACC\CSCSupport\web.config written."
	write-output ""
	####
	####  CASC Mock Services ####
	####
	write-output " CASC MockService Config will be modified"
	
	$Mockwebconfig = Get-Content  "\\$TsCasIp\d`$\TFL\CACC\MockServices\Web.config"
	Set-Content  "\\$TsCasIp\d`$\TFL\CACC\MockServices\Web.config.bak" $Mockwebconfig

	[xml] $MockconfigXML = Get-Content "\\$TsCasIp\d`$\TFL\CACC\MockServices\Web.config";			

	$MockconfigXML.SelectNodes("configuration/OysterWebsite/add[@key='OysterBaseUrl']/@value") | % {$_.Value  = $_.Value.Replace($CACCTag,$TsCasIp).Replace($LocalHostTag,$TsCasIp) };				
	$MockconfigXML.SelectNodes("configuration/appSettings/add[@key='CascValidateUrl']/@value") | % {$_.Value  = $_.Value.Replace($CACCTag,$TsCasIp).Replace($LocalHostTag,$TsCasIp) };
    $MockconfigXML.SelectNodes("configuration/appSettings/add[@key='CasValidateUrl']/@value") | % {$_.Value  = $_.Value.Replace($CACCTag,$TsCasIp).Replace($LocalHostTag,$TsCasIp) };
	$MockconfigXML.SelectNodes("configuration/appSettings/add[@key='CascSignOutUrl']/@value") | % {$_.Value  = $_.Value.Replace($CACCTag,$TsCasIp).Replace($LocalHostTag,$TsCasIp) };
    $MockconfigXML.SelectNodes("configuration/appSettings/add[@key='CascHomePageUrl']/@value") | % {$_.Value  = $_.Value.Replace($CACCTag,$TsCasIp).Replace($LocalHostTag,$TsCasIp) };
	$MockconfigXML.SelectNodes("configuration/appSettings/add[@key='RegistrationSuccessReturnURL']/@value") | % {$_.Value  = $_.Value.Replace($CACCTag,$TsCasIp).Replace($LocalHostTag,$TsCasIp) };
	
	$MockconfigXML.Save("\\$TsCasIp\d`$\TFL\CACC\MockServices\Web.config")

	write-output "\\$TsCasIp\d`$\TFL\CACC\MockServices\Web.config written."
	write-output ""
  }
  catch [System.Exception]
  {
	$error = $_.Exception.ToString()
	Write-Error "$error"

    Log-DeploymentScriptEvent -LastError "EXCEPTION in FixUp_NotificationFunctionalRig.ps1" -LastException $error
	
	exit 1
  }
}

function Check-NetUse
{
	Param
	(
		[string]$PathToTest,
		[string]$User,
		[string]$Password,
		[int]$Retries
	)

	[int]$attempt = 0
	do
	{
		$attempt++
		if($attempt -gt 1) {sleep -Seconds 30}

		$netuseCommand = "net"
		$result = & $netuseCommand use $PathToTest /user:$User $Password 2>&1
        $err =  $result | ?{$_.gettype().Name -eq "ErrorRecord"}
        if($err)
        {
            foreach($msg in $err)
            {
                if(!([System.String]::IsNullOrEmpty($msg)))
                {
                    Write-Warning $msg
                }
            }
        }
	}
	while(($LASTEXITCODE -ne 0) -and ($attempt -lt $Retries))
}

function Get-BuildDefintionName
{
	Param
	(
		$BuildId
	)

	$tfsProjectUri = "$env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI/$env:SYSTEM_TEAMPROJECT"
	$restApiUrl = "$tfsProjectUri/_apis/build/builds/$BuildId`?api-version=2.0"

	$response = Invoke-RestMethod $restApiUrl -UseDefaultCredentials

	return $response.definition.name
}

function Get-DeploymentTool
{
	$BuildDefinitionName = Get-BuildDefintionName -BuildId $env:BUILD_BUILDID
	
    if(-not (Test-Path "$env:AGENT_RELEASEDIRECTORY\$BuildDefinitionName\Deployment\Tools\DeploymentTool"))
    {
		throw [System.ApplicationException] "Unable to locate Build Artefact Deployment. Please check Build output"
    } 
	
	return "$env:AGENT_RELEASEDIRECTORY\$BuildDefinitionName\Deployment\Tools\DeploymentTool"
}

main


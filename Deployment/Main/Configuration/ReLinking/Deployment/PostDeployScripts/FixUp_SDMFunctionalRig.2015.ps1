param
(
    [string] $SDMRig = $(throw '$SDMRig'),
	[string] $UserName = "FAELAB\TFSBuild",
    [string] $Password = "LMTF`$Bu1ld",
    [string] $debugDeploymentToolPath = ""
)

function main
{
	Try
	{
	    Write-Output ""
	    Write-Output "### Starting Config update of SDM functional Rig for '$SDMRig' ###"
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

    
		# Connect to SDM rig
		$rig = $vCloudService.GetVapp($SDMRig);
    	[bool]$MachinesAvailable = $true;
		if ($rig -ne $null)
		{
			$SDMCASIP = $vCloudService.Get_vCloudMachineIPAddress("TS-CAS1", $SDMRig)
		    Check-NetUse -PathToTest "\\$SDMCASIP" -User $UserName -Password $Password -Retries 10
		    if($LASTEXITCODE -ne 0)
		    {
			    $MachinesAvailable = $false
		    }
		
			$SDMCISIP = $vCloudService.Get_vCloudMachineIPAddress("TS-CIS1", $SDMRig)
		    Check-NetUse -PathToTest "\\$SDMCISIP" -User $UserName -Password $Password -Retries 10
		    if($LASTEXITCODE -ne 0)
		    {
			    $MachinesAvailable = $false
		    }
		}
		else
		{
			throw "SDM rig $SDMRig does not exist"
		}
    
	    if (-not $MachinesAvailable)
	    {
		    throw "Unable to verify connection to target machines."
	    }
    
		Write-Output "SDM Rig = $SDMRig"
		Write-Output "SDM CIS IP  = $SDMCISIP"
		Write-Output "SDM CAS IP  = $SDMCASIP"
    
		[string] $webconfig ="";    

		#### SDM Web Config
		$webConfigPath = "\\$SDMCASIP\d`$\TFL\SDM\SDMPortal\web.config"
		$webConfigOriginalPath = "\\$SDMCASIP\d`$\TFL\SDM\SDMPortal\web.config.original"
		$webConfigBackupPath = "\\$SDMCASIP\d`$\TFL\SDM\SDMPortal\web.config.bak"
		write-output " SDM Portal Web Config will be modified"
		if (!(Test-Path $webConfigOriginalPath))
		{
			write-output "Creating original config $webConfigOriginalPath"
			$webconfig = Get-Content  $webConfigPath
			Set-Content  $webConfigOriginalPath $webconfig            
		}
		write-output "Backing up current config $webConfigBackupPath"
		$webconfig = Get-Content  $webConfigPath
		Set-Content $webConfigBackupPath $webconfig
	
		write-output "Updating 	SsoWebsite/SsoWebsiteBaseUrl to use $SDMCISIP"
		[xml] $webConfigXML = Get-Content $webConfigPath;      
		$webConfigXML.SelectNodes("configuration/SsoWebsite/add[@key='SsoWebsiteBaseUrl']/@value") | % {$_.Value = "http://$SDMCISIP`:8728" };

		$webConfigXML.Save($webConfigPath)
		Write-Output  "$webConfigPath written"        

		 #### SDM Mock SSO Web Config
		$mockSsoWebConfigPath = "\\$SDMCISIP\d`$\TFL\SDM\MockSSO\web.config"
		$mockSsoWebConfigOriginalPath = "\\$SDMCISIP\d`$\TFL\SDM\MockSSO\web.config.original"
		$mockSsoWebConfigBackupPath = "\\$SDMCISIP\d`$\TFL\SDM\MockSSO\web.config.bak"
		write-output " SDM MockSSO Web Config will be modified"
		if (!(Test-Path $mockSsoWebConfigOriginalPath))
		{
			write-output "Creating original config $mockSsoWebConfigOriginalPath"
			$mockSsoWebconfig = Get-Content  $mockSsoWebConfigPath
			Set-Content  $mockSsoWebConfigOriginalPath $mockSsoWebconfig            
		}
		write-output "Backing up current config $mockSsoWebConfigBackupPath"
		$mockSsoWebconfig = Get-Content  $mockSsoWebConfigPath
		Set-Content $mockSsoWebConfigBackupPath $mockSsoWebconfig
	
		write-output "Updating 	appSettings/SDMBaseUrl to use $SDMCASIP"
		[xml] $mockSsoWebConfigXML = Get-Content $mockSsoWebConfigPath;      
		$mockSsoWebConfigXML.SelectNodes("configuration/appSettings/add[@key='SDMBaseUrl']/@value") | % {$_.Value = "http://$SDMCASIP`:8081" };

		$mockSsoWebConfigXML.Save($mockSsoWebConfigPath)
		Write-Output  "$mockSsoWebConfigPath written"   
	}
	Catch [System.Exception]
	{
		$error = $_.Exception.ToString()
		Write-Error "$error"

		Log-DeploymentScriptEvent -LastError "EXCEPTION in FixUp_SDMFunctionalRig.VC.ps1" -LastException $error
	
		exit 1
	}
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

main


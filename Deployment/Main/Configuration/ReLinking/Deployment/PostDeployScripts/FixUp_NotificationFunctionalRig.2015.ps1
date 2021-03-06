param
(
    [string] $NotifRig = $(throw '$NotifRig'),
	[string] $UserName = "faelab\tfsbuild",
    [string] $Password = "LMTF`$Bu1ld",
    [string] $debugDeploymentToolPath = ""
)
function main
{
  try
  {
	Write-Output ""
	Write-Output "### Starting Config update of Notifications functional Rig for '$NotifRig' ###"
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

    # Connect to Notif rig
    $rig = $vCloudService.GetVapp($NotifRig);
	[bool]$MachinesAvailable = $true
    if ($rig -ne $null)
    {
        $NOTIFAPPIP = $vCloudService.Get_vCloudMachineIPAddress("TS-APP1", $NotifRig);
		Check-NetUse -PathToTest "\\$NOTIFAPPIP" -User $UserName -Password $Password -Retries 10
		if($LASTEXITCODE -ne 0)
		{
			$MachinesAvailable = $false
		}

		$NOTIFCISIP = $vCloudService.Get_vCloudMachineIPAddress("TS-CIS1", $NotifRig);
		Check-NetUse -PathToTest "\\$NOTIFCISIP" -User $UserName -Password $Password -Retries 10
		if($LASTEXITCODE -ne 0)
		{
			$MachinesAvailable = $false
		}
    }
    else
    {
        throw "Notif rig $NotifRig does not exist"
    }

	Write-Output "Notif Rig = $NotifRig"
    Write-Output "Notif APP IP  = $NOTIFAPPIP"
	Write-Output "Notif CIS IP  = $NOTIFCISIP"

	If(-not $MachinesAvailable)
	{
		throw "Unable to verify connection to target machines."
	}
    
    #### Notif send mail app Config Notifications\SendMailService\SendEmailService.exe.config
	$appConfigPath = "\\$NOTIFAPPIP\d`$\TFL\Notifications\SendMailService\SendEmailService.exe.config"
	$appConfigOriginalPath = "\\$NOTIFAPPIP\d`$\TFL\Notifications\SendMailService\SendEmailService.exe.config.original"
	$appConfigBackupPath = "\\$NOTIFAPPIP\d`$\TFL\Notifications\SendMailService\SendEmailService.exe.config.bak"

    write-output " Notif sendmail app Config will be modified"
    if (!(Test-Path $appConfigOriginalPath))
    {
        write-output "Creating original config $appConfigOriginalPath"
        $appconfig = Get-Content  $appConfigPath
        Set-Content  $appConfigOriginalPath $appconfig            
    }
    write-output "Backing up current config as $appConfigBackupPath"
    $appconfig = Get-Content  $appConfigPath
    Set-Content  $appConfigBackupPath $appconfig
	
    write-output "Updating 	appSettings/imageUrlLocation to use $NOTIFCISIP"
	[xml] $appConfigXML = Get-Content $appConfigPath;      
	$appConfigXML.SelectNodes("configuration/appSettings/add[@key='imageUrlLocation']/@value") | % {$_.Value = "http://$NOTIFCISIP/content/images/email/" };

	$appConfigXML.Save($appConfigPath)
    Write-Output  "$appConfigPath written"        
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


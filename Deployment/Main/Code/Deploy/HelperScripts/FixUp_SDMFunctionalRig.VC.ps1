param
(
    [string] $SDMRig = $(throw '$SDMRig'),
    [string] $Password = "LMTF`$Bu1ld",
	[string] $DriveLetter = "D"
)
function main
{
Try
{
    [string] $webconfig ="";    
    $scriptpath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)
        
	Write-Output "Loading TFL.DBLogging.ps1..."
	Write-Output ""
	Import-Module $scriptpath\..\Scripts\TFL.DBLogging.ps1 -Force
        
    Initialise_DeploymentScriptEventLog -RigName $SDMRig -InitialisationSource ($myinvocation.scriptname) -ScriptHost $env:computername
    Initialise_vCloudEventLog -vAppName $SDMRig -InitialisationSource ($myinvocation.scriptname) -ScriptHost $env:computername

	Write-Output "Importing VCloud module..."
	Write-Output ""
    Import-Module $scriptpath\..\Scripts\VCloud.ps1 -Force
    
    # Connect to SDM rig
    $rig = Get-CIVApp -Name $SDMRig -ErrorAction SilentlyContinue;
    if ($rig -ne $null)
    {
        $SDMCASIP = Get-vCloudMachineIPAddress -vApp $rig "TS-CAS1";
        write-output "net use \\$SDMCASIP /user:faelab\tfsbuild $Password"
        net use \\$SDMCASIP /user:faelab\tfsbuild $Password
		
        $SDMCISIP = Get-vCloudMachineIPAddress -vApp $rig "TS-CIS1";
        write-output "net use \\$SDMCISIP /user:faelab\tfsbuild $Password"
        net use \\$SDMCISIP /user:faelab\tfsbuild $Password
    }
    else
    {
        throw "SDM rig $SDMRig does not exist"
    }
    
	Write-Output "SDM Rig = $SDMRig"
    Write-Output "SDM CIS IP  = $SDMCISIP"
    Write-Output "SDM CAS IP  = $SDMCASIP"
    
    #### SDM Web Config
	$webConfigPath = "\\$SDMCASIP\$DriveLetter`$\TFL\SDM\SDMPortal\web.config"
	$webConfigOriginalPath = "\\$SDMCASIP\$DriveLetter`$\TFL\SDM\SDMPortal\web.config.original"
	$webConfigBackupPath = "\\$SDMCASIP\$DriveLetter`$\TFL\SDM\SDMPortal\web.config.bak"
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
	$mockSsoWebConfigPath = "\\$SDMCISIP\$DriveLetter`$\TFL\SDM\MockSSO\web.config"
	$mockSsoWebConfigOriginalPath = "\\$SDMCISIP\$DriveLetter`$\TFL\SDM\MockSSO\web.config.original"
	$mockSsoWebConfigBackupPath = "\\$SDMCISIP\$DriveLetter`$\TFL\SDM\MockSSO\web.config.bak"
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


main


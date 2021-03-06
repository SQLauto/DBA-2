param
(
    [string] $NotifRig = $(throw '$NotifRig'),
	[string] $UserName = "faelab\tfsbuild",
    [string] $Password = "LMTF`$Bu1ld",
	[string] $DriveLetter = "D"
)
function main
{
Try
{
    $scriptpath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)
        
	Write-Output "Loading TFL.DBLogging.ps1..."
	Write-Output ""
	Import-Module $scriptpath\..\Scripts\TFL.DBLogging.ps1 -Force
        
    Initialise_DeploymentScriptEventLog -RigName $NotifRig -InitialisationSource ($myinvocation.scriptname) -ScriptHost $env:computername
    Initialise_vCloudEventLog -vAppName $NotifRig -InitialisationSource ($myinvocation.scriptname) -ScriptHost $env:computername

    Write-Output "Importing vCloud module" 
    Write-Output ""
    Import-Module $scriptpath\..\Scripts\vCloud.ps1 -Force	
  
    # Connect to Notif rig
    $rig = Get-CIVApp -Name $NotifRig -ErrorAction SilentlyContinue;
    if ($rig -ne $null)
    {
        $NOTIFAPPIP = Get-vCloudMachineIPAddress -vApp $rig -MachineName "TS-APP1"
        net use \\$NOTIFAPPIP /user:$UserName $Password

		$NOTIFCISIP = Get-vCloudMachineIPAddress -vApp $rig -MachineName "TS-CIS1"
        #write-output "net use \\$NOTIFAPPIP /user:$UserName $Password"
        net use \\$NOTIFCISIP /user:$UserName $Password
    }
    else
    {
        throw "Notif rig $NotifRig does not exist"
    }
    
	Write-Output "Notif Rig = $NotifRig"
    Write-Output "Notif APP IP  = $NOTIFAPPIP"
	Write-Output "Notif CIS IP  = $NOTIFCISIP"
    
    #### Notif send mail app Config Notifications\SendMailService\SendEmailService.exe.config
	$appConfigPath = "\\$NOTIFAPPIP\$DriveLetter`$\TFL\Notifications\SendMailService\SendEmailService.exe.config"
	$appConfigOriginalPath = "\\$NOTIFAPPIP\$DriveLetter`$\TFL\Notifications\SendMailService\SendEmailService.exe.config.original"
	$appConfigBackupPath = "\\$NOTIFAPPIP\$DriveLetter`$\TFL\Notifications\SendMailService\SendEmailService.exe.config.bak"

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
Catch [System.Exception]
{
	$error = $_.Exception.ToString()
	Write-Error "$error"
    
    Log-DeploymentScriptEvent -LastError "EXCEPTION in FixUp_NotificationFunctionalRig.ps1" -LastException $error
	
    exit 1
}
}


main


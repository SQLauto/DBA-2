
##############
#
# YOU NEED TO LOAD TFL.DBLogging.ps1 FIRST !
#
#####################

function Initialise-vCloudSession
(
    [string]$vcServer = 'vcloud.onelondon.tfl.local',
    [string]$org = 'ce_organisation_td',
    [string]$vcSvcAccount = 'zSVCCEVcloudBuild',
    [string]$vcSvcPassword = 'P0wer5hell'
)
{
    try
    {
        if ((Get-Module TFL.DBLogging) -ne $null)
        {
            Log-vCloudEvent -EventID $ENTER_INIT_SESSION
        }

        Write-Output "Initialising vCloud API Session"
        Write-Host "Initialising vCloud API Session"
        
        $errCode = 2000;

        $errAction = "Loading VMware.VimAutomation.Core Snapin"

        #Load snappin
        if ( (Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null )
        {
            Write-Output "  Loading VMware.VimAutomation.Core Snapin"
            Write-Host "  Loading VMware.VimAutomation.Core Snapin"

            Add-PSSnapin VMware.VimAutomation.Core;
        }
        else
        {
            Write-Output "  VMware.VimAutomation.Core already loaded"
            Write-Host "  VMware.VimAutomation.Core already loaded"
        }
        

        #Initialise
        $errAction = "Initialize-PowerCLIEnvironment.ps1"
        Write-Output "  Initialize-PowerCLIEnvironment .... "
        Write-Host "  Initialize-PowerCLIEnvironment .... "
        . "C:\Program Files (x86)\VMware\Infrastructure\vSphere PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"
        

        #Connect
        Write-Output "  Setting InvalidCertificateAction to Ignore for SSL root cert problem"
        Write-Host  "  Setting InvalidCertificateAction to Ignore for SSL root cert problem"
        Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$False;
        
        $errAction = "Connect-CIServer to $vcServer, Org: $org"
        Write-Output "  Connecting to $vcServer..., Org: $org"
        Write-Host  "  Connecting to $vcServer..., Org: $org"
        
        Write-Output "Connecting to Server: $vcServer"
        Write-Host "Connecting to Server: $vcServer, Org: $org"
        Connect-CIServer -Server $vcServer -Org $org -User $vcSvcAccount -Password $vcSvcPassword -WarningAction SilentlyContinue;
        
        $errCode = 2001;
        $errAction = "Testing Connection to vCloud API"
        try
        {
            $testGetOrg = Get-Org

            if ($testGetOrg -eq $null)
            {
                $msg = "Error $errAction with Get-Org (result null).  Exiting with code $errCode";

		        Write-output $msg
		        Write-host $msg
                Exit $errCode
                
                if ((Get-Module TFL.DBLogging) -ne $null)
                {
                    Log-vCloudEvent -ExitCode $errCode -LastError $msg
                }
            }
        }    
        catch
        {
		    Write-output "Error Testing Connection with Get-Org.  Exception: $_" + ". Exiting with code $errCode"
		    Write-host "Error Testing Connection with Get-Org.  Exiting with code $errCode"
            Exit $errCode
            
            if ((Get-Module TFL.DBLogging) -ne $null)
            {
                $msg = "On $errAction.  EXCEPTION DETAILS: $_";
                Log-vCloudEvent -ExitCode $errCode -LastError $msg
            }
        }
    }
    catch
    {
		Write-output "Error in Initialise-vCloudSession, $errAction"
		Write-host "Error in Initialise-vCloudSession, $errAction"
		Write-output $_
		Write-host $_

        if ((Get-Module TFL.DBLogging) -ne $null)
        {
            $msg = "On $errAction.  EXCEPTION DETAILS: $_";
            Log-vCloudEvent -ExitCode $errCode -LastError $msg
        }

		Write-output "Exiting with code $errCode"
		exit $errCode
    }
    finally
    {
        if ((Get-Module TFL.DBLogging) -ne $null)
        {
            Log-vCloudEvent -EventID $EXIT_INIT_SESSION
        }
    }
}

function New-vAppFromTemplate
(
    [string] $vAppTemplateName = $(throw '$vAppTemplateName'),
    [string] $vAppName = $(throw '$vAppName')
)
{
    try
    {
		Write-output "Start New-vAppFromTemplate"
        Log-vCloudEvent -EventID $ENTER_NEW_VAPP_FROM_TEMPLATE -TemplateName $vAppTemplateName;

        if (DoesVAppExist -vAppName $vAppName)
        {
		    Write-output "vApp $vAppName already exists, exiting with code 1"
		    Write-host "vApp $vAppName already exists, exiting with code 1"
        }
        else
        {
            Write-output "VApp does not exist at start"        
        }
        
        if (-Not (DoesVAppTemplateExist -vAppName $vAppTemplateName))
        {
		    Write-output "Catalog Template $vAppTemplateName does not exist, exiting with code 2004"
		    Write-host "Catalog Template $vAppTemplateName does not exist, exiting with code 2004"
			
			Log-vCloudEvent -ExitCode 2004 -LastError "Catalog Template $vAppTemplateName does not exist"
			exit 2004
        }
		
    }
    catch
    {
        $errMsg = "Exception at Start of New-vAppFromTemplate";
		Write-output $errMsg 
		Write-host $errMsg 
		Write-output $_
		Write-host $_

        Log-vCloudEvent -ExitCode 2002 -LastError $errMsg -LastException $_
        
		Write-output "Exiting with code 2002"
		exit 2002
    }

    try
    {
        $desc = "vApp cloned from $vAppTemplateName " + (Get-Date -Format "yyyy.MM.dd HH:mm");
		Write-output "New-CIVApp -Name $vAppName -VAppTemplate $vAppTemplateName -Description $desc -Confirm:$false "       
        
        Log-vCloudEvent -EventID $BEGIN_NEW_CIVAPP
        
        $vapp = New-CIVApp -Name $vAppName -VAppTemplate $vAppTemplateName -Description $desc -Confirm:$false
        
        Log-vCloudEvent -EventID $END_NEW_CIVAPP
        
        # Apply Standard Sharing
        Share-vApp -vAppName $vAppName -ShareWith "ROLE-G-CEvCUser" -AccessLevel "FullControl"        
        Share-vApp -vAppName $vAppName -ShareWith "Role-G-CEvCPowerUser" -AccessLevel "FullControl"

        if ($vapp -eq $null)
        {
		    Write-output "vApp Creation Failed: New-CIVApp returned null, exiting with code 2005"
		    Write-host "vApp Creation Failed: New-CIVApp returned null, exiting with code 2005"
			
			Log-vCloudEvent -ExitCode 2005 -LastError "vApp Creation Failed: New-CIVApp returned null"
			exit 2005
        }
        Write-output "Finished New CIVApp"        
    }
    catch
    {
        $errMsg = "New-CIvApp exception in New-vAppFromTemplate"
		Write-output $errMsg
		Write-host $errMsg
		Write-output $_
		Write-host $_

        Log-vCloudEvent -ExitCode 2002 -LastError $errMsg -LastException $_
        
		Write-output "Exiting with code 2002"
		exit 2002
    }

    try
    {
        Log-vCloudEvent -EventID $BEGIN_START_CIVAPP  
        
        $vapp | Start-CIVApp

        Log-vCloudEvent -EventID $END_START_CIVAPP
    }
    catch
    {
        $errMsg = "Start-CIvApp exception in New-vAppFromTemplate"
		Write-output $errMsg
		Write-host $errMsg
		Write-output $_
		Write-host $_

        Log-vCloudEvent -ExitCode 2002 -LastError $errMsg -LastException $_
        
		Write-output "Exiting with code 2002"
		exit 2002
    }
    
    Log-vCloudEvent -EventID $EXIT_NEW_VAPP_FROM_TEMPLATE     
}

function Delete-vApp
(
    [string] $vAppName = $(throw '$vAppName')
)
{
    try
    {
        $vApp = Get-CIvApp -Name $vAppName -ErrorAction SilentlyContinue;

        if ($vApp -eq $null)
        {
		    Write-output "vApp $vAppName not found to delete"
		    Write-host "vApp $vAppName not found to delete"
        }

        # 1) Shutdown
        $errAction = "Stop-CIvApp";
        if ($vApp.Status -eq "PoweredOn")
        {
            Log-vCloudEvent -EventID $BEGIN_STOP_CIVAPP
		    
            $vApp | Stop-CIvApp -Confirm:$false
            
            Log-vCloudEvent -EventID $END_STOP_CIVAPP
		}
		$errAction = "Remove-CIvApp";

        Log-vCloudEvent -EventID $BEGIN_REMOVE_CIVAPP
		    
        $vApp | Remove-CIvApp -Confirm:$false
        
        Log-vCloudEvent -EventID $END_REMOVE_CIVAPP		    
    }
    catch
    {
        $errMsg  = "$errAction errAction error in Delete-vApp"
        Write-output $errMsg
		Write-host $errMsg
		Write-output $_
		Write-host $_

        Log-vCloudEvent -ExitCode 2003 -LastError $errMsg -LastException $_
        
		Write-output "Exiting with code 2003"
		exit 2003;
    }
}

function DoesVAppExist
(
	[string] $vAppName = $(throw '$vAppName')
)
{
	$vApp = Get-CIvApp -Name $vAppName -ErrorAction SilentlyContinue

	if ($vApp -eq $null)
	{
		return $false
	}
	else
	{
		return $true
	}
}

function DoesVAppTemplateExist
(
	[string] $vAppName = $(throw '$vAppName')
)
{
	$vApp = Get-CIVAppTemplate -Name $vAppName -ErrorAction SilentlyContinue

	if ($vApp -eq $null)
	{
		return $false
	}
	else
	{
		return $true
	}
}

function Get-vCloudMachines
(
    [string] $vAppName = $(throw '$vAppName')
)
{
    $vApp = Get-CIVApp -Name $vAppName -ErrorAction SilentlyContinue

    if ($vApp -ne $null)
    {
        $VMS = Get-CIVM -VApp $vApp
        return $VMS
    }
    else
    {
        Write-Output "vApp $vAppName does not exist"
		Write-host "vApp $vAppName does not exist"
        exit 2012;
    }
}

function Get-vCloudMachineIPAddress
(
    [string] $MachineName = $(throw 'A MachineName parameter is required for function Get-vCloudMachineIPAddress'),
    $vApp = $(throw 'A vApp parameter is required for function Get-vCloudMachineIPAddress')
)
{
    [int]$errorCode = 2008
    
    if ([string]::IsNullOrEmpty($MachineName))
    {
        $errMsg  = "ERROR: Empty MachineName argument in Get-vCloudMachineIPAddress"
		Write-output $errMsg
		Write-host $errMsg
		
        Log-vCloudEvent -ExitCode $errorCode -LastError $errMsg -LastException $_

		Write-output "Exiting with code $errorCode"
        exit $errorCode;
    }

    try
    {
        $errAction = "Get-CIVM"
        $vm = Get-CIVM -VApp $vapp | Where-Object { $_.Name -eq $MachineName }
        
        if ($vm -ne $null)
        {
            $errAction = "Get-CINetworkAdapter"
            $netAdapter = (Get-CINetworkAdapter -VM $vm);
            $externalIP = $netAdapter.ExternalIpAddress.ToString();
        }
        else
        {
		    Write-output "Machine $vm not found"
		    Write-host "Machine $vm not found"

            $externalIP = "";
        }
	}
	catch
	{
        $errMsg  = ("$errAction error in Get-vCloudMachineIPAddress (Machine Name: $MachineName): $_")
		Write-output $errMsg
		Write-host $errMsg
		
        Log-vCloudEvent -ExitCode $errorCode -LastError $errMsg -LastException $_

		Write-output "Exiting with code $errorCode"
        exit $errorCode;
	}
	 
	return $externalIP;
}

function Verify-vApp
(
    [string] $vAppName = $(throw '$vAppName')
)
{
	write-output "Verifying the $vAppName"
	write-host "Verifying the $vAppName"

	$timeStarted= Get-Date -format HH:mm:ss

	write-host "Started verify vApp:"$timeStarted
    write-output "Started verify vApp:"$timeStarted

    Log-vCloudEvent -EventID $ENTER_VERIFY_VAPP	

	try
	{
       for ( $i=0; $i -le 60; $i++)      # try 20 minutes
       {
            try
            {                
                $vApp = Get-CIvApp -Name $vAppName -ErrorAction SilentlyContinue # $lmService.GetConfigurationByName($vAppName);        
       
                if ($vApp -ne $null)
                {  
                    break
                }
                Start-Sleep -Seconds 20; 
            }     
            catch 
            {
                # try again....
            }
        }
        $timeFinished= Get-Date -format HH:mm:ss
        write-host "Finished waiting for Get-CIvApp: "$timeFinished
        write-output "Finished waiting wait for Get-CIvApp: "$timeFinished
       
        if ($vApp -eq $null)
        {   
            $msg = "Could not get the $vAppName from Get-CIvApp";
             
            write-output $msg
            write-host $msg
            Write-output $_
            Write-host $_
                         
            Log-vCloudEvent -EventID $END_VERIFY_VAPP -VerifySuccessful 0 -LastError $msg -LastException $_

            return $false
        }
        
		#$cloneID =  $config[0].id
		#write-output "cloneID: " $cloneID " for vAppName:" $vAppName
        #write-host "cloneID: " $cloneID " for vAppName:" $vAppName
        
        # Test vApp deployed (all machines powered on)
		for ( $i=0; $i -le 100; $i++)
		{
            try
            {
    			$machines = Get-CIVM -VApp $vApp # $lmService.ListMachines($cloneID);
            }
            catch
            {
            }
			$readyMachines = ($machines | where {$_.Status -eq "PoweredOn" }).count        
			if ($readyMachines -eq $null) { $readyMachines = 0; }
               
			if( $readyMachines -eq $machines.count)
			{  
                Log-vCloudEvent -EventID $END_VERIFY_VAPP -VerifySuccessful 1 -VerifyLoopsCompleted $i

				return $true
			}
            else
            {
			    Start-Sleep -Seconds 3; # debug should be 30
            }
		}

        $notes = "$i loops executed, $readyMachines / " + ($machines.count.ToString()) + " machines were ready in - 'Test vApp for all machines powered-on'"
        
        Log-vCloudEvent -EventID $END_VERIFY_VAPP -VerifySuccessful 0 -VerifyLoopsCompleted $i -Notes $notes

		return $false
	}
	catch 
	{
        $msg = "Verify vApp errored";
		write-output $msg
		write-host $msg
		Write-output $_
		Write-host $_

        Log-vCloudEvent -EventID $END_VERIFY_VAPP -VerifySuccessful 0 -LastError $msg -LastException $_
        
		return $false
	}
    finally
    {
        Log-vCloudEvent -EventID $EXIT_VERIFY_VAPP
    }

}


function Share-vApp # the long winded way
(
    [string]$vAppName = $(throw, "vAppName is required when calling Share-vApp"),
    [string]$ShareWith = $(throw, "A Group or Username is required when calling Share-vApp"), 
    [bool]$IsUserNotGroup = $false,
    [string]$AccessLevel = "Change" # { ReadOnly | Change | FullControl }

)
{
    Write-Output "Share-vApp()"
    Write-Output "    vAppName = '$vAppName'"
    Write-Output "    ShareWith = '$ShareWith'"
    Write-Output "    AccessLevel = '$AccessLevel'"
    Write-Output "    IsUserNotGroup = '$IsUserNotGroup'"

    # Get our required Objects
    $vApp = Get-CIVApp $vAppName
    
    if ($vApp -eq $null)
    {
        Write-Error "Cannot share vApp '$vAppName'; not found"
        exit 3001;
    }

    #$group = Get-CIGroup "ROL
    # Get current access policy from vApp
    $access = $vApp.ExtensionData.GetControlAccess()

    if (!$access.AccessSettings)
    {
        $access.AccessSettings = New-Object VMware.VimAutomation.Cloud.Views.AccessSettings
    }

    # New Access object
    $newAccess = new-object VMware.VimAutomation.Cloud.Views.AccessSetting
    $newAccess.Subject = New-Object VMware.VimAutomation.Cloud.Views.Reference

    # Set our access level
    $newAccess.AccessLevel = $accessLevel
    
    # Insert user href
    if ($isUserNotGroup)
    {
        $user = Get-CIUser $ShareWith
        
        if ($user -eq $null)
        {
            Write-Error "Cannot share vApp with User '$ShareWith'; user not found";
            exit 3002;
        }

        $userRef = $user.ExtensionData.Href
        $newAccess.Subject.Href = $userRef                   # https://vcloud/api/admin/group/0724aaa9-bfea-44d3-8bd4-ac8424aecfd9
        $newAccess.Subject.Type = "application/vnd.vmware.admin.user+xml"             # "application/vnd.vmware.admin.group+xml"
    }
    else
    {
        $grp = Get-vCloudGroup -Name $ShareWith # Search-Cloud [ -Type Group -Name $var ] IS CASE SENSITIVE ! 
        
        if ($grp -eq $null)
        {
            Write-Error "Cannot share vApp with Group '$ShareWith'; group not found";
            exit 3002;            
        }

        $grpRef = ($grp | Get-CIView).Href
        $newAccess.Subject.Href = $grpRef;
        $newAccess.Subject.Type = "application/vnd.vmware.admin.group+xml"
    }

    # Add new access to vApp access settings object
    $access.AccessSettings.AccessSetting += $newAccess

    #Send new Access config
    $vApp.ExtensionData.ControlAccess($access)
}


function Get-vCloudGroup([string]$Name = $(throw, "A Group Name must be specified for Get-vCloudGroup"))
{
    $allGroups = Search-Cloud -QueryType Group

    $requestedGroup = $allGroups | Where-Object { $_.Name -eq $Name; }

    return $requestedGroup;
}


Initialise-vCloudSession


#returns a double representing number of days
<#function Get-vAppAge
(
	[string] $vAppName
)
{
	try
	{
       $config = Get-CIvApp -Name $vAppName;
	}
	catch
	{
		Write-output "Get-vAppAge error in GetConfigurationByName"
		Write-host "Get-vAppAge error in GetConfigurationByName"
		Write-output $_
		Write-host $_
		
        #exit 2004
	}
	
	$dateCreated = $config.dateCreated
	
	$timespan = (Get-Date) - $dateCreated
	
	return $timespan.TotalDays	
}#>


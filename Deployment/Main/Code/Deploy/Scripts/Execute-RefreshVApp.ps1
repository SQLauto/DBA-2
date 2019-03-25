param
(
    [string] $vAppName = $(throw 'vAppName parameter is required'),
    [string] $vAppTemplateName = $(throw 'vAppTemplateName parameter is required'),
    [Boolean] $ForceRefresh = $false

    #[string] $vAppName = "Build.Dev.Rik.Baseline", # $(throw 'vAppName parameter is required'),
    #[string] $vAppTemplateName = "BaselineRig", # $(throw 'vAppTemplateName parameter is required'),
    
)

function main
{
    $date = Get-Date
    
    Write-Output ""
    Write-Output "### Starting Execute-RefreshVApp on $vAppName using template $vAppTemplateName (at $date)  ###"
    Write-Output ""
        
    $scriptpath = split-path $myinvocation.scriptname;
    
	Write-Output "Loading TFL.DBLogging.ps1..."
	Write-Output ""
	Import-Module $scriptpath\..\Scripts\TFL.DBLogging.ps1 -Force
        
    Initialise_vCloudEventLog -vAppName $vAppName -vAppTemplateName $vAppTemplateName -InitialisationSource ($myinvocation.scriptname) -ScriptHost ($env:COMPUTERNAME)
          

    Write-Output "Importing VCloud module..."
    Write-Output ""
    Write-Output "  Import-Module $scriptpath\..\Scripts\VCloud.ps1"
    Import-Module $scriptpath\..\Scripts\VCloud.ps1 -Force
    

    Log-vCloudEvent -EventID $ENTER_EXECUTE_REFRESH_VAPP;     
   
    $rig = Get-CIvApp -Name $vAppName -ErrorAction SilentlyContinue;
	if ($rig -ne $null)
	{
        $vAppIsDeployed = $rig.ExtensionData.Deployed
        $state = $rig.Status
        
        $vAppGuid = $rig.Id.TrimStart('urn:vcloud:vapp:')
        Log-DeploymentScriptEvent -vAppGuid $vAppGuid 

        if ($vAppIsDeployed -eq $true)
        {
            Log-vCloudEvent -StartState "Exists-Deployed-$state :   ForceRefresh: $ForceRefresh";
        }
        else
        {
            Log-vCloudEvent -StartState "Exists-Undeployed-$state :   ForceRefresh: $ForceRefresh";
            
            if (!$ForceRefresh)
            {
                Log-vCloudEvent -EventID $BEGIN_START_CIVAPP  
        
                $rig | Start-CIVApp

                $vAppIsDeployed = $true
                $doRefresh = $false

                Log-vCloudEvent -EventID $END_START_CIVAPP
            }
        }

		# If the vApp is more than 5 days old and it is a weekend then refesh the given vApp, unless $ForceRefresh is true in
		# which case we always refresh the vApp
		$doRefresh = $false;
		if($ForceRefresh)
		{
			$doRefresh = $true
			Write-Output "Force refresh set to true"
		}
		else 
		{			
			#$today = (Get-Date).DayOfWeek
			#$ageindays = Get-vAppAge $vAppName			
			#Write-Output "Today is $today"
			#Write-Output "vApp $vAppName is $ageindays days old"
			
			#if (($today -eq "Saturday" -or $today -eq "Sunday") -and $ageindays -ge 5)
			#{
			#	$doRefresh = $true
			#}
		}
		
		if ($doRefresh -or (-Not $vAppIsDeployed))
		{
            if ($vAppIsDeployed)
            {
			    Write-Output "Refreshing vApp"
			    #$Workspace = Get-vAppWorkspace $vAppName
			    #Write-Output "vApp $vAppname is from workspace $Workspace"
		    }
            else
            {
			    Write-Output "Existing '$vAppName' vApp is undeployed, deleting first";
            }

			try
			{
				Write-Output "Deleting vApp $vAppName"
    			Delete-vApp -vAppName $vAppName -ErrorAction Stop  # Start and End logged with function
			}
			catch
			{
				$msg = "ERROR: Failed to delete vApp. Reason: " + $_.Exception 
				Write-Output $msg
				exit 1
			}

			try
			{
				Write-Output "Creating vApp $vAppName using template $vAppTemplateName"
				New-vAppFromTemplate $vAppTemplateName $vAppName -ErrorAction Stop # Start and End logged with function
			}
			catch
			{
				$msg = "ERROR: Failed to create vApp from Template. Reason: " + $_.Exception
				Write-Output $msg
				exit 1
			}
        }
		else
		{
			Write-Output "Not necessary to refresh vApp at this time";
		}
	}
	else
	{
		try
		{
			Write-Output "vApp $vAppName does not exist, nothing to refresh"	
			Write-Output "Creating vApp $vAppName from $vAppTemplateName"
			New-vAppFromTemplate $vAppTemplateName $vAppName -ErrorAction Stop # Start and End logged with function
		}
		catch
		{
			$msg = "ERROR: Failed to create vApp from Template. Reason: " + $_.Exception
			Write-Output $msg
			exit 1
		}
	}    
      
    Write-Output ""
    Write-Output "Verifying vApp..."
    Write-Output "Verify-vApp -vAppName $vAppName"

    $result = Verify-vApp -vAppName $vAppName; # Start and End logged with function
    
    write-output $result    

	$date = Get-Date
    Write-Output "Execute-RefreshvApp completed (at $date)"

    if($result -eq $true)
    {
        $msg = "vApp $vAppName is ready for use, all machines deployed correctly, script exiting with code 0";
        Write-Output $msg

        #Log-vCloudAction -vAppName $vAppName -Action "info" -Details $msg 
        Log-vCloudEvent -EventID $EXIT_EXECUTE_REFRESH_VAPP -ExitCode 0;

        exit 0
    }
    else
    {
        $msg = "vApp $vAppName is not ready for use, not all machines deployed correctly, exiting with code 1"
        Write-Output $msg

        Log-vCloudEvent -EventID $EXIT_EXECUTE_REFRESH_VAPP -ExitCode 1;

        exit 1
    }
}

main

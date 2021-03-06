param
(

    [string] $TargetRig = $(throw 'TargetRig'),
    [string] $Username  = "faelab\tfsbuild", 
    [string] $Password  = "LMTF$`Bu1ld"
)

function main
{
  try
  {
	Write-Output "Loading Deployment.Utils"
	[System.Reflection.Assembly]::LoadFrom("..\Tools\DeploymentTool\Deployment.Utils.dll")
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

    
    $rig = $vCloudService.GetVapp($TargetRig);
    if($rig -eq $null)
    {
        throw "Rig '$TargetRig' does not exist";
    }

    #Iterate through vCloud machines  
    $machines = $vCloudService.Get_vCloudMachines($TargetRig); # Get-CIVM -vApp $rig
    foreach ($machine in $machines)
    {  	
        if($machine.Name -eq "TS-CAS1")
        {              
            
          [string] $SSOCISIP = $vCloudService.Get_vCloudMachineIPAddress(($machine.Name), $TargetRig);
          [string] $FTPWebReference = $SSOCISIP

          # Connect to target machine         
          if (![string]::IsNullOrEmpty($SSOCISIP))
          {
            write-output $machine.Name , $SSOCISIP
	        try
            {
                write-output "net use \\$SSOCISIP /user:faelab\tfsbuild $Password"
                net use \\$SSOCISIP /delete
                net use \\$SSOCISIP /user:faelab\tfsbuild $Password


            #1. Replace values in webconfig

	           $webConfigPath = "\\$SSOCISIP\d`$\TFL\SSO\Website\Web.config"
               $webconfig = Get-Content -Path $webConfigPath          
               $webconfig = $webconfig.Replace("TS-CAS1",$SSOCISIP)
             #  Set-Content $webConfigPath $webconfig
                Write-Output $webConfigPath
                Write-output overriding.. "TS-CAS1" with $SSOCISIP
           
               [xml]$webConfigXML = Get-Content $webConfigPath      
                    $webConfigXML.SelectNodes("configuration/appSettings/add[@key='PageStyleToUse']/@value") | % {$_.Value = "FTP" };
                    $webConfigXML.Save($webConfigPath)

            <#2. Replace values in Oyester\webconfig

                $webConfigPathOyster = "\\$SSOCISIP\d`$\TFL\SSO\Website\Oyster\Web.config"
                write-output $webConfigPathOyster

                $webconfigOyster = Get-Content -Path $webConfigPathOyster
                $webconfigOyster = $webconfigOyster.Replace("TS-CAS1",$SSOCISIP)
                Set-Content $webConfigPathOyster $webconfigOyster            
                Write-output overriding.. "TS-CAS1" with $SSOCISIP
           
              [xml] $webConfigOysterXML = Get-Content $webConfigPathOyster           
                    $webConfigOysterXML.SelectNodes("configuration/appSettings/add[@key='PageStyleToUse']/@value") | % {$_.Value = "Oyster" };
                    $webConfigOysterXML.Save($webConfigPathOyster)
          
                Write-output overriding..completed
          #>
              }     
              catch
              {
                $error = $_.Exception.ToString()
                Write-Error "$error"
                exit 1
              }
			  
           }
                           
        }
      
        #3.	The database: dbo.Products table: replace values which contain “TS-CAS1” (most importantly in the HomeUrl column) with the IP of TS-CAS1
        if($machine.Name -eq "TS-DB1")
        {
            [string] $SSODBIP = $vCloudService.Get_vCloudMachineIPAddress(($machine.Name), $TargetRig);
            try
            {
                write-output "Modifying SSO Database Product table"
                $Datasource = "$SSODBIP" + "\Inst3"
		        Write-Output "Updating SingleSignOn Database on $Datasource ..."

                $cmdText = "exec [dbo].[ProductUpdate] 
                                'http://$SSODBIP/HomePage/Validate', 
                                'http://$SSODBIP/HomePage/LogOff', 
                                'http://$SSODBIP'
                                ,null ,
                                'A3AC81D4-80E8-4427-B348-A3D028DFDBE7'

                 		    exec [dbo].[ProductUpdate] 
                                'http://$SSODBIP`:8080/Account/Validate', 
                                'http://$SSODBIP`:8080/Account/LogOff', 
                                'http://$SSODBIP`:8080'
                                ,null,
                                '6687E912-D120-461E-9DA9-3C0288629F4F'"
         
	            Write-Host "$result"
                Write-Output "... SSO Database Updated."         
		        write-output ""
            }
            catch
            {
                $error = $_.Exception.ToString()
                Write-Error "$error"
                exit 1
            }  
        }                
    }
  }
  catch [System.Exception]
  {
    $error = $_.Exception.ToString()
    Write-Error "$error"

    Log-DeploymentScriptEvent -LastError "EXCEPTION in FixUp_NotificationFunctionalRig.ps1" -LastException $error
	
    exit 1
  }
}

main


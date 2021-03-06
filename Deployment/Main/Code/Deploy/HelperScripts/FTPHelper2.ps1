function Get-IisServiceGroupFromConfig()
{
    #    Get this first as Get-CommonRoles relys on $config variable to know which ones to load.
    [xml] $config = Get-DeploymentConfiguration $configFile

    $commonRoles = Get-CommonRoles
    #Set-Variable -Name commonRoles -Value Get-CommonRoles -Scope "global"

    $iisServices = @();
    
    foreach ($machine in $config.configuration.machine)
    {
        foreach ($role in $machine.ServerRole)
        {
            if ($role.Name -eq 'tfl.webdeploy') # -eq is case-insensitive
            {
            	# Resolve any 'included' server roles
            	if ($role.Include)
            	{
                	$ResolvedServerRole = GetCommonRole($role.Include)
                }
                else
                {
                    $ResolvedServerRole = $role;
                }
                # ServerRole.ServiceDeploy.Services.Service[n]
                foreach ($webDeploy in $ResolvedServerRole.WebDeploy)
                {
                    $iisService = New-Object psobject
                    $iisService | Add-Member NoteProperty -Name HostName $machine.Name
                    $iisService | Add-Member NoteProperty -Name SiteName $webDeploy.Site.Name
                    $iisService | Add-Member NoteProperty -Name PortNumber $webDeploy.Site.Port
                    $iisService | Add-Member NoteProperty -Name SiteStatus ""
                    $iisService | Add-Member NoteProperty -Name AppPool $webDeploy.Site.ApplicationPool
                    $iisService | Add-Member NoteProperty -Name AppPoolStatus ""
                    
                    $iisServices += $iisService;
                }
            }
        }
    }
    return $iisServices;
}

function Get-IISStatus()
{
    $webDeployRoles = Get-IisServiceGroupFromConfig;
    # HostName, SiteName, PortNumber, AppPool
    
    if ($webDeployRoles -ne $null)
    {
        $thisHost = "";
        $webDeployRoles | %{
            
            if ($thisHost -ne $_.HostName)
            {
                # Swap remote session to next host
                if ($remotesession -ne $null)
                {
                    Remove-PSSession $remotesession
                }
                $remotesession = new-pssession -computername $_.HostName
                Invoke-Command -Session $remotesession -ScriptBlock { Import-Module WebAdministration; }
                $thisHost = $_.HostName
            }
            
            $status = Invoke-Command -Session $remotesession -ScriptBlock { param($siteName)
                    Get-WebsiteState $siteName } -ArgumentList $_.SiteName
                    
            $_.SiteStatus = $status.Value;
                
            $status = Invoke-Command -Session $remotesession -ScriptBlock { param($appPoolName)
                    Get-WebAppPoolState $appPoolName } -ArgumentList $_.AppPool
                    
            $_.AppPoolStatus = $status.Value;
        }
        
        #Sites
        $webDeployRoles | Format-Table -Property HostName, SiteName, SiteStatus, AppPool, AppPoolStatus
        
        #Distinct AppPools
        #$webDeployRoles | Select-Object HostName, AppPool, AppPoolStatus | Sort-Object -Property HostName, AppPool -Unique # | Format-Table -Property HostName, AppPool, AppPoolStatus
        
    }
    
}


# Get-ServiceGroups returns lists of MachineName, serviceName tuples for manipulating
function Get-PareServiceGroup()
{
     Get-ServiceGroupFromConfig('PARE*');
}
function Get-FaeServiceGroup()
{
     Get-ServiceGroupFromConfig('FAE*');
}
function Get-FtmServiceGroup()
{
     Get-ServiceGroupFromConfig('FTM*');
}


#---------------------------------------------------------------------
#--- Top level Start/Stop/Get command being implemented --------------
#---------------------------------------------------------------------

##### Get Service Statuses
function Get-ServicesStatusAll()
{
    Get-PareServiceStatus;
    
    Get-FaeServiceStatus;
    
    Get-FtmServiceStatus;
    
    Get-IISStatus;
}

function Get-PareServiceStatus()
{
    Get-ServicesStatus ( Get-PareServiceGroup );
}
function Get-FaeServiceStatus()
{
    Get-ServicesStatus ( Get-FaeServiceGroup );
}
function Get-FtmServiceStatus()
{
    Get-ServicesStatus ( Get-FtmServiceGroup );
}
##### Stop - start Services by group
function Stop-PareServices()
{
    Stop-ServiceGroup( Get-PareServiceGroup );
}
function Stop-FaeServices()
{
    Stop-ServiceGroup( Get-FaeServiceGroup );
}
function Stop-FtmServices()
{
    Stop-ServiceGroup( Get-FtmServiceGroup );
}
function Stop-AllServices()
{
    Stop-PareServices;
    Stop-FaeServices;
    Stop-FtmServices;
}
### start ---
function Start-PareServices()
{
    Start-ServiceGroup( Get-PareServiceGroup );
}
function Start-FaeServices()
{
    Start-ServiceGroup( Get-FaeServiceGroup );
}
function Start-FtmServices()
{
    Start-ServiceGroup( Get-FtmServiceGroup );
}
function Start-AllServices()
{
    Start-PareServices;
    Start-FaeServices;
    Start-FtmServices;
}

#---------------------------------------------------------------------

function Get-DeploymentConfiguration
(
    #[string] $configFile = "Integration.TSRig.VC.xml" #$(Throw 'ConfigPath is required')
    # SEE GLOBAL VARIABLE $configFile and Set-ConfigFile in includes
)
{
	[string] $exePath = split-path $myinvocation.scriptname;
    
    $scriptPath = Join-Path $exePath "..\Scripts";    
	[string] $fullConfigPath = Join-Path $scriptPath $ConfigFile
    
    if (-not (Test-Path $fullConfigPath))
    {
        Write-Host "Cannot find specified config file at $fullConfigPath";
        Write-Host ""
    }
    
    # Read Config File
    [xml] $config = Get-Content $fullConfigPath;
    
    # Get Common Included Roles
    [string]$Environment = $config.Configuration.Environment;
    $commonRoles = @()
    foreach($commonRoleNode in $config.configuration.CommonRoleFile)
    {
        if(![string]::IsNullOrEmpty($commonRoleNode))
        {
            $CommonRolesXMLPath = join-path $scriptPath $commonRoleNode;
            $commonRoles += [xml](Get-Content $CommonRolesXMLPath);
        }
    }
    
    return $config
}

function Get-ServicesStatus( $serviceGroup )
{
    if ($serviceGroup -ne $null)
    {
        $serviceGroup | ForEach-Object { Get-Service -computername $_.MachineName -name $_.ServiceName } | Format-table -property MachineName,Name,Status
    }
}

function Start-ServiceGroup($serviceGroup)
{
    $serviceGroup | ForEach-Object {
        $svc = Get-Service -computername $_.MachineName -name $_.ServiceName;
        if ($svc.Status -eq "Stopped")
        {
            Write-Output ("Starting service " + $_.ServiceName);
            $svc.Start();
        }
        elseif ($svc.Status -eq "Starting")
        {
            Write-Output ($svc.Name + " already starting on " + $_.MachineName);
        }
        else
        {
            Write-Output ($svc.Name + " already running on " + $_.MachineName);
        }
    }
}

function Stop-ServiceGroup($serviceGroup)
{
    $serviceGroup | ForEach-Object {
        $svc = Get-Service -computername $_.MachineName -name $_.ServiceName;
        if ($svc.Status -eq "Running")
        {
            Write-Output ("Stopping service " + $_.ServiceName + " on " + $_.MachineName);
            $svc.Stop();
        }
        elseif ($svc.Status -eq "Stopping")
        {
            Write-Output ($svc.Name + " already stopping on " + $_.MachineName);
        }
        else
        {
            Write-Output ($svc.Name + " already stopped on " + $_.MachineName);
        }
    }
}

#---------------------------------------------------------------------

#Import-Module .\FTPHelper2.includes.ps1;

### INCLUDES ###

function Set-ConfigFile([string]$configFileName)
{
    Set-Variable -Name ConfigFile -Value $configFileName -Scope 'global'
}

function Get-ServiceGroupFromConfig([string]$descLike)
{
    #    Get this first as Get-CommonRoles relys on $config variable to know which ones to load.
    [xml] $config = Get-DeploymentConfiguration $configFile

    $commonRoles = Get-CommonRoles
    #Set-Variable -Name commonRoles -Value Get-CommonRoles -Scope "global"

    $machineServices = @();
    
    foreach ($machine in $config.configuration.machine)
    {
        foreach ($role in $machine.ServerRole)
        {
            if (($role.Description -like $descLike) -and ($role.Name -like '*ServiceDeploy*'))
            {
            	# Resolve any 'included' server roles
            	if ($role.Include)
            	{
                	$ResolvedServerRole = GetCommonRole($role.Include)
                }
                else
                {
                    $ResolvedServerRole = $role;
                }
                # ServerRole.ServiceDeploy.Services.Service[n]
                foreach ($service in $ResolvedServerRole.ServiceDeploy.Services.Service)
                {
                    $machineService = New-Object psobject
                    $machineService | Add-Member NoteProperty -Name MachineName $machine.Name
                    $machineService | Add-Member NoteProperty -Name ServiceName $service.Name
                    
                    $machineServices += $machineService;
                }
            }
        }
    }
    return $machineServices;
}

function Get-CommonRoles()
{
    [string] $exePath = split-path $myinvocation.scriptname;
    
    if ([string]::IsNullOrEmpty($ConfigFile))
    {
        Write-Host 'Please specify a deployment config file using Set-ConfigFile "<filename>"';
        Write-Host "";
    }
    
    $scriptPath = Join-Path $exePath "..\Scripts";    
	[string] $fullConfigPath = Join-Path $scriptPath $ConfigFile
    
    if (-not (Test-Path $fullConfigPath))
    {
        Write-Host 'Cannot find config file ' + $fullConfigPath;
        Write-Host "";
    }
    
    # Get Common Included Roles
    [string]$Environment = $config.Configuration.Environment;
    $commonRoles = @()
    foreach($commonRoleNode in $config.configuration.CommonRoleFile)
    {
        if(![string]::IsNullOrEmpty($commonRoleNode))
        {
            $CommonRolesXMLPath = join-path $scriptPath $commonRoleNode;
            $commonRoles += [xml](Get-Content $CommonRolesXMLPath);
        }
    }
    
    return $commonRoles;    
}

function GetCommonRole($include)
{
	# just use the first one we find that matches. File validation should have made sure we have only unique values and
	# that they will always exist
	foreach($commonRole in $commonRoles)
	{
		$ResolvedServerRole = $commonRole.configuration.CommonRoles.ServerRole | ? { $_.Include -eq $include}
		if($ResolvedServerRole -ne $null)
		{
			return $ResolvedServerRole
		}
        $ResolvedServerRole = $commonRole.configuration.CommonRoles.DatabaseRole | ? { $_.Include -eq $include}
		if($ResolvedServerRole -ne $null)
		{
			return $ResolvedServerRole
		}
     }
     # error 
     throw "Error reading common role: $include"
}

function Decrypt-WebConfig($machineName, $section, $physicalPath)
{
    $remotesession = new-pssession -computername $MachineName
    Invoke-Command -Session $remotesession -ScriptBlock { 
       param($section,$physicalPath) 
      c:\windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe -pdf $section "$physicalPath"
    } -ArgumentList $section , $physicalPath
    
    $remoteExitCode = invoke-command -ScriptBlock { $lastexitcode } -Session $remotesession
    if($remoteExitCode -ne 0)
    {
        "Decryption failed aspnet_regiis exited with error code $remoteExitCode"
    }
    else
    {
        "Decryption succedded"
    }
    
    Remove-PSSession $remotesession
}

function Get-Test
{
	$myinvocation.scriptname;    
    $MyInvocation.MyCommand.Module
}

#------- MAIN -------

Write-Host "Now set desired config file e.g. > Set-ConfigFile 'Staging.Internal.xml'"
#Set-ConfigFile 'DevInt.Internal.Performance.xml'
 
#Get-ServicesStatusAll

Get-IISStatus

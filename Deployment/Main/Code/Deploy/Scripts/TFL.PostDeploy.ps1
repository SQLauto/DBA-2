[cmdletbinding()]
param
(
    [string] $ComputerName,
    [string] $Environment,
	[Deployment.Domain.Roles.FileShareDeploy]$DeployRole,
	[string] $Password = "",
    [switch] $ConfigOnly
)





param
(
    [string] $MachineName,
    [string] $Environment,
	[string] $RootConfig,
	[string] $Password,
	[System.XML.XmlElement]$ConfigPart
)
function main
{

$startTime = Get-Date 
LogInfo "--------------------------------------------------------------------------------"
LogInfo ("--- Starting PostDeploy action of '" + $ConfigPart.Description + "' on $ComputerName"  + " at " + $startTime)
LogInfo "--------------------------------------------------------------------------------"

$Script:exitCode = 0
Try
{
	$scriptpath = split-path $myinvocation.scriptname;
	$softwarePath = Join-Path $scriptpath ..\..
	$accountDetailsPath = Join-Path $scriptpath "..\Accounts\$Environment.ServiceAccounts.XML"
    
    [bool]$HasWindowsService = Hasproperty $configPart "WindowsServicePostDeploy"
    [bool]$HasAppFabric = HasProperty $configPart "AppFabricPostDeploy"
    [bool]$HasWebService = Hasproperty $configPart "WebServicePostDeploy"

    # windows services
    if($HasWindowsService -eq $true)
    {
        foreach($windowsService in $configPart.WindowsServicePostDeploy)
        {
            PostDeploy-WindowsService $MachineName $windowsService.GetAttribute("ServiceName") $windowsService.GetAttribute("State") $windowsService.GetAttribute("Action")
        }
    }
        
    if($HasAppFabric -eq $true)
    {
        foreach($appFabric in $ConfigPart.AppFabricPostdeploy)
        {
            PostDeploy-AppFabric $MachineName $appFabric.GetAttribute("PortNumber") $appFabric.GetAttribute("State") $appFabric.GetAttribute("Action")
        }
    }
        
    if($HasWebService -eq $true)
    {
        foreach($webService in $ConfigPart.WebServicePostDeploy)
        {
            PostDeploy-WebService $MachineName $webService.GetAttribute("PortNumber") $webService.GetAttribute("WebServicePath") $webService.GetAttribute("Timeout")
        }
    }
    

}
Catch [System.Exception]
{
	$scriptName = split-path $MyInvocation.ScriptName -Leaf
	$lineNumber =  $_.InvocationInfo.ScriptLineNumber
    $errorMessageToLog = "Error occurred in script [$scriptName]  at line [$lineNumber] with error : " + $_.Exception.ToString() 
	LogError $errorMessageToLog
	$Script:exitCode = 1
}

$endTime = Get-Date 
$totalMinutes = "{0:N4}" -f ($endTime-$startTime).TotalMinutes
if($Script:exitCode -eq 0)
{
	LogSummary ("Successfully completed PostDeploy role '" + $ConfigPart.Description + "' on $ComputerName" + " in " + $totalMinutes + " minutes")   
}
else
{
	LogSummary ("Unsuccessfully completed PostDeploy role '" + $ConfigPart.Description + "' on $ComputerName" + " in " + $totalMinutes + " minutes")   
}

LogInfo "--------------------------------------------------------------------------------"
LogInfo ("--- Ending PostDeploy action of '" + $ConfigPart.Description + "' on $ComputerName" + " at " + $endTime) 
LogInfo "--------------------------------------------------------------------------------"
 
exit $Script:exitCode
}

##############################################################################
#### WINDOWS SERVICES FUNCTIONS
##############################################################################
function PostDeploy-WindowsService($machineName, $serviceName, $state, $action)
{
    # If the service doesnt exist, dont print the error on screen as this scares people
	# just silently continue
    $sc = Get-Service -ComputerName $machineName -Name $serviceName -ErrorAction SilentlyContinue
    if($sc -eq $null)
    {
        # This can't be a fail, the service may not yet have been installed
        LogError "Service $serviceName not found"
        $Script:exitCode = 1
		continue
    }
        
    $currentState = $sc.Status
	LogInfo "Current State of $serviceName is $currentState"
    if($currentState -eq $state)
    {
        LogInfo "Service $serviceName already $state"
        continue
    }
        
    LogInfo "Service $serviceName is in state $currentState"
    if($action -eq "Fail")
    {
        LogInfo "Failing deployment"
        $Script:exitCode = 1
    }
    elseif($action -eq "Ignore")
    {
        LogInfo "Action set to ignore, taking no further action"
        break
    }
    elseif($action -eq "Fix")
    {
        if($state -eq "Stopped")
        {
			LogInfo "Try to stop service $serviceName"	
            $result = StopService $MachineName $serviceName
            if($result -eq $false)
            {
				LogError "Service failed to stop service in time limit, current state is $currentState"
                $Script:exitCode = 1
            }
			else
			{
				LogInfo "Service $serviceName stopped succesfully"
			}
        }
        elseif($state -eq "Running")
        {
			LogInfo "Try  to start service $serviceName"	
            $result = StartService $MachineName $serviceName
            if($result -eq $false)
            {
				LogError "Service failed to start service in time limit, current state is $currentState"
                $Script:exitCode = 1
            }
			else
			{
				LogInfo "Service $serviceName started succesfully"
			}
        }
        else
        {
            LogError "Undefined service state: $state"
            $Script:exitCode = 1
        }
    }
    else
    {
        LogError "Undefined action: $action"
        $Script:exitCode = 1
    }
}

function StartService($machineName, $serviceName)
{
	$sc = Get-Service -ComputerName $machineName -Name $serviceName
    if($sc.Status -ne "Running" -and $sc.Status -ne "StartPending")
	{	        
		$sc.Start()
	}
    $status  = PollServiceStatus $MachineName $serviceName "Running"
    if($status -eq "Running")
    {            
        return $true
    }
    else
    {
        return $false
    }     
}

function StopService($machineName, $serviceName)
{
	$sc = Get-Service -ComputerName $machineName -Name $serviceName
    
    if($sc.Status -ne "Stopped" -and $sc.Status -ne "StopPending")
    {
		$sc.Stop()
	}
    $status  = PollServiceStatus $MachineName $serviceName "Stopped"
    if($status -eq "Stopped")
    {
        LogInfo "Service $serviceName stopped succesfully"
        return $true
    }
    else
    {            
        return $false
    } 	
}

function PollServiceStatus($machineName, $serviceName, $status)
{
        for ($i=0; $i-le 60; $i++)      
    	{
            $sc = Get-Service -ComputerName $machineName -Name $serviceName
            if($sc.Status -eq $status)
            {
                break
            }

            Start-Sleep -Seconds 4;
        }
        
        $sc = Get-Service -ComputerName $machineName -Name $serviceName
        return $sc.Status
}
##############################################################################
##############################################################################

##############################################################################
### APP FABRIC FUNCTIONS
##############################################################################
function PostDeploy-AppFabric($MachineName, $portNumber, $state, $action)
{
    $ScriptBlock = {
        Param($Port,$CacheHostState,$Action)
        Try
        {
			$Script:exitCode = 0

            Import-Module DistributedCacheAdministration
			Use-CacheCluster
            $cacheHost = Get-CacheHost -HostName $env:COMPUTERNAME -CachePort $Port

            $currentState = $cacheHost.Status
            Write-Output "Current Status of AppFabric is $currentState"
            if($currentState -eq $CacheHostState)
            {
                Write-Output "AppFabric is already $CacheHostState"
                continue   
            } 

            Write-Output "AppFabric is in state $currentState"
            if($Action -eq "Fail")
            {
                Write-Output "Failing deployment"
                $Script:exitCode = 1
            }
            elseif($Action -eq "Ignore")
            {
                    Write-Output "Action set to ignore, taking no further action"
                    break
            }
            elseif($Action -eq "Fix")
            {
                if($CacheHostState -eq "Up")
                {
				    Write-Output "Try to start AppFabric"	
                    Start-CacheCluster
                    $cacheHost = Get-CacheHost -HostName $env:COMPUTERNAME -CachePort $Port

                    if($cacheHost.Status -ne $CacheHostState)
                    {
					    Write-Error "Failed to start service AppFabric, current state is ${cacheHost.Status}"
                        $Script:exitCode = 1
                    }
				    else
				    {
					    Write-Output "AppFabric started succesfully"
				    }
                }
                elseif($CacheHostState -eq "Down")
                {
				    Write-Output "Try to stop AppFabric"	
                    Stop-CacheCluster
                    $cacheHost = Get-CacheHost -HostName $env:COMPUTERNAME -CachePort $Port

                    if($cacheHost.Status -ne $CacheHostState)
                    {
					    Write-Error "Failed to stop service AppFabric, current state is ${cacheHost.Status}"
                        $Script:exitCode = 1
                    }
				    else
				    {
					    Write-Output "AppFabric stopped succesfully"
				    }
                }
                else
                {
                    Write-Error "Undefined service state: $CacheHostState"
                    $Script:exitCode = 1
                }
            }
            else
            {
                Write-Error "Undefined action: $ActionToTake"
                $Script:exitCode = 1
            }

			Write-Output "AppFabric Post Deploy Script exiting with code $Script:exitCode"
        }
        catch
        {
            Write-Error "Setting AppFabric status"
			$scriptName = split-path $MyInvocation.ScriptName -Leaf
			$lineNumber =  $_.InvocationInfo.ScriptLineNumber
			$errorMessageToLog = "Error occurred in script [$scriptName]  at line [$lineNumber] with error : " + $_.Exception.ToString() 
			Write-Error $errorMessageToLog
			$Script:exitCode = 100
        }
	    #Set-Variable -Name exitCode -Value $Script:exitCode -Scope 1
    }

    if($MachineName -eq $env:COMPUTERNAME)
    {    
        LogInfo "Bringing local AppFabric Cluster $state"
        Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $portNumber, $state, $action
    }
    else
    {
        LogInfo "Bringing Remote AppFabric Cluster on $ComputerName $state"
        $RemoteSession = New-PSSession -ComputerName $MachineName
        Invoke-Command -Session $RemoteSession -ScriptBlock $ScriptBlock -ArgumentList $portNumber, $state, $action
        $Script:exitCode = invoke-command -ScriptBlock { $Script:exitCode } -Session $RemoteSession
    }
}
##############################################################################
##############################################################################

##############################################################################
### WEB SERVICES FUNCTIONS
##############################################################################
function PostDeploy-WebService($MachineName, $Port, $WebServicePath, $Timeout)
{
    $WebServiceUrl = New-Object -TypeName System.Uri -ArgumentList "http://$MachineName`:$Port/$WebServicePath"
    $Success = $false
    $HTTP_Status = 0

    LogInfo "Polling $WebServiceUrl..."

    for($i = 0; $i -lt 10; $i++)
    {
		$executionTime = Get-Date
		LogInfo "Execution $i at $executionTime with timeout $Timeout"

        $HTTP_Status = PollWebService $WebServiceUrl $Timeout
    
        if($HTTP_Status -ge 200 -and $HTTP_Status -lt 300)
        {
            $Success = $true
            break
        }

        LogInfo "Web Service Polling Failed. Retrying..."
        Start-Sleep -Seconds 5;
    }

    if($Success)
    {
        LogInfo "Successfully Polled Web Service"
        $Script:exitCode = 0
    }
    else
    {
        LogError "Unsuccessfully Polled Web Service after $i times with Status Code: $HTTP_Status"
        $Script:exitCode = 1
    }
}

function PollWebService([System.Uri]$Url, [int]$Timeout)
{
    $HTTP_Request = [System.Net.WebRequest]::Create($Url)
    $HTTP_Request.Timeout = $Timeout*1000
    try
    {
        $HTTP_Response = $HTTP_Request.GetResponse();
    }
    catch [System.Net.WebException]
    {
        LogInfo $_.Exception.ToString()
    }
   
    return [int]$HTTP_Response.StatusCode
    
}
##############################################################################
##############################################################################

main
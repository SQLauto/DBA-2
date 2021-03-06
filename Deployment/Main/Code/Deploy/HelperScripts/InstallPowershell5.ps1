param
(
    [string[]] $TargetMachine, 
	[string] $DriveLetter        = "D",
    [string] $Installer          = "$($DriveLetter):\Software\Win7AndW2K8R2-KB3134760-x64.msu",
    [string] $Username           = "", # If blank windows auth is used
    [string] $Password           = "", 
    [string] $DeploymentLocation = "$($DriveLetter):\Deployment"
)
function main
{
Try
{
    if ($psversiontable.PsVersion.Major -lt 5)
    {
       $msg = "The machine running this must have powershell 5 as a minimum on it";
       throw $msg;
    }

    $TargetMachine

    $scriptpath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)
    $startTime = Get-Date 
    $installerName = [System.IO.Path]::GetFileName($Installer)

    #Only upgrade the servers which have not got Powershell 5
    $serversWithoutPowershell5 = @()
    [bool] $installationsAreRequired = $false
    ForEach ($server in $TargetMachine)
    {           
        $isVersion5 = Invoke-Command -ComputerName $server -ScriptBlock {[bool] $isVersion5 = $psversiontable.PsVersion.Major -eq 5; $isVersion5; }
        if ($isVersion5)
        {
            Write-Output "Version 5 is already installed on $server"
        }
        else
        {
            Write-Output "Version 5 needs to be installed on $server"
            $serversWithoutPowershell5 += $server
            $installationsAreRequired = $true
        }          
    }

    if ($installationsAreRequired)
    {
        $servers = $serversWithoutPowershell5 -join ","
            
        Write-Output "Upgrading to powershell 5 ($installerName) on Machine(s) $servers. Machine may be rebooted. $startTime"
    
        # Copy installer to target machine
        $temp = $DeploymentLocation -replace ":", "`$"
            
            $serversWithoutPowershell5 | % {
                        $targetFolder = "\\$_\$temp"    
                        Write-Output "Copying $installerName to $targetFolder"
                        New-Item $targetFolder -ItemType Directory -Force
                        Copy-Item "$Installer" "$targetFolder\$installerName" -Force
            }  
    
        # Remotley execute installer
        $logFile = "$DeploymentLocation\$installerName" + ".log"
    
            # wusa.exe is the thing that executes .msu files (win update)
        if(![string]::IsNullOrEmpty($Username))
        {
            Write-Output "psexec \\$servers -u $Username -p $Password -h wusa.exe $DeploymentLocation\$installerName /quiet /log:$logFile"
            & psexec /accepteula \\$servers -u $Username -p $Password -h wusa.exe $DeploymentLocation\$installerName /quiet /log:$logFile      
        }
        else
        {
            Write-Output "psexec \\$servers wusa.exe $DeploymentLocation\$installerName /quiet /log:$logFile"
            & psexec /accepteula \\$servers wusa.exe $DeploymentLocation\$installerName /quiet /log:$logFile
        }  
    }

    #check to see if there are any Pending reboots.
    Import-Module .\PendingReboot.ps1 -Force

    [bool] $rebootsRequired = $false
    $machinesToReboot = @()
    foreach ($server in $TargetMachine)
    {
        $rebootInformation = Get-PendingReboot -ComputerName $server
        if ($rebootInformation.RebootPending -eq $True)
        {
            $msg = "REBOOT IS PENDING ON: $server reboot this machine."
	        Write-Output $msg
            $rebootsRequired = $true
            $machinesToReboot += $server
            Write-Output "$server Has successfully rebooted"
        }
        else
        {
            $msg = "No reboot required for: $server."
            Write-Output $msg
        }
    }

    if ($rebootsRequired)
    {
        $rebootServers = $machinesToReboot -join ","
        Restart-Computer -ComputerName $rebootServers -Wait
    }
 
    ForEach($server in $TargetMachine)
    {
          
        $isVersion5 = Invoke-Command -ComputerName $server -ScriptBlock {[bool] $isVersion5 = $psversiontable.PsVersion.Major -eq 5; $isVersion5; }
        if ($isVersion5)
        {
            Write-Output "SUCCESS: Powershell 5 installed on $server"
        }
        else
        {
            $msg = "ERROR: Powershell 5 is not on $server"
            Write-Host -ForegroundColor Red $msg              
        }    
    }
    
    $endTime = Get-Date 
    Write-Output "Finished Powershell 5.0 upgrade on Machine $TargetMachine. $endTime"
    Write-Output "Log file at $targetFolder"
}
Catch [System.Exception]
{
            $error = $_.Exception.ToString()
            Write-Error "$error"
            exit 1
}
}

main

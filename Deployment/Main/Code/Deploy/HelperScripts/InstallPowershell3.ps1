param
(
    [string] $TargetMachine      = "", 
    [string] $Installer          = "\\FTDC2DFS001\Media\PowerShell3\PS3_Windows6.1-KB2506143-x64.msu",
    [string] $Username           = "faelab\xjasonblackford", # If blank windows auth is used
    [string] $Password           = "Ches1549#", 
	[string] $DriveLetter        = "D",
    [string] $DeploymentLocation = "$($DriveLetter):\Deployment"
)
function main
{
Try
{
    $startTime = Get-Date 
    $installerName = [System.IO.Path]::GetFileName($Installer)
    Write-Output "Upgrading to powershell 3 ($installerName) on Machine $TargetMachine. Machine may be rebooted. $startTime"
    $scriptpath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)
   
    # Connect to target machine
    if(![string]::IsNullOrEmpty($Username))
    {
        Write-Output "net use \\$TargetMachine /user:$Username $Password"
        net use \\$TargetMachine /user:$Username $Password
    }
    else
    {
        Write-Output "net use \\$TargetMachine"
        net use \\$TargetMachine
    }
    
    # Copy installer to target machine
    $temp = $DeploymentLocation -replace ":", "`$"
    $targetFolder = "\\$TargetMachine\$temp"    
    Write-Output "Copying $installerName to $targetFolder"
	New-Item $targetFolder -ItemType Directory -Force
	Copy-Item "$Installer" "$targetFolder\$installerName" -Force     
    
    # Remotley execute installer
    $logFile = "$DeploymentLocation\$installerName" + ".log"
    Write-Output "Installing $installerName on $TargetMachine, machine may be restarted if needed"
    
	# wusa.exe is the thing that executes .msu files (win update)
    if(![string]::IsNullOrEmpty($Username))
    {
        Write-Output "psexec \\$TargetMachine -u $Username -p $Password wusa.exe $DeploymentLocation\$installerName /quiet /log:$logFile"
        & psexec \\$TargetMachine -u $Username -p $Password wusa.exe $DeploymentLocation\$installerName /quiet /log:$logFile 2> $null      
    }
    else
    {
        Write-Output "psexec \\$TargetMachine wusa.exe $DeploymentLocation\$installerName /quiet /log:$logFile"
        & psexec \\$TargetMachine wusa.exe $DeploymentLocation\$installerName /quiet /log:$logFile 2> $null
    }  
    
    $endTime = Get-Date 
    Write-Output "Finished Powershell 3 upgrade on Machine $TargetMachine. $endTime"
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


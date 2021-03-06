param
(
    [string] $TargetMachine      = "", 
    [string] $Installer          = "\\FTDC2DFS001\Media\.NET Frameworks\Microsoft .NET Framework 4.5.1\NDP451-KB2858728-x86-x64-AllOS-ENU.exe",
    [string] $Username           = "", # If blank windows auth is used
    [string] $Password           = "", 
	[string] $DriveLetter        = "D",
    [string] $DeploymentLocation = "$($DriveLetter):\Deployment"
)
function main
{
Try
{
    $startTime = Get-Date 
    $installerName = [System.IO.Path]::GetFileName($Installer)
    Write-Output "Upgrading .NET ($installerName) on Machine $TargetMachine. Machine may be rebooted. $startTime"
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
    $logFile = "$DeploymentLocation\$installerName" + "_log"
    Write-Output "Installing $installerName on $TargetMachine, machine may be restarted if needed"
    
    if(![string]::IsNullOrEmpty($Username))
    {
        Write-Output "psexec \\$TargetMachine -u $Username -p $Password $DeploymentLocation\$installerName /q /log $logFile"
        & psexec /accepteula \\$TargetMachine -u $Username -p $Password $DeploymentLocation\$installerName /q /log $logFile
    }
    else
    {
        Write-Output "psexec \\$TargetMachine $DeploymentLocation\$installerName /q /log $logFile"
        & psexec /accepteula \\$TargetMachine $DeploymentLocation\$installerName /q /log $logFile
    }  
    
    $endTime = Get-Date 
    Write-Output "Finished .NET upgrade on Machine $TargetMachine. $endTime"
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


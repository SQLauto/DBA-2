# A generic script that iterates through all the machines in a rig and runs the given installer
# -Installer refers to the absolute path of installer or msi to execute
# -UpgradeScript is the relative path of the powershell upgrade script that performs the upgrade
# -UpgradeScript must conform to the following pattern, it must decalre the following parameters
# 
#    -TargetMachine, machine name of ip address to upgrade
#    -Installer, the absolute path of installer or msi to execute          
#    -Username, user name to connect to target machine as (if blank windows auth is used)           
#    -Password, password for above user         
#    -DeploymentLocation, the location on target machine where the upgrade we be staged
#
# Examples of use
# RunInstaller_LabManagerRig.ps1 -TargetRig 'hamada_bl' -UpgradeScript 'InstallPowershell3.ps1' -Installer '\\FTDC2DFS001\Media\PowerShell3\PS3_Windows6.1-KB2506143-x64.msu'
#
# RunInstaller_LabManagerRig.ps1 -TargetRig 'hamada_bl' -UpgradeScript 'InstallDotNet.ps1' -Installer '\\FTDC2DFS001\Media\.NET Frameworks\Microsoft .NET Framework 4.5.2\NDP452-KB2901907-x86-x64-AllOS-ENU.exe'
#

param
(
    [string] $TargetRig          = $(throw 'TargetRig'),
	[string] $DriveLetter    = "D",
    [string] $Installer          = "", #"\\FTDC2DFS001\Media\.NET Frameworks\Microsoft .NET Framework 4.5.2\NDP452-KB2901907-x86-x64-AllOS-ENU.exe",
    [string] $Username           = "faelab\tfsadmin", 
    [string] $Password           = "LMTF`$Adm1n", 
    [string] $DeploymentLocation = "$($DriveLetter):\Deployment",
    [string] $UpgradeScript      = "", #"InstallDotNet.ps1",    
    [string] $IgnoreBoxes        = "FAEADG001" #comma seperated list of machines to ignore, optionally dont upgrade the AD box, it might get rebooted!
)
function main
{
Try
{
    $startTime = Get-Date 
    $installerName = [System.IO.Path]::GetFileName($Installer)
    $scriptpath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)
    Write-Output "Upgrading on Rig $TargetRig using script $UpgradeScript and installer $installerName. Machines may be rebooted. $startTime"
	if(![string]::IsNullOrEmpty($IgnoreBoxes))
	{
		Write-Output "Install will ignore machines $IgnoreBoxes"
	}
    Write-Output ""
    Write-Output "Importing vCloud module..."
	Write-Output "Import-Module $scriptpath\..\Scripts\vCloud.ps1"
    Import-Module $scriptpath\..\Scripts\vCloud.ps1 -Force
	    
    $rig = Get-CIVapp -Name $TargetVapp -ErrorAction SilentlyContinue;
    if ($rig -eq $null)
    {
        throw "Rig $TargetRig does not exist"
    }
    
    # Iterate through LM machines    
	$machines = Get-vCloudMachines -vApp $rig
    $UpgradeScript = "$scriptpath\$UpgradeScript"
	$ignoreList = $IgnoreBoxes.Split(',')
    foreach($machine in $machines)
    {
        $machineName = $machine.name
        $ignore = $false
        foreach($ignoreMachine in $ignoreList)
        {
            if($machineName -eq $ignoreMachine.Trim())
            {
                $ignore = $true
            } 
        }
        if(!$ignore)
        { 
            $externalIP = Get-vCloudMachineIPAddress -vApp $rig -MachineName $machineName
			Write-Output "Upgrading machine $machineName, external IP $externalIP"
            Write-Output "$UpgradeScript -TargetMachine $externalIP -Installer $Installer -Username $Username -Password $Password -DeploymentLocation $DeploymentLocation"
            & $UpgradeScript -TargetMachine $externalIP -Installer $Installer -Username $Username -Password $Password -DeploymentLocation $DeploymentLocation    
        } 
        else
        {
            Write-Output "Ignoring machine $machineName"
        }           
    }
    
    $endTime = Get-Date 
    Write-Output "Finished upgrade of Rig $TargetRig. $endTime"
	Write-Output ""
}
Catch [System.Exception]
{
    $error = $_.Exception.ToString()
    Write-Error "$error"
    exit 1
}
}

main


# Connect to a rig and get the Powershell and .net version deployed
param
(
    [string] $TargetRig          = "Camden.Servicing.FTP.DTN",
    [string] $Username           = "faelab\xjasonblackford", 
    [string] $Password           = "Ches1549#"
)
function main
{
Try
{
    $scriptpath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)
    Write-Output "Querying .NET and PS version on rig $TargetRig"
    Write-Output ""
    Write-Output "Importing LabManager module..."
	Write-Output "Import-Module $scriptpath\..\Scripts\LabManager.ps1"
    Import-Module $scriptpath\..\Scripts\LabManager.ps1  
	    
    if(!(DoesRigExist $TargetRig))
    {
        throw "Rig $TargetRig does not exist"
    }
    
    # Iterate through LM machines  
    $machines = Get-Machines $TargetRig
    $queryMachineScript = "$scriptpath\QueryMachine.ps1"
    foreach($machine in $machines)
    {
        $machineName = $machine.name
        if($machineName -ne 'FAEADG001') #ad box always hangs! weird, have to ignore it :(
        {
            Write-Output "$machineName"
            & $queryMachineScript -TargetMachine $machine.externalIP -Username $Username -Password $Password   
        }       
    }
}
Catch [System.Exception]
{
    $error = $_.Exception.ToString()
    Write-Error "$error"
    exit 1
}
}

main


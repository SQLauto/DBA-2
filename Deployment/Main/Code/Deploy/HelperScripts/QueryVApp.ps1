# Connect to a rig and get the Powershell and .net version deployed
param
(
    [string] $TargetVapp         = $(throw 'TargetVApp'),
    [string] $Username           = "faelab\tfsadmin", 
    [string] $Password           = "LMTF`$Adm1n"
)
function main
{
Try
{
    $scriptpath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)

    Write-Output "Querying .NET and PS version on rig $TargetRig"
    Write-Output ""
    Write-Output "Importing vCloud module... $scriptpath\..\Scripts\vCloud.ps1"
	Write-Output ""
    Import-Module $scriptpath\..\Scripts\vCloud.ps1 -Force
    	    

    $rig = Get-CIVapp -Name $TargetVapp -ErrorAction SilentlyContinue;

    if ($rig -eq $null)
    {
        throw "vApp $TargetVapp does not exist"
    }

    # Iterate through VMs
    $machines = Get-CIVM $rig
    $queryMachineScript = "$scriptpath\QueryMachine.ps1"
    foreach($machine in $machines)
    {
        $machineName = $machine.name
        if($machineName -ne 'FAEADG001') #ad box always hangs! weird, have to ignore it :(
        {
            $externalip = Get-vCloudMachineIPAddress -vApp $rig -MachineName $machineName
            Write-Output "$machineName [$externalip]"
            & $queryMachineScript -TargetMachine $externalip -Username $Username -Password $Password   
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


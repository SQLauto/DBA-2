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
    
    Write-Output "Loading Deployment.Utils"
	[System.Reflection.Assembly]::LoadFrom("..\Tools\DeploymentTool\Deployment.Utils.dll")
	Write-Output ""

	Write-Output "Initialising VCLoud Module for use"
	$vCloudUrl = 'https://vcloud.onelondon.tfl.local'
	$vCloudOrg = 'ce_organisation_td'
	$vCloudUser = 'zSVCCEVcloudBuild'
	$vCloudPassword = 'P0wer5hell'

	Write-Output "Loading VCloudService and Creating connection to $vCloudUrl. Org: $vCloudOrg"
	$vCloudService = New-Object -TypeName Deployment.Utils.VirtualPlatform.VCloud.VCloudService
	$vCloudService.Initialise_vCloudSession($vCloudUrl, $vCloudOrg, $vCloudUser, $vCloudPassword) | Out-Host
	Write-Output ""

    	    
    $rig = $vCloudService.GetVapp($TargetVapp);

    if ($rig -eq $null)
    {
        throw "vApp $TargetVapp does not exist"
    }

    # Iterate through VMs
    $machines = $vCloudService.Get_vCloudMachines($RigName); # Get-CIVM $rig
    $queryMachineScript = "$scriptpath\QueryMachine.ps1"
    foreach($machine in $machines)
    {
        $machineName = $machine.name
        if($machineName -ne 'FAEADG001') #ad box always hangs! weird, have to ignore it :(
        {
            $externalip = $vCloudService.Get_vCloudMachineIPAddress($machineName, $RigName);
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


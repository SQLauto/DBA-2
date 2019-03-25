[cmdletbinding()]
param
(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
	[string]$RigName
)

$exitCode = 0

$modulePath = Join-Path $PSScriptRoot "Modules"

# if module path does not exists
if(-not (($env:PSModulePath -split ";") -contains $modulePath))
{
	Write-Host "Setting module path to $modulePath"
	[Environment]::SetEnvironmentVariable("PSModulePath",  [Environment]::GetEnvironmentVariable("PSModulePath","Machine"))
	$env:PSModulePath = "$modulePath;" + $env:PSModulePath
}

Import-Module TFL.Deployment -Force -ErrorAction Stop


try{

	$RigMachines = Get-AzureRmNetworkInterface -ResourceGroupName $RigName | Select -ExpandProperty IpConfigurations -Property VirtualMachine | `
		Select @{Name = 'IPV4Address'; Expression = {$_.PrivateIpAddress}}, 
                @{Name = 'ComputerName'; Expression = { (Get-AzureRmResource -ResourceId  $_.VirtualMachine.Id).Name }},
                @{Name = 'Drives'; Expression = { @() }} | where {$_.ComputerName -ne 'faeadg001'}

    Write-Host "Generating new RigManifest.xml"
    $buildDefinitionPath = (get-item $PSScriptRoot).Parent.Parent.FullName
	$output = New-Manifestfile -RigMachines $RigMachines -BuildDefinitionPath $buildDefinitionPath -RigName $RigName
	Write-Host $output

}catch {
	Write-Error $_
	$exitCode = 1
}finally{
	Remove-Module TFL.Deployment	
}
exit $exitCode
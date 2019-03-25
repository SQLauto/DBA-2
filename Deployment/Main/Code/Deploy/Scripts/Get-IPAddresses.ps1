# TODO : Can be converted to parameters
Param
(
	[Parameter(Mandatory)]$ResourceGroupName
)

Write-Host "Acquiring Network Interfaces from Azure"
$cas1nic = Get-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName -Name "TS-CAS1_nic"
$cis1nic = Get-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName -Name "TS-CIS1_nic"
$db1nic = Get-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName -Name "TS-DB1_nic"
$db2nic = Get-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName -Name "TS-DB2_nic"

$db1Address = $db1nic.IpConfigurations[0].PrivateIpAddress
Write-Host "TS-DB1: $db1Address"
$db2Address = $db2nic.IpConfigurations[0].PrivateIpAddress
Write-Host "TS-DB2: $db2Address"
$cas1Address = $cas1nic.IpConfigurations[0].PrivateIpAddress
Write-Host "TS-CAS1: $cas1Address"
$cis1Address = $cis1nic.IpConfigurations[0].PrivateIpAddress
Write-Host "TS-CIS1: $cis1Address"

Write-Host "Assign IP Addresses to Release Variables"

Write-Host "##vso[task.setvariable variable=TSDB1Address]$db1Address"
Write-Host "##vso[task.setvariable variable=TSDB2Address]$db2Address"
Write-Host "##vso[task.setvariable variable=TSCAS1Address]$cas1Address"
Write-Host "##vso[task.setvariable variable=TSCIS1Address]$cis1Address"

Write-Host "Script Successfully Completed"
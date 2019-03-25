# TODO : Can be converted to parameters
Param
(
	[Parameter(Mandatory)]$ResourceGroupName,
	[Parameter(Mandatory)]$EnvironmentShortName
)

Write-Host "Acquiring Network Interfaces from Azure"
$cas1nic = Get-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName -Name "TS-CAS1_nic"
$cis1nic = Get-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName -Name "TS-CIS1_nic"
$db1nic = Get-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName -Name "TS-DB1_nic"
$db2nic = Get-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName -Name "TS-DB2_nic"

Write-Host "Applying FTP web services security group"
$ftpwebnsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name "FTPWebServicesSecurityGroup"
$cis1nic.NetworkSecurityGroup = $ftpwebnsg

Write-Host "Applying CASC Database security group"
$cascdbnsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name "FTPCascDatabaseSecurityGroup"
$db1nic.NetworkSecurityGroup = $cascdbnsg

Write-Host "Applying SingleSignOn security group"
$ssonsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name "SingleSignOnSecurityGroup"
$db2nic.NetworkSecurityGroup = $ssonsg

Write-Host "Applying FTP external web services security group"
$ftpextwebnsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name "FTPExternalWebServicesSecurityGroup"
$cas1nic.NetworkSecurityGroup = $ftpextwebnsg

Write-Host "Getting CASC DB Public IP"
$cascdbip = Get-AzureRmPublicIpAddress -ResourceGroupName $ResourceGroupName -Name "FTP-$EnvironmentShortName-CASCDB-PIP"

Write-Host "Applying CASC DB Public IP to DB server"
$db1nic.IpConfigurations[0].PublicIpAddress = $cascdbip

Write-Host "Saving Network Security Changes"
Set-AzureRmNetworkInterface -NetworkInterface $cas1nic
Set-AzureRmNetworkInterface -NetworkInterface $cis1nic
Set-AzureRmNetworkInterface -NetworkInterface $db1nic
Set-AzureRmNetworkInterface -NetworkInterface $db2nic

Write-Host "Network Security updates applied"
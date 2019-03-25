<#
                
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER
        
        $Name : Name of the lab

    .PARAMETER
        
        $Parameters : Parameters used to connect to azure

    .EXAMPLE
        .\Update-NSG.ps1 -Name "SSO_Main_Azure_RTN_06" -Parameters (Import-LocalizedData -FileName "RigData.psd1") -Verbose -NSGName LabRigOutbound

    .NOTES
                
#>

Param(
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)]
    [string]
    $Name,

	[ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)]
    [string]
	$AzureAccountPassword
)

$Name = $Name -replace '\.','_'

Write-Output "$(Get-Date) : --- Update NSG for $Name"    

$Parameters = @{
		Password = $AzureAccountPassword
		User = "489ccbd1-35d5-47cb-a906-40f96237cde0"
		Tenant = "1fbd65bf-5def-4eea-a692-a089c255346b"
		SubscriptionId = "3065ef51-6e69-4ee9-a407-b2cc275f91d6"
		VNetResourceGroup = "Tfltestresourcegroup"
		VnetName = "CE-MOB-TEST-DEV-NE-ARM-VNET"
	}

#region Login to the subscription with your Azure account..."
$secpasswd = ConvertTo-SecureString $Parameters.Password -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ($Parameters.User, $secpasswd)
Login-AzureRmAccount -ServicePrincipal -Tenant $Parameters.Tenant -Credential $mycreds | Out-Null

Select-AzureRmSubscription -SubscriptionId $Parameters.SubscriptionId | Out-Null
#endregion 

Write-Verbose "`t Searching for the Lab $Name."

$vnet = Get-AzureRmVirtualNetwork -Name $Parameters.VNetName -ResourceGroupName $Parameters.VNetResourceGroup
    
$VNSubnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $Name -ErrorAction SilentlyContinue

if($VNSubnet)
{
	foreach($ipConfig in $VNSubnet.IpConfigurations)
	{
		$nic = Get-AzureRmResource -ResourceId $ipConfig.Id -ApiVersion '2017-11-01'
		$nicName = $nic.ResourceName -replace "/$($nic.Name)"
    
		if($nicName -like 'TS-CAS1*')
		{
			$nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName 'ftp-rig' -Name 'SSO_CAS_LabRigInbound'
			$nic = Get-AzureRmNetworkInterface -ResourceGroupName $nic.ResourceGroupName -Name $nicName
			$nic.NetworkSecurityGroup = $nsg
			Set-AzureRmNetworkInterface -NetworkInterface $nic | Out-Null
		}
		else
		{
			$nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName 'ftp-rig' -Name 'LabRig'
			$nic = Get-AzureRmNetworkInterface -ResourceGroupName $nic.ResourceGroupName -Name $nicName
			$nic.NetworkSecurityGroup = $nsg
			Set-AzureRmNetworkInterface -NetworkInterface $nic | Out-Null
		}
	}

	$VNSubnet.NetworkSecurityGroup = $null
    Set-AzureRmVirtualNetwork -VirtualNetwork $vnet | Out-Null
}

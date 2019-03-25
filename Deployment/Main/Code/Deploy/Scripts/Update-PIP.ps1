<#
                
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER
        
        $Name : Name of the Resource Group

    .PARAMETER
        
        $Parameters : Parameters used to connect to azure

    .EXAMPLE
        

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
    $ComputerName,

	[ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)]
    [string]
    $DNSPrefix,

	[ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)]
    [string]
	$AzureAccountPassword,

	[ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)]
    [string]
	$RigTemplateName
)

$Name = $Name -replace '\.','_'

$Parameters = @{
		Password = $AzureAccountPassword
		User = "489ccbd1-35d5-47cb-a906-40f96237cde0"
		Tenant = "1fbd65bf-5def-4eea-a692-a089c255346b"
		SubscriptionId = "3065ef51-6e69-4ee9-a407-b2cc275f91d6" 
	}

Write-Output "$(Get-Date) : --- Updating PIP for $ComputerName"    

#region Login to the subscription with your Azure account..."
$secpasswd = ConvertTo-SecureString $Parameters.Password -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ($Parameters.User, $secpasswd)
Login-AzureRmAccount -ServicePrincipal -Tenant $Parameters.Tenant -Credential $mycreds | Out-Null

Select-AzureRmSubscription -SubscriptionId $Parameters.SubscriptionId | Out-Null
#endregion 

Write-Verbose "`t Searching for the VM $ComputerName in resource group $Name .."

$ResourceGroupName = $Name
$PublicIPName = "$ResourceGroupName-$ComputerName"
$VM = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $ComputerName

 if($VM)
 {
	$publicIp = Get-AzureRmPublicIpAddress -Name $publicIpName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue

    if($publicIp -eq $null)
    {

		$tags = @{
            SvcName = 'FTP'
            SvcOwner = 'ROLE-G-CEBUILD'
            Environment = 'Dev-Test'
		}

		if($DNSPrefix -ne $null)
		{
			$publicIp = New-AzureRmPublicIpAddress -Name $PublicIPName -ResourceGroupName $ResourceGroupName -Location $VM.Location –AllocationMethod "Dynamic" -DomainNameLabel $DNSPrefix -Tag $tags
		}
		else
		{
			$publicIp = New-AzureRmPublicIpAddress -Name $PublicIPName -ResourceGroupName $ResourceGroupName -Location $VM.Location –AllocationMethod "Dynamic" -Tag $tags 
		}
        
    }

	$nicName = "$($VM.Name)_nic"

	$nic = Get-AzureRmNetworkInterface -ResourceGroupName $VM.ResourceGroupName -Name $nicName -ErrorAction SilentlyContinue
    if($nic.IpConfigurations[0].PublicIPAddress -eq $null)
	{
		$nic.IpConfigurations[0].PublicIPAddress = $publicIp
		Set-AzureRmNetworkInterface -NetworkInterface $nic | Out-Null
	}
	
    Write-Output "$(Get-Date) : --- Sucessfully Updated PIP for $ComputerName with $($publicIp.IpAddress)"
}
else
{
	Write-Output "$(Get-Date) : --- VM $ComputerName in resource group $Name not found."
}
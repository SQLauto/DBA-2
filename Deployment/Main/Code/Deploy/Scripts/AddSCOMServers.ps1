[cmdletbinding()]
param
(
	[parameter(Mandatory=$true)]
	[string]
	$RigName,

	[parameter(Mandatory=$true)]
	[string]
	$imagesResourceGroup,

	[parameter(Mandatory=$true)]
	[string]
	$patchName,
	
	[parameter(Mandatory=$true)]
	[string]
	$AzureAccountPassword
)

$RigName = $RigName -replace '\.','_'


$exitCode = 0

$Parameters = @{
	Password = $AzureAccountPassword
	User = "489ccbd1-35d5-47cb-a906-40f96237cde0"
	Tenant = "1fbd65bf-5def-4eea-a692-a089c255346b"
	SubscriptionId = "3065ef51-6e69-4ee9-a407-b2cc275f91d6" 
}

$subscriptionId = $Parameters.SubscriptionId

#region "Login to the subscription with your Azure account..."
$secpasswd = ConvertTo-SecureString $Parameters.Password -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ($Parameters.User, $secpasswd)
Login-AzureRmAccount -ServicePrincipal -Tenant $Parameters.Tenant -Credential $mycreds | Out-Null

Write-Host "Selecting subscription '$($Parameters.SubscriptionId)'";
Select-AzureRmSubscription -SubscriptionId $Parameters.SubscriptionId | Out-Null
#endregion

$resourceGroup = Get-AzureRmResourceGroup -Name $RigName -ErrorAction SilentlyContinue
if($resourceGroup)
{
    $storageAccountName = 'ftptemplatesandconfigs'                    
	$storageResourceGroup = 'ftp-rig'
	$domainServerPassword = 'LMTF$Adm1n'

	$adip = (Get-AzureRmNetworkInterface -ResourceGroupName "$RigName" -Name 'faeadg001_nic').IpConfigurations[0].PrivateIpAddress


	$ctx = New-AzureStorageContext -StorageAccountName $storageAccountName `
				-StorageAccountKey (Get-AzureRMStorageAccountKey -Name $storageAccountName -ResourceGroupName $storageResourceGroup)[0].Value

	$tokendsc = New-AzureStorageContainerSASToken -Name "windows-powershell-dsc" -Permission rl -Context $ctx -ExpiryTime (Get-Date).AddHours(4)
   
	$dcparameters = @{
		SCOMVMName = 'TS-SCOM1'
		SCOMDBVMName = 'TS-SCOMDB1'
		SCOMImageId = "/subscriptions/$subscriptionId/resourceGroups/$imagesResourceGroup/providers/Microsoft.Compute/images/Full_SCOM_$patchName"
		subnetName = "$RigName"
		SasTokendsc = $tokendsc.ToString()
		adminPassword = "$domainServerPassword"
        adip = $adip
	}

	New-AzureRmResourceGroupDeployment -Name "scom_template" -ResourceGroupName $RigName `
				-TemplateUri "https://ftptemplatesandconfigs.blob.core.windows.net/armtemplates/scom_template_deploy.json" `
				-TemplateParameterObject $dcparameters -Verbose
}
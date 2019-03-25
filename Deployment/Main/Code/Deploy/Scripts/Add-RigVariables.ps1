# TODO : Can be converted to parameters
$storageAccountName = 'ftptemplatesandconfigs'
$storageResourceGroup = 'ftp-rig'
$workspaceName = 'defaultworkspace-3065ef51-6e69-4ee9-a407-b2cc275f91d6-weu'
$keyVaultName = 'tdbuildkv'

Write-Host "Storage Account: $storageAccountName"
Write-Host "Storage Account Resource Group: $storageResourceGroup"
Write-Host "Workspace: $workspacename"
Write-Host "Key Vault: $keyVaultName"

Write-Host "Creating new Azure Storage Context..." -NoNewline
$ctx = New-AzureStorageContext -StorageAccountName $storageAccountName `
		-StorageAccountKey (Get-AzureRMStorageAccountKey -Name $storageAccountName -ResourceGroupName $storageResourceGroup)[0].Value
Write-Host "Done"

Write-Host "Creating SAS Token to access ARM Templates..." -NoNewline
$tokenarmtemplates = New-AzureStorageContainerSASToken -Name "armtemplates" -Permission rl -Context $ctx -ExpiryTime (Get-Date).AddHours(1)
Write-Host "Done"

Write-Host "Creating SAS Token to access custom scripts..." -NoNewline
$tokencustomscripts = New-AzureStorageContainerSASToken -Name "customscripts" -Permission rl -Context $ctx -ExpiryTime (Get-Date).AddHours(1)
Write-Host "Done"

Write-Host "Creating SAS Token to access Windows PowerShell DSC..." -NoNewline
$tokendsc = New-AzureStorageContainerSASToken -Name "windows-powershell-dsc" -Permission rl -Context $ctx -ExpiryTime (Get-Date).AddHours(2)
Write-Host "Done"


#Write-Host "Getting workspace $workspaceName..." -NoNewline
#$workspace = Get-AzureRmOperationalInsightsWorkspace | where {$_.Name -eq $workspaceName}
#Write-Host "Done"

#Write-Host "Getting workspace Primary key..." -NoNewline
#$workspaceKey = ($workspace | Get-AzureRmOperationalInsightsWorkspaceSharedKeys).PrimarySharedKey
#Write-Host "Done"

#Write-Host "Getting workspace ID..." -NoNewline
#$workspaceid = $workspace.CustomerId.Guid
#Write-Host "Done"

#Write-Host "Getting Certificate from KeyVault..." -NoNewline
#$vaultCert = Get-AzureKeyVaultCertificate -VaultName $keyVaultName -Name 'starcetflgovuk'
#Write-Host "Done"

#Write-Host "Getting KeyVault..." -NoNewline
#$vault = Get-AzureRmKeyVault -ResourceGroupName 'ftp-rig' -VaultName $keyVaultName
#Write-Host "Done"

Write-Host "Applying Variables to the Release..." -NoNewline
Write-Host "##vso[task.setvariable variable=armtemplatetoken;issecret=true]$tokenarmtemplates"
Write-Host "##vso[task.setvariable variable=customscriptstoken;issecret=true]$tokencustomscripts"
Write-Host "##vso[task.setvariable variable=dscconfigtoken;issecret=true]$tokendsc"
#Write-Host "##vso[task.setvariable variable=workspaceKey;issecret=true]$workspaceKey" -NoNewline
#Write-Host "##vso[task.setvariable variable=workspaceid]$workspaceid" -NoNewline
#Write-Host "##vso[task.setvariable variable=vaultResourceId]$($vault.ResourceId)" -NoNewline
#Write-Host "##vso[task.setvariable variable=secretUrlWithVersion]$($vaultCert.SecretId)" -NoNewline
Write-Host "Done"

Write-Host "Script Complete"
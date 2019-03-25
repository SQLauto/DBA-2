Param(
    [string] $ResourceGroupLocation = 'northeurope',
    [string] [Parameter(Mandatory = $true)] $ResourceGroupName,
    [string] [Parameter(Mandatory = $true)] $Tag,
	[string] $ResourceGroupContributors,
	[bool] $ForceRefresh = $true
)

function Create-ResourceGroup
{
	Write-Host "Creating resource group $ResourceGroupName in location $ResourceGroupLocation"
    $tags = @{
        ResourceType = 'Rig'
        RigTemplate  = $Tag
        SvcName      = 'FTP'
        SvcOwner     = 'TDBuild@tfl.gov.uk'
        Environment  = 'Development'
        CrgCostCode  = 'RCE02.CT.AZURE'
    }

	Write-Host "Creating resource group $ResourceGroupName"
    $result = New-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Verbose -Force -Tags $tags
    if ($result.ProvisioningState -eq 'Succeeded') {
        Write-Host "Created resource group $ResourceGroupName"
    }
}

function Set-ADGroupPermissions
{
	Param(
		[string] $ADGroupName,
		[string] $ResourceGroupName
	)
    
    $ADGroup = Get-AzureRmADGroup -SearchString "$ADGroupName" -ErrorAction SilentlyContinue
						
	if(!$ADGroup) {
	    Write-Warning "Could not find AD Group $ADGroupName. Permissions not assigned"
		break
    }
    
    New-AzureRmRoleAssignment -ObjectId $ADGroup.Id -RoleDefinitionName Contributor -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
}

function Set-ResourceGroupPermissions
{
	Write-Host "Setting Permissions for Resource Group $ResourceGroupName"

    if(![string]::IsNullOrEmpty($ResourceGroupContributors)) {

        $UsersToAssign = @()
	    $ResourceGroupContributors.Split(',') | % { $UsersToAssign += $_ }

        $UsersToAssign | % {
	        Write-Host "Providing Access to $_"
	        Set-ADGroupPermissions -ADGroupName "$_" -ResourceGroupName "$ResourceGroupName"			
        }
    }

    Write-Host "Providing access to FUNC-X-CLOUD-TSO-NH-Wintel-Team"
	Set-ADGroupPermissions -ADGroupName 'FUNC-X-CLOUD-TSO-NH-Wintel-Team' -ResourceGroupName "$ResourceGroupName"
}

$ResourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
$Tag = "$($Tag)_Template"

if (!$ResourceGroup) 
{
    Create-ResourceGroup
	Set-ResourceGroupPermissions
	exit 0
}
else 
{
	Write-Host "ForceRefresh : $ForceRefresh"
	if($ForceRefresh)
	{
		Write-Host "Deleting resource group"
		$ResourceGroup | Remove-AzureRmResourceGroup -Force | Out-Null

		Create-ResourceGroup
		Set-ResourceGroupPermissions
	}
	else
	{
		$tags = ($ResourceGroup).Tags
		$templateTag = $tags['RigTemplate']
		Write-Host "Validating tag $templateTag"
		
		if($templateTag -eq $Tag)
		{
			Write-Host "Using existing resource group $ResourceGroupName"
		}
		else
		{
			throw "Template tag $Tag did not match."
		}
		
		Set-ResourceGroupPermissions
	}
}
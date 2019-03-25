param
(
    [string] $MachineName,
	[System.Guid] $upgradeCode = "00000000-0000-0000-0000-000000000000",
	[System.Guid] $productCode = "00000000-0000-0000-0000-000000000000",
	[System.Version] $productVersion = "0.0.0.0",
	[bool] $isInstalledVerification = $true,
	[string] $DeploymentDrive = "D"
)

$exitCode = 0 
$lastexitcode = 0
$scriptpath = split-path $MyInvocation.MyCommand.Path;
Set-Location -Path $scriptpath;
Try
{
	if (([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {$_ -match "Deployment.Installation"}) -eq $null) 
	{
	    $deploymentInstallationDll = [System.IO.Path]::Combine($scriptpath, "Deployment.Installation.dll")
        [System.Reflection.Assembly]::LoadFrom($deploymentInstallationDll)
    }
}
catch [System.Exception]
{
	$msg = "ERROR: Unable to load dll: [" + $deploymentInstallationDll + "] on [" + $MachineName + "] error encountered: " + $_.Exception.ToString()
	Write-Output $msg
	$lastexitcode = 1
}
				 
$properties = @{'UpgradeCode'=$upgradeCode;
				 'ProductCode'=$productCode;
				 'ProductVersion'=$productVersion}
[Deployment.Installation.MsiKey] $msiKey = New-Object -TypeName "Deployment.Installation.MsiKey" -Prop $properties


$localhost = $env:COMPUTERNAME;    
$local = $false
if($MachineName.ToLower() -eq $localhost.ToLower())
{
	$local = $true	
	
	Try
	{
		if ($isInstalledVerification)
		{
			[bool] $expectedMsiHasBeenDeployed = [Deployment.Installation.InstallationHelper]::InstalledProductIsExpectedMsi($msiKey)    
			if ($expectedMsiHasBeenDeployed -eq $False)	
			{
				$lastexitcode = 1
			}
		}
		else
		{
			[bool] $msiIsInstalled= $false
			[bool] $allValuesAreSpecified = $msiKey.HasUpgradeCode -and $msiKey.HasProductCode -and $msiKey.HasVersion
			[bool] $productCodeOnlyIsSpecified = $msiKey.HasProductCode -and $msiKey.HasUpgradeCode -eq $false -and $msiKey.HasVersion -eq $false
			[bool] $upgradeOnlyIsSpecified = $msiKey.HasUpgradeCode -and $msiKey.HasProductCode -eq $false -and $msiKey.HasVersion -eq $false
			[bool] $upgradeAndVersionOnlyAreSpecified = $msiKey.HasProductCode -eq $false -and $msiKey.HasUpgradeCode -eq $true -and $msiKey.HasVersion -eq $true
			[bool] $productAndUpgradeAreSpecified = $msiKey.HasProductCode -eq $true -and $msiKey.HasUpgradeCode -eq $true -and $msiKey.HasVersion -eq $false
			
			if ($allValuesAreSpecified)
			{
				$msiIsInstalled = [Deployment.Installation.InstallationHelper]::InstalledProductIsExpectedMsi($msiKey)    
			}
			
			if ($upgradeOnlyIsSpecified -or $productAndUpgradeAreSpecified)
			{
				$msiIsInstalled =[Deployment.Installation.InstallationHelper]::InstalledProductExistsWithUpgradeCode($msiKey.UpgradeCode)
			}
			
			if ($productCodeOnlyIsSpecified -or($productAndUpgradeAreSpecified -and $msiIsInstalled -eq $false))
			{
				$msiIsInstalled =[Deployment.Installation.InstallationHelper]::InstalledProductExistsWithProductCode($msiKey.UpgradeCode)
			}
			
			#this represents a specific minor patch
			if ($upgradeAndVersionOnlyAreSpecified)
			{
				$msiIsInstalled =[Deployment.Installation.InstallationHelper]::InstalledProductExistsWithUpgradeCodeAndVersion($msiKey.UpgradeCode, $msiKey.ProductVersion)
			}
			
			if ($msiIsInstalled)	
			{
				$lastexitcode = 1
			}
		}
	}
	catch [System.Exception]
	{
		$msg = "ERROR: Unable to verify that the msi is deployed locally error encountered: " + $_.Exception.ToString()
		Write-Output $msg
		$lastexitcode = 1
	}
	
	$exitCode = $lastexitcode
}
else
{
    $remotesession = new-pssession -computername $MachineName 
	#Only copy if not exists as the deployment should have placed these files there.
    if (!(Test-Path \\$MachineName\($DeploymentDrive)`$\Deployment\Scripts))
    {
		Try
		{
			Write-Output "Copying $scriptpath to \\$MachineName\($DeploymentDrive)`$\Deployment\"
			Write-Output "Folder Exists about to remove it for idempotent process: \\$MachineName\($DeploymentDrive)`$\Deployment\Scripts"
			Remove-Item \\$MachineName\($DeploymentDrive)`$\Deployment\Scripts -Recurse -Force -errorAction SilentlyContinue 
			Write-Output "Successfully deleted: \\$MachineName\($DeploymentDrive)`$\Deployment\Scripts"
			New-Item \\$MachineName\($DeploymentDrive)`$\Deployment\Scripts -ItemType Directory -Force
			Copy-Item ("$scriptpath\*") "\\$MachineName\($DeploymentDrive)`$\Deployment\Scripts\" -Recurse -Force -ErrorAction stop
		}
		catch [System.Exception]
        {
            $msg = "ERROR: occurred when trying to copy code to remote machine to verify specific msi, error encountered: " + $_.Exception.ToString()
            Write-Output $msg
		    $lastexitcode = 1
        }
	}
	
    Invoke-Command -Session $remotesession -ScriptBlock {
		param($msiKey, $isInstalledVerification)
        Try
        {
			$deploymentInstallationDllRemote =  "D:\Deployment\Scripts\Deployment.Installation.dll"
			
			if (!(Test-Path $deploymentInstallationDllRemote))
			{
				Write-Output "Unable to find dll required to verify msi: $deploymentInstallationDllRemote"
				$lastexitcode = 1
			}
			else
			{
				if (([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {$_ -match "Deployment.Installation"}) -eq $null) 
				{
					$capture =[System.Reflection.Assembly]::LoadFrom($deploymentInstallationDllRemote)
				}
				
				$properties = @{'UpgradeCode'=$msiKey.UpgradeCode;
				 'ProductCode'=$msiKey.ProductCode;
				 'ProductVersion'=$msiKey.ProductVersion}
				[Deployment.Installation.MsiKey] $msiKeyLocal = New-Object -TypeName "Deployment.Installation.MsiKey" -Prop $properties
				[bool] $expectedMsiHasBeenDeployed = [Deployment.Installation.InstallationHelper]::InstalledProductIsExpectedMsi($msiKeyLocal)  
							
				if ($isInstalledVerification)
				{
					[bool] $expectedMsiHasBeenDeployed = [Deployment.Installation.InstallationHelper]::InstalledProductIsExpectedMsi($msiKeyLocal)    
					if ($expectedMsiHasBeenDeployed -eq $False)	
					{
						$lastexitcode = 1
					}
				}
				else
				{
					[bool] $msiIsInstalled= $false
					[bool] $allValuesAreSpecified = $msiKeyLocal.HasUpgradeCode -and $msiKeyLocal.HasProductCode -and $msiKeyLocal.HasVersion
					[bool] $productCodeOnlyIsSpecified = $msiKeyLocal.HasProductCode -and $msiKeyLocal.HasUpgradeCode -eq $false -and $msiKeyLocal.HasVersion -eq $false
					[bool] $upgradeOnlyIsSpecified = $msiKeyLocal.HasUpgradeCode -and $msiKeyLocal.HasProductCode -eq $false -and $msiKeyLocal.HasVersion -eq $false
					[bool] $upgradeAndVersionOnlyAreSpecified = $msiKeyLocal.HasProductCode -eq $false -and $msiKeyLocal.HasUpgradeCode -eq $true -and $msiKeyLocal.HasVersion -eq $true
					[bool] $productAndUpgradeAreSpecified = $msiKeyLocal.HasProductCode -eq $true -and $msiKeyLocal.HasUpgradeCode -eq $true -and $msiKeyLocal.HasVersion -eq $false
					
					if ($allValuesAreSpecified)
					{
						$msiIsInstalled = [Deployment.Installation.InstallationHelper]::InstalledProductIsExpectedMsi($msiKeyLocal)    
					}
					
					if ($upgradeOnlyIsSpecified -or $productAndUpgradeAreSpecified)
					{
						$msiIsInstalled =[Deployment.Installation.InstallationHelper]::InstalledProductExistsWithUpgradeCode($msiKeyLocal.UpgradeCode)
					}
					
					if ($productCodeOnlyIsSpecified -or($productAndUpgradeAreSpecified -and $msiIsInstalled -eq $false))
					{
						$msiIsInstalled =[Deployment.Installation.InstallationHelper]::InstalledProductExistsWithProductCode($msiKeyLocal.UpgradeCode)
					}
					
					#this represents a specific minor patch
					if ($upgradeAndVersionOnlyAreSpecified)
					{
						$msiIsInstalled =[Deployment.Installation.InstallationHelper]::InstalledProductExistsWithUpgradeCodeAndVersion($msiKeyLocal.UpgradeCode, $msiKeyLocal.ProductVersion)
					}
					
					if ($msiIsInstalled)	
					{
						$lastexitcode = 1
					}
				}
			}
		}
	    catch [System.Exception]
        {
            $msg = "ERROR: occurred when trying to verify specific msi, error encountered: " + $_.Exception.ToString()
            Write-Output $msg
		    $lastexitcode = 1
        }
    } -ArgumentList $msiKey, $isInstalledVerification
	$exitCode = invoke-command -ScriptBlock { $lastexitcode } -Session $remotesession	
}


exit $exitCode

           

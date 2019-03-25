
$scriptpath = split-path $MyInvocation.MyCommand.Path;
Set-Location -Path $scriptpath;

$deploymentInstallationDllRemote = Join-Path $scriptpath, "Deployment.Installation.dll"
Try
{
    if (([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {$_ -match "Deployment.Installation"}) -eq $null) 
	{
	    $capture =[System.Reflection.Assembly]::LoadFrom($deploymentInstallationDllRemote)
	}  
}
catch [System.Exception]
{
    $msg = "ERROR: Unable to load dll: [" + $deploymentInstallationDllRemote + "] on [" + $MachineName + "] error encountered: " + $_.Exception.ToString()
    Write-Output $msg
	$lastexitcode = 1
}

$installedProducts = @([Deployment.Installation.InstallationHelper]::GetAllInstalledProducts())

if ($installedProducts.Length -eq 0)
{
    $msg = "There are not products installed!!!"
	Write-Output $msg
}
else
{
    Write-Output "The following 'Transport for London' Products are installed on $env:COMPUTERNAME:"

   # $installedProducts | Sort-Object Publisher, ProductName | fl ProductName, UpgradeCode, ProductCode, ProductVersion, InstallDate, LocalPackage -GroupBy Publisher
   $productsToRemove = $installedProducts | Where { $_.Publisher -Match "Transport for London"}
   foreach ($productToRemove in $productsToRemove)
   {
    Try
    {
        $msg = "About to remove product: "
        Write-Output $msg
        $productToRemove | fl ProductName, UpgradeCode, ProductCode, ProductVersion, InstallDate, LocalPackage
        Write-Output ""

        $unInstallLog = $scriptpath + $productToRemove.ProductName + "_" +  $productToRemove.ProductCode + ".log"

        $productGuid = $productToRemove.ProductCode
        Write-Output "cmd /c msiexec /x $productGuid /quiet /l*v $unInstallLog";
        cmd /c msiexec /x $productGuid /quiet /log $unInstallLog 
        Write-Output "exit code from uninstall: $lastexitcode"

        if ($lastexitcode -ne 0)
        {
            $exitCode = 1
        }
    }
    catch [System.Exception]
    {
        $msg = "ERROR: Unable to remove product: [" + $productToRemove.ProductName + "] on [" + $MachineName + "] error encountered: " + $_.Exception.ToString() + " the full product details will be output after this message"
        Write-Output $msg
        $productToRemove | fl ProductName, UpgradeCode, ProductCode, ProductVersion, InstallDate, LocalPackage
	    $lastexitcode = 1 
    }
    
    Start-Sleep -s 5 #MsiExec doesn't always release the lock fast enough which can cause the subsequent uninstall to fail         
   }
}
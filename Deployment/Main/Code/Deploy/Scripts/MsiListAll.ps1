
$scriptpath = split-path $MyInvocation.MyCommand.Path;
Set-Location -Path $scriptpath;

$deploymentInstallationDllRemote = [System.IO.Path]::Combine($scriptpath, "Deployment.Installation.dll")
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
    Write-Output "The following Products are installed on $env:COMPUTERNAME:"

    $installedProducts | Sort-Object Publisher, ProductName | fl ProductName, UpgradeCode, ProductCode, ProductVersion, InstallDate, LocalPackage -GroupBy Publisher
}
param (
	[string]$zeroDeploymentPath = $env:ZeroDeployPath,
	[string]$jobsFolder = $PSScriptRoot,
    [string]$paramsFile
) 

Invoke-Expression ". $paramsFile"

Write-Host "Autogration Zero Deployment target path is $zeroDeploymentPath"
$currentLocation = Get-Location
Write-Host "CurrentLocation is $currentLocation"
Write-Host "PSScriptRoot is $PSScriptRoot"
set-location $jobsFolder
$currentLocation = Get-Location
Write-Host "CurrentLocation is $currentLocation"

function TryGetCIBuild($cmd)
{
	Write-Host "Trying : $cmd"
	Invoke-Expression $cmd
	
	if($lastexitcode -ne 0)
	{
		throw "The command: $cmd failed with exit code $lastexitcode"
	}
	
	#$p = Start-Process -FilePath <path> -ArgumentList <args> -Wait -NoNewWindow -PassThru
	#$p.ExitCode
}

foreach($component in $componentCiBuilds.GetEnumerator()) {
    $componentName = $component.Name
	$ciBuild = $componentCiBuilds[$componentName]
	$ciBuildPath = "$zeroDeploymentPath\$componentName"
		
	$command = ".\GetLatestCiBuild.exe ""http://tfs:8080/tfs/ftpdev"" ""$componentName"" ""$ciBuild"" ""$ciBuildPath"""

    TryGetCIBuild($command)
}
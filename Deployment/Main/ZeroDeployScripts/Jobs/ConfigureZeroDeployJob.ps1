param (
	[string]$zeroDeployScripts,
    [string]$zeroDeployPath
) 

Write-Host "Beginning ConfigureZeroDeploy job"
 
Set-Location $zeroDeployScripts

.\ConfigureZeroDeployForCI.ps1 -zeroDeploymentPath $zeroDeployPath




param (
	[string]$zeroDeployScripts
) 

Write-Host "Beginning DeployAutogrationDB job"
 
Set-Location $zeroDeployScripts



& {. .\AutomatedTests.ps1; Build }

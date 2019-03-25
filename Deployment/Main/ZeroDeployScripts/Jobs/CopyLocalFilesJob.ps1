param (
	[string]$zeroDeployScripts
) 

Write-Host "Beginning DeployAutogrationDB job"
 
Set-Location $zeroDeployScripts



.\LocalRigSetup.cmd


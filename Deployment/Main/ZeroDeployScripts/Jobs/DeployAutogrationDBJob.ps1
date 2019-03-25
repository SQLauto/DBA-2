param (
	[string]$zeroDeployScripts,
	[string]$autogrationPath,
	[string]$workSpacePath
) 

Write-Host "Beginning DeployAutogrationDB job"
 
Set-Location $zeroDeployScripts

.\Deploy-Local-Databases.ps1 -autogrationPath $autogrationPath -workSpacePath $workSpacePath

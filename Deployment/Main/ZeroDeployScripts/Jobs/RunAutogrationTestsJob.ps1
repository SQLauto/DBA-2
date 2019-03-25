param (
	[string]$zeroDeployScripts
) 

Write-Host "Beginning RunAutogrationTests job"
 


$IntegrationFolder = resolve-path "$zeroDeployScripts\..\..\..\integration\main\code\"
Set-Location $IntegrationFolder

Write-Host "Creating new TestResultsCMD folder in $TestLocation"

mkdir TestResultsCMD -Force

Set-Location $zeroDeployScripts

& {. .\AutomatedTests.ps1; RunTests }

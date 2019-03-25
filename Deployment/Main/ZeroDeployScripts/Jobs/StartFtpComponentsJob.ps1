param (
	[string]$zeroDeployScripts
) 

set-location $zeroDeployScripts

.\StartAppFabricCache.ps1

.\_RunZdFromCI.ps1


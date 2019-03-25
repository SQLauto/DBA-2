REM Start AppFabric Cache (assumes FAEIntraday cache has already been created)
Powershell.exe -executionpolicy Unrestricted -File .\StartAppFabricCache.ps1

Powershell.exe -executionpolicy Unrestricted -File .\_RunZdFromCI.ps1










Powershell.exe -executionpolicy Unrestricted -File .\Invoke-BuildFtp.ps1 -components FAE
pause
ECHO Installing FAE Performance counter...
..\..\..\FAE\Main\Code\EngineControllerHost\bin\Release\EngineControllerHost.exe install
pause
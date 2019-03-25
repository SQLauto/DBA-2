param 
(
    [string]$ServerToCheck = "ftdc2pai002", # $(throw '')
	[string]$DriveLetter = "D"
)

[string]$logLine = Get-Content \\$ServerToCheck\$DriveLetter$\Deployment\NDP452-KB2901907-x86-x64-AllOS-ENU.exe_log-MSI_netfx_Full_GDR_x64.msi.txt | Where-Object {$_ -like '*Product: Microsoft .NET Framework 4.5.2*completed successfully*'; }

if (($logLine -ne $null) -and ($logLine -ne ""))
{
    if ($logLine -like '*Install*') { $mode = "Installed"; }
    if ($logLine -like '*Config*') {  $mode = "Configured"; }

    Write-Host ".Net 4.5.2 on $ServerToCheck successful: " $mode
}
else
{
    Write-Host "FAIL on '$ServerToCheck'"; 
}
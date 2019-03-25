param
(
    [string] $MachineName
)

$exitCode = 0 
$scriptpath = split-path $MyInvocation.MyCommand.Path;
Set-Location -Path $scriptpath;

Import-Module .\PendingReboot.ps1 -Force -ErrorAction SilentlyContinue

Get-PendingReboot -ComputerName $MachineName
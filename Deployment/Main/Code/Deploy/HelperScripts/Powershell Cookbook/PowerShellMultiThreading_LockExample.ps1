
# This script spins up 50 back ground processes that all try to update $summaryFile
# Without locking, many threads will fail due to contention over $summaryFile and $summaryFile will not be updated with 50 entries
# With locking, there should be no failures and $summaryFile will contain all 50 entries (in no particular order)

cls
$summaryFile = "d:\parallel\summary.txt"
$workspaceScriptsFolder = "D:\src\Parallel\Deployment\main\Code\Deploy\Scripts"

# Create session state, load in the locking script and create a shared variable $summaryFile
$sessionstate = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault() 
$sessionstate.ImportPSModule("$workspaceScriptsFolder\TFL.LockObject.ps1") 
$sessionstate.Variables.Add( 
    (New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry('summaryFile', $summaryFile, $null)) 
) 

$runspacepool = [runspacefactory]::CreateRunspacePool(1, 50, $sessionstate, $Host) 
$runspacepool.Open() 
 

$ScriptBlockNoLocking = {
   Param (
   [int]$RunNumber = 0
   )
    try
    {    
        Add-Content $summaryFile $RunNumber -ErrorAction  stop

    }
    Catch [System.Exception]
    {
	    Write-Host  $_.Exception.ToString()
    }
}

$ScriptBlockLocking = {
   Param (
   [int]$RunNumber = 0
   )
    try
    {    
        lock ($summaryFile) {
            Add-Content $summaryFile $RunNumber -ErrorAction  stop
        }
    }
    Catch [System.Exception]
    {
        Write-Host  $_.Exception.ToString()
    }
}

Write-Host "Try to update $summaryFile with no locking - we are gonna see a lot of exceptions"

Set-Content $summaryFile "" #  create an empty file
$Jobs = @() 
1..50 | % {
   $Job = [powershell]::Create().AddScript($ScriptBlockNoLocking).AddArgument($_)
   $Job.RunspacePool = $runspacepool
   $Jobs += New-Object PSObject -Property @{
      RunNum = $_
      Pipe = $Job
      Result = $Job.BeginInvoke()
   }
}
 
Write-Host "Waiting.." -NoNewline
Do {
   Write-Host "." -NoNewline
   Start-Sleep -Seconds 1
} While ( $Jobs.Result.IsCompleted -contains $false)

Write-Host "Update complete: $summaryFile is"
Get-Content $summaryFile

Write-Host "Try to update $summaryFile with locking - should work correctly and $summaryFile should be updated with all 50 entries"

Set-Content $summaryFile "" #  create an empty file
$Jobs = @() 
1..50 | % {
   $Job = [powershell]::Create().AddScript($ScriptBlockLocking).AddArgument($_)
   $Job.RunspacePool = $runspacepool
   $Jobs += New-Object PSObject -Property @{
      RunNum = $_
      Pipe = $Job
      Result = $Job.BeginInvoke()
   }
}
 
Write-Host "Waiting.." -NoNewline
Do {
   Write-Host "." -NoNewline
   Start-Sleep -Seconds 1
} While ( $Jobs.Result.IsCompleted -contains $false)

Write-Host "Update complete: $summaryFile is"
Get-Content $summaryFile



 
 


 

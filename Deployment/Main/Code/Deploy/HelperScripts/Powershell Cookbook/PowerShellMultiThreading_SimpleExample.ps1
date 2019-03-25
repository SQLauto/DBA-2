# Write out 10 text files in parallel to $folderLocation
# The example uses a variable in session state (myString) that is shared across all threads

cls
$numThreads = 5 
$folderLocation = "d:/parallel"

# Create session state
[string] $myString = "this is session state!";
$sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$sessionstate.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList "myString" ,$myString, "test string"))
   
# Create runspace poll consisting of $nuThreads runspaces
$RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, $numThreads, $sessionState, $Host)
$RunspacePool.Open()

$ScriptBlock = {
   Param (
      [string]$fileName,
      [string]$fileContents
   )
   Set-Content $fileName $fileContents
   Add-Content $fileName $myString
}

$Jobs = @()
 
1..10 | % {
    $fileName = "test$_.txt"
    $fileName = [System.IO.Path]::Combine($folderLocation, $fileName)
    $Job = [powershell]::Create().AddScript($ScriptBlock).AddParameter("fileName", $fileName).AddParameter("fileContents", $_)
    $Job.RunspacePool = $RunspacePool
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
} While ( $Jobs.Result.IsCompleted -contains $false) #Jobs.Result is a colection
Write-Host "All jobs completed!"
 

 




# In this example we will spin up 20 background threads that each do the simple job of concatenating two strings
# Each background thread returns a custom object containing the original strings and the concateneated result
# These objects are then piped into the host by calling EndInvoke

cls
$numThreads = 5 


$ScriptBlock = {
   Param (
      [string]$string1,
      [string]$string2
   )

    $concatenatedString = "$string1$string2"
   

   return New-Object PSObject -Property @{
     String1 = $string1
     String2 = $string2
     ConcatenatedResult = $concatenatedString
     }
}

$RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, $numThreads)
$RunspacePool.Open()

$Jobs = @()
 
1..20 | % {
    $fileName = "test$_.txt"
    $fileName = [System.IO.Path]::Combine($folderLocation, $fileName)
    $Job = [powershell]::Create().AddScript($ScriptBlock).AddParameter("string1", "value").AddParameter("string2", $_)
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
} While ( $Jobs.Result.IsCompleted -contains $false)
Write-Host "All jobs completed!"
 
#EndInvoke returns the objects from the background threads
$Results = @()
ForEach ($Job in $Jobs)
{   
    $Job.Pipe.EndInvoke($Job.Result)
}
 




# This example will demonstrate that objects can be shared across threads via session state. 
# We create an synchorinized array
# We spin up two threads, the first adds values to an array
# The second, waits some time then outputs the array
# The fact that the second thread shows the values we added in the first demonsrtates that the array is shared across threads

# Question: Is the use of a Synchronized array enough to ensure thread safety of should we also inists of using locking

cls

# create an array and add it to session state
$arrayList = New-Object System.Collections.ArrayList 
$arrayList.AddRange(('a','b','c','d','e')) 
$arrayList = [System.Collections.ArrayList]::Synchronized($arrayList);
 
$sessionstate = [system.management.automation.runspaces.initialsessionstate]::CreateDefault() 
$sessionstate.Variables.Add( 
    (New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry('arrayList', $arrayList, $null)) 
) 
 
$runspacepool = [runspacefactory]::CreateRunspacePool(1, 2, $sessionstate, $Host) 
$runspacepool.Open() 
 
$ps1 = [powershell]::Create() 
$ps1.RunspacePool = $runspacepool 
 
$ps1.AddScript({ 
    for ($i = 1; $i -le 5; $i++) 
    { 
        $null = $arrayList.Add($i) 
    }
}) > $null

# this adds values to  $arrayList on a background thread
$handle1 = $ps1.BeginInvoke() 
 
$ps2 = [powershell]::Create() 
$ps2.RunspacePool = $runspacepool 
 
$ps2.AddScript({
    start-sleep -s 5
    Write-Host " ArrayList contents is "
     foreach ($i in $arrayList) 
     { 
          $i 
    } 
}) > $null

# this outputs the results of $arrayList after a pause of 3 seconds. It should output the values that wehere added on the above background thread
$handle2 = $ps2.BeginInvoke() 
 
if ($handle1.AsyncWaitHandle.WaitOne() -and 
    $handle2.AsyncWaitHandle.WaitOne()) 
{ 
    $ps1.EndInvoke($handle1) 
    $ps2.EndInvoke($handle2) 
} 


 




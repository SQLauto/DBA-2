param
(
    
    [string] $vAppTemplateName = $(throw 'vAppTemplateName parameter is required'), 
    [string] $vAppName = $(throw '$vAppName parameter is required')   
)
function main
{
    $startTime = Get-Date
    
    Write-Output ""
    Write-Output "### Starting Deploy-vCloudvApp on $vAppName using template $vAppTemplateName (at $startTime)  ###"
    Write-Output ""
        
    $scriptpath = split-path $myinvocation.scriptname;
    
	Write-Output "Loading TFL.DBLogging.ps1..."
	Write-Output ""
	Import-Module $scriptpath\..\Scripts\TFL.DBLogging.ps1 -Force
        
    Initialise_vCloudEventLog -vAppName $vAppName -vAppTemplateName $vAppTemplateName -InitialisationSource ($myinvocation.scriptname)
            
    Write-Output "Importing VCloud module..."
    Write-Output ""
    Import-Module $scriptpath\..\Scripts\VCloud.ps1 -Force

	try
    {
        $rig = Get-CIVApp -Name $RigName -ErrorAction SilentlyContinue;
	    if ($rig -ne $null)
		{
			Write-Output "vApp $vAppName already exists, exiting with code 12"
			$exitcode = 12
			exit 12
		}

		Write-Output "Creating vApp $vAppName from template $vAppTemplateName"
		New-vAppFromTemplate -vAppName $vAppName -VAppTemplateName $vAppTemplateName;
    
		Write-Output ""
		Write-Output "Verifying vApp..."
		$result = Verify-vApp -vAppName $vAppName;
    	Write-Output "Verified vApp..."
	
		$date = Get-Date
		Write-Output "Deploy-vCloudvApp completed (at $date)"
    
		if($result -eq $true)
		{
			Write-Output "vApp $vAppName is ready for use, all machines deployed correctly, script exiting with code 10"
			$exitcode = 0
			exit 0
		}
		else
		{
			Write-Output "vApp $vAppName is not ready for use, not all machines deployed correctly, exiting with code 11"
			$exitcode = 11
			exit 11
		}
    }
    Catch [System.Exception]
    {
    	Write-Output  "Exception: " + ($_.Exception.ToString()) + ". Exiting with exit code 13"
    	$exitCode = 13
	    exit 13
    }
	$endTime = Get-Date 
	
	$totalMinutes = "{0:N4}" -f ($endTime-$startTime).TotalMinutes
	 Write-Output ""
    Write-Output "### Finished Deploy-vCloudvApp on $vAppName using template $vAppTemplateName (at $endTime) in $totalMinutes minutes ###"
    Write-Output ""
}

main
	
	

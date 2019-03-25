[cmdletbinding()]
param
(
    [parameter(Mandatory=$true)][string] $ComputerName,
    [Deployment.Domain.Roles.EventLogDeploy]$DeployRole

)

function Uninstall-EventLog{
[cmdletbinding()]
param([string]$EventLogAction)

	$retVal = 0

	if($EventLogAction -eq "Install"){
		return $retVal
	}

	$logName = $DeployRole.EventLogName

	try{
		Write-Host "Selected Deployment Action is: $EventLogAction"

		if(Assert-EventLog -LogName $logName -ComputerName $ComputerName){
			Remove-EventLog -LogName $logName -ComputerName $ComputerName

			Write-Host2 -Type Success -Message "Removal of Event Log successful. Removed $logName on $ComputerName"
		}
	}
	catch{
		$retVal = 1
		Write-Host2 -Type Failure -Message "Removal of Event Log unsuccessful. Failed to remove $logName or its sources on $ComputerName"
		Write-Error2 -ErrorRecord $_
	}

	$retVal
}

function Install-EventLog{
param([string]$EventLogAction)

	$retVal = 0

	if($EventLogAction -eq "Uninstall"){
		return $retVal
	}

    $logName = $DeployRole.EventLogName
    #$maxLogSizeKiloBytes = $DeployRole.MaxLogSizeKiloBytes

	try	{
		if(!(Assert-EventLog -LogName $logName -ComputerName $ComputerName)){
			Write-Host "Creating $eventLogName as it does not exist"
			New-EventLog -LogName $logName -ComputerName $ComputerName -Source $DeployRole.Sources

			#Limit-EventLog -LogName $logName -ComputerName $ComputerName -MaximumSize $maxLogSizeKiloBytes -OverflowAction OverwriteAsNeeded
		}
	}
	catch {
		Write-Host2 -Type Failure -Message "Failed to create $eventLogName or its sources on $ComputerName"
		Write-Error2 -ErrorRecord $_
		$retVal = 1
	}

	$retVal
}

if($ConfigOnly){
	return $result
}

$result = 0

Write-Host ""
Write-Header "Starting role $DeployRole on $ComputerName." -AsSubHeader
$timer = [Diagnostics.Stopwatch]::StartNew()

try
{
	$eventLogAction = "Install"
	switch($DeployRole.Action) {
	    "Install" {$eventLogAction = "Install"}
	    "Uninstall" {$eventLogAction = "Uninstall"}
	    "" {$eventLogAction = "Install"}
	    default {
			Write-Host2 -Type Failure -Message "Incorrect Deployment Action supplied, please check the Deployment Configuration. Aborting deployment of $($ConfigPart.Description)"
			$result = 1
		}
    }

	if($result -eq 0){
		$result = Invoke-UntilFail {Uninstall-EventLog -EventLogAction $eventLogAction},{Install-EventLog -EventLogAction $eventLogAction}
	}
}
catch [System.Exception]
{
	Write-Error2 -ErrorRecord $_
	$result = 1
}

$timer.Stop()

$SummaryLog | Write-Summary -Message "running role $DeployRole on $ComputerName."  -Elapsed $timer.Elapsed -ScriptResult $result
Write-Header "Ending role $DeployRole on $ComputerName" -AsSubHeader
$result
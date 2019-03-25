[cmdletbinding()]
param
(
    [parameter(Mandatory=$true)][string] $ComputerName,
    [Deployment.Domain.Roles.ScheduledTaskDeploy]$DeployRole
)

function Start-Uninstallation{
[cmdletbinding()]
param()

	$retVal = 0

	try{
		$taskName = $DeployRole.TaskName
		$folder = $DeployRole.Folder

		Write-Host "Checking folder $folder exists on computer $ComputerName"
		$TaskFolder = Get-TaskFolders -ComputerName $ComputerName | Where-Object {$_ -eq $folder}
		if($TaskFolder){
			Write-Host "Folder $folder exists on computer $ComputerName"
			Write-Host "Removing scheduled task $taskName from folder $folder on computer $ComputerName"
			Remove-ScheduledTask -Name $taskName -Folder $folder -ComputerName $ComputerName | Out-Null
			Write-Host2 -Type Success -Message "Successfully removed scheduled task [$($DeployRole.TaskName)] on $ComputerName"
		}
		else{
			Write-Host "Folder $folder does not exist on computer $ComputerName"
			Write-Host "Assuming scheduled task $taskName from folder $folder does not exist on computer $ComputerName"
			Write-Host2 -Type Warning -Message "Scheduled task [$($DeployRole.TaskName)] is installed not on $ComputerName"
		}
	}
	catch{
        Write-Error2 -ErrorRecord $_ -ErrorMessage "Error removing scheduled task [$($DeployRole.TaskName)] on [$ComputerName]"
		$retVal = 1
	}

	$retVal
}

function Start-Installation{
[cmdletbinding()]
param()

	$retVal = 0

	try{
		$taskName = $DeployRole.TaskName
		$folder = $DeployRole.Folder

		$taskCred = Get-ServiceAccount -Path $accountsFile -Password $Password -Account $DeployRole.Account.LookupName -AsPsCredential

		Write-Host "Creating/Updating scheduled task $taskName in folder $folder on computer $ComputerName"

		$scheduler = Open-TaskScheduler -ComputerName $ComputerName

		$task = $scheduler | New-ScheduledTask -Folder $folder -Enabled:$DeployRole.Enabled

        $DeployRole.Triggers | ForEach-Object {

            $trigger = $_

			Write-Host "Adding trigger of type $($trigger.ScheduleType)"
            switch ($trigger.ScheduleType) {
                Daily {
                    $task | Add-TaskTrigger -Daily -At $trigger.StartAt -DaysInterval $trigger.Interval -Disabled:$trigger.Disabled -Repeat $trigger.RepeatEvery -For $trigger.RepeatDuration | Out-Null
                }
                Weekly {
                    $task | Add-TaskTrigger -Weekly -At $trigger.StartAt -WeeksInterval $trigger.Interval -DayOfWeek $trigger.DaysOfWeek -Disabled:$trigger.Disabled | Out-Null
                }
                Once {
                    $task | Add-TaskTrigger -At $trigger.StartAt -Disabled:$trigger.Disabled | Out-Null
                }
                OnStart {
                    $task | Add-TaskTrigger -OnBoot -Disabled:$trigger.Disabled | Out-Null
                }

            }
        }

        $DeployRole.Actions | ForEach-Object {
            $action = $_

			Write-Host "Adding action of type $($action.ActionType)"

            switch ($action.ActionType) {
                Program {
                    $task | Add-TaskAction -Path $action.Command -Arguments $action.Arguments | Out-Null
                }
                #DisplayMessage{
                #	$task | Add-TaskAction -
                #}
            }

        }

		Write-Host "Adding task registration info"
		$task | Add-TaskRegistrationInfo -Description $DeployRole.TaskDescription |
			Register-ScheduledTask -Scheduler $scheduler -Name $DeployRole.TaskName -Folder $DeployRole.Folder -ComputerName $ComputerName -TaskCredential $taskCred | Out-Null

		Write-Host2 -Type Success -Message "Successfully created scheduled task [$($DeployRole.TaskName)] on $ComputerName"
	}
	catch{
        Write-Error2 -ErrorRecord $_ -ErrorMessage "Error creating scheduled task [$($DeployRole.TaskName)] on [$ComputerName]"
		$retVal = 1
	}

	$retVal
}

$result = 0

Write-Host ""
Write-Header "Starting role $DeployRole on $ComputerName." -AsSubHeader
$timer = [Diagnostics.Stopwatch]::StartNew()

try {
	if($DeployRole.Action -eq "Install"){
		$result = Start-Installation
	}
	else{
		$result = Start-Uninstallation
	}
}
catch [System.Exception] {
	Write-Error2 -ErrorRecord $_
	$result = 1
}

$timer.Stop()
$SummaryLog | Write-Summary -Message "running role $DeployRole on $ComputerName."  -Elapsed $timer.Elapsed -ScriptResult $result
Write-Header "Ending role $DeployRole on $ComputerName" -AsSubHeader

$result
function Test-ScheduledTask
{
    <#
    .SYNOPSIS
    Tests if a scheduled task exists on the current computer.

    .DESCRIPTION
    The `Test-ScheduledTask` function uses `schtasks.exe` to tests if a task with a given name exists on the current computer. If it does, `$true` is returned. Otherwise, `$false` is returned. This name must be the *full task name*, i.e. the task's path/location and its name.

    .EXAMPLE
    Test-ScheduledTask -Name 'AutoUpdateMyApp'

    Demonstrates how to test if a scheduled tasks exists.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter()]
        [Alias('TaskName')]
        [string]
        # The name of the scheduled task to check.
        $Name,
		[string]
		$ComputerName = "localhost",
		[Parameter(ParameterSetName="Task")]
		 # The credential used to connect
		[Management.Automation.PSCredential]
		$Credential,
		[Parameter()]
		# The name of the scheduler folder
		[String]
		$Folder = "\"
	)

	if($Folder -ne "\"){
		$Folder = "\$Folder"
	}

    $Name = Join-Path -Path $Folder -ChildPath $Name

	$command = "cmd /c schtasks /query /fo list /s $ComputerName /tn `"$Name`""
	Write-Host "Executing command: '$command'"

    $task = Invoke-Expression -Command $command -ErrorAction Stop

	if($LASTEXITCODE){
		Write-Host "schtasks last exit code: $LASTEXITCODE"
	}

	$null -ne $task
}

function Open-TaskScheduler
{
    <#
    .Synopsis
        Gets a task scheduler object on a computer
    .Description
        Gets a task scheduler object on a computer
    .Example
        $scheduler = Open-TaskScheduler
		Remove-TaskScheduler $scheduler
    #>
    param(
    # The name of the computer to connect to.
    [Parameter(ValueFromPipeline=$true,Mandatory=$true)]
	$ComputerName,
    # The credential used to connect
    [Management.Automation.PSCredential]
    $Credential
    )
	PROCESS{
		$scheduler = New-Object -ComObject Schedule.Service
		if ($Credential) {
			$NetworkCredential = $Credential.GetNetworkCredential()
			$scheduler.Connect($ComputerName,
				$NetworkCredential.UserName,
				$NetworkCredential.Domain,
				$NetworkCredential.Password)
		} else {
			$scheduler.Connect($ComputerName)
		}
		$scheduler
	}
}

function Close-ScheduledTaskObject
{
    <#
    .Synopsis
        Releases a COM Scheduled Task or Scheduler object
    .Description
        Releases a COM Scheduled Task object to allow for proper cleanup

    .Example
        # Note, this is an example of the syntax.
		Get-RunningTask -Name "SomeTask" | Disable-ScheduledTask | Unregister-ScheduledTask
    #>
    param(
    # The Task to De-Reference.  The task can either be from the result of Get-ScheduledTask or Get-RunningTask
    [Parameter(ValueFromPipeline=$true,Mandatory=$true)]
    [AllowNull()]
	[__ComObject]
    $Item
    )
    PROCESS {
        if($Item){
			[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Item) | Out-Null
		}
    }
}

function Get-RunningTask
{
    <#
    .Synopsis
        Gets the tasks currently running on the system
    .Description
        A Detailed Description of what the command does
    .Example
        Get-RunningTask
    #>
    [CmdletBinding(DefaultParameterSetName="Scheduler")]
    param(
    # The Scheduled Task Definition
    [Parameter(Mandatory=$true,
        ValueFromPipeline=$true,
		ParameterSetName="Scheduler")]
    [__ComObject]
    $Scheduler,
	[Parameter(Mandatory=$true, ParameterSetName="Task")]
	# The name of the computer to connect to.
    $ComputerName,
	[Parameter(ParameterSetName="Task")]
	 # The credential used to connect
    [Management.Automation.PSCredential]
    $Credential,
    #The name of the task.  By default, all running tasks are shown
    $Name = "*",
    # If this is set, hidden tasks will also be shown.
    # By default, only tasks that are not marked by Task Scheduler as hidden are shown.
    [Switch]
    $Hidden
    )

    PROCESS {
		switch ($psCmdlet.ParameterSetName) {
            Task {
                $Scheduler = Open-TaskScheduler -ComputerName $ComputerName -Credential $Credential
            }
        }

        if ($scheduler -and $scheduler.Connected) {
            $scheduler.GetRunningTasks($Hidden -as [bool]) | Where-Object {
                $_.Path -like $Name -or
                (Split-Path $_.Path -Leaf) -like $name
            }
        }
    }
}

function Get-ScheduledTask
{
    <#
    .Synopsis
        Gets tasks scheduled on the computer
    .Description
        Gets scheduled tasks that are registered on a computer
    .Example
        Get-ScheduleTask -Recurse
		Get-ScheduleTask -Name "SomeTask"
		Get-ScheduleTask -Name "SomeTask", "SomeOtherTask" | Where-Object {$_.status -eq "stopped"}
    #>
    [CmdletBinding(DefaultParameterSetName="Scheduler")]
    param(
    # The Scheduled Task Definition
    [Parameter(Mandatory=$true,
        ValueFromPipeline=$true,
		ParameterSetName="Scheduler")]
    [__ComObject]
    $Scheduler,
	[Parameter(Mandatory=$true, ParameterSetName="Task")]
	# The name of the computer to connect to.
    $ComputerName,
	[Parameter(ParameterSetName="Task")]
	 # The credential used to connect
    [Management.Automation.PSCredential]
    $Credential,
	[Parameter()]
	# The name or name pattern of the scheduled task
    [string]
	$Name = "*",
    # The folder the scheduled task is in
    [Parameter()]
    [String[]]
    $Folder = "",
    # If this is set, hidden tasks will also be shown.
    # By default, only tasks that are not marked by Task Scheduler as hidden are shown.
    [Switch]
    $Hidden,
    # If set, will get tasks recursively beneath the specified folder
    [switch]
    $Recurse,
	[switch]
    $PassThru
    )
    PROCESS {
		switch ($psCmdlet.ParameterSetName) {
            Task {
                $Scheduler = Open-TaskScheduler -ComputerName $ComputerName -Credential $Credential
            }
        }

		if ($Scheduler -and $Scheduler.Connected) {

			if($PassThru) {
				$Scheduler
			}

			$taskFolder = $Scheduler.GetFolder($folder)
			$taskFolder.GetTasks($Hidden -as [bool]) | Where-Object {
				$_.Name -like $name
			}
			#TODO Need to think about bound parameters if passing scheduler object.
			#as it will be a differnt parameter set.
			#think about not using recursion, but loop instead
			if ($Recurse) {
				$taskFolder.GetFolders(0) | ForEach-Object {
					$psBoundParameters.Folder = $_.Path
					Get-ScheduledTask @psBoundParameters
				}
			}
		}
    }
}

function Stop-ScheduledTask
{
    <#
    .Synopsis
        Stops a scheduled task
    .Description
        Stops a scheduled task or a running task.  Scheduled tasks can be supplied with Get-Task and

    .Example
        # Note, this is an example of the syntax.  You should never stop all running tasks,
        # as they are used by the operating system.  Instead, use a filter to get the tasks
        Get-RunningTask | Stop-Task
    #>
    param(
    # The Task to stop.  The task can either be from the result of Get-ScheduledTask or Get-RunningTask
    [Parameter(ValueFromPipeline=$true,Mandatory=$true)]
    [Alias("Task")]
	[__ComObject]
    $ScheduledTask,
	[switch]
	$KeepAlive
    )
    PROCESS {
        if ($ScheduledTask.PSObject.TypeNames -contains 'System.__ComObject#{9c86f320-dee3-4dd1-b972-a303f26b061e}') {
            $ScheduledTask.Stop(0)
        } else {
            $ScheduledTask.Stop()
        }

		if($KeepAlive){
			return $ScheduledTask
		}

		Close-ScheduledTaskObject $ScheduledTask
    }
}

function Start-ScheduledTask
{
    <#
    .Synopsis
        Starts a scheduled task
    .Description
        Starts running a scheduled task.
        The input to the command is the output of Get-ScheduledTask.
    .Example
        New-ScheduledTask |
            Add-TaskAction -Script {
                Get-Process | Out-GridView
                Start-Sleep 100
            } |
            Register-ScheduledTask (Get-Random) |
            Start-Task |
    #>
    param(
    # The Task to start.  To get tasks, use Get-ScheduledTask
    [Parameter(ValueFromPipeline=$true,
        Mandatory=$true)]
    [Alias("Task")]
	[__ComObject]
    $ScheduledTask,
	[switch]
	$KeepAlive
    )
    PROCESS {
        $ScheduledTask.Run(0)

		if($KeepAlive){
			return $ScheduledTask
		}

		Close-ScheduledTaskObject $ScheduledTask
    }
}

function Enable-ScheduledTask
{
    <#
    .Synopsis
        Enables a scheduled task
    .Description
        Enables a scheduled task.  Scheduled tasks can be supplied with Get-ScheduledTask

    .Example
        # Note, this is an example of the syntax.
        $tasks = Get-ScheduledTask -Name "SomeTask", "SomeOtherTask" | Enable-ScheduledTask -KeepAlive
    #>
    param(
    # The Task to Enable.  The task can either be from the result of Get-ScheduledTask or Get-RunningTask
    [Parameter(ValueFromPipeline=$true,Mandatory=$true)]
	[Alias("Task")]
	[__ComObject]
    $ScheduledTask,
	[switch]
	$KeepAlive
    )

    PROCESS {
        $ScheduledTask.Enabled = $true
		if($KeepAlive){
			return $ScheduledTask
		}

		Close-ScheduledTaskObject $ScheduledTask
    }
}

function Disable-ScheduledTask
{
    <#
    .Synopsis
        Disables a scheduled task
    .Description
        Disables a scheduled task.  Scheduled tasks can be supplied with Get-ScheduledTask

    .Example
        # Note, this is an example of the syntax. You might want to consider stopping a running task before disabling
        Get-ScheduledTask -Name "SomeTask", "SomeOtherTask" | Stop-ScheduledTask | Disable-ScheduledTask
		$task = Get-RunningTask -Name "SomeTask" | Disable-ScheduledTask -KeepAlive
    #>
    param(
    # The Task to Disable.  The task can either be from the result of Get-ScheduledTask or Get-RunningTask
    [Parameter(ValueFromPipeline=$true,Mandatory=$true)]
	[Alias("Task")]
	[__ComObject]
    $ScheduledTask,
	[switch]
	$KeepAlive
    )

	BEGIN{
	}
    PROCESS {
        $ScheduledTask.Enabled = $false

		if($KeepAlive){
			return $ScheduledTask
		}

		Close-ScheduledTaskObject $ScheduledTask
    }
	END{
	}
}

function New-ScheduledTask
{
    <#
    .Synopsis
        Creates a new task definition.
    .Description
        Creates a new task definition.
        Tasks are not scheduled until Register-ScheduledTask is run.
        To add triggers use Add-TaskTrigger.
        To add actions, use Add-TaskActions
    .Link
        Add-TaskTrigger
        Add-TaskActions
        Register-ScheduledTask
    .Example
		 New-ScheduledTask |
            Add-TaskAction -Script {
                Get-Process | Out-GridView
                Start-Sleep 100
            } |
            Register-ScheduledTask (Get-Random)
    #>
    [CmdletBinding(DefaultParameterSetName="Scheduler")]
    param(
    # The Scheduled Task Definition
    [Parameter(Mandatory=$true,
        ValueFromPipeline=$true,
		ParameterSetName="Scheduler")]
    [__ComObject]
    $Scheduler,
	[Parameter(Mandatory=$true,ParameterSetName="Task")]
	# The name of the computer to connect to.
    $ComputerName,
	[Parameter(ParameterSetName="Task")]
	 # The credential used to connect
    [Management.Automation.PSCredential]
    $Credential,
	 # The folder the scheduled task is in
    [Parameter()]
    [String]
    $Folder = "",

	# If set, the task will wake the computer to run
    [Switch]
    $WakeToRun,

    # If set, the task will run on batteries and will not stop when going on batteries
    [Switch]
    $RunOnBattery,

    # If set, the task will run only if connected to the network
    [Switch]
    $RunOnlyIfNetworkAvailable,

    # If set, the task will run only if the computer is idle
    [Switch]
    $RunOnlyIfIdle,

    # If set, the task will run after its scheduled time as soon as it is possible
    [Switch]
    $StartWhenAvailable,

    # The maximum amount of time the task should run
    [Timespan]
    $ExecutionTimeLimit = (New-TimeSpan),

    # Sets how the task should behave when an existing instance of the task is running.
    # By default, a 2nd instance of the task will not be started
    [ValidateSet("Parallel", "Queue", "IgnoreNew", "StopExisting")]
    [String]
    $MultipleInstancePolicy = "IgnoreNew",

    # The priority of the running task
    [ValidateRange(1, 10)]
    [int]
    $Priority = 6,

    # If set, the new task will be a hidden task
    [Switch]
    $Hidden,

    # If set, the task will be enabled
    [Switch]
    $Enabled,

    # If set, the task will not be able to be started on demand
    [Switch]
    $DoNotStartOnDemand,

    # If Set, the task will not be able to be manually stopped
    [Switch]
    $DoNotAllowStop
    )

	PROCESS{
		switch ($psCmdlet.ParameterSetName) {
            Task {
                $Scheduler = Open-TaskScheduler -ComputerName $ComputerName -Credential $Credential
            }
        }

		if ($Scheduler -and $Scheduler.Connected) {

			Add-TaskSchedulerFolder -Scheduler $Scheduler -Folder $Folder -KeepAlive| Out-Null
			$task = $Scheduler.NewTask(0)
			$task.Settings.Priority = $Priority
			$task.Settings.WakeToRun = $WakeToRun
			$task.Settings.RunOnlyIfNetworkAvailable = $RunOnlyIfNetworkAvailable
			$task.Settings.StartWhenAvailable = $StartWhenAvailable
			$task.Settings.Hidden = $Hidden
			$task.Settings.RunOnlyIfIdle = $RunOnlyIfIdle
			$task.Settings.Enabled = $Enabled
			$task.Settings.Compatibility = 2 #TASK_COMPATIBILITY_V2 (Server 2008 R2)

			if ($RunOnBattery) {
				$task.Settings.StopIfGoingOnBatteries = $false
				$task.Settings.DisallowStartIfOnBatteries = $false
			}
			$task.Settings.AllowDemandStart = -not $DoNotStartOnDemand
			$task.Settings.AllowHardTerminate = -not $DoNotAllowStop
			switch ($MultipleInstancePolicy) {
				Parallel { $task.Settings.MultipleInstances = 0 }
				Queue { $task.Settings.MultipleInstances = 1 }
				IgnoreNew { $task.Settings.MultipleInstances = 2}
				StopExisting { $task.Settings.MultipleInstances = 3 }
			}
			$task
		}
	}
}

function Remove-ScheduledTask
{
    <#
    .Synopsis
        Removes a scheduled task
    .Description
        Removes a scheduled task from the computer.
    .Example
        New-ScheduledTask |
            Add-TaskAction -Script {
                Get-Process | Out-GridView
                Start-Sleep 100
            } |
            Register-ScheduledTask (Get-Random) |
            Remove-ScheduledTask
    #>
    [CmdletBinding(DefaultParameterSetName="Name")]
    param(
    # The scheduled task to remove.  This value can be supplied with the output of Get-ScheduledTask
    [Parameter(ParameterSetName="Task",
        ValueFromPipeline=$true)]
		[Alias("Task")]
    [__ComObject]
	$ScheduledTask,
	# The Task Scheduler
	[Parameter(ParameterSetName="Task")]
    [__ComObject]
    $Scheduler,
	[Parameter(Mandatory=$true,ParameterSetName="Name")]
	[Parameter(ParameterSetName="Task")]
	# The name of the computer to connect to.
    $ComputerName,
	[Parameter(ParameterSetName="Name")]
	[Parameter(ParameterSetName="Task")]
	 # The credential used to connect
    [Management.Automation.PSCredential]
    $Credential,
    [Parameter(Mandatory=$true,
        ParameterSetName="Name")]
    [String]
    $Name,
    # The folder the scheduled task is in
    [String]
    $Folder = "",
    # If this is set, hidden tasks will also be shown.
    # By default, only tasks that are not marked by Task Scheduler as hidden are shown.
    [Switch]
    $Hidden,
    # If set, will get tasks recursively beneath the specified folder
    [switch]
    $Recurse
    )

    PROCESS {
        switch ($psCmdlet.ParameterSetName) {
            Task {
                if(!$Scheduler){
					$Scheduler = Open-TaskScheduler -ComputerName $ComputerName -Credential $Credential
				}
                $taskFolder = $Scheduler.GetFolder($Folder)
                $taskFolder.DeleteTask($ScheduledTask.Name, 0)
				Close-ScheduledTaskObject $ScheduledTask
				#Close-ScheduledTaskObject $Scheduler
            }
            Name {
				$taskInfo = Get-ScheduledTask @PSBoundParameters -PassThru #returns scheduler too.

				if($taskInfo.Count -gt 0){
					$psBoundParameters.Remove('Name')
					$psBoundParameters.Scheduler = $taskInfo[0]
					$taskInfo[1] | Remove-ScheduledTask @PSBoundParameters
				}
				else{
					Write-Warning "No tasks matching name '$Name' in folder $Folder were found. Skipping removal."
				}
            }
        }
    }
}

function Register-ScheduledTask
{
    <#
    .Synopsis
        Registers a scheduled task.
    .Description
        Registers a scheduled task.
    #>
    param(
	# The scheduled task to remove.  This value can be supplied with the output of Get-ScheduledTask
    [Parameter(ParameterSetName="Task",
        ValueFromPipeline=$true)]
		[Alias("Task")]
    [__ComObject]
	$ScheduledTask,
	 # The Task Scheduler
    [Parameter()]
    [__ComObject]
    $Scheduler,
	# The name of the computer to connect to.
    [Parameter(Mandatory=$true)]
	[string]
    $ComputerName,
    # The credential used to connect
    [Management.Automation.PSCredential]
    $Credential,
    # The name of the scheduled task to register
    [Parameter(Mandatory=$true)]
    [string]
    $Name,
	 # The credential used to connect
    [Management.Automation.PSCredential]
    $TaskCredential,
	[string]
	$Folder = "",
	[switch]
	$KeepAlive
    )

    BEGIN {
        Set-StrictMode -Off
    }
    PROCESS {
        if ($ScheduledTask.Definition) { $ScheduledTask = $ScheduledTask.Definition }

		if(!$Scheduler){
			$Scheduler = Open-TaskScheduler -ComputerName $ComputerName -Credential $Credential
		}

		$taskCreateOrUpdateFlag = 6

		if ($scheduler -and $scheduler.Connected) {
            $targetFolder = $scheduler.GetFolder($Folder)
            if ($TaskCredential) {
                $targetFolder.RegisterTaskDefinition($Name,
                    $ScheduledTask,
                    $taskCreateOrUpdateFlag,
                    $TaskCredential.UserName,
                    $TaskCredential.GetNetworkCredential().Password,
                    1,
                    $null)
            } else {
                $targetFolder.RegisterTaskDefinition($Name,
                    $ScheduledTask,
                    $taskCreateOrUpdateFlag,
                    "",
                    "",
                    3,
                    $null)
            }
        }

		#TODO: Need to set principal to run at highest priviledges.
		#see if this works.
		#$scheduler.Principal.RunLevel = 1 #Highest

		#TODO: Need to test to ensure RegisterTaskDefinition method
		#does not return a Task object,

		if($KeepAlive){
			return $ScheduledTask
		}

		#Close-ScheduledTaskObject $ScheduledTask
		Close-ScheduledTaskObject $Scheduler
    }
	END{}
}

function Close-TaskSchedulerFolders
{
    <#
    .Synopsis
        Gets a list of folders from a root path
    .Description

    .Example
        Close-TaskSchedulerFolders -ComputerName "SomeServer"
		Open-TaskScheduler -ComputerName $ComputerName | Close-TaskSchedulerFolders -RootFolder "ABC"
    #>
   [CmdletBinding(DefaultParameterSetName="Scheduler")]
    param(
    # The Scheduled Task Definition
    [Parameter(Mandatory=$true,
        ValueFromPipeline=$true,
		ParameterSetName="Scheduler")]
    [__ComObject]
    $Scheduler,
	[Parameter(ParameterSetName="Task")]
	 # The credential used to connect
    [Management.Automation.PSCredential]
    $Credential,

	[Parameter(ParameterSetName="Task")]
	# The name of the computer to connect to.
    $ComputerName,

	[Parameter()]
    # The name of the scheduler root folder
    [String]
    $Folder = "\",
	[switch]
	$KeepAlive
    )

    BEGIN {
        Set-StrictMode -Off
    }

    PROCESS {

		switch ($psCmdlet.ParameterSetName) {
            Task {
                $Scheduler = Open-TaskScheduler -ComputerName $ComputerName -Credential $Credential
            }
        }

		try{
			$Scheduler.GetFolder($Folder).GetFolders(0) | Select-Object -ExpandProperty Name
		}
		catch{
			#ignore error
		}

		if(!$KeepAlive){
			Close-ScheduledTaskObject $Scheduler
		}
    }
	END{
	}
}

function Add-TaskSchedulerFolder
{
    <#
    .Synopsis
        Adds a Task Scheduler folder
    .Description
        Adds a Task Scheduler folder
    .Example
		Add-TaskSchedulerFolders -ComputerName "SomeServer" -Folder "SomeFolder"
		Open-TaskScheduler -ComputerName $ComputerName | Add-TaskSchedulerFolders -Folder "ABC"
    #>
    [CmdletBinding(DefaultParameterSetName="Scheduler")]
    param(
    # The Scheduled Task Definition
    [Parameter(Mandatory=$true,
        ValueFromPipeline=$true,
		ParameterSetName="Scheduler")]
    [__ComObject]
    $Scheduler,

	[Parameter(ParameterSetName="Task")]
	# The name of the computer to connect to.
    $ComputerName,

	[Parameter(ParameterSetName="Task")]
	 # The credential used to connect
    [Management.Automation.PSCredential]
    $Credential,

	[Parameter(Mandatory=$true,
    ParameterSetName="Scheduler")]
    # The name of the scheduler folder
    [String]
    $Folder,
	[switch]
	$KeepAlive
    )

    BEGIN {
        Set-StrictMode -Off
    }

    PROCESS {

		 switch ($psCmdlet.ParameterSetName) {
            Task {
                $Scheduler = Open-TaskScheduler -ComputerName $ComputerName -Credential $Credential
            }
        }

		try{
			$currentFolder = $Scheduler.GetFolder($Folder)
		}
		catch{
			#ignore error
		}

		if(!$currentFolder){
			$root = $Scheduler.GetFolder("\")
			$root.CreateFolder($Folder)
		}

		if(!$KeepAlive){
			Close-ScheduledTaskObject $Scheduler
		}
    }
}

function Add-TaskRegistrationInfo
{
    <#
    .Synopsis
        Adds registation info to a task definition
    .Description
        Adds registration info to a task definition.
        You can create a task definition with New-Task, or use an existing definition from Get-ScheduledTask
    .Example
        New-ScheduledTask -Disabled |
            Add-TaskRegistrationInfo -Author 'Some User' -Description 'The Description' |
			Add-TaskTrigger  $EVT[0] |
            Add-TaskAction -Path Calc |
            Register-ScheduledTask "$(Get-Random)"
    .Link
        Register-ScheduledTask
    .Link
        Add-TaskTrigger
    .Link
        Get-ScheduledTask
    .Link
        New-ScheduledTask
    #>
    [CmdletBinding()]
    param(
    # The Scheduled Task Definition
    [Parameter(Mandatory=$true,
        ValueFromPipeline=$true)]
    [Alias("Task")]
	[__ComObject]
    $ScheduledTask,

    [Parameter()]
    [string]
    $Author = $env:username,

    [Parameter()]
    [string]
    $Description = ""
    )

    BEGIN {
        Set-StrictMode -Off
    }

    PROCESS {
        if ($ScheduledTask.Definition) {  $ScheduledTask = $ScheduledTask.Definition }

        $regInfo = $ScheduledTask.RegistrationInfo
		$regInfo.Description = $Description
		$regInfo.Author = $Author
		#$regInfo.Date = Get-Date

        $ScheduledTask
    }
	END{}
}

function Add-TaskSettings
{
    <#
    .Synopsis
        Adds settings info to a task definition
    .Description
        Adds settings info to a task definition.
        You can create a task definition with New-Task, or use an existing definition from Get-ScheduledTask
    .Example
        New-ScheduledTask -Disabled |
            Add-TaskRegistrationInfo -Author 'Some User' -Description 'The Description' |
			Add-TaskSettings |
			Add-TaskTrigger  $EVT[0] |
            Add-TaskAction -Path Calc |
            Register-ScheduledTask "$(Get-Random)"
    .Link
        Register-ScheduledTask
    .Link
        Add-TaskTrigger
    .Link
        Get-ScheduledTask
    .Link
        New-ScheduledTask
    #>
    [CmdletBinding()]
    param(
    # The Scheduled Task Definition
    [Parameter(Mandatory=$true,
        ValueFromPipeline=$true)]
     [Alias("Task")]
	[__ComObject]
    $ScheduledTask,

    [Parameter()]
    [string]
    $Author = $env:username,

    [Parameter()]
    [string]
    $Description = ""
    )

    BEGIN {
        Set-StrictMode -Off
    }

    PROCESS {
        if ($ScheduledTask.Definition) {  $ScheduledTask = $ScheduledTask.Definition }

        $settings = $ScheduledTask.Settings

        $ScheduledTask
    }
	END{}
}

function Add-TaskAction
{
    <#
    .Synopsis
        Adds an action to a task definition
    .Description
        Adds an action to a task definition.
        You can create a task definition with New-Task, or use an existing definition from Get-ScheduledTask
    .Example
        New-ScheduledTask -Disabled |
            Add-TaskTrigger  $EVT[0] |
            Add-TaskAction -Path Calc |
            Register-ScheduledTask "$(Get-Random)"
    .Link
        Register-ScheduledTask
    .Link
        Add-TaskTrigger
    .Link
        Get-ScheduledTask
    .Link
        New-ScheduledTask
    #>
    [CmdletBinding(DefaultParameterSetName="Script")]
    param(
    # The Scheduled Task Definition
    [Parameter(Mandatory=$true,
        ValueFromPipeline=$true)]
     [Alias("Task")]
	[__ComObject]
    $ScheduledTask,

    # The script to run
    [Parameter(Mandatory=$true,ParameterSetName="Script")]
    [ScriptBlock]
    $Script,

    # If set, will run PowerShell.exe with -WindowStyle Minimized
    [Parameter(ParameterSetName="Script")]
    [Switch]
    $Hidden,

    # If set, will run PowerShell.exe
    [Parameter(ParameterSetName="Script")]
    [Switch]
    $Sta,

    # The path to the program.
    [Parameter(Mandatory=$true,ParameterSetName="Path")]
    [string]
    $Path,

    # The arguments to pass to the program.
    [Parameter(ParameterSetName="Path")]
    [string]
    $Arguments,

    # The working directory the action will run in.
    # By default, this will be the current directory
    [String]
    $WorkingDirectory = $PWD,

    # If set, the powershell script will not exit when it is completed
    [Parameter(ParameterSetName="Script")]
    [Switch]
    $NoExit,

    # The identifier of the task
    [String]
    $Id
    )

    BEGIN {
        Set-StrictMode -Off
    }

    PROCESS {
        if ($ScheduledTask.Definition) {  $ScheduledTask = $ScheduledTask.Definition }

        $Action = $ScheduledTask.Actions.Create(0)
        if ($Id) { $Action.ID = $Id }
        $Action.WorkingDirectory = $WorkingDirectory
        switch ($psCmdlet.ParameterSetName) {
            Script {
                $action.Path = Join-Path $psHome "PowerShell.exe"
                $action.WorkingDirectory = $pwd
                $action.Arguments = ""
                if ($Hidden) {
                    $action.Arguments += " -WindowStyle Hidden"
                }
                if ($sta) {
                    $action.Arguments += " -Sta"
                }
                if ($NoExit) {
                    $Action.Arguments += " -NoExit"
                }

                $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($script))
                $action.Arguments+= " -encodedCommand $encodedCommand"
            }
            Path {
                $action.Path = $Path
                $action.Arguments = $Arguments
				$action.WorkingDirectory = $null
            }
        }
        $ScheduledTask
    }
	END{}
}

function Add-TaskTrigger
{
    <#
    .Synopsis
        Adds a trigger to an existing task.
    .Description
        Adds a trigger to an existing task.
        The task is outputted to the pipeline, so that additional triggers can be added.
    .Example
        New-ScheduledTask |
            Add-TaskTrigger -DayOfWeek Monday, Wednesday, Friday -WeeksInterval 2 -At "3:00 PM" |
            Add-TaskAction -Script { Get-Process | Out-GridView } |
            Register-ScheduledTask TestTask
    .Link
        Add-TaskAction
    .Link
        Register-ScheduledTask
    .Link
        New-ScheduledTask
    #>
    [CmdletBinding(DefaultParameterSetName="OneTime")]
    param(
    # The Scheduled Task Definition.  A New definition can be created by using New-Task
    [Parameter(Mandatory=$true,
        ValueFromPipeline=$true)]
    [Alias('Task')]
    [__ComObject]
    $ScheduledTask,

    # The At parameter is used as the start time of the task for several different trigger types.
    [Parameter(Mandatory=$true,ParameterSetName="Daily")]
    [Parameter(Mandatory=$true,ParameterSetName="Monthly")]
    [Parameter(Mandatory=$true,ParameterSetName="MonthlyDayOfWeek")]
    [Parameter(Mandatory=$true,ParameterSetName="OneTime")]
    [Parameter(Mandatory=$true,ParameterSetName="Weekly")]
    [DateTime]
    $At,

    # Day of Week Trigger
    [Parameter(Mandatory=$true, ParameterSetName="Weekly")] #TODO: Why Mandatory - Default to all?
    [Parameter(Mandatory=$true, ParameterSetName="MonthlyDayOfWeek")]
    [ValidateSet("Sunday","Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")]
    [string[]]
    $DayOfWeek,

	 # If set, the task will trigger at a specific time every day
    [Parameter(ParameterSetName="Weekly")]
    [Switch]
    $Weekly,

    # If set, will only run the task N number of weeks
    [Parameter(ParameterSetName="Weekly")]
    [Int]
    $WeeksInterval = 1,

    # Months of Year
    [Parameter(Mandatory=$true, ParameterSetName="Monthly")]
    [Parameter(Mandatory=$true, ParameterSetName="MonthlyDayOfWeek")]
    [ValidateSet("January","February", "March", "April", "May", "June",
        "July", "August", "September","October", "November", "December")]
    [string[]]
    $MonthOfYear,

    # The day of the month to run the task on
    [Parameter(Mandatory=$true, ParameterSetName="Monthly")]
    [ValidateRange(1,31)]
    [int[]]
    $DayOfMonth,

    # The weeks of the month to run the task on.
    [Parameter(Mandatory=$true, ParameterSetName="MonthlyDayOfWeek")]
    [ValidateRange(1,6)]
    [int[]]
    $WeekOfMonth,

    # The timespan to run the task in.
    [Parameter(Mandatory=$true,ParameterSetName="In")]
    [Timespan]
    $In,

    # If set, the task will trigger at a specific time every day
    [Parameter(ParameterSetName="Daily")]
    [Switch]
    $Daily,

    # If set, the task will trigger every N days
    [Parameter(ParameterSetName="Daily")]
    [Int]
    $DaysInterval = 1,

    # If set, a registration trigger will be created
    [Parameter(Mandatory=$true,ParameterSetName="Registration")]
    [Switch]
    $OnRegistration,

    # If set, the task will be triggered on boot
    [Parameter(Mandatory=$true,ParameterSetName="Boot")]
    [Switch]
    $OnBoot,

    # If set, the task will be triggered on logon.
    # Use the OfUser parameter to only trigger the task for certain users
    [Parameter(Mandatory=$true,ParameterSetName="Logon")]
    [Switch]
    $OnLogon,

    # In Session State tasks or logon tasks, determines what type of users will launch the task
    [Parameter(ParameterSetName="Logon")]
    [Parameter(ParameterSetName="StateChanged")]
    [string]
    $OfUser,

    # In Session State triggers, this parameter is used to determine what state change will trigger the task
    [Parameter(Mandatory=$true,ParameterSetName="StateChanged")]
    [ValidateSet("Connect", "Disconnect", "RemoteConnect", "RemoteDisconnect", "Lock", "Unlock")]
    [string]
    $OnStateChanged,

    # If set, the task will be triggered on Idle
    [Parameter(Mandatory=$true,ParameterSetName="Idle")]
    [Switch]
    $OnIdle,

    # If set, the task will be triggered whenever the event occurs.  To get an event record, use Get-WinEvent
    [Parameter(Mandatory=$true, ParameterSetName="Event")]
    [Diagnostics.Eventing.Reader.EventLogRecord]
    $OnEvent,

    # If set, the task will be triggered whenever the event query occurs.  The query is in xpath.
    [Parameter(Mandatory=$true, ParameterSetName="EventQuery")]
    [string]
    $OnEventQuery,

    # The interval the task should be repeated at.
    [Timespan]
    $Repeat,

    # The amount of time to repeat the task for
    [Timespan]
    $For,

    # The time the task should stop being valid
    [DateTime]
    $Until,
	[switch]
	$Disabled
    )

    BEGIN {
        Set-StrictMode -Off
    }
    PROCESS {
        if ($ScheduledTask.Definition) {  $ScheduledTask = $ScheduledTask.Definition }

        switch ($psCmdlet.ParameterSetName) {
            StateChanged {
                $Trigger = $ScheduledTask.Triggers.Create(11)
                if ($OfUser) {
                    $Trigger.UserID = $OfUser
                }
                switch ($OnStateChanged) {
                    Connect { $Trigger.StateChange = 1 }
                    Disconnect { $Trigger.StateChange = 2 }
                    RemoteConnect { $Trigger.StateChange = 3 }
                    RemoteDisconnect { $Trigger.StateChange = 4 }
                    Lock { $Trigger.StateChange = 7 }
                    Unlock { $Trigger.StateChange = 8 }
                }
            }
            Logon {
                $Trigger = $ScheduledTask.Triggers.Create(9)
				$Trigger.Enabled = !$Disabled.IsPresent
                if ($OfUser) {
                    $Trigger.UserID = $OfUser
                }
            }
            Boot {
                $Trigger = $ScheduledTask.Triggers.Create(8)
				$Trigger.Enabled = !$Disabled.IsPresent
            }
            Registration {
                $Trigger = $ScheduledTask.Triggers.Create(7)
				$Trigger.Enabled = !$Disabled.IsPresent
            }
            OneTime {
                $Trigger = $ScheduledTask.Triggers.Create(1)
                $Trigger.StartBoundary = $at.ToString("s")
				$Trigger.Enabled = !$Disabled.IsPresent
            }
            Daily {
                $Trigger = $ScheduledTask.Triggers.Create(2)
                $Trigger.StartBoundary = $at.ToString("s")
                $Trigger.DaysInterval = $DaysInterval
				$Trigger.Enabled = !$Disabled.IsPresent
            }
            Idle {
                $Trigger = $ScheduledTask.Triggers.Create(6)
				$Trgger.Enabled = !$Disabled.IsPresent
            }
            Monthly {
                $Trigger =  $ScheduledTask.Triggers.Create(4)
                $Trigger.StartBoundary = $at.ToString("s")
				$Trigger.Enabled = !$Disabled.IsPresent
                $value = 0
                foreach ($month in $MonthOfYear) {
                    switch ($month) {
                        January { $value = $value -bor 1 }
                        February { $value = $value -bor 2 }
                        March { $value = $value -bor 4 }
                        April { $value = $value -bor 8 }
                        May { $value = $value -bor 16 }
                        June { $value = $value -bor 32 }
                        July { $value = $value -bor 64 }
                        August { $value = $value -bor 128 }
                        September { $value = $value -bor 256 }
                        October { $value = $value -bor 512 }
                        November { $value = $value -bor 1024 }
                        December { $value = $value -bor 2048 }
                    }
                }
                $Trigger.MonthsOfYear = $Value
                $value = 0
                foreach ($day in $DayofMonth) {
                    $value = $value -bor ([Math]::Pow(2, $day - 1))
                }
                $Trigger.DaysOfMonth  = $value
            }
            MonthlyDayOfWeek {
                $Trigger =  $ScheduledTask.Triggers.Create(5)
                $Trigger.StartBoundary = $at.ToString("s")
				$Trigger.Enabled = !$Disabled.IsPresent
                $value = 0
                foreach ($month in $MonthOfYear) {
                    switch ($month) {
                        January { $value = $value -bor 1 }
                        February { $value = $value -bor 2 }
                        March { $value = $value -bor 4 }
                        April { $value = $value -bor 8 }
                        May { $value = $value -bor 16 }
                        June { $value = $value -bor 32 }
                        July { $value = $value -bor 64 }
                        August { $value = $value -bor 128 }
                        September { $value = $value -bor 256 }
                        October { $value = $value -bor 512 }
                        November { $value = $value -bor 1024 }
                        December { $value = $value -bor 2048 }
                    }
                }
                $Trigger.MonthsOfYear = $Value
                $value = 0
                foreach ($week in $WeekofMonth) {
                    $value = $value -bor ([Math]::Pow(2, $week - 1))
                }
                $Trigger.WeeksOfMonth = $value
                $value = 0
                foreach ($day in $DayOfWeek) {
                    switch ($day) {
                        Sunday { $value = $value -bor 1 }
                        Monday { $value = $value -bor 2 }
                        Tuesday { $value = $value -bor 4 }
                        Wednesday { $value = $value -bor 8 }
                        Thursday { $value = $value -bor 16 }
                        Friday { $value = $value -bor 32 }
                        Saturday { $value = $value -bor 64 }
                    }
                }
                $Trigger.DaysOfWeek = $value

            }
            Weekly {
                $Trigger = $ScheduledTask.Triggers.Create(3)
                $Trigger.StartBoundary = $at.ToString("s")
				$Trigger.Enabled = !$Disabled.IsPresent
                $value = 0
                foreach ($day in $DayOfWeek) {
                    switch ($day) {
                        Sunday { $value = $value -bor 1 }
                        Monday { $value = $value -bor 2 }
                        Tuesday { $value = $value -bor 4 }
                        Wednesday { $value = $value -bor 8 }
                        Thursday { $value = $value -bor 16 }
                        Friday { $value = $value -bor 32 }
                        Saturday { $value = $value -bor 64 }
                    }
                }
                $Trigger.DaysOfWeek = $value
                $Trigger.WeeksInterval = $WeeksInterval
            }
            In {
                $Trigger = $ScheduledTask.Triggers.Create(1)
                $at = (Get-Date) + $in
                $Trigger.StartBoundary = $at.ToString("s")
				$Trigger.Enabled = !$Disabled.IsPresent
            }
            Event {
                $Query = $ScheduledTask.Triggers.Create(0)
                $Query.Subscription = "
<QueryList>
    <Query Id='0' Path='$($OnEvent.LogName)'>
        <Select Path='$($OnEvent.LogName)'>
            *[System[Provider[@Name='$($OnEvent.ProviderName)'] and EventID=$($OnEvent.Id)]]
        </Select>
    </Query>
</QueryList>
                "
            }
            EventQuery {
                $Query = $ScheduledTask.Triggers.Create(0)
                $Query.Subscription = $OnEventQuery
            }
        }
        if ($Until) {
            $Trigger.EndBoundary = $until.ToString("s")
        }
        if ($Repeat.TotalSeconds) {
            $Trigger.Repetition.Interval = "PT$([Math]::Floor($Repeat.TotalHours))H$($Repeat.Minutes)M"
        }
        if ($For.TotalSeconds) {
            $Trigger.Repetition.Duration = "PT$([Math]::Floor($For.TotalHours))H$([int]$For.Minutes)M$($For.Seconds)S"
        }
        $ScheduledTask
    }
}

function Get-TaskStatus {
[CmdletBinding()]
	param (
        # The Scheduled Task Definition
    [Parameter(Mandatory=$true,
        ValueFromPipeline=$true)]
		[Alias("Task")]
    [__ComObject]
    $ScheduleTask,
	[switch]
	$KeepAlive
    )
	PROCESS{

		$obj = New-Object -TypeName PSObject

		Add-Member -InputObject $obj -MemberType NoteProperty -Name 'TaskName' -Value $ScheduleTask.Name

		$state = 'Disabled'

		if (([xml]$ScheduleTask.Xml).Task.Settings.Enabled -eq $true) { $state = 'Enabled' }

		Add-Member -InputObject $obj -MemberType NoteProperty -Name 'State' -Value $state

		if(!$KeepAlive){
			Close-ScheduledTaskObject $ScheduleTask
		}

		$obj
	}
}

function Get-TaskFolders
{
    <#
    .Synopsis
        Gets a list of folders from a root path
    .Description

    .Example
        Get-TaskFolders
    #>
    [CmdletBinding(DefaultParameterSetName="Scheduler")]
    param(
    # The Scheduled Task Definition
    [Parameter(Mandatory=$true,
        ValueFromPipeline=$true,
		ParameterSetName="Scheduler")]
    [__ComObject]
    $Scheduler,
	[Parameter(Mandatory=$true, ParameterSetName="Task")]
	# The name of the computer to connect to.
    $ComputerName,
	[Parameter(ParameterSetName="Task")]
	 # The credential used to connect
    [Management.Automation.PSCredential]
    $Credential,
	[Parameter()]
    # The name of the scheduler root folder
    [String]
    $RootFolder = "\"
    )

    PROCESS {

		 switch ($psCmdlet.ParameterSetName) {
            Task {
                $Scheduler = Open-TaskScheduler -ComputerName $ComputerName -Credential $Credential
            }
        }

		try{
			if($Scheduler -and $Scheduler.Connected){
				$Scheduler.GetFolder($RootFolder).GetFolders(0) | Select-Object -ExpandProperty Name
			}
		}
		catch{
			#ignore error
		}
    }
}
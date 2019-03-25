function Write-Summary{
			param($Message, [switch] $NoSuspend)
				#Resume-Logging $logFile1


				#TODO:Need a way of being able to target which logs we ignore runspace on, rather than all.
				#we could change the -IngoreRunspace swith to take a list of logs instead
				#and store the ignore runspace setting at a log level instead.
				#The problem here is timing.  We could turn this off here, and then it could overlap
				#with a call from the outer script?


				#---Update. We should not call Write-Summary from inner script
				#but instead handle it in the outer loop, that way runspace is not an issue.
				#just means we need to handle it twice
				Write-Host2 $Message #-IgnoreRunspace

				#if(-not $NoSuspend){
				#	Suspend-Logging $logFile1
				#}
			}

function Test-Runspace {
param()

	$numOfThreads = 4

	$sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
	$sessionstate.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList "async" ,$true, "async flag"))
	$sessionState.ImportPSModule("PowerShellLogging")

	$RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, $numOfThreads, $sessionState, $Host)
	$RunspacePool.Open()

	$Jobs = @()

	$InnerBlock = {
		Param (
		[int]$Count,
		[string]$MachineLogPath,
		$SummaryLogFile
		)

		function Write-Summary{
			param($Message)

				Resume-Logging $SummaryLogFile

				Write-Host $Message

				Suspend-Logging $SummaryLogFile
			}

        $exitCode = 0

		$machineLog = Register-LogFile -Path $MachineLogPath
		$SummaryLogFile = Register-LogFile -InputObject $SummaryLogFile -NoLog
		Suspend-Console

		try{
			Write-Host2 "Write $Count before sleep"
			Start-Sleep 2
			Write-Host2 "Write to Machine $Count log only"
			Start-Sleep 6
			Write-Host2 -Type Success
			Write-Summary "Test Summary $Count"
		}
		catch{
			Write-Host "Error occurred"
			Write-Error -ErrorRecord $_
		}
		finally{
			$machineLog,$SummaryLogFile | Unregister-LogFile
		}

        if($LASTEXITCODE -ne 0)
        {
            $exitcode = 6
        }

        # Return the result fo deploying this machine
        return New-Object PSObject -Property @{
            exitCode = $exitcode
        }
    }


	for ($i=1; $i -le $numOfThreads; $i++) {
		$machineLog = "Machine$i.log"

		$Job = [powershell]::Create().AddScript($InnerBlock)
		$Job = $Job.AddParameter("Count", $i)
        $Job = $Job.AddParameter("MachineLogPath", $machineLog)
		$Job = $Job.AddParameter("SummaryLogFile", $logFile1)

		$Job.RunspacePool = $RunspacePool

		$Jobs += New-Object PSObject -Property @{
            Pipe = $Job
			Log = $machineLog
            Result = $Job.BeginInvoke()
			LogProcessed = $false
			JobId = $i
        }
	}


	try{

	$i = 0
	$parentPct = 0

		do{

			$i = $i+1

			if($i -gt 99){
				$i = 1
			}



			$parentPct = $parentPct + 10

			if($parentPct -gt 100){
				$parentPct = 10
			}

			Start-Sleep -s 2

			$complete = $true



			Write-Progress -Id 0 -Activity "Deploying across all servers" -PercentComplete $parentPct

			$jobs | % {



				if(!$Job.LogProcessed) {

					if($_.Result.IsCompleted) {
						#$machineName = $Job.MachineName
						$machineLog = Get-Content $_.Log

						#Resume-Logging $logFile1

						#Write-Host2 $machineLog

						#$machineLog | Out-String -Stream | Write-Host2 -NoConsole

						#Suspend-Logging $logFile1

						$_.LogProcessed = $true
						$result = $_.Pipe.EndInvoke($_.Result)
						if($result.exitCode -ne 0)
						{
							$global:exitcode = 7
						}
						Write-Summary "Test Summary Exit code $($result.exitCode)"
						$_.Pipe.Dispose()
						Write-Progress -Id $_.JobId -ParentId 0 -Activity "Deploying to server $($_.JobId)" -Completed
					}
					else
					{
						Write-Progress -Id $_.JobId -ParentId 0 -Activity "Deploying to server $($_.JobId)" -PercentComplete ($i)
						$complete = $false
					}
				}
			}

		}while(!$complete)


		Write-Progress -Id 0 -Activity "Processing items in $SiteUrl" -Completed

		Write-Host ""

	}
	finally{
		$RunspacePool.Close()
		Resume-Logging $logFile1
	}

}


$logFile1 = Register-LogFile -Path Test1.log -WithHeader -LogTimestamp

Write-Host "Writing with native Write-Host"

Write-Host2 "Wrting to log & console"
Write-Host2 "Writing to log file only" -NoConsole
Write-Host2 "Writing to console only" -NoLog


#Suspend-Console
#Write-Host "Writing to Log Only"
#Resume-Console

Test-Runspace

Write-Host "Logging to console yet again."
Write-Host2 -Type Success -Message "Testy"

$logFile1 | Unregister-LogFile
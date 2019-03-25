function Write-Summary{
			param(
			[parameter(Mandatory=$true, Position=0)][string]$Message,
				[TimeSpan]$Elapsed,
				[switch] $NoSuspend,
				[switch] $Failed
			)
				#Resume-Logging $logFile1


				#TODO:Need a way of being able to target which logs we ignore runspace on, rather than all.
				#we could change the -IngoreRunspace swith to take a list of logs instead
				#and store the ignore runspace setting at a log level instead.
				#The problem here is timing.  We could turn this off here, and then it could overlap
				#with a call from the outer script?


				#---Update. We should not call Write-Summary from inner script
				#but instead handle it in the outer loop, that way runspace is not an issue.
				#just means we need to handle it twice
				if($Failed){
					Write-Host2 -Type Failure -Message $Message -Prefix "Unsuccessfully "-Elapsed $Elapsed
				}
				else{
					Write-Host2 -Type Success -Message $Message -Prefix "Successfully " -Elapsed $Elapsed
				}

				#if(-not $NoSuspend){
				#	Suspend-Logging $logFile1
				#}
			}

function Test-Runspace {
param()
$numOfThreads = 5

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

		$machineLog = Register-LogFile -Path $MachineLogPath -Append #-NoConsole
		$SummaryLogFile = Register-LogFile -InputObject $SummaryLogFile -NoLog #-NoConsole
		#Suspend-Console

		Write-Error2 "Some error"

		try{
			Write-Host "Write $Count before sleep"
			Start-Sleep 2
			Write-Host "Write to Machine $Count log only"
			Start-Sleep 2
			Write-Warning "This is a warning"
			Write-Host2 -Type Failure -Message "Bum"
			#throw "An error has occurred"
			Write-Host2 -Type Success
			Write-Host "Before Summary"
			Write-Summary "Test Summary $Count"
			Write-Host "After Summary"
			Write-Host "Before Header"
			Write-Header "Test header" -AsSubHeader
			Write-Host "After Header1"
			Write-Host "After Header2"
			Write-Host "After Header3"
			Write-Summary "Test Summary $Count"
			Write-Header "Test header" -AsSubHeader
		}
		catch{
			Write-Error2 -ErrorRecord $_
			$exitCode = 1
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

		$powershell = [powershell]::Create().AddScript($InnerBlock)
		$powershell = $powershell.AddParameter("Count", $i)
        $powershell = $powershell.AddParameter("MachineLogPath", $machineLog)
		$powershell = $powershell.AddParameter("SummaryLogFile", $logFile1)
		#$powershell = $powershell.AddCommand("Out-Default")
		#$powershell.Commands.Commands[0].MergeMyResults("Error", "Output")

		$powershell.RunspacePool = $RunspacePool

		$Jobs += New-Object PSObject -Property @{
            Pipe = $powershell
			Log = $machineLog
            Result = $powershell.BeginInvoke()
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


$logFile1 = Register-LogFile -Path Test1.log -WithHeader
$logFile2 = Register-LogFile -Path Test2.log -LogTimestamp

Write-Host "Writing with native Write-Host"
Write-Warning "This is a warning"
Write-Error "This is an error"

#1,2,3,4,5,6,7,8,9,10 | ForEach-Object {

#	if($_ -eq 7){
#		Write-Error "Errored on 7"
#		return
#	}

#	Write-Host2 "This is line $_" -CacheLog
#}

#Write-Host2 "Now finished."

#Write-Error "String Test"
#Write-Error2 "String Test2"

#$E = [System.Exception]@{$e = [System.Exception]@{Source="Get-ParameterNames.ps1";HelpLink="http://go.microsoft.com/fwlink/?LinkID=113425"}}
#Write-Error2 -Exception $E -Message "Files not found. The $Files location does not contain any XML files."

#Remoting Error testing

$func = {

	Import-Module TFL.PowerShell.Logging

	$temp = @{
	'Server' = $env:COMPUTERNAME;
	'ExitCode' = 0;
}

	try{
		Write-Host "In Remote"
		Start-Sleep -Seconds 2

		$result = 0/0
	}
	catch{


		Write-Error2 -ErrorRecord $_ -ErrorMessage "An error occurred in Testing1.Remote.ps1."

		$temp.ExitCode = 1
		$temp.Error = "An error occurred in Testing1.Remote.ps1."
		$temp.LastExitCode = $LASTEXITCODE
		$global:LASTEXITCODE = $null
	}

	[pscustomobject]$temp
}

$output = Invoke-Command -ComputerName "ftDC2mgt001" -ScriptBlock $func

Write-Host2 -Type Failure -Message "Failed to do stuff remotely"

#if($output.ErrorDetail){
#	($output.ErrorDetail) | Write-Error2 -ErrorMessage $output.Error
#}

#try{
#	Write-Host "In try block2"
#	throw "My error"
#}
#catch{
#	Write-Error2 -ErrorRecord $_
#}

#Write-Host "Wrting to log & console"
#Write-Host2 "Writing to log file only" -NoConsole
#Write-Host2 "Writing to console only" -NoLog

#Disable-LogTimestamp

#$temp1 = @{"A"="1";"B"="2";"C"="3"}
#$temp2 = @((New-Object PSObject -Property $temp1))

#$temp2 | fl A,B,C
#$temp2 | fl A,B,C | Out-String -stream | Write-Host2 -ForegroundColor Magenta

#Write-Host "Write Host Test"
#Write-Host "dd" -NoNewline
#Write-Output "This is output test"

#$timer = [Diagnostics.Stopwatch]::StartNew()

#Enable-LogTimestamp

#Suspend-Logging $logfile2

#Write-Error "Some random error"

#Write-Host2 -Type Success -Message "Not writing to LogFile2"
#Write-Host2 -Type Progress -Message "This is my progress" -Prefix "Hello" -ForegroundColor DarkYellow

#Resume-Logging $logfile2

#Write-Host "Writing to both logs files after resuming logging"
#Write-Header "This is a sub header" -AsSubHeader

#Suspend-Console
#Write-Host "Writing to Log Only"
#Resume-Console

#$timer.Stop()

#$result = 0

#Write-Host2 "Timer Test1" -Elapsed $timer.Elapsed
#Write-Host2 -Type Success -Message "Timer Test2" -Elapsed $timer.Elapsed

#Write-Summary "SummaryTest1" -Elapsed $timer.Elapsed -Failed:($result -gt 0)

#$result = 1

#Write-Summary "SummaryTest2" -Elapsed $timer.Elapsed -Failed:($result -gt 0)

#Test-Runspace | Out-Null



Write-Host "Logging to console yet again."
Write-Host2 -Type Success

$logFile1,$logFile2 | Unregister-LogFile
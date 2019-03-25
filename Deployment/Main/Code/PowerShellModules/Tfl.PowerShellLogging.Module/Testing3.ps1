Import-Module PoshRSJob

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

	$Test = 42
	1..5|Start-RSJob -Name {"TEST_$($_)"} -ModulesToImport "PowerShellLogging" -ScriptBlock {
		Param($Object)

		#$machineLog = Register-LogFile -Path "Machine$Object.log"

		$DebugPreference = 'Continue'
		$PSBoundParameters.GetEnumerator() | ForEach {
			Write-Debug $_
		}

		Write-Host "Doing some stuff"
		#Write-Error "An error stuff"

		Write-Verbose "Creating object" -Verbose
		New-Object PSObject -Property @{
			Object=$Object
			Test=$Using:Test
		}

		#Unregister-LogFile $machineLog
	} | Wait-RSJob | Receive-RSJob
}


$logFile1 = Register-LogFile -Path Test1.log -WithHeader
$logFile2 = Register-LogFile -Path Test2.log -LogTimestamp

Write-Host "Writing with native Write-Host"

Write-Host "Wrting to log & console"
Write-Host2 "Writing to log file only" -NoConsole
Write-Host2 "Writing to console only" -NoLog

Disable-LogTimestamp

$temp1 = @{"A"="1";"B"="2";"C"="3"}
$temp2 = @((New-Object PSObject -Property $temp1))

$temp2 | fl A,B,C
$temp2 | fl A,B,C | Out-String -stream | Write-Host2 -ForegroundColor Magenta

Enable-LogTimestamp

Suspend-Logging $logfile2

Write-Error "Some random error"

Write-Host2 -Type Success -Message "Not writing to LogFile2"
Write-Host2 -Type Progress -Message "This is my progress" -Prefix "Hello" -ForegroundColor DarkYellow

Resume-Logging $logfile2

Write-Host "Writing to both logs files after resuming logging"
Write-Header "This is a sub header" -AsSubHeader

Suspend-Console
Write-Host "Writing to Log Only"
Resume-Console

Test-Runspace

Write-Host "Logging to console yet again."
Write-Host2 -Type Success

$logFile1,$logFile2 | Unregister-LogFile
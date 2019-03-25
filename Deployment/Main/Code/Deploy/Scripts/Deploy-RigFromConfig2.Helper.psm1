function Write-Summary{
[cmdletbinding()]
param(
	[parameter(Mandatory=$true, Position=0, ValueFromPipeline="true")]
	[AllowNull()]
	[TFL.PowerShell.Logging.LogFile]$SummaryLog,
	[parameter(Mandatory=$true)][string]$Message,
	[parameter()][TimeSpan]$Elapsed,
	[parameter()]$ScriptResult,
	[parameter()]
	[switch] $NoSuspend
)
	$failed = $false

	if($SummaryLog){
		Resume-Logging $SummaryLog
		Resume-Console
	}

	if(($ScriptResult -and $ScriptResult -is [system.array]) -or $ScriptResult -ne 0){
		$failed = $true

		if($ScriptResult -is [system.array]){
			Write-Host "Results returned an array:"
			$ScriptResult | ForEach-Object {
				Write-Host "$_"
			}
		}
	}

	if($failed){
		Write-Host2 -Type Failure -Message $Message -Elapsed $Elapsed
	}
	else{
		Write-Host2 -Type Success -Message $Message -Elapsed $Elapsed
	}

	if($SummaryLog){
		if(-not $NoSuspend){
			Suspend-Logging $SummaryLog
			if(!$LocalDebug){
				Suspend-Console
			}
		}
	}
}
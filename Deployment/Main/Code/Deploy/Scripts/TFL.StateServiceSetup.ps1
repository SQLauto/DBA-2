[cmdletbinding()]
param
(
	[parameter(Mandatory=$true)][string]$ComputerName,
    [Deployment.Domain.Roles.AspNetStateServiceDeploy]$DeployRole
)

Write-Host ""
Write-Header "Starting role $DeployRole on $ComputerName." -AsSubHeader
$timer = [Diagnostics.Stopwatch]::StartNew()

$result = 0
try
{
	Write-Host  "Starting ASP.Net State Service"
	$result = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
		$result = 0
		try{
			$service = Get-Service -Name "aspnet_state" -ErrorAction Ignore

			if(!$service){
				Write-Warning "Expected aspnet_state service was not found on $ComputerName"
				return 1
			}

			$service | Set-Service -StartupType Automatic -PassThru | Start-Service
			#Wait for upto 20 secs for service to come up
			Get-Service -Name "aspnet_state" | % { $_.WaitForStatus('Running', '00:00:20') | Out-Null }

			if($LASTEXITCODE -and $LASTEXITCODE -ne 0){
				Write-Warning "Starting aspnet_state on $ComputerName had last exit code of [$lastexitcode]"
				$result = 1
			}
		}
		catch{
			$result = 1
		}

		$result
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
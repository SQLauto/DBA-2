[cmdletbinding()]
param
(
    [parameter(Mandatory=$true)][string] $ComputerName,
    [Deployment.Domain.Roles.SsisSetup]$DeployRole
)


function Invoke-SsisSetup{
param()

	$retVal = 0

	$dataSource = Get-Datasource -ComputerName $ComputerName -InstanceName $DeployRole.SsisDbInstance

	$connectionString = Get-ConnectionString -DataSource $dataSource -TargetDatabase "master"

	Write-Host "Setting up SSISDB with connection string: $connectionString"

	Start-SsisSetup -ConnectionString $connectionString -SsisDatabase "SSISDB" -Password "Br1tneyX"

	$retVal
}

$result = 0

Write-Host ""
Write-Header "Starting role $DeployRole on $ComputerName." -AsSubHeader
$timer = [Diagnostics.Stopwatch]::StartNew()

$local = $ComputerName -in $env:computername,"localhost"

try {
	$result = Invoke-SsisSetup
}
catch [System.Exception] {
	Write-Error2 -ErrorRecord $_
	$result = 1
}

$timer.Stop()
$SummaryLog | Write-Summary -Message "running role $DeployRole on $ComputerName."  -Elapsed $timer.Elapsed -ScriptResult $result
Write-Header "Ending role $DeployRole on $ComputerName" -AsSubHeader

$result
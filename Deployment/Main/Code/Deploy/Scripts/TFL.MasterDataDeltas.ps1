[cmdletbinding()]
param
(
    [parameter(Mandatory=$true, Position=0)]
	[ValidateNotNullOrEmpty()]
	[string] $ComputerName,
	[Deployment.Domain.Roles.MasterDataDeltas]$DeployRole
)

function Copy-Assets{
[cmdletbinding()]
param()

	$retVal = 0

	$sourceSubsystem = Join-Path $DeployRole.Source $DeployRole.SubSystem

	# MasterData Assets always needs to go in D:\FMJTAssets on the targeted host
    $targetHost = "\\$ComputerName\$DriveLetter`$\FMJTAssets"
    $targetSubSystem = Join-Path $targetHost $DeployRole.SubSystem

	#Create the subsystem folder structure on a host deploying for the first time
    if (!(Test-Path $targetSubsystem)){
		Write-Host "Path $targetSubsystem does not exist. Creating."
    	New-Item -ItemType Directory -Path $targetSubSystem -Force | Out-Null
    }

	$rootPath = Join-Path $dropFolder $sourceSubsystem

	if(!(Test-Path $rootPath)){
		Write-Host2 -Type Failure -Message "Source RootPath $rootPath does not exist. Please verify Deployment Config."
		$retVal = 1
		return $retVal
	}

    Write-Host "Adding and removing DayKkeys deltas from $rootPath to $targetSubsystem"

	#Delete all sub folders under FmjtAssets
	Write-Host "Removing all Assets from $targetSubsystem"
	Get-ChildItem -Path $targetSubsystem | Remove-Item -Recurse -Force

	$DeployRole.Daykeys | ForEach-Object {
		$dayKey = $_

		$targetDaykeyDelta = Join-Path $targetSubsystem $dayKey
		$sourcePath = Join-Path $rootPath $dayKey

		if(!(Test-Path $sourcePath)) {
			Write-Host2 -Type Failure -Message "SourceFile $sourcePath does not exist. Please verify Deployment Config."
			$retVal = 1
			return
		}

		if(!(Test-Path $targetDaykeyDelta)) {
			Write-Host "Target Daykey Folder $targetDaykeyDelta does not exist. Creating directory."
			New-Item -Type Directory -Path $targetDaykeyDelta -Force | Out-Null
		}

		Write-Host "Adding DayKey Asset $targetDaykeyDelta"

		Copy-Item -Path $sourcePath -Destination $targetSubsystem -Force -Recurse -ErrorAction Stop
	}

	$retVal
}


$result = 0

Write-Host ""
Write-Header "Starting $($DeployRole) on $ComputerName" -AsSubHeader
$timer = [Diagnostics.Stopwatch]::StartNew()

try {
	$result = Copy-Assets
}
catch [System.Exception] {
	Write-Error2 -ErrorRecord $_
	$result = 1
}

$timer.Stop()

$SummaryLog | Write-Summary -Message "running role $DeployRole on $ComputerName."  -Elapsed $timer.Elapsed -ScriptResult $result
Write-Header "Ending role $DeployRole on $ComputerName" -AsSubHeader
$result
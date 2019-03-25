#Requires -Version 5.0
<#
.SYNOPSIS

.PARAMETER DeploymentConfig
    The name of the deployment configuration file used to drive the deployment.
.PARAMETER Groups
    An array of group names to limit what deployment groups should be deployed
.PARAMETER Machines
    An array of server names to that will be used to filter the deployment target machines.
.PARAMETER DeploymentLogFolder
    The name of the folder where the File Versions report will be created.
#>
[cmdletbinding()]
param(
	[parameter(Mandatory=$true, Position=0)]
	[ValidateNotNullOrEmpty()]
	[string]$DeploymentConfig,
	[string[]]$Groups,
	[string[]]$Machines,
	[parameter()]
	[alias("DeploymentLogFolder")]
	[string]$FileVersionFolder,
	[switch]$NoDisplay
	)

$configFullPath = Join-Path $PSScriptRoot $DeploymentConfig

if (!(Test-Path $configFullPath)) {
	Write-Error "The specified Deployment Configuration cannot be found. Please check your deployment setup. Unable to find: $configFullPath"
	return 11
}

Import-Module TFL.PowerShell.Logging -Force
Import-Module Tfl.Utilities -Force -ErrorAction Stop
Import-Module Tfl.Deployment -Force -ErrorAction Stop

function Get-ReportLog{
param(
	[string]$Prefix,
	[string]$Filename = "FileVersions.Report",
	[string]$Extension = "log"
)
	$logname = "{0}.{1}_{2}.{3}" -f $Prefix, $Filename, (Get-Date -Format yyyyMMdd), $Extension
	$path = Join-Path $FileVersionFolder $logname

	$path
}

function Assert-OutputFile{
[cmdletbinding()]
param(
	[string]$ReportName,
	[string]$Source
)
	$results = @{}
	$valid = $true

	$reportFile = Get-ReportLog -Prefix $ReportName
	$reportLog = $reportFile | Register-LogFile

	try{
		$file = Import-Csv $Source

		$results = $file | Where-Object {$_.Directory} | ForEach-Object {

			$temp = 0
			$key = Join-Path $_.Directory $_.AssemblyName

			if($results.ContainsKey($key)){
				$current = $results[$key]

				$diff = Compare-Object -ReferenceObject $current -DifferenceObject $_ -Property 'Version','FileSize'

				if($diff){
					Write-Host2 'Assembly mis-match found between servers' -NoConsole -CacheLog
					$current,$_ | Select-Object "MachineName","Directory","AssemblyName","Version","FileSize" | Format-Table | Out-String | Write-Host2 -NoConsole -CacheLog
					$temp = 1
				}
			}
			else{
				$results.Add($key, $_)
			}

			$temp
		}

		#Must keep in order to flush out cached logging in loop above.
		Write-Host2 "" -NoConsole

		$retVal = ($results | Measure-Object -Maximum).Maximum
	}
	finally{
		$reportLog | Unregister-LogFile
	}

	$valid = $retVal -eq 0

	if(!$valid -and !$NoDisplay){
		Open-File $reportFile
	}

	$valid,$results
}

function Write-FileVersion{
[cmdletbinding()]
param(
	[Parameter(Mandatory=$true)][string]$File,
	[Parameter(Mandatory=$true)][string[]]$Message,
	[Parameter(Mandatory=$false)][PsObject[]]$FileInfo = $null
)
	$Message | Write-File -File $File

	if($FileInfo){
		$FileInfo | Select-Object MachineName,Directory,AssemblyName,Version,FileSize | Write-File -File $File
	}
}

function Get-DeploymentInfo{
[cmdletbinding()]
param()

	$dropFolder = $deploymentFolder | Split-Path
	$groupsPath = Join-Path $deploymentFolder "Groups"

	#Get base deployment object first, do not filter until we know we are good to go.
    $baseDeployment = Get-Deployment -Path $dropFolder -Configuration $DeploymentConfig

	$groupsFile = Join-Path $groupsPath "DeploymentGroups.$($baseDeployment.ProductGroup).xml"

	#Get and validate Group filters (includes & excludes)
	$groupsFilters = Get-DeploymentGroupFilters -Groups $Groups -Path $groupsFile

	if(-not $groupsFilters){
		Write-Host2 -Type Failure -Message "Unable to validate groups for ProductGroup $ProductGroup"
		return $null
	}

	#filter deployment object accordingly
	$deployment = $baseDeployment | Get-Deployment -Groups $groupsFilters -Machines $Machines

	$deployment
}

function Start-GetFileVersions{
[cmdletbinding()]
param()

	$retVal = 0
	$results = @{}

	$deployment = Get-DeploymentInfo

	$webDeployments = Get-WebDeployments -InputObject $deployment

	Write-Host "Getting file versions for web deployments"
	$webDeployments.Machines | ForEach-Object {
		$machine = $_

		Write-Host2 "Getting file versions for server $($machine.Name)"

		[array]$paths = $machine.DeploymentRoles | Select-Object @{Name="Path"; Expression={$_.Site.PhysicalPath}} | Select-Object -ExpandProperty Path | Where-Object {$_ -notlike '*Mock*'} | Sort-Object -Unique

		if(!(Test-IsNullOrEmpty $paths) ) {

			$item = $results.GetEnumerator() | Where-Object { Compare-Array $_.Key $paths }

			if($item){
				$value = $item.value
				$value+=$machine.Name
				$results[$item.key] = $value
			}
			else{
				$results.Add($paths, @($machine.Name))
			}
		}
	}

	$fileInfo = $results.GetEnumerator() | ForEach-Object {
		Get-FileInfo -ComputerName $_.Value -Path $_.Name | Sort-Object -Property MachineName
	}

	$results = @{}
	$serviceDeployments = Get-ServiceDeployments -InputObject $deployment

	Write-Host "Getting file versions for service deployments"

	$serviceDeployments.Machines | ForEach-Object {
		$machine = $_

		Write-Host2 "Getting file versions for server $($machine.Name)"

		[array]$paths = $machine.DeploymentRoles.MsiDeploy | Select-Object @{Name="Path"; Expression={$_.InstallationLocation}} | Select-Object -ExpandProperty Path | Sort-Object -Unique

		if(!(Test-IsNullOrEmpty $paths) ) {

			$item = $results.GetEnumerator() | Where-Object { Compare-Array $_.Key $paths }

			if($item){
				$value = $item.value
				$value+=$machine.Name
				$results[$item.key] = $value
			}
			else{
				$results.Add($paths, @($machine.Name))
			}
		}
	}

	$fileInfo = $fileInfo + ($results.GetEnumerator() | ForEach-Object {
		Get-FileInfo -ComputerName $_.Value -Path $_.Name | Sort-Object -Property MachineName
	})

	if(Test-IsNullOrEmpty $fileInfo){
		Write-Warning "No web, service or Msi deployed files were found for the environment."
		return $retVal
	}

	$outputFile = Get-ReportLog -Prefix $deployment.Name -FileName "FileVersions" -Extension "csv"

	$fileInfo | Select-Object MachineName,Directory,AssemblyName,CreatedTimeStamp,ModifiedTimeStamp,Version,FileSize | Sort-Object MachineName,Directory,AssemblyName | Export-Csv $outputFile -NoTypeInformation

	Write-Host2 -Type Success -Message "File $outputFile was successfully created."
	Write-Host "Validating generated file versions file."

	$result = Assert-OutputFile -ReportName $deployment.Name -Source $outputFile

	if(!($result[0])){
		Write-Warning "File version comparison across $($deployment.Name) servers has differences."
		$retVal = 1
		return $retVal
	}

	Write-Host2 -Type Success -Message "Get file versions now completed."

	$retVal
}

$result = 0

$deploymentFolder = ($PSScriptRoot | Split-Path)

$rootDrive = [System.IO.Path]::GetPathRoot($PSScriptRoot)

if(!$DeploymentLogFolder){
	$DeploymentLogFolder = Join-Path $rootDrive "Deploy\Logs"
}

try{
	$result = Start-GetFileVersions
	Write-Host2 -Type Success
}
catch{
	Write-Error -ErrorRecord $_
	Write-Host2 -Type Failure
}

Remove-Module TFL.PowerShell.Logging
Remove-Module Tfl.Deployment
Remove-Module Tfl.Utilities

$result
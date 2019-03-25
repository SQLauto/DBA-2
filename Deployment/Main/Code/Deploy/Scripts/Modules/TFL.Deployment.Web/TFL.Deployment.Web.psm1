filter Select-AppPool($pools) {$_ | Where-Object {($null -eq $pools -or $pools.Count -eq 0) -or ($_.name -in $pools)}}
filter Select-Stopped {$_ | Where-Object {$_.state -eq 'Stopped'}}
filter Select-Started {$_ | Where-Object {$_.state -eq 'Started'}}
function Wait-StartWebAppPool{
[CmdletBinding()]
<#
.SYNOPSIS
    A Wait loop to wait for starting of Web App Pools.
.DESCRIPTION

.EXAMPLE

.PARAMETER AppPool
    An array of AppPool objects which to await.
#>
Param(
	[Parameter(Mandatory=$true,ValueFromPipeline=$true)][ValidateNotNull()] $AppPool
)
	PROCESS{

		$AppPool | ForEach-Object {

			$name = $_.name

			$state = Get-WebAppPoolState $name
			$retry = 0

			while($state.value -ne "Started" -and $retry -lt 15){
				Start-Sleep -Milliseconds 1000
				$state = Get-WebAppPoolState $name
				$retry++
			}

			$state = Get-WebAppPoolState $name

			if($state.value -ne "Started"){
				throw "Error starting the web app pool $name"
			}
		}
	}
}

function Wait-StopWebAppPool{
[CmdletBinding()]
<#
.SYNOPSIS
    A Wait loop to wait for stopping of Web App Pools.
.DESCRIPTION

.EXAMPLE

.PARAMETER AppPool
    An array of AppPool objects which to await.
#>
Param(
	[Parameter(Mandatory=$true,ValueFromPipeline=$true)][ValidateNotNull()] $AppPool
	)
	PROCESS{

		$AppPool | ForEach-Object {

			$name = $_.name

			$state = Get-WebAppPoolState $name
			$retry = 0

			while($state.value -ne "Stopped" -and $retry -lt 15){
				Start-Sleep -Milliseconds 1000
				$state = Get-WebAppPoolState $name
				$retry++
			}

			$state = Get-WebAppPoolState $name

			if($state.value -ne "Stopped"){
				throw "Error stopping the web app pool $name"
			}
		}
	}
}
function Stop-AppPools {
[CmdletBinding()]
param(
	[Parameter(Mandatory = $false)][string[]]$Pool
)

	$current = Get-ChildItem IIS:\AppPools | Select-AppPool $Pool
	$currentInfo = $current | Select-Object Name,State

	$current | Select-Started | Stop-WebAppPool
	$current | Wait-StopWebAppPool | Out-Null

	$after = Get-ChildItem IIS:\AppPools | Select-AppPool $Pool

	$after | ForEach-Object {
		$item = $_
		$temp = $currentInfo | Where-Object {$_.Name -eq $item.Name} | Select-Object -First 1

        [pscustomobject] @{
            Name     = $item.Name
            Previous = $temp.State
            Current  = $item.State
        }
    }
}
function Start-AppPools {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false)][string[]]$Pool
	)

	$current = Get-ChildItem IIS:\AppPools | Select-AppPool $Pool
	$currentInfo = $current | Select-Object Name, State

	$current | Select-Stopped | Start-WebAppPool
	$current | Wait-StartWebAppPool | Out-Null

	$after = Get-ChildItem IIS:\AppPools | Select-AppPool $Pool

	$after | ForEach-Object {
		$item = $_
		$temp = $currentInfo | Where-Object {$_.Name -eq $item.Name} | Select-Object -First 1

		[pscustomobject] @{
			Name     = $item.Name
			Previous = $temp.State
			Current  = $item.State
		}
	}
}

function Start-WebsiteAndAppPool{
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$true)][string][ValidateNotNull()] $SiteName,
	[Parameter(Mandatory=$true)][string][ValidateNotNull()] $PoolName
)
	PROCESS{

		$websiteState = (Get-WebsiteState -Name $SiteName).Value

		if ($websiteState -eq 'Stopped') {
			Write-Host "Starting Site $SiteName"
			Start-Website -Name $SiteName
		}
		else {
			Write-Host "Site $SiteName is already started"
		}

		$websiteState = (Get-WebsiteState -Name $SiteName).Value

		if ($websiteState -eq 'Stopped'){
			throw "Unable to start WebSite $SiteName. Check another site is not running on the same port."
		}

		Write-Host "Starting AppPool $PoolName"

		$result = Start-AppPools $PoolName

		Write-Host "App Pools state is now: $($result.State)"
	}
}

function Start-Websites {
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
	[string[]][ValidateNotNullOrEmpty()] $SiteName
)
	$SiteName | ForEach-Object {
		$currentState = (Get-WebsiteState -Name $_).Value

		if ($currentState -eq 'Stopped') {
			Start-Website -Name $_
		}

		$websiteState = (Get-WebsiteState -Name $_).Value

		if ($websiteState -eq 'Stopped'){
			throw "Unable to start WebSite $($_). Check another site or process is not running on the same port."
		}

		[pscustomobject] @{
			Site = $_
			Previous = $currentState
			Current = $websiteState
		}
	}
}

function Stop-Websites {
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
	[string[]][ValidateNotNullOrEmpty()] $SiteName
)
	$SiteName | ForEach-Object {
		$currentState = (Get-WebsiteState -Name $_).Value

		if ($currentState -eq 'Started') {
			Stop-Website -Name $_
		}

		$websiteState = (Get-WebsiteState -Name $_).Value

		if ($websiteState -eq 'Started'){
			throw "Unable to stop WebSite $($_)."
		}

		[pscustomobject] @{
			Site = $_
			Previous = $currentState
			Current = $websiteState
		}
	}
}

function Get-WebSiteInfo {
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$true)] [string[]]$ComputerName
	)
	PROCESS{

		$func = {
			$temp = @{
				'Server' = $env:COMPUTERNAME;
				'ExitCode' = 0
			}

			try{

				Import-Module WebAdministration -Force -ErrorAction Stop

				$appPools = Get-ChildItem IIS:\AppPools | Select-Object Name,State,@{Name="Count"; Expression={'0'}},@{Name="Apps"; Expression={[array]$null}},@{Name="Sites"; Expression={[array]$null}}

				$appPools | ForEach-Object {
					$pn = $_.Name
					[array]$sites = (get-webconfigurationproperty "/system.applicationHost/sites/site/application[@applicationPool='$pn' and @path='/']/parent::*" machine/webroot/apphost -name name) | Select-Object -ExpandProperty Value
					[array]$apps = (get-webconfigurationproperty "/system.applicationHost/sites/site/application[@applicationPool='$pn' and @path!='/']" machine/webroot/apphost -name path) | Select-Object -ExpandProperty Value
					$_.Count = $sites.Count + $apps.Count
					$_.Apps = $apps
					$_.Sites = $sites
				}

				$webSites = Get-ChildItem IIS:\Sites | Select-Object ID, Name, State, PhysicalPath, @{Name="LogFilePath";Expression={$_.LogFile.directory}},@{Name="AppPool"; Expression={$null}}

				$webSites | ForEach-Object {
					$sn = $_.Name
					$pool = $appPools | Where-Object {$_.Sites -contains $sn}
					$_.AppPool = $pool.name
				}

				$temp.Sites = $webSites
				$temp.AppPools = $appPools
			}
			catch{
				$temp.ExitCode = 1
				$temp.Error = "Error getting web site data on server"
				$temp.ErrorDetail = $_
			}

			[pscustomobject]$temp
		}

		if ($ComputerName[0] -eq $env:COMPUTERNAME -or $ComputerName[0] -eq 'localhost') {
			$output = & $func
		}
		else {
			try{
				$sessions = $ComputerName | New-PSsession
				$output = Invoke-Command -Session $sessions -ScriptBlock $func
			}
			finally{
				Remove-PSSession $sessions -ErrorAction Continue
			}
		}

		$output
	}
}

function Get-WebPackageVersion {
	[CmdletBinding()]
	<#
	.SYNOPSIS
		Returns the version number of a given assembly from a web package.
	.DESCRIPTION

	.EXAMPLE
		PS> Get-WebPackageVersion -PackagePath "D:\TFL\CASC\" -AssemblyName "SomeAssemlby.dll"
	.PARAMETER PackagePath
		The Path to the package containing the assembly from which we will obtain the version.
	.PARAMETER AssemblyName
		The name of the assembly from which to obtain the version.
	#>
	param([string]$PackagePath, [string]$AssemblyName)

		#Load Compression Assemblys
		Add-Type -As System.IO.Compression.FileSystem;

		#Read WebPackage Contents
		$archive = [System.IO.Compression.ZipFile]::OpenRead($packagePath)
		try {
			#Look in Archive Entries for DLL
			foreach($archiveEntry in $archive.Entries)
			{
				#If we find the dll
				if($archiveEntry.FullName -match $assemblyName)
				{
					#Create a temp file for use
					$tempFile = [System.IO.Path]::GetTempFileName();
					try {
						#Extract the DLL and get the version number
						[System.IO.Compression.ZipFileExtensions]::ExtractToFile($archiveEntry, $tempFile, $true);
						$versionInfo = [Reflection.Assembly]::UnsafeLoadFrom($tempFile).GetName().Version
						$version = "$($versionInfo.Major).$($versionInfo.Minor).$($versionInfo.Build).$($versionInfo.Revision)"
						break
					}
					finally {
						#Remove Temp File
						Remove-Item $tempFile -Force
					}
				}
			}
		}
		finally {
			#Close WebPackage read to stop memory leak
			$archive.Dispose();
		}

		#Return version number
		$version
	}
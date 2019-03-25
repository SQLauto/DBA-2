[cmdletbinding()]
param(
	[parameter(Mandatory=$true, Position=0)]
	[ValidateNotNullOrEmpty()]
	[ValidateScript({Test-Path $_})]
	[string]$Path,
	[string]$TargetModulePath = "D:\TFL\PowerShell\Modules",
	[string[]]$ExcludeList = @('TFL.Deployment.Database.Local','TFL.Deployment.Azure','TFL.Deployment.VCloud','TFL.Deployment.Azure.Utilities')
)

function Update-LocalModules{
[cmdletbinding()]
param()

	$retVal = 0

	Write-Host "Copying PowerShell modules to module path."

	$script:modulePath = $targetModulePath

	if(!(Test-Path $targetModulePath)) {
		Write-Host "Creating target module path at $targetModulePath"
		New-Item -ItemType Directory -Path $targetModulePath -Force | Out-Null
	}

	Write-Host "Temporary deployment folder set to $Path"

	$scriptsFolder = Join-Path $Path "Deployment\Scripts"
	$tempModulePath = Join-Path $scriptsFolder "Modules"

	$moduleFolders = Get-ChildItem -Path $tempModulePath -Directory | Where-Object {$_.Name -notin $ExcludeList}

	#Determine the packaged module version, and use that to validate current version
	#and we will update to that version accordingly.
	$moduleFolders | ForEach-Object {
		$childFolder = $_
		$children = Get-ChildItem $childFolder.FullName -Recurse
		$names = $children | Select-Object -ExpandProperty name

		if($names -contains 'lib'){
			$targetRoot = Join-Path $targetModulePath $childFolder.Name

			if(Test-Path $targetRoot) {
				#try to clean up any older version. We will get a list of sub-folders under the $targetRoot
				#and order them accordingly, and remove all bar the latest.
				$toKeep = [array](Get-ChildItem -Path $targetRoot -Directory | Sort-Object -Property "Name" -Descending | Select-Object -ExpandProperty Name -First 1)
				Write-Host "Attempting to remove old module folders for $targetRoot"
				Get-ChildItem -Path $targetRoot -Directory | Where-Object {$_.Name -notin $toKeep} | Remove-Item -Force -ErrorAction Ignore -Recurse
			}

			$expectedVersion = $children | Where-Object {$_.Name -eq "Deployment.Common.dll"} | Select-Object -ExpandProperty VersionInfo | Select-Object -ExpandProperty FileVersion

			$target = Join-Path $targetRoot $expectedVersion

			if(Test-Path $target){
				Write-Host "Target module path $target already exist. Nothing to update."
				return
			}

			$manifest = Get-ChildItem $childFolder.FullName -Recurse -Filter *.psd1 | Select-Object -First 1

			Update-ModuleManifest -Path $manifest.FullName -ModuleVersion $expectedVersion -FunctionsToExport '*' -CmdletsToExport '*'
		}
		else{
			$target = $targetModulePath
		}

		Write-Host "Copying PowerShell Modules to local module path $target."
		$childFolder | Copy-Item -Destination $target -Force -Recurse
	}

	Push-Location $scriptsFolder
	$command = ".\Set-EnvironmentModulePath.ps1 -ModulePath $TargetModulePath"
	$scriptToExecute = [scriptblock]::Create($command)

	Write-Host "Executing command to setup PSModulePath environmental variable."
	$output = & $scriptToExecute

	$retVal = $output.ExitCode

	Pop-Location

	$retVal
}

$temp = @{
	'Server' = $env:COMPUTERNAME;
	'ExitCode' = 0;
	'ScriptName' = 'Update-LocalModules.ps1'
}

if(!(Test-Path $Path)){
	Write-Error "Module path $Path was not found.  Please unpack the modules accordingly."
	$temp.ExitCode = 1
    $temp.ErrorDetail = "Module path $Path was not found.  Please unpack the modules accordingly."

	return (New-Object PSObject -Property $temp)
}

try{
	Update-LocalModules
}
catch [System.Exception] {
	$temp.ExitCode = 1
	$temp.ErrorDetail = $_
}

(New-Object PSObject -Property $temp)
[cmdletbinding()]
param
(
	[parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()][string]$ComputerName,
	[parameter(Mandatory=$true)]
	[ValidateNotNull()]
	[Deployment.Domain.Roles.FileSystemDeploy]$DeployRole
)

function New-FileSystemFolder{
[cmdletbinding()]
param()

	$retVal = 0

	$results = $DeployRole.CreateFolderDeploys | ForEach-Object {
		$result = 0

		$path = $_.IsAbsolutePath | Get-ConditionalValue -TrueValue $_.TargetPath -FalseValue "\\$ComputerName$($_.TargetPath)"

		if(Test-Path ($path)) {
            Write-Host  "Target folder $path already exists. Not creating."
        }
        else {

			Write-Host "Attempting to create folder: $path"
			try{
				New-Item -Path $path -ItemType Directory -Force -ErrorAction Stop | Out-Null
				Write-Host2 -Type Success -Message "Target folder $path created."
			}
			catch{
                $result = 1
				Write-Error2 -ErrorRecord $_
				Write-Host2 -Type Failure -Message "Failed to create folder $path."
			}

			$result
        }
    }

	$retVal = (Test-IsNullOrEmpty $results) | Get-ConditionalValue -TrueValue 0 -FalseValue ($results | Measure-Object -Maximum).Maximum

	$retVal
}

function Copy-FileSystemFiles{
[cmdletbinding()]
param()

	$retVal = 0

	$results = $DeployRole.CopyItems | ForEach-Object {
		$result = 0
		$path = $_.IsAbsolutePath | Get-ConditionalValue -TrueValue $_.Target -FalseValue "\\$ComputerName$($_.Target)"

		Write-Host "Attempting to copy files to path: $path"

        if ($_.Replace) {
           	if(Test-Path $path) {
                Write-Host "Removing existing folder/item $path"
                Remove-Item -Path $path -Force -Recurse | Out-Null
				Write-Host2 -Type Success -Message "Successfully removed folder/item $path"
            }
        }

		$source = Join-Path $dropFolder $_.Source
		Write-Host "Copying $source to $path"
		try{
			Copy-Item -Path $source -Destination $path -filter $_.Filter -Force -ErrorAction stop -Recurse:$_.Recurse  | Out-Null
			Write-Host2 -Type Success -Message "Copied $source to $path"
		}
		catch{
            $result = 1
			Write-Error2 -ErrorRecord $_
			Write-Host2 -Type Failure -Message "Failed to Copy $source to $path"
		}

		$result
    }

	$retVal = (Test-IsNullOrEmpty $results) | Get-ConditionalValue -TrueValue 0 -FalseValue ($results | Measure-Object -Maximum).Maximum

	$retVal
}

function Remove-FileSystemFolder{
[cmdletbinding()]
param()

	$retVal = 0

	$DeployRole.RemoveFolderDeploys | ForEach-Object {
		$result = 0
		$path = $_.IsAbsolutePath | Get-ConditionalValue -TrueValue $_.Target -FalseValue "\\$ComputerName$($_.Target)"

		if(Test-Path $path)
        {
            Write-Host "Attempting to remove folder: $path"
			try{
				Remove-Item -Path $path -Force -Recurse -ErrorAction Stop | Out-Null
				Write-Host2 -Type Success -Message "Target folder $path deleted."
			}
			catch{
                $result = 1
				Write-Error2 -ErrorRecord $_
                Write-Host2 -Type Failure -Message "Target folder [$path] on [$($env:computername)] was not removed."
			}
        }
        else {
            Write-Host "Folder $path does not exist. Skipping Remove role."
        }

		$result
    }

	$retVal = (Test-IsNullOrEmpty $results) | Get-ConditionalValue -TrueValue 0 -FalseValue ($results | Measure-Object -Maximum).Maximum

	$retVal
}

$result = 0

Write-Host ""
Write-Header "Starting role $DeployRole on $ComputerName." -AsSubHeader
$timer = [Diagnostics.Stopwatch]::StartNew()

try {
	$result = Invoke-UntilFail {New-FileSystemFolder},{Copy-FileSystemFiles},{Remove-FileSystemFolder}
}
catch [System.Exception] {
	Write-Error2 -ErrorRecord $_
	$result = 1
}

$timer.Stop()
$SummaryLog | Write-Summary -Message "running role $DeployRole on $ComputerName."  -Elapsed $timer.Elapsed -ScriptResult $result
Write-Header "Ending role $DeployRole on $ComputerName" -AsSubHeader

$result
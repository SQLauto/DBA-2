[cmdletbinding()]
param(
	[Parameter(Mandatory=$true, Position=0)]
	[ValidateNotNullOrEmpty()]
	[string]$ModulePath
)

function Add-ModulePath {
[cmdletbinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Value,

		[Parameter()]
        [string] $Variable = "PSModulePath",

        [ValidateSet('Machine', 'User', 'Session')]
        [string] $Container = 'Session'
    )

    if ($Container -ne 'Session') {
        $containerMapping = @{
            Machine = [EnvironmentVariableTarget]::Machine
            User = [EnvironmentVariableTarget]::User
        }
        $containerType = $containerMapping[$Container]

		Write-Host "Creating ModulePath mappings for container type $containerType"

        $persistedPaths = [Environment]::GetEnvironmentVariable($Variable, $containerType) -split ';'
        if ($persistedPaths -notcontains $Value) {
            $persistedPaths = $persistedPaths + $Value | where { $_ }
            [Environment]::SetEnvironmentVariable($Variable, $persistedPaths -join ';', $containerType)
        }
    }

    $envPaths = $env:Path -split ';'
    if ($envPaths -notcontains $Value) {
        $envPaths = $envPaths + $Value | ? { $_ }
        $env:Path = $envPaths -join ';'
    }

	$envMPaths = $env:PSModulePath -split ';'
	if ($envMPaths -notcontains $modulePath) {
		$envMPaths = $envMPaths + $modulePath | ? { $_ }
		$env:PSModulePath = $envMPaths -join ';'
	}
}

$temp = @{
	'Server' = $env:COMPUTERNAME;
	'ExitCode' = 0;
	'ScriptName' = 'Set-EnvironmentModulePath.ps1'
}

if(!(Test-Path $ModulePath)){
	Write-Error "Module path $ModulePath was not found.  Please unpack the modules accordingly."
	$temp.ExitCode = 1
    $temp.ErrorDetail = "Module path $ModulePath was not found.  Please unpack the modules accordingly."

	return (New-Object PSObject -Property $temp)
}

try{
	Add-ModulePath -Value $ModulePath -Container "Machine"
}
catch [System.Exception]
{
	$temp.ExitCode = 1
	$temp.ErrorDetail = $_
}

(New-Object PSObject -Property $temp)
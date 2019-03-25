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
            $persistedPaths = $persistedPaths + $Value | Where-Object { $_ }
            [Environment]::SetEnvironmentVariable($Variable, $persistedPaths -join ';', $containerType)
        }
    }

    $envPaths = $env:Path -split ';'
    if ($envPaths -notcontains $Value) {
        $envPaths = $envPaths + $Value | Where-Object { $_ }
        $env:Path = $envPaths -join ';'
    }

    $envMPaths = $env:PSModulePath -split ';'
    if ($envMPaths -notcontains $modulePath) {
        $envMPaths = $envMPaths + $modulePath | Where-Object { $_ }
        $env:PSModulePath = $envMPaths -join ';'
    }
}

function Install-PSRepository {
    [Cmdletbinding()]
    param(
        [Parameter()]
        [string]$Name = "FTP Nuget",
        [Parameter()]
        [string]$SourceLocation = "http://nugetftp.fae.tfl.local:7123/nuget",
        [ValidateSet('Trusted', 'Untrusted')]
        [string]$InstallationPolicy = 'Trusted'
    )
    $repo = Get-PSRepository -ErrorAction SilentlyContinue | Where-Object {$_.SourceLocation -like $SourceLocation}

    if ($repo) {
        $Name = $repo.Name
    }

    Write-Host "Registering local PS repository for $Name"
    Unregister-PSRepository -Name $Name -ErrorAction SilentlyContinue
    Register-PSRepository -Name $Name -PackageManagementProvider Nuget -SourceLocation $SourceLocation -InstallationPolicy Trusted
}

function Install-PackageManagement {
    [Cmdletbinding()]
    param()
    #the first two lines below are necessary to allow access through the proxy
    $wc = new-object system.net.webclient
    $wc.proxy.credentials = [system.net.credentialcache]::defaultnetworkcredentials

    #first ensure we have any version of PackageManagement
    $modules = Get-Module -Name 'PowerShellGet' -ListAvailable

    if ($modules.Count -eq 0) {
        throw "No module called $Name was found. You will need to install this manually to continue."
    }

    #determine installed version of modules
    $module = Get-InstalledModule -Name 'PowerShellGet' -RequiredVersion 1.6.0 -ErrorAction Ignore

    if (!$module) {
        #This will install PowerShellGet and PackageManagement modules (currently 1.6 and 1.1.7.0 respectively)
        Write-Host "Installing Package Management Modules"
        Install-Module -Name PowerShellGet -Force -RequiredVersion 1.6.0 -AllowClobber
    }
}

function Install-InternalPackageProvider {
[Cmdletbinding()]
param()

    #the first two lines below are necessary to allow access through the proxy
    $wc = new-object system.net.webclient
    $wc.proxy.credentials = [system.net.credentialcache]::defaultnetworkcredentials

    $nuget = Get-PackageProvider -Name nuget -Force -ForceBootstrap -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1
    $version = '2.8.5.208'
    if(-not $nuget -or $nuget.Version -lt [version]::Parse($version)) {
        Write-Host "Installing Nuget Package Provider"
        Install-PackageProvider -Name Nuget -MinimumVersion $version -force -verbose -ForceBootstrap -Scope CurrentUser -Confirm:$False
    }

    Write-Host "Importing Nuget Package Provider"
    Import-PackageProvider -Name Nuget -MinimumVersion $version -Force -ForceBootstrap | Out-Null
}

function Install-RequiredModule {
    [Cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string]$Repository = "FTP Nuget",
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string]$Scope = 'CurrentUser',
        [switch]$NoImport
    )

    $found = Find-Module -Name $Name -Repository $Repository

    if (!$found) {
        throw "Unable to find any module matching the name $Name"
    }

    $foundVersion = $found.Version

    #first clean up any legacy old modules
    $module = Get-InstalledModule -Name $Name -ErrorAction Ignore

    if ($module) {
        Write-Host "Removing old installs of module $Name"
        $found | Uninstall-Module -Force
    }

    #we don't want our module to actually run from our current user module path, so we will copy these to D:\TFL\PowerShell\Modules
    #and use that instead.  After copy and registration, we will uninstall local module.
    $targetPath = 'D:\TFL\PowerShell\Modules'

    if (!(Test-Path $targetPath)) {
        New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
        Add-ModulePath -Value $targetPath -Container "Machine"
    }

    #determine if we already have current module based on path.
    $versionedPath = Join-Path (Join-Path $targetPath $Name) $foundVersion

    if (!(Test-Path $versionedPath)) {
        #save module, but don't import/load it.
        Write-Host "Saving version $foundVersion module $Name to $targetPath"
        $found | Save-Module -Path $targetPath -Force
    }
    #Ensure Module is available for use.
    $modules = Get-Module $Name -ListAvailable

    if ($modules.Count -eq 0) {
        throw "No module called $Name was found."
    }

    #TODO: Think about old version clean up
    if (!$NoImport) {
        Write-Host "Importing module $Name with version $foundVersion"
        Import-Module $Name -Force -ErrorAction Stop -DisableNameChecking -Global
        #Import-Module $Name -RequiredVersion $foundVersion
    }
}

function Get-DatabaseNameWithBuildId {
	[cmdletbinding()]
	param(
        [Parameter(Mandatory=$true)]
	    [ValidateNotNullOrEmpty()]
	    [string] $DatabaseName
    )

	# Make sure there is a build number
	if (-not $env:BUILD_BUILDNUMBER) {
		throw "BUILD_BUILDNUMBER environment variable is missing."
	}

	# Get and validate the version data
	$versionData = [regex]::matches($env:BUILD_BUILDNUMBER, "\d+\.\d+")
	switch($versionData.Count) {
		0{ throw "Could not find version number data in BUILD_BUILDNUMBER=" + $env:BUILD_BUILDNUMBER }
		1 {	}
		default {
		  Write-Warning "Found more than instance of version data in BUILD_BUILDNUMBER=" + $env:BUILD_BUILDNUMBER;
		  Write-Warning "Will assume first instance is version."
		}
	}

	# Take the first pattern match
	$version = $versionData[0]
	# Replace any period (.) in the version as these cannot be used as part of a database name
	$retVal = $DatabaseName + "_" + $version.value.replace('.','_')

	$retVal
}
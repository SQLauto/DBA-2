[cmdletbinding(DefaultParameterSetName="FromAssembly")]
param(
    [Parameter(Position=0, Mandatory=$true, ParameterSetName="FromAssembly")]
    [ValidateNotNullOrEmpty()]
    [string]$AssemblyToVersionFrom,
    [Parameter(Position=0, Mandatory=$true, ParameterSetName="FromString")]
    [ValidateNotNullOrEmpty()]
    [string]$Version,
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ModuleManifestFile,
    [Parameter(Mandatory=$false)]
    [string]$Path = '.'
)

function Update-ManifestFile {
    param([string]$AssemblyVersion)

    $moduleManifest = Get-ChildItem -Path $Path -File -Filter $ModuleManifestFile -Recurse

    if (!$moduleManifest) {
        throw "Unable to find any module manifest files"
    }

    $target = $moduleManifest.FullName

    Write-Host "Updating Module Manifest file with version $AssemblyVersion"
    Update-ModuleManifest -Path $target -ModuleVersion $AssemblyVersion -FunctionsToExport '*' -CmdletsToExport '*'
}

function Get-AssemblyVersion {
    param()

    if ($Version) {
        return $Version
    }

    $assembly = Get-ChildItem -Path $Path -File -Filter $AssemblyToVersionFrom -Recurse
    $expectedVersion = $assembly | Select-Object -ExpandProperty VersionInfo | Select-Object -ExpandProperty FileVersion

    $expectedVersion

}

try {
    $expectedVersion = Get-AssemblyVersion

    if (!$expectedVersion) {
        Write-Error "Unable to obtain an assembly version, or no version was passed in."
        exit 1
    }

    Update-ManifestFile -AssemblyVersion $expectedVersion

    exit 0
}
catch {
    Write-Error $_
    exit 1
}
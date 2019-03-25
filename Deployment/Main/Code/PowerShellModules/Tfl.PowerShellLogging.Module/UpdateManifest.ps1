param([string]$Path,[string]$Version)

function Get-MetadataValue {
param (
    [System.Xml.XmlNode]$Xml,
    [string]$NodeName
)
	$node = $null
	$packageNode = $xml.ChildNodes | Where-Object { $_.GetType().ToString() -eq "System.Xml.XmlElement" } | Where-Object { $_.Name -eq "package" } | Select-Object -First 1
	if (!($packageNode -eq $null))
	{
		if (!$packageNode.NamespaceURI)
		{
			$node = Select-Xml -Xml $xml -XPath "/package/metadata/$nodeName";
		}
		else
		{
			$xmlNamespace = @{ ns = $packageNode.NamespaceURI; };
			$node = Select-Xml -Xml $xml -XPath "/ns:package/ns:metadata/ns:$nodeName" -Namespace $xmlNamespace
		}
	}

	if (!$node)
	{
		throw "Unablee to find node $nodeName"
	}

	$node.Node.Innertext
}

function Set-MetadataValue {
param (
    [Parameter(Mandatory=$true, Position="0", ValueFromPipeline=$true)] [xml]$Data,
    [Parameter(Mandatory=$true)][string]$TargetFile,
    [Parameter(Mandatory=$true)][string]$NodeName,
    [Parameter(Mandatory=$true)][string]$Value
)

	$node = $null
	Write-Host "Attempting to get package node"
	$packageNode = $Data.ChildNodes | Where-Object { $_.GetType().ToString() -eq "System.Xml.XmlElement" } | Where-Object { $_.Name -eq "package" } | Select-Object -First 1
	if (!($packageNode -eq $null)) {
		if (!$packageNode.NamespaceURI)
		{
			$node = Select-Xml -Xml $Data -XPath "/package/metadata/$NodeName";
		}
		else
		{
			$XmlNamespace = @{ ns = $packageNode.NamespaceURI; };
			$node = Select-Xml -Xml $Data -XPath "/ns:package/ns:metadata/ns:$NodeName" -Namespace $XmlNamespace;
		}
	}

	if (!$node) {
		thow "Unable to find node $NodeName"
	}

	Write-Host "Set $nodeName value from $node.Node.InnerText to $Value"
	$node.Node.InnerText = $Value;
	Write-Host "Attempting to save file $TargetFile"
	$Data.Save($TargetFile);
}

function Update-ManifestFile{
param([string]$AssemblyVersion)

    if($Path){
        $target = Join-Path $Path "TFL.PowerShell.Logging.psd1"

		if(!(Test-Path $target)){
			Write-Warning "Unable to find any module manifest files. Skipping."
			return
		}
    }
    else{
        $moduleManifest = Get-ChildItem -Path '.' -File -Filter "*.psd1" -Recurse

        if(!$moduleManifest){
            throw "Unable to find any module manifest files"
        }

        $target = $moduleManifest.FullName
    }

    Write-Host "Updating Module Manifest file with version $AssemblyVersion"
    Update-ModuleManifest -Path $target -ModuleVersion $AssemblyVersion -FunctionsToExport '*' -CmdletsToExport '*'
}

function Update-NuSpecFile{
param([string]$AssemblyVersion)

    $nuspecFile = Get-ChildItem -Path . -File -Filter "*.nuspec" -Recurse

    if(!$nuspecFile){
        throw "Unable to find any nuspec files"
    }

    $nuspecXml = [xml](Get-Content -Path $nuspecFile.FullName)

    $nuspecVersion = Get-MetadataValue -Xml $nuspecXml -NodeName 'version'
    Write-Host "Current version of nuspec file set to $nuspecVersion"

    #update nuspec version attribute.
    Write-Host "Updating Nuspec file with version $AssemblyVersion"
    Set-MetadataValue -Data $nuspecXml -TargetFile $nuspecFile.FullName -NodeName 'version' -Value $AssemblyVersion
}

function Get-AssemblyVersion{
param()

    $assembly = Get-ChildItem -Path . -File -Filter "TFL.PowerShell.Logging.dll" -Recurse
    $expectedVersion = $assembly | Select-Object -ExpandProperty VersionInfo | Select-Object -ExpandProperty FileVersion

    $expectedVersion

}
try {
    if($Version){
        Update-ManifestFile -AssemblyVersion $Version
    }
    else{
        $expectedVersion = Get-AssemblyVersion

        if(!$expectedVersion){
            Write-Error "Unable to obtain an assembly version, or no version was passed in."
            exit 1
        }

        Update-ManifestFile -AssemblyVersion $expectedVersion
        Update-NuSpecFile -AssemblyVersion $expectedVersion
    }
}
catch {
    Write-Error $_
    exit 1
}
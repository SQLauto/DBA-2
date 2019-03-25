Param
(
	[Parameter(Mandatory=$true)]
    [string]$DropFolder

    # Debug
    #$DropFolder = "\\share\tfs\Drops\OyBO\OyBO.Stabilisation.PAK.Preview\OyBO.Stabilisation.PAK.Preview_20160610.4"
)

if([System.string]::IsNullOrEmpty($DropFolder))
{
    Write-Error "DropFolder Parameter cannot be null or empty. Exiting with Error"
    Exit 1
}

$PreviewFolder = "\\share\tfs\ConfigPreview"
if(!(Test-Path $PreviewFolder))
{
    New-Item -Path $PreviewFolder -ItemType Directory -Force -Verbose
}

$ZipFiles = Get-ChildItem -Path $DropFolder -Filter "*.zip" -Verbose


foreach($ZipFile in $ZipFiles)
{
    $subStrs = $ZipFile.Name.Split("_");
    $ConfigName = $subStrs[2].TrimEnd(".zip")

    $PackagePreviewFolder = Join-Path $PreviewFolder $ConfigName
    if(Test-Path $PackagePreviewFolder)
    {
        Remove-Item -Path $PackagePreviewFolder -Recurse -Force
    }
    New-Item -Path $PackagePreviewFolder -ItemType Directory -Force

    if(Test-Path "$DropFolder\Deployment\Scripts\$ConfigName.xml")
    {
        $ConfigFile = "$DropFolder\Deployment\Scripts\$ConfigName.xml"
        
    }
    else
    {
        [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')
        $Zip = [System.IO.Compression.ZipFile]::OpenRead($ZipFile.FullName)
        $ZipEntries = $Zip.Entries

        $ConfigFiles = Get-ChildItem -Path "$DropFolder\Deployment\Scripts" -Filter "*$ConfigName*"
        foreach($PossibleConfigFile in $ConfigFiles)
        {
           $FoundConfigFile = $ZipEntries | Select-Object -Property Name | Where-Object {$_.Name -eq $PossibleConfigFile.Name}

           if(!([System.string]::IsNullOrEmpty($FoundConfigFile)))
           {
                $ConfigFile = "$DropFolder\Deployment\Scripts\" + $FoundConfigFile.Name
           }
        }
        $Zip.Dispose()
    }

    Write-Host ("Command: " + "-Type 'Preview' -ConfigFile '$ConfigFile' -PackageName '" + $ZipFile.FullName + "' -OutputDir '$PackagePreviewFolder'")
    & "$DropFolder\DeploymentTool.exe" ("-Type 'Preview' -ConfigFile '$ConfigFile' -PackageName '" + $ZipFile.FullName + "' -OutputDir '$PackagePreviewFolder'")
}



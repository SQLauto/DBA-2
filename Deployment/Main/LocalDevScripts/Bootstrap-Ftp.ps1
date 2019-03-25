$clientDll = "D:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.Client.dll"
$versionControlClientDll = "D:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.Common.dll"
$versionControlCommonDll = "D:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.VersionControl.Client.dll"

#Load the Assemblies
[Reflection.Assembly]::LoadFrom($clientDll)
[Reflection.Assembly]::LoadFrom($versionControlClientDll)
[Reflection.Assembly]::LoadFrom($versionControlCommonDll)

$workspaceName = $env:USERNAME+"_Deployment"

$tfs = [Microsoft.TeamFoundation.Client.TeamFoundationServerFactory]::GetServer("TDC2TFS001\FTPDev")
$ftp = $tfs.GetService([Microsoft.TeamFoundation.VersionControl.Client.VersionControlServer])

[string]$username = (Join-Path $env:USERDOMAIN $env:USERNAME)
[string]$computerName = $env:computername
[bool]$exists = ([array]$ftp.QueryWorkspaces($workspaceName, $username, $computerName).Name).Length -eq 1

if($exists) {
    $ftp.DeleteWorkspace($workspaceName, $username)
}

$targetDirectory = 'D:\src\FT\Deployment\Main'

$workspace = $ftp.CreateWorkspace($workspaceName, $ftp.AuthenticatedUser)
$workspace.Map('$/Deployment/Main/', $targetDirectory)
$workspace.Get()

Set-Location $targetDirectory

Invoke-Expression 'D:\src\FT\Deployment\Main\LocalDevScripts\Get-Workspaces.ps1'

cd 'D:\src\FT\'
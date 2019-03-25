#requires -Version 3.0

param (
	[string]$workspace = @('AutogrationShared'),
	[string]$jobsFolder,
    [string]$paramsFile
) 
 
Invoke-Expression ". $paramsFile"

$tfsServer = "tfs\FTPDev"
$workspaceBasePath = "D:\src\"
$workspacePrefix = $env:COMPUTERNAME  + "_"
	

Write-Host "Beginning Get-Workspaces job"

function LoadAssemblies
{
	$clientDll = "D:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.Client.dll"
	$versionControlClientDll = "D:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.Common.dll"
	$versionControlCommonDll = "D:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.VersionControl.Client.dll"

	#Load the Assemblies
	[Reflection.Assembly]::LoadFrom($clientDll)
	[Reflection.Assembly]::LoadFrom($versionControlClientDll)
	[Reflection.Assembly]::LoadFrom($versionControlCommonDll)
}

function GetTfsConnection
{
	Param([string] $tfsServer)

	#Set up connection to TFS Server and get version control
	$tfs = [Microsoft.TeamFoundation.Client.TeamFoundationServerFactory]::GetServer($tfsServer)
	$vcs = [Microsoft.TeamFoundation.VersionControl.Client.VersionControlServer]
	$ftp = $tfs.GetService($vcs)
	return $ftp
}

function SafeDeleteWorkspace {
    
    param(
        [string] $workspaceName, 
        [string] $user
    )

    [string]$username = (Join-Path $env:USERDOMAIN $env:USERNAME)
    [string]$computerName = $env:computername
    [bool]$exists = ([array]$ftp.QueryWorkspaces($workspaceName,$username, $computerName).Name).Length -eq 1

    if($exists) {
    	echo ("Removing old workspace " + $workspaceName)
        $removeResult = $ftp.DeleteWorkspace($workspaceName, $user)
    }

}

function GetWorkspaceMappings
{
	Param([string] $workspaceName)
	
	[array] $mappings = @();

	foreach ($line in $workspaceMappings.Split("`r`n")) {
		$splitLine = $line.Split(':', 2)
		$item = @{}
		if($splitLine.trim().Length -eq 0)
		{
			continue
		}
		$item['workspacePath'] = $splitLine[0].trim()
		$item['localPath'] = $splitLine[1].trim()
		Write-Host $item['workspacePath']
		Write-Host $item['localPath']
		$mappings += ($item)
	}
	Write-Host "Mappings $mappings"
	return $mappings
}

function MapWorkspace
{
	Param(
		[string] $workspaceName,
		[string] $workspaceBasePath,
		[string] $workspacePrefix,
		[Microsoft.TeamFoundation.VersionControl.Client.VersionControlServer] $ftp
	)

	$mappings = GetWorkspaceMappings -workspaceName $workspaceName 
	$targetWorkspaceName = $workspacePrefix + $workspaceName
    $user = $ftp.AuthenticatedUser
	echo "";
	SafeDeleteWorkspace -workspaceName $targetWorkspaceName -user $user

	echo ("Creating workspace " + $targetWorkspaceName)
    
	#This sets up the parameters to create a public workspace
    $permissionProfile = [Microsoft.TeamFoundation.VersionControl.Client.WorkspacePermissionProfile]::BuiltInProfiles[2];
    $workspaceParams =  [Microsoft.TeamFoundation.VersionControl.Client.CreateWorkspaceParameters]("testParams")
    $workspaceParams.PermissionProfile = $permissionProfile
    $workspaceParams.WorkspaceName = $targetWorkspaceName
    $workspaceParams.OwnerName = $user

	$workspace = $ftp.CreateWorkspace($workspaceParams)
    
	foreach($mapping in $mappings) {
		$fullLocalPath = Join-Path -path (Join-Path -path $workspaceBasePath $workspaceName) $mapping['localPath']
		$workspacePath = $mapping['workspacePath'] 
		echo ("`tMapping " + $workspacePath + " -> " + $fullLocalPath )
        $workspace.Map($workspacePath, $fullLocalPath)
	}
	
	echo ("Getting files for workspace " + $targetWorkspaceName)
	$workspace.Get()
    
}

function Main
{
	LoadAssemblies
	$ftp = GetTfsConnection -tfsServer $tfsServer

	#foreach($workspace in $workspaces) {
		MapWorkSpace -workspaceName $workspace -workspaceBasePath $workspaceBasePath -ftp $ftp -workspacePrefix $workspacePrefix
	#}
}

try
{
	Main
	 Write-Host "Finished Get-Workspaces job!"
}
catch
{
	throw
}

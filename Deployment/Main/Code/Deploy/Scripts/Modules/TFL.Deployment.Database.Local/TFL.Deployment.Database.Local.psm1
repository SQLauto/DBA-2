function Remove-Database {
param([string]$DataSource, [string]$Database)

	$retVal = 0

	$connectionString = "Data Source=$dataSource;Integrated Security=SSPI;Initial Catalog=master"

	$query = "if exists (select 1 from sys.databases where name = '{0}')
		begin
			alter database {0} set single_user with rollback immediate;
			drop database {0};
		end" -f $database

	$func = {
		param([string]$ConnectionString, [string]$Query)

		$result = $true

		try{
			$result = Invoke-ExecuteNonQuery -ConnectionString $ConnectionString -CommandText $Query
		}
		catch{
			Write-Error2 -ErrorRecord $_
			$result = $false
		}

		$result
	}

	$loopCount = 0

	do{
		$success = & $func -ConnectionString $connectionString -Query $query
		$loopCount++

		if(!$success){
			Write-Warning "Attemping to remove database. Retrying - Attempt $loopCount"
			Start-Sleep -Seconds 6
		}
	}while($loopCount -lt 3 -and $success -eq $false)

	$retVal
}

function New-Database {
param(
	[string]$DataSource,
	[string]$Database,
	[string]$DatabaseSize = "200",
	[string]$LogFileSize = "50"
)

	$retVal = 0

	$connectionString = "Data Source=$DataSource;Integrated Security=SSPI;Initial Catalog=master"

	$query = "create database {0};
			alter database {0} set quoted_identifier on;
			alter database {0} set recovery simple;
			alter database {0} modify file (name = {0}, size = {1}MB);
			alter database {0} modify file (name = {0}_log, size = {2}MB);" -f $Database,$DatabaseSize,$LogFileSize

	$func = {
		param([string]$ConnectionString, [string]$Query)

		$result = $true

		try{
			$result = Invoke-ExecuteNonQuery -ConnectionString $ConnectionString -CommandText $Query
		}
		catch{
			Write-Error2 -ErrorRecord $_
			$result = $false
		}

		$result
	}

	$loopCount = 0

	do{
		$success = & $func -ConnectionString $connectionString -Query $query
		$loopCount++

		if(!$success){
			Write-Warning "Attemping to create new database. Retrying - Attempt $loopCount"
			Start-Sleep -Seconds 6
		}
	}while($loopCount -lt 3 -and $success -eq $false)

	$retVal
}

function Initialize-Parameters{
param(
	[string[]]$ParameterFiles,
	[string]$RootPath
)

	if(!$RootPath){
		$RootPath = $PSScriptRoot
	}

	$deploymentPath = Join-Path $RootPath "Deployment"

	if(!(Test-Path $deploymentPath)){
		New-Item -ItemType Directory -Path $RootPath -Name "Deployment" -Force | Out-Null
	}

	#if we have had $ParametersPath passed in we need to copy them locally
	if(!(Test-IsNullOrEmpty $ParameterFiles)){

		$target = Join-Path $deploymentPath "Parameters"

		Write-Host "Target Parameters path set to $target"
		if(!(Test-Path $target)){
			Write-Host "Target Parameters path does not exist. Creating."
			New-Item -ItemType Directory -Path $deploymentPath -Name "Parameters" -Force | Out-Null
		}

		$ParameterFiles	| ForEach-Object {
			Copy-Item $_ $target -Force
		}
	}
}

<#
.SYNOPSIS
	Script for deploying developer databases using deployment scripts and using the deployment patching mechanism
.PARAMETER ServerName
    The name of the target DB server.
.PARAMETER DatabaseName
    The name of the database to path/deploy.
.PARAMETER Environment
    An name of the environment to target.
.PARAMETER IntermediatePatchingFolder
    The name of the deployment partition used if doing blue/green deployments. Acts as a sub-set of machines
.PARAMETER IntermediatePatchingFolderInclude
    False stops before IntermediatePatchingFolder, True stops immediately after IntermediatePatchingFolder.
.PARAMETER DropDatabase
    Switch to determine to set if to drop the existing database first. By default, it will be not be dropped.
#>
function Invoke-LocalDatabaseDeployment {
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true, Position = 0, ParameterSetName = "Baseline")]
        [ValidateNotNullOrEmpty()]
        [string] $BaselineScript,
        [parameter(Mandatory = $true, Position = 0, ParameterSetName = "PatchScript")]
        [ValidateNotNullOrEmpty()]
        [string] $PatchScript,
        [parameter(Mandatory = $true, Position = 0, ParameterSetName = "PatchFolder")]
        [ValidateNotNullOrEmpty()]
        [string] $PatchFolder,
        [parameter(ParameterSetName = "PatchFolder")]
        [string] $PatchFolderFormat = "B???_R????_",
        [parameter(ParameterSetName = "PatchFolder")]
        [string] $UpgradeScript = "Patching.sql",
        [parameter(ParameterSetName = "PatchFolder")]
        [string] $PreValidationScript = "PreValidation.sql",
        [parameter(ParameterSetName = "PatchFolder")]
        [string] $PostValidationScript = "PostValidation.sql",
        [parameter(ParameterSetName = "PatchFolder")]
        [string] $PatchLevelDeterminationScript = "DetermineIfDatabaseIsAtThisPatchLevel.sql",
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Config,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Environment,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ServerName,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DatabaseName,
        [string] $InstanceName,
        [string] $DropFolder,
        [string] $IntermediatePatchingFolder,
        [string] $Role,
        [string] $SqlScriptToRunSuffix,
        [switch] $IntermediatePatchingFolderInclude,
		[switch] $NoDropRunFile
    )
    $result = 0

    $databaseDeployRole = New-Object -TypeName "Deployment.Domain.Roles.DatabaseDeploy"
    $databaseDeployRole.Name = "FromConfig"
    $databaseDeployRole.Description = $Role
    $databaseDeployRole.TargetDatabase = $DatabaseName
    $databaseDeployRole.DatabaseInstance = $InstanceName
    $databaseDeployRole.Configuration = $Config

    switch ($PSCmdlet.ParameterSetName) {
        "Baseline" {
            $databaseDeployRole.BaselineDeployment = $BaselineScript
        }
        "PatchScript" {
            $databaseDeployRole.PatchDeployment = $PatchScript
        }
        "PatchFolder" {
            $databaseDeployRole.UpgradeScript = $UpgradeScript
            $databaseDeployRole.PatchDeploymentFolder = $PatchFolder
            $databaseDeployRole.PatchFolderFormatStartsWith = $PatchFolderFormat
            $databaseDeployRole.PreValidationScript = $PreValidationScript
            $databaseDeployRole.PostValidationScript = $PostValidationScript
            $databaseDeployRole.PatchLevelDeterminationScript = $PatchLevelDeterminationScript
        }
    }

    if (!$DropFolder) {
        $DropFolder = $PSScriptRoot
        $helperScriptRelativePath = "HelperScripts"
    }

    $params = @{
        DropFolder                        = $DropFolder
        ComputerName                      = $ServerName
        Environment                       = $Environment
        DefaultConfig                     = $Config
        DatabaseRole                      = $databaseDeployRole
        IntermediatePatchingFolder        = $IntermediatePatchingFolder
        HelperScriptRelativePath          = $HelperScriptRelativePath
        SqlScriptToRunSuffix              = $SqlScriptToRunSuffix
        IntermediatePatchingFolderInclude = $IntermediatePatchingFolderInclude.IsPresent
		NoDropRunFile 					  = $NoDropRunFile.IsPresent
    }

    $dataDeployScript = Join-Path $PSScriptRoot "TFL.DataDeploy.ps1"
    $result = & $dataDeployScript @params

    $result
}
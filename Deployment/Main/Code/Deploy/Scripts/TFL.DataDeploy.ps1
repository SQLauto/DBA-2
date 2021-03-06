<#
.SYNOPSIS
	Script for deploying database scripts using the deployment patching mechanism
.PARAMETER ComputerName
    The name of the deployment configuration file used to drive the deployment.
.PARAMETER Environment
    The password used to decrypt service account info.
.PARAMETER DefaultConfig
    The name of the folder where deployment logs will be created.
.PARAMETER DropFolder
    An array of group names to limit what deployment groups should be deployed
.PARAMETER DatabaseRole
    An array of server names to that will be used to filter the deployment target machines.
.PARAMETER IntermediatePatchingFolder
    The name of the deployment partition used if doing blue/green deployments. Acts as a sub-set of machines
.PARAMETER IntermediatePatchingFolderInclude
    False stops before IntermediatePatchingFolder, True stops immediately after IntermediatePatchingFolder.
.PARAMETER NoDropRunFile
    Switch to determine if the generated .ToRun files are auto-deleted after a successfull invocation.  By default the are deleted. Setting this will mean they are not removed.
.PARAMETER IsAzure
    Switch to set for synchronous deployments. If not set, then default will be multithreaded. It will use Processor count to determine the number of threads to use
.PARAMETER UseSqlAuth
    Switch to indicate whether to use Sql Authentication. Note Azure will support integrated authentication against Azure Active Directory
.PARAMETER Local
    Switch to set if script is being called locally as part of dev deploy
#>

[cmdletbinding()]
param
(
    [Parameter(Position=0, Mandatory=$true)]
	[Alias("DatabaseHost")]
    [string] $ComputerName,
    [Parameter(Mandatory=$true)]
	[string] $Environment,
	[Parameter(Mandatory=$true)]
    [string] $DefaultConfig,
	[Parameter(Mandatory=$true)]
	[Deployment.Domain.Roles.DatabaseDeploy]$DatabaseRole,
	[Parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string] $DropFolder,
	[Parameter()][string] $IntermediatePatchingFolder,
	[Parameter()][string] $HelperScriptRelativePath,
	[Parameter()][string] $SqlScriptToRunSuffix,
	[Parameter()][string] $DriveLetter = "D",
	[Parameter()][string] $RigConfigFile,
	[Parameter()][switch] $IntermediatePatchingFolderInclude,
	[Parameter()][switch] $NoDropRunFile,
    [Parameter()]
	[Alias("IsAzureDeployment")]
	[switch] $IsAzure,
    [Parameter()]
	[Alias("UseSqlAuthentication")]
    [switch] $UseSqlAuth
)

#Main entry point function
function Initialize-DatabaseDeployment{
[cmdletbinding()]
param()

	$retVal = 0
	$script:isDevEnvironment = Assert-IsDevEnvironment $Environment

	$username = ""
	$password = ""

	if ($UseSqlAuth){
		#TODO: Where on earth do this come from. Not part of the schema
		$username = $ConfigPart.Username
		$password = $ConfigPart.Password
	}

	$databaseInstance = $DatabaseRole.DatabaseInstance
	$script:datasource = Get-Datasource -ComputerName $ComputerName -InstanceName $databaseInstance

	if ($IsAzure) {
 		if(!$HelperScriptRelativePath){
				$HelperScriptRelativePath = "Main\Scripts\SqlRole\DeploymentHelpers"
		}

		if($DatabaseRole.PatchDeployment) {
 			$DatabaseRole.PatchDeployment = Join-Path $env:AGENT_BUILDDIRECTORY $DatabaseRole.PatchDeployment
 		}

 		if($DatabaseRole.PreDeployment) {
 			$DatabaseRole.PreDeployment   = Join-Path $env:AGENT_BUILDDIRECTORY $DatabaseRole.PreDeployment
 		}

 		if($DatabaseRole.PostDeployment) {
 			$DatabaseRole.PostDeployment  = Join-Path $env:AGENT_BUILDDIRECTORY $DatabaseRole.PostDeployment
 		}

 		$username = "$username@$ComputerName"
 		#TODO: Where is this coming from
 		$server = $ConfigPart.Server

 		$script:datasource = $ComputerName
 	}

	if(!$HelperScriptRelativePath){
		$HelperScriptRelativePath = "HelperScripts\SQLHelpers\DeploymentHelpers"
	}

	Write-Host "Deploying to Database $datasource.$($DatabaseRole.TargetDatabase)"

    $script:commonParams = @{
		DataSource=$datasource
        TargetDatabase=$DatabaseRole.TargetDatabase
        IsAzure=$IsAzure
    }

    if($UseSqlAuth){
        $script:commonParams.UseSqlAuth=$UseSqlAuth
	    $script:commonParams.Username=$username
	    $script:commonParams.Password=$password
    }

	$parametersPath = Join-Path $DropFolder "SqlParameters"

	if(!(Test-Path $parametersPath)){
		New-Item -ItemType Directory -Path $parametersPath -Force | Out-Null
	}

	$parametersPath = Join-Path $parametersPath "ToRunParameters.sql"

	$params = @{
		Path = $parametersPath
		DropFolder = $DropFolder
		DefaultConfig = $DefaultConfig
		OverrideConfig = $DatabaseRole.Configuration
		RigName = $RigName
		RigConfigFile = $RigConfigFile
		SqlScriptToRunSuffix = $SqlScriptToRunSuffix
	}

	$parametersPath = New-PatchScriptParameterFile @params

	$script:otherParams = @{
		DropFolder = $DropFolder
		ComputerName = $ComputerName
		Environment = $Environment
		HelperScriptRelativePath = $helperScriptRelativePath
		ParameterFilePath = $parametersPath
		SqlScriptToRunSuffix = $SqlScriptToRunSuffix
		DriveLetter = $DriveLetter
	}

    $script:databaseExists = Test-DatabaseExists @commonParams

	$retVal
}

function Invoke-Baseline{
[cmdletbinding()]
param()

    $retVal = 0

	if(!$IsAzure){
        if($DatabaseRole.BaselineDeployment -and !($script:databaseExists)){

			Write-Host "No base database $($DatabaseRole.TargetDatabase) exists, executing baseline script"

			$script:otherParams.DeploymentScript = $DatabaseRole.BaselineDeployment
			$script:otherParams.Type = "Baseline"

			$sqlScript = New-SqlCmdRunScript @otherParams @commonParams

			if(!$sqlScript){
				$retVal = 1
				return $retVal
			}

			$script:commonParams.TargetDatabase = "master" #need to execute against master db.
			$retVal = Invoke-SqlCmdRunScript @commonParams -ScriptToRun $sqlScript

			if($retVal -eq 0 -and !$NoDropRunFile){
				#Only remove on successful execution
				Remove-Item -Path $sqlScript -Force -ErrorAction Ignore
			}

            #Re-check if db exists after creation
		    $script:databaseExists = $retVal -eq 0 -and (Test-DatabaseExists @commonParams)
        }
	}

    if(!$script:databaseExists){
        $retVal = 1
    }

	$retVal
}

function Invoke-PreDeployment{
[cmdletbinding()]
param()

	$retVal = 0

    if($DatabaseRole.PreDeployment){
		Write-Host "Executing database $($DatabaseRole.TargetDatabase) pre-deployment scripts"

		$script:commonParams.TargetDatabase = $DatabaseRole.TargetDatabase
		$script:otherParams.Type = 'Pre'
		$script:otherParams.DeploymentScript = $DatabaseRole.PreDeployment

		$sqlScript = New-SqlCmdRunScript @otherParams @commonParams

		if(!$sqlScript){
			$retVal = 1
			return $retVal
		}

		$retVal = Invoke-SqlCmdRunScript @commonParams -ScriptToRun $sqlScript

		if($retVal -eq 0 -and !$NoDropRunFile){
			#Only remove on successful execution
			Remove-Item -Path $sqlScript -Force -ErrorAction Ignore
		}
	}

	$retVal
}

function Invoke-PatchDeploymentScript{
[cmdletbinding()]
param()

	$retVal = 0

	if($DatabaseRole.PatchDeployment -and !$DatabaseRole.PatchDeploymentFolder){
		Write-Host "Deploying database $($DatabaseRole.TargetDatabase) using the single patch script process and will not use incremental patch upgrade process."

		$script:otherParams.Type = 'Patch'
		$script:commonParams.TargetDatabase = $DatabaseRole.TargetDatabase
		$script:otherParams.DeploymentScript = $DatabaseRole.PatchDeployment

		$sqlScript = New-SqlCmdRunScript @otherParams @commonParams

		if(!$sqlScript){
			$retVal = 1
			return $retVal
		}

		$retVal = Invoke-SqlCmdRunScript @commonParams -ScriptToRun $sqlScript

		if($retVal -eq 0 -and !$NoDropRunFile){
			#Only remove on successful execution
			Remove-Item -Path $sqlScript -Force -ErrorAction Ignore
		}
	}

	$retVal
}

function Invoke-PatchDeploymentFolder{
[cmdletbinding()]
param(
	[Parameter()]
	[ValidateNotNull()]
	[string]$Username,
    [Parameter()]
	[AllowEmptyString()]
	[string]$Password
)

	$retVal = 0

	$patchFolderPath = $DatabaseRole.PatchDeploymentFolder

	if(!$patchFolderPath){
		return $retVal
	}

	Write-Host "Deploying database $($DatabaseRole.TargetDatabase) using the incremental patch upgrade process."

    $patchParams = @{
        Path                          = $DropFolder
        PatchFolderPath               = $patchFolderPath
        UpgradeScript                 = $DatabaseRole.UpgradeScript
        PreValidationScript           = $DatabaseRole.PreValidationScript
        PostValidationScript          = $DatabaseRole.PostValidationScript
        PatchLevelDeterminationScript = $DatabaseRole.PatchLevelDeterminationScript
        PatchFolderFormatStartsWith   = $DatabaseRole.PatchFolderFormatStartsWith
    }

	$patchData = Get-DatabasePatchUpgrades @patchParams #Deployment.Database.Module call

	if(!$patchData -or (Test-IsNullOrEmpty $patchData.PatchUpgrades)){
		Write-Host2 -Type Failure -Message "Unable to find any patch folders that match the Patch parameters for database $($DatabaseRole.TargetDatabase). Check configuration."
		$retVal = 1
		return $retVal
	}

	if(!$patchData.IsValid){
		$validationErrors = $patchData.ValidationErrors
		$validationErrors += $patchData.PatchUpgrades | ForEach-Object {
			$_.ValidationErrors
		}

		Write-Host2 -Type Failure -Message "Configuration of Patch definition for database $($DatabaseRole.TargetDatabase) is invalid."
		$validationErrors | ForEach-Object {
			Write-Error2 $_
		}
		$retVal = 1
		return $retVal
	}

	$script:otherParams.Type = 'Patch'
	$script:commonParams.TargetDatabase = $DatabaseRole.TargetDatabase

	$upgrades = $patchData.PatchUpgrades

	#TODO: Think about merging functionality of getting list of patch upgrades and running
	#determination level calls into C# binary module function
	$indexOfCurrentPatchLevel = Get-DatabasePatchingLevelOrdinal -UpgradeInfo $upgrades

	if($null -eq $indexOfCurrentPatchLevel){
		return $retVal
	}

	if($indexOfCurrentPatchLevel -lt 0){
		$retVal = 1
		return $retVal
	}

	$startIndex = $indexOfCurrentPatchLevel - 1

	$stopWatch = [Diagnostics.Stopwatch]::StartNew()

	Write-Host ""
	Write-host "Starting patching process: Script ordinal is $indexOfCurrentPatchLevel"

    for ($i = $startIndex; $i -gt -1; $i--) {

        $upgradeToApply = $upgrades[$i]
        $patchDeploymentScript = $upgradeToApply.UpgradeScriptPath

        if ($IntermediatePatchingFolder -and (!$IntermediatePatchingFolderInclude -and $upgradeToApply.FolderPath.Contains($IntermediatePatchingFolder))) {
            Write-Host "Stopping patching before $IntermediatePatchingFolder"
            break;
        }

        Write-Host ""
        Write-Host "Starting Pre-Validation script execution:"
        $patchValidationResult = Assert-PatchingValidation -ValidationScript $upgradeToApply.PreValidationScriptPath -PatchScript $patchDeploymentScript -Type "Pre"

        if (!$patchValidationResult.IsValid) {
            Write-Host "Pre-Validation of patching script failed. Stopping deployment of script."
            $retVal = 1
            $stopWatch.Stop()
            break
        }

        Write-Host ""
        Write-Host "Starting Patching script execution."
        $script:otherParams.DeploymentScript = $patchDeploymentScript

        $sqlScript = New-SqlCmdRunScript @otherParams @commonParams

        if (!$sqlScript) {
            $retVal = 1
            break
        }

        $cmdResult = Invoke-SqlCmdRunScript @commonParams -ScriptToRun $sqlScript

        if ($cmdResult -gt 0 -or ($LASTEXITCODE -and $LASTEXITCODE -ne 0)) {
            Write-Host2 -Type Failure -Message "The incremental patching database script failed: $patchDeploymentScript"
            $retVal = 1
            $stopWatch.Stop()
            break
        }

        Write-Host ""
        Write-Host "Starting Post-Validation script execution:"
        $patchValidationResult = Assert-PatchingValidation -ValidationScript $upgradeToApply.PostValidationScriptPath -PatchScript $patchDeploymentScript -Type "Post"

        if (!$patchValidationResult.IsValid) {
            $retVal = 1
            $stopWatch.Stop()
            break
        }

        if (!$NoDropRunFile) {
            #Only remove main script on successful execution
            Remove-Item -Path $sqlScript -Force -ErrorAction Ignore
        }

        if ($IntermediatePatchingFolder -and $upgradeToApply.FolderPath.Contains($IntermediatePatchingFolder)) {
            Write-Host "Stopping patching after $IntermediatePatchingFolder"
            $stopWatch.Stop()
            break
        }

        Write-Host2 -Type Progress -Message "Database Upgrade Incremental patching for $($upgradeToApply.UpgradeScriptPath)." -Elapsed $stopWatch.Elapsed
        $stopWatch.Restart()

    } #end for loop

	$retVal
}

function Invoke-CacheDependencySetup{
[cmdletbinding()]
param()

	$retVal = 0

    if (!$IsAuzre -and $DatabaseRole.EnableAspnetSqlInfo.Tables.Count -gt 0) {
		$stopWatch = [Diagnostics.Stopwatch]::StartNew()
		$targetDatabase = $DatabaseRole.TargetDatabase
		Write-Host "Enabling Aspnet SQL Cache Dependency on $targetDatabase"

		$command = "cmd /c C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regsql -S `"$Datasource`" -d `"$targetDatabase`" -ed -E"
		Write-Host "Executing command: '$command'"
		Invoke-Expression -Command $command -ErrorAction Stop | Out-Null

		if($LASTEXITCODE -and $LASTEXITCODE -ne 0)	{
			$retVal = 1
			Write-Host2 -Type Failure -Message "aspnet_regsql.exe exited with code $LASTEXITCODE. EnableAspnetSqlCacheDependency unsuccessful on $targetDatabase"
			$stopWatch.Stop()
			return $retVal
		}

		$results = $DatabaseRole.EnableAspnetSqlInfo.Tables | ForEach-Object {
			$result = 0
			Write-Host "  on table $_"

            $command = "cmd /c C:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regsql -S `"$Datasource`" -d `"$targetDatabase`" -E -et -t `"$_`""
		    Write-Host "Executing command: '$command'"
            Invoke-Expression -Command $command -ErrorAction Stop | Out-Null

            if($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
				$result = 1
				Write-Host2 -Type Failure -Message "aspnet_regsql.exe exited with code $LASTEXITCODE. EnableAspnetSqlCacheDependency unsuccessful on $_"
			}

			$result
		}

		$retVal = (Test-IsNullOrEmpty $results) | Get-ConditionalValue -TrueValue 0 -FalseValue ($results | Measure-Object -Maximum).Maximum

		Write-Host2 -Type Progress -Message "Database Asp.Net SQL Cache Dependency Setup deployment step." -Elapsed $stopWatch.Elapsed
		$stopWatch.Stop()
	}

	$retVal
}

function Invoke-PostDeployScript{
[cmdletbinding()]
param()

	$retVal = 0

	if($DatabaseRole.PostDeployment){
		$stopWatch = [Diagnostics.Stopwatch]::StartNew()

		Write-Host ""
		Write-Host "Starting Post-Deployment script execution:"

        $script:commonParams.TargetDatabase = $DatabaseRole.TargetDatabase
		$script:otherParams.DeploymentScript = $DatabaseRole.PostDeployment
		$script:otherParams.Type = "Post"

		$sqlScript = New-SqlCmdRunScript @otherParams @commonParams
		if(!$sqlScript){
			$retVal = 1
			return $retVal
		}

		$retVal = Invoke-SqlCmdRunScript @commonParams -ScriptToRun $sqlScriptpt

		if($retVal -eq 0 -and !$NoDropRunFile){
			#Only remove on successful execution
			Remove-Item -Path $sqlScript -Force -ErrorAction Ignore
		}

		Write-Host2 -Type Progress -Message "Database Build post deployment." -Elapsed $stopWatch.Elapsed
		$stopWatch.Stop()
	}

	$retVal
}

function Get-DatabasePatchingLevelOrdinal{
[cmdletbinding()]
param(
	[Parameter(Mandatory=$true)]
	[Deployment.Database.PatchUpgradeScriptInfo[]] $UpgradeInfo
	)

	[Deployment.Database.PatchUpgradeScriptInfo] $current = $null
	$currentOrdinal = 0

	$stopWatch = [Diagnostics.Stopwatch]::StartNew()

	$UpgradeInfo | Where-Object {$_.PatchOrdinal -eq $currentOrdinal} | ForEach-Object {
		$upgrade = $_
		$current = $null

		$assertResult = Assert-DatabaseMeetsPatchLevel -UpgradePatch $upgrade

        if(!$assertResult.IsValid){
			$currentOrdinal = -1
			Write-Host2 -Type Failure -Message "The incremental deployment patch for: [$($upgrade.DatabaseIsAtPatchLevelScriptPath)] is invalid. The validation message is: $($assertResult.ErrorMessage)"
			return #continue
		}

		if($assertResult.IsAtTestedPatchLevel){
			$current = $upgrade
			Write-Host "The database is at the level of scripts determined by the determiner script."
			Write-Host ""
			return #continue
		}

		Write-Host "The database is NOT at the level of scripts determined by the determiner script."
		$currentOrdinal++
	}

	$stopWatch.Stop()
	Write-Host2 -Type Progress -Message "Determining database upgrade status." -Elapsed $stopWatch.Elapsed

	if (!$current) {
		Write-Host2 -Type Failure -Message "The database patch level cannot be determined. Check configuration."
		return -1
	}

	$latestPatchInformation = $UpgradeInfo[0]

	if($current -eq $latestPatchInformation){
		Write-Host "The database is at the latest version and does not require upgrading."
		return $null
	}

	if($script:isDevEnvironment -and $IntermediatePatchingFolder -and $current.FolderPath.EndsWith($IntermediatePatchingFolder)){
		Write-Host "Stopping patching - already at $IntermediatePatchingFolder"
		return $null
	}

	$currentOrdinal
}

function Assert-DatabaseMeetsPatchLevel {
[cmdletbinding()]
param
(
    [Parameter(Mandatory=$true)]
    [Deployment.Database.PatchUpgradeScriptInfo] $UpgradePatch
)

	try {
		$patchDeploymentScript = $upgradePatch.DatabaseIsAtPatchLevelScriptPath
		Write-Host ""
		Write-Host "Testing database is at patching level using script $PatchDeploymentScript"

		$query = "exec deployment.PatchLevelDeterminationResultEmpty"
		$success = ($connectionString = Get-ConnectionString @commonParams) | Invoke-ExecuteNonQuery -CommandText $query

		if (!$success){
			Write-Host2 -Type Failure -Message "Failed to empty PatchingValidation tables"
			return $null
		}

		$script:commonParams.TargetDatabase = $DatabaseRole.TargetDatabase
		$script:otherParams.DeploymentScript = $patchDeploymentScript
		$script:otherParams.Type = "Patch"

		$sqlScript = New-SqlCmdRunScript @otherParams @commonParams

		if(!$sqlScript){
			return $null
		}

		$cmdResult = Invoke-SqlCmdRunScript @commonParams -ScriptToRun $sqlScript

		if ($cmdResult -ne 0 -or ($LASTEXITCODE -and $LASTEXITCODE -ne 0)) {
			Write-Host2 -Type Failure -Message $return.Message
			return $null
		}
        if (!$NoDropRunFile) {
            #Only remove on successful execution
            Remove-Item -Path $sqlScript -Force -ErrorAction Ignore
        }

		$patchLevelResult = Get-PatchingLevelResult -ConnectionString $connectionString
		$patchLevelResult
	}
	catch{
		Write-Host2 -Type Failure -Message "The incremental deployment patch for: [$PatchDeploymentScript] is invalid, validation result was: $patchLevelResult"
		Write-Error2 -ErrorRecord $_
		return $null
	}
}

function Assert-PatchingValidation {
    [cmdletbinding()]
    param
    (
		[Parameter(Mandatory=$true)]
        [string] $ValidationScript,
        [Parameter(Mandatory = $true)]
        [string] $PatchScript,
        [Parameter()]
        [ValidateSet("Pre", "Post")]
        [string] $Type
    )

    try {
        $query = "exec deployment.PatchingValidationEmpty"
        $success = ($connectionString = Get-ConnectionString @commonParams) | Invoke-ExecuteNonQuery -CommandText $query

        if (!$success) {
            Write-Host2 -Type Failure -Message $return.Message
            return $null
        }

        $script:commonParams.TargetDatabase = $DatabaseRole.TargetDatabase
        $script:otherParams.DeploymentScript = $ValidationScript
        $script:otherParams.Type = "Patch"

        $sqlScript = New-SqlCmdRunScript @otherParams @commonParams

        if (!$sqlScript) {
            return $null
        }

        $cmdResult = Invoke-SqlCmdRunScript @commonParams -ScriptToRun $sqlScript

        if ($cmdResult -ne 0 -or ($LASTEXITCODE -and $LASTEXITCODE -ne 0)) {
            Write-Host2 -Type Failure -Message $return.Message
            return $null
        }

        $patchValidationResult = $connectionString | Get-PatchingValidation -Type $Type

        if ($patchValidationResult.IsValid) {
            if (!$NoDropRunFile) {
                #Only remove on successful execution
                Remove-Item -Path $sqlScript -Force -ErrorAction Ignore
            }
        }
        else {
            $errorMessage = "The $type-validation database script for script $PatchDeploymentScript has validation errors:"
            Write-Host2 -Type Failure -Message $errorMessage
            Write-Host2 -Type Failure -Message $patchValidationResult.UserMessage

            $patchValidationResult.ErrorMessages | ForEach-Object {
                Write-Host "`t$_"
            }
        }

        $patchValidationResult
    }
    catch {
        Write-Error2 -ErrorRecord $_
        return $null
    }
}

$result = 0

$instanceName = "$ComputerName.$($DatabaseRole.DatabaseInstance)"

Write-Host ""
Write-Header "Starting role $DatabaseRole on $instanceName" -AsSubHeader

$timer = [Diagnostics.Stopwatch]::StartNew()

try {
	$functions = @(
		{Initialize-DatabaseDeployment }
		{Invoke-Baseline}
		{Invoke-PatchDeploymentScript}
		{Invoke-PatchDeploymentFolder}
		{Invoke-CacheDependencySetup}
		{Invoke-PostDeployScript}
	)

	$result = Invoke-UntilFail $functions
}
catch
{
	Write-Error2 -ErrorRecord $_
	$result = 1
}

$timer.Stop()

$SummaryLog | Write-Summary -Message "running role $DatabaseRole on $instanceName" -ScriptResult $result -Elapsed $timer.Elapsed
Write-Header "Ending role $DatabaseRole on $instanceName" -AsSubHeader

$result
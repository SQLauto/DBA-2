function Get-Datasource {
param(
	[Parameter(Mandatory=$true)]
	[string]$ComputerName,
	[string]$InstanceName = ""
)

	$datasource = $ComputerName

	if($InstanceName) {
		$datasource = "$ComputerName\$InstanceName"
	}

    $datasource
}

function Test-DatabaseExists {
param
(
    [Parameter(Mandatory=$true)]
	[string] $TargetDatabase,
	[Parameter(Mandatory=$true)]
	[string]$Datasource,
    [Parameter(ParameterSetName="UseSqlAuth")]
	[alias("UseSqlAuthentication")]
	[switch] $UseSqlAuth,
    [Parameter(ParameterSetName="UseSqlAuth")]
	[ValidateNotNull()]
	[string]$Username,
    [Parameter(ParameterSetName="UseSqlAuth")]
	[AllowEmptyString()]
	[string]$Password,
	[alias("IsAzureDeployment")]
	[switch] $IsAzure
)

	$query = "set nocount on; select case when exists(select 1 from sys.databases where name = '{0}') then 1 else 0 end" -f $TargetDatabase
	$PSBoundParameters.TargetDatabase = "master"

	$output = (Get-ConnectionString @PSBoundParameters) | Invoke-ExecuteScalar -CommandText $query

	$output -eq 1
}

function Get-ConnectionString{
param
(
    [Parameter(Mandatory=$true)]
	[string] $TargetDatabase,
    [Parameter(Mandatory=$true)]
	[string]$Datasource,
    [Parameter(ParameterSetName="UseSqlAuth")]
	[alias("UseSqlAuthentication")]
	[switch] $UseSqlAuth,
    [Parameter(ParameterSetName="UseSqlAuth")]
	[ValidateNotNull()]
	[string]$Username,
    [Parameter(ParameterSetName="UseSqlAuth")]
	[AllowEmptyString()]
	[string]$Password,
	[alias("IsAzureDeployment")]
	[switch] $IsAzure
)
	$connectionString = "Data Source='$Datasource';Initial Catalog='$TargetDatabase';Integrated Security=SSPI;MultipleActiveResultSets=True"

	if($UseSqlAuth){
		$connectionString = "Data Source='$Datasource';Initial Catalog='$TargetDatabase';User Id='$Username';Password='$Password';MultipleActiveResultSets=True"
	}
	$connectionString
}

function New-SqlCmdRunScript {
    param (
        [Parameter(Mandatory=$true)]
		[ValidateSet('Baseline','Pre','Patch','Post')]
        [string]$Type,
		[Parameter(Mandatory=$true)]
        [string]$DropFolder,
		[Parameter(Mandatory=$true)]
        [string]$DeploymentScript,
		[Parameter(Mandatory=$true)]
		[string]$ComputerName,
		[Parameter(Mandatory=$true)]
		[string]$Environment,
		[Parameter(Mandatory=$true)]
        [string]$HelperScriptRelativePath,
		[Parameter(Mandatory=$true)]
        [string]$ParameterFilePath,
        [Parameter(Mandatory=$false)]
        [string]$DataSource,
        [Parameter(Mandatory=$true)]
        [string]$TargetDatabase,
		[string]$DriveLetter,
		[string]$SqlScriptToRunSuffix,
        [Parameter(ParameterSetName="UseSqlAuth")]
		[alias("UseSqlAuthentication")]
		[switch]$UseSqlAuth,
        [Parameter(ParameterSetName="UseSqlAuth")]
		[ValidateNotNull()]
		[string]$Username,
        [Parameter(ParameterSetName="UseSqlAuth")]
		[AllowEmptyString()]
		[string]$Password,
		[alias("IsAzureDeployment")]
		[switch]$IsAzure
    )

    $deployFolder = Join-Path $DropFolder "Deployment"

	if (!(Test-Path $deployFolder)) {
		$deployFolder=$DropFolder
	}

	$helperScriptsPath = (Resolve-Path(Join-Path $deployFolder $HelperScriptRelativePath)).Path

	Write-Host "HelperScripts Path resolves to $helperScriptsPath"

	$sqlScript = $DeploymentScript

	#When running from a local DB setup, we pass in fully qualified paths to scripts
	#so we want to use that directly.
	if(!(Test-IsAbsolutePath $sqlScript)){
		$sqlScript = Join-Path $DropFolder $DeploymentScript
	}

	$params = @{
		ComputerName = $ComputerName
		ScriptPath = $sqlScript
		HelperScriptsPath = $helperScriptsPath
		ParameterFilePath = $ParameterFilePath
		Environment = $Environment
		DataSource = $DataSource
		TargetDatabase = $TargetDatabase
		DropFolder = $DropFolder
		SqlScriptToRunSuffix = $SqlScriptToRunSuffix
		DriveLetter = $DriveLetter
	}

	# generate modified sql script to run, this script will be the original but with all the sql command variables declared using 'setvar'
	$sqlScriptToRun = New-PatchScriptRunFile @params

	if(!$sqlScriptToRun -or (!(Test-Path $sqlScriptToRun))){
		Write-Host2 -Type Failure -Message "sqlScriptToRun is either null or does not exist."
		return $null
	}

    Write-Host "Modified sql script is $sqlScriptToRun"

    $sqlScriptToRun
}

function Invoke-SqlCmdRunScript {
[cmdletbinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		[string] $ScriptToRun,
		[Parameter(Mandatory=$true)]
		[string]$Datasource,
		[Parameter(Mandatory=$true)]
		[string] $TargetDatabase,
        [Parameter(ParameterSetName="UseSqlAuth")]
		[alias("UseSqlAuthentication")]
		[switch] $UseSqlAuth,
        [Parameter(ParameterSetName="UseSqlAuth")]
		[ValidateNotNull()]
		[string]$Username,
        [Parameter(ParameterSetName="UseSqlAuth")]
		[AllowEmptyString()]
		[string]$Password,
		[alias("IsAzureDeployment")]
		[switch] $IsAzure
	)

	$result = 0

	Write-Host "Executing script $ScriptToRun on $Datasource.$TargetDatabase"

	if ($UseSqlAuth) {
		(sqlcmd -U $Username -P $password -S $Datasource -d $TargetDatabase -i $ScriptToRun -b) | Out-String -Stream | Write-Host2 -NoConsole
	}
	else {
		# -b ensures we stop at the first error
		(sqlcmd -S $Datasource -E -d $TargetDatabase -i $ScriptToRun -b) | Out-String -Stream | Write-Host2 -NoConsole
	}

    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
		Write-Host2 -Type Failure -Message "Failed to execute script $ScriptToRun. Sqlcmd exited with exit code $LASTEXITCODE"
        return 1
    }

	Write-Host2 -Type Success -Message "Successfully executed script $ScriptToRun. Sqlcmd exited with exit code 0"
	$result
}
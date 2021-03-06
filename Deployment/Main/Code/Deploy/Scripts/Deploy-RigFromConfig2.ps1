#Requires -Version 5.0

<#
.SYNOPSIS

.PARAMETER DeploymentConfig
    The name of the deployment configuration file used to drive the deployment.
.PARAMETER Password
    The password used to decrypt service account info.
.PARAMETER DeploymentLogFolder
    The name of the folder where deployment logs will be created.
.PARAMETER Groups
    An array of group names to limit what deployment groups should be deployed
.PARAMETER Machines
    An array of server names to that will be used to filter the deployment target machines.
.PARAMETER ConfigOnly
    Switch to indicate if a configuration only deployment should be carried out.
.PARAMETER $EnableRemoting
    Switch to determine if remoting should be enabled on target machines
.PARAMETER SingleThreaded
    Switch to set for synchronous deployments. If not set, then default will be multithreaded. It will use Processor count to determine the number of threads to use
.PARAMETER LocalDebug
	Whether to run the script in local debug mode. Can be used in conjuction with SingleThreaded to make debugging easier.
.PARAMETER RigDeployment
    Switch to indicate whether a rig deployment is being performed. Setting this is important as it allows DataBase logging
.PARAMETER RigName
    The name of the the rig used when carrying out a rig deployment.
.PARAMETER PackageName
    The name of the package used when carrying out a rig deployment.
.PARAMETER DeploymentLogId
    The deployment logging ID used when carrying out a rig deployment.
.Parameter DriveLetter
	A letter of the drive on which the deployment will be carried out (D by default)
.PARAMETER NoDropRunFile
	A switch flag to indicate whether when doing database patching deployments, the generated .ToRun files are not deleted by default following successful execution.
.Parameter RigConfigFile
	A unique config file for a rig
#>

[cmdletbinding()]
param
(
	[parameter(Mandatory=$true, Position=0)]
	[ValidateNotNullOrEmpty()]
	[ValidatePattern('\.xml$')]
	[ValidateScript({Test-Path (Join-Path $PSScriptRoot $_)})]
	[string]$DeploymentConfig,
    [parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string]$Password,
	[Parameter()][string]$DeploymentLogFolder,
	[Parameter()][string[]]$Groups,
	[Parameter()][string[]]$Machines,
	[ValidateSet('PreReqs','PreDeploy','ServerRoles','DatabaseRoles','PostDeploy')]
	[string[]]$Roles = @('PreReqs','PreDeploy','ServerRoles','DatabaseRoles','PostDeploy'),
	[Parameter()]
	[ValidateSet('C','D')]
	[string]$DriveLetter = 'D',
	[Parameter()][switch]$ConfigOnly,
	[Parameter()][switch]$EnableRemoting,
	[Parameter()][switch]$SingleThreaded,
	[Parameter()][switch]$LocalDebug,
	[Parameter()][switch] $NoDropRunFile,
	[parameter(ParameterSetName="RigDeploy")]
	[switch]$RigDeployment,
	[parameter(ParameterSetName="RigDeploy")]
	[int]$DeploymentLogId = -1,
	[parameter(ParameterSetName="RigDeploy")]
	[string]$RigConfigFile = "",
	[parameter(ParameterSetName="RigDeploy")]
	[ValidateNotNullOrEmpty()]
	[string]$RigName,
	[parameter(ParameterSetName="RigDeploy")]
	[ValidateNotNullOrEmpty()]
	[string]$PackageName,
	[parameter(ParameterSetName="RigDeploy")]
	[string]$BuildNumber
)

Import-Module TFL.PowerShell.Logging -Force
Import-Module Tfl.Utilities -Force -ErrorAction Stop
Import-Module Tfl.Deployment -Force -ErrorAction Stop
Import-Module Tfl.Deployment.Database -Force -ErrorAction Stop
Import-Module Tfl.FileShare -Force -ErrorAction Stop
Import-Module TFL.ScheduledTask -Force -ErrorAction Stop
Import-Module (Join-Path $PSScriptRoot "Deploy-RigFromConfig2.Helper.psm1") -ErrorAction Stop

function Initialize-SummaryLog{
	if(-not $DeploymentLogFolder){
		$DeploymentLogFolder = Join-Path (Split-Path $dropFolder) "Logs"
	}

	Get-DeploymentLog -Prefix "DeploymentSummary" -Filename $configName  | Register-LogFile -WithHeader
}

function Get-DeploymentLog{
param(
	[parameter(Mandatory=$true, Position=0)]
	[ValidateNotNullOrEmpty()]
	[string]$Prefix,
	[parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[string]$Filename,
	[string]$Suffix,
	[string]$RelativePath = ""
)
	$suffixString = ""
	if($Suffix){
		$suffixString = "." + $Suffix
	}

	$groupString = ""
	if($Groups){
		$groupString = "." + ($Groups -join "_")
	}

	$logname = "{0}.{1}{2}{3}.log" -f $Prefix, $Filename, $suffixString, $groupString
	$path = Join-Path (Join-Path $DeploymentLogFolder $RelativePath) $logname

	$path
}

function Get-DeploymentInfo{
[cmdletbinding()]
param()

	#Get base deployment object first, do not filter until we know we are good to go.
    $baseDeployment = Get-Deployment -Path $dropFolder -Configuration $DeploymentConfig

	Set-Variable -Name "environment" -Value $baseDeployment.Environment -Scope "Script" -Option Constant -Force
	Set-Variable -Name "accountsFile" -Value (Join-Path $accountsPath "$environment.ServiceAccounts.xml") -Scope "Script" -Option Constant -Force
	Set-Variable -Name "baseConfig" -Value $baseDeployment.Configuration -Scope "Script" -Option Constant -Force

	Write-Host "Environment for deployment set to $script:environment"
	Write-Host "Base configuration for deployment set to $script:baseConfig"

	$groupsFile = Join-Path $groupsPath "DeploymentGroups.$($baseDeployment.ProductGroup).xml"

	#Get and validate Group filters (includes & excludes)
	$groupsFilters = Get-DeploymentGroupFilters -Groups $Groups -Path $groupsFile

	if(-not $groupsFilters){
		Write-Host2 -Type Failure -Message "Unable to validate groups for ProductGroup $ProductGroup"
		return $null
	}

	#filter deployment object accordingly
	$deployment = $baseDeployment | Get-Deployment -Groups $groupsFilters -Machines $Machines

	$deployment
}

function Update-DeploymentConfigs{
param([Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string[]]$Path)

	$Path | ForEach-Object {
		Write-Host "Updating deployment files in $_ with dynamic drive letter settings."
		Get-ChildItem -Path $_ -File -Filter *.xml | ForEach-Object {
			$replaced = (Get-Content $_.FullName) -replace '{DriveLetter}', $DriveLetter
			$replaced | Set-Content $_.FullName
		}
	}
}

function Start-Deployment {
[cmdletbinding()]
	param ($CommandName)

	$excludeList = @('DeploymentLogId','RigConfigFile','RigName','PackageName','BuildNumber','RigDeployment')

	 # Get the list of parameters for the command
    $parameterList = (Get-Command -Name $CommandName).Parameters

	# Grab each parameter value, using Get-Variable
    Write-Host ""
	Write-Host "Arguments"
	foreach ($parameter in $parameterList) {
		Get-Variable -Name $parameter.Values.Name -ErrorAction SilentlyContinue | Where-Object {$_.Name -ne 'Password' -and  $_.Name -notin $excludeList } | ForEach-Object {Write-Host "`t$($_.Name): $($_.Value)"}
    }

	if($RigDeployment){
		foreach ($parameter in $parameterList) {
			Get-Variable -Name $parameter.Values.Name -ErrorAction SilentlyContinue | Where-Object {$_.Name -ne 'Password' -and  $_.Name -in $excludeList } | ForEach-Object {Write-Host "`t$($_.Name): $($_.Value)"}
		}
	}

	$retVal = 0

	Update-DeploymentConfigs -Path $script:paramsPath,$PSScriptRoot

	$deployment = Get-DeploymentInfo

	if($null -eq $deployment) {
		Write-Host2 -Type Failure -Message "Unable to find any deployments for specified configuration '$DeploymentConfig'. Aborting deployment."
		$retVal = 12
		return $retVal
	}

	$numThreads = Get-ThreadCount $deployment.Machines.Count -SingleThreaded:$SingleThreaded

	Write-Host "`tThread Count: $numThreads"
	Write-Host ""

	Suspend-Logging $deploymentSummaryLog

	if($roles -contains 'PreReqs') {
		$retVal = Start-DeployServerPreRequisites -Deployment $deployment -ThreadCount $numThreads

		if($retVal -ne 0) {
			return $retVal
		}
	}

	if($roles -contains 'PreDeploy') {
		$retVal = Start-PreDeployRoles -Deployment $deployment -ThreadCount $numThreads

		if($retVal -ne 0) {
			return $retVal
		}
	}

	if($roles -contains 'ServerRoles') {
		$retVal = Start-DeployServerRoles -Deployment $deployment -ThreadCount $numThreads

		if($retVal -ne 0) {
			return $retVal
		}
	}

	if($ConfigOnly){
		return $retVal
	}

	if($roles -contains 'DatabaseRoles') {
		$retVal = Start-DeployDatabaseRoles -Deployment $deployment -ThreadCount $numThreads

		if($retVal -ne 0) {
			return $retVal
		}
	}

	if($roles -contains 'PostDeploy') {
		$retVal = Start-PostDeployRoles -Deployment $deployment -ThreadCount $numThreads
	}

	$retVal
}

function Start-DeployServerPreRequisites {
[cmdletbinding()]
param([Deployment.Domain.Deployment]$Deployment, [int]$ThreadCount)
	$deployMachineScript = Join-Path $PSScriptRoot "Deploy-MachinePreReqsFromConfig.ps1"

	if(!(Test-Path $deployMachineScript)){
		Write-Host2 -Type Failure -Message "Failed to find script '$deployMachineScript'";
		return 15 #DEFINE A SET A CONSTANT RETURN VALUES AND USE THOSE INSTEAD
		#throw "Failed to run pre-requisites. Aborting deployment"
	}

	Resume-Logging $deploymentSummaryLog

	Write-Header "Starting Pre-Requisite Deploy Roles" -AsSubHeader

	Suspend-Logging $deploymentSummaryLog

	$retVal = 0

	$roleTimer = [Diagnostics.Stopwatch]::StartNew()

	if($ThreadCount -eq 1){
		Write-Host "Deploying pre-req roles synchronously"

		if(!$LocalDebug){
			Suspend-Console
		}

		$results = $Deployment.Machines | ForEach-Object {
			$result = 0
			$machineLogPath = Get-DeploymentLog -Prefix "Deployment" -Filename $configName -Suffix $_.Name
			$machineLog = Register-LogFile -Path $machineLogPath

			try{
				$result = & $deployMachineScript -Machine $_ -SummaryLog $deploymentSummaryLog
			}
			finally{
				$machineLog | Unregister-LogFile -NoDetachHost
			}

			$result
		}

		$retVal = (Test-IsNullOrEmpty $results) | Get-ConditionalValue -TrueValue 0 -FalseValue ($results | Measure-Object -Maximum).Maximum
	}
	else{
		Write-Host "Deploying pre-req roles asynchronously"
		$retVal = Start-DeployServerPreRequisitesInParallel -Deployment $Deployment -ThreadCount $ThreadCount -DeployScript $deployMachineScript
	}

	Resume-Logging $deploymentSummaryLog

	Write-Header "Ending Pre-Requisite Deploy Roles" -AsSubHeader -Elapsed $roleTimer.Elapsed

	Suspend-Logging $deploymentSummaryLog

	Resume-Console

	$retVal
}

function Start-DeployServerPreRequisitesInParallel {
[cmdletbinding()]
param([Deployment.Domain.Deployment]$Deployment, [int]$ThreadCount, [string]$DeployScript)

	$func = {
		param (
			[parameter(Mandatory=$true)]
			[ValidateNotNullOrEmpty()]
			[string]$DeployMachineScript,
			[parameter(Mandatory=$true)]
			[ValidateNotNull()]
			[Deployment.Domain.Machine]$Machine,
			[parameter(Mandatory=$true)]
			[ValidateNotNullOrEmpty()]
			[string]$MachineLogPath,
			[parameter(Mandatory=$true)]
			[ValidateNotNull()]
			[TFL.PowerShell.Logging.LogFile]$SummaryLog
		)

		$result = 0
		$machineLog = Register-LogFile -Path $MachineLogPath -Append
		$SummaryLog = Register-LogFile -InputObject $SummaryLog -NoLog

		if(!$LocalDebug){
			Suspend-Console
		}

		try{
			$result = & $deployMachineScript -Machine $Machine -SummaryLog $SummaryLog
		}
		finally{
			$machineLog,$SummaryLog | Unregister-LogFile -NoDetachHost
		}

		$result
	}

	$poolArgs = @{
		ThreadCount = $ThreadCount
		ModulesToImport = "Tfl.Utilities","TFL.PowerShell.Logging","Tfl.Deployment",(Join-Path $PSScriptRoot "Deploy-RigFromConfig2.Helper.psm1")
		VariablesToImport = "enableRemoting","driveLetter"
	}

	$runspacePool = Initialize-RunspacePool @poolArgs
	$runspacePool.Open()

	$taskId = 0

	$tasks = $Deployment.Machines | ForEach-Object {
		$taskId++

		# set up thread/machine specific log files
		$machineLogPath = Get-DeploymentLog -Prefix "Deployment" -Filename $configName -Suffix $_.Name

		$powershell = [powershell]::Create().AddScript($func)
		$powershell = $powershell.AddParameter("DeployMachineScript", $DeployScript)
        $powershell = $powershell.AddParameter("Machine", $_)
		$powershell = $powershell.AddParameter("MachineLogPath", $machineLogPath)
		$powershell = $powershell.AddParameter("SummaryLog", $deploymentSummaryLog)

		$powershell.RunspacePool = $runspacePool

		[pscustomobject] @{
			Pipe = $powershell
			MachineName = $_.Name
			AsyncResult = $powershell.BeginInvoke()
			TaskId = $taskId
			Result = $null
		}
	}

	if(Test-IsNullOrEmpty $tasks){
		Write-Host "No Pre-Req deploy role jobs were generated. Returning."
		return 0
	}

	$params = @{
		RunspacePool = $runspacePool
		Tasks = $tasks
		TaskCount = $taskId
		Activity = "Deploying Pre-Requisites to target servers"
		ErrorResult = 0 #TODO: For now, make it so it does not fail build until more stable
		NoProgress = $RigDeployment.IsPresent
	}

	$results = Get-RunspaceData @params

	(Test-IsNullOrEmpty $results) | Get-ConditionalValue -TrueValue 1 -FalseValue ($results | Measure-Object -Maximum).Maximum
}

function Start-PreDeployRoles {
[cmdletbinding()]
param([Deployment.Domain.Deployment]$Deployment, [int]$ThreadCount)

	$deployMachineScript = Join-Path $PSScriptRoot "Deploy-MachinePreRolesFromConfig.ps1"

	if(!(Test-Path $deployMachineScript)){
		Write-Host2 -Type Failure -Message "Failed to find script '$deployMachineScript'"
		return 15 #DEFINE A SET A CONSTANT RETURN VALUES AND USE THOSE INSTEAD
	}

	Resume-Logging $deploymentSummaryLog

	Write-Header "Starting Pre-Deploy Deploy Roles" -AsSubHeader

	Suspend-Logging $deploymentSummaryLog

	$roleTimer = [Diagnostics.Stopwatch]::StartNew()

	if(!$LocalDebug){
		Suspend-Console
	}

	$results = $Deployment.Machines | Where-Object {$_.PreDeploymentRoles.Count -gt 0} | ForEach-Object {
		$result = 0
		$machineLogPath = Get-DeploymentLog -Prefix "Deployment" -Filename $configName -Suffix $_.Name
		$machineLog = Register-LogFile -Path $machineLogPath -Append

		try{
			$result = & $deployMachineScript -Machine $_ -SummaryLog $deploymentSummaryLog
		}
		finally{
			$machineLog | Unregister-LogFile -NoDetachHost
		}

		$result
	}

	$retVal = (Test-IsNullOrEmpty $results) | Get-ConditionalValue -TrueValue 0 -FalseValue ($results | Measure-Object -Maximum).Maximum

	Resume-Logging $deploymentSummaryLog

	Write-Header "Ending Pre-Deploy Deploy Roles" -AsSubHeader -Elapsed $roleTimer.Elapsed

	Suspend-Logging $deploymentSummaryLog

	Resume-Console

	$retVal
}

function Start-DeployServerRoles {
[cmdletbinding()]
param([Deployment.Domain.Deployment]$Deployment, [int]$ThreadCount)

	$retVal = 0

	$deployMachineScript = Join-Path $PSScriptRoot "Deploy-MachineFromConfig.ps1"

	if(!(Test-Path $deployMachineScript)){
		Write-Host2 -Type Failure -Message "Failed to find script '$deployMachineScript'";
		return 15 #DEFINE A SET A CONSTANT RETURN VALUES AND USE THOSE INSTEAD
	}

	Resume-Logging $deploymentSummaryLog

	Write-Header "Starting Server Deploy Roles" -AsSubHeader

	Suspend-Logging $deploymentSummaryLog

	$roleTimer = [Diagnostics.Stopwatch]::StartNew()

	if($ThreadCount -eq 1){
		Write-Host "Deploying server roles synchronously"

		if(!$LocalDebug){
			Suspend-Console
		}

		$results = $Deployment.Machines | Where-Object {$_.DeploymentRoles.Count -gt 0} | ForEach-Object {
			$result = 0
			$machineLogPath = Get-DeploymentLog -Prefix "Deployment" -Filename $configName -Suffix $_.Name
			$machineLog = Register-LogFile -Path $machineLogPath -Append

			try{
				$result = & $deployMachineScript -Machine $_ -SummaryLog $deploymentSummaryLog
			}
			finally{
				$machineLog | Unregister-LogFile -NoDetachHost
			}

			$result
		}

		$retVal = (Test-IsNullOrEmpty $results) | Get-ConditionalValue -TrueValue 0 -FalseValue ($results | Measure-Object -Maximum).Maximum
	}
	else{
		Write-Host "Deploying server roles asynchronously."
		$retVal = Start-DeployServerRolesInParallel -Deployment $Deployment -ThreadCount $ThreadCount -DeployScript $deployMachineScript
	}

	Resume-Logging $deploymentSummaryLog

	Write-Header "Ending Server Deploy Roles" -AsSubHeader -Elapsed $roleTimer.Elapsed

	Suspend-Logging $deploymentSummaryLog

	Resume-Console

	$retVal
}

function Start-DeployServerRolesInParallel {
[cmdletbinding()]
param([Deployment.Domain.Deployment]$Deployment, [int]$ThreadCount, [string]$DeployScript)

	$func = {
		param (
			[parameter(Mandatory=$true)]
			[ValidateNotNullOrEmpty()]
			[string]$DeployMachineScript,
			[parameter(Mandatory=$true)]
			[ValidateNotNull()]
			[Deployment.Domain.Machine]$Machine,
			[parameter(Mandatory=$true)]
			[ValidateNotNullOrEmpty()]
			[string]$MachineLogPath,
			[parameter(Mandatory=$true)]
			[ValidateNotNull()]
			[TFL.PowerShell.Logging.LogFile]$SummaryLog
		)

		$result = 0
		$machineLog = Register-LogFile -Path $MachineLogPath -Append
		$SummaryLog = Register-LogFile -InputObject $SummaryLog -NoLog

		if(!$LocalDebug){
			Suspend-Console
		}

		try{
			$result = & $DeployMachineScript -Machine $Machine -SummaryLog $SummaryLog
		}
		finally{
			$machineLog,$SummaryLog | Unregister-LogFile -NoDetachHost
		}

		$result
    }

	$poolArgs = @{
		ThreadCount = $ThreadCount
		ModulesToImport = "Tfl.Utilities","TFL.PowerShell.Logging","Tfl.Deployment","Tfl.ScheduledTask","Tfl.FileShare",(Join-Path $PSScriptRoot "Deploy-RigFromConfig2.Helper.psm1")
		VariablesToImport = "dropFolder","accountsFile","baseConfig","commonSoftwarePath","environment","configOnly","password","driveLetter","rigName","rigConfigFile"
	}

	$runspacePool = Initialize-RunspacePool @poolArgs
	$runspacePool.Open()

	$taskId = 0

	$tasks = $Deployment.Machines | Where-Object {$_.DeploymentRoles.Count -gt 0} | ForEach-Object {
		$taskId++

		# set up thread specific log files - one for each thread
		$machineLogPath = Get-DeploymentLog -Prefix "Deployment" -Filename $configName -Suffix $_.Name

		$powershell = [powershell]::Create().AddScript($func)
		$powershell = $powershell.AddParameter("DeployMachineScript", $DeployScript)
        $powershell = $powershell.AddParameter("Machine", $_)
		$powershell = $powershell.AddParameter("MachineLogPath", $machineLogPath)
		$powershell = $powershell.AddParameter("SummaryLog", $deploymentSummaryLog)

	    $powershell.RunspacePool = $runspacePool

		[pscustomobject] @{
			Pipe = $powershell
			MachineName = $_.Name
			AsyncResult = $powershell.BeginInvoke()
			TaskId = $taskId
			Result = $null
		}
	}

	if(Test-IsNullOrEmpty $tasks){
		Write-Host "No server deploy role jobs were generated. Returning."
		return 0
	}

	$params = @{
		RunspacePool = $runspacePool
		Tasks = $tasks
		TaskCount = $taskId
		Activity = "Deploying Server Roles to target servers"
		ErrorResult = 1 #Setting ErrorResult to 1 will mean uncaught/unhandled errors in stream will cause build to fail
		NoProgress = $RigDeployment.IsPresent
	}

	$results = Get-RunspaceData @params

	(Test-IsNullOrEmpty $results) | Get-ConditionalValue -TrueValue 1 -FalseValue ($results | Measure-Object -Maximum).Maximum
}

function Start-DeployDatabaseRoles {
[cmdletbinding()]
param([Deployment.Domain.Deployment]$Deployment, [int]$ThreadCount)

	$instanceCount = $Deployment.SqlInstances.Count

	if($instanceCount -eq 0){
		return 0
	}

	$deployMachineScript = Join-Path $PSScriptRoot "Deploy-SqlInstanceFromConfig.ps1"

	if(!(Test-Path $deployMachineScript)){
		Write-Host2 -Type Failure -Message "Failed to find script '$deployMachineScript'";
		return 15 #DEFINE A SET A CONSTANT RETURN VALUES AND USE THOSE INSTEAD
	}

	Resume-Logging $deploymentSummaryLog

	Write-Header "Starting Database Deploy Roles" -AsSubHeader

	Suspend-Logging $deploymentSummaryLog

	$retVal = 0

	$roleTimer = [Diagnostics.Stopwatch]::StartNew()

	if($instanceCount -eq 1 -or $ThreadCount -eq 1){
		Write-Host "Deploying database roles synchronously"

		if(!$LocalDebug){
            Suspend-Console
        }

		$results = $Deployment.SqlInstances | Where-Object {$_.DatabaseRoles.Count -gt 0} | ForEach-Object {
			$result = 0
			$machineLogPath = Get-DeploymentLog -Prefix "Deployment" -Filename $configName -Suffix $_.DisplayName
			$machineLog = Register-LogFile -Path $machineLogPath -Append

			try{
				$result = & $deployMachineScript -SqlInstance $_ -SummaryLog $deploymentSummaryLog
			}
			finally{
				$machineLog | Unregister-LogFile -NoDetachHost
			}

			$result
		}

		$retVal = (Test-IsNullOrEmpty $results) | Get-ConditionalValue -TrueValue 0 -FalseValue ($results | Measure-Object -Maximum).Maximum
	}
	else{
		Write-Host "Deploying database roles asynchronously."
		$retVal = Start-DeployDatabaseRolesInParallel -Deployment $Deployment -ThreadCount $ThreadCount -DeployScript $deployMachineScript
	}

	Resume-Logging $deploymentSummaryLog

	Write-Header "Ending Database Deploy Roles" -AsSubHeader -Elapsed $roleTimer.Elapsed

	Suspend-Logging $deploymentSummaryLog

	Resume-Console

	$retVal
}

function Start-DeployDatabaseRolesInParallel {
[cmdletbinding()]
param([Deployment.Domain.Deployment]$Deployment, [int]$ThreadCount, [string]$DeployScript)

	$func = {
		param (
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$DeployMachineScript,
		[parameter(Mandatory=$true)]
		[ValidateNotNull()]
		[Deployment.Domain.SqlInstance]$SqlInstance,
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$MachineLogPath,
		[parameter(Mandatory=$true)]
		[ValidateNotNull()]
		[TFL.PowerShell.Logging.LogFile]$SummaryLog
		)

		$result = 0
		$machineLog = Register-LogFile -Path $MachineLogPath -Append
		$SummaryLog = Register-LogFile -InputObject $SummaryLog -NoLog

		if(!$LocalDebug){
			Suspend-Console
		}

		try{
			$result = & $DeployMachineScript -SqlInstance $SqlInstance -SummaryLog $SummaryLog
		}
		finally{
			$machineLog,$SummaryLog | Unregister-LogFile -NoDetachHost
		}

		$result
	}

	$poolArgs = @{
		ThreadCount = $ThreadCount
		ModulesToImport = "Tfl.Utilities","TFL.PowerShell.Logging","Tfl.Deployment","Tfl.Deployment.Database",(Join-Path $PSScriptRoot "Deploy-RigFromConfig2.Helper.psm1")
		VariablesToImport = "dropFolder","baseConfig","environment","driveLetter","rigName","rigConfigFile","noDropRunFile"
	}

	$runspacePool = Initialize-RunspacePool @poolArgs
	$runspacePool.Open()

	$taskId = 0

	$tasks = $Deployment.SqlInstances | Where-Object {$_.DatabaseRoles.Count -gt 0} | ForEach-Object {
		$taskId+=1

		# set up thread specific log files - one for each thread
		$machineLogPath = Get-DeploymentLog -Prefix "Deployment" -Filename $configName -Suffix $_.DisplayName

		$powershell = [powershell]::Create().AddScript($func)
		$powershell = $powershell.AddParameter("DeployMachineScript", $DeployScript)
        $powershell = $powershell.AddParameter("SqlInstance", $_)
		$powershell = $powershell.AddParameter("MachineLogPath", $machineLogPath)
		$powershell = $powershell.AddParameter("SummaryLog", $deploymentSummaryLog)

	    $powershell.RunspacePool = $runspacePool

		[pscustomobject] @{
			Pipe = $powershell
			MachineName = $_.Name
			AsyncResult = $powershell.BeginInvoke()
			TaskId = $taskId
			Result = $null
		}
	}

	if(Test-IsNullOrEmpty $tasks){
		Write-Host "No database deploy role jobs were generated. Returning."
		return 0
	}

	$params = @{
		RunspacePool = $runspacePool
		Tasks = $tasks
		TaskCount = $taskId
		Activity = "Deploying Database Roles to target instances"
		ErrorResult = 0 #TODO: For now, make it so it does not fail build until more stable
		NoProgress = $RigDeployment.IsPresent
	}

	$results = Get-RunspaceData @params

	(Test-IsNullOrEmpty $results) | Get-ConditionalValue -TrueValue 1 -FalseValue ($results | Measure-Object -Maximum).Maximum
}

function Start-PostDeployRoles {
[cmdletbinding()]
param([Deployment.Domain.Deployment]$Deployment, [int]$ThreadCount)

	$deployMachineScript = Join-Path $PSScriptRoot "Deploy-MachinePostRolesFromConfig.ps1"

	if(!(Test-Path $deployMachineScript)){
		Write-Host2 -Type Failure -Message "Failed to find script '$deployMachineScript'"
		return 15 #DEFINE A SET A CONSTANT RETURN VALUES AND USE THOSE INSTEAD
		#throw "Failed to run pre-requisites. Aborting deployment"
	}

	Resume-Logging $deploymentSummaryLog

	Write-Header "Starting Post-Deploy Deploy Roles" -AsSubHeader

	Suspend-Logging $deploymentSummaryLog

	$roleTimer = [Diagnostics.Stopwatch]::StartNew()

	if(!$LocalDebug){
		Suspend-Console
	}

	$results = $Deployment.Machines | Where-Object {$_.PostDeploymentRoles.Count -gt 0} | ForEach-Object {
		$result = 0
		$machineLogPath = Get-DeploymentLog -Prefix "Deployment" -Filename $configName -Suffix $_.Name
		$machineLog = Register-LogFile -Path $machineLogPath -Append

		try{
			$result = & $deployMachineScript -Machine $_ -SummaryLog $deploymentSummaryLog
		}
		finally{
			$machineLog | Unregister-LogFile -NoDetachHost
		}

		$result
	}

	$retVal = (Test-IsNullOrEmpty $results) | Get-ConditionalValue -TrueValue 0 -FalseValue ($results | Measure-Object -Maximum).Maximum

	Resume-Logging $deploymentSummaryLog

	Write-Header "Ending Post-Deploy Deploy Roles" -AsSubHeader -Elapsed $roleTimer.Elapsed

	Suspend-Logging $deploymentSummaryLog

	Resume-Console

	$retVal
}

$exitCode = 0

Set-Variable -Name "deploymentFolder" -Value ($PSScriptRoot | Split-Path) -Scope "Script" -Option Constant -Force
Set-Variable -Name "dropFolder" -Value ($deploymentFolder | Split-Path) -Scope "Script" -Option Constant -Force
Set-Variable -Name "paramsPath" -Value (Join-Path $deploymentFolder "Parameters") -Scope "Script" -Option Constant -Force
Set-Variable -Name "groupsPath" -Value (Join-Path $deploymentFolder "Groups") -Scope "Script" -Option Constant -Force
Set-Variable -Name "toolsPath" -Value (Join-Path $deploymentFolder "Tools") -Scope "Script" -Option Constant -Force
Set-Variable -Name "accountsPath" -Value (Join-Path $deploymentFolder "Accounts") -Scope "Script" -Option Constant -Force
Set-Variable -Name "commonSoftwarePath" -Value (Join-Path $deploymentFolder "Software\Common") -Scope "Script" -Option Constant -Force
Set-Variable -Name "configName" -Value ([System.IO.Path]::GetFileNameWithoutExtension($DeploymentConfig)) -Scope "Script" -Option Constant -Force
Set-Variable -Name "deploymentSummaryLog" -Value (Initialize-SummaryLog) -Scope "Script" -Option ReadOnly -Force

$mainTimer = [Diagnostics.Stopwatch]::StartNew()

try{
	if($RigDeployment){
		if($DeploymentLogId -lt 0){
			Write-Host "Initialising deployment logging"
			$DeploymentLogId = New-DeploymentLogId -RigName $RigName -PackageName $PackageName -ComputerName $env:COMPUTERNAME -ScriptName $MyInvocation.ScriptName
		}

		$logEvents = @{
			BUILDNUMBER = $BuildNumber
			EVENTID = "BeginDeployRig"
		}

		Write-DeploymentLog -DeploymentLogId $DeploymentLogId -LogEvents $logEvents | Out-Null
	}

	$commandName = $PSCmdlet.MyInvocation.InvocationName

	if(!$commandName){
		$commandName = $MyInvocation.InvocationName
	}

	$exitCode = Start-Deployment $commandName

	Resume-Logging $deploymentSummaryLog

	if($RigDeployment){
		Write-DeploymentLog -DeploymentLogId $DeploymentLogId -LogEvents @{EVENTID = "EndDeployRig"} | Out-Null
	}

	$message = ($exitCode -eq 0) | Get-ConditionalValue -TrueValue "All roles successfully deployed." -FalseValue "Errors encountered, not all roles successfully deployed."

	$deploymentSummaryLog | Write-Summary -Message $message -ScriptResult $exitCode -NoSuspend
}
catch{
	$exitCode = 100
    Resume-Console
	Write-Error2 -ErrorRecord $_
}
finally{
	$mainTimer.Stop()
	Write-Header "Ending deployment for $DeploymentConfig. Exiting with code $exitCode" -AsSubHeader -OutConsole -Elapsed $mainTimer.Elapsed
	$deploymentSummaryLog | Unregister-LogFile
}

Remove-Module Tfl.Deployment.Database
Remove-Module TFL.ScheduledTask
Remove-Module Tfl.FileShare
Remove-Module TFL.PowerShell.Logging
Remove-Module Tfl.Deployment
Remove-Module Tfl.Utilities

$exitCode
[cmdletbinding()]
param
(
	[parameter(Mandatory=$true, Position = 0)]
	[string] $RigName,
	[parameter(Mandatory=$true)]
	[string] $RigTemplateName,
	[switch] $ForceRefresh
    #[switch] $EnableFirewall
)

$modulePath = Join-Path $PSScriptRoot "Modules"

[Environment]::SetEnvironmentVariable("PSModulePath",  [Environment]::GetEnvironmentVariable("PSModulePath","Machine"))
$env:PSModulePath = "$modulePath;" + $env:PSModulePath

Import-Module TFL.PowerShell.Logging -Force
Import-Module TFL.Deployment.VCloud -Force -ErrorAction Stop
Import-Module TFL.Deployment.Database -Force -ErrorAction Stop

function Write-ErrorDeploymentLog{
param(
	[int]$ErrorCode,
	[string]$LastError,
	[string]$EventId = "ExitInitSession",
	[switch]$VCloud
)

	$logEvents = @{
		EVENTID = $EventId
		EXITCODE = $ErrorCode
		LASTERROR = "$LastError Exiting with code $ErrorCode"
	}

	if($LastException){
		$logEvents.LASTEXCEPTION = $LastException
	}

	if($LastError){
		Write-Error $LastError
	}

	Write-DeploymentLog -DeploymentLogId $script:deploymentLogId -LogEvents $logEvents -VCloud:$VCloud  | Out-Null
}

function Get-StartingState{
[cmdletbinding()]
param()

	Write-Host "Getting status of Rig $RigName from VCloud."

	try {
		$logEvents = @{
			STARTSTATE = "Does-not-Exist : ForceRefresh  $($ForceRefresh.IsPresent)"
		}

		$script:vApp = Get-VApp -Name $RigName

		$vAppStartingState = @{
			Exists    = $false
			Deployed = $false
			State    = $null
		}

		if($vApp){
			$isDeployed = $vApp.IsDeployed()
			$state = $vApp| Get-AppStatusString

			if($isDeployed){
				$logEvents.STARTSTATE = "Exists-Deployed-$state : ForceRefresh $($ForceRefresh.IsPresent)"
			}
			else{
				$logEvents.STARTSTATE = "Exists-Undeployed-$state : ForceRefresh $($ForceRefresh.IsPresent)"
			}

			$vAppStartingState.Exists = $true
			$vAppStartingState.Deployed = $isDeployed
			$vAppStartingState.State = $state
		}

		Write-DeploymentLog -DeploymentLogId $script:deploymentLogId -LogEvents $logEvents -VCloud | Out-Null
	}
	catch {
		Write-ErrorDeploymentLog -ErrorCode 2001 -LastError "Error getting rig state from vCloud for vApp '$RigName'." -VCloud
		Write-Error2 -ErrorRecord $_
	}

	$retVal = (New-Object PSObject -Property $vAppStartingState)

	Write-Host "Exists: $($retVal.Exists)"
	Write-Host "Deployed: $($retVal.Deployed)"
	Write-Host "State: $($retVal.State)"

	$retVal
}

function Invoke-RemoveVApp {
[cmdletbinding()]
param ()

	$success = $true
	try {
		Write-DeploymentLog -DeploymentLogId $deploymentLogId -LogEvents @{EVENTID = "BeginRemoveCiVapp"} -VCloud | Out-Null

		Write-Host "Deleting vApp $RigName"

		$success = $script:vApp | Remove-VApp

		if($success){
			Write-Host "Successfully deleted vApp $RigName"
			Remove-Variable -Name "vApp" -Scope Script
		}
		else{
			Write-Warning "Failed to delete vApp $RigName"
		}

		Write-DeploymentLog -DeploymentLogId $deploymentLogId -LogEvents @{EVENTID = "EndRemoveCiVapp"} -VCloud | Out-Null
	}
	catch {
		Write-ErrorDeploymentLog -ErrorCode 2003 -LastError "Error deleting vApp rig '$RigName'." -VCloud
		Write-Error2 -ErrorRecord $_
		$success = $false
	}

	$success
}

function Invoke-StartVApp {
[cmdletbinding()]
	param
	()

	$success = $true
	try {
		Write-DeploymentLog -DeploymentLogId $deploymentLogId -LogEvents @{EVENTID = "BeginStartCiVapp"} -VCloud | Out-Null

		Write-Host "Starting vApp $RigName"

		$app =  $script:vApp | Start-VApp

		if($app) {

			Write-Host "Started vApp $RigName"

			Write-DeploymentLog -DeploymentLogId $deploymentLogId -LogEvents @{EVENTID = "EndStartCiVapp"} -VCloud | Out-Null

			Remove-Variable -Name "vApp" -Scope Script
			Set-Variable -Name "vApp" -Value $app -Scope Script
		}
		else{
			$success = $false
			Write-Warning "Failed to start vApp $RigName"
		}
	}
	catch {
		Write-ErrorDeploymentLog -ErrorCode 2010 -LastError "Error starting vApp rig '$RigName'." -VCloud
		Write-Error2 -ErrorRecord $_
		$success = $false
	}

	$success
}

function Invoke-StopVApp {
[cmdletbinding()]
param()

	$success = $true
	try {
		Write-DeploymentLog -DeploymentLogId $deploymentLogId -LogEvents @{EVENTID = "BeginStopCiVapp"} -VCloud | Out-Null

		Write-Host "Stopping vApp $RigName"

		$success = $script:vApp | Stop-VApp

		if($success){
			Write-Host "Stopped vApp $RigName"
		}
		else{
			Write-Warning "Failed to stop vApp $RigName"
		}

		Write-DeploymentLog -DeploymentLogId $deploymentLogId -LogEvents @{EVENTID = "EndStopCiVapp"} -VCloud | Out-Null
	}
	catch {
		Write-ErrorDeploymentLog -ErrorCode 2011 -LastError "Error stopping vApp rig '$RigName'." -VCloud
		Write-Error2 -ErrorRecord $_
		$success = $false
	}

	$success
}

function Invoke-NewVAppFromTemplate {
[cmdletbinding()]
param()
	$success = $true
	try {
		Write-DeploymentLog -DeploymentLogId $deploymentLogId -LogEvents @{EVENTID = "BeginNewVappFromTemplate"} -VCloud | Out-Null
		Write-Host "Creating vApp $RigName from template $RigTemplateName"

		Write-DeploymentLog -DeploymentLogId $deploymentLogId -LogEvents @{EVENTID = "BeginNewCiVapp"} -VCloud | Out-Null

		$script:vApp = New-VAppFromTemplate -Name $RigName -Template $RigTemplateName

		Write-DeploymentLog -DeploymentLogId $deploymentLogId -LogEvents @{EVENTID = "EndNewCiVapp"} -VCloud | Out-Null

		if($script:vApp){
			Write-Host "Created vApp $RigName from template $RigTemplateName"
		}
		else{
			Write-Warning "Failed to create vApp $RigName from template $RigTemplateName"
			$success = $false
		}

		Write-DeploymentLog -DeploymentLogId $deploymentLogId -LogEvents @{EVENTID = "ExitNewVappFromTemplate"} -VCloud | Out-Null
	}
	catch {
		Write-ErrorDeploymentLog -ErrorCode 2002 -LastError "Error creating new vApp rig '$RigName'." -VCloud
		Write-Error2 -ErrorRecord $_
		$success = $false
	}

	$success
}

function Invoke-GrantVApp {
[cmdletbinding()]
param()
	$success = $true
	try {
		Write-Host "Sharing vApp $RigName with ROLE-G_CEvCUser,ROLE-G-CEvCPowerUser with Full Control"

		$script:vApp | Grant-VAppRights -Group "ROLE-G-CEvCPowerUser" -AccessLevel "FullControl"
		$script:vApp | Grant-VAppRights -Group "ROLE-G-CEvCUser" -AccessLevel "FullControl"
	}
	catch {
		Write-ErrorDeploymentLog -ErrorCode 2004 -LastError "Error sharing vApp rig '$RigName'." -VCloud
		Write-Error2 -ErrorRecord $_
		$success = $false
	}
	$success
}

function Start-Setup {
[cmdletbinding()]
param()

	$retVal = 0

	Write-Host "Initialise deployment logging"
	$script:deploymentLogId = New-DeploymentLogId -RigName $RigName -ComputerName $env:COMPUTERNAME -ScriptName $Myinvocation.ScriptName -PackageName "a" -VCloud
	Write-Host "##vso[task.setvariable variable=VCLOUDDEPLOYMENTID;]$script:deploymentLogId"
	
	Write-Host "Logging deployment ID: $script:deploymentLogId"
	Write-Host ""

	Write-DeploymentLog -DeploymentLogId $deploymentLogId -LogEvents @{EVENTID = "EnterExecuteRefreshVapp"} -VCloud | Out-Null

	Write-DeploymentLog -DeploymentLogId $deploymentLogId -LogEvents @{EVENTID = "EnterInitSession"} -VCloud | Out-Null

	$vAppStartingState = Get-StartingState

	if($vAppStartingState.Exists){

		if($ForceRefresh) {
			Write-Host "Force Refresh is enabled"
			if($vAppStartingState.Deployed) {
				Write-Host "vApp $RigName exists and running. Stopping vApp"
				if(-not (Invoke-StopVApp)) {
					$retVal = 2011
					return $retVal
				}
			}

			Write-Host "vApp $RigName will now be deleted, created and started"
			$success = Invoke-RemoveVapp

			if(!$success){
				$retVal = 2003
				return $retVal
			}

			$success = Invoke-NewVAppFromTemplate

			if(!$success){
				$retVal = 2002
				return $retVal
			}

			#get status again as rig is new
			$vAppStartingState = Get-StartingState

			if(!$vAppStartingState.Exists){
				Write-Warning "Failed to create rig $RigName."
				$retVal = 2002
				return $retVal
			}

			if(-not (Invoke-StartVApp)) {
				$retVal = 2010
				return $retVal
			}
		}
		else{
			if($vAppStartingState.Deployed) {
				Write-Host "VApp $RigName exists and is started. No action needed."
			}
			else{
				Write-Host "vApp $RigName is not started. Starting vApp for use"

				if(-not (Invoke-StartVapp)) {
					$retVal = 2010
					return $retVal
				}
			}
		}
	}
	else{
		Write-Host "vApp $RigName does not exist. vApp will now be created and started"

		$success = Invoke-NewVAppFromTemplate

		if(!$success){
			$retVal = 2002
			return $retVal
		}

		#get status again as rig is new
		$vAppStartingState = Get-StartingState

		if(!$vAppStartingState.Exists){
			Write-Warning "Failed to create rig $RigName."
			$retVal = 2002
			return $retVal
		}

		if(-not (Invoke-StartVApp)) {
			$retVal = 2010
			return $retVal
		}
	}

	if(-not (Invoke-GrantVApp)) {
		$retVal = 2004
		return $retVal
	}

	#start should have run and verified all vm's started.

    #Firewall configuration goes here, need to update build step once in main(leave commented until then)
    <#if($enablefirewall -ne $null){
       [bool]$result = set-firewallconfig -rigname $RigName -setupfirewall $EnableFirewall
       if($enablefirewall -eq $false){
            Write-Host "Firewall has been Disabled"
       }
       else{
            Write-Host "Firewall has been Enabled"
       }
    }
    else{
        Write-Host "No changes to firewall"
    }    #>


	#TODO: Do we need to wait longer to get IP?
	Write-Host "Getting VApp Resource ID"
	$vAppGuid = $script:vApp | Get-VAppResourceId

	Write-Host "VApp Resource ID:$vAppGuid"
	$env:RigResourceID = $vAppGuid

	Write-DeploymentLog -DeploymentLogId $deploymentLogId -LogEvents @{VAPPGUID = $vAppGuid} -VCloud | Out-Null

	Write-Host "vApp $RigName is ready for use, all machines deployed correctly, script exiting with code 0"

	Write-DeploymentLog -DeploymentLogId $deploymentLogId -LogEvents @{EVENTID = "ExitExecuteRefreshVapp"} -VCloud | Out-Null

	$retVal
}

$vCloudPassword = ConvertTo-SecureString "P0wer5hell" -AsPlainText -Force
$vCloudParams = @{
	Url = "https://vcloud.onelondon.tfl.local"
	Organisation = "ce_organisation_td"
	Username = "zSVCCEVcloudBuild"
	Password = $vCloudPassword
}

$exitCode = 0
Write-Host "Initialising VCloud connection...."
$vCloud = Connect-VCloud @vCloudParams

try{
	$exitCode = Start-Setup
}
catch{
	Write-Error2 -ErrorRecord $_
	$exitCode = 1
}
finally{
	Write-Host "Closing VCloud connection."
	$vCloud | Disconnect-VCloud
}

Remove-Module TFL.PowerShell.Logging
Remove-Module TFL.Deployment.VCloud
Remove-Module TFL.Deployment.Database

$exitCode
[cmdletbinding()]
param
(
    [parameter(Mandatory=$true)][string] $ComputerName,
	[Deployment.Domain.Roles.SmtpDeploy]$DeployRole
)

function Start-SmtpDeploy{
[cmdletbinding()]
param()

	$retVal = 0
	$dropFolderLocation = $DeployRole.DropFolderLocation
	$forwardingMailSMTP = $DeployRole.ForwardingMailSmtp

	$resourcepath = Join-Path $PSScriptRoot "RealyIpList.txt"
	$smtpIpList = Get-Content $resourcepath
	$smtpRemoteScriptFile = Join-Path $PSScriptRoot "TFL.SMTPDeploy.Remote.ps1"

	Write-Host "Installing and Configuring SMTP Server"

	if ($ComputerName -in {$env:computername,"localhost"}) {
		$output = & $smtpRemoteScriptFile -DropFolderLocation $dropFolderLocation -ForwardingMailSMTP $forwardingMailSMTP -SmtpIpList $smtpIpList
	}
	else {
		$output = Invoke-Command -ComputerName $ComputerName -FilePath $smtpRemoteScriptFile -ArgumentList $dropFolderLocation,$forwardingMailSMTP,$smtpIpList
	}

	$retVal = $output.ExitCode
	#TODO: Process errors etc.
	$retVal
}


$result = 0
#$role = "SMTPDeploy and Configuration"

Write-Host ""
Write-Header "Starting role $DeployRole on $ComputerName." -AsSubHeader
$timer = [Diagnostics.Stopwatch]::StartNew()

try
{
	$result = Start-SmtpDeploy
}
catch [System.Exception]
{
	$result = 1
	Write-Error2 -ErrorRecord $_
}

$timer.Stop()
$SummaryLog | Write-Summary -Message "running role $DeployRole on $ComputerName."  -Elapsed $timer.Elapsed -ScriptResult $result
Write-Header "Ending role $DeployRole on $ComputerName" -AsSubHeader

$result
$script:currentPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

<#
	.SYNOPSIS
		Creates and throws an invalid argument exception.
	.PARAMETER Message
		The message explaining why this error is being thrown.
	.PARAMETER ArgumentName
		The name of the invalid argument that is causing this error to be thrown.
#>
function New-RigFromTemplate
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]
		$RigName,

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]
		$TemplateName,

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]
		$ProjectName,
		
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[bool]
		$ForceRefresh,

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[object]
		$Servers,

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[object]
		$Parameters,

		[Parameter(Mandatory = $true)]
		[object]
		$Headers
	)

	Write-Host "Creating Rig $Name for project $Project using template $Template"
	$serverList = ($Servers.Projects | where {$_.Name -eq $ProjectName}).Servers

	$Parameters.User = "489ccbd1-35d5-47cb-a906-40f96237cde0"

	try{

		$InputObject = @{
			Name = $RigName
			ProjectName = $ProjectName
			TemplateName = $TemplateName
			ForceRefresh = if ($ForceRefresh) {$true} else {$false}
			Servers = $serverList
		}

		Write-Host "Invoking Provision-Rig...."
		$exitCode = Invoke-Webhook -Token 'FfPCJQEbyrO2litvUU43tJSwbSf0hf%2b5PVnzqTqzgno%3d' -Parameters $Parameters -InputObject $InputObject -Headers $Headers		

		if($exitCode -ne 0)
		{
			$ErrorMessage = "Provision-VM failed."
			throw $ErrorMessage
		}
	}
	catch{
		Write-Error -Message $_.Exception
		$exitCode = 1
	}	

	Write-Output $exitCode
}

<#
	.SYNOPSIS
		Creates and throws an invalid argument exception.
	.PARAMETER Message
		The message explaining why this error is being thrown.
	.PARAMETER ArgumentName
		The name of the invalid argument that is causing this error to be thrown.
#>
function Get-RigVM
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[String]
		$RigName,

		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[object]
		$Parameters
	)

	$Parameters.User = "489ccbd1-35d5-47cb-a906-40f96237cde0"
	$RigName = $RigName -replace '\.','_'
	$vmList = @()

	#region "Login to the subscription with your Azure account..."

	$secpasswd = ConvertTo-SecureString $Parameters.Password -AsPlainText -Force
	$mycreds = New-Object System.Management.Automation.PSCredential ($Parameters.User, $secpasswd)
	Login-AzureRmAccount -ServicePrincipal -Tenant $Parameters.Tenant -Credential $mycreds | Out-Null

	Select-AzureRmSubscription -SubscriptionId $Parameters.SubscriptionId | Out-Null
	#endregion
		
	$vmList = @()
	$resourceGroup = Get-AzureRmResourceGroup -Name $RigName -ErrorAction SilentlyContinue
	if($resourceGroup)
	{
		$nics = Get-AzureRmNetworkInterface -ResourceGroupName $RigName

		foreach($nic in $nics)
		{
			$ip = $nic.IpConfigurations[0].PrivateIpAddress
			$name = $nic.Name.Replace('_nic','')
			$nicInfo = New-Object System.Object
			$nicInfo | Add-Member -type NoteProperty -name Name -value $name
			$nicInfo | Add-Member -type NoteProperty -name IP -value $ip

			Write-Verbose $nicInfo
			$vmList += $nicInfo
		}
	}
		
	Write-Output $vmList 
}

<#
	.SYNOPSIS
		Creates and throws an invalid argument exception.
	.PARAMETER Message
		The message explaining why this error is being thrown.
	.PARAMETER ArgumentName
		The name of the invalid argument that is causing this error to be thrown.
#>
function Invoke-Webhook
{
	[cmdletbinding(SupportsShouldProcess)]
	Param(
		[ValidateNotNullOrEmpty()]
		[string]
		$Token,

		[ValidateNotNullOrEmpty()]
		[pscustomobject]
		$Parameters,

		[ValidateNotNullOrEmpty()]
		[pscustomobject]
		$InputObject,

		[ValidateNotNullOrEmpty()]
		[pscustomobject]
		$Headers
	)

	$Parameters.User = "489ccbd1-35d5-47cb-a906-40f96237cde0"

	$uri = "https://s9events.azure-automation.net/webhooks?token=$Token"
		
	$body = ConvertTo-Json -InputObject $InputObject -Depth 5

	$jobid = Invoke-RestMethod -Method Post -Uri $uri -Headers $Headers -Body $body

	#region "Login to the subscription with your Azure account..."

	$secpasswd = ConvertTo-SecureString $Parameters.Password -AsPlainText -Force
	$mycreds = New-Object System.Management.Automation.PSCredential ($Parameters.User, $secpasswd)
	Login-AzureRmAccount -ServicePrincipal -Tenant $Parameters.Tenant -Credential $mycreds | Out-Null

	Select-AzureRmSubscription -SubscriptionId $Parameters.SubscriptionId | Out-Null
	#endregion

	$job = Get-AzureRmAutomationJob -AutomationAccountName $Parameters.AutomationAccountName `
		-Id $jobid.JobIds[0] -ResourceGroupName $Parameters.AutomationResourceGroup
	
	Write-Verbose "Job : $($jobid.JobIds[0]) is  $($job.Status)"

	while(-not($job.Status -eq "Completed" -or $job.Status -eq "Stopped" -or $job.Status -eq "Suspended" -or $job.Status -eq "Failed"))
	{
		Start-Sleep -s 10
		$job = Get-AzureRmAutomationJob -AutomationAccountName $Parameters.AutomationAccountName `
			-Id $jobid.JobIds[0] -ResourceGroupName $Parameters.AutomationResourceGroup
		
		Write-Verbose "Job : $($jobid.JobIds[0]) is  $($job.Status)"
	}

	(Get-AzureRmAutomationJobOutput -AutomationAccountName $Parameters.AutomationAccountName `
			-Id $jobid.JobIds[0] -ResourceGroupName  $Parameters.AutomationResourceGroup -Stream Output) | ForEach-Object { Write-Host $_.Summary}

	if($job.Status -eq "Completed" -and $job.Exception -eq $null) {
		$result = 0
	} else {
		Write-Host '**********************************************'
		Write-Host "Job did not complete.  Reason: $($job.Exception)"
		Write-Host '**********************************************'
		$result = 1
	}

	Write-Output $result
}

Export-ModuleMember -Function @(
	'New-RigFromTemplate',
	'Get-RigVM',
	'Invoke-Webhook'
	)
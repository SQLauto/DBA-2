Param
(
  [string] $RigRelativePath,
  [string] $RigName,
  [string] $DropFolder,
  [string] $Password,
  [string] $DeploymentAccountName = "DeploymentAccount",
  [switch] $IsLocal,
  [string] $DriveLetter = "D"
)

function main
{
	$global:exitCode = 0

	Write-Output "************************************"
	Write-Output "*** MasterData Post Deployment Activites Starting"
	Write-Output "************************************"

	Write-Output "RigName: $RigName"
	Write-Output "Password: $Password"
	Write-Output "Deploy Config: $RigRelativePath"
	Write-Output ""

    Try
    {
		# 1. Get Deployment Details
        $scriptPath = Split-Path $MyInvocation.ScriptName
        $RigXmlPath = Join-Path $scriptPath "..\Scripts\$RigRelativePath"
        $psExecPath = join-path $scriptpath "..\Tools\PsExec.exe"

		# 1.1 Getting Environment name
        Write-output "Checking Environment Name..."
        $RigData = [XML](Get-Content $RigXmlPath)
        [string]$EnvironmentName = $RigData.Configuration.Environment;
		Write-Output "Environment: $EnvironmentName"
		Write-Output ""

		# 1.2 Getting Service Account Credentials
		Write-Output "Using ServiceAccounts credentials set named $DeploymentAccountName for deployment"        
		Write-Output "Mapping credentials from $DeploymentAccountName"
		$serviceAccountsFile = Join-Path $scriptpath "..\Accounts\$EnvironmentName.ServiceAccounts.XML"
        $serviceAccount = Get-ServiceAccount -Path $serviceAccountsFile -Password $Password -Account $DeploymentAccountName
        [string]$USR = $serviceAccount.QualifiedUsername
		[string]$PWD = $serviceAccount.DecryptedPassword
        [securestring]$SecPWD = ConvertTo-SecureString $PWD -AsPlainText -Force
		Write-Output "Decrypting Credentials"
		Write-Output ("Credentials : 1 " + $USR)
		Write-Output ("Credentials : 2 " + $PWD)
        $deploymentCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $USR,$SecPWD

		# 1.3 Getting Deployment and Target Machine ID
		Write-Output "Finding name of Target Machine..."
		$TargetMachine = $RigData.configuration.machine | Where-Object {$_.ServerRole.Description -eq "Event replay tool installer" }
		$TargetMachineName = $TargetMachine.Name
        Write-output "Target Machine: $TargetMachineName"

		Write-Output "Finding name of Deployment Machine..."
		$DeploymentMachine = $RigData.configuration.machine | Where-Object {$_.GetAttribute("DeploymentMachine") -eq "true" }
		$DeploymentMachineName = $DeploymentMachine.Name
        Write-output "Deployment Machine: $DeploymentMachineName"
        Write-Output ""

        $vm = Get-AzureRmVm -ResourceGroupName $RigName -Name $TargetMachineName
        if($vm)
        {
            $nic = get-AzureRmNetworkInterface -ResourceGroupName $RigName | Where-Object {$_.VirtualMachine.Id -eq $vm.Id}
            if($nic)
            {
                $TargetMachineIP  = $nic.IpConfigurations | select-object -ExpandProperty PrivateIpAddress
                if($TargetMachineIP -ne "")
                {
                    Write-Output "Target Machine IP: $TargetMachineIP"

		            Write-Output "Start copying MasterData_EventStore.bak ....."
                    $source = "\\$TargetMachineIP\$DriveLetter$\Deploy\DropFolder\DatabaseScripts\MasterData_EventStore.bak"
                    $destination = "\\$TargetMachineIP\$DriveLetter$\Tfl\MasterData-Scripts\"
                    if (!(Test-Path -path $destination)) {New-Item $destination -Type Directory}
		            Copy-Item -Path $source -Destination $destination -Recurse -Force
		            Write-Output "Fnished copying MasterData_EventStore.bak ....."

		            #3 Run restore and event replay
		            Write-Output "Executing Restore EventStore and Event Replay"
                    $MDScriptsFolder = "${DriveLetter}:\tfl\MasterData-Scaffolding\Scripts"
		            $command = ("Push-Location $MDScriptsFolder; Import-Module .\Deploy.ps1;" + 
				            " RestoreDatabaseThenReplayEvents -pathToBackup ${DriveLetter}:\Tfl\MasterData-Scripts\MasterData_EventStore.bak" +
				            " -EnvironmentName $EnvironmentName > ${DriveLetter}:\MasterData-RestoreAndReplay.log")
		            Write-Output "Executing command:"
		            Write-Output $command
		            Write-Output ""
		            $scriptToExecute = [scriptblock]::Create($command)
		            Invoke-Command -ComputerName $TargetMachineIP -Script $scriptToExecute -Credential $deploymentCredentials -Authentication Credssp -OutVariable $result | Out-String -Stream | ? {!($_ -as [int])} | Write-Host
		            Write-Output "Execute Complete"

		            Write-Output "Copying Log File to DropFolder\Logs"
                    $sourceLog = "\\$TargetMachineIP\$DriveLetter$\MasterData-RestoreAndReplay.log"
                    $destinationLog = "$DropFolder\Logs\"
                    if (!(Test-Path -path $destinationLog)) {New-Item $destinationLog -Type Directory}
		            Copy-Item -Path $sourceLog -Destination $destinationLog -Recurse -Force
					Write-Output "$sourceLog copied to $destinationLog"
                }
            }
        }	
	}
	Catch [System.Exception]
	{
		Write-Error $_.Exception.ToString()
		$global:exitCode = 1000
	}
    #finally
    #{
        #Write-Host "Closing VCloud connection."
	    #$vCloud | Disconnect-VCloud
    #}
}

$modulePath = Join-Path $PSScriptRoot "..\Scripts\Modules"

[Environment]::SetEnvironmentVariable("PSModulePath",  [Environment]::GetEnvironmentVariable("PSModulePath","Machine"))
$env:PSModulePath = "$modulePath;" + $env:PSModulePath

Import-Module TFL.Deployment -Force
#Import-Module TFL.Deployment.VCloud -Force -ErrorAction Stop
Import-Module TFL.Utilities -Force -ErrorAction Stop

main

Remove-Module TFL.Deployment
#Remove-Module TFL.Deployment.VCloud
Remove-Module TFL.Utilities
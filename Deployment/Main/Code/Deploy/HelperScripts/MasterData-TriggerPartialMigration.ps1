Param
(
  [string] $RigRelativePath,
  [string] $RigName,
  [string] $DropFolder,
  [string] $Password,
  [string] $DriveLetter = "D",
  [string] $DeploymentAccountName = "DeploymentAccount",
  [switch] $IsLocal
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
		$TargetMachine = $RigData.configuration.machine | Where-Object {$_.ServerRole.Include -eq "MasterData.PartialMigration.Install" }
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
					#3 Run Partial Migration									
					Write-Output "Executing Partial Migration"
					$MDScriptsFolder = "${DriveLetter}:\tfl\MasterData-Scaffolding\Scripts"
					$command = ("$($DriveLetter):\Tfl\MasterData-Scaffolding\MasterData.PartialMigration.exe -runPM -exit")
					Write-Output "Executing command:"
					Write-Output $command
					Write-Output ""
					$scriptToExecute = [scriptblock]::Create($command)
					Invoke-Command -ComputerName $TargetMachineIP -Script $scriptToExecute -Credential $deploymentCredentials -Authentication Credssp -OutVariable $result | Out-String -Stream | ? {!($_ -as [int])} | Write-Host
					Write-Output "Execute Complete"

					Write-Output "Copying Log File to DropFolder\Logs"
					Copy-Item -Path \\$TargetMachineIP\$DriveLetter$\TFL\MasterData\logs\PartialMigration.log -Destination $DropFolder\Logs -Recurse -Force
					Write-Output "Log file copied"

					# #3 Run Partial Migration
					# Write-Output "Running partial migration"
					
					# $psScript = "$($psExecPath) -accepteula -h $($DriveLetter):\Tfl\MasterData-Scaffolding\MasterData.PartialMigration.exe -runPM -exit"
					# Write-Output "psScript: $psScript"
					
					# $SecurePassword = ConvertTo-SecureString $PWD -AsPlainText -Force
					# $RuntimeCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $USR, $SecurePassword
					# Invoke-Command -ComputerName $TargetMachineIP -Credential $RuntimeCredentials -ScriptBlock { cmd /c $psScript } -Authentication Credssp		
					# Write-Output "Execute Complete"

					# Write-Output "Copying Log File to DropFolder\Logs"
                    # $sourceLog = "\\$TargetMachineIP\$DriveLetter$\TFL\MasterData\logs\PartialMigration.log"
                    # $destinationLog = "$DropFolder\Logs\"
                    # if (!(Test-Path -path $destinationLog)) {New-Item $destinationLog -Type Directory}
		            # Copy-Item -Path $sourceLog -Destination $destinationLog -Recurse -Force
					# Write-Output "$sourceLog copied to $destinationLog"
				}
			}
		}
	}
	Catch [System.Exception]
	{
		Write-Error $_.Exception.ToString()
		$global:exitCode = 1000
	}
}

$modulePath = Join-Path $PSScriptRoot "..\Scripts\Modules"

[Environment]::SetEnvironmentVariable("PSModulePath",  [Environment]::GetEnvironmentVariable("PSModulePath","Machine"))
$env:PSModulePath = "$modulePath;" + $env:PSModulePath

Import-Module TFL.Deployment -Force
Import-Module TFL.Utilities -Force -ErrorAction Stop

main

Remove-Module TFL.Deployment
Remove-Module TFL.Utilities
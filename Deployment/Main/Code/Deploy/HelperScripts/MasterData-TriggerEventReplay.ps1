Param
(
  [string] $RigRelativePath,
  [string] $RigName,
  [string] $DropFolder,
  [string] $Password,
  [string] $DeploymentAccountName = "DeploymentAccount",
  [string] $DeploymentDrive = "D"
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
	    Write-Output "Importing TFL.Decryption.ps1"    
	    Import-Module $scriptPath\..\Scripts\TFL.Decryption.ps1 -Force
		Write-Output "TFL.Decryption.ps1 imported"
		Write-Output "Getting Account Detail XML"
        $accountDetailsPath = Join-Path $scriptpath "..\Accounts\$EnvironmentName.ServiceAccounts.XML"
        [xml]$accountData = [xml](Get-Content $accountDetailsPath)
        $userAccount = $accountData.ServiceAccounts.Account | Where-Object { $_.Name -eq $DeploymentAccountName }
        [string]$USR = $userAccount.username
		[string]$PWD =  Decrypt-String2 $userAccount.password $Password "$scriptPath\..\Scripts"
		Write-Output "Decrypting Credentials"
		Write-Output ("Credentials : 1 " + $USR)
		Write-Output ("Credentials : 2 " + $PWD)

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

		# 1.5 Verifying Rig Exisits
		If($RigName -ne "")
		{
			Write-Output "Rig Name provided, Checking VCLoud"
			Write-output "Verifying Rig Exists..."

			# 1.5.1 Loading vCloud Module
			Write-output "Importing vCloud Module..."
            Write-output ""
			Import-Module $scriptPath\..\Scripts\vCloud.ps1 -Force

			Write-output "vCloud Module loaded"
			Write-Output ""

            $rig = Get-CIVApp -Name $RigName -ErrorAction SilentlyContinue;
			if($rig -ne $null)
			{
				Write-output "Rig $RigName Found"
				Write-Output ""

				# 1.5.2 Getting Deployment Machine IP Address
				Write-output "Getting Target Machine IP Address..."
				$TargetMachineIP = Get-vCloudMachineIPAddress -vApp $rig -MachineName $TargetMachineName
				Write-Output "Target Machine IP: $TargetMachineIP"

				Write-output "Getting Deployment Machine IP Address..."
				$DeploymentMachineIP = Get-vCloudMachineIPAddress -vApp $rig -MachineName $DeploymentMachineName
				Write-Output "Deployment Machine IP: $DeploymentMachineIP"
				Write-Output ""
			}
			else
			{
				Write-Error "ERROR: Rig $RigName does not exist. Please Provide a valid RigName"
				$global:exitCode = 1001;
			}
		}
		else
		{
			# 1.6 Getting Deployment and Target Machine External IP from Deploy Config
			Write-output "Getting Target Machine IP Address..."
			$TargetMachine = $RigData.configuration.machine | Where-Object {$_.ServerRole.Description -eq "MasterData Event Replay Tools" }
			$TargetMachineIP = $TargetMachine.ExternalIP
			Write-Output "Target Machine IP: $TargetMachineIP"

			Write-output "Getting Deployment Machine IP Address..."
			$DeploymentMachine = $RigData.configuration.machine | Where-Object {$_.GetAttribute("DeploymentMachine") -eq "true" }
			$DeploymentMachineIP = $DeploymentMachine.ExternalIP
			Write-Output "Deployment Machine IP: $DeploymentMachineIP"
			Write-Output ""
		}


		# 2. Setup Deployment Process
		# 2.1 Connecting to Deployment Machine
        Write-Output "Attempting to Connecting to Target Machine..."
        [int] $attempt = 0
	    do
	    {
		    $attempt++
            Write-Output "Attempt $attempt"
		    if ($attempt -gt 1) {sleep -Seconds 30};
                
		    $netuseCommand = "net"
            Write-Output "& $netuseCommand use \\$TargetMachineIP\($DeploymentDrive)`$ /user:$USR $PWD"
		    & $netuseCommand use \\$TargetMachineIP\($DeploymentDrive)`$ /user:$USR $PWD
	    }
	    while (($LASTEXITCODE -ne 0 ) -and ($attempt -lt 20) )
            
        if ($LASTEXITCODE -ne 0 )
	    { 
		    Write-Error "ERROR: FAILED to connect to deployment machine."
		    $global:exitCode = 1002;
	    }
		Write-Output ""  

		$deploybatFile = join-path $scriptpath "\MasterData-RestoreAndReplay.bat"
		Add-Content $deploybatFile "echo. | powershell -ExecutionPolicy Unrestricted -NonInteractive Import-Module ($DeploymentDrive):\tfl\MasterData-Scaffolding\Scripts\Deploy.ps1; RestoreDatabaseThenReplayEvents -pathToBackup ($DeploymentDrive):\Tfl\MasterData-Scripts\MasterData_EventStore.bak -EnvironmentName $EnvironmentName > ($DeploymentDrive):\MasterData-RestoreAndReplay.log"
		# Add-Content $deploybatFile "echo. | powershell -ExecutionPolicy Unrestricted -NonInteractive Import-Module D:\tfl\MasterData-Scaffolding\Scripts\Deploy.ps1; SetupPartialMigration -environmentName $EnvironmentName"
        Write-Output "$deploybatFile file created"

		Copy-Item -Path \\TDC2FAEC02V01.FAE.tfl.local\BaseDataBackup\MasterData_EventStore.bak -Destination \\$TargetMachineIP\($DeploymentDrive)$\Tfl\MasterData-Scripts -Recurse -Force
		Copy-Item -Path $deploybatFile -Destination \\$TargetMachineIP\($DeploymentDrive)$\Tfl\MasterData-Scripts -Recurse -Force
		Write-Output "$deploybatFile copied to \\$TargetMachineIP\($DeploymentDrive)$\Tfl\MasterData-Scripts"
		Write-Output ""

		#3 Run restore and event replay
		Write-Output "Executing Restore EventStore and Event Replay"
		& $psExecPath /accepteula \\$TargetMachineIP -h -u $USR -p $PWD ($DeploymentDrive):\Tfl\MasterData-Scripts\MasterData-RestoreAndReplay.bat
		Write-Output "Execute Complete"

		Write-Output "Copying Log File to DropFolder\Logs"
		Copy-Item -Path \\$TargetMachineIP\($DeploymentDrive)$\MasterData-RestoreAndReplay.log -Destination $DropFolder\Logs -Recurse -Force
		Write-Output ""


		If($LASTEXITCODE -ne 0)
		{
			Write-Error "ERROR: Projection Store Deployment Failed."
			$global:exitCode = 1003
		}				
	}
	Catch [System.Exception]
	{
		Write-Error $_.Exception.ToString()
		$global:exitCode = 1000
	}
}

main
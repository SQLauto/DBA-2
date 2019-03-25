Param
(
  [string] $RigRelativePath,
  [string] $RigName,
  [string] $DropFolder,
  [string] $Password,
  [switch] $IsLocal,
  [string] $DeploymentAccountName = "DeploymentAccount",
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
        
		Write-Output "Found and mapped credentials"
		Write-Output ""
        
		# 1.3 Getting Deployment and Target Machine ID
		Write-Output "Finding name of Target Machine..."
		$TargetMachine = $RigData.configuration.machine | Where-Object {$_.ServerRole.Description -eq "MasterData Event Replay Tools" }
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

	        Write-Output "Loading Deployment.Utils"
	        [System.Reflection.Assembly]::LoadFrom("..\Tools\DeploymentTool\Deployment.Utils.dll")
	        Write-Output ""

	        Write-Output "Initialising vCloud Module for use"
	        $vCloudUrl = 'https://vcloud.onelondon.tfl.local'
	        $vCloudOrg = 'ce_organisation_td'
	        $vCloudUser = 'zSVCCEVcloudBuild'
	        $vCloudPassword = 'P0wer5hell'

	        Write-Output "Loading VCloudService and Creating connection to $vCloudUrl. Org: $vCloudOrg"
	        $vCloudService = New-Object -TypeName Deployment.Utils.VirtualPlatform.VCloud.VCloudService
	        $vCloudService.Initialise_vCloudSession($vCloudUrl, $vCloudOrg, $vCloudUser, $vCloudPassword) | Out-Host
			Write-output "vCloud Module loaded"
	        Write-Output ""

            $rig = $vCloudService.GetVapp($RigName);
			if($rig -ne $null)
			{
				Write-output "Rig $RigName Found"
				Write-Output ""

				# 1.5.2 Getting Deployment Machine IP Address
				Write-output "Getting Target Machine IP Address..."
				$TargetMachineIP = $vCloudService.Get_vCloudMachineIPAddress($TargetMachineName, $RigName);
				Write-Output "Target Machine IP: $TargetMachineIP"

				Write-output "Getting Deployment Machine IP Address..."
				$DeploymentMachineIP = $vCloudService.Get_vCloudMachineIPAddress($DeploymentMachineName, $RigName);
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
		if($IsLocal.IsPresent)
		{
			Write-Output "Attempting to Connecting to Target Machine..."
			[int] $attempt = 0
			do
			{
				$attempt++
				Write-Output "Attempt $attempt"
				if ($attempt -gt 1) {sleep -Seconds 30};
                
		    $netuseCommand = "net"
            Write-Output "& $netuseCommand use \\$TargetMachineIP\$DriveLetter`$ /user:$USR $PWD"
		    & $netuseCommand use \\$TargetMachineIP\d`$ /user:$USR $PWD
	    }
	    while (($LASTEXITCODE -ne 0 ) -and ($attempt -lt 20) )
            
			if ($LASTEXITCODE -ne 0 )
			{ 
				Write-Error "ERROR: FAILED to connect to deployment machine."
				$global:exitCode = 1002;
			}
			Write-Output "" 
		}

		# 2.1 Creating and Copying Trigger batch file
        # Create a deployment .bat file to get around any psexec command line length issue
        Write-Output "Creating batch file to execute MasterData Post Deploy Activity..."
        $arguments = "-EnvironmentName $EnvironmentName"            
        $deploybatFile = join-path $scriptpath "\Masterdata-DeployProjectionStore.bat"
        if (Test-Path $deploybatFile)
		{    
			Remove-Item $deploybatFile
		}
		Write-Output "Creating Script $deploybatFile"
		Add-Content $deploybatFile "echo. | powershell -ExecutionPolicy Unrestricted -NonInteractive -File $($DriveLetter):\Tfl\\MasterData-Scripts\MasterData-DeployProjectionStore.ps1 $arguments > $($DriveLetter):\MasterData-DeployProjectionStore.log"
        Write-Output "$deploybatFile file created"
        Copy-Item -Path $deploybatFile -Destination \\$TargetMachineIP\$DriveLetter$\Tfl\MasterData-Scripts -Recurse -Force
		Copy-Item -Path \\$DeploymentMachineIP\$DriveLetter$\Deploy\DropFolder\Deployment\Scripts\MasterData-DeployProjectionStore.ps1 -Destination \\$TargetMachineIP\$DriveLetter$\Tfl\MasterData-Scripts -Recurse -Force
        Write-Output "$deploybatFile copied to \\$TargetMachineIP\$DriveLetter$\Tfl\MasterData-Scripts"
		Write-Output ""

		# 3. Trigger Deployment Process
		Write-Output "Executing ProjectionStore Update..."
		& $psExecPath /accepteula \\$TargetMachineIP -u $USR -p $PWD $($DriveLetter):\Tfl\MasterData-Scripts\Masterdata-DeployProjectionStore.bat
		Write-Output "Execute Complete"

		Write-Output "Copying Log File to DropFolder\Logs"
		Copy-Item -Path \\$TargetMachineIP\$DriveLetter$\MasterData-DeployProjectionStore.log -Destination $DropFolder\Logs -Recurse -Force
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

	#4. Verification
	if($global:exitCode -eq 0)
	{
		Write-Output "Verifying Log File.."
		$logFile = "$DropFolder\Logs\MasterData-DeployProjectionStore.log"
		if(!(Test-Path $logFile))
		{
			Write-Error "ERROR: $logFile not found. Failing Deployment"
			$global:ExitCode = 1004
		}
		else
		{
			Write-Output "$logFile was found."
		}

		if($global:exitCode -eq 0)
		{
			$verificationText = "MasterData-DeployProjectionStore exiting with Code 0"
			$result = Select-String -pattern $verificationText -path $logFile
			if([String]::IsNullOrEmpty($result))
			{
				Write-Error "ERROR: File $logFile does not contain text $verificationtext, failing deployment"
				$global:ExitCode = 1005       
			}
			else
			{
				Write-Output "Log file verified, $result"
			}
			Write-Output ""
		}
	}
    
	Write-Output "Deployment-DeployProjectionStore exiting with code $global:exitCode"
	if($global:exitCode -eq 0)
	{
		Write-Output "MasterData Post Deployment Successful"
	}
	else
	{
		Write-Output "MasterData Post Deployment Failed"
	}
	Write-Output "" 

	Write-Output "************************************"
	Write-Output "*** MasterData Post Deployment Activites Ending"
	Write-Output "************************************"

	exit $global:exitCode
}

main
param
(
    [string]$RigName = $(throw 'Argument RigName is required for this script.'),
    [string]$RigRelativePath,
    [string]$OutputDir,
    [bool] $AreEventLogsToBeCollected = $true,
    [int] $NumThreads = 7

    #Debug
    #[string]$RigName = "FTP.Stabilisation.DTN",
    #[string]$RigRelativePath = "Integration.TSRig.VC.xml",
    #[string]$OutputDir = "D:\LogVcloud"
)

function main
{
    try
    {
        if(!(Test-Path $OutputDir))
        {
            Write-Output "Creating Output Directory $OutputDir"
            New-Item -Path $OutputDir -ItemType Directory | Out-Null
        }
        else
        {
            Write-Output "Output Directory $OutputDir already exists"
        }
                
        $ScriptPath = Split-Path $MyInvocation.ScriptName;
        $LogsForMachineScript = Join-Path $ScriptPath "LogsForMachine.ps1"
        $SoftwarePath = Join-Path $ScriptPath ..
        $ScriptsPath = Join-Path $SoftwarePath "\Scripts"
        $VcloudScriptPath = Join-Path $ScriptsPath "\vCloud.ps1"
        $DBLoggingScriptPath = Join-Path $ScriptsPath "\Tfl.DBLogging.ps1"
        $LabUser = "FAELAB\TFSBuild"
        $LabPass = "LMTF`$Bu1ld"
        $LabSecPass = ConvertTo-SecureString $LabPass -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential($LabUser, $LabSecPass)  
        $LogTempFolder =  [System.IO.Path]::Combine($OutputDir, "temp")

        if(!(Test-Path $LogTempFolder))
        {
            Write-Output "Creating Log Directory $LogTempFolder"
            New-Item -Path $LogTempFolder -ItemType Directory | Out-Null
        }
        else
        {
            Write-Output "Log Directory $LogTempFolder already exists"
        }


        Write-Output "Connecting to vCloud..."
        Import-Module $DBLoggingScriptPath -force
        Import-Module $VcloudScriptPath -force

        Write-Output "Reading Deployment Configuration file: $RigRelativePath"
        $RigXmlPath = Join-Path $ScriptsPath $RigRelativePath;
        if(Test-Path $RigXmlPath)
        {
            [xml]$RigXmlData = (Get-Content $RigXmlPath);
        }
        else
        {
            Write-Error "TERMINATING: Cannot find Deployment Configuration file $RigXmlPath"
            Exit 2;
        }

        $JobsToRun = @()

		foreach ($Machine in $RigXmlData.configuration.machine)
		{
			$MachineName = $Machine.Name
			$MachineIP = Get-vCloudMachineIPAddress -vApp $RigName -MachineName $MachineName
			$MachineDir = Join-Path $OutputDir $MachineName

            if(!(Test-Path $MachineDir))
            {
                Write-Output "Creating New Directory $MachineDir"
                New-Item -Path $MachineDir -ItemType Directory | Out-Null
            }

            # set up thread specific log files - one for each thread
            $DeploymentMachineLogFile = "Deployment." + [System.IO.Path]::GetFileNameWithoutExtension($RigRelativePath) + "." + $machine.Name + ".log" 
	        $DeploymentMachineLogFile = [System.IO.Path]::Combine($LogTempFolder, $DeploymentMachineLogFile)
            New-Item -Path $DeploymentMachineLogFile -Type File -Force > $null

                			
	        $DeployMachineScriptBlock = {
			Param (
         	[string]$MachineName,
			[string]$MachineIP,
			[string]$RigName,
            [string] $OutputDir,
            [bool]$AreEventLogsToBeCollected,
            [string] $DeploymentMachineLogFile
			)
            $exitCode = 0
           
            & $LogsForMachineScript -MachineName $MachineName -MachineIP $MachineIP -RigName $RigName -OutputDir $OutputDir -AreEventLogsToBeCollected $AreEventLogsToBeCollected *> $DeploymentMachineLogFile

            if($LASTEXITCODE -ne 0)
            {
                $exitcode = 8
            }

            # Return the result fo deploying this machine
            return New-Object PSObject -Property @{
                exitCode = $exitcode
            }
        } 

            $Job = [powershell]::Create().AddScript($DeployMachineScriptBlock)
            $Job = $Job.AddParameter("MachineName", $MachineName)
            $Job = $Job.AddParameter("MachineIP", $MachineIP)
            $Job = $Job.AddParameter("RigName", $RigName)				
            $Job = $Job.AddParameter("OutputDir", $OutputDir) 
            $Job = $Job.AddParameter("AreEventLogsToBeCollected", $AreEventLogsToBeCollected)
            $Job = $Job.AddParameter("DeploymentMachineLogFile", $DeploymentMachineLogFile)

            $JobPs = New-Object PSObject -Property @{
                Pipe = $Job
			    MachineName = $machine.Name 
			    Log = $DeploymentMachineLogFile
                Result = $null
			    LogProcessed = $false
            }

            $JobsToRun += $JobPs
		}

        Deploy-ServerRolesInParallel -JobsToRun  $JobsToRun -NumThreads $NumThreads -ScriptsPath $ScriptsPath -ScriptVariableName "LogsForMachineScript" -ScriptVariableValue $LogsForMachineScript
    }
    catch [System.Exception]
    {
        $error = $_.Exception.ToString()
        Write-Error "$error"
        exit 1
    }
}

function Deploy-ServerRolesInParallel
{
    param
    (
        [PSObject[]] $JobsToRun, 
        [int] $NumThreads,
        [string] $ScriptsPath,
        [string] $ScriptVariableName,
        [string] $ScriptVariableValue
    )
    Write-Output "Harvesting Logs and eventlogs asynchronously across all machines on $NumThreads threads"
	# Init session state for each background process, session state variables are shared across the 
	# runspace pool so we always have to be careful to access them in a thread safe manner.
	# Q: is it safe to read $commonRoles concurently from multiple threads? I think so..
	$sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $sessionstate.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList "async" ,$true, "async flag"))
    $scriptDescr = $ScriptVariableName + " Script"
    $sessionstate.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $ScriptVariableName ,$ScriptVariableValue, $scriptDescr))
    $sessionState.ImportPSModule("$ScriptsPath\Tfl.Utilities.ps1")	

    if ($JobsToRun.Count -lt $NumThreads)
    {
        $NumThreads = $JobsToRun.Count
    }

	$RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, $NumThreads, $sessionState, $Host)
	$RunspacePool.Open()
    $Jobs = @()	
									 
	foreach($Job in $JobsToRun)
    {
	    $Job.Pipe.RunspacePool = $RunspacePool
        $Jobs += $Job
        $Job.Result = $Job.Pipe.BeginInvoke()
	}

	# poll all processes until they all complete
	[boolean] $complete = $false
    Do 
	{
        # we use write-host here as we dont want this progress indicator to get written to the log - it should only show in the host console
        Write-Host "." -NoNewline 
        start-sleep -s 2
		$complete = $true
        foreach($Job in $Jobs)
		{
			if(!$Job.LogProcessed)
			{
                if($Job.Result.IsCompleted)
                {
                    $machineName = $Job.MachineName							   	
					$machineLog = Get-Content $Job.Log
					Write-Output $machineLog
                    $Job.LogProcessed = $true
                    $result = $Job.Pipe.EndInvoke($Job.Result)
                    $resultExitCode = $result.exitCode
                    if($resultExitCode -ne 0)
                    {
                        $global:exitcode = 7
                        Write-Error "There was an error getting logs from $machineName exit code was $resultExitCode"
                    }
                    $Job.Pipe.Dispose()	
                }
                else
				{
					$complete = $false
				}
			}
	
		}
    } While (!$complete)

    $RunspacePool.Close() # q: should we do this in the background with BeginClose, lets see how it performs
}

main
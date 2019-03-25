# A generic script that iterates through all the machines specificed and runs the given installer
# -UpgradeScript is the relative path of the powershell upgrade script that performs the upgrade
# -UpgradeScript must conform to the following pattern, it must decalre the following parameters
# 
#    -TargetMachine, machine name of ip address to upgrade
#    -Installer, the absolute path of installer or msi to execute          
#    -Username, user name to connect to target machine as (if blank windows auth is used)           
#    -Password, password for above user         
#    -DeploymentLocation, the location on target machine where the upgrade we be staged
#
# -Servers refers to the list of Servers on which the installer or msi is to execute on
# -Installer refers to the absolute path of installer or msi to execute
# -DeploymentLocation refers to where on the machine to runthe MSi from and save the log file to.
# -NumThreads refers to how many concurrent machines to run on at the same time
#
# Examples of use
# RunInstaller_LocalDomain.MultiThread.ps1 -UpgradeScript 'InstallPowershell3.ps1' -Servers 'TS-FAE1,TS-FAE2,TS-FAE3,TS-FAE4' -Installer '\\FTDC2DFS001\Media\PowerShell3\PS3_Windows6.1-KB2506143-x64.msu'
#
# RunInstaller_LocalDomain.MultiThread.ps1 -UpgradeScript 'InstallDotNet.ps1' -Servers 'TS-FAE1,TS-FAE2,TS-FAE3,TS-FAE4' -Installer '\\FTDC2DFS001\Media\.NET Frameworks\Microsoft .NET Framework 4.5.2\NDP452-KB2901907-x86-x64-AllOS-ENU.exe'
#

Param
(
    [string] $UpgradeScript      = "InstallDotNet.ps1", 
	[string] $DriveLetter        = "D",
    [string] $Servers            = $(throw 'Servers'),    #comma seperated list of machines to upgrade     
    [string] $Installer          = "\\FTDC2DFS001\Media\.NET Frameworks\Microsoft .NET Framework 4.5.2\NDP452-KB2901907-x86-x64-AllOS-ENU.exe",
    [string] $DeploymentLocation = "$($DriveLetter):\Deployment",
    [int]    $NumThreads         = 5
)

function main
{
    $global:exitcode = 0
    try
    {
        $startTime = Get-Date
        $installerName = [System.IO.Path]::GetFileName($Installer)
        $scriptpath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)
        
        Write-Output "Upgrading on Servers $Servers using script $UpgradeScript and installer $installerName. Machines may be rebooted. $startTime"
        $UpgradeScript = [System.IO.Path]::Combine($scriptpath, $UpgradeScript)

        if($NumThreads -ne 0)
        {
            Upgrade-InParallel
        }
        else
        {
            Upgrade-InSequence
        }

        If($global:exitcode -ne 0)
        {
            Write-Output "One or more machines failed to up grade. Please check $DeploymentLocation on each Server"
        }
        else
        {
            Write-Output "All machines upgrade successfully"
        }

        $endTime = Get-Date
        $totalTime = "{0:N4}" -f ($endTime - $startTime  ).TotalMinutes
        Write-Output "Completed in $totalTime minutes"
        exit $global:exitcode
    }
    catch
    {
        Write-Output $_.Exception
        exit 999
    }
}

function Upgrade-InParallel
{
    Param ( )

    Write-Output "Upgrading .Net on Servers in Parallel. Using $NumThreads threads."

    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

    $runspacePool = [runspacefactory]::CreateRunspacePool(1, $NumThreads, $sessionState, $Host)
    $runspacePool.Open()
    $jobs = @()

    $UpgradeScriptBlock={
        Param(
            [string]$UpgradeScript,
            [string]$Machine,
            [string]$Installer,
            [string]$DeploymentFolder,
			[string]$LogFile
            )

            $exitCode=0

            & $UpgradeScript -TargetMachine $Machine -Installer $Installer -DeploymentLocation $DeploymentFolder *> $LogFile
            if($LASTEXITCODE -ne 0)
            {
                $exitCode=1
            }

            # Return the result
            return New-Object PSObject -Property @{
                exitCode = $exitcode
            }
    }

    $ServerList = $Servers.Split(',')
    foreach($Server in $ServerList)
    {
        #$ServerIP = Get-IPAddress -ComputerName $Server -IPV4only
		$LogFile = $Server + "." + $installerName + ".log"
		$LogFile = [System.IO.Path]::Combine($DeploymentLocation, $LogFile)
		New-Item -Path $LogFile -ItemType File -Force

        $job = [powershell]::Create().AddScript($UpgradeScriptBlock)
        $job.AddParameter("UpgradeScript", $UpgradeScript) > $null
        $job.AddParameter("Machine", $Server).AddParameter("Installer", $Installer).AddParameter("DeploymentFolder",$DeploymentLocation) > $null
		$job.AddParameter("LogFile", $LogFile) > $null
        $job.RunspacePool = $runspacePool
        $jobs += New-Object PSObject -Property @{
            Pipe = $job
            MachineName = $Server
            Log = $LogFile
            Result = $job.BeginInvoke()
            LogProcessed = $false
        }
    }

    [boolean]$complete=$false
    Do
    {
        Write-Host -NoNewline "." 
        Start-Sleep -s 2
        $complete=$true
        foreach($job in $jobs)
        {
            if(!$job.LogProcessed)
            {
                if($job.Result.IsCompleted)
                {
                    $machineName = $job.MachineName
                    $log = $job.Log
                    Write-Output $log
                    $job.LogProcessed=$true
                    $result = $job.Pipe.EndInvoke($job.Result)
                    if($result.exitCode -ne 0)
                    {
                        $global:exitcode = 1
                        Write-Output "$machineName failed to complete job. Please Check logs."
                    }
                    $job.Pipe.Dispose()	
                }
                else
				{
					$complete = $false
				}
            }
        }
    } While (!$complete)

    $RunspacePool.Close()
}

function Upgrade-InSequence
{
    Write-Output "Upgrading .Net on Servers in Sequence."

    $ServerList = $Servers.Split(',')
    foreach($Server in $ServerList)
    {
        #$ServerIP = Get-IPAddress -ComputerName $Server -IPV4only
        $LogFile = $Server + "." + $installerName + ".log"
		$LogFile = [System.IO.Path]::Combine($DeploymentLocation, $LogFile)
		New-Item -Path $LogFile -ItemType File -Force

        Write-Output "Upgrading machine $Server"
        & $UpgradeScript -TargetMachine $Server -Installer $Installer -DeploymentLocation $DeploymentFolder *> $LogFile
        if($LASTEXITCODE -ne 0)
        {
            exit 1
        }
    }
}

function Get-IPAddress {
#Requires -Version 2.0            
[CmdletBinding()]            
 Param             
   (                       
    [Parameter(Position=1,
               ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true)]
    [String[]]$ComputerName = $env:COMPUTERNAME,
    [Switch]$IPV6only,
    [Switch]$IPV4only
   )#End Param

Begin            
{            
 Write-Verbose "`n Checking IP Address . . .`n"
 $i = 0            
}#Begin          
Process            
{
    $ComputerName | ForEach-Object {
        $HostName = $_

        Try {
            $AddressList = @(([net.dns]::GetHostEntry($HostName)).AddressList)
        }
        Catch {
            "Cannot determine the IP Address on $HostName"
        }

        If ($AddressList.Count -ne 0)
        {
            $AddressList | ForEach-Object {
            if ($IPV6only)
                {
                    if ($_.AddressFamily -eq "InterNetworkV6")
                        {
                            New-Object psobject -Property @{
                                IPAddress    = $_.IPAddressToString
                                ComputerName = $HostName
                                } | Select ComputerName,IPAddress   
                        }
                }
            if ($IPV4only)
                {
                    if ($_.AddressFamily -eq "InterNetwork")
                        {
                              New-Object psobject -Property @{
                                IPAddress    = $_.IPAddressToString
                                ComputerName = $HostName
                               } | Select ComputerName,IPAddress   
                        }
                }
            if (!($IPV6only -or $IPV4only))
                {
                      New-Object psobject -Property @{
                        IPAddress    = $_.IPAddressToString
                        ComputerName = $HostName
                       } | Select ComputerName,IPAddress
                }
        }#IF
        }#Foreach-Object(IPAddress)
    }#Foreach-Object(ComputerName)

}#Process

}#Get-IPAddress

main
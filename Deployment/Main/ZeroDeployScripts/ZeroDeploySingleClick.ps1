#Prerequisites:
#Path set for MSBuild.exe
#Path set for MSTest.exe
#Service bus installed
#AppFabric installed and configured
#Test output directory exists

param (
    [string]$paramsFile = ".\Parameters\FTP_Stabilisation_ZD.ps1"
) 

$paramsFilePath = resolve-path $paramsFile
Write-Host "Using parameters file: $paramsFilePath"

$jobsFolder = "$PSScriptRoot\Jobs"
$startTime = Get-Date

$ReadyForTesting = $false
$FtpComponentsStarted = $false
$WorkspaceDownloaded = $false
$CIBuildsDownloaded = $false
$AutogrationDatabasesDeployed = $false
$AutogrationSolutionBuilt = $false
$SetupComplete = $false

$timestampWorkspaceName="ZD"+(Get-Date).ToString("yyyyMMddHHmmss")
$zeroDeploymentPath = "D:\Autogration\$timestampWorkspaceName"
$workspaceFolder = "D:\SRC\$timestampWorkspaceName"
$zeroDeployScripts ="$workspaceFolder\Deployment\Main\ZeroDeployScripts"
$autogrationSolutionPath ="$workspaceFolder\Integration\Main\Autogration.sln"

Write-Host "Creating new Zero Deployment with timestamp $timestampWorkspaceName"



function SetUp{
    $gws = start-job -filepath $jobsFolder\GetWorkspaceJob.ps1 -Name "GetWorkspaceJob" -ArgumentList $timestampWorkspaceName,$jobsFolder,$paramsFilePath.Path
    $gci = start-job -filepath $jobsFolder\GetCIBuildsJob.ps1 -Name "GetCIBuildsJob" -ArgumentList $zeroDeploymentPath,$jobsFolder,$paramsFilePath.Path

    while(!$ReadyForTesting)
    {
        if(!$WorkspaceDownloaded)
        {
            $WorkspaceDownloaded = CheckJobComplete $gws $WorkspaceDownloaded
            
            if($WorkspaceDownloaded) #only need to go in here once
            {
                #Kick off DB deployment job and build autogration solution job
                $dbd = start-job -filepath $jobsFolder\DeployAutogrationDBJob.ps1 -Name "DeployAutogrationDBJob" -ArgumentList $zeroDeployScripts, $zeroDeploymentPath, $workspaceFolder
                $bld = start-job -filepath $jobsFolder\BuildAutogrationSlnJob.ps1 -Name "BuildAutogrationSlnJob" -ArgumentList $zeroDeployScripts
                $cpl = start-job -filepath $jobsFolder\CopyLocalFilesJob.ps1 -Name "CopyLocalFilesJob" -ArgumentList $zeroDeployScripts
            }    
        }

        if($WorkspaceDownloaded)
        {
            $AutogrationDatabasesDeployed = CheckJobComplete $dbd $AutogrationDatabasesDeployed
            $AutogrationSolutionBuilt = CheckJobComplete $bld  $AutogrationSolutionBuilt
        }

        if(!$CIBuildsDownloaded)
        {
            $CIBuildsDownloaded = CheckJobComplete $gci $CIBuildsDownloaded
            if($CIBuildsDownloaded) #only need to go in here once
            {
                #Now configure the components
                $cfg = start-job -filepath $jobsFolder\ConfigureZeroDeployJob.ps1 -Name "ConfigureZeroDeployJob" -ArgumentList $zeroDeployScripts, $zeroDeploymentPath
            }
        }

        if($CIBuildsDownloaded)
        {
            $ZeroDeployConfigured = CheckJobComplete $cfg $ZeroDeployConfigured
        }

        if($CIBuildsDownloaded -and $AutogrationDatabasesDeployed -and $ZeroDeployConfigured)
        {
            if(!$SetupComplete)
            {
                $SetupComplete=$true
                #fire up the ZD rig
                $run = start-job -filepath $jobsFolder\StartFtpComponentsJob.ps1 -Name "StartFtpComponentsJob" -ArgumentList $zeroDeployScripts
            }
            else
            {
                $FtpComponentsStarted = CheckJobComplete $run $FtpComponentsStarted
            }
        }

        if($FtpComponentsStarted -and $AutogrationSolutionBuilt)
        {
            $ReadyForTesting = $true
        }

        Start-Sleep 3
    }
}

function RunTests {
    Write-Host "Running tests"
    $tst = start-job -filepath $jobsFolder\RunAutogrationTestsJob.ps1 -Name "RunAutogrationTestsJob" -ArgumentList $zeroDeployScripts
    Wait-Job -Id $tst.Id
    Receive-Job -Id $tst.Id
}

function StopAndWait {
   $stp = start-job -filepath $jobsFolder\StopZeroDeployServicesJob.ps1 -Name "StopZeroDeployServicesJob" 
    Wait-Job -Id $stp.Id
    Write-Host "Press any key to continue ..."
    $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function CheckJobComplete($job, $completed){
    if($completed){ return $true } #already complete, no need to check

    if($job.JobStateInfo.state -ne "Running" )
    {
        if($job.JobStateInfo.state -eq "Complete")
        {
            if(!$completed)
            {
                ShowSuccess($job)
                return $true
            }
        }
        else
        {
            ShowFailure($job)
        }
    }
    return $false
}

function ShowSuccess($job)
{
    $completedTime = Get-Date
    $jobName = $job.Name
    $jobId = $job.Id
    Write-Host "$completedTime SUCCESS: $jobName (Id:$jobId)"
	if($verbose)
	{
		Receive-Job -Id $jobId
	}
}

function ShowFailure($job)
{
    $completedTime = Get-Date
    $jobName = $job.Name
    $jobId = $job.Id
    Write-Host "$completedTime FAILURE: $jobName (Id:$jobId)"
    
    #Show output from the job
    Receive-Job -Id $jobId

    Exit
}

Setup

RunTests

StopAndWait

$endTime = Get-Date
Write-Host "Start time: $startTime"
Write-Host "End time  : $endTime"
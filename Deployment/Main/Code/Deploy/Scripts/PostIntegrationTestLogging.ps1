param
(
    [string]$VAppName = $(throw "Parameter VAppName is required for script PostIntegrationTestLogging"),        # Get all DTN's if none specified.
    [string]$BuildNumber = "",
    [int]$TestResult,                 # 1 SUCCESS, 0 UNKNOWN, -1 FAIL
    [bool]$ShutDownOnGreen = $false
)

function WRITE([string] $s) { Write-Output $s; Write-Host $s; }

function main
(
)
{
    $scriptpath = split-path $myinvocation.scriptname;

	WRITE "Loading TFL.DBLogging.ps1"
	WRITE ""
	Import-Module $scriptpath\..\Scripts\TFL.DBLogging.ps1 -Force

    Initialise_DeploymentScriptEventLog -RigName $VAppName -InitialisationSource ($myinvocation.scriptname) -ScriptHost $env:computername

    Log-DeploymentScriptEvent -BuildNumber $BuildNumber -TestResult $TestResult -ShutDownOnGreen $ShutDownOnGreen

    if ($ShutDownOnGreen)
    {
        if ($TestResult -eq 1)
        {
            WRITE "ShutDownOnGreen = True and TestResult = 1...Shutting Rig Down"
            WRITE ""
            WRITE "Importing VCloud module..."
            WRITE ""
            WRITE "  Import-Module $scriptpath\..\Scripts\VCloud.ps1"

            Import-Module $scriptpath\..\Scripts\VCloud.ps1 -Force
    
            $vApp = Get-CIvApp -Name $vAppName -ErrorAction SilentlyContinue

            if ($vApp -ne $null)
            {
                Log-DeploymentScriptEvent -DeploymentEventID $BEGIN_POST_TEST_SHUTDOWN
		    
                $vApp | Stop-CIvApp -Confirm:$false
            
                Log-DeploymentScriptEvent -DeploymentEventID $END_POST_TEST_SHUTDOWN
            }
            else
            {
                $errMsg = "vApp Shutdown After Green Build Attempted but vApp '$VAppName' not found. Exiting with code 4001"
                $exitCode = 4001
                Log-DeploymentScriptEvent -LastError $errMsg -DeploymentEventID $END_SETUP_DEPLOYMENT -SetupDeployment_ExitCode $exitCode
                
                WRITE $errMsg
                WRITE ""
            }
        }
        else
        {
            WRITE "ShutDownOnGreen = True but TestResult is not 1 (= Successful).  No further action"
            WRITE ""
        }
    }
    else
    {
        WRITE "ShutDownOnGreen = False.  No further action"
        WRITE ""
    }
    
	exit 0

}


main
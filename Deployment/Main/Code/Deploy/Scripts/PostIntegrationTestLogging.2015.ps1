param
(
    [string]$VAppName = $(throw "Parameter VAppName is required for script PostIntegrationTestLogging"),        # Get all DTN's if none specified.
    [string]$BuildNumber = "",
    [int]$TestResult,                 # 1 SUCCESS, 0 UNKNOWN, -1 FAIL
    [bool]$ShutDownOnGreen = $false
)

function WRITE([string] $s) { Write-Output $s; Write-Host $s; }

function Get-DeploymentTool
{
	$BuildDefinitionName = Get-BuildDefintionName -BuildId $env:BUILD_BUILDID
	
    if(-not (Test-Path "$env:AGENT_RELEASEDIRECTORY\$BuildDefinitionName\Deployment\Tools\DeploymentTool"))
    {
		throw [System.ApplicationException] "Unable to locate Build Artefact Deployment. Please check Build output"
    } 
	
	return "$env:AGENT_RELEASEDIRECTORY\$BuildDefinitionName\Deployment\Tools\DeploymentTool"
}

function Get-BuildDefintionName
{
	Param
	(
		$BuildId
	)

	$tfsProjectUri = "$env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI/$env:SYSTEM_TEAMPROJECT"
	$restApiUrl = "$tfsProjectUri/_apis/build/builds/$BuildId`?api-version=2.0"

	$response = Invoke-RestMethod $restApiUrl -UseDefaultCredentials

	return $response.definition.name
}

function main
(
)
{
	$DeploymentToolPath = Get-DeploymentTool
    $scriptpath = split-path $myinvocation.scriptname;
	$LoggingValues = New-Object "System.Collections.Generic.Dictionary``2[System.String,System.Object]"

	WRITE "Loading Deployment.Utils.dll"
	[System.Reflection.Assembly]::LoadFrom("$DeploymentToolPath\Deployment.Utils.dll")
	WRITE ""

	if($env:FTPDEPLOYMENTID -le -1)
	{
		WRITE "Initialise DeploymentLogging"
		$DeploymentID = [Deployment.Utils.Logging.DeploymentLogging]::GenerateDeploymentID($VAppName, "", $env:COMPUTERNAME, ($myinvocation.ScriptName))
	}
	else
	{
		$DeploymentID = $env:FTPDEPLOYMENTID
	}

    if ($ShutDownOnGreen)
    {
		$LoggingValues.Clear();
		$LoggingValues.Add("TestResult", $TestResult)
		$LoggingValues.Add("ShutdownOnGreen", 1)	
		[Deployment.Utils.Logging.DeploymentLogging]::LogDeploymentEvent($DeploymentID, $LoggingValues)

        if ($TestResult -eq 1)
        {
            WRITE "ShutDownOnGreen = True and TestResult = 1...Shutting Rig Down"
            WRITE ""
            
			$vCloudUrl = 'https://vcloud.onelondon.tfl.local'
			$vCloudOrg = 'ce_organisation_td'
			$vCloudUser = 'zSVCCEVcloudBuild'
			$vCloudPassword = 'P0wer5hell'

			WRITE "Loading VCloudService and Creating connection to $vCloudUrl. Org: $vCloudOrg"
			$vCloudService = New-Object -TypeName Deployment.Utils.VirtualPlatform.VCloud.VCloudService
			$vCloudService.Initialise_vCloudSession($vCloudUrl, $vCloudOrg, $vCloudUser, $vCloudPassword) | Out-Host
			WRITE ""
    
            $vApp = $vCloudService.GetVapp($VAppName)

            if ($vApp -ne $null)
            {
				$LoggingValues.Clear()
				$LoggingValues.Add("EventID", [Deployment.Utils.Enum.DeploymentEventActions]::BEGIN_POST_TEST_SHUTDOWN)
				[Deployment.Utils.Logging.DeploymentLogging]::LogDeploymentEvent($DeploymentID, $LoggingValues)
		    
                $vCloudService.Stop_vApp($VAppName)
            
				$LoggingValues.Clear()
				$LoggingValues.Add("EventID", [Deployment.Utils.Enum.DeploymentEventActions]::END_POST_TEST_SHUTDOWN)
				[Deployment.Utils.Logging.DeploymentLogging]::LogDeploymentEvent($DeploymentID, $LoggingValues)
            }
            else
            {
                $errMsg = "vApp Shutdown After Green Build Attempted but vApp '$VAppName' not found. Exiting with code 4001"
                $exitCode = 4001
				
				$LoggingValues.Clear()
				$LoggingValues.Add("EventID", [Deployment.Utils.Enum.DeploymentEventActions]::END_POST_TEST_SHUTDOWN)
				$LoggingValues.Add("LastError", $errMsg)
				[Deployment.Utils.Logging.DeploymentLogging]::LogDeploymentEvent($DeploymentID, $LoggingValues)
                
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
		$LoggingValues.Clear();
		$LoggingValues.Add("TestResult", $TestResult)
		$LoggingValues.Add("ShutdownOnGreen", 0)	
		[Deployment.Utils.Logging.DeploymentLogging]::LogDeploymentEvent($DeploymentID, $LoggingValues)

        WRITE "ShutDownOnGreen = False.  No further action"
        WRITE ""
    }
    
	exit 0

}


main
param
(
    [string] $BuildNumber = $(throw '$BuildNumber is not defined'), 
    [string] $AppBuildNumber = $(throw '$AppBuildNumber'),
    [string] $AppBuildDropLocation = $(throw '$AppBuildDropLocation'), 
    [string] $DeploymentLogFile = $(throw '$DeploymentLogFile')
)

function main
{
    Write-Output "Parameters are:  "
    Write-Output "    BuildNumber : $BuildNumber"
    Write-Output "    AppBuildNumber : $AppBuildNumber"
    Write-Output "    AppBuildDropLocation: $AppBuildDropLocation"
    Write-Output "    DeploymentLogFile $DeploymentLogFile"

    $timestamp = Get-Date 
	$AppBuildNumberFinal=$AppBuildNumber
	# Ensure the log file exists
    try
    {
        if (!(Test-Path -Path $DeploymentLogFile))
        {
            New-Item -Path $DeploymentLogFile -Type File 
        }
        
    	if($AppBuildNumber -match "#")
    	{
    		$CountofBuilds= $AppBuildNumber.Split("#").Getlength(0)
                $AppBuildNumberFinal=$AppBuildNumber.Replace("#"," ")
    		#$AppBuildNumberFinal="$CountofBuilds Builds: " $AppBuildNumberFinal
    	}
     
    	Add-Content "$DeploymentLogFile" "`n"
    	Add-Content "$DeploymentLogFile" "`n$timestamp"
    	Add-Content "$DeploymentLogFile" "`nBuildNumber: $BuildNumber, AppBuildNumber(s): $AppBuildNumberFinal, AppBuildDropLocation: $AppBuildDropLocation"    
    }
    catch [System.Exception]
    {
       LogError $_.Exception.ToString()
       $exitCode = 1
    }
}

main 

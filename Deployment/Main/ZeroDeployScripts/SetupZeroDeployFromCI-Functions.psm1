Function Clear-CiBuild
{
	param
	(
		[string] $path = $(throw "Please specify path")
	)

	process
	{
		If (Test-Path $path)
		{
			Remove-Item -Recurse -Force $path
		}
	}
}

Function Get-LatestCiBuild
{
	param
	(
		[string] $projectName = $(throw "Please specify path"),
		[string] $buildName = $(throw "Please specify path"),
		[string] $targetFolder = $(throw "Please specify path")
	)

	process
	{
		$program = ".\GetLatestCiBuild.exe"
		$tfsUrl = "http://tfs:8080/tfs/ftpdev"
		
        $message = "GetLatestCiBuild.exe " + $projectName + "." + $targetFolder
        Write-Progress -activity $message

		Clear-CiBuild -path $targetFolder
		Invoke-Command -ScriptBlock { param ($_PROJECTNAME="", $_BUILDNAME="", $_TARGETFOLDER="") & $program $tfsUrl $_PROJECTNAME $_BUILDNAME $_TARGETFOLDER} -ArgumentList $projectName, $buildName, $targetFolder
        Write-Host ""
	}
}

Function Install-ServiceBus
{
	param
	(
		[bool] $setupServiceBus
	)

	process
	{
		If($setupServiceBus)
		{
			& .\ServiceBusSetupForFAE.ps1 -userdomain "FAE" -username "zsvcServiceBus" -password "S3rv1c3B4s"
			& .\CreateTopic.ps1 -Namespace ServiceBusDefaultNamespace -Path tfl.ft.sdm.disruption.command.topic
			& .\CreateSubscription.ps1 -Namespace ServiceBusDefaultNamespace -TopicPath tfl.ft.sdm.disruption.command.topic -Name Tfl.Ft.Sdm.Disruption.Command.Fae
			& .\CreateTopic.ps1 -Namespace ServiceBusDefaultNamespace -Path tfl.ft.sdm.disruption.status.topic 
			& .\CreateSubscription.ps1 -Namespace ServiceBusDefaultNamespace -TopicPath tfl.ft.sdm.disruption.status.topic -Name Tfl.Ft.Sdm.Disruption.Status.Sdm
		}
	}
}

Function Install-EngineHost
{
	param
	( 
		[string] $zeroDeployPath
	)
		
	$program = Join-Path -Path $zeroDeployPath "\FAE\EngineControllerHost.exe"
	Invoke-Command -ScriptBlock { param ($_PROGRAMARGS="install") & $program $_PROGRAMARGS}
}

Function Publish-Database
{
    param
    (
        [string] $databaseName,
        [string] $deploymentScript,
        [string] $argumentList,
        [string] $logPath
    )

    process
    {
        $message = "Deploying " + $databaseName + " database"
        Write-Progress -activity $message

        Set-Location $PSScriptRoot
    	cd $PSScriptRoot
        
        $arg = "DatabaseName=" + $databaseName
        Invoke-Sqlcmd -InputFile "PreDeploymentForPs.sql" -Variable $arg

		# Handle spaces in $deploymentScript path (http://serverfault.com/a/333959).
    	$output = Invoke-Expression "& '$deploymentScript' $argumentList" | Out-File $($logpath + $databaseName + '.txt')
    	if($? -ne $true) {
    		echo $output
            $errorMessage = $databaseName + " Deployment Failed"
    		throw $errorMessage
    	}
    }
}

Function Restore-Database 
{
	param
	(
		[Parameter(Mandatory=$True)]
		[String]$databaseName,
		[Parameter(Mandatory=$True)]
		[String]$backupPath,
		[String]$sqlInstanceName= "localhost"
	)

    $absolutePath = Resolve-Path $backupPath

	$message =  "Restoring database: " + $databaseName + " from : " + $absolutePath
    Write-Progress -activity $message

    try {
		    			 
		#Load the required assemlies SMO and SmoExtended.
		[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
		[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
 
		# Connect SQL Server.
		$sqlServer = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $sqlInstanceName
		$dbRestore = new-object ("Microsoft.SqlServer.Management.Smo.Restore")				
        $dbRestore.Database = $databaseName
        $dbRestore.Devices.AddDevice($absolutePath, "File")
        $dbRestore.ReplaceDatabase = $True

        $DataFiles = $dbRestore.ReadFileList($sqlServer)
                
        ForEach ($DataRow in $DataFiles) {
            $LogicalName = $DataRow.LogicalName
            $RestoreData = New-Object("Microsoft.SqlServer.Management.Smo.RelocateFile")
            $RestoreData.LogicalFileName = $LogicalName

            if ($DataRow.Type -eq "D") 
			{
                # Restore Data file
                $RestoreData.PhysicalFileName = $sqlServer.Information.MasterDBPath + "\" + $dbRestore.Database + ".Data.mdf"
            }
            else 
			{
                # Restore Log file
                $RestoreData.PhysicalFileName = $sqlServer.Information.MasterDBLogPath + "\" + $dbRestore.Database + "_Log.ldf"
            }
            [Void]$dbRestore.RelocateFiles.Add($RestoreData)
        }

        $dbRestore.SqlRestore($sqlServer)
 
		Write-host "...SQL Database" $databaseName "Successfully Restored"
	}
	catch {
		$erroredAt = Get-Date
		$message = [string]::Format("{0} Unable to restore database {1}. See build log for more detail", $erroredAt, $databaseName)
		write-host $message
        Write-host "Exception Message: $($_.Exception)"
		
		#$host.SetShouldExit($result.ExitCode) 
		#Exit $result.ExitCode
	}
}
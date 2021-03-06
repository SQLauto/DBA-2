######################################################
##
##  FTP Deployment Script Logging to DB ##
##
######################################################

function Initialise_DeploymentScriptEventLog
(
    [int]$DeploymentScriptLogId = -1,  # For when this has been passed down from SetupDeployment.ps1
    [string]$RigName = "",
    [string]$PackageName = "",
    [string]$ScriptHost = "",
    [string]$InitialisationSource = "",
	[bool] $ReportError = $False
)
{
	try
	{

		$msg = "Initialising database logging" 
		Write-Output $msg
		Write-Host $msg

		if ($THIS_FTP_DEPLOYMENT_ID -gt 0) # ($THIS_FTP_DEPLOYMENT_ID -ne $null)
		{
			$msg = "Deployment Event Database Logging already initialised wth ID $THIS_FTP_DEPLOYMENT_ID"
			Write-Output $msg
			Write-Host $msg
		}
		elseif ($DeploymentScriptLogId -gt 0)
		{
			$msg = "Initialising Deployment Event Database Logging with ID passed from Setup-Deployment: $DeploymentScriptLogId"
			Write-Output $msg
			Write-Host $msg

			Set-Variable -Name THIS_FTP_DEPLOYMENT_ID -Value $DeploymentScriptLogId -Scope Global -Force;
		}
		elseif ( ([string]::IsNullOrEmpty($RigName)) -and  ([string]::IsNullOrEmpty($PackageName)) )
		{
			$msg = "NOTE: Not initialising Deployment Event Database Logging: no Rig or Package Name specified";
			Write-Output $msg
			Write-Host $msg
		}
		else
		{
			$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
			$SqlConnection.ConnectionString = "Server=$FTP_LOGGING_DB_SERVER;Initial Catalog=$FTP_LOGGING_DB_NAME;User Id=tfsbuild;Password=LMTF`$Bu1ld;"
			try
			{
				$SqlConnection.Open()

				$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
				$SqlCmd.Connection = $SqlConnection

				# get next build number
				$cmdText = "INSERT INTO dbo.FTPDeployment (RigName, PackageName, ScriptHost, InitialisationSource ) VALUES ("
				$cmdText += "'" + ($RigName -replace "'", "''") + "', "
				$cmdText += "'" + ($PackageName -replace "'", "''") + "', "
				$cmdText += "'" + ($ScriptHost -replace "'", "''") + "', "
				$cmdText += "'" + ($InitialisationSource -replace "'", "''") + "'"
				$cmdText += "); ";
				$cmdText += " SELECT SCOPE_IDENTITY()";
			
				$SqlCmd.CommandText = $cmdText;
				$result = $SqlCmd.ExecuteScalar();

				if ($result -eq $null)
				{
					#problem
				}
				else
				{
					Set-Variable -Name THIS_FTP_DEPLOYMENT_ID -Value $result -Scope Global -Force;
				}
			}
			catch
			{
				if ($ReportError)
				{
					$msg = "INFO ONLY : Problem in Initialise_DeploymentScriptEventLog(RigName = $RigName): "
					Write-Output $msg
					Write-Host $msg

					Write-output  "Details: $_"
					Write-host "Details: $_"
				}
			}
			finally
			{
				$SqlConnection.Close();
			}
		}
	}
	catch
	{
	}
}
if($PSVersionTable.PSVersion.Major -le 2)
{
	exit 501
}
#Set these to comply with strictmode 
$FTP_LOGGING_DB_SERVER | Out-null
$FTP_LOGGING_DB_NAME | Out-null
$BEGIN_SETUP_DEPLOYMENT | Out-null
$END_SETUP_DEPLOYMENT | Out-null
$BEGIN_DEPLOY_RIG | Out-null
$END_DEPLOY_RIG | Out-null
$BEGIN_POST_TEST_SHUTDOWN | Out-null
$END_POST_TEST_SHUTDOWN | Out-null


if ($FTP_LOGGING_DB_SERVER -eq $null) { New-Variable FTP_LOGGING_DB_SERVER	-Value TDC2SQL005.fae.tfl.local  -Option Constant -Scope Global }
if ($FTP_LOGGING_DB_NAME -eq $null)   { New-Variable FTP_LOGGING_DB_NAME    -Value FTPEnvironmentManagment  -Option Constant -Scope Global }

if ($BEGIN_SETUP_DEPLOYMENT -eq $null) { New-Variable BEGIN_SETUP_DEPLOYMENT	-Value 1  -Option Constant -Scope Global }
if ($END_SETUP_DEPLOYMENT -eq $null)   { New-Variable END_SETUP_DEPLOYMENT		-Value 2  -Option Constant -Scope Global }
 
if ($BEGIN_DEPLOY_RIG -eq $null) { New-Variable BEGIN_DEPLOY_RIG	-Value 3  -Option Constant -Scope Global }
if ($END_DEPLOY_RIG -eq $null)   { New-Variable END_DEPLOY_RIG		-Value 4  -Option Constant -Scope Global }

if ($BEGIN_POST_TEST_SHUTDOWN -eq $null) { New-Variable BEGIN_POST_TEST_SHUTDOWN	-Value 5  -Option Constant -Scope Global }
if ($END_POST_TEST_SHUTDOWN -eq $null)   { New-Variable END_POST_TEST_SHUTDOWN		-Value 6  -Option Constant -Scope Global }

function Log-DeploymentScriptEvent
(
    [int]$DeploymentEventID = [int]::MinValue,
    [string]$BuildName, 
    [string]$RigName,
    [int]$SetupDeployment_ExitCode = [int]::MinValue,
    [int]$DeployRig_ExitCode = [int]::MinValue,
    [string]$LastError,
    [string]$LastException,
    [string]$vAppGuid,
    [string]$ScriptHost,
    [string]$InitialisationSource,
    [string]$BuildNumber,
    [int]$TestResult = [int]::MinValue,
    [int]$ShutDownOnGreen = [int]::MinValue,
    [string]$Environment,
	[bool] $ReportError = $False
)
{   
	try
	{
	
		$logID = $global:THIS_FTP_DEPLOYMENT_ID;

		if ($logID -lt 1)
		{
			# not initialised - ignore
		}
		else
		{
			try
			{
				$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
				$SqlConnection.ConnectionString = "Server=$FTP_LOGGING_DB_SERVER;Initial Catalog=$FTP_LOGGING_DB_NAME;User Id=tfsbuild;Password=LMTF`$Bu1ld;"

				$SqlConnection.Open()

				$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
				$SqlCmd.Connection = $SqlConnection

				if ($DeploymentEventID -gt [int]::MinValue)
				{
					New-Variable -Name columnName -Value "" -Option Private;
					switch ($DeploymentEventID)
					{
						$BEGIN_SETUP_DEPLOYMENT { $columnName = 'SetupDeployment_Start'; break; } 
						$END_SETUP_DEPLOYMENT { $columnName = 'SetupDeployment_End'; break; } 

						$BEGIN_DEPLOY_RIG { $columnName = 'DeployRig_Start'; break; } 
						$END_DEPLOY_RIG { $columnName = 'DeployRig_End'; break; }
						
						$BEGIN_POST_TEST_SHUTDOWN { $columnName = 'PostTestShutdown_Start'; break; } 
						$END_POST_TEST_SHUTDOWN { $columnName = 'PostTestShutdown_End'; break; }
					}
					if (-Not [string]::IsNullOrEmpty($columnName))
					{
						$SqlCmd.CommandText = "UPDATE [dbo].[FTPDeployment] SET [$columnName] = GETDATE() WHERE [ID] = $logID";
					
						$result = $SqlCmd.ExecuteNonQuery();
					}
				}
			
				if (-Not [string]::IsNullOrEmpty($BuildName))
				{
					$SqlCmd.CommandText = "UPDATE [dbo].[FTPDeployment] SET [BuildName] = $BuildName WHERE [ID] = $logID";

					$result = $SqlCmd.ExecuteNonQuery();
				}
				if (-Not [string]::IsNullOrEmpty($RigName))
				{
					$SqlCmd.CommandText = "UPDATE [dbo].[FTPDeployment] SET [RigName] = $RigName WHERE [ID] = $logID";

					$result = $SqlCmd.ExecuteNonQuery();
				}        

				if ($SetupDeployment_ExitCode -gt [int]::MinValue)
				{
					$SqlCmd.CommandText = "UPDATE [dbo].[FTPDeployment] SET [SetupDeployment_ExitCode] = $SetupDeployment_ExitCode WHERE [ID] = $logID";

					$result = $SqlCmd.ExecuteNonQuery();
				}
				if ($DeployRig_ExitCode -gt [int]::MinValue)
				{
					$SqlCmd.CommandText = "UPDATE [dbo].[FTPDeployment] SET [DeployRig_ExitCode] = $DeployRig_ExitCode WHERE [ID] = $logID";

					$result = $SqlCmd.ExecuteNonQuery();
				}
				if (-Not [string]::IsNullOrEmpty($LastError))
				{
					$SqlCmd.CommandText = "UPDATE [dbo].[FTPDeployment] SET [LastError] = '" + ($LastError.Replace("'", "''")) + "', [LastError_DateTime] = GETDATE() WHERE [ID] = $logID";

					$result = $SqlCmd.ExecuteNonQuery();
				}
				if (-Not [string]::IsNullOrEmpty($LastException))
				{
					$SqlCmd.CommandText = "UPDATE [dbo].[FTPDeployment] SET [LastException] = '" + ($LastException.Replace("'", "''")) + "' WHERE [ID] = $logID";

					$result = $SqlCmd.ExecuteNonQuery();
				}
				if (-Not [string]::IsNullOrEmpty($vAppGuid)) # ($vAppGuid -ne $null)
				{
					$SqlCmd.CommandText = "UPDATE [dbo].[FTPDeployment] SET [vAppGuid] = '" + ($vAppGuid.Replace("'", "''")) + "' WHERE [ID] = $logID";

					$result = $SqlCmd.ExecuteNonQuery();
				}
				if (-Not [string]::IsNullOrEmpty($ScriptHost)) #  ($ScriptHost -ne $null)
				{
					$SqlCmd.CommandText = "UPDATE [dbo].[FTPDeployment] SET [ScriptHost] = '" + ($ScriptHost.Replace("'", "''")) + "' WHERE [ID] = $logID";

					$result = $SqlCmd.ExecuteNonQuery();
				}
				if (-Not [string]::IsNullOrEmpty($InitialisationSource)) #  ($InitialisationSource -ne $null)
				{
					$SqlCmd.CommandText = "UPDATE [dbo].[FTPDeployment] SET [InitialisationSource] = '" + ($InitialisationSource.Replace("'", "''")) + "' WHERE [ID] = $logID";

					$result = $SqlCmd.ExecuteNonQuery();
				}
				if (-Not [string]::IsNullOrEmpty($BuildNumber)) #  ($BuildNumber -ne $null)
				{
					$SqlCmd.CommandText = "UPDATE [dbo].[FTPDeployment] SET [BuildNumber] = '" + ($BuildNumber.Replace("'", "''")) + "' WHERE [ID] = $logID";

					$result = $SqlCmd.ExecuteNonQuery();
				}
				if ($TestResult -gt  [int]::MinValue)
				{
					$SqlCmd.CommandText = "UPDATE [dbo].[FTPDeployment] SET [TestResult] = $TestResult WHERE [ID] = $logID";

					$result = $SqlCmd.ExecuteNonQuery();
				}
				if ($ShutDownOnGreen -gt [int]::MinValue)
				{
					$SqlCmd.CommandText = "UPDATE [dbo].[FTPDeployment] SET [ShutDownOnGreen] = $ShutDownOnGreen WHERE [ID] = $logID";

					$result = $SqlCmd.ExecuteNonQuery();
				}
				if  (-Not [string]::IsNullOrEmpty($Environment)) # ($Environment -ne "")
				{
					$SqlCmd.CommandText = "UPDATE [dbo].[FTPDeployment] SET [Environment] = '" + ($Environment.Replace("'", "''")) + "' WHERE [ID] = $logID";

					$result = $SqlCmd.ExecuteNonQuery();
				}
			}
			catch
			{
				if ($ReportError)
				{
					#ERROR
					Write-Output "INFO ONLY :  Problem in Log-DeploymentScriptEvent: $_";
					Write-Host "INFO ONLY : Problem in Log-DeploymentScriptEvent: $_";

					Write-Output "SQL: " $SqlCmd.CommandText;
					Write-Host "SQL: " $SqlCmd.CommandText;
				}
			}
			finally
			{
				$SqlConnection.Close();
			}
		}
	}
	catch
	{
	}
}



######################################################
##
##  VCLOUD LOGGING to DB ##
##
######################################################

         
function Initialise_vCloudEventLog
(
    [string]$vAppName = $(throw '$vAppName'),
    #[string]$vAppGuid = "",
    [string]$InitialisationSource = "",
    [string]$ScriptHost = "",
    [string]$Notes = "",
	[bool] $ReportError = $False
)
{
	try
	{
		if ([string]::IsNullOrEmpty($vAppName))
		{
			Write-Output  "Not initialising vCloud Event Logging: no vApp Name";
			Write-Host "Not initialising vCloud Event Logging: no vApp Name";

			return;
		}

		$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
		$SqlConnection.ConnectionString = "Server=$FTP_LOGGING_DB_SERVER;Initial Catalog=$FTP_LOGGING_DB_NAME;User Id=tfsbuild;Password=LMTF`$Bu1ld;"
		try
		{
			$SqlConnection.Open()

			$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
			$SqlCmd.Connection = $SqlConnection

			# get next build number
			$cmdText = "INSERT INTO dbo.vCloudDeployment (vAppName, Notes, InitialisationSource, ScriptHost /*, vAppGuid*/) VALUES (";
			$cmdText += "'" + ($vAppName -replace "'", "''") + "'"
			$cmdText += ",'" + ($Notes -replace "'", "''") + "'"
			$cmdText += ",'" + ($InitialisationSource -replace "'", "''") + "'"
			$cmdText += ",'" + ($ScriptHost -replace "'", "''") + "'"
			#$cmdText += ",'$vAppGuid'"
			$cmdText += "); ";
			$cmdText += "SELECT SCOPE_IDENTITY()";
			
			$SqlCmd.CommandText = $cmdText;
			$result = $SqlCmd.ExecuteScalar();

			if ($result -eq $null)
			{
				#problem
			}
			else
			{
				Set-Variable -Name THIS_VCLOUD_DEPLOYMENT_ID -Value $result -Scope Global -Force;
			}
		}
		catch
		{
			if ($ReportError)
			{
				$msg = "INFO ONLY : Problem in Initialise_vCloudEventLog (vAppName = $vAppName, InitialisationSource = $InitialisationSource, ScriptHost = $ScriptHost)"
				write-output $msg
				write-host $msg

				Write-output  "Details: $_"
				Write-host "Details: $_"
			}
		}
		finally
		{
			$SqlConnection.Close();
		}
	}
	catch
	{
	}
}

#Set these to comply with StrictMode
$ENTER_INIT_SESSION | Out-null
$EXIT_INIT_SESSION | Out-null
$ENTER_EXECUTE_REFRESH_VAPP | Out-null
$EXIT_EXECUTE_REFRESH_VAPP | Out-null
$ENTER_NEW_VAPP_FROM_TEMPLATE | Out-null
$EXIT_NEW_VAPP_FROM_TEMPLATE | Out-null
$ENTER_VERIFY_VAPP | Out-null
$EXIT_VERIFY_VAPP | Out-null
$BEGIN_START_CIVAPP | Out-null
$END_START_CIVAPP | Out-null
$BEGIN_STOP_CIVAPP | Out-null
$END_STOP_CIVAPP| Out-null
$BEGIN_REMOVE_CIVAPP| Out-null
$END_REMOVE_CIVAPP | Out-null
$BEGIN_NEW_CIVAPP | Out-null
$END_NEW_CIVAPP | Out-null
$THIS_VCLOUD_DEPLOYMENT_ID | Out-null


if ($ENTER_INIT_SESSION -eq $null) { New-Variable ENTER_INIT_SESSION		-Value 1 -Option Constant -Scope Global }
if ($EXIT_INIT_SESSION -eq $null) { New-Variable EXIT_INIT_SESSION		-Value 2 -Option Constant -Scope Global }

if ($ENTER_EXECUTE_REFRESH_VAPP -eq $null) { New-Variable ENTER_EXECUTE_REFRESH_VAPP	-Value 3 -Option Constant -Scope Global }
if ($EXIT_EXECUTE_REFRESH_VAPP -eq $null) { New-Variable EXIT_EXECUTE_REFRESH_VAPP	-Value 4 -Option Constant -Scope Global }
    
if ($ENTER_NEW_VAPP_FROM_TEMPLATE -eq $null) { New-Variable ENTER_NEW_VAPP_FROM_TEMPLATE	-Value 5 -Option Constant -Scope Global }
if ($EXIT_NEW_VAPP_FROM_TEMPLATE -eq $null) { New-Variable EXIT_NEW_VAPP_FROM_TEMPLATE	-Value 6 -Option Constant -Scope Global }
    
if ($ENTER_VERIFY_VAPP -eq $null) { New-Variable ENTER_VERIFY_VAPP	-Value 13 -Option Constant -Scope Global  }
if ($EXIT_VERIFY_VAPP -eq $null) { New-Variable EXIT_VERIFY_VAPP	-Value 14 -Option Constant -Scope Global }

if ($BEGIN_START_CIVAPP -eq $null) { New-Variable BEGIN_START_CIVAPP	-Value 7  -Option Constant -Scope Global }
if ($END_START_CIVAPP -eq $null) { New-Variable END_START_CIVAPP	-Value 8  -Option Constant -Scope Global }

if ($BEGIN_STOP_CIVAPP -eq $null) { New-Variable BEGIN_STOP_CIVAPP	-Value 9  -Option Constant -Scope Global }
if ($END_STOP_CIVAPP -eq $null) { New-Variable END_STOP_CIVAPP	-Value 10 -Option Constant -Scope Global }

if ($BEGIN_REMOVE_CIVAPP -eq $null) { New-Variable BEGIN_REMOVE_CIVAPP -Value 11 -Option Constant -Scope Global }
if ($END_REMOVE_CIVAPP -eq $null) { New-Variable END_REMOVE_CIVAPP	 -Value 12 -Option Constant -Scope Global }

if ($BEGIN_NEW_CIVAPP -eq $null) { New-Variable BEGIN_NEW_CIVAPP	-Value 15 -Option Constant -Scope Global }
if ($END_NEW_CIVAPP -eq $null) { New-Variable END_NEW_CIVAPP	    -Value 16 -Option Constant -Scope Global }

if ($THIS_VCLOUD_DEPLOYMENT_ID -eq $null) { New-Variable THIS_VCLOUD_DEPLOYMENT_ID -Value -1 -Option ReadOnly -Scope Global }

function Log-vCloudEvent
(
    [int]$EventID = -1,
    [string]$VerifySuccessful = "", # Sob, can't have null booleans
    [int]$VerifyLoopsCompleted = -1,
    [int]$ExitCode = -1,
    [string]$LastError = "",
    [string]$LastException = "",
    [string]$Notes = "",
    [string]$StartState = "",
	[bool] $ReportError = $False
)
{
	try
	{
		# New system - 1 row per build
		$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
		$SqlConnection.ConnectionString = "Server=$FTP_LOGGING_DB_SERVER;Initial Catalog=$FTP_LOGGING_DB_NAME;User Id=tfsbuild;Password=LMTF`$Bu1ld;"
		try
		{
			$SqlConnection.Open()

			$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
			$SqlCmd.Connection = $SqlConnection

			$deploymentId = $global:THIS_VCLOUD_DEPLOYMENT_ID;

			if ($deploymentId -lt 1)
			{
				# not initialised
				return;
			}

			if ($EventID -gt -1)
			{
				New-Variable -Name columnName -Value "" -Option Private;
				switch ($EventID)
				{
					$ENTER_INIT_SESSION { $columnName = 'Enter_InitSession'; } 
					$EXIT_INIT_SESSION { $columnName = 'Exit_InitSession'; }
				
					$ENTER_EXECUTE_REFRESH_VAPP { $columnName = 'Enter_Execute_Refresh_vApp'; }
					$EXIT_EXECUTE_REFRESH_VAPP { $columnName = 'Exit_Execute_Refresh_vApp'; } 
		
					$ENTER_NEW_VAPP_FROM_TEMPLATE { $columnName = 'Enter_New_Vapp_from_Template'; } 
					$EXIT_NEW_VAPP_FROM_TEMPLATE { $columnName = 'Exit_New_Vapp_from_Template'; } 
		
					$ENTER_VERIFY_VAPP { $columnName = 'Enter_Verify_vApp'; } 
					$EXIT_VERIFY_VAPP { $columnName = 'Exit_Verify_vApp'; } 

					$BEGIN_START_CIVAPP { $columnName = 'Begin_Start_CIvApp'; } 
					$END_START_CIVAPP { $columnName = 'End_Start_CIvApp'; } 

					$BEGIN_STOP_CIVAPP { $columnName = 'Begin_Stop_CIvApp'; } 
					$END_STOP_CIVAPP { $columnName = 'End_Stop_CIvApp'; } 

					$BEGIN_REMOVE_CIVAPP { $columnName = 'Begin_Remove_CIvApp'; } 
					$END_REMOVE_CIVAPP { $columnName = 'End_Remove_CIvApp'; } 
					
					$BEGIN_NEW_CIVAPP { $columnName = 'Begin_New_CIvApp'; } 
					$END_NEW_CIVAPP { $columnName = 'End_New_CIvApp'; } 

				}
				if ($columnName -ne "")
				{
					$SqlCmd.CommandText = "UPDATE [dbo].[vCloudDeployment] SET [$columnName] = GETDATE() WHERE [ID] = $deploymentId";
					
					$result = $SqlCmd.ExecuteNonQuery();
				}
			}

			if (-Not [string]::IsNullOrEmpty($VerifySuccessful))
			{
				$SqlCmd.CommandText = "UPDATE [dbo].[vCloudDeployment] SET [VerifyVappSuccessful] = $VerifySuccessful WHERE [ID] = $deploymentId";

				$result = $SqlCmd.ExecuteNonQuery();
			}
			if ($VerifyLoopsCompleted -gt -1)
			{
				$SqlCmd.CommandText = "UPDATE [dbo].[vCloudDeployment] SET [VerifyLoopsCompleted] = $VerifyLoopsCompleted WHERE [ID] = $deploymentId";

				$result = $SqlCmd.ExecuteNonQuery();
			}

			if ($ExitCode -gt -1)
			{
				$SqlCmd.CommandText = "UPDATE [dbo].[vCloudDeployment] SET [ExitCode] = $ExitCode WHERE [ID] = $deploymentId";

				$result = $SqlCmd.ExecuteNonQuery();
			}

			if (-Not [string]::IsNullOrEmpty($LastError))
			{
				$SqlCmd.CommandText = "UPDATE [dbo].[vCloudDeployment] SET [LastError] = '" + ($LastError.Replace("'", "''")) + "', [LastError_DateTime] = GETDATE() WHERE [ID] = $deploymentId";

				$result = $SqlCmd.ExecuteNonQuery();
			}

			if (-Not [string]::IsNullOrEmpty($LastException))
			{
				$SqlCmd.CommandText = "UPDATE [dbo].[vCloudDeployment] SET [LastException] = '" + ($LastException.Replace("'", "''")) + "' WHERE [ID] = $deploymentId";

				$result = $SqlCmd.ExecuteNonQuery();
			}

			if (-Not [string]::IsNullOrEmpty($Notes))
			{
				$SqlCmd.CommandText = "UPDATE [dbo].[vCloudDeployment] SET [Notes] = ([Notes] + '" + ($Notes.Replace("'", "''")) + "') WHERE [ID] = $deploymentId";

				$result = $SqlCmd.ExecuteNonQuery();
			}

			if (-Not [string]::IsNullOrEmpty($StartState))
			{
				$SqlCmd.CommandText = "UPDATE [dbo].[vCloudDeployment] SET [StartState] = '" + ($StartState.Replace("'", "''")) + "' WHERE [ID] = $deploymentId";

				$result = $SqlCmd.ExecuteNonQuery();
			}
		}
		catch
		{
			if ($ReportError)
			{
				#ERROR
				$msg = "INFO ONLY : Problem in Log-vCloudEvent (SQL: " + ($SqlCmd.CommandText);
				write-output $msg
				write-host $msg

				Write-output  "Details: $_"
				Write-host "Details: $_"
			}
		}
		finally
		{
			$SqlConnection.Close();
		}
	}
	catch
	{
	}
}

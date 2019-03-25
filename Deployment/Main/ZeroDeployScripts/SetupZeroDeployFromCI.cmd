echo off
if "%ZeroDeployPath%"=="" goto :setVar

SET /P ANSWER=This will erase the contents of %ZeroDeployPath% (yes/no)? 
if /i {%ANSWER%}=={yes} (goto :yes) 
goto :no 
:yes 
echo Setting up Zero Deploy FTP from latest CI builds... 

REM Kill all CMD and IISExpress processes and trash the previous CI Zero deploy installation
taskkill /f /im iisexpress.exe

REM Below is suicide, manually kill services for now
REM taskkill /f /im iisexpress.exe 

rmdir /S /Q %ZeroDeployPath%

echo on
start .\LocalRigSetup.cmd /c

start .\Deploy_Local_Databases.cmd /c

REM Powershell.exe -executionpolicy Unrestricted -File .\_SetZeroDeployPath.ps1 

.\GetLatestCiBuild.exe "http://tfs:8080/tfs/ftpdev" "FAE" "FAE.Main.CI" "%ZeroDeployPath%\FAE"
.\GetLatestCiBuild.exe "http://tfs:8080/tfs/ftpdev" "PARE" "Pare.Main.CI" "%ZeroDeployPath%\PARE" 
.\GetLatestCiBuild.exe "http://tfs:8080/tfs/ftpdev" "CACC" "CACC.Main.CI" "%ZeroDeployPath%\CACC" 
.\GetLatestCiBuild.exe "http://tfs:8080/tfs/ftpdev" "Notifications" "Notifications.Main.CI" "%ZeroDeployPath%\Notifications"
.\GetLatestCiBuild.exe "http://tfs:8080/tfs/ftpdev" "SDM" "SDM.Main.CI" "%ZeroDeployPath%\SDM"
.\GetLatestCiBuild.exe "http://tfs:8080/tfs/ftpdev" "Deployment" "Deployment.Main.ZeroDeploy" "%ZeroDeployPath%\Deployment"
.\GetLatestCiBuild.exe "http://tfs:8080/tfs/ftpdev" "MasterData" "MasterData.Main.CI" "%ZeroDeployPath%\MasterData"

@ECHO OFF

Powershell.exe -executionpolicy Unrestricted -File .\ServiceBusSetupForFAE.ps1 -userdomain "FAE" -username "zsvcServiceBus" -password "S3rv1c3B4s"

REM Below script setup servicebus topic and subscribtions
REM ===================================
Powershell.exe -executionpolicy Unrestricted -File .\CreateTopic.ps1 -Namespace ServiceBusDefaultNamespace -Path tfl.ft.sdm.disruption.command.topic 
Powershell.exe -executionpolicy Unrestricted -File .\CreateSubscription.ps1 -Namespace ServiceBusDefaultNamespace -TopicPath tfl.ft.sdm.disruption.command.topic -Name Tfl.Ft.Sdm.Disruption.Command.Fae
Powershell.exe -executionpolicy Unrestricted -File .\CreateTopic.ps1 -Namespace ServiceBusDefaultNamespace -Path tfl.ft.sdm.disruption.status.topic 
Powershell.exe -executionpolicy Unrestricted -File .\CreateSubscription.ps1 -Namespace ServiceBusDefaultNamespace -TopicPath tfl.ft.sdm.disruption.status.topic -Name Tfl.Ft.Sdm.Disruption.Status.Sdm
REM ===================================

Powershell.exe -executionpolicy Unrestricted -File .\ConfigureZeroDeployForCI.ps1

start %ZeroDeployPath%\FAE\EngineControllerHost.exe install

pause
exit /b 0 

:no 
echo Setup aborted! 
exit /b 1

:setVar

echo -------------------------------------------------------
echo ATTENTION!
echo Please set the environment user variable ZeroDeployPath
echo to the desired output location. 
echo You can run SetZeroDeployPath.ps1 to do this.
echo -------------------------------------------------------
pause
exit /b 1
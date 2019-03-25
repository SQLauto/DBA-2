param(
	[string] $serverName = "TDC2SQL005",
	[string] $databaseName = $(throw "Please specify a database."),
	[string] $outputFile = "Output.txt",
	[string] $Environment = "TestRig",
	[string] $IntermediatePatchingFolder = $null,
	[bool] $IntermediatePatchingFolderInclude = $False,
	[bool] $DropDatabase = $True,
	#Additional params for zero deploy from CI 
    [string]$deploymentFolder,
    [string]$scriptpath,
    [string]$patchingScriptsFolder
  )
  
$Script:exitCode = 0;
$scriptpath = split-path $MyInvocation.MyCommand.Path;
Set-Location -Path $scriptpath;
$env:errorLogPath = $scriptPath;
  
$startTime = Get-Date;

$outputFile = [System.IO.Path]::Combine($scriptpath, $outputFile);
$outputFile=[System.IO.Path]::GetFullPath($outputFile);
#global variable used in tfl.DataDeploy.ps1
$DeploymentSummaryLog=$outputFile
$env:databaseName=$databaseName

#deploy the deployment baseline
if([string]::IsNullOrEmpty($deploymentFolder))
{
    $dropFolder=[System.IO.Path]::Combine( $scriptpath, "..\..\..\..\");
    $deploymentFolder = [System.IO.Path]::Combine($dropFolder, "Deployment\Main\Code\Deploy\");
}
if([string]::IsNullOrEmpty($patchingScriptsFolder))
{

	$patchingScriptsFolder = [System.IO.Path]::Combine($deploymentFolder, "..\Build\DeploymentSchema.Scripts\Patching\");
}

$deploymentScriptsFolder=[System.IO.Path]::Combine($deploymentFolder, "Scripts")
$dataDeployScript=[System.IO.Path]::Combine($deploymentScriptsFolder, "TFL.DataDeploy.ps1");
$env:deploymentHelpersPath=[System.IO.Path]::Combine($deploymentFolder, "HelperScripts\SQLHelpers\DeploymentHelpers");

$env:baselinePath=".\Baseline"
$env:Environment=$Environment
$loggingModule=[System.IO.Path]::Combine($deploymentFolder, "Scripts\TFL.Utilities.ps1");
$parametersModule=[System.IO.Path]::Combine($deploymentFolder, "Scripts\TFL.Parameters.ps1");
$dropAndRecreateModule=[System.IO.Path]::Combine($scriptPath, "DropAndRecreateDatabase.ps1");

Import-Module -Name $loggingModule -Force
Import-Module -Name $parametersModule -Force
Import-Module -Name $dropAndRecreateModule -Force

if ($DropDatabase)
{
	$exitCode = DropAndRecreateDatabase -dataSource $serverName -database $databaseName
	if ($exitCode -ne 0)
	{
		LogError "The database drop and recreate function failed"
		$Script:exitCode = 1
		exit
	}
	else
	{
		echo ("Successfully recreated database (in simple recovery): {0}" -f $databaseName);
	}
}

$instanceName=""
$pareFolder="..\..\" 

$databaseRole = "<DatabaseRole Name='FromConfig' Description='Deployment Schema' Include=''>
      <ProjectStub>DeploymentSchema</ProjectStub>
      <TargetDatabase>{0}</TargetDatabase>
      <DatabaseInstance>{1}</DatabaseInstance>
      <PreDeployment></PreDeployment>
      <PatchDeployment>{2}\DeploymentSchema.Patching.sql</PatchDeployment>
      <PostDeployment></PostDeployment>
    </DatabaseRole>" -f $databaseName, $instanceName, $patchingScriptsFolder
$deploymentDatabaseRole=[xml]$databaseRole
$configPart = $deploymentDatabaseRole.DatabaseRole 


$env:scriptPath=$scriptPath;

Set-Location -Path $deploymentScriptsFolder;
Invoke-Command -ScriptBlock{.\TFL.DataDeploy.ps1 $serverName $Environment "TestRig.PARE" $configPart "" $deploymentFolder}
echo $deploymentFolder
if ($LASTEXITCODE -ne 0)
{
    LogError "The incremental deployment schema database script failed."
    $Script:exitCode = 1
    exit
}
echo "ran data deploy"

# Run patches twice to ensure that they are re-runnable
for ($i=1; $i -le 2; $i++)
{

	echo ("Baseline Patches ({0})" -f $i)
	$env:scriptPath= [System.IO.Path]::Combine($scriptpath, "..\Common")
	echo "Environment script path is: "
	echo $env:scriptPath
	$databaseRole="<DatabaseRole Name='FromConfig' Description='Baseline Main Schema Increment' Include=''>
      <ProjectStub>Baseline.Database</ProjectStub>
      <TargetDatabase>{0}</TargetDatabase>
      <DatabaseInstance>{1}</DatabaseInstance>
      <PreDeployment></PreDeployment>
      <PatchDeployment>{2}\Patching\Baseline.Patching.sql</PatchDeployment>
      <PostDeployment></PostDeployment>
	  <PatchDeploymentFolder>{2}\Patching</PatchDeploymentFolder>
	  <PatchFolderFormatStartsWith>B???_R????_</PatchFolderFormatStartsWith>
	  <UpgradeScriptName>Patching.sql</UpgradeScriptName>
	  <PreValidationScriptName>PreValidation.sql</PreValidationScriptName>
	  <PostValidationScriptName>PostValidation.sql</PostValidationScriptName>
	  <DetermineIfDatabaseIsAtThisPatchLevelScriptName>DetermineIfDatabaseIsAtThisPatchLevel.sql</DetermineIfDatabaseIsAtThisPatchLevelScriptName>
    </DatabaseRole>" -f $databaseName, $instanceName, $env:scriptPath
	$deploymentDatabaseRole=[xml]$databaseRole
	$configPart = $deploymentDatabaseRole.DatabaseRole 
	$env:scriptPath=$scriptPath;
    Set-Location -Path $deploymentScriptsFolder;
	Invoke-Command -ScriptBlock{.\TFL.DataDeploy.ps1 $serverName $Environment "TestRig.PARE" $configPart "" $deploymentFolder  -IntermediatePatchingFolder $IntermediatePatchingFolder -IntermediatePatchingFolderInclude $IntermediatePatchingFolderInclude }
    if ($LASTEXITCODE -ne 0)
    {
        LogError "The Baseline Common incremental patching database script failed"
		Write-Error "The Baseline Common incremental patching database script failed";
        $Script:exitCode = 1
        exit
    }
}

$endTime = Get-Date;
$test = New-TimeSpan $startTime $endTime;
$output = "Finished in {0}" -f $test;
LogInfo $output


if ($Script:exitCode -ne 0)
{
    LogError "BUILD FAILED DO NOT USE THIS BUILD";
    Write-Error "BUILD FAILED DO NOT USE THIS BUILD";
}
else
{
    
    
    # set the new colour
       
	LogInfo "Successful Build";
	
}

 # restore the original colour

Remove-Module "DropAndRecreateDatabase";
Remove-Module "TFL.Utilities";

param(
	[string] $serverName =  $(throw "Please specify a server."),
	[string] $instanceName =  $null,
	[string] $databaseName = $(throw "Please specify a database."),
	[string] $outputFile = "Output.txt",
	[string] $Environment = "TestRig2",
	[string] $IntermediatePatchingFolder = $null,
	[bool] $IntermediatePatchingFolderInclude = $False,
	[bool] $DropDatabase = 0 ,
	#Additional params for zero deploy from CI 
    [string]$deploymentFolder,
    [string]$scriptpath,
    [string]$patchingScriptsFolder
  )

function Install-RequiredModule{
 [Cmdletbinding()]
 param(
    [Parameter(Mandatory=$true)]
    [string]$Name,
    [string]$Repository = "FTPNuget",
    [ValidateSet('CurrentUser', 'AllUsers')]
    [string]$Scope = 'CurrentUser'
 )
    $module = Get-InstalledModule -Name $Name -ErrorAction Ignore

    if($module) {
	    Find-Module -Name $Name  -Repository $Repository | Update-Module -ErrorAction Continue
    }
    else{
        Find-Module -Name $Name  -Repository $Repository | Install-Module -Scope $Scope
    }
}
  
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

Import-Module PackageManagement -Verbose

#Next, install the local dev db deployment module. This contains all components and scripts necessary to begin a local DB deployment
#this will in turn load other dependent modules and scripts, which the callee does not need to know about.
Install-RequiredModule -Name "TFL.Deployment.Database"
Install-RequiredModule -Name "TFL.Deployment.Database.Local"
Install-RequiredModule -Name "TFL.PowerShell.Logging"

#Import relevant modules
Import-Module TFL.PowerShell.Logging -Force
Import-Module TFL.Deployment.Database -Force
Import-Module TFL.Deployment.Database.Local -Force




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
#$loggingModule=[System.IO.Path]::Combine($deploymentFolder, "Scripts\TFL.Utilities.ps1");
#$parametersModule=[System.IO.Path]::Combine($deploymentFolder, "Scripts\TFL.Parameters.ps1");
$dropAndRecreateModule=[System.IO.Path]::Combine($scriptPath, "DropAndRecreateDatabase.ps1");

#Import-Module -Name $loggingModule -Force
#Import-Module -Name $parametersModule -Force
Import-Module -Name $dropAndRecreateModule -Force


if([string]::IsNullOrEmpty($instanceName))
{
    $dataSource =  $serverName
}
else
{
	$dataSource =  $serverName +"\"+$instanceName
}


if ($DropDatabase)
{
	$exitCode = DropAndRecreateDatabase -dataSource $dataSource -database $databaseName
	if ($exitCode -ne 0)
	{
		echo "The database drop and recreate function failed"
		$Script:exitCode = 1
		exit
	}
	else
	{
		echo ("Successfully recreated database (in simple recovery): {0}" -f $databaseName);
	}
}

   # Set DB to baseline
    echo "Creating BaselineData baseline DB"
	& sqlcmd -S $dataSource -E -d $databaseName -i $scriptpath\..\BaseLine\baselinedataR68.sql -b
    if ($LASTEXITCODE -ne 0)
    {
        echo "Error running Create database baseline FAE Camden"
        $Script:exitCode = 1
        exit
    }
    else
    {
        echo "Successfully created FAE Camden baseline"
    }



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

if ($LASTEXITCODE -ne 0)
{
    echo "The incremental deployment schema database script failed."
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
      <ProjectStub>BaselineData.Database</ProjectStub>
      <TargetDatabase>{0}</TargetDatabase>
      <DatabaseInstance>{1}</DatabaseInstance>
      <PreDeployment></PreDeployment>
      <PatchDeployment>{2}\Patching\PARE.Patching.sql</PatchDeployment>
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
    $databaseDeployRole = New-Object -TypeName Deployment.Domain.Roles.DatabaseDeploy

    $params = @{
		DropFolder = $DropFolder
		ComputerName = $ServerName
		Environment = $Environment
		DefaultConfig = $Config
		DatabaseRole = $databaseDeployRole
		IntermediatePatchingFolder = $IntermediatePatchingFolder
		HelperScriptRelativePath = $HelperScriptRelativePath
		SqlScriptToRunSuffix = $SqlScriptToRunSuffix
		IntermediatePatchingFolderInclude = $IntermediatePatchingFolderInclude.IsPresent
	}

	Write-Host "Deploying Deployment Role"
	$dataDeployScript = Join-Path $deploymentScriptsFolder "TFL.DataDeploy.ps1"
	$result = & $dataDeployScript @params -Local

    
    Invoke-Command -ScriptBlock{.\TFL.DataDeploy.ps1 $serverName $Environment "TestRig.PARE" $configPart "" $deploymentFolder  -IntermediatePatchingFolder $IntermediatePatchingFolder -IntermediatePatchingFolderInclude $IntermediatePatchingFolderInclude }
    if ($LASTEXITCODE -ne 0)
    {
        echo "The Baseline Common incremental patching database script failed"
		Write-Error "The Baseline Common incremental patching database script failed";
        $Script:exitCode = 1
        exit
    }
}

$endTime = Get-Date;
$test = New-TimeSpan $startTime $endTime;
$output = "Finished in {0}" -f $test;
echo $output


if ($Script:exitCode -ne 0)
{
    echo "BUILD FAILED DO NOT USE THIS BUILD";
    Write-Error "BUILD FAILED DO NOT USE THIS BUILD";
}
else
{
    
    
    # set the new colour
       
	echo "Successful Build";
	
}

 # restore the original colour

#Remove-Module "DropAndRecreateDatabase";
#Remove-Module "TFL.Utilities";

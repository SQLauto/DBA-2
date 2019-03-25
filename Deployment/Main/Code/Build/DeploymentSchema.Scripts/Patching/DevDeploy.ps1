param(
	[string] $serverName = "TDC2SQL005",
	[string] $databaseName = $(throw "Please specify a database."),
	[string] $outputFile = "Output.txt"
  )

$scriptPath = split-path $MyInvocation.MyCommand.Path;
Set-Location -Path $scriptPath;
$Script:exitCode = 0;
  
$startTime = Get-Date;

$env:databaseName=$databaseName
$env:Environment=$Environment
$env:scriptPath="..\"
$dropAndRecreateModule=[System.IO.Path]::Combine($scriptPath, "DropAndRecreateDatabase.ps1");
Import-Module -Name $dropAndRecreateModule

#echo "Drop and recreate database"
#$exitCode = DropAndRecreateDatabase -dataSource $serverName -database $databaseName
#if ($exitCode -ne 0)
#{
#    Echo "The database drop and recreate function failed"
#    $Script:exitCode = 1
#}
#else
#{
 #   echo ("Successfully recreated database (in simple recovery): {0}" -f $databaseName);
	echo "Deployment Schema Deploy"
	& sqlcmd -S $serverName -E -d $databaseName -i DeploymentSchema.Patching.sql -b > $outputFile
	if ($LASTEXITCODE -ne 0)
	{
		echo "The DeploymentSchema.Patching.sql database script failed on first run"
		$Script:exitCode = 1
	}
	else
	{
		echo "calling twice to ensure that scripts are re-runable"
		& sqlcmd -S $serverName -E -d $databaseName -i DeploymentSchema.Patching.sql -b >> $outputFile
		if ($LASTEXITCODE -ne 0)
		{
			echo "The DeploymentSchema.Patching.sql database script failed on second run"
			$Script:exitCode = 1
		}
	}
#}



$endTime = Get-Date;
$test = New-TimeSpan $startTime $endTime;
$output = "Finished in {0}" -f $test;

echo $output;


$backGroundColour = $host.UI.RawUI.BackgroundColor;
$foreGroundColour = $host.UI.RawUI.ForegroundColor;

if ($Script:exitCode -ne 0)
{
    $host.UI.RawUI.BackgroundColor = "Red";
    $host.UI.RawUI.ForegroundColor = "White";
    Echo "BUILD FAILED DO NOT USE THIS BUILD"
}
else
{
    
    
    # set the new colour
    $host.UI.RawUI.BackgroundColor = "Green";
    $host.UI.RawUI.ForegroundColor = "White";
       
	Echo "Successful Build";
	
}

 # restore the original colour
$host.UI.RawUI.BackgroundColor = $backGroundColour;
$host.UI.RawUI.ForegroundColor = $foreGroundColour;



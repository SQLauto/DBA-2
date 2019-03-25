# ALWAYS RUN FROM THE JUMP SERVER!!!!!!
param
(	
    [string] $TargetDBServer = "TS-DB1\INST1",
    [string] $DatabaseName = "NPL"
)

$NPLDBExitCode = 0

Try 
{
    $ScriptPath = join-path $PSScriptRoot "NPL.DB.SysUsers.sql"
    write-output "DB Sys Users  script path is" $ScriptPath
				
    invoke-sqlcmd -inputfile $ScriptPath -serverinstance $TargetDBServer -database $DatabaseName

    $TFSAdminUserExist = Invoke-Sqlcmd -ServerInstance TS-DB1\INST1 -Database NPL -Query "SELECT CASE WHEN EXISTS( SELECT * FROM dbo.SysUser where Login = 'FAELAB\TFSAdmin') THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END"
    $TFSBuildUserExist = Invoke-Sqlcmd -ServerInstance TS-DB1\INST1 -Database NPL -Query "SELECT CASE WHEN EXISTS( SELECT * FROM dbo.SysUser where Login = 'FAELAB\TFSBuild') THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END"

    if($TFSAdminUserExist.Column1 -and $TFSBuildUserExist.Column1)
    {
        Write-output "Database Script run successfully on target machine."
    }
    else
    {
        write-output "Database Script did not run properly and NPL DB Script Exit Code is" $NPLDBExitCode
    }  
}
catch [System.Exception]
{
	$error = $_.Exception.ToString()
	Write-Error "$error"

    $errMsg = "TERMINATING: Failed to execute Database script on Target $TargetDBServer. Exiting with code $exitCode"
	Write-Error $errMsg
	
	$NPLDBExitCode = 1
}

$NPLDBExitCode
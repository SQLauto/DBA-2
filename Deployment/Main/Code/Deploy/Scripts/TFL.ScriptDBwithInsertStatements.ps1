param(
	[string] $serverName = "TDC2SQL005",
	[string] $databaseName ="MasterData_ProjectionStore",
	[string] $DeploymentDrive = "D",
    [string] $directoryToSaveTo='($DeploymentDrive):\DbScripts'
)

# set "Option Explicit" to catch subtle errors
set-psdebug -strict

$errorActionPreference = "stop" 

# Load SMO assembly, and if we're running SQL 2008 DLLs load the SMOExtended and SQLWMIManagement libraries
$v = [System.Reflection.Assembly]::LoadWithPartialName( 'Microsoft.SqlServer.SMO')
if ((($v.FullName.Split(','))[1].Split('='))[1].Split('.')[0] -ne '9') {
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended') | out-null
}
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SmoEnum') | out-null
set-psdebug  -strict # catch a few extra bugs
$errorActionPreference = "stop"

$My='Microsoft.SqlServer.Management.Smo'
$srv = new-object ("$My.Server") $ServerName # attach to the server

if ($srv.ServerType-eq $null) # if it managed to find a server
   {
   Write-Error "Server '$ServerName' either does not exist or cannot be connected to"
   return
}
if($srv.databases[$databaseName] -eq $null)
    {
    Write-Error "Database $databaseName doesn not exist on  '$ServerName' "
   return
}

$scripter = new-object ("$My.Scripter") $srv # create the scripter
$scripter.Options.ToFileOnly = $true
$scripter.Options.ScriptData = $true
$scripter.Options.ScriptSchema = $false
$scripter.Options.DdlHeaderOnly =$true
$scripter.Options.AppendToFile=$true
# we now get all the object types except extended stored procedures
# first we get the bitmap of all the object types we want
$all =[long] [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::all `
    -bxor [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::ExtendedStoredProcedure
# and we store them in a datatable
$d = new-object System.Data.Datatable
# get all tables
$d=$srv.databases[$databaseName].EnumObjects() | `
    Where-Object {$_.DatabaseObjectTypes -eq 'Table'}

$folderNumber=1
# and write out each table with inserts as a file in the directory you specify
$d| FOREACH-OBJECT { # for every object we have in the datatable.
   
   $folderNumberToString=$folderNumber.ToString("0000")
   $schema=$_.schema
   $tablename=$_.name
   $tb=$srv.databases[$databaseName].Tables| `
    Where-Object {$_.Schema -eq $schema -and $_.Name -eq $tablename}
   $rowcount=$tb.RowCount
   
   $SavePath="$($directoryToSaveTo)\B001_R$($folderNumberToString)_$($tablename)"
   # create the directory if necessary (SMO doesn't).
   if (!( Test-Path -path $SavePath )) # create it if not existing
        {Try { New-Item $SavePath -type directory | out-null }
        Catch [system.exception]{
            Write-Error "error while creating '$SavePath' $_"
            return
         }
    }
    # tell the scripter object where to write it
    $scripter.Options.Filename = "$SavePath\Patching.sql";
       
    
    #Determiner
    Out-File -FilePath "$SavePath\DetermineIfDatabaseIsAtThisPatchLevel.sql";
    Add-Content "$SavePath\DetermineIfDatabaseIsAtThisPatchLevel.sql" "GO"
    Add-Content "$SavePath\DetermineIfDatabaseIsAtThisPatchLevel.sql" ":r `$(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql"
    Add-Content "$SavePath\DetermineIfDatabaseIsAtThisPatchLevel.sql" "GO"
    Add-Content "$SavePath\DetermineIfDatabaseIsAtThisPatchLevel.sql" "--nothing to validate as we are starting from scratch"
    Add-Content "$SavePath\DetermineIfDatabaseIsAtThisPatchLevel.sql" "insert into deployment.PatchingLevelDeterminationResult (IsAtPatchLevelWhichWasTested) values(0)"
    
    #PreValidation
    Out-File -FilePath "$SavePath\PreValidation.sql";
    Add-Content "$SavePath\PreValidation.sql" "GO"
    Add-Content "$SavePath\PreValidation.sql" ":r `$(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql"
    Add-Content "$SavePath\PreValidation.sql" "GO"
    Add-Content "$SavePath\PreValidation.sql" "exec #AssertTableExistsWithCount '$schema', '$tablename','0'"
    Add-Content "$SavePath\PreValidation.sql" "GO"
    
    #Patching
    Out-File -FilePath "$SavePath\Patching.sql";
    Add-Content "$SavePath\patching.sql" "Delete from  $schema.$tablename"   

    # Create a single element URN array
    $UrnCollection = new-object ('Microsoft.SqlServer.Management.Smo.urnCollection')
    $URNCollection.add($_.urn)
    # and write out the object to the specified file
    $scripter.enumscript($URNCollection)
       
    Add-Content "$SavePath\patching.sql" "GO"
    Add-Content "$SavePath\patching.sql" "EXEC [deployment].[SetScriptAsRun] 'B001_R$($folderNumbertostring)_$($tablename)'"
    Add-Content "$SavePath\patching.sql" "GO"

    #Post Validation
    Out-File -FilePath "$SavePath\PostValidation.sql";
    Add-Content "$SavePath\PostValidation.sql" "GO"
    Add-Content "$SavePath\PostValidation.sql" ":r `$(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql"
    Add-Content "$SavePath\PostValidation.sql" "GO"
    Add-Content "$SavePath\PostValidation.sql" "exec #AssertTableExistsWithCount '$schema', '$tablename','$rowcount'"
    Add-Content "$SavePath\PostValidation.sql" "GO"

   
    $folderNumber+=1;
 

}
    
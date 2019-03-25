function FindChangeSets {

[CmdletBinding()]
	Param(
            [string] $datesToSearchFor=[String]::Empty
         )
    

    if ($datesToSearchFor -eq [String]::Empty){
        throw [System.ArgumentException] "You need to pass in the comma separated dates that you wish to search for. e.g. 26/10, 27/10 -> {dd}/{mm}/{yy} all parts of optional, though being specific by day and month will help"
    }        

    $reposToQuery = @{
                        "FTM2-Stabilisation"="$/FTM2/Stabilisation"; 
                        "FTM-Stabilisation"="$/FTM/Stabilisation";
                        "FAE-Stabilisation"="$/FAE/Stabilisation";
                        "CACC-Stabilisation"="$/CACC/Stabilisation";
                        "Deployment-Stabilisation"="$/Deployment/Stabilisation";
                        "MasterData-Stabilisation"="$/MasterData/Stabilisation";
                        "Oybo-Stabilisation"="$/OyBO/Stabilisation";
                        "Integration-Stabilisation"="$/Integration/Stabilisation";
                        "Common-Stabilisation"="$/Common/Stabilisation";
                        "DBA-Stabilisation"="$/DBA/Stabilisation";
                        "PARE-Stabilisation"="$/PaRE/Stabilisation";
                    }
					
    $workSpaceRoot = "D:\ChangeSetReview\"
    $dates = $datesToSearchFor -split ","
    $pathToChangeSetSummary = $workSpaceRoot + "ChangesToNote.txt"


    if (-not (Test-Path($workSpaceRoot))){
        mkdir $workSpaceRoot
    }

    cd $workSpaceRoot
    Remove-Item * -include *.* -Recurse
          
    $tfsDirectory = SetTfsExeDirectory
    
    CreateWorkspace -tfExeDirectory $tfsDirectory
   
    cd $workSpaceRoot
           
    Write-Host
	Write-Host "Staring to emumerating repositories looking for changes"
	
    $reposToQuery.GetEnumerator() | ForEach-Object{

        $fileSystemPath = $workSpaceRoot + $_.Key
        $changeSetFileName = $fileSystemPath + "-changesets.txt"

        MapWorkspace -tfExeDirectory $tfsDirectory -tfsRepoPath $_.Value -fileSystemPath $fileSystemPath
    
    
        & ./tf.exe hist $fileSystemPath /recursive > $changeSetFileName

        
        Add-Content $pathToChangeSetSummary ("-----" + $_.Key + "-----")
            foreach($date in $dates){
        
            Get-ChildItem $changeSetFileName | ForEach-Object {
                $fileContent = Get-Content $_.FullName | Where-Object{$_.Contains($date)}        
                Add-Content $pathToChangeSetSummary $fileContent
            }            
        }
        Add-Content $pathToChangeSetSummary "-----------------------------"
        Add-Content $pathToChangeSetSummary " "
    }

    RemoveWorkspace $tfsDirectory
    
    Get-Content $pathToChangeSetSummary
    cd /
}

function CreateWorkspace 
{
    [CmdletBinding()]
    Param(
        [string] $tfExeDirectory         
    )       
		write-host "Creating workspace ChangeSetReview"
        cd $tfExeDirectory
        & .\Tf.exe workspace /new ChangeSetReview /noprompt /collection:http://tfs:8080/tfs/ftpdev 
        & .\Tf.exe workfold /unmap $/
		write-host "Workspace ChangeSetReview Created"
}


function MapWorkspace 
{
    [CmdletBinding()]
    Param(
        [string] $tfExeDirectory ,
        [string] $tfsRepoPath,
        [string] $fileSystemPath        
    )    

    cd $tfExeDirectory
	write-host "Mapping $tfsRepoPath to $fileSystemPath"	
    & .\tf.exe workfold /map $tfsRepoPath $fileSystemPath /workspace:ChangeSetReview
	write-host "$tfsRepoPath successfully mapped to $fileSystemPath"
}

function RemoveWorkspace {
    Param(
        [string] $tfExeDirectory 
    )
    
    cd $tfExeDirectory
    & .\tf.exe workspace ChangeSetReview /delete /noprompt
	write-host "Workspace ChangeSetReview successfully deleted"
}

function SetTfsExeDirectory{

    $tfsDirectory = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\"
    $tfsExePath = $tfsDirectory + "tf.exe"
    if (-not (Test-Path($tfsExePath))){
        $tfsDirectory="D:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\"
        $tfsExePath = $tfsDirectory + "tf.exe"
        if (-not (Test-Path($tfsExePath))){
            throw [System.IO.FileNotFoundException] "tf.exe could not be found"
        }
    }
    return $tfsDirectory
}

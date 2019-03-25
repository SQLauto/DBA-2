$srcPath = "..\..\..\integration\Main\Code\"

function BuildAndRun(){

    $elapsed = [System.Diagnostics.Stopwatch]::StartNew()
    
    Write-host "Started build and run at $(get-date)"
        
    MSBuild.exe $srcPath"Autogration.sln" /p:Configuration=Debug /p:Platform="Any CPU" /consoleloggerparameters:Summary /m 

    if (! $?) { throw "MSBuild failed" }

    Write-host "Running Tests"
    MSTest.exe /nologo /usestderr /testSettings:$srcPath"local.testsettings" /searchpathroot:$srcPath"Autogration.AcceptanceTests\bin\debug\" /resultsfileroot:$srcPath"TestResultsCMD\" /testcontainer:$srcPath"Autogration.AcceptanceTests\bin\debug\Autogration.AcceptanceTests.dll" /category:"Top10" 

    write-host "Ended build and run at $(get-date)"
    write-host "Total elapsed time: $($elapsed.Elapsed.ToString())"
}


function BuildAndRunTop100(){

    $elapsed = [System.Diagnostics.Stopwatch]::StartNew()
    
    Write-host "Started build and run at $(get-date)"
        
    MSBuild.exe $srcPath"Autogration.sln" /p:Configuration=Debug /p:Platform="Any CPU" /consoleloggerparameters:Summary /m 

    if (! $?) { throw "MSBuild failed" }

    Write-host "Running Tests"
    MSTest.exe /nologo /usestderr /testSettings:$srcPath"local.testsettings" /searchpathroot:$srcPath"Autogration.AcceptanceTests\bin\debug\" /resultsfileroot:$srcPath"TestResultsCMD\" /testcontainer:$srcPath"Autogration.AcceptanceTests\bin\debug\Autogration.AcceptanceTests.dll" /category:"zerodeploy" 

    write-host "Ended build and run at $(get-date)"
    write-host "Total elapsed time: $($elapsed.Elapsed.ToString())"
}

function Build(){

    Write-Host "Building Autogration solution"
    MSBuild.exe $srcPath"Autogration.sln" /p:Configuration=Debug /p:Platform="Any CPU" /consoleloggerparameters:Summary /m 
}

function RunTests(){

    Write-host "Running Tests"
    MSTest.exe /nologo /usestderr /testSettings:$srcPath"local.testsettings" /searchpathroot:$srcPath"Autogration.AcceptanceTests\bin\debug\" /resultsfileroot:$srcPath"TestResultsCMD\" /testcontainer:$srcPath"Autogration.AcceptanceTests\bin\debug\Autogration.AcceptanceTests.dll" /category:"Top10" 
}

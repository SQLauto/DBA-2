   
 param(
  [string] $BinariesDirectory="",  
  [string] $IntegrationTestResults="",
  [string] $DropFolder=""
)

write-host "BinariesDirectory:" $BinariesDirectory

$testResultFolder= $BinariesDirectory.Replace("Binaries","TestResults")
$sourcesFolder= $BinariesDirectory.Replace("Binaries","Sources")
$FAESourceFolder= join-path $sourcesFolder "FAE\Main\Code\"
write-output "testResultFolder:" $testResultFolder
write-output "sourcesFolder:"  $sourcesFolder
write-output "FAESourceFolder:" $FAESourceFolder

#TFSBuild_TDC2BLD005 2014-11-18 23_33_17_Mixed Platforms_Debug.trx

$trxFolders=Get-ChildItem -Path $testResultFolder -Exclude "*.trx"
foreach ($trxfolder in $trxFolders){

    $possibleTestPath= join-path $trxfolder "out\Automation.tests.dll"
    if (Test-Path($possibleTestPath )){
        $trxFolderName= $trxfolder 
    }
}
write-output "trxFileName:" $trxFolderName
$trimmedtrxFileName= $trxFolderName.ToString().TrimEnd()+".trx"
write-output "trimmedtrxFileName: "  $trimmedtrxFileName

    If(Test-Path $trimmedtrxFileName){
    $testResultParameter="/testResult:$trimmedtrxFileName"
    write-host "testResultParameter:" $testResultParameter
    #Ganesh's test
    $specFlowPath="\\tdc2bld006\packages\SpecFlow.1.9.0\tools\SpecFlow.exe"
    $msTestExecutionReport="mstestexecutionreport"
    $testProj= join-path $FAESourceFolder "Automation.Testing\Automation.Tests.csproj"

    $ReportOutput= join-path $DropFolder "SpecFlow_Nightly_NightTube_Result.html"
    write-output "ReportOutput: " $ReportOutput
    $specFlowReport="/out:" + """$ReportOutput"""
    write-output "Will execute "	$specFlowPath $msTestExecutionReport $testProj $testResultParameter $specFlowReport 
	& $specFlowPath $msTestExecutionReport $testProj $testResultParameter $specFlowReport
    }



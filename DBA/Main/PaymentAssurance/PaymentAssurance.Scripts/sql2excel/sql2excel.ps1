$ScriptVersion='1.0'

function Import-Modules
{    
      $SQL2Excel=Join-Path -path $PSScriptRoot -childPath "\scripts\SQL2Excel.psm1"
      import-module $SQL2Excel -DisableNameChecking  
      
      $writelog=Join-Path -path $PSScriptRoot -childPath "\scripts\write-log.psm1"
      import-module $writelog -DisableNameChecking  

      $htmlreport=Join-Path -path $PSScriptRoot -childPath "\scripts\htmlreport.psm1"
      import-module $htmlreport -DisableNameChecking  
}

Import-Modules
Set-Location "$PSScriptRoot"



$debugmode=$false
$tablelog=$null

try
{
        [string]$workconfigxmlfile=Join-Path -path $PSScriptRoot -childPath "\inputs\readonlyfiles\workconfig.xml"
        [xml]$localworkconfig=Get-content $workconfigxmlfile
        $sql2excelworkNode=$localworkconfig.tfl.sql2excel
        $worklogging=$sql2excelworkNode.logging
        
        [string]$configxmlfile=Join-Path -path $PSScriptRoot -childPath "\inputs\config.xml"
        [xml]$localconfig=Get-content $configxmlfile
        $sql2excelNode=$localconfig.tfl.sql2excel
        $format=$sql2excelNode.outputformat
        $sqlinput=$sql2excelNode.sqlinput
 
        $processfolder=$sql2excelNode.processfolder
        $outputfolder=$sql2excelNode.outputfolder
        $excelpassword=$sql2excelNode.excelpassword
        $autofit=$sql2excelNode.AutoFit
        $autofitMaxWidth=$sql2excelNode.AutoFitMaxWidth
        $limitdata=$sql2excelNode.limitdata
        $queryTimeout=$sql2excelNode.queryTimeoutSS
        $connectionTimeout=$sql2excelNode.connectionTimeoutSS
         
        [object]$logging=$localconfig.tfl.logging
    
        if($format -eq "excel")
        {
            $scriptcode="SQL2EXCEL"
        }
        else
        {
            $scriptcode="SQL2CSV"
        }
        
        [string]$todaydate=(Get-Date).ToString('yyyyMMddHHmmss')
        [string]$logfilename=$scriptcode + "_" + $todaydate + ".log"
        $logging | Add-Member NoteProperty logfilename("$logfilename")

        $iserror=$false

        $runno=Log-Start -ScriptVersion $ScriptVersion -format $scriptcode -logging $logging -worklogging $worklogging
        $iserror=extract-SQLData -sqlinput $sqlinput -processfolder $processfolder -connectionTimeout $connectionTimeout -queryTimeout $queryTimeout -limitdata $limitdata -excelpassword $excelpassword -AutoFit $autofit -AutoFitMaxWidth $autofitMaxWidth -format $format -logging $logging -worklogging $worklogging
        Log-FinishXml -logging $logging -logname $scriptcode
        Log-Report -format $scriptcode -logstage "file" -logging $logging -worklogging $worklogging -executionid $runno -outputfolder $outputfolder
        Log-Finish -NoExit $true -format $scriptcode -logging $logging -worklogging $worklogging
        Copy-ProcessedFile -processfolder $processfolder -outputfolder $outputfolder
        Log-Email -iserror $iserror -format $scriptcode -logging $logging 
        $exit=0
}
catch [Exception] 
{ 
        $objerror=$_ 
        $ErrorMessage="Unhandled Error Occured."
        Log-Error -ErrorMessage "$ErrorMessage" -ErrorObj $objerror -ExitGracefully $false -format $scriptcode -logging $logging -noxml $true
        Log-Finish -format $scriptcode -logging $logging -NoExit $true
        Log-Email -iserror 1 -format $scriptcode -logging $logging
        $exit=1
}
finally
{
    #delete all logs which is more than 30 days old
    $rtncode=log-purge -logging $logging -format $scriptcode
    if($exit -eq 1 -or $rtncode -eq 1)
    {
        exit 1  #exit=1 failure
    }
    else
    {
        exit 0 #exit=0 Pass
    }
}
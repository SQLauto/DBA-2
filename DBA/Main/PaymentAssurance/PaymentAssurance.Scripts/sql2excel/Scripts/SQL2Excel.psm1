[string]$ConnectionStringFormat1 = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}" 
[string]$ConnectionStringFormat2="Server={0};Database={1};Integrated Security=SSPI;Connect Timeout={2}"

function openConnectionString([string]$Connectionstring)
{
   $Connection = New-Object System.Data.SQLClient.SQLConnection
   $Connection.ConnectionString = $Connectionstring
   $Connection.Open()
   return $Connection
}    


function closeConnectionString($Connection,$Command)
{
    if ($Connection.State -eq "Open") 
    { 
       $Command.Dispose();
       $Connection.Close();
       $Connection.Dispose();
    } 
}

function RollbackOrCommitTransaction($Command,$onErrorAction='none')
{
    if($onErrorAction -eq 'Rollback')
    {
        $Command.CommandText = "IF @@TRANCOUNT>0 ROLLBACK TRAN;" # if you want to discard
    }
    elseif($onErrorAction -eq 'Commit')
    {
        $Command.CommandText = "WHILE @@TRANCOUNT>0 COMMIT TRAN;" # if you want to save
    }
    
    if($onErrorAction -ne 'none')
    {
        $Command.ExecuteNonQuery()
    }
}

function Copy-ProcessedFile
{
    param([string]$processfolder,[string]$outputfolder)

    [string]$sourceDirectory  = Join-Path -path $processfolder -childPath "\*"
    [string]$destinationDirectory = Join-Path -path $outputfolder -childPath "\"
    move-item $sourceDirectory -Destination $destinationDirectory -Force
}

function extract-SQLData
{

param([object]$sqlinput, [string]$processfolder, [string]$excelpassword=$null,[string]$AutoFit,
      [Int32]$AutoFitMaxWidth, [Int32]$queryTimeout=0, [Int32]$connectionTimeout=0, 
      [Int32]$limitdata=0,[string]$format, [object]$logging,[object]$worklogging) 

    if($format -eq 'excel')
    {
        $iserror=Write-SQL2Excel -sqlinput $sqlinput -processfolder $processfolder -excelpassword $excelpassword -AutoFit $autofit -AutoFitMaxWidth $autofitMaxWidth -queryTimeout $queryTimeout -connectionTimeout $connectionTimeout -limitdata $limitdata  -format "SQL2EXCEL" -logging $logging -worklogging $worklogging

    }
    else
    {    
          $iserror=Write-SQL2CSV -sqlinput $sqlinput -processfolder $processfolder -queryTimeout $queryTimeout -connectionTimeout $connectionTimeout -limitdata $limitdata -format "SQL2CSV" -logging $logging -worklogging $worklogging
    }

    return $iserror
}

function  Write-SQL2Excel #using open excel
{ 
    param([string]$dbhandler="master", [object]$sqlinput, [string]$processfolder,[string]$excelpassword=$null,
          [string]$AutoFit,[Int32]$AutoFitMaxWidth,[string]$username=$null, [string]$password=$null, [Int32]$queryTimeout=0, [Int32]$connectionTimeout=0, 
          [Int32]$limitdata=0,[string]$format,[object]$logging,[object]$worklogging)  
    
    #queryTimeout=0 menas no restriction
    #limitdata=0 means no restriction of data
    
    $instance=$sqlinput.runatserver
    $dbhandler=$sqlinput.runatdb
    [string]$logfilename=Join-Path -path $logging.logfolder -childPath $logging.logfilename

    if($AutoFit -eq 'true' -or $AutoFit -eq '1' -or $AutoFit -eq 'yes')
    {
        [bool]$AutoFit=$true
    }
    else
    {
        [bool]$AutoFit=$false
    }

    $ToolDir=Get-Location -PSProvider FileSystem
    $SQL2Excel=Join-Path -path $ToolDir -childPath "\scripts\export2openexcel.psm1"
    import-module $SQL2Excel -DisableNameChecking 

    $excel=init-excel -processfolder $processfolder

     
    $iserror=$false;
    $ToolDir=Get-Location -PSProvider FileSystem
    [string]$todaydate=(Get-Date).ToString('yyyyMMddHHmmss')
    $inputfolder=Join-Path -path $ToolDir -childPath "\temp\$todaydate"
    $files0bjs=findInputQueries -sqlinput $sqlinput -logging $logging -worklogging $worklogging -inputfolder $inputfolder
    
    $files=$files0bjs.files
    $inputfolder=$files0bjs.inputfolder
    create-logtable -sqlinput $sqlinput -worklogging $worklogging -format $format -logging $logging -logtable "reports"

    $orderfilexmlfile=Join-Path -path $inputfolder -childPath "\fileorder.xml"
    if(Test-Path $orderfilexmlfile)
    {
        $orderbyxml=$true
        [xml]$orderfilexml=Get-content $orderfilexmlfile
        [string]$orderfileNode=$orderfilexml.tfl.orderfiles
        $orderbyfilearray=$orderfileNode -split(',')

        [string]$deletefiles=$orderfilexml.tfl.deletefiles
        $deletefilesarray=$deletefiles -split(',')
    }
    else
    {
        $orderbyxml=$false
        $orderbyfilearray=$files
        $deletefilesarray=$null
    }
    foreach ($file in $orderbyfilearray) 
    {
        if($orderbyxml)
        {
            $filename=$file.trim()
        }
        else
        {
            $filename=$file.name
        }
        $InputFile=Join-Path -path $inputfolder -childPath $filename

        Log-inputsqls -sqlinput $sqlinput -InputFile $InputFile -format $format -logging $logging -logfilename $logfilename -worklogging $worklogging

        Log-Write -logstage "file" -logstepname "$filename" -LineValue "Process file $file..." -format $format -logging $logging 
        try 
        {
             $sheetname=[System.IO.Path]::GetFileNameWithoutExtension("$InputFile")
            
             $objs=$null
             $startTime = (Get-Date)
             $objs=invoke-SqlReader -instance $instance -dbhandler $dbhandler -InputFile $InputFile -queryTimeout $queryTimeout -onErrorAction None
             $endTime = (Get-Date)
             if($objs.HasError -ne $true)
             {
                Export-XLSX -Path $excel -InputObject $objs -WorksheetName $sheetname -password $excelpassword -Autofit $AutoFit -AutoFitMaxWidth $AutoFitMaxWidth
             }
             else
             {
                $iserror=$true
                Log-Error -logstage "file" -logstepname "$filename" -ErrorObj $objs -ExitGracefully $false -format "$format" -logging $logging
             }   
        } 
        catch [Exception]
        {
             if($endTime -eq $null)
             {
                $endTime = (Get-Date)
             }
             $objerror=$_ 
             $iserror=$true
             Log-Error -logstage "file" -logstepname "$filename" -ErrorObj $objerror -ExitGracefully $false -format "$format" -logging $logging
         }
         
        $ElapsedTime= $([math]::Round(($endTime-$startTime).totalMinutes, 2))
        Log-Write -logstage "file" -logstepname "$filename" -LineValue "Finished Processing file $filename" -position 'end' -ElapsedTime "$ElapsedTime" -format $format -logging $logging 
    }
    
    if($deletefilesarray -ne $null)
    {
        foreach ($file in $deletefilesarray) 
        {
            $filename=$file.trim()
            $deleteFile=Join-Path -path $inputfolder -childPath $filename
            Remove-Item $deleteFile -Force -ErrorAction SilentlyContinue
        }
    }



    If((test-path $inputfolder))
    {   
        $method=($sqlinput).method
        if($method -eq 'table')
        {
            Remove-Item $inputfolder -Force -Recurse
        }
    }
    Remove-Module export2openexcel


    return $iserror
}


function Write-SQL2CSV
{ 
    param([string]$dbhandler="master", [object]$sqlinput, [string]$processfolder,
          [string]$username=$null, [string]$password=$null, [Int32]$queryTimeout=0, [Int32]$connectionTimeout=0,
          [Int32]$limitdata=0, [string]$format,[object]$logging,[object]$worklogging)  
    
    $instance=$sqlinput.runatserver
    $dbhandler=$sqlinput.runatdb
    [string]$logfilename=Join-Path -path $logging.logfolder -childPath $logging.logfilename

    $iserror=$false;
    $ToolDir=Get-Location -PSProvider FileSystem
    [string]$todaydate=(Get-Date).ToString('yyyyMMddHHmmss')
    $inputfolder=Join-Path -path $ToolDir -childPath "\temp\$todaydate"
    $files0bjs=findInputQueries -sqlinput $sqlinput -logging $logging -worklogging $worklogging -inputfolder $inputfolder
    
    $files=$files0bjs.files
    $inputfolder=$files0bjs.inputfolder
    create-logtable -sqlinput $sqlinput -worklogging $worklogging -format $format -logging $logging -logtable "reports"

    foreach ($file in $files) 
    {
        $filename=$file.name
        Log-Write -logstage "file" -logstepname "$filename" -LineValue "Process file $file..." -format $format -logging $logging 
        $InputFile=Join-Path -path $inputfolder -childPath $filename
        $sheetname=[System.IO.Path]::GetFileNameWithoutExtension("$InputFile")
        
        Log-inputsqls -InputFile $InputFile -format $format -logging $logging -logfilename $logfilename -worklogging $worklogging

        try 
        { 
            [string]$todatstring=$((Get-Date).ToString("yyyyMMddhhmmss"))
            [string]$outputpath=$processfolder+"\"+$sheetname + "_" + $todatstring+".csv"
             $startTime = (Get-Date)
             $objs=invoke-SqlReader -instance $instance -dbhandler $dbhandler -InputFile $InputFile -queryTimeout $queryTimeout -onErrorAction None
             $endTime = (Get-Date)
            
            
            if($objs.HasError -ne $true)
            {
                 $objs | Export-Csv -Path $outputpath -NoTypeInformation -Encoding UTF8
            }
            else
            {
                 Log-Error -logstage "file" -logstepname "$filename" -ErrorObj $objs -ExitGracefully $false -format "$format" -logging $logging
                 $iserror=$true
            }
        }
        catch [Exception] 
        { 
             if($endTime -eq $null)
             {
                $endTime = (Get-Date)
             }
             $objerror=$_ 
             Log-Error -logstage "file" -logstepname "$filename" -ErrorObj $objerror -ExitGracefully $false -format "$format" -logging $logging
             $iserror=$true
        }
        $ElapsedTime= $([math]::Round(($endTime-$startTime).totalMinutes, 2))
        Log-Write -logstage "file" -logstepname "$filename" -LineValue "Finished Processing file $filename" -ElapsedTime "$ElapsedTime" -format $format -logging $logging 
      }  

      If((test-path $inputfolder))
      {
        $method=($sqlinput).method
        if($method -eq 'table')
        {
            Remove-Item $inputfolder -Force -Recurse
        }
      }
      return $iserror
    }

function Log-inputsqls([string]$InputFile, [object]$logging,[object]$worklogging,[string]$logfilename,[string]$format)
{
    $logtotable=$logging.logToTable
    $islog=$logtotable.islog
    $instance=$logtotable.instance
    $database=$logtotable.database

    if($islog -eq 'true' -or $islog -eq '1' -or $islog -eq 'yes')
    {
        $filename= Split-Path $InputFile -leaf
        $querytext=Get-content $InputFile -encoding String | Out-String

        $getdiff=CompareTwoFiles -InputFile $InputFile -logging $logging -worklogging $worklogging
        if($getdiff)
        {
            $ToolDir=Get-Location -PSProvider FileSystem  
            $tables=$worklogging.tables.table
            $executiontab=$tables | Where-Object{$_.tablename -eq "reports"}
            $tablename=($executiontab).tablename
            $schemaname=($executiontab).schemaname
            $inserttablesql=($executiontab).insertsql
            $updatetablesql=($executiontab).updatesql

            $updatetablesql=Join-Path -path $ToolDir -childPath "\inputs\sqls\$updatetablesql"
            $sqlvariables = @{filename=$filename;}
            $sqlvarstypes= @{filename='string';}
            $objs=$null
            $objs=invoke-SqlNonQuery -instance $instance -InputFile $updatetablesql -dbhandler $database -sqlvariables $sqlvariables -sqlvarstypes $sqlvarstypes
            if($objs.HasError)
            {
                Log-Error -ErrorObj $objs -format $format -logging $logging
            }
            else
            {
                 if($objs.errortype -ne "NOLOGGING")
                 {
                    Log-Write -LineValue "Old file $filename disabled in reports table" -format $format -logging $logging -noxml $true
                 }
                 
                 $sqlvariables = @{filename=$filename;querytext=$querytext}
                 $sqlvarstypes= @{filename='varchar|100';querytext='varchar|max'}
                 #$sqlvarstypes= @{filename='varchar|100';querytext='xml'}
            
                  
                 $insertscript=Join-Path -path $ToolDir -childPath "\inputs\sqls\$inserttablesql"
                 $objs=$null
                 $objs=invoke-SqlNonQuery2 -instance $instance -InputFile $insertscript -dbhandler $database -sqlvariables $sqlvariables -sqlvarstypes $sqlvarstypes
                 if($objs.HasError)
                 {
                     Log-Error -ErrorObj $objs -format $format -logging $logging
                 }
                 else
                 {
                      if($objs.errortype -ne "NOLOGGING")
                      {
                         Log-Write -LineValue "NEW file $filename inserted in reports table for logging" -format $format -logging $logging -noxml $true
                      }       
                 }     
            }

            
        }

    }
}

function CompareTwoFiles([string]$InputFile,[object]$logging,[object]$worklogging)
{
    $ToolDir=Get-Location -PSProvider FileSystem
    $filename= Split-Path $InputFile -leaf
    $newquery=Get-content $InputFile -encoding String | Out-String

    
    $logtotable=$logging.logToTable
    $instance=$logtotable.instance
    $database=$logtotable.database

    $tables=$worklogging.tables.table
    $executiontab=$tables | Where-Object{$_.tablename -eq "reports"}
    $selectsql=($executiontab).selectsql
	$selectsql=Join-Path -path $ToolDir -childPath "\inputs\sqls\$selectsql"
		 
	$sqlvariables = @{filename=$filename}
    $sqlvarstypes= @{filename='varchar|100'}

	try 
    {
           $objs=$null
           $objs=invoke-SqlReader2 -instance $instance -dbhandler $database -InputFile $selectsql -sqlvariables $sqlvariables -sqlvarstypes $sqlvarstypes -queryTimeout $queryTimeout -onErrorAction None
           if($objs.HasError -ne $true)
           {
               if($objs -ne $null)
               {
                    $storedqyery=$objs.QUERY
                    $diff=Compare-Object -ReferenceObject $newquery.trim() -DifferenceObject $storedqyery.trim()
                }
               else
               {
                    $diff=$true
               }
           }
           else
           {
                 $iserror=$true
                 Log-Error -logstage "file" -logstepname "$filename" -ErrorObj $objs -ExitGracefully $false -format "$format" -logging $logging
                 $diff=$null
           } 
                 
      } 
      catch [Exception]
      {
           $diff=$null
           $objerror=$_ 
           $iserror=$true
           Log-Error -logstage "file" -logstepname "$filename" -ErrorObj $objerror -ExitGracefully $false -format "$format" -logging $logging
      }

    
    if($diff -ne $null)
    {
        return $true
    }
    else
    {
        return $false
    }

    
}

 function invoke-SqlReader 
 {
      param(
      [string]$instance,
      [string]$dbhandler="master",
      [string]$cmdText,
      [Int32]$queryTimeout, 
      [string]$InputFile,
      $sqlvariables=$null, 
      $sqlvarstypes=$null,
      [bool]$formatsql=$false,
      [ValidateSet("Rollback","Commit","None")] [string]$onErrorAction='none',
      [string]$username=$null,
      [string]$password=$null,
      [int]$connectionTimeout=0
      )

     
     
     
     if($username) 
     { $dbConnString = $ConnectionStringFormat1 -f $instance,$dbhandler,$username,$password,$connectionTimeout } 
     else 
     { $dbConnString = $ConnectionStringFormat2 -f $instance,$dbhandler,$connectionTimeout }

      try
      {        
          $cmdText=formatted-query -InputFile $InputFile -cmdText $cmdText -sqlvariables $sqlvariables -sqlvarstypes $sqlvarstypes -formatsql $formatsql
          $Connection=openConnectionString $dbConnString
          $Command = New-Object System.Data.SQLClient.SQLCommand 
          $Command.Connection = $Connection 
          $Command.CommandText = $cmdText 
          $Command.CommandTimeout =$queryTimeout
          $Reader = $Command.ExecuteReader()  
          
          $tableobj = new-object “System.Data.DataTable”
          $tableobj.Load($Reader)
          $Reader.close()
          
      }
      catch [System.Data.SqlClient.SqlException]
      {
           $tableobj=@{};
           $tableobj.HasError=$true
           $tableobj.Query=$cmdText
           $tableobj.errortype="Exception";
           $tableobj.message=$_.Exception.Message.ToString()
           if($_.Exception.Number -eq -2) # -2=command timeout occured!
           {   
                $tableobj.errortype="Query Timeout"
                RollbackOrCommitTransaction -Command $Command -onErrorAction $onErrorAction
           }

      }
      finally
      {
        closeConnectionString -Connection $Connection -Command $Command
      }
      return $tableobj;
}

 function invoke-SqlReader2
 {
      param(
      [string]$instance,
      [string]$dbhandler="master",
      [string]$cmdText,
      [Int32]$queryTimeout, 
       [string]$InputFile,
       $sqlvariables=$null, 
       $sqlvarstypes=$null,
       [bool]$formatsql=$false,
       [ValidateSet("Rollback","Commit","None")] [string]$onErrorAction='none',
       [string]$username=$null,
       [string]$password=$null,
       [int]$connectionTimeout=0
      )

     if($username) 
     { $dbConnString = $ConnectionStringFormat1 -f $instance,$dbhandler,$username,$password,$connectionTimeout } 
     else 
     { $dbConnString = $ConnectionStringFormat2 -f $instance,$dbhandler,$connectionTimeout }
     

      try
      {
          $cmdText=formatted-query -InputFile $InputFile -cmdText $cmdText -formatsql $formatsql
          $Connection=openConnectionString $dbConnString
          $Command = New-Object System.Data.SQLClient.SQLCommand 
          $Command.Connection = $Connection 
          $Command.CommandText = $cmdText 
          $Command.CommandTimeout =$queryTimeout

          foreach($sqlvarstype in $sqlvarstypes.keys)
          {
            [string]$vartypestr=$sqlvarstypes[$sqlvarstype] 
            $vartypearr=$vartypestr.split('|')
            $vartype=$vartypearr[0]
            $varlength=$vartypearr[1]
            if($varlength -eq "max")
            {
                $varlength="-1"
            }

            if($varlength -eq $null)
            {
                $Command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@$sqlvarstype",[Data.SQLDBType]::$vartype))) | Out-Null
            }
            else
            {
                $Command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@$sqlvarstype",[Data.SQLDBType]::$vartype, $varlength))) | Out-Null
            }
         }

        $i=0
        foreach($sqlvariable in $sqlvariables.keys)
        {
            $varValue=$sqlvariables[$sqlvariable] 
            $Command.Parameters[$i].Value = "$varValue"
            $i++
        }

        $Reader = $Command.ExecuteReader()  
        $tableobj = new-object “System.Data.DataTable”
        $tableobj.Load($Reader)
        $Reader.close()
          
      }
      catch [System.Data.SqlClient.SqlException]
      {
           $tableobj=@{};
           $tableobj.HasError=$true
           $tableobj.Query=$cmdText
           $tableobj.errortype="Exception";
           $tableobj.message=$_.Exception.Message.ToString()
           if($_.Exception.Number -eq -2) # -2=command timeout occured!
           {   
                $tableobj.errortype="Query Timeout"
                RollbackOrCommitTransaction -Command $Command -onErrorAction $onErrorAction
           }

      }
      finally
      {
        closeConnectionString -Connection $Connection -Command $Command
      }
      return $tableobj;
}

function invoke-SqlNonQuery2
{
           param([string]$instance, [string]$dbhandler="master",[string]$cmdText=$null, 
          [string]$InputFile=$null, $sqlvariables=$null, $sqlvarstypes=$null,
          [string]$username=$null, [string]$password, [Int32]$queryTimeout=0, [Int32]$connectionTimeout=0, 
          [string]$onErrorAction='none',[bool]$formatsql=$false)
 
    if($username) 
    { $dbConnString = $ConnectionStringFormat1 -f $instance,$dbhandler,$username,$password,$connectionTimeout } 
    else 
    { $dbConnString = $ConnectionStringFormat2 -f $instance,$dbhandler,$connectionTimeout } 

    $tableobj=@{};
    try 
    {
        $cmdText=formatted-query -InputFile $InputFile -cmdText $cmdText -formatsql $formatsql
        $Connection=openConnectionString $dbConnString
        $Command = New-Object System.Data.SQLClient.SQLCommand 
        $Command.Connection = $Connection 
        $Command.CommandTimeout =$queryTimeout
        $Command.CommandText = $cmdText 
    
        foreach($sqlvarstype in $sqlvarstypes.keys)
        {
            [string]$vartypestr=$sqlvarstypes[$sqlvarstype] 
            $vartypearr=$vartypestr.split('|')
            $vartype=$vartypearr[0]
            $varlength=$vartypearr[1]
            if($varlength -eq "max")
            {
                $varlength="-1"
            }

            if($varlength -eq $null)
            {
                $Command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@$sqlvarstype",[Data.SQLDBType]::$vartype))) | Out-Null
            }
            else
            {
                $Command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@$sqlvarstype",[Data.SQLDBType]::$vartype, $varlength))) | Out-Null
            }
        }

        $vartype=$null
        $i=0
        foreach($sqlvariable in $sqlvariables.keys)
        {
            $varValue=$sqlvariables[$sqlvariable] 
            $Command.Parameters[$i].Value = $varValue
            $i++
        }
 

        ## Attach the InfoMessage Event Handler to the connection to write out the messages  
        $global:sp_messagereturn=""
        $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {param($sender, $event) $global:sp_messagereturn=$sp_messagereturn + "`n" + $event.Message };
        $Connection.add_InfoMessage($handler);
        $Connection.FireInfoMessageEventOnUserErrors = $true;
        $insertedID=$Command.ExecuteScalar() 
             
        $tableobj.Query=$cmdText
        if($sp_messagereturn.trim() -contains "TABLE ALREADY EXIST")
        {
             $tableobj.HasError=$false
             $tableobj.errortype="NOLOGGING";
             $message="Table already exist."
        }
        elseif(($insertedID -gt 0) -and ($sp_messagereturn -eq $null -or $sp_messagereturn -eq ""))
        {
            $tableobj.HasError=$false
            $tableobj.insertedID=$insertedID
            $tableobj.errortype="INFO";
            $message="Command(s) completed successfully."
        }
        else
        {
            $tableobj.HasError=$true
            $tableobj.errortype="ERROR";
            $message=$sp_messagereturn
        }
        $tableobj.message=$message

   } 
   catch [System.Data.SqlClient.SqlException] 
   { 
           $tableobj.HasError=$true
           $tableobj.Query=$cmdText
           $tableobj.errortype="ERROR";
           $tableobj.message=$_.Exception.Message.ToString()
           if($_.Exception.Number -eq -2)
           {   
                $tableobj.errortype="Query Timeout"
           }
           RollbackOrCommitTransaction -Command $Command -onErrorAction "Rollback"
    }
    finally
    {
      closeConnectionString -Connection $Connection -Command $Command
    }
    return  $tableobj

}

function invoke-SqlNonQuery
{ 
     param([string]$instance, [string]$dbhandler="master",[string]$cmdText=$null, 
          [string]$InputFile=$null, $sqlvariables=$null, $sqlvarstypes=$null,
          [string]$username=$null, [string]$password, [Int32]$queryTimeout=0, [Int32]$connectionTimeout=0, 
          [string]$onErrorAction='none',[bool]$formatsql=$false)
    
    #$username="mytest"
    #$password="mytest"

    if ($username) 
    { $dbConnString = $ConnectionStringFormat1 -f $instance,$dbhandler,$username,$password,$connectionTimeout } 
    else 
    { $dbConnString = $ConnectionStringFormat2 -f $instance,$dbhandler,$connectionTimeout } 

    $tableobj=@{};

    try 
    {
            $cmdText=formatted-query -InputFile $InputFile -cmdText $cmdText -sqlvariables $sqlvariables -sqlvarstypes $sqlvarstypes -formatsql $formatsql
            $Connection=openConnectionString $dbConnString
            $Command = New-Object System.Data.SQLClient.SQLCommand
            $Command.CommandTimeout =$queryTimeout #$querytimeout
            $Command.Connection = $Connection 
            $Command.CommandText = $cmdText 

            ## Attach the InfoMessage Event Handler to the connection to write out the messages  
            $global:sp_messagereturn=""
            $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {param($sender, $event) $global:sp_messagereturn=$sp_messagereturn + "`n" + $event.Message };
            $Connection.add_InfoMessage($handler);
            $Connection.FireInfoMessageEventOnUserErrors = $true;
            $retsql=$Command.ExecuteNonQuery() 
            
            $tableobj.Query=$cmdText
            if($sp_messagereturn.trim() -contains "TABLE ALREADY EXIST")
            {
                $tableobj.HasError=$false
                $tableobj.errortype="NOLOGGING";
                $message="Table already exist."
            }
            elseif(($retsql -eq -1 -or $retsql -eq 1) -and ($sp_messagereturn -eq $null -or $sp_messagereturn -eq ""))
            {
                $tableobj.HasError=$false
                $tableobj.errortype="INFO";
                $message="Command(s) completed successfully."
            }
            else
            {
                $tableobj.HasError=$true
                $tableobj.errortype="ERROR";
                $message=$sp_messagereturn
            }
            $tableobj.message=$message
        } 
        catch [System.Data.SqlClient.SqlException] 
        { 
           $tableobj.HasError=$true
           $tableobj.Query=$cmdText
           $tableobj.errortype="ERROR";
           $tableobj.message=$_.Exception.Message.ToString()
           if($_.Exception.Number -eq -2)
           {   
                $tableobj.errortype="Query Timeout"
           }
           RollbackOrCommitTransaction -Command $Command -onErrorAction $onErrorAction
        }
        finally
        {
            closeConnectionString -Connection $Connection -Command $Command
        }
    return  $tableobj
} 

function TsqlFormatter([string]$Source, [string]$Target)
{

    if (($Source -eq "") -or ($Target -eq ""))
    {
	    Write-Error "Please specify both source and target file paths"
	    Exit
    }

    $sqldom = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.TransactSql.ScriptDom")

    [Microsoft.SqlServer.TransactSql.ScriptDom.TSql110Parser] $parser = new-object Microsoft.SqlServer.TransactSql.ScriptDom.TSql110Parser($false)
    if ($parser -eq $null)
    {
	    Write-Error "Please install the SQLDOM.MSI from the SQL 2012 Feature Pack web page http://www.microsoft.com/en-us/download/details.aspx?id=35580"
	    Exit
    }

    [System.IO.TextReader] $scriptrdr = New-Object System.IO.StreamReader($Source)

    $errors = $null
    $tsqlfrag = $parser.Parse($scriptrdr, [ref]$errors)
    $scriptrdr.Dispose()

    [Microsoft.SqlServer.TransactSql.ScriptDom.Sql110ScriptGenerator] $scriptgen = New-Object Microsoft.SqlServer.TransactSql.ScriptDom.Sql110ScriptGenerator
    [string]$finalscript = $null
    $scriptgen.GenerateScript($tsqlfrag, [ref]$finalscript)

    [System.IO.TextWriter] $scriptWriter = New-Object System.IO.StreamWriter($Target)
    $scriptWriter.Write($finalscript)
    $scriptWriter.Flush()
    $scriptWriter.Dispose()

}

function limitrowsCount ($limitdata,$cmdText)
{
    if($limitdata -ne 0)
    {
        $cmdText=$cmdText.Trim() -Replace("select  top","select top")
        $cmdText=$cmdText.Trim() -Replace("select top","select top")
        $cmdText=$cmdText.Trim() -Replace("select   top","select top")
        $cmdText=$cmdText.Trim() -Replace("select top","!TOBEREPLACED!")
        $cmdText=$cmdText.Trim() -Replace("select ","select top $limitdata")
        $cmdText=$cmdText.Trim() -Replace("!TOBEREPLACED!","select top")
    }

    return $cmdText
}


function formatted-query([string]$InputFile,[string]$cmdText=$null,$sqlvariables,$sqlvarstypes,[bool]$formatsql=$true)
{
    if ($InputFile)
    { 
       if($formatsql)
       {
          TsqlFormatter $InputFile $InputFile
       }
       $filePath = $(resolve-path $InputFile.trim()).path
       [string]$cmdText =  [System.IO.File]::ReadAllText("$filePath")
       $cmdText=limitrowsCount -limitdata $limitdata -cmdText $cmdText
    }

    $cmdText=replaceRuntimeVars -cmdText $cmdText -sqlvariables $sqlvariables -sqlvarstypes $sqlvarstypes 
    return $cmdText
}


function replaceRuntimeVars([string]$cmdText, [object]$sqlvariables, [object]$sqlvarstypes)
{
    if($sqlvariables)
    {
            $commas=","
            $replacewith="','"

            foreach($sqlvariable in $sqlvariables.keys)
            {
                 $varobjects= $sqlvarstypes | where-object {$_.varname -eq $sqlvariable -or $_.name -eq $sqlvariable}
                 $vartype=$varobjects.variabletype
                 if($vartype -eq $null)
                 {
                    $vartype=$sqlvarstypes.$sqlvariable
                 }

                $dbvariable="!" + "DBVARIABLE_$sqlvariable" + "!"
                $colvariable="!" + "COLVARIABLE_$sqlvariable" + "!"

                [string]$varvalue=$sqlvariables[$sqlvariable]

                $colvalue=$sqlvariable

                if($varvalue -is [array])
                {
                    $varvalue=array2String($varvalue)
                }


                if($vartype -eq "stringin")
                {
                    if($sqlvariable -eq "procedurename")
                    {
                        if($varvalue -ne $null -and $varvalue -ne "")
                        {
                            $db=$sqlvariables["database"]
                            $varvaluearr= $varvalue -split(",")
                            $newvarvalue=""
                            foreach($v in $varvaluearr)
                            {
                                $v=$v.trim()
                                $newvarvalue +="$v,"
                            }
                            $varvalue=$newvarvalue.Substring(0,$newvarvalue.Length-1)
                        }
                    }

                    if($varvalue -ne $null -and $varvalue -ne "")
                    {    
                        $varvalue = "'" + $varvalue.Replace($commas,$replacewith) + "'"
                        $varvalue="and $sqlvariable in ($varvalue)"
                    }
                    else
                    {
                        #find column value
                        $ascolvalArr=$sqlvariable -split('as ')
                        $ascolval=$ascolvalArr[1]
                        if($ascolval -ne $null)
                        {
                            $ascolval=$ascolval.trim()
                        }
                        else
                        {
                            $ascolvalArr=$sqlvariable -split('\.')
                            $ascolval=$ascolvalArr[1]
                            if($ascolval -ne $null)
                            {
                                $ascolval=$ascolval.trim()
                            }
                        }
                        $colvalue="'' as $ascolval"
                    }
                }
                elseif($vartype -eq "stringnotnull")
                {
                    if($varvalue -ne $null -and $varvalue -ne '')
                    {
                        $varvalue="and $sqlvariable ='$varvalue'"
                    }
                    else
                    {
                        
                        $ascolvalArr=$sqlvariable -split('as ')
                        $ascolval=$ascolvalArr[1]
                        if($ascolval -ne $null)
                        {
                            $ascolval=$ascolval.trim()
                        }
                        else
                        {
                            $ascolvalArr=$sqlvariable -split('\.')
                            $ascolval=$ascolvalArr[1]
                            if($ascolval -ne $null)
                            {
                                $ascolval=$ascolval.trim()
                            }
                        }
                        $colvalue="'' as $ascolval"
                    }
                }
                elseif($vartype -eq 'int')
                {
                    if($varvalue.ToString() -eq [String]::Empty)
                    {
                        $varvalue="9999999999"
                    }
                }
                else
                {
                    if($vartype -ne 'int')
                    {
                        $varvalue = "'" + $varvalue.Replace($commas,$replacewith) + "'"
                    }

                    #$cmdText=$cmdText -replace("$dbvariable",$varvalue)
                }


                $cmdText=$cmdText -replace(([Regex]::Escape($dbvariable)),$varvalue)
                $cmdText=$cmdText -replace("$colvariable","$colvalue")
                
            }
    }

    return $cmdText;
}

function array2String($array,$delimeter=",")
{
    $strval=""
    foreach($item in $array)
    {
        if($strval -eq "")
        {
            $strval=$item
        }
        else
        {
            $strval=$strval + "$delimeter" + $item
        }
    }
    return $strval
}


Function findInputQueries([object]$sqlinput,[object]$logging,[object]$worklogging,[string]$inputfolder)
{
    $inputmethod=$sqlinput.method
    if( $inputmethod -eq "table")
    {
        If(!(test-path $inputfolder))
        {
              New-Item -ItemType Directory -Force -Path $inputfolder | out-null
        }

        $tables=$worklogging.tables.table
        $executiontab=$tables | Where-Object{$_.tablename -eq "reports"}
        $selectsql=($executiontab).selectsql2
        
        $ToolDir=Get-Location -PSProvider FileSystem   
        $selectsql=Join-Path -path $ToolDir -childPath "\inputs\sqls\$selectsql"

        $logToTable=$logging.logToTable
        $database=$logToTable.database
        $instance=$logToTable.instance

        $objs = invoke-SqlReader -instance $instance -dbhandler $database -InputFile $selectsql -formatsql $false -queryTimeout 0 -onErrorAction None
        foreach($obj in $objs)
        {
            $filename=$obj.filename
            $sqltempdir=Join-Path -path $inputfolder -childPath "$filename"
            $sqlval=$obj.query
            ac $sqltempdir $sqlval -Encoding UTF8 | out-null
        }

    }
    else
    {
        $inputfolder=$sqlinput.folder
    }
    $IncludeExt=@("*.sql")
    $objs = Get-Childitem $inputfolder -Recurse -Include "$IncludeExt"
    
    $objsps = [PSCustomObject]@{    
      files = $objs
      inputfolder=$inputfolder
    }
    
    return $objsps
}

function update-ExecutionTable([object]$logging,[object]$worklogging,[string]$xmlfile,[int]$executionid,[string]$format)
{
    $logtotable=$logging.logToTable
    $islog=$logtotable.islog
    $instance=$logtotable.instance
    $dbhandler=$logtotable.database
    $username=$null
    $password=$null
    $connectionTimeout=0

    if($dbhandler -eq $null -or $dbhandler -eq "")
    {
        $dbhandler="master"
    }

    if($username) 
    { $dbConnString = $ConnectionStringFormat1 -f $instance,$dbhandler,$username,$password,$connectionTimeout } 
    else 
    { $dbConnString = $ConnectionStringFormat2 -f $instance,$dbhandler,$connectionTimeout }
     
    if($islog -eq 'true' -or $islog -eq '1' -or $islog -eq 'yes')
    {
         [xml]$xmlNode=Get-content $xmlfile
         $logprocessNode=$xmlNode.tfl.logprocess.file

         $tables=$worklogging.tables.table
         $executiontab=$tables | Where-Object{$_.tablename -eq "execution"}
         $tablename=($executiontab).tablename
         $schemaname=($executiontab).schemaname
         $updatesql=($executiontab).updatesql
         $ToolDir=Get-Location -PSProvider FileSystem   
         $updatesql=Join-Path -path $ToolDir -childPath "\inputs\sqls\$updatesql"

         $fileNode=$logprocessNode | Where-Object{$_.position -eq "end" -and $_.iserror -eq "1"}
         if($fileNode -ne $null)
         {
              $iserror=1
         }
         else
         {
             $iserror=0;
         }
         [string]$finisheddate=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

         $sqlvariables = @{executionid=$executionid;iserror=$iserror;finisheddate=$finisheddate}
         $sqlvarstypes= @{executionid='Int';iserror='Int';finisheddate='string';}
         
         $objs=invoke-SqlNonQuery -instance $instance -InputFile $updatesql -dbhandler $dbhandler -sqlvariables $sqlvariables -sqlvarstypes $sqlvarstypes
         if($objs.HasError)
         {
             Log-Error -ErrorObj $objs -format $format -logging $logging
         }
         else
         {
             if($objs.errortype -ne "NOLOGGING")
             {
                  $insertedID=$objs.insertedID
                  Log-Write -LineValue "Execution table updated with final result" -format $format -logging $logging -noxml $true
             }       
         }


    }
}

function insert-ResultsTable([object]$logging,[object]$worklogging,[string]$xmlfile,[int]$executionid,[string]$format)
{
    $logtotable=$logging.logToTable
    $islog=$logtotable.islog
    $instance=$logtotable.instance
    $dbhandler=$logtotable.database

    if($dbhandler -eq $null -or $dbhandler -eq "")
    {
        $dbhandler="master"
    }

    if($islog -eq 'true' -or $islog -eq '1' -or $islog -eq 'yes')
    {
         [xml]$xmlNode=Get-content $xmlfile
         $logprocessNode=$xmlNode.tfl.logprocess.file

         $fileNode=$logprocessNode | Where-Object{$_.position -eq "start"}
         $fileNames=$fileNode.name
         $fileNames=$fileNames | sort-object –Unique
     
         $tables=$worklogging.tables.table
         $executiontab=$tables | Where-Object{$_.tablename -eq "reports"}
         $tablename=($executiontab).tablename
         $schemaname=($executiontab).schemaname
         $selectsql=($executiontab).selectsql

         $resulttab=$tables | Where-Object{$_.tablename -eq "results"}
         $resultTablename=($resulttab).tablename
         $resultSchemaname=($resulttab).schemaname
         $resultInsertsql=($resulttab).insertsql

         $ToolDir=Get-Location -PSProvider FileSystem   
         $selectsql=Join-Path -path $ToolDir -childPath "\inputs\sqls\$selectsql"
         $resultInsertsql=Join-Path -path $ToolDir -childPath "\inputs\sqls\$resultInsertsql"
                
         foreach($filename in $filenames)
         {
             $filename=$filename.trim()
             $sqlvariables = @{filename=$filename}
             $sqlvarstypes= @{filename='varchar|100'}

             try 
             {
                     $objs=$null
                     $objs=invoke-SqlReader2 -instance $instance -dbhandler $dbhandler -InputFile $selectsql -sqlvariables $sqlvariables -sqlvarstypes $sqlvarstypes -queryTimeout $queryTimeout -onErrorAction None
                     if($objs.HasError -ne $true)
                     {
                            $reportid=$objs.ID
                            $fileErrorNode=$logprocessNode | Where-Object{$_.name -eq "$filename"}
                            $iserrorNodeExist=$fileErrorNode | Where-Object{$_.iserror -eq "1" -and $_.position -eq "err-error"}
                            if($iserrorNodeExist -ne $null)
                            {
                                 $iserror=1
                                 $errormessage=$iserrorNodeExist.message
                                 $errormessage=$errormessage -replace('&quot;','"')
                                 $errormessage=$errormessage -replace("&apos;","''")
                                 $errormessage=$errormessage -replace('&lt;','<')
                                 $errormessage=$errormessage -replace('&gt;','>')
                                 $errormessage=$errormessage -replace('&amp;','&')
                            }
                            else
                            {
                                 $iserror=0;
                                 $errormessage="";
                            }

                            $executionEndNode=$fileErrorNode | Where-Object{$_.position -eq "end"}
                            $createddate=$executionEndNode.date
                            $executionEndNode.iserror="$iserror"
                            $xmlNode.save($xmlfile)

                            $sqlvariables = @{executionid=$executionid;reportid=$reportid;iserror=$iserror;errormessage=$errormessage;createddate=$createddate}
                            $sqlvarstypes= @{executionid='Int';reportid='Int';iserror='Int';errormessage='string';createddate='string';}

                            $objs=invoke-SqlNonQuery -instance $instance -InputFile $resultInsertsql -dbhandler $dbhandler -sqlvariables $sqlvariables -sqlvarstypes $sqlvarstypes
                            if($objs.HasError)
                            {
                                Log-Error -ErrorObj $objs -format $format -logging $logging
                            }
                            else
                            {
                                 if($objs.errortype -ne "NOLOGGING")
                                 {
                                      #Log-Write -LineValue "Record inserted in table results" -format $format -logging $logging -noxml $true
                                 }       
                            }

                     }
                     else
                     {
                          $iserror=$true
                          Log-Error -logstage "file" -logstepname "$filename" -ErrorObj $objs -ExitGracefully $false -format "$format" -logging $logging
                     } 
                 
              } 
              catch [Exception]
              {
                   $objerror=$_ 
                   $iserror=$true
                   Log-Error -logstage "file" -logstepname "$filename" -ErrorObj $objerror -ExitGracefully $false -format "$format" -logging $logging
              }  
        }
    }
}


function YYYYMMDD2DDMMYYY([string]$yyyymmdd)
{
    $yyyymmddarr=$yyyymmdd -split(' ')
    $datestr=$yyyymmddarr[0]
    $timestr=$yyyymmddarr[1]

    $datestr=$datestr -split('-')
    $yyyy=$datestr[0]
    $mm=$datestr[1]
    $dd=$datestr[2]

    return "$dd-$mm-$yyyy $timestr"
}
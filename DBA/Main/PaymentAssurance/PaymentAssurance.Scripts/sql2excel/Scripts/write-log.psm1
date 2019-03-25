$beganEventId = 13011
$successEventId = 13012
$failedEventId = 13013
[string]$ConnectionStringFormat1 = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}" 
[string]$ConnectionStringFormat2="Server={0};Database={1};Integrated Security=SSPI;Connect Timeout={2}"

Function Log-Start
{
    
  [CmdletBinding()]
  
  Param ([Parameter(Mandatory=$true)][string]$ScriptVersion, [string]$format, [object]$logging,[object]$sqlinput,[object]$worklogging)
  

    
   $debugmode=$logging.debugmode
   $logToHTML=$logging.logToHTML
   [string]$logfilename=Join-Path -path $logging.logfolder -childPath $logging.logfilename

    #Check if file exists and delete if it does
    If((Test-Path -Path $logfilename))
    {
      Remove-Item -Path $logfilename -Force
    }   

    Add-Content -Path $logfilename -Value "***************************************************************************************************"
    Log-XML -logfilename $logfilename -logstage init -islog $logToHTML

    [string]$messageprocessing="$format- Started processing $format at [$([DateTime]::Now)]."
    Add-Content -Path $logfilename -Value "$messageprocessing"
    Log-Event -message $messageprocessing -eventId $beganEventId -entryType "Information" -eventLogSource $format -logging $logging

    Add-Content -Path $logfilename -Value "***************************************************************************************************"
    
    Add-Content -Path $logfilename -Value ""
    
    [string]$messagerunning="$format- Running script version [$ScriptVersion]."
    Add-Content -Path $logfilename -Value "$messagerunning"
    Log-Event -message $messagerunning -eventId $successEventId -entryType "Information" -eventLogSource $format -logging $logging
    Add-Content -Path $logfilename -Value ""    
    Add-Content -Path $logfilename -Value "***************************************************************************************************"
    
    Log-XML -logfilename $logfilename -logstage start -message "$messageprocessing $messagerunning" -islog $logToHTML
    create-logtable -worklogging $worklogging -format $format -logging $logging -logtable "execution"
    $runno=start-execution -logging $logging -worklogging $worklogging -format $format 
    if($debugmode -eq 'true' -or $debugmode -eq '1' -or $debugmode -eq 'yes')
    {
        #Write to screen for debug mode
        Write-Host "***************************************************************************************************"
        Write-Host "$messageprocessing"
        Write-Host "***************************************************************************************************"
        Write-Host ""
        Write-Host "$messagerunning"
        Write-Host ""
        Write-Host "***************************************************************************************************"
        Write-Host ""
    }

  return $runno
}


Function Log-Write
{

  [CmdletBinding()]
  
  Param ([Parameter(Mandatory=$true)][string]$LineValue, [string]$position='start',[string]$format, 
         [object]$logging,[string]$logstepname=$null,[string]$logstage='file',[bool]$noxml=$false,[string]$ElapsedTime="")
  
  Process{

    $debugmode=$logging.debugmode
    $logToHTML=$logging.logToHTML
	[string]$logfilename=Join-Path -path $logging.logfolder -childPath $logging.logfilename
	
    [string]$timenow=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $messagetype="INFO"
    $preblankspace="     "
    $postblankspace="      "
    $message="$timenow$preblankspace$messagetype$postblankspace$LineValue"

    Add-Content -Path $logfilename -Value $message
    Log-Event -message $LineValue -eventId $successEventId -entryType "Information" -eventLogSource $format -logging $logging
    if($noxml -eq $false)
    {
        Log-xml -logfilename $logfilename -logstage $logstage -message $LineValue -logstepname $logstepname -position $position -ElapsedTime "$ElapsedTime" -islog $logToHTML
    }
    if($position -eq 'end')
    {
        Add-Content -Path $logfilename -Value ""
    }

    if($debugmode -eq 'true' -or $debugmode -eq '1' -or $debugmode -eq 'yes')
    {
        Write-Host $LineValue
    }

  }
}

Function Log-Error
{
  
  [CmdletBinding()]
  
  Param ([string]$ErrorMessage=$null, [object]$ErrorObj=$null,
         [boolean]$ExitGracefully=$false, [string]$format, [object]$logging,[string]$logstepname=$null, 
         [string]$logstage='file',[bool]$noxml=$false,[bool]$noTableLogging=$false) 
  
  Process{
    
    $debugmode=$logging.debugmode
    $logToHTML=$logging.logToHTML
    [string]$logfilename=Join-Path -path $logging.logfolder -childPath $logging.logfilename

    [string]$timenow=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    
    $messagetype="ERROR"
    $blankspace="     "

    if($ErrorMessage -ne $null -and $ErrorMessage -ne "") 
    {
        $errormsg="$timenow$blankspace$messagetype$blankspace$ErrorMessage"
        Add-Content -Path $logfilename -Value $errormsg
        Log-Event -message $ErrorMessage -eventId $failedEventId -entryType "ERROR" -eventLogSource $format -logging $logging 
        if($noxml -eq $false)
        {
            Log-xml -logfilename $logfilename -logstage $logstage -message $ErrorMessage -logstepname $logstepname -iserror '1' -islog $logToHTML -position "err-manual"
        }
        if($debugmode -eq 'true' -or $debugmode -eq '1' -or $debugmode -eq 'yes')
        {
           Write-Host "Error: $ErrorMessage."
        }
    }

    if($ErrorObj -ne $null)
    {
        $errormsg=$ErrorObj.message;
        if($errormsg -ne $null)
        {
            $ErrorDesc="$timenow$blankspace$messagetype$blankspace$errormsg"
            Add-Content -Path $logfilename -Value $ErrorDesc
            Log-Event -message $ErrorDesc -eventId $failedEventId -entryType "ERROR" -eventLogSource $format -logging $logging
            if($noxml -eq $false)
            {
                Log-xml -logfilename $logfilename -logstage $logstage -message $errormsg -logstepname $logstepname -iserror '1' -islog $logToHTML -position "err-error"
            }
            if($debugmode -eq 'true' -or $debugmode -eq '1' -or $debugmode -eq 'yes')
            {
                Write-Host "Error: $errormsg."
            }
        }

        $query=$ErrorObj.query;
        if($query -ne $null)
        {
            $ErrorDesc="$timenow$blankspace$messagetype$blankspace$query"
            Add-Content -Path $logfilename -Value $ErrorDesc
            $eventmessage="Error occured while running query: $query"
            #Log-Event -message $eventmessage -eventId $failedEventId -entryType "ERROR" -eventLogSource $format -logging $logging
            if($noxml -eq $false)
            {
                Log-xml -logfilename $logfilename -logstage $logstage -message $eventmessage -logstepname $logstepname -iserror '1' -islog $logToHTML -position "err-query"
            }
            if($debugmode -eq 'true' -or $debugmode -eq '1' -or $debugmode -eq 'yes')
            {
                Write-Host "Error: An error has occurred. Query: [$query]."
            }
        }

        $errorexception=$ErrorObj.Exception;
        if($errorexception -ne $null)
        {
            $errormsg=$errorexception.message.tostring();
            $exceptionerror="$timenow$blankspace$messagetype$blankspace$errormsg"
            Add-Content -Path $logfilename -Value $exceptionerror
            Log-Event -message $errormsg -eventId $failedEventId -entryType "ERROR" -eventLogSource $format -logging $logging
            if($noxml -eq $false)
            {
                Log-xml -logfilename $logfilename -logstage $logstage -message $errormsg -logstepname $logstepname -iserror '1' -islog $logToHTML -position "err-exception"
            }
            if($debugmode -eq 'true' -or $debugmode -eq '1' -or $debugmode -eq 'yes')
            {
                Write-Host "Error: $errormsg."
            }
        }
       
        
    }
    

    #If $ExitGracefully = True then run Log-Finish and exit script
    If ($ExitGracefully -eq $True)
    {
      Log-Finish -format $format -logging $logging
      Break
    }
  }
}

function create-logtable([object]$worklogging,[string]$format, [object]$logging,[string]$logtable)
{
    $logtotable=$logging.logToTable
    $islog=$logtotable.islog
    $instance=$logtotable.instance
    $database=$logtotable.database
    
    $tables=$worklogging.tables.table
    $executiontab=$tables | Where-Object{$_.tablename -eq "$logtable"}
    $tablename=($executiontab).tablename
    $schema=($executiontab).schemaname
    $createtablesql=($executiontab).createsql
    

    if($islog -eq 'true' -or $islog -eq '1' -or $islog -eq 'yes')
    {
        $istablecreated=createLogTable -instance $instance -database $database -tablename $tablename -schema $schema -tablescript $createtablesql -format $format -logging $logging 
    }
}

function start-execution([object]$logging,[object]$worklogging,[string]$format)
{
    [string]$logfilename=Join-Path -path $logging.logfolder -childPath $logging.logfilename
	$logtotable=$logging.logToTable
    $islog=$logtotable.islog
    $instance=$logtotable.instance
    $database=$logtotable.database
    
    $tables=$worklogging.tables.table
    $executiontab=$tables | Where-Object{$_.tablename -eq "execution"}
    $tablename=($executiontab).tablename
    $schema=($executiontab).schemaname
    $inserttablesql=($executiontab).insertsql

    [string]$starteddate=(Get-Date).ToString('dd/MM/yyyy HH:mm:ss')
    $sqlvariables = @{starteddate=$starteddate;}
    $sqlvarstypes= @{starteddate='DateTime2';}

    $ToolDir=Get-Location -PSProvider FileSystem   
    $insertscript=Join-Path -path $ToolDir -childPath "\inputs\sqls\$inserttablesql"
    $insertedID=$null;
    if($islog -eq 'true' -or $islog -eq '1' -or $islog -eq 'yes')
    {
        $objs=invoke-SqlNonQuery2 -instance $instance -InputFile $insertscript -dbhandler $database -sqlvariables $sqlvariables -sqlvarstypes $sqlvarstypes
        if($objs.HasError)
        {
            Log-Error -ErrorObj $objs -format $format -logging $logging
        }
        else
        {
             if($objs.errortype -ne "NOLOGGING")
             {
                $insertedID=$objs.insertedID
                Log-Write -LineValue "Runno $insertedID created in table execution" -format $format -logging $logging -noxml $true
             }       
        }
    }
    return $insertedID;
}





function createLogTable([string]$instance, [string]$database, [string]$tablename, [string]$schema,[string]$tablescript,[string]$format, [object]$logging, [string]$logstepname=$null)
{
    $sqlvariables = @{tablename=$tablename;schemaname=$schema;}
    $sqlvarstypes= @{tablename='string';schemaname='string';}
    $ToolDir=Get-Location -PSProvider FileSystem   
    $tablescript=Join-Path -path $ToolDir -childPath "\inputs\sqls\$tablescript"
    $objs=invoke-SqlNonQuery -instance $instance -InputFile $tablescript -dbhandler $database -sqlvariables $sqlvariables -sqlvarstypes $sqlvarstypes
    if($objs.HasError)
    {
        Log-Error -ErrorObj $objs -format $format -logging $logging -noTableLogging $true
        return $false
    }
    else
    {
         if($objs.errortype -ne "NOLOGGING")
         {
            Log-Write -logstepname $logstepname -LineValue "Table $tablename created for logging" -format $format -logging $logging -noxml $true
         }       
         return $true
    }
}


Function Log-Event([string]$message, [int]$eventId, [string]$entryType = "Information",[string]$eventLogSource, [object]$logging)
{	
    $logtoevent=$logging.logToEvent
    #$entryType: The acceptable values for this parameter are: Error, Warning, Information, SuccessAudit, and FailureAudit. The default value is Information.
	if($logtoevent -eq 'true' -or $logtoevent -eq '1' -or $logtoevent -eq 'yes')
    {
        if ([System.Diagnostics.EventLog]::SourceExists($eventLogSource) -eq $false)
        {
            New-EventLog -LogName "Application" -Source "$eventLogSource"
        }
	    Write-EventLog -Message $message -EntryType $entryType -EventId $eventId -LogName "Application" -Source "$eventLogSource" -Category 0
    }
}

Function Log-XML
{
    param([ValidateSet("init","start","log","file","processemail","end","close")][string]$logstage,[string]$logfilename,
    [string]$logstepname="",[string]$message="", [string]$iserror='0',[string]$position='start',[string]$islog,[string]$ElapsedTime="")
    
    $message=$message -replace('"','&quot;')
    $message=$message -replace("'","&apos;")
    $message=$message -replace('<','&lt;')
    $message=$message -replace('>','&gt;')
    $message=$message -replace('&','&amp;')

    $logstepname=$logstepname -replace('\\','_')
    $xmlfile=FindXMLFilename -logfilename $logfilename
    
    
    if($islog -eq 'true' -or $islog -eq '1' -or $islog -eq 'yes')
    {
        [string]$todaydate=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    
        if($logstage -eq "init")
        {
           if((Test-Path -Path $xmlfile))
           {
              Remove-Item -Path $xmlfile -Force
           }
           ac $xmlfile "<?xml version=""1.0""?>"
           ac $xmlfile "<tfl>"
        }

        if($logstage -eq "start")
        {
            ac $xmlfile "<logstart date=""$todaydate"" message=""$message"" iserror=""$iserror""/>"
            ac $xmlfile "<logprocess>"
        }
        elseif($logstage -eq "processemail")
        {
            ac $xmlfile "<processemail message=""$message"" iserror=""$iserror"" date=""$todaydate""/>"
        }
        elseif($logstage -eq "end")
        {
            ac $xmlfile "</logprocess>"
            ac $xmlfile "<logend date=""$todaydate"" message=""$message"" iserror=""$iserror""/>"
        }
        elseif($logstage -eq "close")
        {
            ac $xmlfile "</tfl>"
        }
        else
        {
            if($logstage -ne "init")
            {
                ac $xmlfile "<$logstage name=""$logstepname"" message=""$message"" iserror=""$iserror"" date=""$todaydate"" position=""$position"" ElapsedTime=""$ElapsedTime""/>"
            }
        }

        
    }
}

Function Log-Email
{
  
  [CmdletBinding()]
  
  Param ($iserror=$false, [string]$format,[object]$logging,[bool]$attachimage=$true) 
  
      [string]$logfilename=Join-Path -path $logging.logfolder -childPath $logging.logfilename
      if($iserror -eq $null)
      {
        $iserror=$false;
      }
      
      $logToHTML=$logging.logToHTML
      
      $sendmail=$logging.sendmail
      $islog=$sendmail.islog
      if($islog -eq 'true' -or $islog -eq '1' -or $islog -eq 'yes')
      {
        [bool]$isElailLog=$true
      }
      else
      {
        [bool]$isElailLog=$false
      }
      $EmailFrom=$sendmail.EmailFrom
	  $EmailTo=$sendmail.EmailTo
	  $EmailSubject=$sendmail.EmailSubject
	  $SmtpServer=$sendmail.smtpserver
	  $emailOnAction=$sendmail.emailOnAction
      
      
      if(($isElailLog -eq $true) -and (($emailOnAction -eq 'OnError' -and $iserror -eq $true)-or $emailOnAction -eq 'onSuccess'))
      {
          try
          {
              if($logToHTML -eq 'true' -or $logToHTML -eq '1' -or $logToHTML -eq 'yes')
              {
                $htmlfile=FindReportFilename -logging $logging
                if(Test-Path $htmlfile)
                {
                    $BodyAsHtml=$true
                    $sBody = (Get-Content $htmlfile | out-string)
                    $sBody=$sBody -replace('&quot;','"')
                    $sBody=$sBody -replace("&apos;","'")
                    $sBody=$sBody -replace('&lt;','<')
                    $sBody=$sBody -replace('&gt;','>')
                    $sBody=$sBody -replace('&amp;','&')

                }
                else
                {
                    $BodyAsHtml=$false
                    $sBody = (Get-Content $logfilename | out-string)
                }
              }
              else
              {
                $BodyAsHtml=$false
                $sBody = (Get-Content $logfilename | out-string)
              }

              if($iserror -eq $true)
              {
                $EmailSubject="$EmailSubject : Error Occured"
              }
              else
              {
                 $EmailSubject="$EmailSubject"
              }

               $ToolDir=Get-Location -PSProvider FileSystem  
               $attachmenton=Join-Path -path $ToolDir -childPath "\inputs\images\on.jpg"
               $attachmentoff=Join-Path -path $ToolDir -childPath "\inputs\images\off.jpg"

               $attachmenton=Get-Item $attachmenton
               $attachmentoff=Get-Item $attachmentoff
               $Attachon = $attachmenton.FullName
               $Attachoff = $attachmentoff.FullName
              

              if($iserror -eq $true)
              {
                $attachments=$logfilename,$Attachon,$Attachoff
              }
              else
              {
                $attachments=$logfilename,$Attachon
              }

              if($BodyAsHtml -eq $true)
              {
                Send-MailMessage -From $EmailFrom -To $EmailTo -Bcc "TDDBAOPS@tfl.gov.uk" -Subject $EmailSubject -SmtpServer $SmtpServer -Body $sBody -Attachments $attachments  -BodyAsHtml
              }
              else
              {
                Send-MailMessage -From $EmailFrom -To $EmailTo -Bcc "TDDBAOPS@tfl.gov.uk" -Subject $EmailSubject -SmtpServer $SmtpServer -Body $sBody
              }      
              Log-Write -logstage "processemail" -LineValue "All Done. Confirmation email sent to $EmailTo" -format $format -logging $logging -noxml $true
          }
          catch [Exception] 
          { 
             $objerror=$_ 
             $ErrorMessage="Error occured while sending confirmation email."
             Log-Error -ErrorMessage "$ErrorMessage" -ErrorObj $objerror -ExitGracefully $True -format $format -logging $logging -logstage 'processemail' -noxml $true
          }
      }
}



Function Log-Finish
{
  
  [CmdletBinding()]
  
  Param ([Parameter(Mandatory=$false)][string]$NoExit,[string]$format,[object]$logging,[object]$worklogging)
  
    
  Process{
    
    $debugmode=$logging.debugmode
    $logToHTML=$logging.logToHTML
    [string]$logfilename=Join-Path -path $logging.logfolder -childPath $logging.logfilename

    [string]$messagefinish="$format- Finished processing $format at [$([DateTime]::Now)]."

    Add-Content -Path $logfilename -Value ""
    Add-Content -Path $logfilename -Value "***************************************************************************************************"
    Add-Content -Path $logfilename -Value "$messagefinish"
    Log-Event -message $messagefinish -eventId $successEventId -entryType "Information" -eventLogSource $format -logging $logging
    Add-Content -Path $logfilename -Value "***************************************************************************************************"
    
   if($debugmode -eq 'true' -or $debugmode -eq '1' -or $debugmode -eq 'yes')
   {
        Write-Host ""
        Write-Host "***************************************************************************************************"
        Write-Host "$format- Finished processing at [$([DateTime]::Now)]."
        Write-Host "***************************************************************************************************"
   }
    #Exit calling script if NoExit has not been specified or is set to False
    If(!($NoExit) -or ($NoExit -eq $False)){
      Exit
    }    
  }
}


function Log-FinishXml([object]$logging, [string]$logname)
{
    
    $logToHTML=$logging.logToHTML
    [string]$messagefinish="$logname- Finished processing at [$([DateTime]::Now)]."
    [string]$logfilename=Join-Path -path $logging.logfolder -childPath $logging.logfilename

    Log-XML -logfilename $logfilename -logstage end -message "$messagefinish" -islog $logToHTML
    Log-XML -logfilename $logfilename -logstage close -islog $logToHTML
}


function FindXMLFilename([string]$logfilename)
{
   $xmllogfilename=[System.IO.Path]::GetFileNameWithoutExtension($logfilename) + ".xml"
   $xmlfolder=Split-Path $logfilename
   $xmllogfilename=Join-Path -path $xmlfolder -childPath "$xmllogfilename"

   return $xmllogfilename
}

function FindReportFilename($isreportfile=$false,$reportdate="",[object]$logging)
{
   if($isreportfile -eq $false)
   {
        $htmlfile=[System.IO.Path]::GetFileNameWithoutExtension($logging.logfilename) + ".html"
   }
   else
   {
        $htmlfile=$logfilename + "_$reportdate.html"
   }
   $htmlfile=$htmlfile -replace(' ','_')
   
   $htmlfile=Join-Path -path $logging.reportfolder -childPath "$htmlfile"

   return $htmlfile
}

Function Log-Table
{
    param([object]$logging,[object]$worklogging,[string]$format,[int]$executionid,[string]$xmlfile)
      
     create-logtable -worklogging $worklogging -format $format -logging $logging -logtable "results"
     insert-ResultsTable -logging $logging -worklogging $worklogging -xmlfile $xmlfile -executionid $executionid -format $format 
     update-ExecutionTable -logging $logging -worklogging $worklogging -xmlfile $xmlfile -executionid $executionid -format $format       
}

function Log-Report($format,$logstage,[object]$logging,[object]$worklogging, [int]$executionid,[string]$outputfolder)
{
    
    [string]$logfilename=Join-Path -path $logging.logfolder -childPath $logging.logfilename

    if($format -eq "excel")
    {
        $format="SQL2EXCEL"
    }
    elseif($format -eq "csv")
    {
        $format="SQL2CSV"
    }

    $htmlfile=FindReportFilename -logging $logging
    $xmlfile=FindXMLFilename -logfilename $logfilename
    if(test-path $xmlfile)
    {
        #log entery in table
        Log-Table -logging $logging -worklogging $worklogging -format $format -executionid $executionid -xmlfile $xmlfile
        
        
        #create HTML Report
        [xml]$localconfig=Get-content $xmlfile
        
        $logstart=$localconfig.tfl.logstart
        $processlogs=$localconfig.tfl.logprocess."$logstage"
        $processemail=$localconfig.tfl.processfiles.processemail
        $logend=$localconfig.tfl.logend

        HtmlHeader -fileName $htmlfile -tableheader "$format Report" -outputfolder $outputfolder
        TableHeader -fileName $htmlfile
        #$previousbackcolor=TableBody -fileName $htmlfile -objs $logstart
        $previousbackcolor=TableBody -fileName $htmlfile -objs $processlogs -previousbackcolor $previousbackcolor
        #$previousbackcolor=TableBody -fileName $htmlfile -objs $processemail -previousbackcolor $previousbackcolor
        #$previousbackcolor=TableBody -fileName $htmlfile -objs $logend -previousbackcolor $previousbackcolor
        TableFooter -fileName $htmlfile
        HtmlFooter -fileName $htmlfile 

        Remove-Item $xmlfile -Force
    }
}

function log-purge([object]$logging,[string]$format)
{
    try
    {
        $keeplogdays=$logging.keeplogdays
        $keeplogdays=$keeplogdays.trim()
        $Nowdate = Get-Date
        $Lastwrite = $Nowdate.AddDays(-$keeplogdays)

        $ToolDir=Get-Location -PSProvider FileSystem   
    
        #delete log files
        $logdir=$logging.logfolder
        $logExtension=@("*.log","*.xml")
        $logFiles = get-childitem $logdir -Recurse -Include $logExtension | where {$_.LastwriteTime -le "$Lastwrite"}

        foreach ($File in $logFiles)
        {
            if ($File -ne $Null)
            {
                Remove-item $File.Fullname -Force| out-null
            }
        }

        #delete html files
        $reportdir=$logging.reportfolder
        $reportExtension=@("*.html","*.htm")
        $reportFiles = Get-childitem $reportdir -Include $reportExtension -Recurse | where {$_.LastwriteTime -le "$Lastwrite"}
        foreach ($File in $reportFiles)
        {
            if ($File -ne $Null)
            {
                Remove-item $File.Fullname -Force | out-null
            }
        }

        #delete Temp files
        $tempdir=Join-Path -path $ToolDir -childPath "\Temp"
        $tempExtension = "*.*"
        $tempFiles = Get-childitem $tempdir -Include $tempExtension -Recurse | where {$_.LastwriteTime -le "$Lastwrite"}
        foreach ($File in $tempFiles)
        {
            if ($File -ne $Null)
            {
                Remove-item $File.Fullname -Force | out-null
            }
        }
        return 0
    }
    catch [Exception] 
    { 
            $objerror=$_ 
            $errormsg=$objerror.Exception.Message
            $EmailFrom=$logging.sendmail.EmailFrom
            $EmailTo=$logging.sendmail.EmailTo
            $EmailSubject="SQL2Excel: Unhandled error occured during log purge"
            $SmtpServer=$logging.sendmail.smtpserver
            Log-Error -ErrorMessage "$EmailSubject" -ErrorObj $objerror -ExitGracefully $false -format $format -logging $logging -noxml $true
            Send-MailMessage -From $EmailFrom -To $EmailTo -Subject $EmailSubject -SmtpServer $SmtpServer -Body $errormsg
            return 1
    }
}
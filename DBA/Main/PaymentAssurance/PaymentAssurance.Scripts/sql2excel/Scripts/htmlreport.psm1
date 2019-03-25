Function HtmlHeader
{ 
param($fileName, $tableheader,[string]$outputfolder) 

$date = ( get-date ).ToString('dd/MM/yyyy') 

Add-Content $fileName "<html>" 
Add-Content $fileName "<head>" 
Add-Content $fileName "<meta charset='utf-8'>"
Add-Content $fileName "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>" 
Add-Content $fileName "<title>$tableheader</title>" 
add-content $fileName "<style>
#maintable {
    font-family: 'Trebuchet MS', Arial, Helvetica, sans-serif;
    border-collapse: collapse;
    width: 100%;
}

#maintable td, #maintable th {
    border: 1px solid #ddd;
    padding: 8px;
}

#maintable th {
    padding-top: 12px;
    padding-bottom: 12px;
    text-align: left;
    background-color: #1C6EA4;
    color: white;
}

</style>"
add-content $fileName  "<script>"
$javajquery=get-content ("inputs/js/jquery.min.txt")
$javaminimizetext=get-content ("inputs/js/minimizetext.txt")
add-content $fileName $javajquery
add-content $fileName  ""
add-content $fileName $javaminimizetext
Add-Content $fileName "</script>"
#Add-Content $fileName "<link rel='stylesheet' href='../inputs/css/highlight.css'>"
#Add-Content $fileName "<script src='../inputs/js/highlight.js'></script>"
#Add-Content $fileName "<script>hljs.initHighlightingOnLoad();</script>"
Add-Content $fileName "</head>"
Add-Content $fileName "<body>"
Add-Content $fileName "<div class='beforeAfter'>"
add-content $fileName  "<table width='100%' border=0 cellpadding=0 cellspacing=0><tr><td width='100%'>"
add-content $fileName  "<table width='100%' border=0 cellpadding=0 cellspacing=0>" 
add-content $fileName  "<tr>" 
add-content $fileName  "<td>" 

$outputfolderwithprefix="file:///$outputfolder"


add-content $fileName  "<font face='tahoma' size='3'><b>Output folder: <font color=blue><u><a href=""$outputfolderwithprefix"">$outputfolder</a></u></font></b></font><br><br>" 
add-content $fileName  "</td>" 
add-content $fileName  "</tr>" 
add-content $fileName  "<tr bgcolor='#5F9EA0' height='25'>" 
add-content $fileName  "<td>" 
add-content $fileName  "<font face='tahoma' color='#000000' size='5'><center><strong>$tableheader - $date</strong></center></font>" 
add-content $fileName  "</td>" 
add-content $fileName  "</tr>" 
add-content $fileName  "</table>" 
add-content $fileName  "</td></tr>"
}

Function TableHeader
{
    param($fileName) 
    add-content $fileName  "<tr><td>"
    Add-Content $fileName "<table id='maintable' width='100%'>"
    Add-Content $fileName "<thead>"
    Add-Content $fileName "<tr bgcolor=#5F9EA0>" 
    Add-Content $fileName "<th width='10%' style='text-align: center;'>Time</th>" 
    Add-Content $fileName "<th width='10%' style='text-align: center;'>File</th>"
    Add-Content $fileName "<th width='10%' style='text-align: center;' nowrap>Elapsed Time</th>"
    Add-Content $fileName "<th width='60%'>Message</th>" 
    Add-Content $fileName "<th width='10%' style='text-align: center;'>Status</th>"
    Add-Content $fileName "</tr>"
    Add-Content $fileName "</thead>"
    Add-Content $fileName "<tbody id='myTable'>"
}

Function TableBody
{
    param($fileName,$objs,$previousbackcolor=$null) 

    
    $endedObjs=$objs | Where-Object{$_.position -eq "end"}

    if($previousbackcolor -eq "white")
    {
        $i=1
    }
    else
    {
        $i=0
    }

    foreach($obj in $endedObjs)
    {
        If([bool]!($i%2))
        {
            $backcolor="white"
        }
        else
        {
            $backcolor="aliceblue"
        }

        $date=$obj.date
        $date=YYYYMMDD2DDMMYYY -yyyymmdd $date
        $file=$obj.name
        $message=$obj.message
        $iserror=$obj.iserror
        $ElapsedTime=$obj.ElapsedTime

        $message=$message -replace('&quot;','"')
        $message=$message -replace("&apos;","'")
        $message=$message -replace('&lt;','<')
        $message=$message -replace('&gt;','>')
        $message=$message -replace('&amp;','&')

        if($iserror -eq '1')
        {
            $img="off"
            $errorObjs=$objs | Where-Object{$_.name -eq "$file" -and $_.position -eq "err-error"}
            $message=$errorObjs.message
        }
        else
        {
            $img="on"

        }

        Add-Content $fileName "<tr bgcolor='$backcolor'>" 
        Add-Content $fileName "<td nowrap>$date</td>" 
        Add-Content $fileName "<td nowrap style='text-align: center;'>$file</td>"
        Add-Content $fileName "<td nowrap style='text-align: center;'>$ElapsedTime mins</td>"  
        Add-Content $fileName "<td><p class='minimize' align='left'>$message</p></td>" 

        $ToolDir=Get-Location -PSProvider FileSystem
        $attachment=Join-Path -path $ToolDir -childPath "\inputs\images\$img.jpg"
        $attachment=Get-Item $attachment
        $statustd="<td align='center' valign='middle'><img src='{0}'></td>" -f ($attachment.Name)
        Add-Content $fileName  $statustd
        Add-Content $fileName "</tr>" 

      $i++
    }

    return $backcolor
}

Function TableFooter 
{ 
param($fileName) 
Add-Content $fileName "</tbody>"
Add-Content $fileName "</table>"
add-content $fileName  "</td></tr></table>"
Add-Content $fileName "<br>"

} 


Function HtmlFooter 
{ 
param($fileName) 

    $footer=("<br><I>Report run {0} by {1}\{2}<I>" -f (Get-Date -displayhint date),$env:userdomain,$env:username) 
    Add-Content $fileName "$footer"
    Add-Content $fileName "</body>" 
    Add-Content $fileName "</html>" 
}



#open an URL in Internet explorer
function openReportInIE([string]$filename)
{
  try
  {
    Start-Process "chrome.exe" "$filename"
  }
  catch [Exception]
  {
    $ie = new-object -comobject InternetExplorer.Application 
    $ie.navigate($filename) 
    $ie.visible = $true
  }
}
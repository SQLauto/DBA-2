Write-Host "Querying for current Release Iteration..."
$Result = Invoke-RestMethod "http://tfs:8080/tfs/FTPDev/FTP/_apis/work/TeamSettings/Iterations?`$timeframe=current&api-version=2.0" -UseDefaultCredentials

Write-Host "Release Iteration found. Determining Release Number..."
$ReleaseName = $Result.value.name
$ReleaseNumber = $ReleaseName.Replace("Release ","")

Write-Host "Current Release Number is: $ReleaseNumber"
Write-Host "##vso[task.setvariable variable=FTPReleaseNumber;]$ReleaseNumber"

$date = Get-Date
$JulietDate = [System.String]::Format("{0}{1}", $date.ToString("yy"), [System.String]::Format("{0:000}", $date.DayOfYear));
Write-Host "##vso[task.setvariable variable=JulietDate;]$JulietDate"
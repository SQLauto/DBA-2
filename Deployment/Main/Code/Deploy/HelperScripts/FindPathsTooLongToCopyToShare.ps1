$dropLocation = '\\share\TFS\Drops\common\Main.FTP.CI\Main.FTP.CI_20160621.19'
$shareToCopyTo = '\\share\TFS\drops\Common\Build.Main.FTP.DTN\Build.Main.FTP.DTN_20160622.1'

cd $dropLocation
[int] $folderLengthsDifferBy = $shareToCopyTo.Length - $dropLocation.Length
Write-Output ("Folders differ by: " + $folderLengthsDifferBy)
[int] $searchForObjectsOver = 260 - $folderLengthsDifferBy
Write-Output ("Search for file paths greater than or equal: " + $searchForObjectsOver)
Get-ChildItem -Recurse | Where-Object {$_.FullName.Length -ge $searchForObjectsOver}  | Select-Object -Property FullName, Name 

[int] $maxFolderLength = 248 - $folderLengthsDifferBy
Write-Output ""
Write-Output ("Search for folder paths greater than or equal: " + $maxFolderLength)

Get-ChildItem -Directory -Recurse | Where-Object {$_.FullName.Length -ge $maxFolderLength}  | Select-Object -Property FullName
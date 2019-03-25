param
(
    [string]$ShareName,
    [string]$UserName,
    [string]$Permissions
)

$lastexitcode = 1

try
{
    #$newTargetPath = ($TargetPath.Split("\", 0,1,2) | Select -Index 3,4,5) -join "\"
    $folderPermissions = Get-Acl $ShareName

    $rights = [System.Security.AccessControl.FileSystemRights] $Permissions
    

    foreach($folderRight in $folderPermissions.Access | Where-Object {$_.IdentityReference -eq $UserName})
            {
                $bitwiseComparisonResult = $folderRight.FileSystemRights -band $rights
                if($bitwiseComparisonResult -eq $rights)
                {                                        
                    $lastexitcode = 0
                }
           }
           
}
catch [System.Exception]
{
    $message = "Error occured when trying to retrieve SID. Exception " + $_.Exception.ToString()
    $lastexitcode = 1
    Write-Output $message
}

exit $lastexitcode
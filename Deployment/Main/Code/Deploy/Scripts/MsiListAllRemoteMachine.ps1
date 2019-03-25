param
(
    [string] $MachineName
)

$exitCode = 0 
$scriptpath = split-path $MyInvocation.MyCommand.Path;
Set-Location -Path $scriptpath;

$localhost = $env:COMPUTERNAME;    
$local = $false
if($MachineName.ToLower() -eq $localhost.ToLower())
{
  .\MsiListAll.ps1                  
}
else
{
    $remotesession = new-pssession -computername $MachineName 
    Write-Output "Copying $scriptpath to \\$MachineName\d`$\Deployment\"
    if (Test-Path \\$MachineName\d`$\Deployment)
    {
        Write-Output "Folder Exists about to remove it for idempotent process: \\$MachineName\d`$\Deployment\Scripts"
		Remove-Item \\$MachineName\d`$\Deployment\Scripts -Recurse -Force -errorAction SilentlyContinue 
		Write-Output "Successfully deleted: \\$MachineName\d`$\Deployment\Scripts"
	}

	New-Item \\$MachineName\d`$\Deployment\Scripts -ItemType Directory -Force
		
	$capture = Copy-Item ("$scriptpath\*") "\\$MachineName\d`$\Deployment\Scripts\" -Recurse -Force -ErrorAction stop
    Invoke-Command -Session $remotesession -ScriptBlock {
        Try
        {
            D:\Deployment\Scripts\MsiListAll.ps1
	    }
	    catch [System.Exception]
        {
            $msg = "ERROR: Unable to run script to find all MSIs, error encountered: " + $_.Exception.ToString()
            Write-Output $msg
		    $lastexitcode = 1
        }
    } 
}

           
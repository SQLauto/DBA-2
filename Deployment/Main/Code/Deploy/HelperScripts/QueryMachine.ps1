# Connect to a machine and get the Powershell and .net version deployed
param
(
    [string] $TargetMachine      = "10.107.201.115", 
    [string] $Username           = "faelab\xjasonblackford", # If blank windows auth is used
    [string] $Password           = "Ches1549#" ,
	[string] $DriveLetter    = "D"
)
function main
{
Try
{
    # Connect to target machine
    if(![string]::IsNullOrEmpty($Username))
    {
        net use \\$TargetMachine /user:$Username $Password
    }
    else
    {
        net use \\$TargetMachine
    } 
    
    # Create query file on machine   
    $destLocation = "\\$targetMachine\$DriveLetter`$\"
    $destFile = "$destLocation\QueryMachine.ps1"
    if (Test-Path $destFile)
    {    
	   Remove-Item $destFile
	}
    add-content $destFile "Write-Output `".Net Version is`""
    add-content $destFile "`$prop = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name Version"
    add-content $destFile "`$prop.Version"
    add-content $destFile "Write-Output `"`""
    add-content $destFile "Write-Output `"Powershell version is`""
    add-content $destFile "`$PSVersionTable.PSVersion"
    add-content $destFile "Write-Output `"`""
	add-content $destFile "exit 0"
    
   
    # Run it remotley, i would like to just use PS remoting but we cant do that with ip addresses, which means it wont work with 
    # LM, so psexec it is
    Write-Output "Machine: $targetMachine"
    if(![string]::IsNullOrEmpty($Username))
    {
        & psexec \\$TargetMachine -u $Username -p $Password powershell -ExecutionPolicy Unrestricted -File $($DriveLetter):\QueryMachine.ps1 
    }
    else
    {
        & psexec \\$TargetMachine powershell -ExecutionPolicy Unrestricted -File $($DriveLetter):\QueryMachine.ps1
    }  

    
    # Clean up
    Remove-Item $destFile
}
Catch [System.Exception]
{
    $error = $_.Exception.ToString()
    Write-Error "$error"
    exit 1
}
}

main
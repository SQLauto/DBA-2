
param
(
    [string] $SSORig = $(throw '$SSORig'),
    [string] $FTPRig = "",               #optional
	[string] $OysterRig = ""           #optional
)

	function main
{
    [string] $webconfig ="";
    $useDummyFTP = $false
    $useDummyOyster = $false    
    if([string]::IsNullOrEmpty($FTPRig))
    {
        $useDummyFTP = $true
    }

	 $scriptpath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)
        
    Write-Output "Importing LabManager module..."
	Write-Output ""
    
    Write-Output "Parameters are: ${SSORig} : $FTPRig"
    Import-Module $scriptpath\LabManager.ps1    
	Add-Content "\\10.107.197.65\shared\to\a1.txt" "`n"
	Add-Content "\\10.107.197.65\shared\to\a1.txt" "`nImported LabManager module..."
    Add-Content "\\10.107.197.65\shared\to\a1.txt" "Parameters are: ${SSORig} $FTPRig"
    # Connect to SSO rig
    try{
    
        if (DoesRigExist $SSORig)
        {
            $SSOWebIP = Get-LabManagerMachineIPAddress $SSORig "TS-CAS1";
    		$SSOCISIP = Get-LabManagerMachineIPAddress $SSORig "TS-CIS1";
            $SSODBIP = Get-LabManagerMachineIPAddress $SSORig "TS-DB1";	
            $SSOServiceIP = ($SSOWebIP + ":8081");
            $SSOErrorPage = "http://$SSOWebIP/error"
            net use \\$SSOWebIP /user:faelab\tfsbuild LMTF`$Bu1ld
    		net use \\$SSOCISIP /user:faelab\tfsbuild LMTF`$Bu1ld
    		Add-Content "\\10.107.197.65\shared\to\a1.txt" "`n"
    		Add-Content "\\10.107.197.65\shared\to\a1.txt" "`nRig:${SSOWebIP}"
        }
        else
        {
            throw "SSO rig $SSORig does not exist"
        }
    }
    
    catch [Exception] {
        Write-Host $_.Exception.ToString()
        Add-Content "\\10.107.197.65\shared\to\a1.txt" "`nRig:${_.Exception.ToString()}"
 
    }

	Add-Content "\\10.107.197.65\shared\to\a1.txt" "`nSSo Rig: ${SSORig} SSOWebIP: ${SSOWebIP}"
 }

 	$result=test-path -path "\\10.107.197.65\shared\to\a1.txt" -pathtype leaf
	write-host "File Exists:" $result
	remove-item "\\10.107.197.65\shared\to\a1.txt" 
	$result= test-path -path "\\10.107.197.65\shared\to\a1.txt"
	write-host "End result:" $result
	copy-item "\\10.107.197.65\shared\from\a1.txt" -destination \\10.107.197.65\shared\to -verbose 
	$result= test-path -path "\\10.107.197.65\shared\to\a1.txt"
	write-host "End result:" $result
	$theDate= Get-Date
	Add-Content "\\10.107.197.65\shared\to\a1.txt" "`n"
	Add-Content "\\10.107.197.65\shared\to\a1.txt" "`n${theDate}"
main

filter Select-Exists { $_| Where-Object{ $_ } }
filter Select-Error { $_| Where-Object{$_.Error} }
filter Select-NotError { $_| Where-Object{!$_.Error} }

function Assert-IsDevEnvironment{
[CmdletBinding()]
param (
	[Parameter(Mandatory=$true)]
	[string] $Environment
)

	($Environment -eq "TSRig") -or ($Environment -eq "TestRig") -or ($Environment -eq "Dev") -or ($Environment -eq "Baseline") -or ($Environment -contains "MasterData.Sandbox")
}

function Invoke-UntilFail{
[CmdletBinding()]
param([scriptblock[]]$Scriptblock)
	$retVal = 0
    $failed = $false
	$global:LASTEXITCODE = $null

    $results = $Scriptblock | ForEach-Object {
        $result = 0
		if($failed){return $result}

        $result = . $_

		if($LASTEXITCODE -and $LASTEXITCODE -ne 0){
			Write-Host "Invoke-UntilFail action exited with LASTEXITCODE $LASTEXITCODE"
			$result = 1
		}

		if($result -ne 0) {
			$failed = $true
		}

		$global:LASTEXITCODE = $null

		$result
    }

	if(Test-IsNullOrEmpty $results){
		$retVal = 0
	}
	else{
		$retVal = ($results | Measure-Object -Maximum).Maximum
	}

    $retVal
}

function Test-IsNullOrEmpty {
Param(
	[Parameter(Mandatory=$true)]
	[AllowNull()]$Subject
)

	($null -eq $Subject -or $Subject.Count -eq 0)
}

function Test-IsNotNullOrEmpty {
Param(
	[Parameter(Mandatory=$true)]
	[AllowNull()]$Subject
)

	($null -ne $Subject -and $Subject.Count -gt 0)
}

function Merge-Xml {
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$true)][xml]$TargetXml,
	[Parameter(Mandatory=$true, ValueFromPipeline=$True)][xml]$SourceXml
	)
	PROCESS{
		$SourceXml.DocumentElement.ChildNodes | ForEach-Object {
			$TargetXml.DocumentElement.AppendChild($TargetXml.ImportNode($_, $true)) | Out-Null
		}
		$TargetXml
	}
}

function New-Xml {
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$true, ValueFromPipeline=$True)]$Nodes
	)
	PROCESS{
		$xml = New-Object -TypeName xml
		$xml.AppendChild($xml.ImportNode($Nodes, $true)) | Out-Null
		$xml
	}
}

function Compare-Array{
<#
.SYNOPSIS
	Compares two arrays and returns items that are only in both arrays.
.PARAMETER Reference
    The reference array used for comparison.
.PARAMETER Target
    The Target array to compare to the comparison array.
#>
[CmdletBinding()]
    param (
      	[Parameter(Mandatory=$true)] [array][AllowNull()]$Reference,
		[Parameter(Mandatory=$true)] [array][AllowNull()]$Target
    )
	BEGIN{
		$Reference = $Reference | Select-Exists
		$Target = $Target | Select-Exists
	}
	PROCESS{

		if((Test-IsNullOrEmpty $Reference) -or (Test-IsNullOrEmpty $Target) ){
			return $null
		}

		Compare-Object -ReferenceObject $Reference -DifferenceObject $Target -ExcludeDifferent -IncludeEqual | Select-Object -ExpandProperty InputObject
	}
}

function Limit-Array{
<#
.SYNOPSIS
	Limits or Filters an target array based comparing it's contents to a reference array.
	Items in the reference array are filtered based on what is in the target array.
	i.e. The target (Filter) array is used to limit or filter the Reference (Source) array
.PARAMETER Reference
    The reference array used to as a comparison for filtering.
.PARAMETER Target
    The Target array that will be filtered based on presence of values in Reference array.
#>
[CmdletBinding()]
    param (
      	[Parameter(Mandatory=$true)][Alias("Reference")][array][AllowNull()]$Source,
		[Parameter(Mandatory=$true)][Alias("Target")] [array][AllowNull()]$Filter
    )
	BEGIN{
		$Source = $Source | Select-Exists
		$Filter = $Filter | Select-Exists
	}
	PROCESS{

		if((Test-IsNullOrEmpty $Source) -or (Test-IsNullOrEmpty $Filter) ){
			return $null
		}

		Compare-Object -ReferenceObject $Source -DifferenceObject $Filter | Select-Object -ExpandProperty InputObject
	}
}

function Get-LogFileSuffix {
<#
.SYNOPSIS
	Given a comma separted list of groups, return a string that will be used to suffix the end of the deployment log files.
	Note: If you update this then you will also have to update the build xaml files as the xaml file also manages log files and
	unfortunatley it is not easy to share code between powershell and the build template
.PARAMETER Groups
    A comman seperated list of deployment groups. String can be null or empty.
#>
param([string] $Groups)

	$logGroupSuffix = ""
	if(![string]::IsNullOrWhiteSpace($Groups))
    {
        $logGroupSuffix += "."
		foreach ($group in $Groups.Split(","))
        {
			$logGroupSuffix += $group.Trim() + "_"
		}
		$logGroupSuffix = $logGroupSuffix.TrimEnd("_")
	}

	$logGroupSuffix
}

function Assert-EventLog {
    Param(
        [Parameter(Mandatory=$true)]
        [string] $LogName,
		[Parameter()]
        [string[]] $ComputerName = "."
    )

	$log = $null
	try{
		$log = Get-Eventlog -ComputerName $ComputerName -list | Where-Object {$_.Log -eq $LogName}
	}
	catch{
		$log = $null
	}

	($null -ne $log)
}

function Assert-EventLogSource {
    Param(
        [Parameter(Mandatory=$true)]
        [string] $SourceName
    )

    [System.Diagnostics.EventLog]::SourceExists($SourceName)
}

function Get-EventLogFromSource {
    Param(
        [Parameter(Mandatory=$true)]
        [string] $SourceName,
		[Parameter(Mandatory=$false)]
        [string] $MachineName = "."
    )

    [System.Diagnostics.EventLog]::LogNameFromSourceName($sourceToAssociate, $MachineName)
}

function Get-RegistryKeyProperty {
<#
.SYNOPSIS
	Set the value of a remote registry key property
.EXAMPLE
	PS >$registryPath =
		"HKLM:\software\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell"
	PS >Set-RegistryKeyProperty LEE-DESK $registryPath `
		  "ExecutionPolicy" "RemoteSigned"
#>
[CmdletBinding()]
param(
    ## The Computer to connect to
    [Parameter(Mandatory = $true)]
    $ComputerName,

    ## The registry path to get value from
    [Parameter(Mandatory = $true)]
    $Path,

    ## The property to get
    [Parameter(Mandatory = $true)]
    $PropertyName
)
	PROCESS{

		## Validate and extract out the registry key
		if($Path -match "^HKLM:\\(.*)") {
			$baseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(
				"LocalMachine", $ComputerName)
		}
		elseif($Path -match "^HKCU:\\(.*)") {
			$baseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(
				"CurrentUser", $ComputerName)
		}
		else {
			Write-Error ("Please specify a fully-qualified registry path " +
				"(i.e.: HKLM:\Software) of the registry key to open.")
			return
		}

		## Open the Key and get the required value
		$key = $baseKey.OpenSubKey($Matches[1])
		$value = $key.GetValue($PropertyName)

		## Close the key and base keys
		$key.Close()
		$baseKey.Close()

		$value
	}
}

function Set-RegistryKeyProperty {
[CmdletBinding()]
param(
    ## The computer to connect to
    [Parameter(Mandatory = $true)]
    $ComputerName,

    ## The registry path to modify
    [Parameter(Mandatory = $true)]
    $Path,

    ## The property to modify
    [Parameter(Mandatory = $true)]
    $PropertyName,

    ## The value to set on the property
    [Parameter(Mandatory = $true)]
    $PropertyValue
)
	PROCESS{
		## Validate and extract out the registry key
		if($path -match "^HKLM:\\(.*)") {
			$baseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(
				"LocalMachine", $computername)
		}
		elseif($path -match "^HKCU:\\(.*)") {
			$baseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(
				"CurrentUser", $computername)
		}
		else {
			Write-Error ("Please specify a fully-qualified registry path " +
				"(i.e.: HKLM:\Software) of the registry key to open.")
			return
		}

		## Open the key and set its value
		$key = $baseKey.CreateSubKey($matches[1])
		$key.SetValue($propertyName, $propertyValue)

		## Close the key and base keys
		$key.Close()
		$baseKey.Close()
	}
}

function Get-PendingReboot {
<#
.SYNOPSIS
    Gets the pending reboot status on a local or remote computer.

.DESCRIPTION
    This function will query the registry on a local or remote computer and determine if the
    system is pending a reboot, from Microsoft updates, Configuration Manager Client SDK, Pending Computer
    Rename, Domain Join or Pending File Rename Operations. For Windows 2008+ the function will query the
    CBS registry key as another factor in determining pending reboot state.  "PendingFileRenameOperations"
    and "Auto Update\RebootRequired" are observed as being consistant across Windows Server 2003 & 2008.

    CBServicing = Component Based Servicing (Windows 2008+)
    WindowsUpdate = Windows Update / Auto Update (Windows 2003+)
    CCMClientSDK = SCCM 2012 Clients only (DetermineIfRebootPending method) otherwise $null value
    PendComputerRename = Detects either a computer rename or domain join operation (Windows 2003+)
    PendFileRename = PendingFileRenameOperations (Windows 2003+)
    PendFileRenVal = PendingFilerenameOperations registry value; used to filter if need be, some Anti-
                     Virus leverage this key for def/dat removal, giving a false positive PendingReboot

.PARAMETER ComputerName
    A single Computer or an array of computer names.  The default is localhost ($env:COMPUTERNAME).

.PARAMETER ErrorLog
    A single path to send error data to a log file.

.EXAMPLE
    PS C:\> Get-PendingReboot -ComputerName (Get-Content C:\ServerList.txt) | Format-Table -AutoSize

    Computer CBServicing WindowsUpdate CCMClientSDK PendFileRename PendFileRenVal RebootPending
    -------- ----------- ------------- ------------ -------------- -------------- -------------
    DC01           False         False                       False                        False
    DC02           False         False                       False                        False
    FS01           False         False                       False                        False

    This example will capture the contents of C:\ServerList.txt and query the pending reboot
    information from the systems contained in the file and display the output in a table. The
    null values are by design, since these systems do not have the SCCM 2012 client installed,
    nor was the PendingFileRenameOperations value populated.

.EXAMPLE
    PS C:\> Get-PendingReboot

    Computer           : WKS01
    CBServicing        : False
    WindowsUpdate      : True
    CCMClient          : False
    PendComputerRename : False
    PendFileRename     : False
    PendFileRenVal     :
    RebootPending      : True

    This example will query the local machine for pending reboot information.

.EXAMPLE
    PS C:\> $Servers = Get-Content C:\Servers.txt
    PS C:\> Get-PendingReboot -Computer $Servers | Export-Csv C:\PendingRebootReport.csv -NoTypeInformation

    This example will create a report that contains pending reboot information.

.LINK
    Component-Based Servicing:
    http://technet.microsoft.com/en-us/library/cc756291(v=WS.10).aspx

    PendingFileRename/Auto Update:
    http://support.microsoft.com/kb/2723674
    http://technet.microsoft.com/en-us/library/cc960241.aspx
    http://blogs.msdn.com/b/hansr/archive/2006/02/17/patchreboot.aspx

    SCCM 2012/CCM_ClientSDK:
    http://msdn.microsoft.com/en-us/library/jj902723.aspx

.NOTES
    Author:  Brian Wilhite
    Email:   bcwilhite (at) live.com
    Date:    29AUG2012
    PSVer:   2.0/3.0/4.0/5.0
    Updated: 27JUL2015
    UpdNote: Added Domain Join detection to PendComputerRename, does not detect Workgroup Join/Change
             Fixed Bug where a computer rename was not detected in 2008 R2 and above if a domain join occurred at the same time.
             Fixed Bug where the CBServicing wasn't detected on Windows 10 and/or Windows Server Technical Preview (2016)
             Added CCMClient property - Used with SCCM 2012 Clients only
             Added ValueFromPipelineByPropertyName=$true to the ComputerName Parameter
             Removed $Data variable from the PSObject - it is not needed
             Bug with the way CCMClientSDK returned null value if it was false
             Removed unneeded variables
             Added PendFileRenVal - Contents of the PendingFileRenameOperations Reg Entry
             Removed .Net Registry connection, replaced with WMI StdRegProv
             Added ComputerPendingRename
#>

[CmdletBinding()]
param(
	[Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
	[Alias("CN","Computer")]
	[string[]]$ComputerName="$env:COMPUTERNAME",
	[string]$ErrorLog
	)

	PROCESS {
		$ComputerName | ForEach-Object {
			$computer = $_

			try {
				# Setting pending values to false to cut down on the number of else statements
				$CompPendRen,$PendFileRename,$Pending,$SCCM,$PendExeMod = $false,$false,$false,$false,$false

				# Querying WMI for build version
				$WMI_OS = Get-WmiObject -Class Win32_OperatingSystem -Property BuildNumber, CSName -ComputerName $Computer -ErrorAction Stop

				# Making registry connection to the local/remote computer
				$HKLM = [UInt32] "0x80000002"
				$WMI_Reg = [WMIClass] "\\$computer\root\default:StdRegProv"

				$RegSubKeysCBS = $WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\")
				$CBSRebootPend = $RegSubKeysCBS.sNames -contains "RebootPending"

				# Query WUAU from the registry
				$RegWUAURebootReq = $WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")
				$WUAURebootReq = $RegWUAURebootReq.sNames -contains "RebootRequired"

				# Query PendingFileRenameOperations from the registry
				$RegSubKeySM = $WMI_Reg.GetMultiStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\Session Manager\","PendingFileRenameOperations")
				$RegValuePFRO = $RegSubKeySM.sValue

				# Query JoinDomain key from the registry - These keys are present if pending a reboot from a domain join operation
				$Netlogon = $WMI_Reg.EnumKey($HKLM,"SYSTEM\CurrentControlSet\Services\Netlogon").sNames
				$PendDomJoin = ($Netlogon -contains 'JoinDomain') -or ($Netlogon -contains 'AvoidSpnSet')

				# Query ComputerName and ActiveComputerName from the registry
				$ActCompNm = $WMI_Reg.GetStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName\","ComputerName")
				$CompNm = $WMI_Reg.GetStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\","ComputerName")

				if(($ActCompNm -ne $CompNm) -or $PendDomJoin) {
					$CompPendRen = $true
				}

				# If PendingFileRenameOperations has a value set $RegValuePFRO variable to $true
				if($RegValuePFRO) {
					$PendFileRename = $true
				}

				#Pending Exe Modification
				$RegSubKeysExeMod = $WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Updates\UpdateExeVolatile\")
				$PendExeMod = ($null -ne $RegSubKeysExeMod -and $RegSubKeysExeMod.ReturnValue -eq 0)

				# Determine SCCM 2012 Client Reboot Pending Status
				# To avoid nested 'if' statements and unneeded WMI calls to determine if the CCM_ClientUtilities class exist, setting EA = 0
				$CCMClientSDK = $null

				# Try CCMClientSDK
				try {
					$CCMSplat = @{
						NameSpace='ROOT\ccm\ClientSDK'
						Class='CCM_ClientUtilities'
						Name='DetermineIfRebootPending'
						ComputerName=$computer
						ErrorAction='Stop'
					}

					$CCMClientSDK = Invoke-WmiMethod @CCMSplat
				}
				catch [System.UnauthorizedAccessException] {
					$CcmStatus = Get-Service -Name CcmExec -ComputerName $computer -ErrorAction SilentlyContinue
					if($CcmStatus.Status -ne 'Running') {
						Write-Warning "$Computer`: Error - CcmExec service is not running."
						$CCMClientSDK = $null
					}
				}
				catch {
					$CCMClientSDK = $null
				}

				if($CCMClientSDK) {
					if($CCMClientSDK.ReturnValue -ne 0) {
						Write-Warning "Warning: Get-PendingReboot returned error code $($CCMClientSDK.ReturnValue)"
					}

					if($CCMClientSDK.IsHardRebootPending -or $CCMClientSDK.RebootPending) {
						$SCCM = $true
					}
				}
				else {
					$SCCM = $null
				}

				if($PendFileRename){
					Write-Warning "Warning: Get-PendingReboot returned true for a pending file rename. This will not fail the deployment, but if other errors are observed, this could be a cause."
				}

				if($CBSRebootPend){
					Write-Warning "Warning: Get-PendingReboot returned true for a pending CBS reboot. This will not fail the deployment, but if other errors are observed, this could be a cause."
				}

				[PSCustomObject] @{
					Computer=$WMI_OS.CSName
					CBServicing=$CBSRebootPend
					WindowsUpdate=$WUAURebootReq
					CCMClientSDK=$SCCM
					PendComputerRename=$CompPendRen
					PendFileRename=$PendFileRename
					PendFileRenVal=$RegValuePFRO
					PendingExeModification = $PendExeMod
					RebootPending=($CompPendRen -or $WUAURebootReq -or $SCCM -or $PendExeMod) #$-or PendFileRename
				}
				#-or $CBSRebootPend)
			}
			catch {
				Write-Warning "$Computer`: $_"
				# If $ErrorLog, log the file to a user specified location/path
				if($ErrorLog) {
					Out-File -InputObject "$Computer`,$_" -FilePath $ErrorLog -Append
				}
			}
		}
	}
}

function Copy-ItemRobust {
<# TODO:
.SYNOPSIS
    A PowerShell wrapper function for using RoboCopy.
.DESCRIPTION
    Copy or move files and/or folders using RoboCopy.
.PARAMETER Path
    The name of the source folders whose contents to archive.
.PARAMETER TargetPath
    The name of the folder where the zip archives will be saved.
#TODO
.PARAMETER File
    Option string that is used to prefix the nameof the zip archive. If no argument is passed, the name of the source folder is used.
.PARAMETER DateFormat
    Option string to specify a valid date format string that is used when naming the archive.
.PARAMETER ArchiveOffset
    The number of days to offset from today of the files LastWriteTime from which to begin archiving.
.PARAMETER ArchiveDays
    The number of days from today to count back of any files LastWriteTime that will be archived.
.PARAMETER ArchiveCount
    The number of current archive zip files to keep (if any) at the zip archive target folder.
.PARAMETER Move
	Switch to indicate whether the source files should be moved (deleted).

.EXAMPLE
    Copy-ItemRobust -Path D:\Source -TargetPath D:\Archive
	Copy files from the source directory to the target directory. This will copy top all files, but not recursively.  All output will be suppressed.
	If you want to see the output of the call, you need to pass the -ShowOuput argument.

	Copy-ItemRobust -Path D:\Source -TargetPath D:\Archive -File "*.log" -Recurse -Delete -ShowOutput -JobHeader
	This will move all files with the extension of .log from the folder D:\Source to D:\Archive, acting recursivley, showing any output, (ie. JobHeader)
#>
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$true)][Alias("SourcePath")][string]$Path,
	[Parameter(Mandatory=$true)][Alias("Destination")][string]$TargetPath,
	[Parameter()][string[]]$File = "*.*",
	[Parameter()][string]$Wait = "2",
	[Parameter()][string]$Retry = "3",
	[Parameter()][switch]$Recurse,
	[Parameter()][switch]$FileList,
	[Parameter()][switch]$DirectoryList,
	[Parameter()][switch]$JobHeader,
	[Parameter()][switch]$JobSummary,
	[Parameter()][switch]$Progress,
	[Parameter()][switch]$Mirror,
	[Parameter()][switch]$MultiThreaded,
    [Parameter()][Alias("Delete")][switch]$Move,
    [Parameter()][switch]$ShowOutput
	)
	PROCESS{

		if(!(Test-Path -Path $Path)){
			throw "Source folder $Path does not exist"
		}

		$s = "";
		if($Recurse){
			$s = "/s"
		}

		$nfl = "/nfl";
		if($FileList){
			$nfl = ""
		}

		$ndl = "/ndl";
		if($DirectoryList){
			$ndl = ""
		}

		$np = "/np";
		if($Progresst){
			$np = ""
		}

		$njs = "/njs";
		if($JobSummary){
			$njs = ""
		}

		$njh = "/njh";
		if($JobHeader){
			$njh = ""
		}

		$mt = "";
		if($MultiThreaded){
			$mt = "/mt"
		}

		$mve = "";
		if($Move){
			$move = "/move"
		}

		$mir = "";
		if($Mirror){
			$mir = "/mir"
		}

        $command = "robocopy.exe `"$Path`" `"$TargetPath`" $File /R:$Retry /W:$Wait $s $nfl $np $njh $ndl $njs $mt $mve $mir"

        if($ShowOutput){
            Invoke-Expression -Command $command -ErrorAction Stop | Out-String -Stream | Write-Host
        }
        else{
            Invoke-Expression -Command $command -ErrorAction Stop -OutVariable output | Out-Null
        }

		$result = $LASTEXITCODE -lt 8
		if ($result) {
			$global:LASTEXITCODE = $null
		}

		$result
	}
}

function New-TemporaryDirectory {
param(
	[Parameter()]
	[Alias("Root")]
	[Alias("Parent")]
	[string]$Path
)
    $tempPath = Get-TemporaryDirectory -Path $Path

	Write-Host "Creating temporary directory at $tempPath"
    New-Item -ItemType Directory -Path $tempPath -Force
}

function Get-TemporaryDirectory {
param(
	[Parameter()]
	[Alias("Root")]
	[Alias("Parent")]
	[string]$Path
)

    if(!$Path){
		$Path = [System.IO.Path]::GetTempPath()
	}

	$guid = [system.guid]::newguid()
	$encoded = [System.Convert]::ToBase64String($guid.ToByteArray()).Replace("/", "_").Replace("+", "-").Substring(0, 22)
	$tempPath  = Join-Path $Path $encoded

	$tempPath
}

function Remove-AllFiles {
param(
	[Parameter(Mandatory=$true)]
	[Alias("Destination")]
	[Alias("Path")]
	[string]$TargetPath,
	[ValidateScript( {$_ -gt -1})]
    [int]$ArchiveOffset = 0,
	[Parameter()][switch]$RemoveFolder
)

	$source = (New-TemporaryDirectory).FullName

	if ($ArchiveOffset -eq 0) {
		Write-Host "Removing all files from folder $TargetPath"
		Copy-ItemRobust -Path $source -TargetPath $TargetPath -Mirror | Out-Null
	}
	else {
		$archiveDate = Get-OffsetDate -$ArchiveOffset
		$allFiles = Get-ChildItem -Path $TargetPath -File | Where-Object { $_.LastWriteTime -lt $archiveDate }
		if (-not $allFiles) { Write-Host "No files found to remove older than $($archiveDate.ToLongDateString())."; return }
		Write-Host "Removing all files from folder $TargetPath older than $($archiveDate.ToLongDateString())"
		Copy-ItemRobust -Path $source -TargetPath $TargetPath -File $allFiles -Mirror | Out-Null
	}

	$source | Remove-Item -Force

	if($RemoveFolder){
		$TargetPath | Remove-Item -Force
	}
}

function ConvertTo-XmlString {
param([string][ValidateNotNull()]$inputValue)
	Add-Type -AssemblyName System.Web
	[System.Web.HttpUtility]::HtmlEncode($inputValue)
}

function Get-Folder {
[cmdletbinding()]
param
([string]$Source,[string]$Target)
	PROCESS{
		$rooted = [System.IO.Path]::IsPathRooted($Target)

		if(!$rooted){
			$parent = Split-Path $Source
			$Target = Join-Path $parent $Target
		}

		$Target
	}
}

filter Get-FilesInDay {
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)][IO.FileInfo[]] $files,
		[Parameter(Mandatory = $true)][DateTime] $Date
	)
	$files | Where-Object { $_.LastWriteTime.Month -eq $Date.Month `
		-and $_.LastWriteTime.Year -eq $Date.Year `
		-and $_.LastWriteTime.Day -eq $Date.Day }
}

function Remove-EmptyDirectories {
param (
	[Parameter(Mandatory = $true)][string] $Path)

	Get-ChildItem -Force -LiteralPath $Path -Directory | ForEach-Object {
		Remove-EmptyDirectories -Path $_.FullName
	}

	$currentChildren = Get-ChildItem -Force -LiteralPath $Path

    if ($null -eq $currentChildren) {
        Write-Host "Removing empty folder at path '${Path}'." -Verbose
        Remove-Item -Force -LiteralPath $Path
    }
}

function Get-OffsetDate {
param (
	[Parameter(Mandatory=$true)] [int]$DaysOffset
)
	(Get-Date).AddDays($DaysOffset)
}

function Get-ZipName {
    param(
        [string]$TargetPath,
        [string]$FilePrefix,
        [string]$DateFormat = "yyyyMMdd",
        [datetime]$Date
    )

    $datePart = "{0:$DateFormat}" -f $Date
    #get count of files where name like the date part
    $files = [array](Get-ChildItem -Path $TargetPath -File -Filter '*.zip' | Where-Object {$_.Name -like "*$datePart*"})

    $count = $files.Count

    $zipname = "$FilePrefix.$($datePart)_$count.zip"

    $destinationPath = Join-Path $TargetPath $zipname

    $destinationPath
}

function Backup-Folder{
<#
.SYNOPSIS
    Creates a zip backup of a source folder based on the name of the soruce folder.
.DESCRIPTION
    Backup or archive a folder by creating a zip archive of that folder. Allows for the achiving of
	folders, with the option to delete (move) the contents of the source folder.
	The script allows the archive of files based on the number of days (offset) to keep files and archives or based upon the total number of archives.
	The name of the archive path can be passed in, and is absolute or relative to the parent of the source folder, the latter being the default.
.PARAMETER Path
    The name of the source folders whose contents to archive.
.PARAMETER TargetPath
    The name of the folder where the zip archives will be saved.
.PARAMETER FilePrefix
    Option string that is used to prefix the nameof the zip archive. If no argument is passed, the name of the source folder is used.
.PARAMETER DateFormat
    Option string to specify a valid date format string that is used when naming the archive.
.PARAMETER ArchiveOffset
    The number of days to offset from today of the files LastWriteTime from which to begin archiving.
.PARAMETER ArchiveDays
    The number of days from today to count back of any files LastWriteTime that will be archived.
.PARAMETER ArchiveCount
    The number of current archive zip files to keep (if any) at the zip archive target folder.
.PARAMETER Move
	Switch to indicate whether the source files should be moved (deleted).
#.PARAMETER Recurse
#    Switch to indicate whether the source files should be recursively archived.

.EXAMPLE
    Backup-Folder -Path D:\Source -TargetPath D:\Archive -ArchiveOffset 1 -ArchiveDays 30 -Move
	The will archive (move) all files in the folder D:\Source where the LastWriteTime property is from yesterday for the last 30 days.  Any files
	or archives older than 30 days from today will be deleted.

	Backup-Folder -Path D:\Source -TargetPath D:\Archive -ArchiveOffset 0 -ArchiveCount 3 -Move
	The will archive (move) all files in the folder D:\Source where the LastWriteTime property is today.  The all but the last 3 zips in the archive folder will
	be deleted.

.INPUTS
.OUTPUTS
#>
[cmdletbinding(DefaultParameterSetName="ByDays")]
param(
	[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [Alias('Source')]
    [ValidateNotNullOrEmpty()]
    [string[]]$Path,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetPath,
    [Parameter()]
    [string]$FilePrefix,
    [string]$DateFormat = "yyyyMMdd",
    [Parameter(Mandatory = $true, ParameterSetName = "ByDays")]
    [ValidateScript( {$_ -ge -1})]
    [int]$ArchiveDays,
    [Parameter(ParameterSetName = "ByDays")]
    [ValidateScript( {$_ -ge -1})]
    [int]$ArchiveOffset = 0,
    [Parameter(Mandatory = $true, ParameterSetName = "ByCount")]
    [ValidateScript( {$_ -ge -1})]
    [int]$ArchiveCount,
    [switch]$Move,
    [switch]$Recurse,
    [switch]$Copy
)

	PROCESS {

        if (!(Test-Path $TargetPath)) {
            New-Item -Path $TargetPath -ItemType Directory -Force | Out-Null
        }

        $Path | ForEach-Object {
            $sourcePath = $_

            if (!(Test-Path $sourcePath)) {
                throw "Source Path $sourcePath was not found."
            }

            if (!$FilePrefix) {
                $FilePrefix = Split-Path $sourcePath -Leaf
            }

            $rootPath = Split-Path $sourcePath

            if ($PSCmdlet.ParameterSetName -eq "ByDays") {
                if ($ArchiveDays -gt 0) {
                    $toKeepDate = (Get-OffsetDate -$ArchiveDays).Date

                    Write-Host "Deleting archive files older than $($toKeepDate.ToLongDateString())."
                    Get-ChildItem -Path $TargetPath -Recurse | Where-Object {!$_.PSIsContainer -and $_.LastWriteTime -lt $toKeepDate} | Remove-Item -Force

                    Write-Host "Deleting source files older than $($toKeepDate.ToLongDateString())."
                    Get-ChildItem -Path $_ -Recurse | Where-Object {!$_.PSIsContainer -and $_.LastWriteTime -lt $toKeepDate} | Remove-Item -Force
                }

                $archiveDate = Get-OffsetDate -$ArchiveOffset
                $allFiles = Get-ChildItem -Path $_ -Recurse -File | Where-Object { $_.LastWriteTime -lt $archiveDate }
                if (-not $allFiles) { Write-Host "No files found to archive older than $($archiveDate.ToLongDateString())."; return }

                Write-Host "Archiving files older than $($archiveDate.ToLongDateString())."

                $earliestFileDate = (($allFiles.LastWriteTime | Sort-Object)[0]).Date

                $ArchiveDays..$ArchiveOffset | ForEach-Object {
                    $date = Get-OffsetDate -$_
                    if ($date -lt $earliestFileDate) { return }

                    # Get a single day's files
                    $dayFiles = $allFiles | Get-FilesInDay -Date $date | Select-Object -ExpandProperty 'Fullname'

                    if ($dayFiles.Count -eq 0) { return }

                    Write-Host "Archiving files from $($date.ToLongDateString())."
                    $tempPath = New-TemporaryDirectory -Path $rootPath

                    if ($Move) {
                        $dayFiles | Move-Item -Destination $tempPath -Force
                    }
                    else {
                        $dayFiles | Copy-Item -Destination $tempPath -Force -Recurse
                    }

                    $zipname = Get-ZipName -TargetPath $TargetPath -FilePrefix $FilePrefix -Date $date

                    Write-Host "Creating Zip Archive $zipname"
                    "$tempPath\*" | Compress-Archive -DestinationPath $zipname -Update

                    if ($tempPath -and (Test-Path $tempPath)) {
                        Remove-Item $tempPath -Recurse -Force
                    }
                }
            }
            else {
                if ($ArchiveCount -gt 0) {
                    $toKeep = [array](Get-ChildItem -Path $TargetPath -File -Filter "$FilePrefix.*.zip" | Sort-Object -Property "LastWriteTime" -Descending | Select-Object -ExpandProperty Name -First ($ArchiveCount - 1))
                    Get-ChildItem -Path $TargetPath -File -Filter "$FilePrefix.*.zip" | Where-Object {$_.Name -notin $toKeep} | Remove-Item -Force
                }

                if ($Move) {
                    $tempPath = New-TemporaryDirectory -Path $rootPath
                    $sourcePath | Get-ChildItem -Recurse -Force | Move-Item -Destination $tempPath -Force
                    $sourcePath = $tempPath
                }
                else {
                    if ($Copy) {
                        $tempPath = New-TemporaryDirectory -Path $rootPath
                        $sourcePath | Get-ChildItem -Force | Copy-Item -Destination $tempPath -Force -Recurse
                        $sourcePath = $tempPath
                    }
                }

                $date = Get-Date
                $zipname = Get-ZipName -TargetPath $TargetPath -FilePrefix $FilePrefix -Date $date -DateFormat 'yyyyMMdd.HHmm'

                Write-Host "Creating Zip Archive $zipname"
                "$sourcePath\*" | Compress-Archive -DestinationPath $zipname -Update
            }

            if ($tempPath -and (Test-Path $tempPath)) {
                Remove-Item $tempPath -Recurse -Force
            }
        }
    }
}

function Invoke-PsExec {
[CmdletBinding(DefaultParameterSetName="Command")]
<#
.SYNOPSIS
    Invoke-PsExec for PowerShell is a cmdlet that lets you execute PowerShell and batch/cmd.exe
.PARAMETER ComputerName
    IP address or computer name.
.PARAMETER Command
    Batch or cmd.exe code to execute.
.PARAMETER PsCommand
    The PowerShell command to run
.PARAMETER PSFile
    PowerShell file in the local file system to be run via PsExec on the remote computer.
.PARAMETER CustomPsExecParameters
    Custom parameters for PsExec.
.PARAMETER Credential
    Pass in alternate credentials. Get-Help Get-Credential.
.PARAMETER Timeout
    Timeout in seconds. Causes problems if too short. 30 as a default seems OK. Increase if doing a lot of processing with PsExec.
.PARAMETER UseDNS
    Perform a DNS lookup.
.PARAMETER ContinueOnPingFail
    Attempt PsExec command even if ping fails.
#>
param(
    [Parameter(Mandatory=$True, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string] $ComputerName,
    [Parameter(ParameterSetName="Command", Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $Command,
    [Parameter(ParameterSetName="PowerShell")]
    [string] $PsCommand,
    [Parameter(ParameterSetName="PowerShell")]
    [ValidateScript({Test-Path -Path $_ -PathType Leaf})][string] $PsFile = '',
    [string] $CustomPsExecParameters = '',
    [PSCredential][System.Management.Automation.Credential()] $Credential = [System.Management.Automation.PSCredential]::Empty,
    [switch] $UseDNS,
    [switch] $ContinueOnPingFail
)
    Set-StrictMode -Version Latest

    $data = @{
        'Server' = $ComputerName
        'IP' = $null
		'Result' = 0
    }

    $eap = 'Stop'
    $ErrorActionPreference = $eap

    if ($PsExecExecutable = Get-Item -LiteralPath (Join-Path (Get-Location) 'PsExec.exe') -ErrorAction SilentlyContinue) {
        Write-Host "Found PsExec.exe in current working directory."
        $PsExecPath = $PsExecExecutable | Select-Object -ErrorAction SilentlyContinue -ExpandProperty FullName
    }
    elseif ($PsExecExecutable = Get-Item -LiteralPath "$PSScriptRoot\PsExec.exe" -ErrorAction SilentlyContinue) {
        Write-Host "Found PsExec.exe in directory script was called from."
        $PsExecPath = $PsExecExecutable | Select-Object -ErrorAction SilentlyContinue -ExpandProperty FullName
    }
    elseif ($PsExecExecutable = Get-Command -Name psexec -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1) {
        Write-Host "Found PsExec.exe in `$Env:PATH."
        $PsExecPath = $PsExecExecutable | Select-Object -ErrorAction SilentlyContinue -ExpandProperty Definition
    }
    else {
        Write-Error "You need PsExec.exe from Microsoft's SysInternals suite to use this script. Either in the working dir, or somewhere in `$Env:PATH." -ErrorAction Stop
        $data.Result = 1
		return [PSCustomObject]$data
    }

    $version = ($PsExecExecutable | Select-Object -ExpandProperty Version)
	#TODO: Consider testing for a particular version of PsExec?
    Write-Host "Using this PsExec.exe executable: '$PsExecPath', Version $Version."

    $tempPSFile = $tempStdOut = $tempStdErr = $null

    try {
        if ($UseDNS) {
            Write-Host "${ComputerName}: Performing DNS lookup."
            $ErrorActionPreference = 'SilentlyContinue'
            $hostEntry = [System.Net.Dns]::GethostEntry($ComputerName)
            $result = $?
            $ErrorActionPreference = $eap
            # It looks like it's sometimes "successful" even when it isn't, for any practical purposes (pass in IP, get the same IP as .HostName)...
            if ($result) {
                ## This is a best-effort attempt at handling things flexibly.
                if ($hostEntry.HostName.Split('.')[0] -ieq $ComputerName.Split('.')[0]) {
                    $ipDns   = @($hostEntry  | Select-Object -ExpandProperty AddressList | Select-Object -ExpandProperty IPAddressToString)
                }
                else {
                    $ipDns   = @(@($hostEntry.HostName) + @($hostEntry.Aliases))
                }

                $data.IP = $ipDns
            }
        }

        Write-Host "${ComputerName}: Pinging."
        if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
            $data.Ping = $false
            if (-not $ContinueOnPingFail) {
				$data.Result = 1
                return [PSCustomObject]$data
            }
        }

        $data.Ping = $true

        if ($null -ne $Credential.Username) {
            [string] $commandString = "-u `"$($Credential.Username)`" -p `"$($Credential.GetNetworkCredential().Password)`" /accepteula $CustomPsExecParameters \\$ComputerName"
        }
        else {
            [string] $commandString = "-accepteula -h -nobanner $CustomPsExecParameters \\$ComputerName"
        }

        if($PSCmdlet.ParameterSetName -eq "Command"){
            $commandString += " cmd /c `"$Command`""
        }
        else{
            if($PSFile){
                $tempPSFile = $PSFile
            }
            else{
                #If the PowerShell code produces a base64-encoded string of a length greater than 260, you get 'Argument too long' [SIC] from PsExec. Use a temporary file that's created on the remote computer.
                $tempPSFile = [System.IO.Path]::GetTempFileName()
                $PsCommand | Out-File -LiteralPath $tempPSFile
            }

            #create a temp PS file on target server.
            $guid = [system.guid]::newguid()
            $encoded = [System.Convert]::ToBase64String($guid.ToByteArray()).Replace("/", "_").Replace("+", "-").Substring(0, 22)
            $targetFile  = "\\${ComputerName}\ADMIN`$\$encoded.ps1"

            Copy-Item -LiteralPath $tempPSFile -Destination $targetFile -ErrorAction Stop
            Remove-Item -LiteralPath $tempPSFile -Force -ErrorAction Continue
            $commandString += " cmd /c `"echo . | powershell.exe -ExecutionPolicy Bypass -File $Env:SystemRoot\$encoded.ps1`""
        }

        $tempStdOut = [System.IO.Path]::GetTempFileName()
        $tempStdErr = [System.IO.Path]::GetTempFileName()

        Write-Host "${ComputerName}: Running PsExec command."
        $result = Start-Process -FilePath $PsExecPath -ArgumentList $commandString -Wait -NoNewWindow -PassThru -RedirectStandardOutput $tempStdOut -RedirectStandardError $tempStdErr -ErrorAction Continue
        $data.Result = $result.ExitCode
        $data.StdOut = ((Get-Content -LiteralPath $tempStdOut) -join "`n")
        $data.StdErr = ((Get-Content -LiteralPath $tempStdErr) -join "`n")

        [PSCustomObject]$data
    }
    finally {
        if($tempStdOut){
            Remove-Item -LiteralPath $tempStdOut -Force -ErrorAction Continue
            Remove-Item -LiteralPath $tempStdErr -Force -ErrorAction Continue
        }

        if($tempPSFile){
            Remove-Item -LiteralPath $targetFile -ErrorAction Continue
        }
    }
}

function Write-File{
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$true,ValueFromPipeline=$True)][ValidateNotNull()][string[]]$Message,
	[Parameter(Mandatory=$true)][string]$Path
)
	BEGIN{
		if(!(Test-Path $Path)){
			New-Item -Path $Path -Type File -Force | Out-Null
		}
	}
	PROCESS{

		$Message | ForEach-Object {
			$_ >> $Path
		}
	}
}

function Open-File{
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$true)][string]$Path
)
	if(Test-Path $Path){
		$content = Get-Content $Path
		if($content){
			notepad $Path
		}
	}
}

function Test-IsAbsolutePath {
    Param (
        [Parameter(Mandatory=$True)]
        [string]$Path
    )

    [System.IO.Path]::IsPathRooted($Path)
}

function Select-Item {
<#
.SYNOPSIS
    Allows the user to select simple items, returns a number to indicate the selected item.
.DESCRIPTION
    Produces a list on the screen with a caption followed by a message, the options are then
    displayed one after the other, and the user can one.
.EXAMPLE
    PS> Select-Item -Caption "Configuring RemoteDesktop" -Message "Do you want to: " -ChoiceList "&Disable Remote Desktop",
        "&Enable Remote Desktop","&Cancel" -Default 1
    Will display the following

    Configuring RemoteDesktop
    Do you want to:
    [D] Disable Remote Desktop  [E] Enable Remote Desktop  [C] Cancel  [?] Help (default is "E"):

.PARAMETER Choicelist
    An array of strings, each one is possible choice. The hot key in each choice must be prefixed with an & sign
.PARAMETER Default
    The zero based item in the array which will be the default choice if the user hits enter.
.PARAMETER Caption
    The First line of text displayed
.PARAMETER Message
    The Second line of text displayed
#>
param(
	[string[]]$ChoiceList,
    [string]$Caption="Please make a selection",
    [string]$Message="Choices are presented below",
    [int]$Default=0
)

   $choicedesc = New-Object System.Collections.ObjectModel.Collection[System.Management.Automation.Host.ChoiceDescription]

   $ChoiceList | ForEach-Object  {
		$temp = New-Object System.Management.Automation.Host.ChoiceDescription ($_ -split ';')
   		$choicedesc.Add($temp)
	}

   $Host.ui.PromptForChoice($caption, $message, $choicedesc, $Default)
}

function Get-SystemVersionInfo {
[cmdletbinding()]
param(
	[string]$ExpectedVersion = "4.5.2",
	[string]$ExpectedPSVersion = "5.0"
)
	$temp = @{
		'Server' = $env:COMPUTERNAME;
		'ExitCode' = 0;
	}

	function Get-NetVersion{
		Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse |
		Get-ItemProperty -name Version,Release -EA 0 |
		Where-Object { $_.PSChildName -match '^(?!S)\p{L}'} |
		Select-Object PSChildName, Version, Release, @{
			name="Product"
			expression={
				switch -regex ($_.Release) {
					"378389" { [Version]"4.5.0" }
					"378675|378758" { [Version]"4.5.1" }
					"379893|379991" { [Version]"4.5.2" }
					"393295|393297" { [Version]"4.6.0" }
					"394254|394271" { [Version]"4.6.1" }
					"394802|394806" { [Version]"4.6.2" }
					"460798|460805" { [Version]"4.7.0" }
					"461308|461310" { [Version]"4.7.1" }
					"461808|461814" { [Version]"4.7.2" }
					{$_ -gt 461814} { [Version]"Undocumented 4.7.2 or higher, please update script" }
				}
			}
		} | Where-Object {$_.PSChildName -eq "Full"} | Select-Object -ExpandProperty Product
	}

	try{
		$netVersion = Get-NetVersion

        Write-Host "Determined .net version on $env:ComputerName to be $netVersion"
        $minVersion = [Version]$ExpectedVersion

		if($netVersion -lt $minVersion){
			Write-Warning ".net version $ExpectedVersion or later is not installed on server $env:ComputerName."
			$temp.ExitCode = 23
		}

		$psversion = $PSVersionTable.PSVersion

		Write-Host "Determined PowerShell version on $env:ComputerName to be $psversion"

		$minVersion = [Version]$ExpectedPSVersion
		if($psversion -lt $minVersion){
			Write-Warning "PowerShell version $ExpectedPSVersion is not installed on server $env:ComputerName."
			$temp.ExitCode = 24
		}
	}
	catch{
		Write-Warning "Problem trying to determine .Net and PowerShell versions on Computer $env:ComputerName."
		$temp.ExitCode = 20
	}

	[pscustomobject]$temp
}

function Initialize-RunspacePool{
param(
	[parameter(Mandatory=$true, Position=0)][int]$ThreadCount,
	[parameter()]
	[Alias('ModulesToLoad')][string[]]$ModulesToImport,
	[parameter()]
    [Alias('VariablesToLoad')][string[]]$VariablesToImport
)
	$sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

	if($PSBoundParameters['ModulesToImport']) {
        [void]$sessionState.ImportPSModule($ModulesToImport)
	}

	if($PSBoundParameters['VariablesToImport']) {
		$results = $VariablesToImport | ForEach-Object {
			if ($MyInvocation.CommandOrigin -eq 'Runspace') {
                $variable = Get-Variable $_ -ErrorAction Continue | Where-Object { $_.Options -notmatch 'Constant' }
			}
			else {
                $variable = $PSCmdlet.SessionState.PSVariable.Get($_)
			}

			New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $variable.Name, $variable.Value, $variable.Description
		}

		$results | ForEach-Object {
			$sessionState.Variables.Add($_)
		} | Out-Null
	}

	[RunspaceFactory]::CreateRunspacePool(1, $ThreadCount, $sessionState, $Host)
}

function Get-RunspaceData {
[cmdletbinding()]
param(
	[parameter(Mandatory=$true, Position=0)][System.Management.Automation.Runspaces.RunspacePool]$RunspacePool,
	[parameter(Mandatory=$true)][PSObject[]]$Tasks,
	[parameter(Mandatory=$true)][int]$TaskCount,
	[parameter(Mandatory=$true)][string]$Activity,
	$ErrorResult = $null,
	[switch]$NoProgress
)
	$retVal = 0

	if(Test-IsNullOrEmpty $Tasks){
		Write-Warning "No Tasks were passed for processing.  Returning."
		return $retVal
	}

	$completedCount = 0
	$counter = 1

	try{
		#loop through runspaces
		do {
			if(!$NoProgress){
				$counter+=1
				if($counter -gt 99){ $counter = 1 }

				$percentComplete = $(try{ $completedCount / $TaskCount * 100 } catch {0})
				Write-Progress -Id 0 -Activity $Activity -Status "Progress:" -PercentComplete $percentComplete
			}

			Start-Sleep -milliseconds 2000

			#run through each runspace.
            $temp = $Tasks | Where-Object { ($null -ne $_.AsyncResult) -and ($null -ne $_.Pipe -and $_.Pipe.InvocationStateInfo.State -ne 'NotRunning')  } | ForEach-Object {
				$task = $_
				$completed = 0

				#If runspace completed, end invoke, dispose, recycle
				if($task.AsyncResult.IsCompleted) {
					#check if there were errors
					if($task.Pipe.InvocationStateInfo.State -eq 'Failed'){
						Write-Error "Task on $($task.MachineName) completed with errors"
						Write-Error "InvocationState of pipe set to 'Failed'"
						Write-Error2 -ErrorRecord $job.Pipe.InvocationStateInfo.Reason.ErrorRecord
						$task.Result = $ErrorResult
					}
					elseif($task.Pipe.Streams.Error.Count -gt 0) {
						#this will capture any errors written to the error stream that
						#have not caused an exception to be thrown and captured. Also handles uncaught errors.
						Write-Error "Task on $($task.MachineName) completed with errors"
						Write-Error "One or more unhandled errors where written to the output error stream."
						$task.Pipe.Streams.Error | ForEach-Object {
							Write-Error2 -ErrorRecord $_
						} | Out-Null

						$task.Pipe.EndInvoke($task.AsyncResult)
						$task.Result = $ErrorResult
					}
					else{
						$item = $task.Pipe.EndInvoke($task.AsyncResult)[0]
						$task.Result = $item
					}

					$task.Pipe.Dispose()
					$task.AsyncResult = $null
					$task.Pipe = $null

					if(!$NoProgress){
						Write-Progress -Id $task.TaskId -ParentId 0 -Activity "Executing actions on target $($task.MachineName)" -Completed
					}

					$completed = 1
				}
				else{
					if(!$NoProgress){
						Write-Progress -Id $task.TaskId -ParentId 0 -Activity "Executing actions on target $($task.MachineName)" -PercentComplete ($counter)
					}
				}

				$completed
			}

			$completedCount += ($temp | Measure-Object -Sum).Sum

		#Loop again only if there are more runspaces to process
		} while ($completedCount -lt $TaskCount)

		if(!$NoProgress){
			Write-Progress -Id 0 -Activity $Activity -Completed
		}
	}
	finally{
		$RunspacePool.Close()
	}

	#return the Result property of the Task objects, and let caller handle results accordinlgy
	$Tasks | Select-Object -ExpandProperty 'Result'
}

function Get-ThreadCount{
param([int]$MachineCount,[switch]$SingleThreaded)

	if($SingleThreaded -or $MachineCount -eq 1){
		return 1
	}

	$procCount = [int]$env:NUMBER_OF_PROCESSORS

	#if we are on a machine with a large number of cores, we will limit otherwise logging can get messy
	if($procCount -gt 4){
		$procCount = 4
	}

	$procCount = $procCount * 3

	($MachineCount -gt $procCount) | Get-ConditionalValue -TrueValue $procCount -FalseValue $MachineCount
}

function Get-DriveInfo {
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$true)] [string[]]$ComputerName,
	[Parameter(Mandatory=$false)] [string[]]$Drive = @("C","D")
	)

	$func = {
		param([string[]]$drives)
		$temp = @{
			'Server' = $env:COMPUTERNAME;
			'ExitCode' = 0
		}

		try{
			$temp.DriveData = Get-PSDrive $drives
		}
		catch{
			$temp.ExitCode = 1
			$temp.Error = "Error accessing the drive data on server: $_"
			$temp.ErrorDetail = $_
		}

		[pscustomobject]$temp
	}

	try{
		$sessions = $ComputerName | New-PSsession
		$output = Invoke-Command -Session $sessions -ScriptBlock $func -ArgumentList (,$Drive)
	}
	finally{
		Remove-PSSession $sessions -ErrorAction Continue
	}

	$output
}

function ConvertTo-ArrayArgument{
param([string[]]$Source, [string]$Argument)
	$value = (Test-IsNotNullOrEmpty $Source) | Get-ConditionalValue -TrueValue {"$Argument @('{0}')" -f ($Source -join "','")} -FalseValue ""
	$value
}

function Get-ClonedObject([Psobject]$InputObject){
	$retVal = New-Object PsObject
	$InputObject.psobject.properties | ForEach-Object {
		$retVal | Add-Member -MemberType $_.MemberType -Name $_.Name -Value $_.Value
	}

	$retVal
}

function Add-XmlAttribute {
param ([System.Xml.XmlNode] $Node, [string]$Name, [string]$Value)

  $attrib = $Node.OwnerDocument.CreateAttribute($Name)
  $attrib.Value = $Value
  $node.Attributes.Append($attrib)
}

function Import-PfxCertificate{
param(
    [Parameter(Mandatory = $true)]
    [string]$CertPath,
    [string]$CertRootStore = "localmachine",
    [string]$CertStore = "My",
	[string]$X509Flags = "Exportable,PersistKeySet",
    $PfxPass = $null
)

	$pfx = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2

	if ($null -eq $PfxPass) {
		$pfxPass = Read-Host "Password" -AsSecureString
	}

	$pfx.Import($CertPath, $PfxPass, $X509Flags)

	$store = New-Object System.Security.Cryptography.X509Certificates.X509Store($CertStore, $CertRootStore)
	$store.Open("MaxAllowed")
	$store.Add($pfx)
	$store.Close()
	Remove-Item -LiteralPath $CertPath
}
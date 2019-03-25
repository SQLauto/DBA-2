   
param
(
    [string] $MachineName, 
    [string] $MachineIP,
    [string] $RigName,
    [string] $OutputDir,
    [bool] $AreEventLogsToBeCollected = $true,
	[string] $DriveLetter = "D"
) 
function main
{    
    $exitcode = 0    
               
    try
    {
	    $MachineDir = Join-Path $OutputDir $MachineName
        $driveName = $MachineName
        $LabUser = "FAELAB\TFSBuild"
        $LabPass = "LMTF`$Bu1ld"
        $LabSecPass = ConvertTo-SecureString $LabPass -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential($LabUser, $LabSecPass)  
    
        Write-Output "Getting logs from Machine Name: [$MachineName] Machine IP [$MachineIP]"
        
        if(!(Test-Path $MachineDir))
        {
            Write-Output "Creating Output Directory $MachineDir"
            New-Item -Path $MachineDir -ItemType Directory | Out-Null
        }
        else
        {
            Write-Output "Output Directory $MachineDir already exists"
        }
	
	    New-PSDrive -Name $driveName -PSProvider FileSystem -Root \\$MachineIP\$DriveLetter$ -Credential $Credential
        $driveRoot = $driveName + ":\"
	    if(Test-Path $driveRoot)
        {
            $LogFiles = Get-ChildItem -Path $driveRoot\TFL -Filter "*.log" -Recurse

            foreach ($LogFile in $LogFiles)
            {
                $DestTemp = $LogFile.FullName
                $pos = $DestTemp.IndexOf("\Tfl\", [System.StringComparison]::CurrentCultureIgnoreCase) + 4
                $DestTemp = $DestTemp.Substring($pos, ($DestTemp.Length - $pos))
                $DestTemp = [System.IO.Path]::GetDirectoryName($DestTemp)
                $Destination = Join-Path $MachineDir $DestTemp

                if(!(Test-Path $Destination))
                {
                    Write-Output "Creating New Directory $Destination"
                    New-Item -Path $Destination -ItemType Directory | Out-Null
                }

                $logFileFullName = $LogFile.FullName
                Write-Output "Copying $logFileFullName to $Destination"
		        Copy-Item -Path $logFileFullName -Destination $Destination -Force | Out-Null
		    }
	    }
	    else
	    {
	        Write-Warning "Unable to locate drive D: on $machineName, skipping machine $machineName"
	    }

        Remove-PSDrive -Name $driveName
	    if ($AreEventLogsToBeCollected)
        {
	        foreach ($EventLogFileToRead in Get-EventLog -ComputerName $MachineIP -List)
	        {
                $logName = $EventLogFileToRead.LogDisplayName

                if ($logName -ne "Operations Manager")
                {
	                $EventLogFile = "$MachineDir\" + ($logName) + ".log"
    	            if(!(Test-Path $EventLogFile))
		            {
	    	            Write-Output "Creating New File $EventLogFile"
			            New-Item -Path $EventLogFile -ItemType File | Out-Null
		            }
			
		            $EventLogFileToRead >> $EventLogFile
		            "" >> $EventLogFile
		            "" >> $EventLogFile
		            "Time|Event ID|Event Type|Machine|Source|Message" >> $EventLogFile
		            foreach($Entry in $EventLogFileToRead.Entries)
		            {
		                $msg = ($Entry.TimeGenerated.ToString()) + "|" + ($Entry.EventID) + "|" + ($Entry.EntryType) + "|" + ($Entry.MachineName) + "|" + ($Entry.Source) + "|" + ($Entry.Message)
		                $msg >> $EventLogFile
		            }
                }
            }
        }

    }
    catch [System.Exception]
    {
        $exitcode = 6

        Write-Output $error
    }

    Write-Output "Exit Code on $MachineName was: $exitCode"

    exit $exitCode
}

#execute the main function
main
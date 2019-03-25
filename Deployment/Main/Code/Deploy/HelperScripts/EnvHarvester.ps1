param
(
    [string]$RigRelativePath = "Integration.TSRig.VC.xml",
	[string]$DriveLetter = "D",
    [string]$OutputDir = "$($DriveLetter):\EnvironmentConfigs"
)

function main
{
  try
  {
    if(!(Test-Path $OutputDir))
    {
		Write-Output "Creating Output Directory $OutputDir"
        New-Item -Path $OutputDir -ItemType Directory | Out-Null
    }
	else
	{
		Write-Output "Output Directory $OutputDir already exists"
	}

	Write-Output "Trying to read deployment config file $RigRelativePath"
    $scriptpath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)  
    $scriptpath = join-path $scriptpath "\..\Scripts"
    $RigXMLPath = join-path $scriptpath $RigRelativePath;    
    if(Test-Path $RigXMLPath)
    {
        [xml]$RigData = (Get-Content $RigXMLPath); # Read a deployment config file 
    }    
    else
    {
        Write-Error "TERMINATING; Cannot find config file $RigXMLPath"
        Exit 1;
    }   
   
    # For each machine (presuming that D:\TFL\ is always the install folder)
    # Find all folders that contain *.config
    foreach($machine in $RigData.configuration.machine)
    {
        $machineName = $machine.Name
        $MachineDir = join-path $OutputDir $machineName
       
		if(Test-Path \\$machineName\$DriveLetter$)
		{

			# search for *.config files        
			$ConfigFiles = Get-ChildItem -Path \\$machineName\$DriveLetter$\Tfl -Filter "*.config" -Recurse

			foreach($configFile in $ConfigFiles)
			{

				# create a destination directorty structure same as the source directory 
			   $DestTemp = $configFile.FullName 
			   $pos = $DestTemp.IndexOf("\Tfl\") + 4 # integer value to determine the start position for sub-string
			   $DestTemp = $DestTemp.Substring($pos, ($DestTemp.Length - $pos))
			   $DestTemp = [system.io.path]::GetDirectoryName($DestTemp)  # Get Directory
			   $Destination =  join-path $MachineDir $DestTemp

				if(!(Test-Path $Destination))
				{
					New-Item -Path $Destination -ItemType Directory
				}

				#copy to destination folder D:\EnvironmentConfigs\$machineName
				Copy-Item -Path $configFile.FullName -Destination $Destination -Force
			}
		}
		else
		{
			Write-Warning "Unable to locate drive D: on $machineName, skipping machine $machineName"
		}
    }
  }
  catch [System.Exception]
  {
    $error = $_.Exception.ToString()
    Write-Error "$error"
    exit 1
  }
}
main


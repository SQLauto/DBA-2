<#
	This script is used to copy all MaximumJourneyTime Assets 
	& selective Fare Assets
#>
$pathToCommonDeltasConfig = "..\Code\Deploy\Scripts\CommonMJTDeltasRole.xml"
$destinationRoot = "D:\FMJTAssets\"

function CopyMasterDataAssets {
		if (Test-Path $destinationRoot){
			Remove-Item -Recurse -Force $destinationRoot
		}		
		CopyMjtFiles
		CopyFareFiles 
}

function CopyMjtFiles { 
		
        [xml]$fileContents = Get-Content $pathToCommonDeltasConfig	
		$mjtXml = $fileContents.configuration.CommonRoles.ServerRole | where {$_.Include -eq "MasterData.MJTService.Assets.Last13Weeks"}		
		$mjtXml.CopyAssets.Daykeys.Split(',') | ForEach {
            Write-Host "Copying mjt assets under daykey" $_.Trim()
			CopyAssets -serviceName "Mjt" -clientName "ftp" -dayKey $_.Trim()
    }
}

function CopyFareFiles { 
		[xml]$fileContents = Get-Content $pathToCommonDeltasConfig	
				$faresXml = $fileContents.configuration.CommonRoles.ServerRole | where {$_.Include -eq "MasterData.FareService.Assets.Last13Weeks"}		
		$faresXml.CopyAssets.Daykeys.Split(',') | ForEach {
            Write-Host "Copying fare assets under daykey" $_.Trim()
			CopyAssets -serviceName "Fares" -clientName "ftp" -dayKey $_.Trim()
    }
}

function CopyAssets {
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True)]
		[string]$serviceName, 
		[Parameter(Mandatory=$True)]
		[string]$clientName,
		[string]$dayKey
	)

	$dataSuffix = "Data"
	$masterDataAssetsFilePath = "..\..\..\MasterData\Main\Code\MasterDataV2\MasterData.Deploy\Assets\" + $serviceName + $dataSuffix + "\" + $clientName
	
	if ($dayKey -eq $null -or $dayKey -eq ""){
		$dayKey="*"
		$fullPath = $masterDataAssetsFilePath + "\" + $dayKey
		$destination = $destinationRoot + $serviceName + $dataSuffix + "\" + $clientName + "\"	
	}
	else
	{
		$fullPath = $masterDataAssetsFilePath + "\" + $dayKey + "\*" 
		$destination = $destinationRoot + $serviceName + $dataSuffix + "\" + $clientName + "\"	+ $dayKey
	}	
	
	#Oddity in Copy-Item module, requires leaf to exist as I can't get -Container switch to work
	if (-Not(Test-Path $destination))
	{
		New-Item $destination -type directory
	}
	
	Write-Host "Copying " $fullPath " to " $destination
	Copy-Item $fullPath $destination -recurse -force
}


CopyMasterDataAssets
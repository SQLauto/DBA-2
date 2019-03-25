param
(
	[switch] $All,
	[switch] $SBOnly,
	[switch] $SB,

	[string] $Branch = "Stabilisation",
	
	[string] $FAE,
	[string] $PARE,
	[string] $CACC,
	[string] $Notifications,
	[string] $SDM,
	[string] $MasterData,
    [string] $OyBO
)

begin
{
	[System.Collections.ArrayList] $deploy = @('FAE', 'PARE', 'CACC', 'Notifications', 'SDM', 'MasterData', 'OyBO')
	$zeroDeployPath = (Get-ChildItem Env:ZeroDeployPath).Value
	
	Import-Module .\SetupZeroDeployFromCI-Functions.psm1 -Force
}

process
{
	Clear-Host
	Write-Host "Script root is:" $PSScriptRoot
	
	If ($PSBoundParameters.ContainsKey('SBOnly'))
	{
		Install-ServiceBus -setupServiceBus $True	
		exit
	}
	
	If ($PSBoundParameters.ContainsKey('SB'))
	{
		Install-ServiceBus -setupServiceBus $True	
	}

	# Validate parameters
	If (-Not $PSBoundParameters.ContainsKey('ALL')) 
	{
		if (-Not $FAE -And -Not $PARE -And -Not $CACC -And -Not $Notifications -And -Not $SDM -And -Not $MasterData -And -Not $OyBO)
		{
			throw("Must specify a component to install")
		}
	}

	Write-Host "Setting up Zero Deploy FTP from latest CI builds..."
	$program = ".\LocalRigSetup.cmd"
	Invoke-Command -ScriptBlock { & $program }
	
	If ($FAE)
	{
		$deploy.Remove("FAE")
		
		$project = "FAE"
		$path = Join-Path -Path $zeroDeployPath $project
		$buildName = $project + "." + $FAE + ".CI"
		Get-LatestCiBuild -projectName $project -buildName $buildName -targetFolder $path
    
		$databaseToDeply = @("FAE")
		Set-Location $PSScriptRoot
		& .\Deploy-CI-Databases.ps1 -databasesToDeploy $databaseToDeply
	}

	If ($PARE)
	{
		$deploy.Remove("PARE")
		
		$project = "PARE"
		$path = Join-Path -Path $zeroDeployPath $project
		$buildName = $project + "." + $PARE + ".CI"
		Get-LatestCiBuild -projectName $project -buildName $buildName -targetFolder $path

		$databaseToDeply = @("PARE")
		Set-Location $PSScriptRoot
		& .\Deploy-CI-Databases.ps1 -databasesToDeploy @("PARE");
	}

	If ($CACC)
	{
		$deploy.Remove("CACC")
		
		$project = "CACC"
		$path = Join-Path -Path $zeroDeployPath $project
		$buildName = $project + "." + $CACC + ".CI"
		Get-LatestCiBuild -projectName $project -buildName $buildName -targetFolder $path

		$databaseToDeply = @("CACC")
		Set-Location $PSScriptRoot
		& .\Deploy-CI-Databases.ps1 -databasesToDeploy $databaseToDeply
	} 

	If ($Notifications)
	{
		$deploy.Remove("Notifications")
		
		$project = "Notifications"
		$path = Join-Path -Path $zeroDeployPath $project
		$buildName = $project + "." + $Notifications + ".CI"
		Get-LatestCiBuild -projectName $project -buildName $buildName -targetFolder $path

		$databaseToDeply = @("Notifications")
		Set-Location $PSScriptRoot
		& .\Deploy-CI-Databases.ps1 -databasesToDeploy $databaseToDeply
	} 
	
	If ($SDM)
	{
		$deploy.Remove("SDM")
		
		$project = "SDM"
		$path = Join-Path -Path $zeroDeployPath $project
		$buildName = $project + "." + $SDM + ".CI"
		Get-LatestCiBuild -projectName $project -buildName $buildName -targetFolder $path

		$databaseToDeply = @("SDM")
		Set-Location $PSScriptRoot
		& .\Deploy-CI-Databases.ps1 -databasesToDeploy $databaseToDeply
	} 
	
	If ($MasterData)
	{
		$deploy.Remove("MasterData")
		
		$project = "MasterData"
		$path = Join-Path -Path $zeroDeployPath $project
		$buildName = $project + "." + $MasterData + ".CI"
		Get-LatestCiBuild -projectName $project -buildName $buildName -targetFolder $path

		$databaseToDeply = @("MasterData")
		Set-Location $PSScriptRoot
		& .\Deploy-CI-Databases.ps1 -databasesToDeploy $databaseToDeply
	}

	If ($OyBO)
	{
		$deploy.Remove("OyBO")
		
		$project = "OyBO"
		$path = Join-Path -Path $zeroDeployPath $project
		$buildName = $project + "." + $OyBO + ".CI"
		Get-LatestCiBuild -projectName $project -buildName $buildName -targetFolder $path

		$databaseToDeply = @("OyBO")
		Set-Location $PSScriptRoot
		& .\Deploy-CI-Databases.ps1 -databasesToDeploy $databaseToDeply
	}

	If ($PSBoundParameters.ContainsKey('ALL')) 
	{
		foreach($component in $deploy)
		{
			$project = $component
			$path = Join-Path -Path $zeroDeployPath $project
			$buildName = $project + "." + $Branch + ".CI"
			Get-LatestCiBuild -projectName $project -buildName $buildName -targetFolder $path
		}

		if ($deploy.Count -ne 0)
		{
			Set-Location $PSScriptRoot
			& .\Deploy-CI-Databases.ps1 -databasesToDeploy $deploy
		}
	}
	
	& .\ConfigureZeroDeployForCI.ps1
	
	Install-EngineHost -zeroDeployPath $zeroDeployPath
}
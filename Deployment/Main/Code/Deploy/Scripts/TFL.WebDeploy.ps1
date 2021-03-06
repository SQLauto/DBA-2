[cmdletbinding()]
param
(
    [parameter(Mandatory=$true)][string] $ComputerName,
    [Deployment.Domain.Roles.WebDeploy]$DeployRole
)

function Assert-ConfigOnly{
[cmdletbinding()]
param()

	# Checking Website Version for Config Only Deployment
    # Website and DLL To Version from match version number assuming it's the same package
    # If not terminate the role and fail deployment
    if($ConfigOnly)
    {
        $registrypath = "HKLM:\$($DeployRole.RegistryKey)\$($DeployRole.Name)"

        $currentVersion = Get-RegistryKeyProperty -ComputerName $ComputerName -Path $registrypath -PropertyName 'Version'
        $packageName = $DeployRole.Package.Name

		$packageFolderName = $packageName + "_Package"

        $packageFolderPath = Join-Path (Join-Path $dropFolder _PublishedWebsites) "$packageFolderName"
		$packagePath = Join-Path $packageFolderPath "$packageName.zip"
        $newVersion = Get-WebPackageVersion -PackagePath $packagePath -AssemblyName $DeployRole.AssemblyToVersionFrom

        if($currentVersion -ne $newVersion) {
			throw "Package Version does not match Current Version. Config Only deploy is exiting due to version mismatch"
        }
    }
}

function Start-AppPoolDeploy {
[cmdletbinding()]
param()

	if($ConfigOnly -or !$DeployRole.AppPool){
		return 0
	}

	Write-Host "Setting up and configuring AppPool settings."
	$subScriptPath = Join-Path $PSScriptRoot Tfl.WebDeploy.AppPool.ps1

	if($DeployRole.AppPool.ServiceAccount -inotin "NetworkService","ApplicationPoolIdentity"){
		$serviceAccount = Get-ServiceAccount -Path $accountsFile -Account $DeployRole.AppPool.ServiceAccount -Password $Password
		$accountPW = $serviceAccount.DecryptedPassword
		$accountUser = $serviceAccount.QualifiedUsername
	}

	if ($local) {
		$output = & $subScriptPath -DeployRoleXml $deployXml -AccountUser $accountUser -AccountPassword $accountPW
	}
	else {
		$output = Invoke-Command -ComputerName $ComputerName -FilePath $subScriptPath -ArgumentList $deployXml,$accountUser,$accountPW
	}

    if ($output.ExitCode -eq 0) {
        Write-Host2 -Type Success -Message "App Pool setup on $ComputerName"
    }
    else {
		if($temp.ErrorDetail){
			Write-Error2 -ErrorRecord $temp.ErrorDetail -ErrorMessage $temp.Error
		}
		else{
			Write-Error2 $temp.Error
		}

        Write-Host2 -Type Failure -Message "Failed to setup app pools on $ComputerName"
    }

	$output.ExitCode
}

function Start-WebSiteDeploy {
[cmdletbinding()]
param()

	$retVal

	if (!$DeployRole.Site) 	{
		return 0
	}

	Write-Host "Setting up and configuring WebSite settings."
	# 2.1) Create Physical Path
	$targetPath = $DeployRole.Site.PhysicalPath

	if (!$local) {
		$targetPath = "\\$ComputerName\" + ($targetPath -replace "$($DriveLetter):","$DriveLetter`$")
	}

	if(!(Test-Path $targetPath)){
		Write-Host "Creating directory $targetPath"
		New-Item -Path $targetPath -ItemType directory | Out-Null
	}

	$subScriptPath = Join-Path $PSScriptRoot "Tfl.WebDeploy.WebSite.ps1"

	if ($local) {
		$output = & $subScriptPath -DeployRoleXml $deployXml
	}
	else {
		$output = Invoke-Command -ComputerName $ComputerName -FilePath $subScriptPath -ArgumentList $deployXml
	}

	if ($output.ExitCode -eq 0) {
        Write-Host2 -Type Success -Message "App Pool setup on $ComputerName"
    }
    else {
		if($temp.ErrorDetail){
			Write-Error2 -ErrorRecord $temp.ErrorDetail -ErrorMessage $temp.Error
		}
		else{
			Write-Error2 $temp.Error
		}

        Write-Host2 -Type Failure -Message "Failed to complete WebSite deploy on $ComputerName"
	}

	$output.ExitCode
}

function Start-InstallDeployPackage{
[cmdletbinding()]
param()

	# 3) Deploy Package
    if (!$DeployRole.Package) {
		return 0
	}

	$configToDeploy = $DeployRole.Configuration

	Write-Host "Deploying WebDeploy package."

	$packageName = $DeployRole.Package.Name

	$packageFolderPath = Join-Path $dropFolder (Join-Path "_PublishedWebsites" "$($packageName)_Package")

	$targetPath = $local | Get-ConditionalValue -TrueValue "$($DriveLetter):\Deployment\$($packageName)" -FalseValue "\\$ComputerName\$DriveLetter`$\Deployment\$($packageName)"

	#Copy package to target server
	if (Test-Path $targetPath) {
		Write-Host "Removing existing path '$targetPath'"
		Remove-Item $targetPath -Recurse -Force
	}

	Write-Host "Copying deployment package to target '$targetPath'"
	$success = Copy-ItemRobust -Path $packageFolderPath -TargetPath "$targetPath"

	if(-not $success){
		Write-Host2 -Type Failure -Message "Problem copying web deployment package files to target machine $ComputerName, exited with error code $exitCode."
		return 1
	}

	# Update the set parameters file to deploy to the specified website - make sure all updates to the webdeploy package are done on the target server
	# not on the deployment server - this is eliminate any contention with files in the deployment package when doing multi threaded deployments
	if($DeployRole.Site) {

		$params = @{
			DefaultConfig = $baseConfig
			OverrideConfig = $configToDeploy
			PackagePath = $targetPath
			DropFolder = $dropFolder
			PackageName = $PackageName
			SiteName = $DeployRole.Site.Name
			Environment = $Environment
			RigName = $RigName
			RigConfigFile = $RigConfigFile
		}

		Write-Host "Updating site parameters file."
		$success = Update-WebParametersFile @params

		if(-not $success){
			Write-Host2 -Type Failure -Message "Problem updating Web parameters file."
			return 1
		}
	}

	Write-Host "Deploying package $packageName"
	$installLog = "$($DriveLetter):\Deployment\WebDeploy.$packageName.$configToDeploy.log"

	$func = {
		param([string]$PackageName,[string]$LogPath, [string]$DriveLetter)

		$temp = @{
			'Server' = $env:COMPUTERNAME;
			'ExitCode' = 0
		}

		try{
			$cmdFile = "$($DriveLetter):\Deployment\$packageName\$packageName.deploy.cmd"
			#$edited = $false

			$contents = Get-Content $cmdFile

			$contents | ForEach-Object {
				#if (!$edited -and $_ -eq "goto :eof"){ # add before
				if($_ -eq "goto :eof"){
					"if %errorlevel% neq 0 exit %errorlevel%"
				#	$edited = $true
				}
				$_ # write original line
			} | Set-Content $cmdFile

			$command = "cmd /c `"$cmdFile`" /Y 2>&1> `"$LogPath`""

			Write-Host "Executing command: '$command'"
			Invoke-Expression -Command $command -ErrorAction Stop | Out-Null

            if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
                throw "Deploying web package $packageName on $env:COMPUTERNAME with last exit code of [$LASTEXITCODE]"
            }
		}
		catch{
			$temp.ExitCode = 1
			$temp.Error = "An error occurred during Start-InstallDeployPackage. LastExitCode: $LASTEXITCODE"
			$temp.ErrorDetail = $_
			$global:LASTEXITCODE = $null
		}

		[pscustomobject]$temp
	}

    if ($local) {
        $output = & $func -PackageName $packageName -LogPath $installLog -DriveLetter $DriveLetter
    }
    else {
        $output = Invoke-Command -ComputerName $ComputerName -ScriptBlock $func -ArgumentList $packageName, $installLog, $DriveLetter
	}

	if ($output.ExitCode -eq 0) {
        Write-Host2 -Type Success -Message "WebDeploy completed successfully. See $installLog on $ComputerName"
    }
    else {
		if($temp.ErrorDetail){
			Write-Error2 -ErrorRecord $temp.ErrorDetail -ErrorMessage $temp.Error
		}
		else{
			Write-Error2 $temp.Error
		}

		Write-Host2 -Type Failure -Message "WebDeploy failed on machine $ComputerName, exited with error code $($output.ExitCode). See $installLog on $ComputerName"
	}

	$output.ExitCode
}

function Update-RegistryInfo{
[cmdletbinding()]
param()

	$retVal = 0

	if($ConfigOnly -or ($null -eq $DeployRole.Site)){
		return $retVal
	}

	# 4) Update registry
	$registrypath = $registrypath = "HKLM:\$($DeployRole.RegistryKey)\$($DeployRole.Name)"
	Write-Host "Updating registry settings in $registrypath"

	# Determine the physical path of the website
	$siteName = $DeployRole.Site.Name

	if($DeployRole.Site.Application) {
		$siteName += "\" + $DeployRole.Site.Application.Name
	}

	$physicalPath = $DeployRole.Site.PhysicalPath

	# Determine the version number
	$version = "n\a"

	$assemblyName = $DeployRole.AssemblyToVersionFrom

	if($assemblyName) {
		$targetPath = $physicalPath
		if (!$local) {
			$targetPath = "\\$ComputerName\" + ($targetPath -replace "$($DriveLetter):","$DriveLetter`$")
		}

		$assemblyPath = Join-Path "$targetPath" "bin\$assemblyName"

		if(Test-Path $assemblyPath) {
			Write-Host "Checking VersionInfo of assembly: $assemblyPath"

			$versionInfo = [Reflection.Assembly]::UnsafeLoadFrom($assemblyPath).GetName().Version
			$version = "$($versionInfo.Major).$($versionInfo.Minor).$($versionInfo.Build).$($versionInfo.Revision)"
			Write-Host "Assembly version: $version"
		}
		else {
			Write-Host2 -Type Failure -Message "Assembly $assemblyPath cannot be found on [$ComputerName]. Version set to $version"
			$retVal = 1
		}

		# 4.1) Hack away: Due to an bug in the .Net framework, references to custom behaviour extensions need to use the explicit assembly version number
		$webConfigFile = Join-Path $targetPath "web.config"

        $token = "Token_TFLAssemblyVersion"
        $matches = Select-String -Simple $token $webConfigFile

		if($matches)
        {
			Write-Host "Replacing $token with $version in $webConfigFile"

			$file = Get-Item $webConfigFile
			if ($file.IsReadOnly) {
  				$file.IsReadOnly = $false
			}

			(Get-Content $webConfigFile) -replace $token, $version | Set-Content $webConfigFile
        }
	}

	Set-RegistryKeyProperty -ComputerName $ComputerName -Path $registrypath -PropertyName 'Version' -PropertyValue $version | Out-Null
	Set-RegistryKeyProperty -ComputerName $ComputerName -Path $registrypath -PropertyName 'SiteName' -PropertyValue $siteName | Out-Null

	$retVal
}

function Start-CleanUp{
[cmdletbinding()]
param()
	$retVal = 0

	$targetPath = $DeployRole.Site.PhysicalPath

	if (!$local) {
		$targetPath = "\\$ComputerName\" + ($targetPath -replace "$($DriveLetter):","$DriveLetter`$")
	}

	$originalFile = Join-Path $targetPath "web.config.original"
	 # 6) Remove old copies of web.config.original
    if (Test-Path $originalFile) {
        Write-Host "Removing old .original web config file."
		Remove-Item $originalFile -Force -Recurse
    }

	# 7) Remove configuration parameters folder and parameters.xml
    $path = Join-Path $targetPath "ConfigurationParameters"
	if (Test-Path ($path)) {
        Write-Host "Deleting folder $path"
		Remove-Item $path -Recurse -Force;
    }

	$path = Join-Path $targetPath "bin\ConfigurationParameters"
	if (Test-Path ($path)) {
        Write-Host "Deleting folder $path"
		Remove-Item $path -Recurse -Force;
    }

	$parametersXml = Join-Path $targetPath "parameters.xml"
	if (Test-Path ($parametersXml))  {
        Write-Host "Deleting $parametersXml"
		Remove-Item $parametersXml -Force;
    }

	$retVal
}

function Protect-WebConfig{
[cmdletbinding()]
param()

	if($ConfigOnly){
		return 0
	}

	$sections = $DeployRole.ConfigurationEncryption.Section

	$func = {
		param([string]$TargetPath, [string[]]$Section)

		$temp = @{
			'Server' = $env:COMPUTERNAME;
			'ExitCode' = 0
		}

		try{
			$Section | ForEach-Object {
				Write-Host "Encrypting web.config section $_"

				$command = "cmd /c C:\windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe -pef $_ `"$TargetPath`""
				Write-Host "Executing command: '$command'"
				Invoke-Expression -Command $command -ErrorAction Stop | Out-Null
			}

			if($LASTEXITCODE -and $LASTEXITCODE -ne 0){
				throw "Using aspnet_regiis to encrypt config on [$($env:COMPUTERNAME)] had last exit code of [$LASTEXITCODE]"
			}
		}
		catch{
			$temp.ExitCode = 1
			$temp.Error = "An error occurred in Protect-WebConfig. LastExitCode: $LASTEXITCODE"
			$temp.ErrorDetail = $_
			$global:LASTEXITCODE = $null
		}

		[pscustomobject]$temp
	}

	if ($local) {
		$output = & $func -TargetPath $DeployRole.Site.PhysicalPath -Section $sections
	}
	else {
		$output = Invoke-Command -ComputerName $ComputerName -ScriptBlock $func -ArgumentList $DeployRole.Site.PhysicalPath,$sections
	}

	if ($output.ExitCode -eq 0) {
        Write-Host2 -Type Success -Message "Protect-WebConfig completed successfully. See $installLog on $ComputerName"
    }
    else {
		if($temp.ErrorDetail){
			Write-Error2 -ErrorRecord $temp.ErrorDetail -ErrorMessage $temp.Error
		}
		else{
			Write-Error2 $temp.Error
		}

		Write-Host2 -Type Failure -Message "Protect-WebConfig failed on machine $ComputerName, exited with error."
	}

	$output.ExitCode
}

function Start-WebSites{
[cmdletbinding()]
param()

	# 8) Start App pool.
	if (!$startupSites){
		Write-Host "Not starting Website and App Pools automatically for production deployments."
		return 0
	}

	$func = {
		param([string]$SiteName, [string]$PoolName)

		Import-Module TFL.Deployment.Web

		$temp = @{
			'Server' = $env:COMPUTERNAME;
			'ExitCode' = 0
		}

		try{
			Start-WebsiteAndAppPool $SiteName $PoolName
		}
		catch{
			$temp.Error = "An error has occured in Start-WebSite"
			$temp.ExitCode = 1
			$temp.ErrorDetail = $_
		}

		[pscustomobject]$temp
	}

	Write-Host "Starting Websites and App Pools automatically following successful deployment."

    if ($local) {
        $output = & $func -SiteName $DeployRole.Site.Name -PoolName $DeployRole.AppPool.Name
    }
    else {
        $output = Invoke-Command -ComputerName $ComputerName -ScriptBlock $func -ArgumentList $DeployRole.Site.Name, $DeployRole.AppPool.Name
    }

	if ($output.ExitCode -eq 0) {
        Write-Host2 -Type Failure -Message "Failed to start Website and/or AppPool on $ComputerName"
    }
    else {
		if($temp.ErrorDetail){
			Write-Error2 -ErrorRecord $temp.ErrorDetail -ErrorMessage $temp.Error
		}
		else{
			Write-Error2 $temp.Error
		}

		Write-Host2 -Type Failure -Message "Protect-WebConfig failed on machine $ComputerName, exited with error."
	}

	$output.ExitCode
}

$result = 0

$startupSites = $false

$local = $ComputerName -in $env:computername,"localhost"

Write-Host ""
Write-Header "Starting role $DeployRole on $ComputerName." -AsSubHeader
$timer = [Diagnostics.Stopwatch]::StartNew()

try
{
	if(Assert-IsDevEnvironment $Environment) {
		Write-Host "Deployment on to virtual environment, Application Pools and Sites will be started after creation..."
		$startupSites = $true
	}

	Assert-ConfigOnly

	$deployXml = ConvertTo-DeployRoleXml $DeployRole

	$functions = @(
		{Start-AppPoolDeploy}
		{Start-WebSiteDeploy}
		{Start-InstallDeployPackage}
		{Update-RegistryInfo}
		{Protect-WebConfig}
        {Start-CleanUp}
		{Start-WebSites}
	)

	$result = Invoke-UntilFail $functions
}
catch [System.Exception] {
	$result = 1
	Write-Error2 -ErrorRecord $_
}

$timer.Stop()

$type = ""
if($ConfigOnly) {
	$type = "(ConfigOnly)"
}

$SummaryLog | Write-Summary -Message "running role $DeployRole $type on $ComputerName."  -Elapsed $timer.Elapsed -ScriptResult $result
Write-Header "Ending role $DeployRole $type on $ComputerName" -AsSubHeader

$result
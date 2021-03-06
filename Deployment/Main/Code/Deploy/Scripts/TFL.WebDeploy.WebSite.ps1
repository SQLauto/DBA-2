#requires -Version 5.0
[cmdletbinding()]
param(
	[parameter(Mandatory=$true)]
	[ValidateNotNull()][string]$DeployRoleXml
)

$temp = @{
	'Server' = $env:COMPUTERNAME;
	'ExitCode' = 0;
}

try {
    Set-ExecutionPolicy Unrestricted
	Import-Module TFL.Deployment.Web -Force -ErrorAction Stop

	$deployRole = $DeployRoleXml | ConvertFrom-DeployRoleXml -Type Deployment.Domain.Roles.WebDeploy

	$site = $deployRole.Site
	$appPool = $deployRole.AppPool

	$siteName = $site.Name
	$sitePath = "IIS:\\Sites\$siteName"

	Write-Host "Site: $siteName"
	Write-Host "Port: $($site.Port)"
	Write-Host "Path: $($site.PhysicalPath)"
	Write-Host "Pool: $($appPool.Name)"

	if (!(Test-Path $sitePath)){
		Write-Host "Creating WebSite '$siteName'"
		New-WebSite -Name $siteName -Port $site.Port -PhysicalPath $site.PhysicalPath -ApplicationPool $appPool.Name -Force | Out-Null
	}
	else{
		$currentId = Get-Item $sitePath | Select-Object -ExpandProperty Id

		if($currentId -eq 1){
			Write-Host "Recreating vanilla Default Web Site"
			New-WebSite -Name $siteName -Port $site.Port -PhysicalPath $site.PhysicalPath -ApplicationPool $appPool.Name -Force | Out-Null
		}
		else {
			Write-Host "Setting existing site properties"
			Set-ItemProperty $sitePath -Name physicalPath -Value $site.PhysicalPath -Force
			Set-ItemProperty $sitePath -Name applicationPool -Value $appPool.Name -Force

			Get-WebBinding -Name $siteName -Protocol "http" | ForEach-Object { Set-WebBinding -Name $siteName -BindingInformation $_.bindingInformation -PropertyName "Port" -Value $site.Port | Out-Null }

			#temp testing. Seems to be an issue updating a vanilla default web site.
			#New-WebSite -Name $siteName -Port $site.Port -PhysicalPath $site.PhysicalPath -ApplicationPool $appPool.Name -Force | Out-Null
		}
	}

	$websiteState = (Get-WebsiteState -Name $siteName).Value

    if ($websiteState -ne 'Stopped') {
        Write-Host "Stopping Site: $siteName as it is currently started."
        Stop-Website -Name $siteName
    }
    else {
        Write-Host "Site $siteName is already stopped"
    }

    if ( $site.DirectoryBrowsingEnabled ) {
        Write-Host "Setting DirectoryBrowsingEnabled to " + $site.DirectoryBrowsingEnabled
        Set-WebConfigurationProperty -filter /system.webServer/directoryBrowse -name enabled -PSPath $sitePath -Value $site.DirectoryBrowsingEnabled
    }

    if ($site.VirtualDirectory)  {
        $virtualPath = $sitePath + "\$($site.VirtualDirectory.Name)\"

		if (-Not (Test-Path $virtualPath)) {
            Write-Host "Creating Virtual Directory '$virtualPath'"
            New-WebVirtualDirectory -Name $virtualDir.Name -Site $siteName -PhysicalPath $site.VirtualDirectory.PhysicalPath | Out-Null
        }
        else {
            Write-Host "Virtual Directory '$virtualPath' already exists"
        }
    }

    if ($site.Application) {
        Write-Host "Setting site applications"

		$site.Application | ForEach-Object {
			$applicationPath = "$sitePath\$($_.Name)"

			if (-Not (Test-Path $applicationPath)) {
                Write-Host "Creating Application $applicationPath"
                New-Item ('$sitePath') -Name $_.Name -ItemType Application -PhysicalPath $_.PhysicalPath | Out-Null
            }
            else {
                Write-Host "Application $applicationPath already exists"
            }
		}
    }

    if ($site.AuthenticationModes.Count -gt 0) {
        # turn it all off
        Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/anonymousAuthentication -name enabled -value false -location $siteName
        Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/digestAuthentication -name enabled -value false -location $siteName
        Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/basicAuthentication -name enabled -value false -location $siteName
        Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/windowsAuthentication -name enabled -value false -location $siteName

        $site.AuthenticationModes | ForEach-Object {
			Write-Host "Enabling Site Authentication mode $($_)"

            switch ($_) {
                "anonymous" {
                    Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/anonymousAuthentication -name enabled -value true -location $siteName
                }
                "basic" {
                    Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/basicAuthentication -name enabled -value true -location $siteName
                }
                "digest" {
                    Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/digestAuthentication -name enabled -value true -location $siteName
                }
                "windows" {
                    Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/windowsAuthentication -name enabled -value true -location $siteName
                }
            }
		}
    }
}
catch {
	$temp.ExitCode = 1
    $temp.Error = "An error occurred in TFL.WebDeploy.WebSite.ps1. LastExitCode: $LASTEXITCODE"
	$temp.ErrorDetail = $_
	$global:LASTEXITCODE = $null
}

[pscustomobject]$temp
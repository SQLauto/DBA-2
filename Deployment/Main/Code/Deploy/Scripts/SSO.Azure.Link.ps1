#Script to link CASC in Azure with SSO and Oyster
#e.g. .\CASC.SSO.Azure.Link.ps1 -CASCportalPort 80 -SSOWebPort 82 -SSOFacadePort 8082 -OysterInstance OysterSolo2

param
(
    
    [string] $CASCportalPort = $(throw 'CASCportalPort parameter is required'), #81	
	#[string] $CACPortalPort = $(throw '$CACPortalPort parameter is required'), #8080
	[string] $SSOWebPort = $(throw '$SSOWebPort parameter is required'), #80
	[string] $SSOFacadePort = $(throw '$SSOFacadePort parameter is required'), #8081
    [string] $OysterInstance = $(throw '$OysterInstance parameter is required') #oystersolo1
	

)
function main
{
Try
{
	[string] $webconfig ="";
	Write-host "RigName: " 

    $computer = gc env:computername

	Write-Output ""
	Write-Output "### Starting Config update of SSO functional Azure VM  ###"
	Write-Output ""

 
	#### 
	#### SSO Website Web Config
	####
	write-output "Modifying SSO Web config"
	
	$webconfig = Get-Content  "\\$computer\c`$\TFL\SSO\Website\web.config"
	Set-Content  "\\$computer\c`$\TFL\SSO\Website\web.config.bak" $webconfig
	
	[xml] $webConfigXML = Get-Content "\\$computer\c`$\TFL\SSO\Website\web.config";
	
	[string] $CASCportalPortTag = "`$CASCportalPort";                       
	[string] $CASportalPortTag = "`$CASportalPort"; 
	[string] $SSOWebPortTag ="`$SSOWebPort";
	[string] $SSOFacadePortTag ="`$SSOFacadePort";
    [string] $OysterInstanceTag ="`$OysterInstance";

	
	write-host "  Setting values"
	
	$webConfigXML.SelectNodes("configuration/appSettings/add[@key='DefaultSsoRedirectProtectedUrl']/@value") | % {$_.Value  = $_.Value.Replace($CASCportalPortTag,$CASCportalPort) };
	$webConfigXML.SelectNodes("configuration/appSettings/add[@key='DefaultSsoRedirectPublicUrl']/@value") | % {$_.Value  = $_.Value.Replace($CASCportalPortTag,$CASCportalPort) };

	$webConfigXML.SelectNodes("configuration/appSettings/add[@key='OysterSiteBase']/@value") | % {$_.Value  = $_.Value.Replace($OysterInstanceTag,$OysterInstance)};
	$webConfigXML.SelectNodes("configuration/appSettings/add[@key='OysterAddExistingCardUrl']/@value") | % {$_.Value  = $_.Value.Replace($OysterInstanceTag,$OysterInstance)};

	$webConfigXML.SelectNodes("configuration/appSettings/add[@key='OysterAddCardExistingUserUrl']/@value") | % {$_.Value  = $_.Value.Replace($OysterInstanceTag,$OysterInstance)};
	$webConfigXML.SelectNodes("configuration/appSettings/add[@key='OysterAddCardNewUserUrl']/@value") | % {$_.Value  = $_.Value.Replace($OysterInstanceTag,$OysterInstance)};

	$webConfigXML.Save("\\$computer\c`$\TFL\SSO\Website\web.config")
	Write-Output  "\\$computer\c`$\TFL\SSO\Website\web.config written"
	write-output ""

	####
	#### SSO Services Web Config ####
	####
	write-output "Modifying SSO Services Web config"

	$webconfig = Get-Content  "\\$computer\c`$\TFL\SSO\SingleSignOnServices\web.config"
	Set-Content  "\\$computer\c`$\TFL\SSO\SingleSignOnServices\web.config.bak" $webconfig
	
	[xml] $webConfigXML = Get-Content  "\\$computer\c`$\TFL\SSO\SingleSignOnServices\web.config";
	
	$webConfigXML.SelectNodes("configuration/appSettings/add[@key='EmailUrl']/@value") | % {$_.Value  = $_.Value.Replace($SSOWebPortTag,$SSOWebPort) };
	$webConfigXML.SelectNodes("configuration/appSettings/add[@key='CASAdminUrl']/@value") | % {$_.Value  = $_.Value.Replace($CASportalPortTag,$CASportalPort) };

	$webConfigXML.SelectNodes("configuration/appSettings/add[@key='OysterBaseUrl']/@value") | % {$_.Value  = $_.Value.Replace($OysterInstanceTag,$OysterInstance) };

    $webConfigXML.Save("\\$computer\c`$\TFL\SSO\SingleSignOnServices\web.config")
	Write-Output  "\\$computer\c`$\TFL\SSO\SingleSignOnServices\web.config written"
	write-output ""

	
}
catch [System.Exception]
{
	$error = $_.Exception.ToString()
	Write-Error "$error"
	exit 1
}
}

main


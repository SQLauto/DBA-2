param($dropFolderLocation,
	$forwardingMailSMTP,
	$smtpIpList
)

$temp = @{
	'Server' = $env:COMPUTERNAME;
	'ScriptName' = 'Tfl.SMTPDeploy.Remote.ps1'
	'ExitCode' = 0;
}

function Add-WindowsFeatures{
param()
	try{
        $retVal = 0

		$smtpserver = Get-WindowsFeature SMTP-Server
		$webwmi = Get-WindowsFeature Web-WMI

		if(!$smtpserver.Installed) {
			$state = Add-WindowsFeature SMTP-Server
			if ($state.Success -eq $false) {
                throw [System.Exception]
            }
			Write-Host "SMTP Server is installed"
		}

		if(!$webwmi.Installed) {
			$state = Add-WindowsFeature Web-WMI
			if ($state.Success -eq $false) {
                throw [System.Exception]
            }
			Write-Output "Web WMI is installed"
		}
	}
	catch{
		Write-Warning "Unable to add windows features."
		$temp.ExitCode = 1
		$temp.ErrorDetail = $_
        $retVal = 1
	}

    $retVal
}

function New-SmtpDomain{
param()
	try{
        $retVal = 0
		Write-Host "Configuring existing SMTPSVC service..."
		# Check the status of the SMTP service
		Set-Service "SMTPSVC" -StartupType Automatic -ErrorAction Stop
		Start-Service "SMTPSVC" -ErrorAction Stop

		Write-Host "CreatingCreate incoming SMTP domain..."

		# First create a new smtp domain. The path 'SmtpSvc/1' is the first virtual SMTP server. If you need to modify another virtual SMTP server
		# change the path accordingly.

		$smtpDomains = [wmiclass]'root\MicrosoftIISv2:IIsSmtpDomain'
		$newSMTPDomain = $smtpDomains.CreateInstance()
		$newSMTPDomain.Name = "SmtpSvc/1/Domain/$incomingEMailDomainName"
		$newSMTPDomain.Put()  | Out-Null

		Write-Host " [OK] Successfully created incoming email domain."

		Write-Host "Configuring incoming SMTP domain..."

		# Configure the new smtp domain as alias domain
		$smtpDomainSettings = [wmiclass]'root\MicrosoftIISv2:IIsSmtpDomainSetting'
		$newSMTPDomainSetting = $smtpDomainSettings.CreateInstance()

		# Set the type of the domain to "Alias"
		$newSMTPDomainSetting.RouteAction = 16

		# Map the settings to the domain we created in the first step
		$newSMTPDomainSetting.Name = "SmtpSvc/1/Domain/$incomingEMailDomainName"
		$newSMTPDomainSetting.Put() | Out-Null

		Write-Host " [OK] Successfully configured incoming email domain."
	}
	catch{
		Write-Warning "Unable to add new incoming SMTP domain"
		$temp.ExitCode = 1
		$temp.ErrorDetail = $_
        $retVal = 1
	}
    $retVal
}

function Update-SmtpDomain{
param()
	try{
        $retVal = 0
		Write-Host "Configuring incoming SMTP domain..."

		# Configure the new smtp domain as alias domain
		$smtpDomainSettings = [wmiclass]'root\MicrosoftIISv2:IIsSmtpDomainSetting'
		$newSMTPDomainSetting = $smtpDomainSettings.CreateInstance()

		# Set the type of the domain to "Alias"
		$newSMTPDomainSetting.RouteAction = 16

		# Map the settings to the domain we created in the first step
		$newSMTPDomainSetting.Name = "SmtpSvc/1/Domain/$incomingEMailDomainName"
		$newSMTPDomainSetting.Put() | Out-Null

		Write-Host " [OK] Successfully configured incoming email domain."
	}
	catch{
		Write-Warning "Unable to configure new incoming SMTP domain"
		$temp.ExitCode = 1
		$temp.ErrorDetail = $_
        $retVal = 1
	}
    $retVal
}

function Update-SmtpServer{
param()
	try
	{
        $retVal = 0
		Write-Output "Configuring virtual SMTP server..."

		$virtualSMTPServer = Get-WmiObject IISSmtpServerSetting -namespace "ROOT\MicrosoftIISv2" | Where-Object { $_.name -like "SmtpSVC/1" }

		# Set maximum message size (in bytes)
		$virtualSMTPServer.MaxMessageSize = ($incomingEMailMaxMessageSize * 1024)

		# Disable session size limit
		$virtualSMTPServer.MaxSessionSize = 0

		# Set maximum number of recipients
		$virtualSMTPServer.MaxRecipients = 0

		if ($dropFolderLocation) {
			$virtualSMTPServer.DropDirectory  = $dropFolderLocation
			Write-Host "[Info] Dropfolder location is now set to $dropFolderLocation"
		}

		#$virtualSMTPServer.RelayIpList = get-content -encoding byte "IPlist.txt"
		$virtualSMTPServer.RelayIpList = $smtpIpList

		if ($forwardingMailSMTP) {
			$virtualSMTPServer.SmartHost = $forwardingMailSMTP
			$virtualSMTPServer.SmartHostType = 2
			Write-Host "[Info] Forwarding Mail SMTP is set to $forwardingMailSMTP"
		}

		# Set maximum messages per connection
		$virtualSMTPServer.MaxBatchedMessages = 0
		$virtualSMTPServer.Put() | Out-Null

		Write-Host "[OK] Successfully configured virtual SMTP server."
	}
	catch {
		Write-Warning "Unable to configure virtual SMTP server."
		$temp.ExitCode = 1
		$temp.ErrorDetail = $_
		$retVal = 1
	}
    $retVal
}

try
{
    $result = 0
	Set-ExecutionPolicy Unrestricted
	Import-Module ServerManager
	Invoke-UntilFail {Add-WindowsFeatures},{New-SmtpDomain},{Update-SmtpDomain},{Update-SmtpServer}
}
catch [System.Exception]
{
	$temp.ExitCode = 1
	$temp.ErrorDetail = $_
	Write-Warning ("ERROR in SMTP server Installation:" + $_.Exception.ToString())
}

(New-Object PSObject -Property $temp)
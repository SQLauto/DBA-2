param
(
	[string] $FTPRig = $(throw $FTPRig),
	[string] $UserName = "FAELAB\TFSBuild",
	[string] $Password = "LMTF`$Bu1ld",
	[string] $DeploymentToolPath = $(throw $DeploymentToolPath)
)

function main
{
	try
	{
		Write-Output ""
		Write-Output "### Starting Config Update of 'FTPRig' to link with OOL ###"
		Write-Output ""

		Write-Output "Loading Deployment.Utils.dll"
		if(-not (Test-Path $DeploymentToolPath))
		{
			Write-Error "Unable to find directory '$DeploymentToolPath'. Please check directory exists"
			exit 1
		}

		if (-not (Test-Path("$DeploymentToolPath\Deployment.Utils.dll")))
		{
			Write-Error "Failed to locate Deployment Utils assembly at $DeploymentToolPath";
			exit 2
		}
		else
		{
			[System.Reflection.Assembly]::LoadFrom((Join-Path $DeploymentToolPath "Deployment.Utils.dll"));
		}
		Write-Output ""

		Write-Output "Initialising vCloud Module for use"
		$vCloudUrl = 'https://vcloud.onelondon.tfl.local'
		$vCloudOrg = 'ce_organisation_td'
		$vCloudUser = 'zSVCCEVcloudBuild'
		$vCloudPassword = 'P0wer5hell'

		Write-Output "Loading VCloudService and Creating connection to $vCloudUrl. Org: $vCloudOrg"
		$vCloudService = New-Object -TypeName Deployment.Utils.VirtualPlatform.VCloud.VCloudService
		$vCloudService.Initialise_vCloudSession($vCloudUrl, $vCloudOrg, $vCloudUser, $vCloudPassword) | Out-Host
		Write-Output "vCloud Module loaded"
		Write-Output ""

		$rig = $vCloudService.GetVapp($FTPRig)
		[bool]$MachinesAvailable = $true
		if($rig -ne $null)
		{
			$FTPSBUSIP = $vCloudService.Get_vCloudMachineIpAddress("TS-OYBO1", $FTPRig)
			Check-NetUse -PathToTest \\$FTPSBUSIP -User $UserName -Password $Password -Retries 10
			if($LASTEXITCODE -ne 0)
			{
				$MachinesAvailable = $false
			}
		}
		else
		{
			Write-Error "FTP Rig '$FTPRig' does not exist. Please check the name"
			exit 3
		}

		if (-not $MachinesAvailable)
		{
			Write-Error "Unable to verify connection to target machines."
			exit 4
		}

		Write-Output "FTP Rig     : $FTPRig"
		Write-Output "FTP SBUS IP : $FTPSBUSIP"
		Write-Output ""

		[string]$appConfig = ""

		### FTM App Config Settings
		$appConfigPath = "\\$FTPSBUSIP\d`$\tfl\FTM\FileTransferManager.Service\Tfl.FileTransferManagerService.exe.config"
		$appConfigOriginalPath = "\\$FTPSBUSIP\d`$\tfl\FTM\FileTransferManager.Service\Tfl.FileTransferManagerService.exe.config.original"
		$appConfigBakPath = "\\$FTPSBUSIP\d`$\tfl\FTM\FileTransferManager.Service\Tfl.FileTransferManagerService.exe.config.bak"
		Write-Output "FTM Application config will now be updated"
		if(!(Test-Path $appConfigOriginalPath))
		{
			Write-Output "Creating original config $appConfigOriginalPath"
			$appConfig = Get-Content $appConfigPath
			Set-Content $appConfigOriginalPath $appConfig
		}

		Write-Output "Backing up current config $appConfigBakPath"
		$appConfig = Get-Content  $appConfigPath
		Set-Content $appConfigBakPath $appConfig

		[xml]$appConfigXml = Get-Content $appConfigPath

		Write-Output "Updating OolSales Target File System"
		$appConfigXml.SelectNodes("configuration/fileTransferSettings/fileTransfers/add[@name='OolSales']/targetFileSystem/@URL") | % { $_.Value = "sftp://vnet3-batch@10.107.203.26:22/prestige/id7" }
		$appConfigXml.SelectNodes("configuration/fileTransferSettings/fileTransfers/add[@name='OolSales']/targetFileSystem/options/add[@name='password']/@value") | % { $_.Value = "P1ssw0rd1" }

		Write-Output "Updating OoLAutoloads Target File System"
		$appConfigXml.SelectNodes("configuration/fileTransferSettings/fileTransfers/add[@name='OoLAutoloads']/targetFileSystem/@URL") | % { $_.Value = "sftp://vnet3-batch@10.107.203.26:22/prestige/id8" }
		$appConfigXml.SelectNodes("configuration/fileTransferSettings/fileTransfers/add[@name='OoLAutoloads']/targetFileSystem/options/add[@name='password']/@value") | % { $_.Value = "P1ssw0rd1" }

		Write-Output "Updating OolRefunds Target File System"
		$appConfigXml.SelectNodes("configuration/fileTransferSettings/fileTransfers/add[@name='OolRefunds']/targetFileSystem/@URL") | % { $_.Value = "sftp://vnet3-batch@10.107.203.26:22/prestige/id10" }
		$appConfigXml.SelectNodes("configuration/fileTransferSettings/fileTransfers/add[@name='OolRefunds']/targetFileSystem/options/add[@name='password']/@value") | % { $_.Value = "P1ssw0rd1" }

		Write-Output "Updating OolReplacements Target File System"
		$appConfigXml.SelectNodes("configuration/fileTransferSettings/fileTransfers/add[@name='OolReplacements']/targetFileSystem/@URL") | % { $_.Value = "sftp://vnet3-batch@10.107.203.26:22/prestige/id12" }
		$appConfigXml.SelectNodes("configuration/fileTransferSettings/fileTransfers/add[@name='OolReplacements']/targetFileSystem/options/add[@name='password']/@value") | % { $_.Value = "P1ssw0rd1" }

		$appConfigXml.Save($appConfigPath)
		Write-Output "$appConfigPath written"

		### OTFP Config Settings
		$appConfigPath = "\\$FTPSBUSIP\d`$\tfl\OTFP\Tfl.Ft.OyBo.FileProcessor.Host.exe.config"
		$appConfigOriginalPath = "\\$FTPSBUSIP\d`$\tfl\OTFP\Tfl.Ft.OyBo.FileProcessor.Host.exe.config.original"
		$appConfigBakPath = "\\$FTPSBUSIP\d`$\tfl\OTFP\Tfl.Ft.OyBo.FileProcessor.Host.exe.config.bak"
		Write-Output "OTFP Application config will now be updated"
		if(!(Test-Path $appConfigOriginalPath))
		{
			Write-Output "Creating original config $appConfigOriginalPath"
			$appConfig = Get-Content $appConfigPath
			Set-Content $appConfigOriginalPath $appConfig
		}

		Write-Output "Backing up current config $appConfigBakPath"
		$appConfig = Get-Content  $appConfigPath
		Set-Content $appConfigBakPath $appConfig
		
		[xml]$appConfigXml = Get-Content $appConfigPath
		Write-Output "Updating OysterOnlineProcessing\Active"
		$appConfigXml.SelectNodes("configuration/OysterOnlineProcessorSettings/add[@key='Active']/@value") | % { $_.Value = "true" }

		$appConfigXml.Save($appConfigPath)
		Write-Output "$appConfigPath written"
	}
	catch [System.Exception]
	{
		$error = $_.Exception.ToString()
		Write-Error $error
		exit 5
	}
}

function Check-NetUse
{
	Param
	(
		[string]$PathToTest,
		[string]$User,
		[string]$Password,
		[int]$Retries
	)

	[int]$attempt = 0
	do
	{
		$attempt++
		if($attempt -gt 1) {sleep -Seconds 30}

		$netuseCommand = "net"
		$result = & $netuseCommand use $PathToTest /user:$User $Password 2>&1
        $err =  $result | ?{$_.gettype().Name -eq "ErrorRecord"}
        if($err)
        {
            foreach($msg in $err)
            {
                if(!([System.String]::IsNullOrEmpty($msg)))
                {
                    Write-Warning $msg
                }
            }
        }
	}
	while(($LASTEXITCODE -ne 0) -and ($attempt -lt $Retries))
}

main
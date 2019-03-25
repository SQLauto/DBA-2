@(
    @{
        Name = "TS-CAS"
		Size = "Standard_DS1_v2"
		Image = "Core"
		OU = "Web Servers"
		Count = 1
        ConfigFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/WebServerWithData.ps1.zip'
        Script = 'WebServerWithData.ps1'
        Function = 'WebServerWithData'
        DataFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/WebServerWithData.psd1'
    }
    @{
		Name = "TS-CIS"
		Size = "Standard_DS1_v2"
		Image = "Core"        
		OU = "Web Servers"
		Count = 1
        ConfigFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/WebServerWithData.ps1.zip'
        Script = 'WebServerWithData.ps1'
        Function = 'WebServerWithData'
        DataFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/WebServerWithData.psd1'
	}
    @{
		Name = "TS-DB"		
		Size = "Standard_DS2_v2"
		Image = "SQL"        
        OU = "SQL"		
        Count = 2
        ConfigFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/SQLSA.ps1.zip'
        Script = 'SQLSA.ps1'
        Function = 'SQLSA'
        DataFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/SQLSA.psd1'
	}
    @{
        Name = "TS-AF"        
		Size = "Standard_DS1_v2"
		Image = "Full"
        OU = "Application"		
        Count = 1
        ConfigFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/AFConfig.ps1.zip'
        Script = 'AFConfig.ps1'
        Function = 'AFConfig'
        DataFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/AFConfig.psd1'
	}
    @{
		Name = "TS-SFTP"		
		Size = "Standard_DS1_v2"
		Image = "Full"
        OU = "Application"		
        Count = 1
        ConfigFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/SFTPConfig.ps1.zip'
        Script = 'SFTPConfig.ps1'
        Function = 'SFTPConfig'
        DataFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/SFTPConfig.psd1'
	}
    @{
		Name = "TS-FAE"
		Size = "Standard_DS1_v2"
		Image = "Core"
        OU = "Application"	
		Count = 4
        ConfigFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/AllNodesConfiguration.ps1.zip'
        Script = 'AllNodesConfiguration.ps1'
        Function = 'AllNodesConfiguration'
        DataFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/AllNodesConfiguration.psd1'
	}
    @{
		Name = "TS-FTM"
		Size = "Standard_DS1_v2"
		Image = "Core"
        OU = "Application"		
        Count = 1
        ConfigFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/AllNodesConfiguration.ps1.zip'
        Script = 'AllNodesConfiguration.ps1'
        Function = 'AllNodesConfiguration'
        DataFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/AllNodesConfiguration.psd1'
	}
    
    @{
		Name = "TS-PARE"
		Size = "Standard_DS1_v2"
		Image = "Core"
        OU = "Application"		
        Count = 1
        ConfigFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/AllNodesConfiguration.ps1.zip'
        Script = 'AllNodesConfiguration.ps1'
        Function = 'AllNodesConfiguration'
        DataFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/AllNodesConfiguration.psd1'
	}
    @{
		Name = "TS-SAS"
		Size = "Standard_DS1_v2"
		Image = "Core"
        OU = "Application"		
        Count = 1
        ConfigFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/AllNodesConfiguration.ps1.zip'
        Script = 'AllNodesConfiguration.ps1'
        Function = 'AllNodesConfiguration'
        DataFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/AllNodesConfiguration.psd1'
	}
    @{
		Name = "TS-APP"
		Size = "Standard_DS1_v2"
		Image = "Core"
        OU = "Application"		
        Count = 1
        ConfigFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/AllNodesConfiguration.ps1.zip'
        Script = 'AllNodesConfiguration.ps1'
        Function = 'AllNodesConfiguration'
        DataFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/AllNodesConfiguration.psd1'
	}
    @{
		Name = "TS-OYBO"
		Size = "Standard_DS1_v2"
		Image = "Core"
        OU = "Application"		
        Count = 1
        ConfigFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/AllNodesConfiguration.ps1.zip'
        Script = 'AllNodesConfiguration.ps1'
        Function = 'AllNodesConfiguration'
        DataFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/AllNodesConfiguration.psd1'
	}
    @{
		Name = "TS-WIN"
		Size = "Standard_DS1_v2"
		Image = "Full"
        OU = "Application"		
        Count = 1
        ConfigFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/AllNodesConfiguration.ps1.zip'
        Script = 'AllNodesConfiguration.ps1'
        Function = 'AllNodesConfiguration'
        DataFileUri = 'https://ftptemplatesandconfigs.blob.core.windows.net/windows-powershell-dsc/AllNodesConfiguration.psd1'
	}
)
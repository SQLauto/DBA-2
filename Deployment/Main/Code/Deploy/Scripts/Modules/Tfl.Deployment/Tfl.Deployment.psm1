function Enable-Remoting {
[CmdletBinding(DefaultParameterSetName="ByMachine")]
param
(
    [Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$true, Position=0, ParameterSetName="ByMachine")] $Machine,
	[Parameter(Mandatory=$true, Position=0, ParameterSetName="ByName")][string] $ComputerName,
	[int]$RetryCount = 3,
	[int]$RetryDelay = 10
)

	PROCESS {

		$func = {
			param([string]$machineName, [switch]$ThrowOnError)

			function Test-ShouldEnable{

				if($machineName -eq $env:COMPUTERNAME){
                    return $false
                }

                Write-Host "Testing session connection to $machineName"
                $session = New-PSSession -ComputerName $machineName -ErrorAction Ignore

				$result = ($null -eq $session)

				if(!$result){
					Write-Host "Session to $machineName successfully created. Remoting is enabled."
                    Remove-PSSession $session
				}

				$result
			}

			$temp = @{
				'Server'   = $env:COMPUTERNAME;
				'ExitCode' = 0
			}

			$retVal = 0
			try{
				#first determine in remoting needs enabling
				if(Test-ShouldEnable){
					#temporary fix for Rig deployments. If not enabled, throw
					#as it is causing issues when running this
					if($ThrowOnError){
						throw "Unable to create PowerShell session on $machineName"
					}

					$inner = '
						Write-Host "Stopping WinRM Service";`
						Stop-Service WinRM; `
						Start-Sleep 2; `
						Get-Service WinRM; `
						Write-Host ""; Write-Host "Enabling PSRemoting"; `
						Enable-PSRemoting;'

					#Test to see if service is available and running. If running, stop it to allow re-configure
					$psExecOutput  = Invoke-PsExec -ComputerName $machineName -PsCommand "$inner"
					$psExecOutput | Select-Object -ExpandProperty StdOut | Write-Host
					$temp.ExitCode = $psExecOutput.Result
				}
			}
			catch{
				$temp.Error = ("An error has occured: {0}`r`n{1}" -f $_, $_.InvocationInfo.PositionMessage)
				$temp.ErrorRecord = $_
				$temp.ExitCode = 1
			}

			[PSCustomObject]$temp
		}

		$loopCount = 0
		$retVal = 0

		do{
			if($PSCmdlet.ParameterSetName -eq "ByName"){
				$output = & $func -MachineName $ComputerName
			}
			else{
				$output = & $func -MachineName $Machine.Name #-ThrowOnError
			}

			$retVal = $output.ExitCode

			if ($retVal -ne 0) {
				if ($output.ErrorRecord) {
					Write-Error2 -ErrorRecord $output.ErrorRecord -ErrorMessage $output.Error
				}
				else {
					Write-Error2 $output.Error
				}

				$loopCount++
				Write-Host "Attempting to enable remoting. Retrying - Attempt $loopCount"
				Start-Sleep -Seconds $RetryDelay
			}

		}While($loopCount -lt $RetryCount -and $retVal -ne 0)

		($retVal -eq 0)
	}
}

function Stop-WindowsService {
[CmdletBinding()]
Param(
	[parameter(Mandatory=$true)] [string[]]$ComputerName,
	[parameter(Mandatory=$true)] [string[]]$Service,
	[string]$TimeOut = "00:00:30"

	)
	PROCESS{

		$func = {
			param([string[]]$services, [string]$timeOut)

			$temp = @{
				'Server' = $env:COMPUTERNAME;
				'ExitCode' = 0;
			}

			try{
				Get-Service $services | Where-Object {$_.status -ne "stopped"} | Stop-Service | Out-Null
				Get-Service $services | ForEach-Object { $_.WaitForStatus('Stopped', $timeOut) | Out-Null }
				$temp.Services = Get-Service $services | Select-Object Name, Status,DisplayName
			}
			catch{
				$temp.ExitCode = 1
				$temp.Error = "Error stopping windows services. May have exceed timeout of $timeout to return status."
				$temp.ErrorDetail = $_
			}

			[pscustomobject]$temp
		}

		if ($ComputerName -eq $env:COMPUTERNAME) {
			$output = & $func -Services $Service -Timeout $TimeOut
		}
		else{
			try{
				$sessions = $ComputerName | New-PSsession
				$output = Invoke-Command -Session $sessions -ScriptBlock $func -ArgumentList $Service,$TimeOut
			}
			finally{
				Remove-PSSession $sessions -ErrorAction Continue
			}
		}

		$output
	}
}

function Start-WindowsService {
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$true)] [string[]]$ComputerName,
	[Parameter(Mandatory=$true)] [string[]]$Service,
	[string]$TimeOut = "00:00:30"
	)
	PROCESS{

		$func = {
			param([string[]]$services, [string]$timeOut)

			$temp = @{
				'Server' = $env:COMPUTERNAME;
				'ExitCode' = 0;
			}

			Write-Host "Attempting to start services $services on $($env:COMPUTERNAME)"

			try{
				$validServices = (Get-WmiObject win32_service | Where-Object { $_.StartMode -ne 'Disabled' -and ($services -contains $_.Name) } | Select-Object -ExpandProperty Name)
				Get-Service $validServices | Start-Service -ErrorAction Stop | Out-Null
				Get-Service $validServices | ForEach-Object { $_.WaitForStatus('Running', $timeOut) }
				$temp.Services = Get-Service $services | Select-Object Name, Status,DisplayName
			}
			catch [System.ServiceProcess.TimeoutException]{
				$temp.ExitCode = 2
				$temp.Error = "Error starting windows services due to process exceeding timeout of $timeOut"
				$temp.ErrorDetail = $_
			}
			catch{
				$temp.ExitCode = 1
				$temp.Error = "Failed to start windows services."
				$temp.ErrorDetail = $_
			}

			[pscustomobject]$temp
		}

		if ($ComputerName -eq $env:COMPUTERNAME) {
			$output = & $func -Services $Service -Timeout $TimeOut
		}
		else {
			try{
				$sessions = $ComputerName | New-PSsession
				$output = Invoke-Command -Session $sessions -ScriptBlock $func -ArgumentList $Service,$TimeOut
			}
			finally{
				Remove-PSSession $sessions -ErrorAction Continue
			}
		}

		$output
	}
}

function Get-WindowsServiceStatus {
    [CmdletBinding(DefaultParameterSetName = "ByName")]
    Param(
        [Parameter(Mandatory = $true)] [string[]]$ComputerName,
        [Parameter(Mandatory = $true, ParameterSetName = "ByName")] [string[]]$Service,
        [Parameter(Mandatory = $true, ParameterSetName = "ByObject")] [Deployment.Domain.Roles.ServiceDeploy[]]$ServiceDeploys
    )

    $func = {
        param([string[]]$services)

        $temp = @{
            'Server'    = $env:COMPUTERNAME
            'Clustered' = $false
            'ExitCode'  = 0
        }

        try {
            $temp.Services = Get-WmiObject win32_Service | Where-Object { $_.Name -in $services } | Select-Object Name, DisplayName, StartMode, @{Name = "Status"; Expression = {$_.State}}
        }
        catch {
            $temp.ExitCode = 1
            $temp.Error = "Error accessing the services on server"
            $temp.ErrorDetail = $_
        }

        [pscustomobject]$temp
	}

	if ($PSCmdlet.ParameterSetName -eq "ByName") {
		if ($ComputerName -eq $env:COMPUTERNAME -or $ComputerName -eq "localhost") {
			$output = & $func -Services $Service
		}
		else {
			try{
				$sessions = $ComputerName | New-PSsession
				$output = Invoke-Command -Session $sessions -ScriptBlock $func -ArgumentList (,$Service)
			}
			finally{
				Remove-PSSession $sessions -ErrorAction Continue
			}
		}

		return $output
	}

    $server = $ComputerName[0]

    $cluster = Get-ClusterQuorum -Cluster $server -ErrorAction Ignore

    if ($cluster) {

        $temp = @{
			'Server'      = $server
			'Clustered'   = $true
			'ExitCode'    = 0
			'ClusterInfo' = @()
			'ClusterGroups' = @()
		}

		$all = Get-ClusterResource -Cluster $server

        $ServiceDeploys | ForEach-Object {
            $resourceName = $_.Services | Select-Object @{Name = "ResourceName"; Expression = {$_.ClusterInfo.ResourceName}} | Select-Object -ExpandProperty 'ResourceName'

			$clusterResource =  $all | Where-Object {$_.Name -eq "$resourceName" }

			#get the cluster group we care about from the specific cluster resource
			$clusterGroup = $clusterResource | Select-Object -ExpandProperty OwnerGroup

			$temp.ClusterGroups += $clusterGroup
			$clusterGroupName = $clusterGroup | Select-Object -ExpandProperty Name

            $temp.ClusterInfo += $all | Where-Object {$_.OwnerGroup.Name -eq "$clusterGroupName"}
        }

        return [pscustomobject]$temp
    }

    $Service = $ServiceDeploys.Services | Select-Object @{Name = "Name"; Expression = {$_.Name}} | Select-Object -ExpandProperty 'Name'

	if ($ComputerName -eq $env:COMPUTERNAME -or $ComputerName -eq "localhost") {
		$output = & $func -Services $Service
	}
	else {
		try{
			$sessions = $ComputerName | New-PSsession
			$output = Invoke-Command -Session $sessions -ScriptBlock $func -ArgumentList (,$Service)
		}
		finally{
			Remove-PSSession $sessions -ErrorAction Continue
		}
	}

	$output
}

function Start-ClusteredWindowsService {
[CmdletBinding(DefaultParameterSetName="ByName")]
Param(
	[Parameter(Mandatory=$true, Position=0)][ValidateNotNullOrEmpty()][string]$Cluster,
	[Parameter(ParameterSetName="ByName")][ValidateNotNullOrEmpty()] [string]$ResourceName,
	[Parameter(ParameterSetName="ByType", ValueFromPipeline=$true)] [string[]]$ResourceType
)
	PROCESS{
		$pattern = 'PARC|LMEM|HMEM|LMC0|HMC0'
		switch($PScmdlet.ParameterSetName){
			"ByName" { Get-ClusterResource -Cluster $Cluster -Name $ResourceName | Where-Object {$_.State -eq 'Offline'} | Start-ClusterResource | Out-Null }
			"ByType" {
				$bits = Get-ClusterResource -Cluster $Cluster | Where-Object {$_.State -eq 'Offline' -and $_.OwnerGroup.Name -match $pattern}
				$ResourceType | ForEach-Object {
					$name = $_
					$bits | Where-Object { $_.ResourceType.Name -eq $name } | Start-ClusterResource | Out-Null
				}
			}
		}

		Get-ClusterResource -Cluster $Cluster | Where-Object {($null -ne $ResourceName-and $_.Name -eq $ResourceName) -or ($_.OwnerGroup.Name -match $pattern -and $_.ResourceType.Name -in $ResourceType)}
	}
}

function Stop-ClusteredWindowsService {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0)][ValidateNotNullOrEmpty()][string]$Cluster,
        [Parameter(ParameterSetName = "ByName")][ValidateNotNullOrEmpty()] [string]$ResourceName,
        [Parameter(ParameterSetName = "ByType", ValueFromPipeline = $true)] [string[]]$ResourceType
    )
    PROCESS {
		$pattern = 'PARC|LMEM|HMEM|LMC0|HMC0'
        switch ($PScmdlet.ParameterSetName) {
            "ByName" { Get-ClusterResource -Cluster $Cluster -Name $ResourceName | Where-Object {$_.State -eq 'Online'} | Stop-ClusterResource | Out-Null }
            "ByType" {
                $bits = Get-ClusterResource -Cluster $Cluster | Where-Object {$_.State -eq 'Online' -and $_.OwnerGroup.Name -match $pattern}
                $ResourceType | ForEach-Object {
                    $name = $_
                    $bits | Where-Object { $_.ResourceType.Name -eq $name } | Stop-ClusterResource | Out-Null
                }
            }
        }

        Get-ClusterResource -Cluster $Cluster | Where-Object {($null -ne $ResourceName -and $_.Name -eq $ResourceName) -or ($_.OwnerGroup.Name -match $pattern -and $_.ResourceType.Name -in $ResourceType)}
    }
}

function Stop-AppFabric {
[CmdletBinding()]
Param(
	[parameter(Mandatory=$true)] [string[]]$ComputerName,
	[int]$Port = 22233,
	[string]$Action = "Fix"
	)
	PROCESS{

		$func = {
			param([int]$Port, [string]$Action)

			$temp = @{
				'Server' = $env:COMPUTERNAME;
				'ExitCode' = 0;
			}

			try{
				Import-Module DistributedCacheAdministration
				Use-CacheCluster
				$cacheHost = Get-CacheHost -HostName $env:COMPUTERNAME -CachePort $Port
				$currentState = $cacheHost.Status

				Write-Host "Current Status of AppFabric is $currentState"

				if($currentState -ieq "Down") {
					Write-Host "AppFabric is already DOWN"
					return (New-Object PSObject -Property $temp)
				}

				if($Action -ieq "Fail"){
					Write-Warning "AppFabric - Failing deployment."
					$temp.ExitCode = 1
					$temp.Error = "Failing deployment of AppFabric."
					$temp.ErrorDetail = ""
					return (New-Object PSObject -Property $temp)
				}

				if($Action -ieq "Ignore"){
					Write-Host "Action set to ignore, taking no further action"
					return (New-Object PSObject -Property $temp)
				}

				#Fix - Default
				Write-Host "Trying to stop AppFabric"
				Stop-CacheCluster
				$cacheHost = Get-CacheHost -HostName $env:COMPUTERNAME -CachePort $Port
				$currentState = $cacheHost.Status

				if($currentState -ine "Down") {
					throw "Failed to stop AppFabric."
				}
			}
			catch{
				$temp.ExitCode = 1
				$temp.Error = "Error stopping AppFabric."
				$temp.ErrorDetail = $_
			}

			[PSCustomObject]$temp
		}

		if ($ComputerName[0] -eq $env:COMPUTERNAME -or $ComputerName[0] -eq 'localhost') {
			$output = & $func -Port $Port -Action $Action
		}
		else {
			try{
				$sessions = $ComputerName | New-PSsession
				$output = Invoke-Command -Session $sessions -ScriptBlock $func -ArgumentList $Port,$Action
			}
			finally{
				Remove-PSSession $sessions -ErrorAction Continue
			}
		}

		$output
	}
}

function Start-AppFabric {
[CmdletBinding()]
Param(
	[parameter(Mandatory=$true)] [string[]]$ComputerName,
	[int]$Port = 22233,
	[string]$Action = "Fix"
	)
	PROCESS{

		$func = {
			param([int]$Port, [string]$Action)
			$temp = @{
				'Server' = $env:COMPUTERNAME;
				'ExitCode' = 0;
			}

			try{
				Import-Module DistributedCacheAdministration
				Use-CacheCluster
				$cacheHost = Get-CacheHost -HostName $env:COMPUTERNAME -CachePort $Port
				$currentState = $cacheHost.Status

				Write-Host "Current Status of AppFabric is $currentState"

				if($currentState -ieq "Up") {
					Write-Host "AppFabric is already UP"
					return (New-Object PSObject -Property $temp)
				}

				if($Action -eq  "Fail"){
					Write-Warning "AppFabric - Failing deployment."
					$temp.ExitCode = 1
					$temp.Error = "Failing deployment of AppFabric."
					$temp.ErrorDetail = ""
					return (New-Object PSObject -Property $temp)
				}

				if($Action -eq "Ignore"){
					Write-Host "Action set to ignore, taking no further action"
					return (New-Object PSObject -Property $temp)
				}

				#Fix - Default
				Write-Host "Trying to start AppFabric"
				Start-CacheCluster
				$cacheHost = Get-CacheHost -HostName $env:COMPUTERNAME -CachePort $Port
				$currentState = $cacheHost.Status

				if($currentState -ne "Up") {
					throw "Failed to start AppFabric."
				}
			}
			catch{
				$temp.ExitCode = 1
				$temp.Error = "Error starting AppFabric."
				$temp.ErrorDetail = $_
			}

			[PSCustomObject]$temp
		}

		if ($ComputerName -eq $env:COMPUTERNAME) {
			$output = & $func -Port $Port -Action $Action
		}
		else {
			try{
				$sessions = $ComputerName | New-PSsession
				$output = Invoke-Command -Session $sessions -ScriptBlock $func -ArgumentList $Port,$Action
			}
			finally{
				Remove-PSSession $sessions -ErrorAction Continue
			}
		}

		$output
	}
}

function Get-FileInfo {
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$true)] [string[]]$ComputerName,
	[Parameter(Mandatory=$true)] [string[]]$Path
	)
	PROCESS{

		$func = {
			param([string[]]$paths)

			try{
				$fileInfos = $paths | Where-Object { Test-Path $_ } | ForEach-Object  {

					$files = (Get-ChildItem -Path $_ -Include '*.dll','*.exe' -Exclude '*Test*','*Mock*','System.*','Microsoft.*','log4net*','Newtonsoft*','Topshelf*', -File -Recurse -Depth 0)

					$files | Where-Object {($_.Name -match 'tfl') -or ($_.Name -match 'pare') -or ($_.VersionInfo.FileVersion -match "[1-4].\d{1,2}.\d{5}.\d")} | ForEach-Object {
						[PSCustomObject] @{
							'MachineName' = $env:COMPUTERNAME;
							'Directory' = $_.Directory.FullName;
							'AssemblyName' = $_.Name;
							'Version' = $_.VersionInfo.FileVersion;
							'ModifiedTimeStamp' = $_.LastWriteTime;
							'CreatedTimeStamp' = $_.CreationTime;
							'FileSize' = $_.Length
						}
					}
				}
			}
			catch{
				$temp.Error = "Error getting file info on server: $_"
			}

			$fileInfos | Where-Object {$_.Version}
		}

		if ($ComputerName[0] -eq 'localhost' -or $ComputerName[0] -eq $env:COMPUTERNAME) {
			$output = & $func $Path
		}
		else {
			try{
				$sessions = $ComputerName | New-PSsession
				$output = Invoke-Command -Session $sessions -ScriptBlock $func -ArgumentList (,$Path) -ThrottleLimit 18
			}
			finally{
				Remove-PSSession $sessions
			}
		}

		$output
	}
}

function New-Manifestfile {
	[CmdletBinding()]
	Param(
			[Parameter(Mandatory=$true)] [array]$RigMachines,
			[Parameter(Mandatory=$true)] [string]$BuildDefinitionPath,
			[Parameter(Mandatory=$true)] [string]$RigName
		)

		[xml]$doc = New-Object System.Xml.XmlDocument
		$dec = $doc.CreateXmlDeclaration("1.0","UTF-8",$null)
		$doc.AppendChild($dec) | Out-Null

		$root = $doc.CreateNode("element","machines",$null)
		$root.SetAttribute("rigname", $RigName)
		$root.SetAttribute("createddate", (Get-Date).ToString())
		$root.SetAttribute("xmlns", 'http://tfl.gov.uk/DeploymentConfig')

		foreach($RigMachine in $RigMachines)
		{
			$m = $doc.CreateNode("element","machine",$null)
			$m.SetAttribute("name", $RigMachine.ComputerName)
			$m.SetAttribute("ipv4address", $RigMachine.IPV4Address)

			$drives = $RigMachine.Drives
			foreach($drive in $drives)
			{
				$d = $doc.CreateNode("element","drive",$null)
				$d.SetAttribute("name", $drive.Name)
				$d.SetAttribute("used", $drive.Used)
				$d.SetAttribute("free", $drive.Free)

				$m.AppendChild($d) | Out-Null
			}
			$root.AppendChild($m) | Out-Null
		}
		$doc.AppendChild($root) | Out-Null

		$doc.Save("$BuildDefinitionPath\RigManifest.xml")

		Write-Host "Generated file : $BuildDefinitionPath\RigManifest.xml"
}

function Get-RigInfo {
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$true)] [string]$ComputerName,
	[Parameter(Mandatory=$true)] [pscredential]$Credential
	)

	$RigMachines = Invoke-Command  {
		$outputList = @()
		# Jump server
		$properties = [PSCustomObject]@{
			ComputerName = $env:COMPUTERNAME
			IPV4Address = ""
			Drives = (Get-PSDrive -PSProvider 'FileSystem' | Where-Object {$_.Used -gt 0}| Select-Object -Property Name,Used,Free)
		}

		$outputList += $properties

	    $RigComputerName = (Get-ADComputer -Filter * -Property Name | Where-Object {$_.Name -ne "faeadg001"} | Where-Object {(Test-Connection -ComputerName $_.Name -Count 1 -ErrorAction SilentlyContinue)}).Name

		# Other servers excluding jump server
        $notThisComputerName = $RigComputerName | Where-Object {$_ -ne $env:COMPUTERNAME}

		$outputList += Invoke-Command -ComputerName $notThisComputerName -ScriptBlock {
			[PSCustomObject] @{
				ComputerName = $env:COMPUTERNAME
				IPV4Address = ""
				Drives = (Get-PSDrive -PSProvider 'FileSystem' | Where-Object {$_.Used -gt 0}| Select-Object -Property Name,Used,Free)
			}
		}

        $outputList

	} -Credential $Credential -ComputerName $ComputerName -Authentication Credssp

	Write-Host ($RigMachines | Select-Object ComputerName,IPV4Address,Drives)
}
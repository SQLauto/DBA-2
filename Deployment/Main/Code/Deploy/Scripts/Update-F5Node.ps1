# Update-F5Node.ps1
# Modified: 02/05/2018

Param(
    [string] $F5Server = 'tdc2vlb005.onelondon.tfl.local',
	[string] $F5ServerUserId = 'zsvcautomate',
	[string] $F5ServerPassword,
	[string] $RigName,
	[string] $EnvironmentShortName,
	[string] $MachineName
)

function Get-NodeMapping ($MachineName, $EnvironmentShortName) {

	$nodeMappings = @()

	switch($MachineName){
		"TS-CIS1" {
			$FIDNode = @{
				PoolName = "FIDSVC-$EnvironmentShortName-POOL"
				Port = 8705
			}
			$JUSNode = @{
				PoolName = "JUSVC-$EnvironmentShortName-POOL"
				Port = 8704
			}
			$TTNode = @{
				PoolName = "TTSVC-$EnvironmentShortName-POOL"
				Port = 8706
			}
			$MDNode = @{
				PoolName = "MDAPI-$EnvironmentShortName-POOL"
				Port = 8734
			}
			$SSNode = @{
				PoolName = "SSSVC-$EnvironmentShortName-POOL"
				Port = 8722
			}

			$nodeMappings += $FIDNode
			$nodeMappings += $JUSNode
			$nodeMappings += $TTNode
			$nodeMappings += $MDNode
			$nodeMappings += $SSNode
		}
		"TS-CAS1" {
			$OysterNode = @{
				PoolName = "OYSTERSVC-$EnvironmentShortName-POOL"
				Port = 8799
			}
			$TJSOysterNode = @{
				PoolName = "TJSOYSTER-$EnvironmentShortName-POOL"
				Port = 8745
			}
            $TJSCPCNode = @{
				PoolName = "TJSCPC-$EnvironmentShortName-POOL"
				Port = 8744
			}

            $nodeMappings += $OysterNode
			$nodeMappings += $TJSOysterNode
			$nodeMappings += $TJSCPCNode
		}
		"TS-DB1" {
			$DBNode = @{
				PoolName =  "CASCDB-$EnvironmentShortName-POOL"
				Port = 56075
			}

			$nodeMappings += $DBNode
		}
		"TS-DB2"{
			$SSONode = @{
				PoolName = "SSOSVC-$EnvironmentShortName-POOL"
				Port = 8081
			}
			$SSOWebNode = @{
				PoolName = "SSOWEB-$EnvironmentShortName-POOL"
				Port = 80
			}

			$nodeMappings += $SSONode
			$nodeMappings += $SSOWebNode
		}
	}

	return $nodeMappings
}

function Get-BuildDefintionName ($BuildId) {
	$tfsProjectUri = "$env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI/$env:SYSTEM_TEAMPROJECT"
	$restApiUrl = "$tfsProjectUri/_apis/build/builds/$BuildId`?api-version=2.0"

	$response = Invoke-RestMethod $restApiUrl -UseDefaultCredentials

	return $response.definition.name
}

function Read-RigManifest ($MachineName) {
	$buildDefinitionName = Get-BuildDefintionName -BuildId $env:BUILD_BUILDID
	$buildDefinitionPath = "$env:AGENT_RELEASEDIRECTORY\$buildDefinitionName"
	$rigManifestPath = "$BuildDefinitionPath\RigManifest.xml"
	[xml]$rigManifestContent = Get-Content $rigManifestPath

	$machine = $rigManifestContent.machines.machine | Where-Object {$_.name -eq $MachineName} | Select-Object -Property ipv4address
    return $machine.ipv4address
}

function Remove-NodeFromPool ($nodeName, $port, $poolName) {
    $addressStruct = Create-AddressStruct -nodeName $nodeName -port $port

	Write-Host "Removing node $nodeName from pool $poolName"
	$iCtrl.LocalLBPool.remove_member_v2($poolName, $addressStruct)
	Write-Host "Node $nodeName removed from pool $poolName"
}

function Delete-Node ($nodeName) {
	Write-Host "Deleting node $nodeName"
	$iCtrl.LocalLBNodeAddressV2.delete_node_address($nodeName)
	Write-Host "Node $nodeName deleted successfully"
}

function Create-Node ($node) {
	Write-Host "Creating node with settings: "
	Write-Host $node
	$iCtrl.LocalLBNodeAddressV2.create($node.NodeName,$node.Address,@(0)) 
	Write-Host "Node $($node.NodeName) created successfully"
}

function Add-NodeToPool ($nodeName, $port, $poolName) {
	$addressStruct = Create-AddressStruct -nodeName $nodeName -port $port

	Write-Host "Adding $nodeName to pool $poolName on port $port"
	$iCtrl.LocalLBPool.add_member_v2($poolName, $addressStruct)
	Write-Host "Successfully added $nodeName to pool $poolName"
}

function Create-AddressStruct( $nodeName, $port){
    Write-Host "Creating Address Struct"
	$addressStruct = New-Object -TypeName iControl.CommonAddressPort
	$addressStruct.address = $nodeName
	$addressStruct.port = $port
	Write-Host $addressStruct

    return $addressStruct
}

$exitCode = 0
$PortMappings = @{}

# Connect to the BIG-IP
Write-Host "Adding iControlSnapIn"
Add-PSSnapIn iControlSnapIn

Write-Host "Connecting to F5 Administration..."
$success = Initialize-F5.iControl -Hostname $F5Server -Username $F5ServerUserId -Password $F5ServerPassword
if(!$success)
{
	Write-Error "Failed to login to F5. Please contact your administrator."
	Exit 1001
}
$iCtrl = Get-F5.iControl
Write-Host "Connection Successful"

try
{
	# new Node Information
	$newNodeInformation = @{
		NodeName = "/Common/$RigName.$MachineName"
		Name = $MachineName
		Address = Read-RigManifest($MachineName)
	}

	# Get Node Information from BIG-IP
	Write-Host "Getting Node Information from F5"
	$nodes       = @($ictrl.LocalLBNodeAddressV2.get_list())
	$nodeAddress = @($ictrl.LocalLBNodeAddressV2.get_address($nodes));
	$nodeList    = @();
	for ($i=0; $i -le $nodes.Length; $i++) {
		$nodeList += "" | Select-Object @{Name="Name";   Expression={$nodes[$i]}}, @{Name="Address";Expression={$nodeAddress[$i]}}
	}

	# Get Pool Information from BIG-IP
	Write-Host "Getting Pool information from F5"
	$pools       = @($iCtrl.LocalLBPool.get_list())
	$poolMembers = @($iCtrl.LocalLBPool.get_member_v2($pools))
	$poolList    = @()
	for ($i=0; $i -le $pools.Length; $i++) {
		$poolList += "" | Select-Object @{Name="Name";Expression={$pools[$i]}}, @{Name="Members";Expression={@($poolMembers[$i])}}
	}

	$poolsOfInterest = $null
	# Check if New Node address is already in use
	Write-Host "Validating if new Node address is already in use"
	$node = $nodeList | Where-Object{$_.Address -like $newNodeInformation.Address}
	if($node) {
		Write-Host "New Node address is in use. Validating that it is the correct node"
		if($node.Name -eq $newNodeInformation.NodeName) {
			# Address matches do nothing
			Write-Host "Node $($node.Name) address is correct"
			Write-Host "Node does not need updating. Exiting process"
			exit 0
		}
		else {
			Write-Host "Node $($node.Name) is not part of this environment and has incorrect address"
			Write-Host "Node $($node.Name) will be deleted"
			Write-Host "Finding Pools with Node $($node.Name) as a member"
			$poolsOfInterest = @($poolList | Where-Object{$_.Members | Where-Object{$_.Address -eq $node.Name}})
			$poolsOfInterest | ForEach-Object{ Remove-NodeFromPool -nodeName $_.Members.address -port $_.Members.port -poolName $_.Name }
			Delete-Node($node.Name)
		}
	}

	$poolsOfInterest = $null
	# Node to Find
	Write-Host "Looking for Node $($newNodeInformation.NodeName)"
	$node = $nodeList | ?{$_.Name -like $newNodeInformation.NodeName}
	if($node) {
		# If node exists check ip address
		Write-Host "Found node $($node.Name)"
		Write-Host "Checking node address is correct"
		if($node.Address -ne $newNodeInformation.Address) {
			# Address does not match, perform update
			Write-Host "Node $($node.Name) address is incorrect"

			# Find pools where node is a member
			Write-Host "Finding pools with Node $($node.Name) as member"
			$poolsOfInterest = @($poolList | ?{$_.Members | ?{$_.address -eq $node.Name}})

			# remove node from pools
			Write-Host "Removing Node $($node.Name) from pools"
            $poolsOfInterest | ForEach-Object { Remove-NodeFromPool -nodeName $_.Members.address -port $_.Members.port -poolName $_.Name }

            # Delete the node
            Delete-Node($node.Name)
		}
		else {
			# Address matches do nothing
			Write-Host "Node $($node.Name) address is correct"
			Write-Host "Node does not need updating. Exiting process"
			exit 0
		}
	}

	# Create the Node
    Write-Host "Adding Node $($newNodeInformation.Name) with Address $($newNodeInformation.Address)"
	Create-Node -node $newNodeInformation

    # Add node into pools
    Write-Host "Adding Node $($newNodeInformation.NodeName) to pools"
    Get-NodeMapping -MachineName $MachineName -EnvironmentShortName $EnvironmentShortName | ForEach-Object {
		Add-NodeToPool -nodeName $newNodeInformation.NodeName -port $_.Port -poolName $_.PoolName
	}
}
catch
{
	Write-Error "Failure during F5 Node update."
	Write-Error $_.Message
	exit 1
}
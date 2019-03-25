# .\Update-F5.ps1 -g_pwd '<< password >>' -rig_name 'IPP.Int07' -g_pool 'CASCDB-IPP007-POOL'
Param(
    [string] $F5Server = 'tdc2vlb005.onelondon.tfl.local',
	[string] $F5ServerUserId = 'zsvcautomate',
	[string] $F5ServerPassword,
	[string] $F5PoolName,
	[string] $RigName,
	[string] $MachineName,
	[int] $PortNumber
)

function Get-BuildDefintionName
{
	Param
	(
		$BuildId
	)

	$tfsProjectUri = "$env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI/$env:SYSTEM_TEAMPROJECT"
	$restApiUrl = "$tfsProjectUri/_apis/build/builds/$BuildId`?api-version=2.0"

	$response = Invoke-RestMethod $restApiUrl -UseDefaultCredentials

	return $response.definition.name
}

function Read-RigManifest
{
	param(
		$machineName
	)

	$buildDefinitionName = Get-BuildDefintionName -BuildId $env:BUILD_BUILDID
	$buildDefinitionPath = "$env:AGENT_RELEASEDIRECTORY\$buildDefinitionName"
	$rigManifestPath = "$BuildDefinitionPath\RigManifest.xml"
	[xml]$rigManifestContent = Get-Content $rigManifestPath

	$machine = $rigManifestContent.machines.machine | Where-Object {$_.name -eq $MachineName} | Select-Object -Property ipv4address
    return $machine.ipv4address
}

$exitCode = 0

Add-PSSnapIn iControlSnapIn
$success = Initialize-F5.iControl -Hostname $F5Server -Username $F5ServerUserId -Password $F5ServerPassword
if(!$success)
{
	Write-Error "Failed to login to F5. Please contact your administrator."
	Exit 1001
}

$node = @{
	NodeName = "/Common/$RigName.$MachineName"
	Name = $MachineName
	Address = Read-RigManifest -machineName $MachineName
	Port = $PortNumber
}

$F5PoolName = "/Common/$F5PoolName"
$pool = Get-F5.LTMPool -Pool $F5PoolName
if($pool)
{
	Write-Host "Pool $F5PoolName found"
	$members = Get-F5.LTMPoolMember -Pool $F5PoolName
	
	# Remove Member from Pool
    foreach($member in $members)
	{
		# Remove Member from Pool
	    Write-Host "Removing member $($member.Name) from Pool $F5PoolName"
		$member | Remove-F5.LTMPoolMember
	}
		
	$iCtrl = Get-F5.iControl
	$nodes = @($ictrl.LocalLBNodeAddressV2.get_list())
		
	# Check Node has correct address
    $nodeExists = $false
	$nodeOfInterest = $nodes.Contains($node.NodeName)
    if($nodeOfInterest) 
    {
        Write-Host "Node $($node.NodeName) found"
        $nodeExists = $true
        $nodeOfInterestAddress = $iCtrl.LocalLBNodeAddressV2.get_address($node.NodeName)
        if($node.Address -ne $nodeOfInterestAddress) 
        {
            Write-Host "Address for node $($node.NodeName) requires updating"	
		    Write-Host "Removing node $($node.NodeName)"
		    $iCtrl.LocalLBNodeAddressV2.delete_node_address($node.NodeName)
            $nodeExists = $false
        }
        else
        {
            Write-Host "Address for node $($node.NodeName) is correct"	
        }
    }


	# Add New Node if needed
	if(!$nodeExists)
	{
		$nodeNames = @()
		$nodeNames += $node.NodeName
		$nodeAddress = @()
		$nodeAddress += $node.Address

		Write-Host "Adding Node $($nodeNames) with Address $($nodeAddress)"
		$iCtrl.LocalLBNodeAddressV2.create($nodeNames,$nodeAddress,@(0)) 
	}

	# Add member to Pool
	$member = "$($node.Address):$($node.Port)"
	Write-Host "Adding member $member to Pool $F5PoolName"
	Add-F5.LTMPoolMember -Pool $F5PoolName -Member $member | Out-Null
}
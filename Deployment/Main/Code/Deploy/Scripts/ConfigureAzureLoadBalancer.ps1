<# 
.SYNOPSIS
    Create or delete a load balancers Pools and Inbound NAT Rules
.PARAMETER LoadBalancerName 
    The name of the load balancer to create the pools and rules
.PARAMETER ResourceGroup
    The Resource group of the machines you want to add the the load balancers backend pool
.PARAMETER LoadBalancerFrontEnd
    The name of the front end IP configuration you want to add the inbound NAT rules to
.PARAMETER LoadBalancerResourceGroup 
    The name of the resource group where the load balancer resides
.PARAMETER Cleanup
    A switch that when selected will delete all the pools and rules given the correct parameters (Will not delete front end configurations)
.EXAMPLE
    .\ConfigureAzureLoadBalancer.ps1 -LoadBalancerName "ftp-integration-lb" -ResourceGroup "ftp-main-top10-rg" -LoadBalancerFrontEnd "FrontEnd-maintop10"
#>

param(
    [Parameter(Mandatory=$true)]
    [string] $LoadBalancerName, 
    [Parameter(Mandatory=$true)]
    [string] $ResourceGroup, 
    [Parameter(Mandatory=$true)]
    [string] $LoadBalancerFrontEnd, 
    [string] $LoadBalancerResourceGroup = "ftp-integrationlb-rg",    
    [switch] $Cleanup
)

$backendPools = @()
        $CASPool = @{
                PoolName = $ResourceGroup -Replace "-rg", "-TS-CAS1" 
                Machine = "TS-CAS1"
        }
        $CISPool = @{
                PoolName = $ResourceGroup -Replace "-rg", "-TS-CIS1"
                Machine = "TS-CIS1"
        }
        $DB1Pool = @{
                PoolName = $ResourceGroup -Replace "-rg", "-TS-DB1"
                Machine = "TS-DB1"
        }
        $DB2Pool = @{
                PoolName = $ResourceGroup -Replace "-rg", "-TS-DB2"
                Machine = "TS-DB2"
        }
    
$backendPools += $CASPool
$backendPools += $CISPool
$backendPools += $DB1Pool
$backendPools += $DB2Pool

function Get-LoadBalancer{
    try{
        $LoadBalancer = Get-AzureRmLoadBalancer -Name $LoadBalancerName -ResourceGroupName $LoadBalancerResourceGroup
        Write-Host "Load Balancer $LoadBalancerName found"
        return $LoadBalancer
    }
    catch {
        Write-Error "Could not find load balancer $loadBalancerName in resource group $loadBalancerResourceGroup"
        exit 1
    }
}

function Create-BackendPoolsandRules ($Pool, $PublicIP)
{
    Write-Host "Creating rules and pools"
    $lb = Get-LoadBalancer
    $nicName = $Pool.Machine + "_nic"
    $nic = Get-AzureRmNetworkInterface -ResourceGroupName $ResourceGroup -Name $nicName
        
    $lb | Add-AzureRmLoadBalancerBackendAddressPoolConfig -Name $Pool.PoolName | Set-AzureRmLoadBalancer
    $backendPool = Get-AzureRmLoadBalancerBackendAddressPoolConfig -LoadBalancer $lb -Name $Pool.PoolName
                           
    switch($Pool.Machine) {  
        "TS-CAS1" {        
            $nic.IpConfigurations[0].LoadBalancerBackendAddressPools.Add($backendPool)                            
            $casNatRules = @()          
            
            $casNatRules += $casNatRule1 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "TJSCPC-$ResourceGroup" -FrontendIpConfiguration $PublicIP -Protocol Tcp -FrontendPort 8744 -BackendPort 8744
            $casNatRules += $casNatRule2 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "TJSOYSTER-$ResourceGroup" -FrontendIpConfiguration $PublicIP -Protocol Tcp -FrontendPort 8745 -BackendPort 8745
            $casNatRules += $casNatRule3 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "OYSTERSVC-$ResourceGroup" -FrontendIpConfiguration $PublicIP -Protocol Tcp -FrontendPort 8799 -BackendPort 8799                        
            
            Write-Host "Creating rules for machine TS-CAS1"
            
            foreach($rule in $casNatRules){
                $nic.IpConfigurations[0].LoadBalancerInboundNatRules.Add($rule)
                $lb.InboundNatRules.Add($rule)
            }
            
            $lb | Set-AzureRmLoadBalancer
            $nic | Set-AzureRmNetworkInterface
        }
        "TS-CIS1"{
            $nic.IpConfigurations[0].LoadBalancerBackendAddressPools.Add($backendPool)
            $cisNatRules = @()
            
            $cisNatRules += $cisNatRule1 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "JUSVC-$ResourceGroup" -FrontendIpConfiguration $PublicIP -Protocol Tcp -FrontendPort 8704 -BackendPort 8704
            $cisNatRules += $cisNatRule2 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "FIDSVC-$ResourceGroup" -FrontendIpConfiguration $PublicIP -Protocol Tcp -FrontendPort 8705 -BackendPort 8705            
            $cisNatRules += $cisNatRule3 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "TTSVC-$ResourceGroup" -FrontendIpConfiguration $PublicIP -Protocol Tcp -FrontendPort 8706 -BackendPort 8706
            $cisNatRules += $cisNatRule4 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "MDAPI-$ResourceGroup" -FrontendIpConfiguration $PublicIP -Protocol Tcp -FrontendPort 8722 -BackendPort 8722
            $cisNatRules += $cisNatRule5 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "SSSVC-$ResourceGroup" -FrontendIpConfiguration $PublicIP -Protocol Tcp -FrontendPort 8734 -BackendPort 8734                        

            Write-Host "Creating rules for machine TS-CIS1"

            foreach($rule in $cisNatRules){
                $nic.IpConfigurations[0].LoadBalancerInboundNatRules.Add($rule)
                $lb.InboundNatRules.Add($rule)
            }
                      
            $lb | Set-AzureRmLoadBalancer
            $nic | Set-AzureRmNetworkInterface 
        }
        "TS-DB1"{
            $nic.IpConfigurations[0].LoadBalancerBackendAddressPools.Add($backendPool)
            $db1NatRule = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "CASCDB-$ResourceGroup" -FrontendIpConfiguration $PublicIP -Protocol Tcp -FrontendPort 56075 -BackendPort 56075            

            Write-Host "Creating rules for machine TS-DB1"

            $nic.IpConfigurations[0].LoadBalancerInboundNatRules.Add($db1NatRule)
            $lb.InboundNatRules.Add($db1NatRule)

            $lb | Set-AzureRmLoadBalancer
            $nic | Set-AzureRmNetworkInterface
        }
        "TS-DB2"{
            $nic.IpConfigurations[0].LoadBalancerBackendAddressPools.Add($backendPool)
            $db2NatRules = @()
            $db2NatRules += $db2NatRule1 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "SSOSVC-$ResourceGroup" -FrontendIpConfiguration $PublicIP -Protocol Tcp -FrontendPort 8081 -BackendPort 8081
            $db2NatRules += $db2NatRule2 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "SSOWEB-$ResourceGroup" -FrontendIpConfiguration $PublicIP -Protocol Tcp -FrontendPort 80 -BackendPort 80            

            Write-Host "Creating rules for machine TS-DB2"

            foreach ($rule in $db2NatRules) {
                $nic.IpConfigurations[0].LoadBalancerInboundNatRules.Add($rule)
                $lb.InboundNatRules.Add($rule)
            }                        
            
            $lb | Set-AzureRmLoadBalancer
            $nic | Set-AzureRmNetworkInterface 
        }
    }
}

function Cleanup-PoolsAndRules ($Pools) {
    Write-Host "Removing existing pools and rules"

    $lb = Get-AzureRmLoadBalancer -Name $LoadBalancerName -ResourceGroupName $LoadBalancerResourceGroup
    
    Write-Host "Deleting Rules"
        $rulesToDelete = @()
        $rulesToDelete += $rule1 = Remove-AzureRmLoadBalancerInboundNatRuleConfig -LoadBalancer $lb -Name "TJSCPC-$ResourceGroup" -ErrorAction SilentlyContinue
        $rulesToDelete += $rule2 = Remove-AzureRmLoadBalancerInboundNatRuleConfig -LoadBalancer $lb -Name "TJSOYSTER-$ResourceGroup" -ErrorAction SilentlyContinue
        $rulesToDelete += $rule3 = Remove-AzureRmLoadBalancerInboundNatRuleConfig -LoadBalancer $lb -Name "OYSTERSVC-$ResourceGroup" -ErrorAction SilentlyContinue
        $rulesToDelete += $rule4 = Remove-AzureRmLoadBalancerInboundNatRuleConfig -LoadBalancer $lb -Name "JUSVC-$ResourceGroup" -ErrorAction SilentlyContinue
        $rulesToDelete += $rule5 = Remove-AzureRmLoadBalancerInboundNatRuleConfig -LoadBalancer $lb -Name "FIDSVC-$ResourceGroup" -ErrorAction SilentlyContinue
        $rulesToDelete += $rule6 = Remove-AzureRmLoadBalancerInboundNatRuleConfig -LoadBalancer $lb -Name "TTSVC-$ResourceGroup" -ErrorAction SilentlyContinue
        $rulesToDelete += $rule7 = Remove-AzureRmLoadBalancerInboundNatRuleConfig -LoadBalancer $lb -Name "MDAPI-$ResourceGroup" -ErrorAction SilentlyContinue
        $rulesToDelete += $rule8 = Remove-AzureRmLoadBalancerInboundNatRuleConfig -LoadBalancer $lb -Name "SSSVC-$ResourceGroup" -ErrorAction SilentlyContinue
        $rulesToDelete += $rule9 = Remove-AzureRmLoadBalancerInboundNatRuleConfig -LoadBalancer $lb -Name "CASCDB-$ResourceGroup" -ErrorAction SilentlyContinue
        $rulesToDelete += $rule10 = Remove-AzureRmLoadBalancerInboundNatRuleConfig -LoadBalancer $lb -Name "SSOSVC-$ResourceGroup" -ErrorAction SilentlyContinue
        $rulesToDelete += $rule11 = Remove-AzureRmLoadBalancerInboundNatRuleConfig -LoadBalancer $lb -Name "SSOWEB-$ResourceGroup" -ErrorAction SilentlyContinue     

     Write-Host "Removing pools"
        $poolsToRemove = @()
        foreach ($pool in $Pools){
            $poolsToRemove += $backendPool = Remove-AzureRmLoadBalancerBackendAddressPoolConfig -Name $pool.PoolName -LoadBalancer $lb -ErrorAction SilentlyContinue
        }
             
        $lb | Set-AzureRmLoadBalancer
     Write-Host "Rules and Pools deleted"    
}

$loadBalancer = Get-LoadBalancer
$publicIP = Get-AzureRmLoadBalancerFrontendIpConfig -Name $LoadBalancerFrontEnd -LoadBalancer $loadBalancer 

if($Cleanup){    
    Cleanup-PoolsAndRules -Pools $backendPools
}
else{
    Cleanup-PoolsAndRules -Pools $backendPools
    Sleep -Seconds 10
    foreach ($pool in $backendPools){
        Create-BackendPoolsandRules -Pool $pool -PublicIP $publicIP
    }
}
# USAGE: ServiceBus -password <password>
param([string]$userdomain, [string]$username,  [string]$password, [string]$server = "localhost")
   
#if ($password -eq "")
#{
#	"USAGE: ServiceBus -password <password> [-server <servername>]"
#	Exit
#}

#$fae_servicebus_sbmanagement_db = $env:username + "_SBManagementDB"
#$fae_servicebus_sbgateway_db = $env:username + "_SBGatewayDatabase"
#$fae_servicebus_sbmessagecontainer_db = $env:username + "_SBMessageContainer01"

$fae_servicebus_sbmanagement_db = "SbManagementDB"
$fae_servicebus_sbgateway_db = "SbGatewayDatabase"
$fae_servicebus_sbmessagecontainer_db = "SBMessageContainer01"

$dbManageUser = $username + "@" + $userdomain
$SBRunAsAccount= $userdomain + "\" + $username
$SBRunAsPassword=ConvertTo-SecureString -AsPlainText -Force -String $password -Verbose
$SBFarmDBConnectionString="Data Source=" + $server + "; Initial Catalog=" + $fae_servicebus_sbmanagement_db + "; Integrated Security=True;Encrypt=False"
$GatewayDBConnectionString="Data Source=" + $server + "; Initial Catalog=" + $fae_servicebus_sbgateway_db + "; Integrated Security=True;Encrypt=False"
$ContainerDBConnectionString="Data Source=" + $server + "; Initial Catalog=" + $fae_servicebus_sbmessagecontainer_db + "; Integrated Security=True;Encrypt=False"
$DefaultNamespace="ServiceBusDefaultNamespace"
$AdminGroup="Builtin\Administrators"
$SecureString = ConvertTo-SecureString -AsPlainText -Force -String "makeCert_1" -Verbose

$HostName = $env:computername + ".FAE.TFL.LOCAL"

### Functions ###

function DropDatabase
{
    param([string]$dbName)
    $sql = "
EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'" + $dbName + "'
GO
ALTER DATABASE [" + $dbName + "] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
DROP DATABASE [" + $dbName + "]
GO
"
    "Dropping " + $dbName
    Invoke-Sqlcmd $sql -ServerInstance $server -Verbose -QueryTimeout 180  -EA SilentlyContinue # 3 min
}

$setupRequired = $false

try
{
	$sbr = Get-SBAuthorizationRule -namespace $DefaultNamespace
	
	$sbr.ConnectionString
	
	$setupRequired = $false
}
Catch [system.exception]
{
  $setupRequired = $true;
}

if ($setupRequired -eq $true) {
	### Remove existing
	"Removing existing Service bus"

	# Remove Host
	"Removing host"
	Remove-SBHost -HostName $HostName -SBFarmDBConnectionString $SBFarmDBConnectionString -EA SilentlyContinue

	# Remove Namespace
	"Removing namespace"
	Remove-SBNamespace -Name $DefaultNamespace -Force -EA SilentlyContinue

	# Remove databases
	"Removing databases"
	DropDatabase -db $fae_servicebus_sbmanagement_db
	DropDatabase -db $fae_servicebus_sbgateway_db
	DropDatabase -db $fae_servicebus_sbmessagecontainer_db

	### Create New
	"Creating new Service bus"

	# Create Service Bus Instance
	"Creating farm"
	New-SBFarm -CertificateAutoGenerationKey $SecureString -SBFarmDBConnectionString $SBFarmDBConnectionString -InternalPortRangeStart 9200 -HttpsPort 9355 -TcpPort 9354 -MessageBrokerPort 9356 -RPHttpsport 9359 -AmqpPort 5672 -AmqpsPort 5671 -RunAsAccount $SBRunAsAccount -AdminGroup $AdminGroup -GatewayDBConnectionString $GatewayDBConnectionString -MessageContainerDBConnectionString $ContainerDBConnectionString -Verbose;
	"Adding host"
	Add-SBHost -CertificateAutoGenerationKey $SecureString -SBFarmDBConnectionString $SBFarmDBConnectionString -RunAsPassword $SBRunAsPassword -EnableFirewallRules $true
	"Creating namespace"
	New-SBNamespace -Name $DefaultNamespace -AddressingScheme 'Path' -ManageUsers $dbManageUser;
	"Info"
	Get-SBAuthorizationRule -namespace ServiceBusDefaultNamespace
}
function DropAndRecreateDatabase($dataSource, $database)
{
	$Script:exitCode = 0
$connectionString = "Data Source=$dataSource; " +
		"Integrated Security=SSPI; " +
		"Initial Catalog=master"

$connection = new-object system.data.SqlClient.SQLConnection($connectionString)
$query = @"
	if exists (select 1 from sys.databases where name = '{0}')
	begin
		alter database {0} set single_user with rollback immediate; 
		drop database {0};
	end
	create database {0};
	alter database {0} set quoted_identifier on;
	alter database {0} set recovery simple;
	alter database {0} modify file (name = {0}, size = 50MB);
	alter database {0} modify file (name = {0}_log, size = 5MB);
"@

$sqlQuery = $query -f $database

$command = new-object system.data.sqlclient.sqlcommand($sqlQuery, $connection)
$connection.Open()

if ($command.ExecuteNonQuery() -ne -1)
{
	$Script:exitCode = 1
} 

$connection.Close()

return $Script:exitCode;


}
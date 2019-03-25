

GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO



exec #AssertSqlJobExists 'DB $(databasename) - Capture CPU Utilisation';
exec #AssertSqlJobExists 'DB $(databasename) - Capture Daily Config Values';
exec #AssertSqlJobExists 'DB $(databasename) - Capture Disk Latency';
exec #AssertSqlJobExists 'DB $(databasename) - Capture Perfmon Counters';
exec #AssertSqlJobExists 'DB $(databasename) - Capture Procedure Performance';
exec #AssertSqlJobExists 'DB $(databasename) - Capture sp_whoisactive';
exec #AssertSqlJobExists 'DB $(databasename) - Capture File Info';
exec #AssertSqlJobExists 'DB $(databasename) - Purge Old Data';
exec #AssertSqlJobExists 'DB $(databasename) - Capture Wait Stats';
exec #AssertSqlJobExists 'DB $(databasename) - Capture SQLServer Logs';



GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

exec #AssertSqlJobExists 'CommandLog Cleanup';
exec #AssertSqlJobExists 'DB Maint - Audit';
exec #AssertSqlJobExists 'DB Maint - Backup System Databases Full';
exec #AssertSqlJobExists 'DB Maint - Backup User Databases Full';
exec #AssertSqlJobExists 'DB Maint - Backup User Databases Log';
exec #AssertSqlJobExists 'DB Maint - Cycle Error Logs';
exec #AssertSqlJobExists 'DB Maint - DBA STATS WeekDays';
exec #AssertSqlJobExists 'DB Maint - DBA STATS Weekend';
exec #AssertSqlJobExists 'DB Maint - DBCC System Databases';
exec #AssertSqlJobExists 'DB Maint - DBCC User Databases';
exec #AssertSqlJobExists 'DB Maint - Reindexing';
exec #AssertSqlJobExists 'Output File Cleanup';
exec #AssertSqlJobExists 'sp_delete_backuphistory';
exec #AssertSqlJobExists 'sp_purge_jobhistory';
if exists (select 1 from sys.databases where name = 'SSISDB')
begin
    exec #AssertSqlJobExists 'SSIS Server Maintenance Job';
end
exec #AssertSqlJobExists 'syspolicy_purge_history';

go

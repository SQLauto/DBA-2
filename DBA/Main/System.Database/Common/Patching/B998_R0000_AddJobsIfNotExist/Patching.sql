GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

select 'CommandLogCleanup'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\CommandLogCleanup.sql
-- need this space here - sql cmd mystery
EXEC [deployment].[SetScriptAsRun] 'CommandLogCleanup'
go


select 'DbMaintAudit'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DbMaintAudit.sql
-- need this space here - sql cmd mystery
EXEC [deployment].[SetScriptAsRun] 'DbMaintAudit'
go

select 'DBMaintBackupSystemDatabasesFull'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DBMaintBackupSystemDatabasesFull.sql
-- need this space here - sql cmd mystery
EXEC [deployment].[SetScriptAsRun] 'DBMaintBackupSystemDatabasesFull'
go

select 'DBMaintBackupUserDatabasesFull'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DBMaintBackupUserDatabasesFull.sql
-- need this space here - sql cmd mystery
EXEC [deployment].[SetScriptAsRun] 'DBMaintBackupUserDatabasesFull'
go

select 'DBMaintBackupUserDatabasesLog'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DBMaintBackupUserDatabasesLog.sql
-- need this space here - sql cmd mystery
EXEC [deployment].[SetScriptAsRun] 'DBMaintBackupUserDatabasesLog'
go

select 'DBMaintCycleErrorLogs'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DBMaintCycleErrorLogs.sql
-- need this space here - sql cmd mystery
EXEC [deployment].[SetScriptAsRun] 'DBMaintCycleErrorLogs'
go

select 'DBMaintDbaStatsWeekDays'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DBMaintDbaStatsWeekDays.sql
-- need this space here - sql cmd mystery
EXEC [deployment].[SetScriptAsRun] 'DBMaintDbaStatsWeekDays'
go

select 'DBMaintDbaStatsWeekend'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DBMaintDbaStatsWeekend.sql
-- need this space here - sql cmd mystery
EXEC [deployment].[SetScriptAsRun] 'DBMaintDbaStatsWeekend'
go

select 'DBMaintDbccSystemDatabases'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DBMaintDbccSystemDatabases.sql
-- need this space here - sql cmd mystery
EXEC [deployment].[SetScriptAsRun] 'DBMaintDbccSystemDatabases'
go

select 'DBMaintDbccUserDatabases'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DBMaintDbccUserDatabases.sql
-- need this space here - sql cmd mystery
EXEC [deployment].[SetScriptAsRun] 'DBMaintDbccUserDatabases'
go

select 'DbMaintReindexing'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DbMaintReindexing.sql
-- need this space here - sql cmd mystery
EXEC [deployment].[SetScriptAsRun] 'DbMaintReindexing'
go

select 'OutputFileCleanup'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\OutputFileCleanup.sql
-- need this space here - sql cmd mystery
EXEC [deployment].[SetScriptAsRun] 'OutputFileCleanup'
go

select 'sp_delete_backuphistory'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\sp_delete_backuphistory.sql
-- need this space here - sql cmd mystery
EXEC [deployment].[SetScriptAsRun] 'sp_delete_backuphistory'
go

select 'sp_purge_jobhistory'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\sp_purge_jobhistory.sql
-- need this space here - sql cmd mystery
EXEC [deployment].[SetScriptAsRun] 'sp_purge_jobhistory'
go

select 'SsisServerMaintenanceJob'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\SsisServerMaintenanceJob.sql
-- need this space here - sql cmd mystery
EXEC [deployment].[SetScriptAsRun] 'SsisServerMaintenanceJob'
go

select 'syspolicy_purge_history'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\syspolicy_purge_history.sql
-- need this space here - sql cmd mystery
EXEC [deployment].[SetScriptAsRun] 'syspolicy_purge_history'
go

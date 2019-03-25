
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO



select 'DbBaselineCaptureCpuUtilisation'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DbBaselineCaptureCpuUtilisation.sql

EXEC [deployment].[SetScriptAsRun] 'DbBaselineCaptureCpuUtilisation'
go

select 'DbBaselineCaptureDailyConfigValues'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DbBaselineCaptureDailyConfigValues.sql

EXEC [deployment].[SetScriptAsRun] 'DbBaselineCaptureDailyConfigValues'
go

select 'DbBaselineCaptureDiskLatency'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DbBaselineCaptureDiskLatency.sql

EXEC [deployment].[SetScriptAsRun] 'DbBaselineCaptureDiskLatency'
go

select 'DbBaselineCapturePerfmonCounters5Mins'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DbBaselineCapturePerfmonCounters5Mins.sql

EXEC [deployment].[SetScriptAsRun] 'DbBaselineCapturePerfmonCounters5Mins'
go

select 'DbBaselineCaptureProcPerformance'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DbBaselineCaptureProcPerformance.sql

EXEC [deployment].[SetScriptAsRun] 'DbBaselineCaptureProcPerformance'
go

select 'DbBaselineCaptureSpWhoIsActive'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DbBaselineCaptureSpWhoIsActive.sql

EXEC [deployment].[SetScriptAsRun] 'DbBaselineCaptureSpWhoIsActive'
go

select 'DbBaselineFileInfo'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DbBaselineFileInfo.sql

EXEC [deployment].[SetScriptAsRun] 'DbBaselineFileInfo'
go

select 'DbBaselinePurgeOldData'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DbBaselinePurgeOldData.sql

EXEC [deployment].[SetScriptAsRun] 'DbBaselinePurgeOldData'
go

select 'DbBaselineWaitStats'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DbBaselineWaitStats.sql

EXEC [deployment].[SetScriptAsRun] 'DbBaselineWaitStats'
go

select 'DbBaselineCaptureCPUbyDB'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DbBaselineCaptureCPUbyDB.sql

EXEC [deployment].[SetScriptAsRun] 'DbBaselineCaptureCPUbyDB'
go

select 'DbBaselineCaptureBufferUsage'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DbBaselineCaptureBufferUsage.sql

EXEC [deployment].[SetScriptAsRun] 'DbBaselineCaptureBufferUsage'
go


select 'DbBaselineCaptureDiskUsage'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DbBaselineCaptureDiskUsage.sql

EXEC [deployment].[SetScriptAsRun] 'DbBaselineCaptureDiskUsage'
go


select 'DbBaselineCaptureQueryPerformance'
go
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\DbBaselineCaptureQueryPerformance.sql

EXEC [deployment].[SetScriptAsRun] 'DbBaselineCaptureQueryPerformance'
go

select 'CaptureSQLServerLogs'
GO
--Run script
:r $(scriptPath)\B998_R0000_AddJobsIfNotExist\Jobs\CaptureSQLServerLogs.sql

EXEC [deployment].[SetScriptAsRun] 'CaptureSQLServerLogs'
go

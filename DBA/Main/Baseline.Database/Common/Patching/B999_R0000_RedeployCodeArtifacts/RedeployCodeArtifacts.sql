

SELECT 'XXX'
SELECT DB_NAME()  
SELECT 'XXX'

SELECT 'CaptureCpuUtilisation' 
GO 
:r $(scriptPath)\..\Schemas\capture\Proc\CpuUtilisation.sql
 
EXEC [deployment].[SetScriptAsRun] 'CpuUtilisation' 
GO 

SELECT 'LongRunningQueries' 
GO 
:r $(scriptPath)\..\Schemas\capture\Proc\LongRunningQueries.sql
 
EXEC [deployment].[SetScriptAsRun] 'LongRunningQueries' 
GO 

SELECT 'PerformanceDatabaseMacroMetrics' 
GO 
:r $(scriptPath)\..\Schemas\capture\Proc\PerformanceDatabaseMacroMetrics.sql
 
EXEC [deployment].[SetScriptAsRun] 'PerformanceDatabaseMacroMetrics' 
GO 

SELECT 'PerformanceDatabaseSprocMetrics' 
GO 
:r $(scriptPath)\..\Schemas\capture\Proc\PerformanceDatabaseSprocMetrics.sql
 
EXEC [deployment].[SetScriptAsRun] 'PerformanceDatabaseSprocMetrics' 
GO 

SELECT 'ProcedurePerformance' 
GO 
:r $(scriptPath)\..\Schemas\capture\Proc\ProcedurePerformance.sql
 
EXEC [deployment].[SetScriptAsRun] 'ProcedurePerformance' 
GO 

SELECT 'SlowRunningProcs' 
GO 
:r $(scriptPath)\..\Schemas\capture\Proc\SlowRunningProcs.sql
 
EXEC [deployment].[SetScriptAsRun] 'SlowRunningProcs' 
GO 

SELECT 'SqlPerfCounters' 
GO 
:r $(scriptPath)\..\Schemas\capture\Proc\SqlPerfCounters.sql
EXEC [deployment].[SetScriptAsRun] 'SqlPerfCounters' 
GO 

SELECT 'DiskLatency' 
GO 
:r $(scriptPath)\..\Schemas\capture\Proc\DiskLatency.sql
 
EXEC [deployment].[SetScriptAsRun] 'DiskLatency' 
GO 

SELECT 'FileInfo' 
GO 
:r $(scriptPath)\..\Schemas\capture\Proc\FileInfo.sql
 
EXEC [deployment].[SetScriptAsRun] 'FileInfo' 
GO 
 
SELECT 'ProcedurePerfomance' 
GO 
:r $(scriptPath)\..\Schemas\capture\Proc\ProcedurePerformance.sql
EXEC [deployment].[SetScriptAsRun] 'ProcedurePerformance' 
GO 

SELECT 'dropwhoisactivetables' 
GO 
:r $(scriptPath)\..\Schemas\capture\Proc\dropwhoisactivetables.sql
EXEC [deployment].[SetScriptAsRun] 'dropwhoisactivetables' 
GO 

SELECT 'PerfMonReport' 
GO 
:r $(scriptPath)\..\Schemas\capture\Proc\PerfMonReport.sql
EXEC [deployment].[SetScriptAsRun] 'PerfMonReport' 
GO 

SELECT 'PurgeOldData' 
GO 
:r $(scriptPath)\..\Schemas\capture\Proc\PurgeOldData.sql
EXEC [deployment].[SetScriptAsRun] 'PurgeOldData' 
GO 

SELECT 'ServerConfigReport' 
GO 
:r $(scriptPath)\..\Schemas\capture\Proc\ServerConfigReport.sql
EXEC [deployment].[SetScriptAsRun] 'ServerConfigReport' 
GO 

SELECT 'SysConfigReport' 
GO 
:r $(scriptPath)\..\Schemas\capture\Proc\SysConfigReport.sql
EXEC [deployment].[SetScriptAsRun] 'SysConfigReport' 
GO 

SELECT 'Split' 
GO 
:r $(scriptPath)\..\Schemas\capture\Func\Split.sql
EXEC [deployment].[SetScriptAsRun] 'Split' 
GO 

SELECT 'CaptureCacheUsagebyDB' 
GO 
:r $(scriptPath)\..\Schemas\capture\Proc\CacheUsagebyDB.sql
EXEC [deployment].[SetScriptAsRun] 'CacheUsagebyDB' 
GO 

SELECT 'CPUUsageByDatabase' 
GO 
:r $(scriptPath)\..\Schemas\capture\Proc\CPUUsageByDatabase.sql
EXEC [deployment].[SetScriptAsRun] 'CPUUsageByDatabase' 
GO 



SELECT 'sp_WhoIsActive' 
GO 
:r $(scriptPath)\..\Schemas\dbo\Proc\sp_whoisactive.sql
EXEC [deployment].[SetScriptAsRun] 'sp_whoisactive' 
GO 

SELECT 'Capture.WhoIsActiveData' 
GO 
:r $(scriptPath)\..\Schemas\capture\Proc\WhoIsActiveData.sql
EXEC [deployment].[SetScriptAsRun] 'WhoIsActiveData' 
GO 



SELECT 'DiskUsage' 
GO 
:r $(scriptPath)\..\Schemas\capture\Proc\DiskUsage.sql
EXEC [deployment].[SetScriptAsRun] 'DiskUsage' 
GO 

SELECT 'CollectWaitStats' 
GO 
:r $(scriptPath)\..\Schemas\capture\Proc\CollectWaitStats.sql
EXEC [deployment].[SetScriptAsRun] 'CollectWaitStats' 
GO 


SELECT 'QueryPerformance' 
GO 
:r $(scriptPath)\..\Schemas\capture\Proc\QueryPerformance.sql
EXEC [deployment].[SetScriptAsRun] 'QueryPerformance' 
GO 


SELECT 'SQLServerLogs' 
GO 
:r $(scriptPath)\..\Schemas\capture\Proc\SQLServerLogs.sql
EXEC [deployment].[SetScriptAsRun] 'SQLServerLogs' 
GO 

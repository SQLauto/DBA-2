go
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
go



exec #AssertProcExists 'capture', 'CpuUsage'
exec #AssertProcExists 'capture', 'LongRunningQueries' 
exec #AssertProcExists 'capture', 'PerformanceDatabaseMacroMetrics' 
exec #AssertProcExists 'capture', 'PerformanceDatabaseSprocMetrics' 
exec #AssertProcExists 'capture', 'ProcedurePerformance' 
exec #AssertProcExists 'capture', 'SlowRunningProcs'
exec #AssertProcExists 'capture', 'SqlPerfCounters' 
exec #AssertProcExists 'capture', 'DiskLatency'
exec #AssertProcExists 'capture', 'FileInformation'
exec #AssertProcExists 'capture', 'ProcedurePerformance' 
exec #AssertProcExists 'capture', 'dropwhoisactivetables'
exec #AssertProcExists 'capture', 'PerfMonReport' 
exec #AssertProcExists 'capture', 'SysConfigReport' 

exec #AssertProcExists 'capture', 'ServerConfigReport'
exec #AssertFunctionExists 'dbo', 'Split'
exec #AssertProcExists 'capture',  'CacheUsagebyDB'
exec #AssertProcExists 'capture',  'CPUUsageByDatabase' 
exec #AssertProcExists 'dbo',  'sp_whoisactive' 
exec #AssertProcExists 'capture',  'DiskUsage' 
exec #AssertProcExists 'capture',  'WhoIsActiveData' 
go

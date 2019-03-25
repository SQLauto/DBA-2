
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

exec #AssertTableExists 'capture', 'BlockedProcessReport';
exec #AssertTableExists 'capture', 'CacheUsageData';
exec #AssertTableExists 'capture', 'CacheUsageResults';
exec #AssertTableExists 'capture', 'FileStatsWindow';
exec #AssertTableExists 'capture', 'StoredProcedureWindow';
exec #AssertTableExists 'capture', 'StoredProcedureStats';
exec #AssertTableExists 'capture', 'FileStats';
exec #AssertTableExists 'capture', 'ConfigData';
exec #AssertTableExists 'capture', 'CpuUtilisation';
exec #AssertTableExists 'capture', 'CurrentPartitionState';
exec #AssertTableExists 'capture', 'DatabaseFiles';
exec #AssertTableExists 'capture', 'FileInfo';
exec #AssertTableExists 'capture', 'PerfMonData';
exec #AssertTableExists 'capture', 'ProcPerfCacheCollection';
exec #AssertTableExists 'capture', 'ServerConfig';
exec #AssertTableExists 'capture', 'WaitStats';
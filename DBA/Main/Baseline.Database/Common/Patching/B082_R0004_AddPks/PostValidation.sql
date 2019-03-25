
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

exec #AssertPrimaryKeyExists 'capture', 'BlockedProcessReport'
exec #AssertPrimaryKeyExists 'capture', 'ConfigData'
exec #AssertPrimaryKeyExists 'capture', 'CpuUtilisation'
exec #AssertPrimaryKeyExists 'capture', 'CurrentPartitionState'
exec #AssertPrimaryKeyExists 'capture', 'ProcPerfCacheCollection'
exec #AssertPrimaryKeyExists 'capture', 'ServerConfig'
exec #AssertPrimaryKeyExists 'capture', 'WaitStats'
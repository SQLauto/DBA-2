
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

exec #AssertColumnExists 'capture', 'CacheUsagebyDbData',  'MemoryUsedByInstanceMB'
exec #AssertColumnExists 'capture', 'CacheUsagebyDbData',  'TotalAllocatedInstanceMemoryMB'
exec #AssertColumnExists 'capture', 'CacheUsagebyDbData',  'TotalServerMemoryMB'

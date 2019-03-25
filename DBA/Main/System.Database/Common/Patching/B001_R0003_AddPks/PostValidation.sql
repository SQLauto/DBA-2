
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

exec #AssertPrimaryKeyExists 'dbo', 'AlertHistory'
exec #AssertPrimaryKeyExists 'dbo', 'ErrorLog'
exec #AssertPrimaryKeyExists 'dbo', 'FragmentationLevels'
exec #AssertPrimaryKeyExists 'dbo', 'Job_Failures'
exec #AssertPrimaryKeyExists 'dbo', 'JobAnalysis'
exec #AssertPrimaryKeyExists 'dbo', 'LocalDrives'
exec #AssertPrimaryKeyExists 'dbo', 'loginstuff'
exec #AssertPrimaryKeyExists 'dbo', 'PhysicalStats'
exec #AssertPrimaryKeyExists 'dbo', 'ProcPerfCacheCollection'
exec #AssertPrimaryKeyExists 'dbo', 'ReindexHistory'
exec #AssertPrimaryKeyExists 'dbo', 'TableSizeLog'
exec #AssertPrimaryKeyExists 'dbo', 'UptimeHistory'

go




go
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
go

exec #AssertProcExists 'dbo', 'CheckLinkedServer';
exec #AssertProcExists 'dbo', 'CommandExecute';
exec #AssertProcExists 'dbo', 'CreateRestoreScript';
exec #AssertProcExists 'dbo', 'DatabaseBackup';
exec #AssertProcExists 'dbo', 'DatabaseIntegrityCheck';
exec #AssertProcExists 'dbo', 'dba_indexDefrag_sp'
exec #AssertProcExists 'dbo', 'FragmentationCheck'
exec #AssertProcExists 'dbo', 'GetAuditData'
exec #AssertProcExists 'dbo', 'GetPartitionInfo' 
exec #AssertProcExists 'dbo', 'IndexOptimize'
exec #AssertProcExists 'dbo', 'JobDurations'
exec #AssertProcExists 'dbo', 'JobFailures'
exec #AssertProcExists 'dbo', 'JobHistory'
exec #AssertProcExists 'dbo', 'JobReporting'
exec #AssertProcExists 'dbo', 'Reindex'
exec #AssertProcExists 'dbo', 'Reindexing'
exec #AssertProcExists 'dbo', 'ResourceConsumers'
exec #AssertProcExists 'dbo', 'ServiceBrokerInfo'
exec #AssertProcExists 'dbo', 'sp_AskBrent'
exec #AssertProcExists 'dbo', 'sp_Blitz'
exec #AssertProcExists 'dbo', 'sp_BlitzCache'
exec #AssertProcExists 'dbo', 'sp_BlitzIndex'
exec #AssertProcExists 'dbo', 'sp_BlitzTrace'
exec #AssertProcExists 'dbo', 'sp_LogShippingLight'
exec #AssertProcExists 'dbo', 'sp_WhoIsActive'
exec #AssertProcExists 'dbo', 'sp_WriteTextFile'
exec #AssertProcExists 'dbo', 'spWriteStringToFile'
exec #AssertProcExists 'dbo', 'TableSize'
exec #AssertProcExists 'maint', 'RestoreScriptGenerateFromBackup'
exec #AssertProcExists 'support', 'ErrorLogsOfInterestGet'
go

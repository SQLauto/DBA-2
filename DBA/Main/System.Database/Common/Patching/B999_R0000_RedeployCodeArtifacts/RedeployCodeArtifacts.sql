SELECT 'CheckLinkedServer'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\CheckLinkedServer.sql
EXEC [deployment].[SetScriptAsRun] 'CheckLinkedServer'
GO

SELECT 'CommandExecute'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\CommandExecute.sql
EXEC [deployment].[SetScriptAsRun] 'CommandExecute' 
GO

SELECT 'CreateRestoreScript'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\CreateRestoreScript.sql
EXEC [deployment].[SetScriptAsRun] 'CreateRestoreScript' 
GO

SELECT 'DatabaseBackup'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\DatabaseBackup.sql
EXEC [deployment].[SetScriptAsRun] 'DatabaseBackup' 
GO

SELECT 'DatabaseIntegrityCheck'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\DatabaseIntegrityCheck.sql
EXEC [deployment].[SetScriptAsRun] 'DatabaseIntegrityCheck' 
GO

SELECT 'dba_indexDefrag_sp'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\dba_indexDefrag_sp.sql
EXEC [deployment].[SetScriptAsRun] 'dba_indexDefrag_sp' 
GO

SELECT 'FragmentationCheck'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\FragmentationCheck.sql
EXEC [deployment].[SetScriptAsRun] 'FragmentationCheck' 
GO

SELECT 'GetAuditData'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\GetAuditData.sql
EXEC [deployment].[SetScriptAsRun] 'GetAuditData' 
GO

SELECT 'GetPartitionInfo'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\GetPartitionInfo.sql
EXEC [deployment].[SetScriptAsRun] 'GetPartitionInfo' 
GO

SELECT 'IndexOptimize'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\IndexOptimize.sql
EXEC [deployment].[SetScriptAsRun] 'IndexOptimize' 
GO

SELECT 'JobDurations'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\JobDurations.sql
EXEC [deployment].[SetScriptAsRun] 'JobDurations' 
GO

SELECT 'JobFailures'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\JobFailures.sql
EXEC [deployment].[SetScriptAsRun] 'JobFailures' 
GO

SELECT 'JobHistory'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\JobHistory.sql
EXEC [deployment].[SetScriptAsRun] 'JobHistory' 
GO

SELECT 'JobReporting'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\JobReporting.sql
EXEC [deployment].[SetScriptAsRun] 'JobReporting' 
GO

SELECT 'Reindex'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\Reindex.sql
EXEC [deployment].[SetScriptAsRun] 'Reindex' 
GO

SELECT 'Reindexing'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\Reindexing.sql
EXEC [deployment].[SetScriptAsRun] 'Reindexing' 
GO

SELECT 'ResourceConsumers'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\ResourceConsumers.sql
EXEC [deployment].[SetScriptAsRun] 'ResourceConsumers' 
GO

SELECT 'ServiceBrokerInfo'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\ServiceBrokerInfo.sql
EXEC [deployment].[SetScriptAsRun] 'ServiceBrokerInfo' 
GO

SELECT 'sp_AskBrent'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\sp_AskBrent.sql
EXEC [deployment].[SetScriptAsRun] 'sp_AskBrent' 
GO

SELECT 'sp_Blitz'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\sp_Blitz.sql
EXEC [deployment].[SetScriptAsRun] 'sp_Blitz' 
GO

SELECT 'sp_BlitzCache'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\sp_BlitzCache.sql
EXEC [deployment].[SetScriptAsRun] 'sp_BlitzCache' 
GO

SELECT 'sp_BlitzIndex'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\sp_BlitzIndex.sql
EXEC [deployment].[SetScriptAsRun] 'sp_BlitzIndex'
GO

SELECT 'sp_BlitzTrace'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\sp_BlitzTrace.sql
EXEC [deployment].[SetScriptAsRun] 'sp_BlitzTrace'
GO

SELECT 'sp_LogShippingLight'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\sp_LogShippingLight.sql
EXEC [deployment].[SetScriptAsRun] 'sp_LogShippingLight' 
GO

SELECT 'sp_WhoIsActive'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\sp_WhoIsActive.sql
EXEC [deployment].[SetScriptAsRun] 'sp_WhoIsActive' 
GO

SELECT 'sp_WriteTextFile'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\sp_WriteTextFile.sql
EXEC [deployment].[SetScriptAsRun] 'sp_WriteTextFile' 
GO

SELECT 'spWriteStringToFile'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\spWriteStringToFile.sql
EXEC [deployment].[SetScriptAsRun] 'spWriteStringToFile' 
GO

SELECT 'TableSize'
GO
:r $(scriptPath)\..\Schemas\dbo\Proc\TableSize.sql
EXEC [deployment].[SetScriptAsRun] 'TableSize' 
GO

SELECT 'RestoreScriptGenerateFromBackup'
GO
:r $(scriptPath)\..\Schemas\maint\Proc\RestoreScriptGenerateFromBackup.sql
EXEC [deployment].[SetScriptAsRun] 'RestoreScriptGenerateFromBackup' 
GO

SELECT 'RestoreScriptGenerateForSimpleRestore'
GO
:r  $(scriptPath)\..\Schemas\maint\Proc\RestoreScriptGenerateForSimpleRestore.sql
EXEC [deployment].[SetScriptAsRun] 'RestoreScriptGenerateForSimpleRestore'
GO

SELECT 'ErrorLogsOfInterestGet'
GO
:r $(scriptPath)\..\Schemas\support\Proc\ErrorLogsOfInterestGet.sql
EXEC [deployment].[SetScriptAsRun] 'ErrorLogsOfInterestGet' 
GO
SELECT 'RestoreScriptGenerateForSimpleRestore' 
GO 
:r $(scriptPath)\..\Schemas\maint\Proc\RestoreScriptGenerateForSimpleRestore.sql
EXEC [deployment].[SetScriptAsRun] 'RestoreScriptGenerateForSimpleRestore' 
GO 
SELECT 'RestoreScriptGenerateFromBackup' 
GO 
:r $(scriptPath)\..\Schemas\maint\Proc\RestoreScriptGenerateFromBackup.sql
EXEC [deployment].[SetScriptAsRun] 'RestoreScriptGenerateFromBackup' 
GO 




 

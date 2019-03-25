
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @columnExists bit 
exec #ColumnExists 'capture', 'CacheUsagebyDbData',  'MemoryUsedByInstanceMB',@columnExists out

if (@columnExists = 0)
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION
			ALTER TABLE [capture].[CacheUsagebyDBData]
			ADD [MemoryUsedByInstanceMB] [float] NULL,
			[TotalAllocatedInstanceMemoryMB] [float] NULL,
			[TotalServerMemoryMB] [float] NULL;
			
			ALTER TABLE [capture].[CacheUsagebyDBData] DROP COLUMN PullPeriod;
			ALTER TABLE [capture].[CacheUsagebyDBData] DROP COLUMN EndTime;
			EXEC sp_rename '[capture].[CacheUsagebyDBData].[StartTime]', 'CaptureDate', 'COLUMN';
			ALTER TABLE [capture].[CacheUsagebyDbResults] DROP COLUMN CaptureDate;
		COMMIT TRANSACTION;
	END TRY
    BEGIN CATCH
		IF @@trancount > 0 ROLLBACK TRANSACTION;
		THROW;
    END CATCH
END 
GO
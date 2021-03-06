
EXEC #CreateDummyStoredProcedureIfNotExists 'dbo', 'Reindexing'
GO

ALTER PROCEDURE [dbo].[Reindexing] @db_name varchar(400), @MaxHours int
AS

SET NOCOUNT ON

DECLARE @EntryDate DATETIME, @dbid INT, @StartTime DATETIME, @referenceDate DATETIME, @StartTimeInMinutes INT, @fragmentThreshold INT, @logThreshold INT, @indexThreshold INT, @idleThreshold INT, @SQL VARCHAR(2000)
SET @EntryDate = CAST(CONVERT(VARCHAR(11),GETDATE(),113) AS DATETIME)
SET @dbid = DB_ID(@db_name)
SET @referenceDate = '01 Jan 2000'
SET @StartTime = GETDATE()
SET @StartTimeInMinutes = DATEDIFF(MINUTE, @referenceDate, @StartTime)
SET @fragmentThreshold = 25			-- 25%, defragmentation required to trigger rebuild process
SET @logThreshold = 50				-- 50%, log usage to backup log instead of rebuilding index
SET @indexThreshold = 15000000		-- 15GB, total size of indexes to rebuild should not exceed this number
SET @idleThreshold = 120			-- 120 min, time between index rebuilds to trigger DBA alerts

-- CREATE THE TEMP TABLE TO STORE THE TABLES TO EXCLUDE
IF OBJECT_ID('tempdb..#TablesToExcludeReIndex') IS NOT NULL 
	DROP TABLE [dbo].[#TablesToExcludeReIndex]
CREATE TABLE #TablesToExcludeReIndex (
	[database_name] [varchar](100) NOT NULL,
	[object_id] [int] NOT NULL,
	[table_name] [varchar](100) NOT NULL
)

BEGIN TRY
	SET @SQL = 'USE ' + @db_name + ' SELECT DISTINCT c.TABLE_CATALOG, i.[object_id], c.TABLE_NAME
			FROM sys.indexes i JOIN INFORMATION_SCHEMA.COLUMNS c
			ON object_name(i.object_id) = c.TABLE_NAME
			WHERE c.DATA_TYPE IN (''text'', ''ntext'', ''image'', ''xml'') 
			OR (c.DATA_TYPE IN (''varchar'', ''nvarchar'', ''varbinary'') AND c.CHARACTER_MAXIMUM_LENGTH = -1)' 
	INSERT INTO #TablesToExcludeReIndex 
	EXEC (@SQL)
END TRY
BEGIN CATCH
	PRINT ERROR_MESSAGE()
END CATCH

--CHECK TO SEE IF ANY REINDEXING HAS BEEN DONE BY CHECKING THE RECORD_COUNT COLUMN
IF (SELECT COUNT(*) FROM system.dbo.PhysicalStats WHERE EntryDate = @EntryDate AND database_id = @dbid AND record_count IS NOT NULL) = 0
BEGIN
	DELETE FROM system.dbo.PhysicalStats WHERE EntryDate = @EntryDate AND database_id = @dbid
	
	--INSERT THE LATEST STATS INTO THE SYSTEM TABLE
	INSERT INTO system.dbo.PhysicalStats (EntryDate, database_id, object_id, index_id, partition_number, index_type_desc, alloc_unit_type_desc, index_depth, index_level, avg_fragmentation_in_percent, fragment_count, avg_fragment_size_in_pages, page_count, avg_page_space_used_in_percent, record_count, ghost_record_count, version_ghost_record_count, min_record_size_in_bytes, max_record_size_in_bytes, avg_record_size_in_bytes, forwarded_record_count)
		SELECT @EntryDate [EntryDate]
		,[database_id]
		,[object_id]
		,[index_id]
		,[partition_number]
		,[index_type_desc]
		,[alloc_unit_type_desc]
		,[index_depth]
		,[index_level]
		,[avg_fragmentation_in_percent]
		,[fragment_count]
		,[avg_fragment_size_in_pages]
		,[page_count]
		,[avg_page_space_used_in_percent]
		,[record_count]
		,[ghost_record_count]
		,[version_ghost_record_count]
		,[min_record_size_in_bytes]
		,[max_record_size_in_bytes]
		,[avg_record_size_in_bytes]
		,[forwarded_record_count] 
	FROM sys.dm_db_index_physical_stats (@dbid, NULL, NULL , NULL, 'DETAILED')
	WHERE [index_id] > 0
	
	--TIMESTAMPING GOOD INDEXES AS DONE
	UPDATE system.dbo.PhysicalStats
	SET record_count = @StartTimeInMinutes
	WHERE database_id = @dbid
		AND entryDate = @EntryDate
		AND avg_fragmentation_in_percent < @fragmentThreshold
		AND record_count IS NULL

END

--CREATE LIST OF INDEXES TO REINDEX
IF OBJECT_ID('tempdb..#work_to_do') IS NOT NULL 
	DROP TABLE [dbo].#work_to_do
CREATE TABLE #work_to_do (
	[Schema] VARCHAR(10),
	[TableName] VARCHAR(100),
	[IndexName] VARCHAR(100),
	[index_id] INT,
	[object_id] INT,
	[partition_number] INT,
	[avg_fragmentation_in_percent] FLOAT,
	[IndexSizeKB] BIGINT
)
SET @SQL = 
	'USE ' + @db_name + ' SELECT s.name AS ''Schema'', t.name AS ''TableName'', i.name AS ''IndexName'', p.index_id, p.object_id, p.partition_number, p.avg_fragmentation_in_percent, SUM(ps.used_page_count) * 8 AS ''IndexSizeKB''
	FROM system.dbo.PhysicalStats p JOIN sys.tables t ON p.object_id = t.object_id
	JOIN sys.indexes i ON t.object_id = i.object_id and p.index_id = i.index_id
	JOIN sys.objects o ON t.object_id = o.object_id
	JOIN sys.schemas s ON o.schema_id = s.schema_id
	JOIN sys.dm_db_partition_stats ps ON i.object_id = ps.object_id AND i.index_id = ps.index_id
	WHERE database_id = ' + CAST(@dbid AS VARCHAR) +
	' AND entryDate = ''' + CAST(@EntryDate AS VARCHAR) + '''' +
	' AND avg_fragmentation_in_percent >= ' + CAST(@fragmentThreshold AS VARCHAR) +
	' AND p.record_count IS NULL
	GROUP BY s.name, t.name, i.name, p.index_id, p.object_id, p.partition_number, p.avg_fragmentation_in_percent'
INSERT INTO #work_to_do
	EXEC (@SQL)
DELETE FROM #work_to_do WHERE object_id in (SELECT object_id FROM #TablesToExcludeReIndex)

IF (SELECT COUNT(*) FROM #work_to_do) > 0
BEGIN
	IF OBJECT_ID('tempdb..#LogCheck') IS NOT NULL 
		DROP TABLE #LogCheck
	CREATE TABLE #LogCheck(
		DatabaseName	VARCHAR(100),
		LogSizeMB		REAL,
		LogUsedPercent	REAL,
		StatusFlag		INT)
	
	INSERT INTO #LogCheck
	EXEC ('dbcc sqlperf(logspace)')

	--CHECK IF LOG IS > THRESHOLD
	--IF (SELECT LogUsedPercent FROM #LogCheck WHERE DatabaseName = @db_name) > @logThreshold
	--BEGIN
	--	PRINT 'Log usage exceeded ' + CAST(@logThreshold AS VARCHAR) + '%, backing up log...'
	--	--BACKUP LOG
	--	DECLARE @fileName VARCHAR(200), @fileDate VARCHAR(200), @path VARCHAR(200)
	--	SET @fileDate =CONVERT(VARCHAR(17),GETDATE(),112)+REPLACE(CONVERT(VARCHAR(17),GETDATE(),108),':','')
	--	SET @path = 'Z:\Backups\'

	--	EXEC msdb.dbo.sp_start_job N'DB Maint - Log Backups'
		
	--END
	----LOG < THRESHOLD, PROCEED TO GATHER INDEXES TO REINDEX
	--ELSE
	BEGIN
		DECLARE @firstLoop BIT, @rebuildSchema VARCHAR(10), @rebuildTable VARCHAR(100), @rebuildObjectID INT, @rebuildIndex VARCHAR(100), @rebuildIndexID INT, @rebuildPartitionNum INT, @rebuildIndexSize BIGINT
		SET @firstLoop = 1
		
		WHILE @indexThreshold > 0
		BEGIN
			SELECT TOP 1
				@rebuildSchema = [Schema],
				@rebuildTable = [TableName],
				@rebuildObjectID = [object_id],
				@rebuildIndex = [IndexName],
				@rebuildIndexID = [index_id],
				@rebuildPartitionNum = [partition_number],
				@rebuildIndexSize = [IndexSizeKB]
			FROM #work_to_do
			WHERE IndexSizeKB <= CASE WHEN @firstLoop = 1 THEN IndexSizeKB ELSE @indexThreshold END --we need to pull at least 1 index to rebuild, so omitting criteria on 1st run
			ORDER BY IndexSizeKB DESC
			
			SET @firstLoop = 0

			IF @rebuildIndex IS NOT NULL
			BEGIN
				BEGIN TRY
					PRINT 'Rebuilding Index ' + @rebuildIndex + ': Index Size = ' + CAST(@rebuildIndexSize AS VARCHAR) + ', Threshold = ' + CAST(@indexThreshold AS VARCHAR)
					SET @SQL = N'ALTER INDEX ['+ @rebuildIndex + N'] ON [' +  + @db_name + '].[' + @rebuildSchema + N'].[' + @rebuildTable + N'] REBUILD';
					PRINT @SQL
					IF @rebuildPartitionNum > 1
						SET @SQL = @SQL + N' PARTITION=' + CAST(@rebuildPartitionNum AS NVARCHAR(10))
					ELSE
						SET @SQL = @SQL + ' WITH (ONLINE = ON)'
					EXEC (@SQL)

					--UPDATE TABLE TO INDICIATE THAT THIS INDEX HAS BEEN REINDEXED
					UPDATE system.dbo.PhysicalStats
					SET record_count = DATEDIFF(MINUTE, @referenceDate, GETDATE()),
						max_record_size_in_bytes = @rebuildIndexSize
					WHERE object_id = @rebuildObjectID
						AND database_id = @dbid
						AND index_id = @rebuildIndexID
						AND EntryDate = @EntryDate
					
					DELETE FROM #work_to_do WHERE TableName = @rebuildTable AND IndexName = @rebuildIndex
					
					SET @indexThreshold = @indexThreshold - @rebuildIndexSize
					SET @rebuildIndex = NULL

					PRINT N'  Executed: ' + @SQL;
					IF GETDATE() > DATEADD(HOUR, @MaxHours, @StartTime)
					BEGIN
						PRINT 'Exiting due to max hours reached'
						BREAK
					END
				END TRY
				BEGIN CATCH
					PRINT ERROR_MESSAGE()
				END CATCH
			END
			ELSE
			BEGIN
				PRINT 'No more valid indexes to rebuild for this iteration'
				BREAK -- no valid index to rebuild (either because we are done or they are too big for this run)
			END
		END
	END

	--CHECK IF QUALIFIED INDEXES HAVE NOT BEEN REBUILT FOR A CERTAIN AMOUNT OF TIME
	DECLARE @lastRebuildTime BIGINT
	SELECT @lastRebuildTime = MAX(record_count) FROM system.dbo.PhysicalStats WHERE database_id  = @dbid AND EntryDate = @EntryDate AND record_count IS NOT NULL
	IF (@lastRebuildTime IS NOT NULL AND @StartTimeInMinutes-@lastRebuildTime >= @idleThreshold)
	BEGIN
		DECLARE @logUsage varchar(10)
		SELECT @logUsage = CONVERT(VARCHAR(20),ROUND(LogUsedPercent,2)) FROM #LogCheck WHERE DatabaseName  = @db_name
		PRINT 'We have a problem!'
		PRINT 'Reindexing has not occur for ' + @db_name + ' for ' + CAST(@StartTimeInMinutes-@lastRebuildTime AS VARCHAR) + ' minutes.'
		PRINT 'Current transaction log usage is ' + @logUsage + '%.'
		
		RETURN 
	END
	
	DROP TABLE #LogCheck
END

-- DROP THE TEMPORARY TABLES
DROP TABLE #work_to_do
DROP TABLE #TablesToExcludeReIndex


GO

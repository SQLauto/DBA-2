EXEC #CreateDummyStoredProcedureIfNotExists 'admin', 'Partitioning_SplitTable'
GO
ALTER PROCEDURE [admin].[Partitioning_SplitTable]
(
	@SourceTableSchema NVARCHAR(128),
	@SourceTableName NVARCHAR(128),
	@DestinationTableSchema NVARCHAR(128),
	@DestinationTableName NVARCHAR(128),
	@Strategy TINYINT
)
AS
BEGIN

	DECLARE @message NVARCHAR(2047);

	IF (NOT EXISTS(SELECT 1 FROM sys.tables t INNER JOIN sys.schemas sc ON t.schema_id = sc.schema_id WHERE t.name = @SourceTableName and sc.name = @SourceTableSchema))
	BEGIN
		SET @message = @SourceTableSchema + '.' + @SourceTableName + ' does not exist';
		RAISERROR (@message, 16, 1);
	END

	IF (NOT EXISTS(SELECT 1 FROM sys.tables t INNER JOIN sys.schemas sc ON t.schema_id = sc.schema_id WHERE t.name = @DestinationTableName and sc.name = @DestinationTableSchema))
	BEGIN
		SET @message = @DestinationTableSchema + '.' + @DestinationTableName + ' does not exist';
		RAISERROR (@message, 16, 1);
	END

	DECLARE @sql NVARCHAR(MAX);

	-- Find boundary values and files that are found on source table but not destination
	DECLARE partitionCursor CURSOR FOR 
		SELECT ar.[boundary_value], ar.[filegroup], ar.FileGroupDataSpaceId FROM 
		(
			SELECT [boundary_value], [filegroup], FileGroupDataSpaceId, CountOfFiles, partition_number 
			FROM [admin].[View_PartitionRanges] 
			WHERE [partition_function] = 'PF_' + @SourceTableName
		) ar
		LEFT JOIN
		(
			SELECT [boundary_value], FileGroupDataSpaceId, CountOfFiles 
			FROM [admin].[View_PartitionRanges] 
			WHERE [partition_function] = 'PF_' + @DestinationTableName
		) ars
		ON ar.boundary_value = ars.boundary_value and ar.CountOfFiles <= ars.CountOfFiles
		WHERE ars.boundary_value IS NULL
		ORDER BY partition_number;

	DECLARE @boundaryValue SQL_VARIANT;
	DECLARE @fileGroupName SYSNAME;
	DECLARE @fileGroupDataSpaceId INT;
	
	OPEN partitionCursor;

	BEGIN TRY

		FETCH NEXT FROM partitionCursor INTO @boundaryValue, @fileGroupName, @fileGroupDataSpaceId;

		WHILE @@FETCH_STATUS = 0
		BEGIN 

			-- ENSURE THAT THE NEW FILE GROUP EXISTS --
			DECLARE @newFileGroupName VARCHAR(MAX) = REPLACE(@fileGroupName, @SourceTableName, @DestinationTableName);
			IF NOT EXISTS(SELECT 1 FROM sys.filegroups WHERE name = @newFileGroupName)
			BEGIN

				SET @sql = 'ALTER DATABASE ' + DB_NAME() + ' ADD FILEGROUP ' + @newFileGroupName + ';';
				EXECUTE (@sql);

			END
	
			SET @sql = 'ALTER PARTITION SCHEME PS_' + @DestinationTableName + ' NEXT USED ' +  @newFileGroupName + ';';
			EXECUTE (@sql);

			-- CREATE THE FILES IN THIS FILE GROUP --
			DECLARE FileCursor CURSOR FOR 
				SELECT physical_name, size, max_size, growth, is_percent_growth 
				FROM sys.database_files f 
				WHERE f.data_space_id = @fileGroupDataSpaceId;

			DECLARE @physicalName NVARCHAR(260);
			DECLARE @size INT;
			DECLARE @maxSize INT;
			DECLARE @growth INT;
			DECLARE @isPercentGrowth BIT;
			DECLARE @index INT = 0;
			
			OPEN FileCursor;

			BEGIN TRY

				FETCH NEXT FROM FileCursor INTO @physicalName, @size, @maxSize, @growth, @isPercentGrowth;
				WHILE @@FETCH_STATUS = 0
				BEGIN

					DECLARE @logicalFileName NVARCHAR(260) = RIGHT(@newFileGroupName, LEN(@newFileGroupName) - 3) + '_' + CAST(@index AS VARCHAR(255));
					
					DECLARE @physicalFileName NVARCHAR(260) = 
						LEFT(@physicalName, LEN(@physicalName) - CHARINDEX('\', REVERSE(@physicalName)) + 1) + DB_NAME() + '_' + @logicalFileName + '.ndf';

					IF NOT EXISTS(SELECT 1 FROM sys.database_files WHERE physical_name = @physicalFileName)
					BEGIN
						SET @sql = 'ALTER DATABASE ' + DB_NAME() + ' ADD FILE (NAME=''' + @logicalFileName + ''', FILENAME=''' + @physicalFileName + ''', SIZE = ' + CAST(@size * 8 AS VARCHAR) + ' KB, MAXSIZE = ' + CASE WHEN @maxSize < 0 THEN 'UNLIMITED' ELSE CAST(@maxSize * 8 AS VARCHAR) + ' KB' END + ', FILEGROWTH = ' + CASE WHEN @isPercentGrowth = 0 THEN CAST(@growth * 8 AS VARCHAR) + ' KB' ELSE CAST(@growth AS VARCHAR) + ' %' END + ') TO FILEGROUP ' + @newFileGroupName + ';';
						EXECUTE (@sql);
					END

					FETCH NEXT FROM FileCursor INTO @physicalName, @size, @maxSize, @growth, @isPercentGrowth;
					SET @index = @index + 1;
				END

				CLOSE FileCursor;
				DEALLOCATE FileCursor;
			
			END TRY
			BEGIN CATCH

				CLOSE FileCursor;
				DEALLOCATE FileCursor;
				THROW;

			END CATCH

			-- SPLIT THE PARTITION FUNCTION --
			EXEC admin.Partitioning_SplitRange @Strategy, @boundaryValue, @DestinationTableName;

			FETCH NEXT FROM partitionCursor INTO @boundaryValue, @fileGroupName, @fileGroupDataSpaceId;

		END

		CLOSE partitionCursor;
		DEALLOCATE partitionCursor;

	END TRY
	BEGIN CATCH

		CLOSE partitionCursor;
		DEALLOCATE partitionCursor;
		THROW;

	END CATCH

END
GO

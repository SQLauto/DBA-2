EXEC #CreateDummyStoredProcedureIfNotExists @SchemaName = 'admin', @ProcedureName = 'Partitioning_Configure'
GO

ALTER PROCEDURE [admin].[Partitioning_Configure]
(
	@RequiredFileGroups AS admin.RequiredPartition READONLY,
	@RequiredFiles AS admin.RequiredFile READONLY,
	@TableName NVARCHAR(128),
	@Strategy TINYINT
)
AS
BEGIN

	DECLARE @sql NVARCHAR(MAX);

	-- Find boundary values and files that are found on source table but not destination
	DECLARE partitionCursor CURSOR FOR SELECT InitialBoundaryValue, BoundaryValue FROM @RequiredFileGroups ORDER BY InitialBoundaryValue;

	DECLARE @initialBoundaryValue SQL_VARIANT;
	DECLARE @boundaryValue SQL_VARIANT;
	DECLARE @fileGroupDataSpaceId INT;
	
	OPEN partitionCursor;

	BEGIN TRY

		FETCH NEXT FROM partitionCursor INTO @initialBoundaryValue,@boundaryValue;

		WHILE @@FETCH_STATUS = 0
		BEGIN 

			-- ENSURE THAT THE NEW FILE GROUP EXISTS --
			DECLARE @newFileGroupName VARCHAR(MAX) = 'FG_' + @TableName + '_' + [admin].PartitioningFormatBoundary(@initialBoundaryValue, @Strategy);
			IF NOT EXISTS(SELECT 1 FROM sys.filegroups WHERE name = @newFileGroupName)
			BEGIN

				SET @sql = 'ALTER DATABASE ' + DB_NAME() + ' ADD FILEGROUP ' + @newFileGroupName + ';';
				EXECUTE (@sql);

				-- Additional Logging Added 2015/10/06
				INSERT INTO admin.PartitionLog (EntryDate,ObjectID,DateRangeSwitchedInt,
					DateRangeSwitchedDate,RowCountSwitched,Success,Comments)
				VALUES (GETDATE(),NULL,NULL,NULL,NULL,1,@sql);
				-- Additional Logging Added 2015/10/06

			END

			SET @sql = 'ALTER PARTITION SCHEME PS_' + @TableName + ' NEXT USED ' +  @newFileGroupName + ';';
			EXECUTE (@sql);

			-- Additional Logging Added 2015/10/06
			INSERT INTO admin.PartitionLog (EntryDate,ObjectID,DateRangeSwitchedInt,
				DateRangeSwitchedDate,RowCountSwitched,Success,Comments)
			VALUES (GETDATE(),NULL,NULL,NULL,NULL,1,@sql);
			-- Additional Logging Added 2015/10/06
	
			-- CREATE THE FILES IN THIS FILE GROUP --
			DECLARE FileCursor CURSOR FOR 
			SELECT Size, MaxSize, Growth, IsPercentGrowth, [Path]
			FROM @RequiredFiles
			WHERE InitialBoundaryValue = @boundaryValue;

			DECLARE @path NVARCHAR(260);
			DECLARE @size INT;
			DECLARE @maxSize INT;
			DECLARE @growth INT;
			DECLARE @isPercentGrowth BIT;
			DECLARE @index INT = 0;
			
			OPEN FileCursor;

			BEGIN TRY

				FETCH NEXT FROM FileCursor INTO @size, @maxSize, @growth, @isPercentGrowth, @path;
				WHILE @@FETCH_STATUS = 0
				BEGIN

					DECLARE @logicalFileName NVARCHAR(260) = RIGHT(@newFileGroupName, LEN(@newFileGroupName) - 3) + '_' + CAST(@index AS VARCHAR(255));
					
					DECLARE @physicalFileName NVARCHAR(260) = @path + '\' + DB_NAME() + '_' + @logicalFileName + '.ndf';

					IF NOT EXISTS(SELECT 1 FROM sys.database_files WHERE name = @logicalFileName)
					BEGIN
						SET @sql = 'ALTER DATABASE ' + DB_NAME() + ' ADD FILE (NAME=''' + @logicalFileName + ''', FILENAME=''' + @physicalFileName + ''', SIZE = ' + CAST(@size * 8 AS VARCHAR) + ' KB, MAXSIZE = ' + CASE WHEN @maxSize < 0 THEN 'UNLIMITED' ELSE CAST(@maxSize * 8 AS VARCHAR) + ' KB' END + ', FILEGROWTH = ' + CASE WHEN @isPercentGrowth = 0 THEN CAST(@growth * 8 AS VARCHAR) + ' KB' ELSE CAST(@growth AS VARCHAR) + ' %' END + ') TO FILEGROUP ' + @newFileGroupName + ';';
						EXECUTE (@sql);

						-- Additional Logging Added 2015/10/06
						INSERT INTO admin.PartitionLog (EntryDate,ObjectID,DateRangeSwitchedInt,
							DateRangeSwitchedDate,RowCountSwitched,Success,Comments)
						VALUES (GETDATE(),NULL,NULL,NULL,NULL,1,@sql);
						-- Additional Logging Added 2015/10/06

					END

					FETCH NEXT FROM FileCursor INTO @size, @maxSize, @growth, @isPercentGrowth, @path;
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
			IF (NOT EXISTS(SELECT TOP 1 1 FROM [admin].View_PartitionRanges WHERE partition_function = 'PF_' + @TableName AND boundary_value = @boundaryValue))
			BEGIN

				EXEC [admin].[Partitioning_SplitRange] @Strategy, @boundaryValue, @TableName;

				-- Additional Logging Added 2015/10/06
				INSERT INTO admin.PartitionLog (EntryDate,ObjectID,DateRangeSwitchedInt,
					DateRangeSwitchedDate,RowCountSwitched,Success,Comments)
				VALUES (GETDATE(),NULL,NULL,NULL,NULL,1,@sql + ' Boundary Value = ' + CAST(@boundaryValue AS VARCHAR(20)));
				-- Additional Logging Added 2015/10/06

			END

			FETCH NEXT FROM partitionCursor INTO @initialBoundaryValue,@boundaryValue;

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

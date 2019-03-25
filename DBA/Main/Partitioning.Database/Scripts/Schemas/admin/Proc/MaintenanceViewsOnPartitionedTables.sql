EXEC #CreateDummyStoredProcedureIfNotExists @SchemaName = 'admin', @ProcedureName = 'MaintenanceViewsOnPartitionedTables'
GO
ALTER PROCEDURE [admin].[MaintenanceViewsOnPartitionedTables] 
AS
BEGIN
BEGIN TRY

	DECLARE @columns VARCHAR(MAX) = '';
	DECLARE @sql VARCHAR(MAX) = '';
	DECLARE @tablename VARCHAR(200);
	DECLARE @ArchivetoLiveSwitchOverPartitionKeyValue VARCHAR(100)
	DECLARE @partitionKey VARCHAR(100);
	DECLARE @sqlCommand NVARCHAR(1000);
	DECLARE @minlivepartitionkeyvalue VARCHAR(100);
	DECLARE @maxarchivepartitionkeyvalue VARCHAR(100);
	DECLARE @minboundaryvalue VARCHAR(100);
	DECLARE @maxboundaryvalue VARCHAR(100);
	DECLARE @PartitionKeyLength INT;
	DECLARE @minPartitionValueExist BIT = 1;
	DECLARE @LiveSchema SYSNAME;
	DECLARE @ArchiveSchema SYSNAME;
	DECLARE @Strategy TINYINT;

	DECLARE table_cursor CURSOR FOR
	SELECT name tablename,partitionkey,partitionkeyLength, LiveSchema, ArchiveSchema, Strategy 
	FROM [admin].[PartitionConfig];
	
	DECLARE @ValuesLive TABLE(value SQL_VARIANT);
	DECLARE @ValuesArchive TABLE(value SQL_VARIANT);

	OPEN table_cursor
	FETCH NEXT FROM table_cursor INTO @tablename,@partitionkey,@PartitionKeyLength, @LiveSchema, @ArchiveSchema, @Strategy

	WHILE @@FETCH_STATUS=0
	BEGIN

		DELETE FROM @ValuesLive;
		DELETE FROM @ValuesArchive;

		IF @Strategy = 1 OR @Strategy = 2
		BEGIN
			
			INSERT INTO @ValuesLive (value) SELECT boundary_value
			FROM admin.view_PartitionRanges R
			JOIN sys.partitions P 
				ON OBJECT_NAME(object_id) = REPLACE(partition_scheme,'PS_','') 
				AND OBJECT_SCHEMA_NAME(object_id) = @LiveSchema 
				AND R.partition_number = P.partition_number
			WHERE 
			OBJECT_NAME(P.object_id) = @tablename 
			AND P.index_id=1
			AND CAST(P.ROWS AS INT) > 0;

			INSERT INTO @ValuesArchive (value) SELECT boundary_value
			FROM admin.view_PartitionRanges R
			JOIN sys.partitions P 
				ON OBJECT_NAME(object_id) = REPLACE(partition_scheme,'PS_','') 
				AND OBJECT_SCHEMA_NAME(object_id) = @ArchiveSchema 
				AND R.partition_number = P.partition_number
			WHERE 
			OBJECT_NAME(P.object_id) = @tablename 
			AND P.index_id=1
			AND CAST(P.ROWS AS INT) > 0;

			select @minboundaryvalue = MIN(CAST(value as SMALLINT)) FROM @ValuesLive
			select @maxboundaryvalue = MAX(CAST(value as SMALLINT)) FROM @ValuesArchive
		
			SET @sqlCommand = 'SELECT @minlivepartitionkeyvalue = MIN(' + @partitionkey + ') FROM ' + @LiveSchema + '.' + @tablename + ' WHERE ' + @partitionkey + ' <= ' + @minboundaryvalue
			EXECUTE sp_executesql @sqlCommand, N'@minlivepartitionkeyvalue VARCHAR(100) OUTPUT',  @minlivepartitionkeyvalue = @minlivepartitionkeyvalue OUTPUT
			
			SET @sqlCommand = 'SELECT @maxarchivepartitionkeyvalue = MAX(' + @partitionkey + ') FROM ' + @ArchiveSchema + '.' + @tablename + ' WHERE ' + @partitionkey + ' >= ' + @maxboundaryvalue
			EXECUTE sp_executesql @sqlCommand, N'@maxarchivepartitionkeyvalue VARCHAR(100) OUTPUT',  @maxarchivepartitionkeyvalue = @maxarchivepartitionkeyvalue OUTPUT		

		END
		ELSE IF @Strategy = 0
		BEGIN 

			INSERT INTO @ValuesLive (value) SELECT boundary_value
			FROM admin.view_PartitionRanges R
			JOIN sys.partitions P 
				ON OBJECT_NAME(object_id) = REPLACE(partition_scheme,'PS_','') 
				AND OBJECT_SCHEMA_NAME(OBJECT_ID) = @LiveSchema 
				AND R.partition_number = P.partition_number
			WHERE 
			OBJECT_NAME(P.OBJECT_ID) = @tablename 
			AND P.index_id=1
			AND CAST(P.ROWS AS INT) > 0

			INSERT INTO @ValuesArchive (value) SELECT boundary_value
			FROM admin.view_PartitionRanges R
			JOIN sys.partitions P 
				ON OBJECT_NAME(object_id) = REPLACE(partition_scheme,'PS_','') 
				AND OBJECT_SCHEMA_NAME(OBJECT_ID) = @ArchiveSchema 
				AND R.partition_number = P.partition_number
			WHERE 
			OBJECT_NAME(P.OBJECT_ID) = @tablename 
			AND P.index_id=1
			AND CAST(P.ROWS AS INT) > 0

			select @minboundaryvalue = MIN(CAST(value as DATETIMEOFFSET)) FROM @ValuesLive
			select @maxboundaryvalue = MAX(CAST(value as DATETIMEOFFSET)) FROM @ValuesArchive

			SET @sqlCommand = 'SELECT @minlivepartitionkeyvalue=min(' + @partitionkey + ') FROM ' + @LiveSchema + '.' + @tablename + ' WHERE ' + @partitionkey + ' <= ''' + @minboundaryvalue + ''''
			EXECUTE sp_executesql @sqlCommand, N'@minlivepartitionkeyvalue varchar(100) OUTPUT',  @minlivepartitionkeyvalue = @minlivepartitionkeyvalue OUTPUT

			SET @sqlCommand = 'SELECT @maxarchivepartitionkeyvalue=max(' + @partitionkey + ') FROM ' + @ArchiveSchema + '.' + @tablename + ' WHERE ' + @partitionkey + ' >=''' + @maxboundaryvalue + ''''
			EXECUTE sp_executesql @sqlCommand, N'@maxarchivepartitionkeyvalue varchar(100) OUTPUT',  @maxarchivepartitionkeyvalue = @maxarchivepartitionkeyvalue OUTPUT
		END
		ELSE
		BEGIN
			declare @errorMessage varchar(max) = 'Unsupported strategy: ' + CAST(@Strategy AS VARCHAR(10));
			RAISERROR (@errorMessage, 16, 1)
		END

		SET @minlivepartitionkeyvalue = ISNULL(@minlivepartitionkeyvalue, @minboundaryvalue);
		SET @maxarchivepartitionkeyvalue =ISNULL(@maxarchivepartitionkeyvalue, @maxboundaryvalue);


		IF OBJECT_ID(@LiveSchema + '.View_' + @tablename) IS NOT NULL
		BEGIN 
			SET @SQl='ALTER'
		END 
		ELSE
		BEGIN 
			SET @SQl='CREATE'
		END

		SET @SQL = @SQL + ' VIEW [' + @LiveSchema + '].View_' + @tablename + ' AS' + CHAR(10) + ' SELECT '
		SELECT @columns = @columns + '['+ SC.name + '],'
		FROM syscolumns SC
		JOIN sys.types TY 
			ON SC.xtype=TY.user_type_id
		WHERE OBJECT_NAME(id) = @tablename
		AND OBJECT_SCHEMA_NAME(id) = @LiveSchema
		ORDER by SC.colid

		SET @SQL = @SQL + SUBSTRING(@columns,1,LEN(@columns)-1) + CHAR(10)
		SET @SQL = @SQL +' FROM ' + @LiveSchema + '.' + @tablename + ' WITH (READUNCOMMITTED)' + CHAR(10)

		IF(@maxarchivepartitionkeyvalue IS NOT NULL)
		BEGIN
			SET @SQL = @SQL + ' WHERE ' + @partitionKey + '>=''' + @minlivepartitionkeyvalue + '''' + CHAR(10)
		END

		SET @SQL=@SQL+'UNION ALL'+CHAR(10)

		SET @SQL = @sql + 'SELECT ' + SUBSTRING(@columns,1,LEN(@columns)-1) + CHAR(10)
		SET @SQL = @SQL + ' FROM ' + @ArchiveSchema + '.' + @tablename + ' WITH (READUNCOMMITTED)' + CHAR(10)

		IF(@maxarchivepartitionkeyvalue IS NOT NULL)
		BEGIN
			SET @SQL = @SQL + ' WHERE ' + @partitionKey + '<=''' + @maxarchivepartitionkeyvalue + ''''
		END
			
		PRINT CHAR(10) + @SQL + CHAR(10) + 'GO'
		SET @columns=''
		EXEC(@SQL)

		IF (@maxarchivepartitionkeyvalue IS NOT NULL)
		BEGIN
			UPDATE [admin].[PartitionConfig]
			SET ArchivetoLiveSwitchOverDate = NULL,
				ArchivetoLiveSwitchOverPartitionKeyValue = @maxarchivepartitionkeyvalue
			WHERE name = @tablename
		END

		SET @minlivepartitionkeyvalue=NULL;
		SET @maxarchivepartitionkeyvalue=NULL;
		SET @minboundaryvalue=NULL;
		SET @maxboundaryvalue=NULL;

		FETCH NEXT FROM table_cursor INTO @tablename,@partitionkey,@PartitionKeyLength, @LiveSchema, @ArchiveSchema, @Strategy
	END

	CLOSE table_cursor
	DEALLOCATE table_cursor
	
END TRY
BEGIN CATCH
	IF (SELECT CURSOR_STATUS('global','table_cursor')) >= -1
	BEGIN
		DEALLOCATE table_cursor
	END;
	
	THROW;

END CATCH
END
GO

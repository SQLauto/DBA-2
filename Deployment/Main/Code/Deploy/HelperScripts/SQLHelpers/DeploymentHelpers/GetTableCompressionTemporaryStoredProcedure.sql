CREATE PROC #GetTableCompression
	@schemaName varchar(128),
	@tableName varchar(128),
	@compressionType varchar(255) out
AS
BEGIN
	IF (@schemaName IS NULL OR @tableName IS NULL)
	BEGIN
		RAISERROR('#GetColumnType procedure was called with one or more null arguments', 16, 1)
	END

	SET @compressionType = 	(SELECT DISTINCT	sp.data_compression_desc
							 FROM				sys.partitions SP
												INNER JOIN 
												sys.tables st ON st.object_id = sp.object_id 
												LEFT OUTER JOIN 
												sys.indexes ix ON sp.object_id = ix.object_id AND sp.index_id = ix.index_id
							 WHERE				OBJECT_SCHEMA_NAME(sp.object_id) = @schemaName
												AND 
												st.name = @tableName)	
END

GO
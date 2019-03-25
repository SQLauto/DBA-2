CREATE PROC #ColumnExistsInPartitionScheme
	
	@schemaName		VARCHAR(128),
	@tableName		VARCHAR(128),
	@indexName		VARCHAR(128),
	@columnName		VARCHAR(128),
	
	@columnExistsInPartitionScheme BIT OUT
AS
BEGIN
	IF (@schemaName is null or @tableName is null or @indexName is null or @columnName is null)
	BEGIN
		RAISERROR('#ColumnExistsInPartitionScheme procedure was called with one or more null arguments', 16, 1)
	END

	SET @columnExistsInPartitionScheme = 0
	IF EXISTS(
				SELECT		i.name,
							t.name,
							ic.partition_ordinal,
							c.name
				FROM		sys.tables          t
				INNER JOIN  sys.schemas			s 
							ON t.schema_id = s.schema_id
				INNER JOIN  sys.indexes         i 
							ON i.object_id = t.object_id 
				INNER JOIN  sys.index_columns   ic 
							ON
							(ic.partition_ordinal > 0 
							AND ic.index_id = i.index_id 
							AND ic.object_id = t.object_id)
				INNER JOIN  sys.columns         c 
							ON
							(c.object_id = ic.object_id 
							AND c.column_id = ic.column_id)
				WHERE		s.name = @schemaName
							AND	
							t.name = @tableName
							AND   
							i.name = @indexName
							AND						
							c.name = @columnName
			)
	BEGIN
		SET @columnExistsInPartitionScheme = 1
	END	
END

GO



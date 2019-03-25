CREATE PROC #IndexExistsInPartitionScheme
	
	@schemaName		VARCHAR(128),
	@tableName		VARCHAR(128),
	@indexName		VARCHAR(128),
	
	@indexExistsInPartitionScheme BIT OUT
AS
BEGIN
	IF (@schemaName is null or @tableName is null or @indexName is null)
	BEGIN
		RAISERROR('#IndexExistsInPartitionScheme procedure was called with one or more null arguments', 16, 1)
	END

	SET @indexExistsInPartitionScheme = 0
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
			)
	BEGIN
		SET @indexExistsInPartitionScheme = 1
	END	
END

GO



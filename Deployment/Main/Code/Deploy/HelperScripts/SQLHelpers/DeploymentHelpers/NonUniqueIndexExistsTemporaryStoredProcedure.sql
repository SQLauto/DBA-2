
CREATE PROC #NonUniqueIndexExists
	@schemaName varchar(128),
	@tableName varchar(128),
	@indexName varchar(128),
	@nonUniqueIndexExists bit out
AS
BEGIN
	IF @schemaName IS NULL OR @tableName IS NULL OR @indexName IS NULL
	BEGIN
		RAISERROR('#NonUniqueIndexExists procedure was called with one or more null arguments', 16, 1)
	END

	SET @nonUniqueIndexExists = 0
	IF EXISTS(SELECT 1 FROM sys.indexes si
                     INNER JOIN sys.tables t ON 
							si.object_id = t.object_id
                     INNER JOIN sys.schemas sc ON
							sc.schema_id = t.schema_id
                     WHERE 
							sc.name = @schemaName AND
							t.name =  @tableName AND
							si.name = @indexName AND
							si.is_unique = 0
				)
	BEGIN
		SET @nonUniqueIndexExists = 1
	END
END;

GO



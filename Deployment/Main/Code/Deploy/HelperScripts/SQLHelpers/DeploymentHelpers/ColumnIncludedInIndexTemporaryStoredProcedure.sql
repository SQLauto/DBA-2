CREATE PROCEDURE [#ColumnIncludedInIndex]
(
	@schemaName VARCHAR(128),
	@indexName VARCHAR(128),
	@columnName VARCHAR(128),
	@columnExists BIT OUT
)
AS
BEGIN
	IF @schemaName IS NULL OR @indexName IS NULL OR @columnName IS NULL OR @columnExists IS NULL
	BEGIN
		raiserror('#ColumnIncludedInIndex procedure was called with one or more null arguments', 16, 1)
	END

	SET @columnExists = 0
	IF EXISTS(
		SELECT	1
		FROM	sys.indexes i
			JOIN sys.objects so on i.object_id = so.object_id
			JOIN sys.schemas sc on so.schema_id = sc.schema_id
			JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
			JOIN sys.columns c ON ic.object_id = c.object_id AND c.column_id = ic.column_id
		WHERE	sc.Name = @schemaName
			AND
			i.Name = @indexName
			AND 
			c.Name = @columnName
			AND
			ic.is_included_column = 1
		)
	BEGIN
		SET @columnExists = 1
	END
END
GO


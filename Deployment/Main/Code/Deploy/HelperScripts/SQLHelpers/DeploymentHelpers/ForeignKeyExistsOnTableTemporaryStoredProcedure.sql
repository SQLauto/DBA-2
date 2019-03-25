CREATE PROCEDURE #ForeignKeyExistsOnTable
(
	@schemaName VARCHAR(128),
	@tableName VARCHAR(128),
	@foreignKeyName VARCHAR(128),
	@foreignKeyExists BIT OUT
)
AS
BEGIN
	IF @schemaName IS NULL OR @tableName IS NULL OR @foreignKeyName IS NULL 
	BEGIN
		raiserror('#ForeignKeyExistsOnTable procedure was called with one or more null arguments', 16, 1)
	END

	SET @foreignKeyExists = 0
	IF EXISTS(
				SELECT	1 
				FROM	INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
				WHERE	CONSTRAINT_TYPE='FOREIGN KEY' 
						AND 
						TABLE_SCHEMA = @schemaName
						AND 
						TABLE_NAME = @tableName
						AND 
						CONSTRAINT_NAME = @foreignKeyName
			)
	BEGIN
		SET @foreignKeyExists = 1
	END
END
GO




CREATE PROCEDURE [#DatabaseExists]
(
	@databaseName VARCHAR(128),
	@databaseExists BIT OUT
)
AS
BEGIN
	IF @databaseName IS NULL
	BEGIN
		raiserror('#DatabaseExists procedure was called with one or more null arguments', 16, 1)
	END

	SET @databaseExists = 0
	IF EXISTS(
		SELECT	1
		FROM	master.sys.databases
		WHERE	name = @databaseName
		)
	BEGIN
		SET @databaseExists = 1
	END
END
GO


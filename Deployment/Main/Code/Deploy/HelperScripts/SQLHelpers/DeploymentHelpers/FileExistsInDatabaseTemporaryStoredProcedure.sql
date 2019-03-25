CREATE PROC #FileExistsInDatabase
	@fileName VARCHAR(128),	
	@fileExists BIT OUT
AS
BEGIN
	IF (@fileName IS NULL)
	BEGIN
		RAISERROR('#FileExistsInDatabase procedure was called with a null argument for @fileName', 16, 1)
	END

	SET @fileExists = 0

	DECLARE @fileNameLength INT = LEN(@fileName);

	IF EXISTS
	(
		SELECT	1
		FROM	sys.database_files 
		WHERE	RIGHT(physical_name, @fileNameLength) = @fileName
	)
	BEGIN
		SET @fileExists = 1
	END	
END

GO



CREATE PROC #FilegroupExistsInDatabase
	@filegroupName VARCHAR(128),	
	@filegroupExists BIT OUT
AS
BEGIN
	IF (@filegroupName IS NULL)
	BEGIN
		RAISERROR('#FilegroupExistsInDatabase procedure was called with a null argument for @filegroupName', 16, 1)
	END

	SET @filegroupExists = 0

	IF EXISTS
	(
		SELECT	1
		FROM	sys.filegroups 
		WHERE	name = @filegroupName
	)
	BEGIN
		SET @filegroupExists = 1
	END	
END

GO



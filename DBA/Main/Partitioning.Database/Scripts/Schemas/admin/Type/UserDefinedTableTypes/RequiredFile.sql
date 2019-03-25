DECLARE @tableTypeExists BIT;
EXEC #TableTypeExists @schemaName  = 'admin', @tableTypeName  = 'RequiredFile', @tableTypeExists = @tableTypeExists  OUTPUT

IF @tableTypeExists  = 0
BEGIN

	CREATE TYPE admin.RequiredFile AS TABLE (
		[InitialBoundaryValue] SQL_VARIANT    NOT NULL,
		[Size]                 INT            NOT NULL,
		[MaxSize]              INT            NOT NULL,
		[Growth]               INT            NOT NULL,
		[IsPercentGrowth]      BIT            NOT NULL,
		[Path]                 NVARCHAR (260) NOT NULL);
END
GO



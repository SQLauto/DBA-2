DECLARE @tableTypeExists BIT;
EXEC #TableTypeExists @schemaName  = 'admin', @tableTypeName  = 'RequiredPartition', @tableTypeExists = @tableTypeExists  OUTPUT

IF @tableTypeExists  = 0
BEGIN

	CREATE TYPE admin.RequiredPartition AS TABLE (
		[InitialBoundaryValue] SQL_VARIANT NOT NULL,
		[BoundaryValue]        SQL_VARIANT NOT NULL);
END
GO


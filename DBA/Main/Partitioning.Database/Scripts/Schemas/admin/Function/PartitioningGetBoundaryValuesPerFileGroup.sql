EXEC #DropFunctionIfExists @SchemaName = 'admin', @FunctionName = 'PartitioningGetBoundaryValuesPerFileGroup'
GO

CREATE FUNCTION [admin].PartitioningGetBoundaryValuesPerFileGroup
(
	@Strategy TINYINT
)  
RETURNS INT
AS  
BEGIN 

	DECLARE @Result INT;

	IF (@Strategy = 0 OR @Strategy = 1) -- Created, TravelDay
	BEGIN
		SET @Result = 7;
	END
	ELSE IF (@Strategy = 2) -- ExpiryDate
	BEGIN
		SET @Result = 12;
	END

	RETURN @Result;
END
GO



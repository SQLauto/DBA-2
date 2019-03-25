EXEC #DropFunctionIfExists @SchemaName = 'admin', @FunctionName = 'PartitioningFormatBoundary'
GO

CREATE FUNCTION [admin].[PartitioningFormatBoundary]
(
	@BoundaryValue SQL_VARIANT,
	@Strategy TINYINT
)  
RETURNS VARCHAR(128)
AS  
BEGIN 

	DECLARE @Result VARCHAR(128);

	IF (@Strategy = 0) -- Created
	BEGIN
		DECLARE @createdBoundary DATETIMEOFFSET = CAST(@BoundaryValue AS DATETIMEOFFSET);
		SET @Result = FORMAT(@createdBoundary, 'yyyyMMdd');
	END
	ELSE IF (@Strategy = 1) -- TravelDay
	BEGIN
		DECLARE @travelDayBoundary SMALLINT = CAST(@BoundaryValue AS SMALLINT);

-- Added 20151005
--		SET @Result = FORMAT(@travelDayBoundary, '000000');
		SET @Result = FORMAT(@travelDayBoundary, '00000');
-- Added 20151005

	END
	ELSE IF (@Strategy = 2) -- ExpiryDate
	BEGIN
		DECLARE @expiryDateBoundary SMALLINT = CAST(@BoundaryValue AS SMALLINT);
		SET @Result = FORMAT(@expiryDateBoundary, '0000');
	END

	RETURN @Result;
END
GO


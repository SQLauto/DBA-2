EXEC #DropFunctionIfExists @SchemaName = 'admin', @FunctionName = 'PartitioningGetNextBoundary'
GO

CREATE FUNCTION [admin].PartitioningGetNextBoundary
(
	@Current SQL_VARIANT,
	@Strategy TINYINT
)  
RETURNS SQL_VARIANT
AS  
BEGIN 

	DECLARE @Result SQL_VARIANT;

	IF (@Strategy = 0) -- Created
	BEGIN
		DECLARE @createdBoundary DATETIMEOFFSET = CAST(@Current AS DATETIMEOFFSET);
		SET @Result = CAST(DATEADD(dd, 1, @createdBoundary) AS SQL_VARIANT);
	END
	ELSE IF (@Strategy = 1) -- TravelDay
	BEGIN
		DECLARE @travelDayBoundary SMALLINT = CAST(@Current AS SMALLINT);
		SET @Result = CAST(@travelDayBoundary + 1 AS SQL_VARIANT);
	END
	ELSE IF (@Strategy = 2) -- ExpiryDate
	BEGIN
		DECLARE @expiryDateBoundary SMALLINT = CAST(@Current AS SMALLINT);

		DECLARE @year INT = @expiryDateBoundary / 100 + 2000;
		DECLARE @month INT = @expiryDateBoundary % 100;

		DECLARE @expiryDate DATETIME = DATEFROMPARTS(@year, @month, 1);
		SET @expiryDate = DATEADD(MM, 1, @expiryDate);

		SET @year = DATEPART(yyyy, @expiryDate) % 100;
		SET @month = DATEPART(MM, @expiryDate);
		SET @expiryDateBoundary = @year * 100 + @month;
		SET @Result = CAST(@expiryDateBoundary AS SQL_VARIANT);
	END

	RETURN @Result;
END
GO


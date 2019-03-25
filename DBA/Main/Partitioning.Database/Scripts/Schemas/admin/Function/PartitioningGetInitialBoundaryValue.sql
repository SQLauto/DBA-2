EXEC #DropFunctionIfExists @SchemaName = 'admin', @FunctionName = 'PartitioningGetInitialBoundaryValue'
GO

CREATE FUNCTION [admin].PartitioningGetInitialBoundaryValue
(
	@Date DATE,
	@Strategy TINYINT
)  
RETURNS SQL_VARIANT
AS  
BEGIN 

	DECLARE @Result SQL_VARIANT;

	IF (@Strategy = 0) -- Created
	BEGIN
		-- Monday
		DECLARE @createdBoundary DATETIMEOFFSET = CAST(@Date AS DATETIMEOFFSET);
		DECLARE @createdBoundaryDow INT = (@@DATEFIRST + DATEPART(DW, @createdBoundary) - 2) % 7 + 1; -- 1 = Mon, 7 = Sun
		SET @createdBoundary = DATEADD(dd, -1 * (@createdBoundaryDow - 1), @createdBoundary);
		SET @Result = CAST(@createdBoundary AS SQL_VARIANT);
	END
	ELSE IF (@Strategy = 1) -- TravelDay
	BEGIN
		-- Monday
		DECLARE @travelDayBoundaryDow INT = (@@DATEFIRST + DATEPART(DW, @Date) - 2) % 7 + 1; -- 1 = Mon, 7 = Sun
		SET @Date = DATEADD(dd, -1 * (@travelDayBoundaryDow - 1), @Date);
		SET @Result = CAST(CAST(DATEDIFF(dd, '1 jan 1980', @Date) AS SMALLINT) AS SQL_VARIANT);
	END
	ELSE IF (@Strategy = 2) -- ExpiryDate
	BEGIN
		-- January
		DECLARE @year INT = DATEPART(yyyy, @Date) % 100;
		DECLARE @month INT = 1;
		DECLARE @expiryDateBoundary SMALLINT = @year * 100 + @month;
		SET @Result = CAST(@expiryDateBoundary AS SQL_VARIANT);
	END

	RETURN @Result;
END
GO

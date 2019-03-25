EXEC #CreateDummyStoredProcedureIfNotExists 'admin', 'Partitioning_SplitRange'
GO
ALTER PROCEDURE [admin].[Partitioning_SplitRange]
(
	@Strategy TINYINT,
	@BoundaryValue SQL_VARIANT,
	@TableName NVARCHAR(128)
)  
AS  
BEGIN 

	DECLARE @sql NVARCHAR(MAX) = 'ALTER PARTITION FUNCTION PF_' + @TableName + '() SPLIT RANGE (@boundaryValue);';
	DECLARE @paramDefinition NVARCHAR(255);

	IF (@Strategy = 0) -- Created
	BEGIN
		DECLARE @created DATETIMEOFFSET = CAST(@boundaryValue AS DATETIMEOFFSET);
		SET @paramDefinition = '@boundaryValue DATETIMEOFFSET';
		EXEC sp_executesql @sql, @paramDefinition, @boundaryValue = @created;
	END
	ELSE IF (@Strategy = 1) -- TravelDay
	BEGIN
		DECLARE @travelDay SMALLINT = CAST(@boundaryValue AS SMALLINT);
		SET @paramDefinition = '@boundaryValue SMALLINT';
		EXEC sp_executesql @sql, @paramDefinition, @boundaryValue = @travelDay;
	END
	ELSE IF (@Strategy = 2) -- ExpiryDatePartition
	BEGIN
		DECLARE @expiryDatePartition SMALLINT = CAST(@boundaryValue AS SMALLINT);
		SET @paramDefinition = '@boundaryValue SMALLINT';
		EXEC sp_executesql @sql, @paramDefinition, @boundaryValue = @expiryDatePartition;
	END

END
GO

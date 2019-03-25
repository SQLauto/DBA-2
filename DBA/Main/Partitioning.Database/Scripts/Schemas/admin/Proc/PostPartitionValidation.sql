EXEC #CreateDummyStoredProcedureIfNotExists @SchemaName = 'admin', @ProcedureName = 'PostPartitionValidation'
GO

ALTER PROCEDURE admin.PostPartitionValidation AS
BEGIN

IF OBJECT_ID('tempdb..#PartitionValidationResults') IS NOT NULL
	DROP TABLE #PartitionValidationResults;

WITH CTE0 AS
(
	SELECT
		 pc.Name, pc.Strategy, vp.partition_function, vp.filegroup, vp.boundary_value , 
		 CASE pc.Strategy WHEN 0 THEN CAST(vp.boundary_value AS datetimeoffset) ELSE NULL END AS Strategy0_Boundary_Value,
		 CASE pc.Strategy WHEN 1 THEN CAST(vp.boundary_value AS INT) ELSE NULL END AS Strategy1_Boundary_Value,
		 CASE pc.Strategy WHEN 2 THEN CAST(vp.boundary_value AS INT) ELSE NULL END AS Strategy2_Boundary_Value
	FROM admin.View_PartitionRanges vp
	JOIN admin.PartitionConfig pc
		ON vp.partition_function = 'PF_' + pc.Name
), CTE1 AS
(
	SELECT partition_function, filegroup, COUNT(*) AS PartitionCount
	FROM admin.View_PartitionRanges vp
	JOIN admin.PartitionConfig pc
		ON vp.partition_function = 'PF_' + pc.Name
	GROUP BY partition_function, filegroup
), ParVal AS
(
	SELECT x0.*, x1.PartitionCount
	FROM CTE0 x0
	JOIN CTE1 x1 
		ON x0.partition_function = x1.partition_function
		AND x0.filegroup = x1.filegroup
), PartitionDetails AS
(
	-- Check for missing partitions validation
	SELECT *
	FROM ParVal
	WHERE Strategy = 0
	AND Strategy0_Boundary_Value >= GETDATE()
	AND PartitionCount <> 7 
	UNION ALL
	SELECT *
	FROM ParVal
	WHERE Strategy = 1
	AND Strategy1_Boundary_Value >= DATEDIFF(day,'1 Jan, 1980', GETDATE())
	AND PartitionCount <> 7 
	UNION ALL
	SELECT *
	FROM ParVal
	WHERE Strategy = 2
	AND Strategy2_Boundary_Value >= (CAST(CONVERT(VARCHAR(10),GETDATE(),12) AS INT) - DATEPART(day,GETDATE())) / 100
	AND PartitionCount <> 12
)

SELECT Name, Strategy, partition_function, [filegroup], PartitionCount, 
	CASE Strategy 
		WHEN 0 THEN CAST(Strategy0_Boundary_Value AS VARCHAR(24))
		WHEN 1 THEN CAST(Strategy1_Boundary_Value AS VARCHAR(24))
		WHEN 2 THEN CAST(Strategy2_Boundary_Value AS VARCHAR(24))
	END AS Boundary_Value
INTO #PartitionValidationResults
FROM PartitionDetails;

IF EXISTS (SELECT TOP 1 1 FROM #PartitionValidationResults)
BEGIN
			SELECT *
			FROM #PartitionValidationResults;
			RAISERROR('Missing Partitions', 18, 1);
END

END

GO

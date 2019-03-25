EXEC #CreateDummyStoredProcedureIfNotExists 'capture', 'CpuUsageByDatabase'
GO
ALTER PROCEDURE [capture].[CpuUsageByDatabase]

	@WaitTimeSec INT = 300,
	@StopTime DATETIME = NULL
AS

BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	DECLARE @CaptureDataID int
	/* Check that stopdate is greater than current time. If not, throw error! */
	/* If temp tables exist drop them. */
	IF OBJECT_ID('tempdb..#CPUSnapshot') IS NOT NULL
	BEGIN
		DROP TABLE #CPUSnapshot
	END

	IF OBJECT_ID('tempdb..#CPUResult') IS NOT NULL
	BEGIN
		DROP TABLE #CPUResult
	END
	/* Create temp tables for capture baseline */
	CREATE TABLE #CPUSnapshot
	(	
		CaptureDate datetime,
		DatabaseName varchar(128),
		CPU_Time_Ms BIGINT
		
	)



	CREATE TABLE #CPUResult
	(
	
		CaptureDate datetime,
		DatabaseName varchar(128),
		CPU_Time_Ms BIGINT
		
	)
	
	/* instance info */
	DECLARE @ServerName varchar(300),@NodeName varchar(300)
	SELECT @ServerName = convert(nvarchar(128), serverproperty('servername'))
	SELECT @NodeName = convert(nvarchar(128), serverproperty('ComputerNamePhysicalNetBIOS'))
	

	/* Insert master record for capture data */

	INSERT INTO capture.CpuData (StartTime, EndTime, ServerName,PullPeriod,Node)
	VALUES (GETDATE(), NULL, @ServerName, @WaitTimeSec,@NodeName)
	SELECT @CaptureDataID = SCOPE_IDENTITY()

	/* Loop through until time expires  */

	IF @StopTime IS NULL
		SET @StopTime = DATEADD(mi, 10, getdate())
	WHILE GETDATE() < @StopTime
	BEGIN



	

	/* Get baseline snapshot of cpu */
		
		WITH DB_CPU_Stats
AS
(SELECT DatabaseID, DB_Name(DatabaseID) AS [DatabaseName], SUM(total_worker_time) AS [CPU_Time_Ms]
  FROM sys.dm_exec_query_stats AS qs
 CROSS APPLY (SELECT CONVERT(int, value) AS [DatabaseID] 
              FROM sys.dm_exec_plan_attributes(qs.plan_handle)
              WHERE attribute = N'dbid') AS F_DB
 GROUP BY DatabaseID)
INSERT INTO #CPUSnapshot (CaptureDate,DatabaseName,CPU_Time_Ms)
SELECT GETDATE() CaptureDate,
       DatabaseName, [CPU_Time_Ms]
       
FROM DB_CPU_Stats
WHERE DatabaseID > 4 -- system databases
AND DatabaseID <> 32767 -- ResourceDB

		
		/* Wait a few minutes and get final snapshot */

		WAITFOR DELAY @WaitTimeSec;
		
			WITH DB_CPU_Stats
AS
(SELECT DatabaseID, DB_Name(DatabaseID) AS [DatabaseName], SUM(total_worker_time) AS [CPU_Time_Ms]
  FROM sys.dm_exec_query_stats AS qs
 CROSS APPLY (SELECT CONVERT(int, value) AS [DatabaseID] 
              FROM sys.dm_exec_plan_attributes(qs.plan_handle)
              WHERE attribute = N'dbid') AS F_DB
 GROUP BY DatabaseID)
INSERT INTO #CPUResult (CaptureDate,DatabaseName,CPU_Time_Ms)
SELECT GETDATE() CaptureDate,
       DatabaseName, [CPU_Time_Ms]
FROM DB_CPU_Stats
WHERE DatabaseID > 4 -- system databases
AND DatabaseID <> 32767 -- ResourceDB
		
			

		INSERT INTO [capture].[CpuResults] (CpuDataID,CaptureDate, DatabaseName, CPU_Time_Ms,CPUPercent)
		SELECT @CaptureDataID,CaptureDate,DatabaseName, CPU_Time_Ms,CPUPercent
			FROM (
		SELECT	r.CaptureDate,
				r.DatabaseName,
				r.CPU_Time_Ms-s.CPU_Time_Ms CPU_Time_Ms,
				CAST((r.CPU_Time_Ms-s.CPU_Time_Ms) * 1.0 / SUM(r.CPU_Time_Ms-s.CPU_Time_Ms) OVER() * 100.0 AS DECIMAL(5, 2))  CPUPercent
		FROM #CpuSnapshot s
			 INNER JOIN #CpuResult r ON (s.DatabaseName=r.DatabaseName )
			 WHERE r.CPU_Time_Ms>=s.CPU_Time_Ms
		) inline
	
		TRUNCATE TABLE #CPUSnapshot
		TRUNCATE TABLE #CPUResult
 END -- END of WHILE

 /* Update Capture Data meta-data to include end time */
 UPDATE [capture].[CpuData]
 SET EndTime = GETDATE()
 WHERE ID = @CaptureDataID

END



GO
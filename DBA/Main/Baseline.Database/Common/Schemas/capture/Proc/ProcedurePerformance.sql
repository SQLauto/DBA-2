EXEC #CreateDummyStoredProcedureIfNotExists 'capture', 'ProcedurePerformance'
GO

ALTER PROCEDURE [capture].[ProcedurePerformance]

	-- Add the parameters for the stored procedure here
		--@database varchar(100),
	@WaitTimeSec INT = 60,
	@StopTime DATETIME = NULL
AS

BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	DECLARE @CaptureDataID int
	/* Check that stopdate is greater than current time. If not, throw error! */
	/* If temp tables exist drop them. */
	IF OBJECT_ID('tempdb..#ProcSnapshot') IS NOT NULL
	BEGIN
		DROP TABLE #ProcSnapshot
	END

	IF OBJECT_ID('tempdb..#ProcResult') IS NOT NULL
	BEGIN
		DROP TABLE #ProcResult
	END
	/* Create temp tables for capture baseline */
	CREATE TABLE #ProcSnapshot(CaptureDate datetime,

	ProcedureName varchar(100),
	execution_count bigint,
	total_worker_time bigint,
	total_physical_reads bigint,
	total_logical_writes bigint,
	total_logical_reads bigint,
	total_elapsed_time bigint,
	[database_id] smallint,
		database_name varchar(100),
		proc_object_id INT
	)



	CREATE TABLE #ProcResult(CaptureDate datetime,
	ProcedureName varchar(100),
	execution_count bigint,
	total_worker_time bigint,
	total_physical_reads bigint,
	total_logical_writes bigint,
	total_logical_reads bigint,
	total_elapsed_time bigint,
	[database_id] smallint,
	database_name varchar(100),
	proc_object_id INT

	)

	DECLARE @ServerName varchar(300),@NodeName varchar(300)
	SELECT @ServerName = convert(nvarchar(128), serverproperty('servername'))
	SELECT @NodeName = convert(nvarchar(128), serverproperty('ComputerNamePhysicalNetBIOS'))
	

	/* Insert master record for capture data */

	INSERT INTO capture.StoredProcedureWindow (StartTime, EndTime, ServerName,PullPeriod,Node)
	VALUES (GETDATE(), NULL, @ServerName, @WaitTimeSec,@NodeName)
	SELECT @CaptureDataID = SCOPE_IDENTITY()

	/* Loop through until time expires  */

	IF @StopTime IS NULL
		SET @StopTime = DATEADD(mi, 20, getdate())
	WHILE GETDATE() < @StopTime
	BEGIN

	IF OBJECT_ID('tempdb..#procedures') IS NOT NULL
	BEGIN
		DROP TABLE #procedures
	END
	
	CREATE table #procedures(database_id smallint,objectid int,name varchar(100),CONSTRAINT IX_PK_procs  PRIMARY KEY  (database_id,objectid) )

	EXEC sp_MSforeachdb 'USE [?] INSERT into #procedures SELECT  DB_id(''?''),object_id,schema_name(schema_id)+''.''+name FROM sys.procedures order by name '
	


	

	/* Get baseline snapshot of stalls */
		INSERT INTO #ProcSnapshot (CaptureDate,procedurename,execution_count,
		total_worker_time,total_physical_reads,	total_logical_writes,
		total_logical_reads,total_elapsed_time,[database_id],database_name,proc_object_id)
		select GETDATE(),p.name,SUM(execution_count) execution_count,SUM(total_worker_time) total_worker_time,SUM(total_physical_reads) total_physical_reads ,
		SUM(total_logical_writes) total_logical_writes,SUM(total_logical_reads) total_logical_reads ,SUM(total_elapsed_time)total_elapsed_time,qs.database_id,DB_NAME(qs.database_id) database_name,p.[objectid]
		FROM #procedures AS p WITH (NOLOCK) 
		INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
		ON p.[objectid] = qs.[object_id] and p.database_id=qs.database_id
		GROUP BY p.name,qs.database_id,p.[objectid]
		
		/* Wait a few minutes and get final snapshot */

		WAITFOR DELAY @WaitTimeSec
		
		INSERT INTO #ProcResult (CaptureDate,procedurename,execution_count,
		Total_worker_time,total_physical_reads,	total_logical_writes,
		total_logical_reads,total_elapsed_time,[database_id],database_name,proc_object_id)
		Select GETDATE(),p.name,SUM(execution_count) execution_count,SUM(total_worker_time) total_worker_time,SUM(total_physical_reads) total_physical_reads ,
		SUM(total_logical_writes) total_logical_writes,SUM(total_logical_reads) total_logical_reads ,SUM(total_elapsed_time)total_elapsed_time,qs.database_id,DB_NAME(qs.database_id) database_name,p.[objectid]
		FROM #procedures AS p WITH (NOLOCK) 
		INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
		ON p.[objectid] = qs.[object_id] and p.database_id=qs.database_id
		GROUP BY p.name,qs.database_id,p.[objectid]
		
			

		INSERT INTO [capture].[StoredProcedureStats] (CaptureProcDataID,CaptureDate, ProcedureName, execution_count, total_worker_time, 
		total_physical_reads, total_logical_writes, total_logical_reads, total_elapsed_time, [database_id],[database],proc_object_id)
		SELECT @CaptureDataID,CaptureDate,procedurename,execution_count,total_worker_time,total_physical_reads,total_logical_writes,
			total_logical_reads,total_elapsed_time,database_id,DB_NAME(database_id) database_name,inline.proc_object_id
			FROM (
		SELECT	r.CaptureDate,
				r.procedurename,
				r.execution_count-s.execution_count execution_count,
				r.total_worker_time-s.total_worker_time total_worker_time,
				r.total_physical_reads-s.total_physical_reads total_physical_reads,
				r.total_logical_writes-s.total_logical_writes total_logical_writes,
				r.total_logical_reads-s.total_logical_reads total_logical_reads,
				r.total_elapsed_time-s.total_elapsed_time total_elapsed_time,r.[database_id],r.database_name,r.proc_object_id
		FROM #ProcSnapshot s
			 INNER JOIN #ProcResult r ON (s.procedurename=r.procedurename and s.database_id=r.database_id)
			 WHERE r.execution_count>s.execution_count
		) inline
		UNION
		SELECT @CaptureDataID,inline.CaptureDate,inline.procedurename,inline.execution_count,inline.total_worker_time,inline.total_physical_reads,
		inline.total_logical_writes,inline.total_logical_reads,inline.total_elapsed_time,inline.database_id,DB_NAME(inline.database_id) database_name,inline.proc_object_id
			FROM (
		SELECT	r.CaptureDate,
				r.procedurename,
				1 execution_count,
				r.total_worker_time-s.total_worker_time total_worker_time,
				r.total_physical_reads-s.total_physical_reads total_physical_reads,
				r.total_logical_writes-s.total_logical_writes total_logical_writes,
				r.total_logical_reads-s.total_logical_reads total_logical_reads,
				r.total_elapsed_time-s.total_elapsed_time total_elapsed_time,r.[database_id],r.database_name,r.proc_object_id
		FROM #ProcSnapshot s
			 INNER JOIN #ProcResult r ON (s.procedurename=r.procedurename and s.database_id=r.database_id)
			 		) inline
		LEFT JOIN [capture].[StoredProcedureStats] CPR ON CPR.database_id=inline.database_id and CPR.ProcedureName=inline.ProcedureName
		WHERE CPR.ID IS NULL

		TRUNCATE TABLE #ProcSnapshot
		TRUNCATE TABLE #ProcResult
 END -- END of WHILE

 /* Update Capture Data meta-data to include end time */
 UPDATE [capture].[StoredProcedureWindow]
 SET EndTime = GETDATE()
 WHERE ID = @CaptureDataID

END

GO



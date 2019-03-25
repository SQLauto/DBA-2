EXEC #CreateDummyStoredProcedureIfNotExists 'capture', 'QueryPerformance'
GO
ALTER PROCEDURE [capture].[QueryPerformance]

	-- Add the parameters for the stored procedure here
		--@database varchar(100),
	@WaitTimeSec INT = 900,
	@StopTime DATETIME = NULL
AS

BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	DECLARE @CaptureDataID int
	/* Check that stopdate is greater than current time. If not, throw error! */
	/* If temp tables exist drop them. */
	IF OBJECT_ID('tempdb..#Querysnapshot') IS NOT NULL
	BEGIN
		DROP TABLE #Querysnapshot
	END

	IF OBJECT_ID('tempdb..#QueryResult') IS NOT NULL
	BEGIN
		DROP TABLE #QueryResult
	END
	/* Create temp tables for capture baseline */
	CREATE TABLE #Querysnapshot(CaptureDate datetime,
	[type] [char](2) NULL,
	[ObjectName] [nvarchar](257) NULL,
	[QueryText] [nvarchar](max) NULL,
	[execution_count] [bigint] NOT NULL,
	[total_worker_time] [bigint] NOT NULL,
	[total_physical_reads] [bigint] NOT NULL,
	[total_logical_writes] [bigint] NOT NULL,
	[total_logical_reads] [bigint] NOT NULL,
	[total_elapsed_time] [bigint] NOT NULL,
	[min_rows] [bigint] NOT NULL,
	[max_rows] [bigint] NOT NULL,
	[last_rows] [bigint] NOT NULL,
	[statement_start_offset] [int] NOT NULL,
	[statement_end_offset] [int] NOT NULL,
	[database_id] smallint,
		database_name varchar(100),
		[objectid] INT
	)



	CREATE TABLE #QueryResult(CaptureDate datetime,
	[type] [char](2) NULL,
	[ObjectName] [nvarchar](257) NULL,
	[QueryText] [nvarchar](max) NULL,
	[execution_count] [bigint] NOT NULL,
	[total_worker_time] [bigint] NOT NULL,
	[total_physical_reads] [bigint] NOT NULL,
	[total_logical_writes] [bigint] NOT NULL,
	[total_logical_reads] [bigint] NOT NULL,
	[total_elapsed_time] [bigint] NOT NULL,
	[min_rows] [bigint] NOT NULL,
	[max_rows] [bigint] NOT NULL,
	[last_rows] [bigint] NOT NULL,
	[statement_start_offset] [int] NOT NULL,
	[statement_end_offset] [int] NOT NULL,
	[database_id] smallint,
		database_name varchar(100),
		[objectid] INT

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

	IF OBJECT_ID('tempdb..#Objects') IS NOT NULL
	BEGIN
		DROP TABLE #Objects
	END
	
	CREATE table #Objects(database_id smallint,objectid int,name varchar(500),[type] varchar(10),PRIMARY KEY  (database_id,objectid,name) )

	EXEC sp_MSforeachdb 'USE [?] INSERT into #Objects SELECT  DB_id(''?''),object_id,schema_name(schema_id)+''.''+name,[type] FROM sys.objects order by name '
	
	
	/* Get baseline snapshot of stalls */
		INSERT INTO #Querysnapshot([CaptureDate], [type], [ObjectName], [QueryText],  [execution_count], 
		[total_worker_time], [total_physical_reads], [total_logical_writes], [total_logical_reads], [total_elapsed_time], [min_rows], [max_rows], [last_rows],
		[statement_start_offset], [statement_end_offset],[database_id],database_name,objectid) 
		SELECT GETDATE() capturedate,type,ObjectName,QueryText,SUM(execution_count) execution_count ,SUM(total_worker_time) total_worker_time,
		SUM(total_physical_reads) total_physical_reads,	SUM(total_logical_writes) total_logical_writes ,SUM(total_logical_reads) total_logical_reads,
		SUM(total_elapsed_time) total_elapsed_time,MIN(min_rows) min_rows ,MAX(max_rows) max_rows ,MAX(last_rows) last_rows,	statement_start_offset,	statement_end_offset,
		database_id,database_name,objectid
 	 FROM (SELECT   SO.type,OBJECT_SCHEMA_NAME(qt.objectid, dbid)  +'.'+ISNULL(OBJECT_NAME(qt.objectid, dbid),'Adhoc') AS [ObjectName],SUBSTRING(qt.[text],
		qs.statement_start_offset/2,(CASE 		WHEN qs.statement_end_offset = -1 	 THEN LEN(CONVERT(nvarchar(max), qt.[text])) * 2 		
		ELSE qs.statement_end_offset  END - qs.statement_start_offset)/2) AS [QueryText],creation_time,last_execution_time	,[execution_count],
		 [total_worker_time], [total_physical_reads], [total_logical_writes], [total_logical_reads], [total_elapsed_time],min_rows ,max_rows,last_rows, statement_start_offset,statement_end_offset,
		so.database_id, DB_NAME(so.database_id) database_name,SO.[objectid]
		FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
		JOIN #Objects SO on qt.objectid = SO.objectid and SO.database_id=qt.dbid
		WHERE ISNULL(qt.[dbid], 5) > 4

) SQ
GROUP BY [type],ObjectName,QueryText,statement_start_offset,statement_end_offset,database_id,database_name,objectid

		
		/* Wait a few minutes and get final snapshot */

		WAITFOR DELAY @WaitTimeSec
	
	
		INSERT INTO #QueryResult([CaptureDate], [type], [ObjectName], [QueryText],  [execution_count], 
		[total_worker_time], [total_physical_reads], [total_logical_writes], [total_logical_reads], [total_elapsed_time], [min_rows], [max_rows], [last_rows],
		[statement_start_offset], [statement_end_offset],[database_id],database_name,objectid) 
		SELECT GETDATE() capturedate,type,ObjectName,QueryText,SUM(execution_count) execution_count ,SUM(total_worker_time) total_worker_time,
		SUM(total_physical_reads) total_physical_reads,	SUM(total_logical_writes) total_logical_writes ,SUM(total_logical_reads) total_logical_reads,
		SUM(total_elapsed_time) total_elapsed_time,MIN(min_rows) min_rows ,MAX(max_rows) max_rows ,MAX(last_rows) last_rows,	statement_start_offset,	statement_end_offset,
		database_id,database_name,objectid
 	 FROM (SELECT   SO.type,OBJECT_SCHEMA_NAME(qt.objectid, dbid)  +'.'+ISNULL(OBJECT_NAME(qt.objectid, dbid),'Adhoc') AS [ObjectName],SUBSTRING(qt.[text],
		qs.statement_start_offset/2,(CASE 		WHEN qs.statement_end_offset = -1 	 THEN LEN(CONVERT(nvarchar(max), qt.[text])) * 2 		
		ELSE qs.statement_end_offset  END - qs.statement_start_offset)/2) AS [QueryText],creation_time,last_execution_time	,[execution_count],
		 [total_worker_time], [total_physical_reads], [total_logical_writes], [total_logical_reads], [total_elapsed_time],min_rows ,max_rows,last_rows, statement_start_offset,statement_end_offset,
		so.database_id, DB_NAME(so.database_id) database_name,SO.[objectid]
		FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
		CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
		JOIN #Objects SO on qt.objectid = SO.objectid  and SO.database_id=qt.dbid
		WHERE ISNULL(qt.[dbid], 5) > 4
) SQ
GROUP BY [type],ObjectName,QueryText,statement_start_offset,statement_end_offset,database_id,database_name,objectid
		

		INSERT INTO [capture].[QueryExecutionStats] ([CaptureQueryDataID],[CaptureDate],[Type], [ObjectName],[QueryText], [execution_count], 
		[total_worker_time], [total_physical_reads], [total_logical_writes], [total_logical_reads], [total_elapsed_time], 
		[min_rows], [max_rows],[last_rows], [statement_start_offset], [statement_end_offset],[database], [database_id],[object_id])
		SELECT @CaptureDataID,CaptureDate,[type],ObjectName,QueryText,execution_count,total_worker_time,total_physical_reads,total_logical_writes,
			total_logical_reads,total_elapsed_time,min_rows, max_rows,last_rows, statement_start_offset, statement_end_offset,DB_NAME(database_id) [database] ,database_id,objectid
			FROM (
		SELECT	r.CaptureDate,
				r.type,
				r.ObjectName,
				CAST(r.QueryText as Varchar(8000)) QueryText,
				r.execution_count-s.execution_count execution_count,
				r.total_worker_time-s.total_worker_time total_worker_time,
				r.total_physical_reads-s.total_physical_reads total_physical_reads,
				r.total_logical_writes-s.total_logical_writes total_logical_writes,
				r.total_logical_reads-s.total_logical_reads total_logical_reads,
				r.total_elapsed_time-s.total_elapsed_time total_elapsed_time,s.min_rows, s.max_rows,s.last_rows, s.statement_start_offset, s.statement_end_offset,
				s.database_id,s.objectid
		FROM #Querysnapshot s
			 INNER JOIN #QueryResult r ON (s.ObjectName=r.ObjectName and s.QueryText=r.QueryText and  s.database_id=r.database_id)
			 WHERE r.execution_count>s.execution_count
		) inline
		UNION
		SELECT  @CaptureDataID,inline.CaptureDate,inline.type,inline.ObjectName,inline.QueryText,inline.execution_count,inline.total_worker_time,inline.total_physical_reads,inline.total_logical_writes,
			inline.total_logical_reads,inline.total_elapsed_time,inline.min_rows, inline.max_rows,inline.last_rows, inline.statement_start_offset, inline.statement_end_offset,DB_NAME(inline.database_id) [database],
			inline.database_id,objectid
			FROM (
		SELECT	r.CaptureDate,
				r.type,
				r.ObjectName,
				CAST(r.QueryText as Varchar(8000)) QueryText,
				1 execution_count,
				r.total_worker_time-s.total_worker_time total_worker_time,
				r.total_physical_reads-s.total_physical_reads total_physical_reads,
				r.total_logical_writes-s.total_logical_writes total_logical_writes,
				r.total_logical_reads-s.total_logical_reads total_logical_reads,
				r.total_elapsed_time-s.total_elapsed_time total_elapsed_time,r.min_rows, r.max_rows,r.last_rows,r.statement_start_offset, r.statement_end_offset,r.[database_id],r.objectid
		FROM #Querysnapshot s
			 INNER JOIN #QueryResult r ON (s.ObjectName=r.ObjectName and  s.QueryText=r.QueryText and  s.database_id=r.database_id)
			 		) inline
		LEFT JOIN [capture].[QueryExecutionStats] CPR ON CPR.database_id=inline.database_id and CPR.ObjectName=inline.ObjectName
		WHERE CPR.ID IS NULL
		and inline.total_worker_time + inline.total_physical_reads + inline.total_logical_writes + inline.total_logical_reads + inline.total_elapsed_time > 0 		
		TRUNCATE TABLE #Querysnapshot
		TRUNCATE TABLE #QueryResult
 END -- END of WHILE

 /* Update Capture Data meta-data to include end time */
 UPDATE [capture].[QueryExecutionWindow]
 SET EndTime = GETDATE()
 WHERE ID = @CaptureDataID

END;


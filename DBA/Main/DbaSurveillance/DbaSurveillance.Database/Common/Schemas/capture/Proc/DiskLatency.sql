EXEC #CreateDummyStoredProcedureIfNotExists 'capture', 'DiskLatency'
GO

ALTER PROCEDURE [capture].[DiskLatency]
	-- Add the parameters for the stored procedure here
	@WaitTimeSec INT = 60,
	@StopTime DATETIME = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	
	DECLARE @CaptureDataID int
	/* Check that stopdate is greater than current time. If not, throw error! */

	/* If temp tables exist drop them. */
	IF OBJECT_ID('tempdb..#IOStallSnapshot') IS NOT NULL
	BEGIN
		DROP TABLE #IOStallSnapshot
	END

	IF OBJECT_ID('tempdb..#IOStallResult') IS NOT NULL
	BEGIN
		DROP TABLE #IOStallResult
	END

	/* Create temp tables for capture baseline */
	CREATE TABLE #IOStallSnapshot(
	CaptureDate datetime,
	read_per_ms float,
	write_per_ms float,
	num_of_bytes_written bigint,
	num_of_reads bigint,
	num_of_writes bigint,
	database_id int,
	file_id int
	)

	CREATE TABLE #IOStallResult(
	CaptureDate datetime,
	read_per_ms float,
	write_per_ms float,
	num_of_bytes_written bigint,
	num_of_reads bigint,
	num_of_writes bigint,
	database_id int,
	file_id int
	)

	DECLARE @ServerName varchar(300)
	SELECT @ServerName = convert(nvarchar(128), serverproperty('servername'))

	/* Insert master record for capture data */
	INSERT INTO capture.FileStatsWindow (StartTime, EndTime, ServerName,PullPeriod)
	VALUES (GETDATE(), NULL, @ServerName, @WaitTimeSec)

	SELECT @CaptureDataID = SCOPE_IDENTITY()

	UPDATE df
	SET endDate=GETDATE()
	from  capture.DatabaseFiles df
	LEFT JOIN sys.master_files mf ON df.Database_ID = mf.database_id AND df.[File_ID] = mf.[File_ID] and df.physicalName = mf.physical_name 
	WHERE mf.file_id is null

	/* Do lookup to get property data for all database files to catch any new ones if they exist */
	INSERT INTO capture.DatabaseFiles ([ServerName],[DatabaseName],[LogicalFileName],fileType,[Database_ID],[File_ID],PhysicalName,file_guid)
	SELECT @ServerName, DB_NAME(database_id), name,[type], database_id, [FILE_ID],physical_name,file_guid
	FROM sys.master_files mf 
	WHERE NOT EXISTS
	(
		SELECT 1
		FROM capture.DatabaseFiles df
		WHERE df.Database_ID = mf.database_id AND df.[File_ID] = mf.[File_ID] and df.physicalName = mf.physical_name 
	)

	/* Loop through until time expires  */
	IF @StopTime IS NULL
		SET @StopTime = DATEADD(hh, 1, getdate())
	WHILE GETDATE() < @StopTime
	BEGIN

	/* Get baseline snapshot of stalls */
		INSERT INTO #IOStallSnapshot (CaptureDate,
		read_per_ms,
		write_per_ms,
		num_of_bytes_written,
		num_of_reads,
		num_of_writes,
		database_id,
		[file_id])
		SELECT getdate(),
			a.io_stall_read_ms,
			a.io_stall_write_ms,
			a.num_of_bytes_written,
			a.num_of_reads,
			a.num_of_writes,
			a.database_id,
			a.file_id
		FROM sys.dm_io_virtual_file_stats (NULL, NULL) a
		JOIN sys.master_files b ON a.file_id = b.file_id
		AND a.database_id = b.database_id

		/* Wait a few minutes and get final snapshot */
		WAITFOR DELAY @WaitTimeSec

		INSERT INTO #IOStallResult (CaptureDate,
			read_per_ms,
			write_per_ms,
			num_of_bytes_written,
			num_of_reads,
			num_of_writes,
			database_id,
			[file_id])
		SELECT getdate(),
			a.io_stall_read_ms,
			a.io_stall_write_ms,
			a.num_of_bytes_written,
			a.num_of_reads,
			a.num_of_writes,
			a.database_id,
			a.file_id
		FROM sys.dm_io_virtual_file_stats (NULL, NULL) a
		JOIN sys.master_files b ON a.file_id = b.file_id
		AND a.database_id = b.database_id
	
	
		INSERT INTO capture.FileStats (CaptureDataID,
			CaptureDate,
			read_per_ms,
			write_per_ms,
			io_stall_read,
			io_stall_write,
			num_of_reads,
			num_of_writes,
			num_of_bytes_written,
			database_id,
			[file_id])
		SELECT @CaptureDataID
			,inline.CaptureDate
			,CASE WHEN inline.num_of_reads =0 THEN 0 ELSE inline.io_stall_read_ms / inline.num_of_reads END AS read_per_ms
			,CASE WHEN inline.num_of_writes = 0 THEN 0 ELSE inline.io_stall_write_ms / inline.num_of_writes END AS write_per_ms
			,inline.io_stall_read_ms
			,inline.io_stall_write_ms
			,inline.num_of_reads
			,inline.num_of_writes
			,inline.num_of_bytes_written
			,inline.database_id
			,inline.[file_id]
		FROM (
		SELECT  r.CaptureDate
				,r.read_per_ms - s.read_per_ms AS io_stall_read_ms
				,r.num_of_reads - s.num_of_reads AS num_of_reads
				,r.write_per_ms - s.write_per_ms AS io_stall_write_ms
				,r.num_of_writes - s.num_of_writes AS num_of_writes
				,r.num_of_bytes_written - s.num_of_bytes_written AS num_of_bytes_written
				,r.database_id AS database_id
				,r.[file_id] AS [file_id]

		FROM #IOStallSnapshot s
			 INNER JOIN #IOStallResult r ON (s.database_id = r.database_id and s.file_id = r.file_id)
		) inline
		LEFT  JOIN  (
								SELECT RANK() over (partition by database_id, [file_id] order by id desc) rnk, 
								[database_id],[file_id],iops,num_of_reads,num_of_writes
								FROM [BaselineData].[capture].[FileStats]
								) LastCaptureHadIops ON LastCaptureHadIops.database_id=inline.database_id 
								and LastCaptureHadIops.file_id=inline.file_id 
								and rnk = 1 		
								
				where ( inline.num_of_writes + inline.num_of_reads <> LastCaptureHadIops.num_of_writes + LastCaptureHadIops.num_of_reads  )
				 OR ( LastCaptureHadIops.rnk is null) 
				 OR (inline.num_of_writes + inline.num_of_reads > 0)

	TRUNCATE TABLE #IOStallSnapshot
	TRUNCATE TABLE #IOStallResult
	
 END -- END of WHILE

 /* Update Capture Data meta-data to include end time */
 UPDATE capture.FileStatsWindow
 SET EndTime = GETDATE()
 WHERE ID = @CaptureDataID

END




GO


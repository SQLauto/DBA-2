USE [msdb]
GO

DECLARE @jobExists  BIT;
EXEC #SqlJobExists @JobName = 'DB Maint - $(databasename) - Filegroup and Partition Management', @jobExists  = @jobExists  OUTPUT;
IF @jobExists = 0
BEGIN 

	BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0
	IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
	BEGIN
		
		EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitCreateWithRollback

	END

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DB Maint - $(databasename) - Filegroup and Partition Management', 
			@enabled=0, 
			@notify_level_eventlog=0, 
			@notify_level_email=0, 
			@notify_level_netsend=0, 
			@notify_level_page=0, 
			@delete_level=0, 
			@description=N'No description available.', 
			@category_name=N'Database Maintenance', 
			@owner_login_name=N'sa', @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitCreateWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_name=N'DB Maint - $(databasename) - Filegroup and Partition Management' , @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitCreateWithRollback

	COMMIT TRANSACTION
	GOTO CreateSave
	QuitCreateWithRollback:
		IF (@@TRANCOUNT > 0) 
		BEGIN
			ROLLBACK TRANSACTION
			RAISERROR('JOB CREATION Failure for DB Maint - $(databasename) - Filegroup and Partition Management',16,1)
		END
	CreateSave:

END




BEGIN 

BEGIN TRANSACTION

/* Remove All Steps and re-create them to preserve job history */


BEGIN TRY
DECLARE @step_id smallint


WHILE EXISTS(select JS.step_id from msdb.dbo.sysjobs J
				JOIN msdb.dbo.sysjobsteps JS ON J.job_id=JS.job_id
				where name ='DB Maint - $(databasename) - Filegroup and Partition Management')
BEGIN
	select @step_id=max(step_id) from msdb.dbo.sysjobs J
	JOIN msdb.dbo.sysjobsteps JS ON J.job_id=JS.job_id
	where name ='DB Maint - $(databasename) - Filegroup and Partition Management'

	EXEC msdb.dbo.sp_delete_jobstep @job_name=N'DB Maint - $(databasename) - Filegroup and Partition Management', @step_id=1
END

END TRY
BEGIN CATCH
	
	IF (@@TRANCOUNT > 0) 
		ROLLBACK TRANSACTION;
	THROW
END CATCH




/* STEP 1*/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_name=N'DB Maint - $(databasename) - Filegroup and Partition Management', @step_name=N'COMMON - Pre-Partitioning Processes', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DELETE FROM admin.PartitionLog WHERE EntryDate < DATEADD(month,-3,GETDATE()); ', 
		@database_name=N'$(databasename)', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitStepCreationWithRollback

/* STEP 2*/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_name=N'DB Maint - $(databasename) - Filegroup and Partition Management', @step_name=N'COMMON - Create New Filegroups', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=3, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET DEADLOCK_PRIORITY 10

DECLARE @StartDate DATETIME = GETDATE(), @EndDate DATETIME = DATEADD(week,10,GETDATE()), @RC INT;

EXEC @RC = [admin].[Partitioning_CreatePartitions]   @StartDate=@StartDate, @EndDate = @EndDate;

GO
',  
		@database_name=N'$(databasename)', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitStepCreationWithRollback

/* STEP 3*/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_name=N'DB Maint - $(databasename) - Filegroup and Partition Management', @step_name=N'COMMON - Archive Partitions', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET DEADLOCK_PRIORITY 10

DECLARE @Archiverundate datetime=GETDATE()

EXEC [admin].[Partitioning_TableArchiving] @ArchiveRunDate=@Archiverundate;

GO
', 
		@database_name=N'$(databasename)', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitStepCreationWithRollback
/* STEP 4*/

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_name=N'DB Maint - $(databasename) - Filegroup and Partition Management', @step_name=N'COMMON - Fail Job If a Step Failed', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @jobId UNIQUEIDENTIFIER = 
(
	SELECT job_id 
	FROM dbo.sysjobs 
	WHERE name = ''DB Maint - $(databasename) - Filegroup and Partition Management''
)

DECLARE @lastRunDate INT;
DECLARE @lastRunTime INT;

SELECT TOP 1
	@lastRunDate = CAST(FORMAT(start_execution_date, ''yyyyMMdd'') AS INT),
	@lastRunTime = CAST(FORMAT(start_execution_date,  ''HHmmss'') AS INT)	
FROM dbo.sysjobactivity
WHERE job_id = @jobId
ORDER BY run_requested_date DESC

IF EXISTS
(
	SELECT 1 
	FROM dbo.sysjobhistory 
	WHERE job_id = @jobId
	AND run_date >= @lastRunDate
	AND run_time >= @lastRunTime
	AND run_status in (0, 3) --failed or cancelled
)

BEGIN
	SELECT * 
	FROM dbo.sysjobhistory 
	WHERE job_id = @jobId
	AND run_date = @lastRunDate
	AND run_time = @lastRunTime
	AND run_status in (0, 3)
	ORDER BY step_id

	RAISERROR(''See output for failed or cancelled steps'', 16,1) 
END
ELSE
BEGIN
	SELECT * 
	FROM dbo.sysjobhistory 
	WHERE job_id = @jobId
	AND run_date = @lastRunDate
	AND run_time = @lastRunTime
	ORDER BY step_id
END;

', 
		@database_name=N'msdb', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitStepCreationWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_name=N'DB Maint - $(databasename) - Filegroup and Partition Management', @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitStepCreationWithRollback

DECLARE @step_name VARCHAR(100)

WHILE EXISTS(SELECT 1 FROM sysjobs J
JOIN sysjobschedules JS ON J.job_id = JS.job_id
JOIN sysschedules S ON S.schedule_id = JS.schedule_id 
WHERE J.name = 'DB Maint - $(databasename) - Filegroup and Partition Management'
)
BEGIN
	SELECT @step_name = S.[name]  FROM sysjobs J
	JOIN sysjobschedules JS ON J.job_id = JS.job_id
	JOIN sysschedules S ON S.schedule_id = JS.schedule_id 
	WHERE J.name = 'DB Maint - $(databasename) - Filegroup and Partition Management'
	
	EXECUTE  msdb.dbo.sp_delete_jobschedule @job_name=N'DB Maint - $(databasename) - Filegroup and Partition Management', @name=@step_name
END


EXECUTE @ReturnCode = msdb.dbo.sp_add_jobschedule @job_name=N'DB Maint - $(databasename) - Filegroup and Partition Management', @name=N'Sunday 500', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20140213, 
		@active_end_date=99991231, 
		@active_start_time=50000, 
		@active_end_time=235959;
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitStepCreationWithRollback;

	
/* DISABLE JOB WHEN DEPLOYED */

EXEC @ReturnCode= msdb.dbo.sp_update_job @job_name=N'DB Maint - $(databasename) - Filegroup and Partition Management', 
		@enabled=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitStepCreationWithRollback;		
		
	
COMMIT TRANSACTION
GOTO EndSave
QuitStepCreationWithRollback:
    IF (@@TRANCOUNT > 0) 
	BEGIN 
		
		ROLLBACK TRANSACTION
		RAISERROR('JOB CREATION Failure for DB Maint - $(databasename) - Filegroup and Partition Management',16,1)
		
	END 
	
EndSave:


END 


	


GO



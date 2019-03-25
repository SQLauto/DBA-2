DECLARE @jobExists  BIT;
EXEC #SqlJobExists @JobName = 'DB $(databasename) - Capture Procedure Performance', @jobExists  = @jobExists  OUTPUT;
IF @jobExists = 0
BEGIN 

	BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	SELECT @ReturnCode = 0
	IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'$(databasename)' AND category_class=1)
	BEGIN
		
		EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'$(databasename)'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitCreateWithRollback

	END

	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DB $(databasename) - Capture Procedure Performance', 
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

	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitCreateWithRollback


	COMMIT TRANSACTION
	GOTO CreateSave
	QuitCreateWithRollback:
		IF (@@TRANCOUNT > 0) 
		BEGIN
			ROLLBACK TRANSACTION
			RAISERROR('JOB CREATION Failure for DB $(databasename) - Capture Procedure Performance',16,1)
		END
	CreateSave:

END  
	


/* Remove All Steps and re-create them to preserve job history */


BEGIN TRY
BEGIN TRANSACTION
DECLARE @step_id smallint


WHILE EXISTS(select JS.step_id from msdb.dbo.sysjobs J
				JOIN msdb.dbo.sysjobsteps JS ON J.job_id=JS.job_id
				where name ='DB $(databasename) - Capture Procedure Performance')
BEGIN
	select @step_id=max(step_id) from msdb.dbo.sysjobs J
	JOIN msdb.dbo.sysjobsteps JS ON J.job_id=JS.job_id
	where name ='DB $(databasename) - Capture Procedure Performance'

	EXEC msdb.dbo.sp_delete_jobstep @job_name=N'DB $(databasename) - Capture Procedure Performance', @step_id=1
END

EXEC msdb.dbo.sp_update_job @job_name='DB $(databasename) - Capture Procedure Performance',@enabled = 0

/* STEP 1*/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_name=N'DB $(databasename) - Capture Procedure Performance', @step_name=N'Capture Procedure Performance', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
		 
DECLARE @EndTime datetime, @CollectionWaitSeconds int ,@MinutesTillExecutionEnd int

select @CollectionWaitSeconds=CollectionWaitSeconds,@MinutesTillExecutionEnd=MinutesTillExecutionEnd from capture.config
where jobname=''DB $(databasename) - Capture Procedure Performance''

SELECT @EndTime = DATEADD(MI,@MinutesTillExecutionEnd, getdate())
EXEC Capture.ProcedurePerformance  
@WaitTimeSec = @CollectionWaitSeconds, 
@StopTime = @EndTime
', 
		@database_name=N'$(databasename)', 
		@flags=0
		
DECLARE @job_id BINARY(16),@schedule_id INT

select @job_id = J.job_id from msdb.dbo.sysjobs J
where J.name = 'DB $(databasename) - Capture Procedure Performance'

IF EXISTS (
select 1 from msdb.dbo.sysjobs J
Join msdb.dbo.sysjobschedules S ON J.job_id=S.job_id
where name = 'DB $(databasename) - Capture Procedure Performance')
BEGIN 
select @schedule_id=S.schedule_id from msdb.dbo.sysjobs J
Join msdb.dbo.sysjobschedules S ON J.job_id=S.job_id
where name = 'DB $(databasename) - Capture Procedure Performance'

EXEC msdb.dbo.sp_detach_schedule @job_id=@job_id, @schedule_id=@schedule_id, @delete_unused_schedule=1

END


/*
	freq_type	int	How frequently a job runs for this schedule.
	1 = One time only
	4 = Daily
	8 = Weekly
	16 = Monthly
	32 = Monthly, relative to freq_interval
	64 = Runs when the SQL Server Agent service starts
	128 = Runs when the computer is idle
	
	
	freq_subday_type	int	Units for the freq_subday_interval. The following are the possible values and their descriptions.
	1 : At the specified time
	2 : Seconds
	4 : Minutes
	8 : Hours
	
*/

EXEC msdb.dbo.sp_add_jobschedule @job_id=@job_id, @name=N'DB $(databasename) - Capture Procedure Performance - Every 5 minutes', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5
		

COMMIT TRANSACTION 		
END TRY
BEGIN CATCH
	
	IF (@@TRANCOUNT > 0) 
		ROLLBACK TRANSACTION;
	THROW
END CATCH
	
EndSave:


















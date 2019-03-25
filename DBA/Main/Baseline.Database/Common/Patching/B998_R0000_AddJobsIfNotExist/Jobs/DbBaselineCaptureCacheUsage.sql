GO
DECLARE @jobExists  BIT;
EXEC #SqlJobExists @JobName = 'DB Baseline - Capture Cache Usage', @jobExists  = @jobExists  OUTPUT;
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
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DB $(databasename) - Capture Cache Usage - Every 15 minutes', 
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
			RAISERROR('JOB CREATION Failure for DB $(databasename) - Capture Cache Usage - Every 15 minutes',16,1)
		END
	CreateSave:

END  
	


/* Remove All Steps and re-create them to preserve job history */


BEGIN TRY
BEGIN TRANSACTION
DECLARE @step_id smallint


WHILE EXISTS(select JS.step_id from msdb.dbo.sysjobs J
				JOIN msdb.dbo.sysjobsteps JS ON J.job_id=JS.job_id
				where name ='DB $(databasename) - Capture Cache Usage - Every 15 minutes')
BEGIN
	select @step_id=max(step_id) from msdb.dbo.sysjobs J
	JOIN msdb.dbo.sysjobsteps JS ON J.job_id=JS.job_id
	where name ='DB $(databasename) - Capture Cache Usage - Every 15 minutes'

	EXEC msdb.dbo.sp_delete_jobstep @job_name=N'DB $(databasename) - Capture Cache Usage - Every 15 minutes', @step_id=1
END

EXEC msdb.dbo.sp_update_job @job_name='DB $(databasename) - Capture Cache Usage - Every 15 minutes',@enabled = 0

/* STEP 1*/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_name=N'DB $(databasename) - Capture Cache Usage - Every 15 minutes', @step_name=N'Capture Cache Usage', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec capture.CacheUsage', 
		@database_name=N'$(databasename)', 
		@flags=0
		
DECLARE @job_id BINARY(16),@schedule_id INT

select @job_id = J.job_id from msdb.dbo.sysjobs J
where J.name = 'DB $(databasename) - Capture Cache Usage'

IF EXISTS (
select 1 from msdb.dbo.sysjobs J
Join msdb.dbo.sysjobschedules S ON J.job_id=S.job_id
where name = 'DB $(databasename) - Capture Cache Usage')
BEGIN 
select @schedule_id=S.schedule_id from msdb.dbo.sysjobs J
Join msdb.dbo.sysjobschedules S ON J.job_id=S.job_id
where name = 'DB $(databasename) - Capture Cache Usage'

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

EXEC msdb.dbo.sp_add_jobschedule @job_id=@job_id, @name=N'DB $(databasename) - Capture Cache Usage - Every 15 minutes - Every 15 minutes', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=15
	


COMMIT TRANSACTION 		
END TRY
BEGIN CATCH
	
	IF (@@TRANCOUNT > 0) 
		ROLLBACK TRANSACTION;
	THROW
END CATCH
	
EndSave:


















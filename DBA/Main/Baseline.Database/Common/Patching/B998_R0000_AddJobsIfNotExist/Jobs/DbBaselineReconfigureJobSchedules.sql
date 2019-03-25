DECLARE @jobExists  BIT;
EXEC #SqlJobExists @JobName = 'DB $(databasename) - Reconfigure Job Schedules', @jobExists  = @jobExists  OUTPUT;
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

	
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_name=N'DB $(databasename) - Reconfigure Job Schedules', @name=N'DB $(databasename) - Reconfigure Job Schedules - Every 1 Day', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1,
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20150907, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959 
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitCreateWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitCreateWithRollback


	COMMIT TRANSACTION
	GOTO CreateSave
	QuitCreateWithRollback:
		IF (@@TRANCOUNT > 0) 
		BEGIN
			ROLLBACK TRANSACTION
			RAISERROR('JOB CREATION Failure for DB $(databasename) - Reconfigure Job Schedules',16,1)
		END
	CreateSave:

END  
	


/* Remove All Steps and re-create them to preserve job history */


BEGIN TRY
BEGIN TRANSACTION
DECLARE @step_id smallint


WHILE EXISTS(select JS.step_id from msdb.dbo.sysjobs J
				JOIN msdb.dbo.sysjobsteps JS ON J.job_id=JS.job_id
				where name ='DB $(databasename) - Reconfigure Job Schedules')
BEGIN
	select @step_id=max(step_id) from msdb.dbo.sysjobs J
	JOIN msdb.dbo.sysjobsteps JS ON J.job_id=JS.job_id
	where name ='DB $(databasename) - Reconfigure Job Schedules'

	EXEC msdb.dbo.sp_delete_jobstep @job_name=N'DB $(databasename) - Reconfigure Job Schedules', @step_id=1
END

EXEC msdb.dbo.sp_update_job @job_name='DB $(databasename) - Reconfigure Job Schedules',@enabled = 0

/* STEP 1*/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_name=N'DB $(databasename) - Reconfigure Job Schedules', @step_name=N'Reconfigure Job Schedules', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC capture.UpdateSchedulesFromConfig', 
		@database_name=N'$(databasename)', 
		@flags=0
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
		
EXEC msdb.dbo.sp_update_schedule @name='DB $(databasename) - Reconfigure Job Schedules - Every 1 Day', 
	@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1,
		
COMMIT TRANSACTION 		
END TRY
BEGIN CATCH
	
	IF (@@TRANCOUNT > 0) 
		ROLLBACK TRANSACTION;
	THROW
END CATCH
	
EndSave:


















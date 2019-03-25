DECLARE @jobExists  BIT;
EXEC #SqlJobExists @JobName = 'DB $(databasename) - Capture Daily Config Values', @jobExists  = @jobExists  OUTPUT;
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
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DB $(databasename) - Capture Daily Config Values', 
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
			RAISERROR('JOB CREATION Failure for DB $(databasename) - Capture Daily Config Values',16,1)
		END
	CreateSave:

END  
	


/* Remove All Steps and re-create them to preserve job history */


BEGIN TRY
BEGIN TRANSACTION
DECLARE @step_id smallint


WHILE EXISTS(select JS.step_id from msdb.dbo.sysjobs J
				JOIN msdb.dbo.sysjobsteps JS ON J.job_id=JS.job_id
				where name ='DB $(databasename) - Capture Daily Config Values')
BEGIN
	select @step_id=max(step_id) from msdb.dbo.sysjobs J
	JOIN msdb.dbo.sysjobsteps JS ON J.job_id=JS.job_id
	where name ='DB $(databasename) - Capture Daily Config Values'

	EXEC msdb.dbo.sp_delete_jobstep @job_name=N'DB $(databasename) - Capture Daily Config Values', @step_id=1
END

EXEC msdb.dbo.sp_update_job @job_name='DB $(databasename) - Capture Daily Config Values',@enabled = 0

/* STEP 1*/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_name=N'DB $(databasename) - Capture Daily Config Values', @step_name=N'Daily Config Capture', 
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


INSERT  INTO [capture].[ConfigData]
        ( [ConfigurationID] ,
          [Name] ,
          [Value] ,
          [ValueInUse] ,
          [CaptureDate]
        )
        SELECT  [configuration_id] ,
                [name] ,
                [value] ,
                [value_in_use] ,
                GETDATE()
        FROM    [sys].[configurations];


INSERT  INTO [capture].[ServerConfig]
        ( [Property] ,
          [Value]
        )
        EXEC xp_instance_regread N''HKEY_LOCAL_MACHINE'',
            N''HARDWARE\DESCRIPTION\System\CentralProcessor\0'',
            N''ProcessorNameString'';
UPDATE  [capture].[ServerConfig]
SET     [CaptureDate] = GETDATE()
WHERE   [Property] = N''ProcessorNameString''
        AND [CaptureDate] IS NULL;


INSERT  INTO [capture].[ServerConfig]
        ( [Property] ,
          [Value] ,
          [CaptureDate]
        )
        SELECT  N''MachineName'' ,
                SERVERPROPERTY(''MachineName'') ,
                GETDATE();
INSERT  INTO [capture].[ServerConfig]
        ( [Property] ,
          [Value] ,
          [CaptureDate]
        )
        SELECT  N''ServerName'' ,
                SERVERPROPERTY(''ServerName'') ,
                GETDATE();
INSERT  INTO [capture].[ServerConfig]
        ( [Property] ,
          [Value] ,
          [CaptureDate]
        )
        SELECT  N''InstanceName'' ,
                SERVERPROPERTY(''InstanceName'') ,
                GETDATE();
INSERT  INTO [capture].[ServerConfig]
        ( [Property] ,
          [Value] ,
          [CaptureDate]
        )
        SELECT  N''IsClustered'' ,
                SERVERPROPERTY(''IsClustered'') ,
                GETDATE();
INSERT  INTO [capture].[ServerConfig]
        ( [Property] ,
          [Value] ,
          [CaptureDate]
        )
        SELECT  N''ComputerNamePhysicalNetBios'' ,
                SERVERPROPERTY(''ComputerNamePhysicalNetBIOS'') ,
                GETDATE();
INSERT  INTO [capture].[ServerConfig]
        ( [Property] ,
          [Value] ,
          [CaptureDate]
        )
        SELECT  N''Edition'' ,
                SERVERPROPERTY(''Edition'') ,
                GETDATE();
INSERT  INTO [capture].[ServerConfig]
        ( [Property] ,
          [Value] ,
          [CaptureDate]
        )
        SELECT  N''ProductLevel'' ,
                SERVERPROPERTY(''ProductLevel'') ,
                GETDATE();
INSERT  INTO [capture].[ServerConfig]
        ( [Property] ,
          [Value] ,
          [CaptureDate]
        )
        SELECT  N''ProductVersion'' ,
                SERVERPROPERTY(''ProductVersion'') ,
                GETDATE();

DECLARE @TRACESTATUS TABLE
    (
      [TraceFlag] SMALLINT ,
      [Status] BIT ,
      [Global] BIT ,
      [Session] BIT
    );

INSERT  INTO @TRACESTATUS
        EXEC ( ''DBCC TRACESTATUS (-1)''
            );

IF ( SELECT COUNT(*)
     FROM   @TRACESTATUS
   ) > 0 
    BEGIN;
        INSERT  INTO [capture].[ServerConfig]
                ( [Property] ,
                  [Value] ,
                  [CaptureDate]
                )
                SELECT  N''DBCC_TRACESTATUS'' ,
                        ''TF '' + CAST([TraceFlag] AS VARCHAR(5))
                        + '': Status = '' + CAST([Status] AS VARCHAR(1))
                        + '', Global = '' + CAST([Global] AS VARCHAR(1))
                        + '', Session = '' + CAST([Session] AS VARCHAR(1)) ,
                        GETDATE()
                FROM    @TRACESTATUS
                ORDER BY [TraceFlag];
    END;
ELSE 
    BEGIN;
        INSERT  INTO [capture].[ServerConfig]
                ( [Property] ,
                  [Value] ,
                  [CaptureDate]
                )
                SELECT  N''DBCC_TRACESTATUS'' ,
                        ''No trace flags enabled'' ,
                        GETDATE()
    END;', 
		@database_name=N'$(databasename)', 
		@flags=0

		
DECLARE @job_id BINARY(16),@schedule_id INT

select @job_id = J.job_id from msdb.dbo.sysjobs J
where J.name = 'DB $(databasename) - Capture Daily Config Values'

IF EXISTS (
select 1 from msdb.dbo.sysjobs J
Join msdb.dbo.sysjobschedules S ON J.job_id=S.job_id
where name = 'DB $(databasename) - Capture Daily Config Values')
BEGIN 
select @schedule_id=S.schedule_id from msdb.dbo.sysjobs J
Join msdb.dbo.sysjobschedules S ON J.job_id=S.job_id
where name = 'DB $(databasename) - Capture Daily Config Values'

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

EXEC msdb.dbo.sp_add_jobschedule @job_id=@job_id, @name=N'DB $(databasename) - Capture Daily Config Values', 
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


















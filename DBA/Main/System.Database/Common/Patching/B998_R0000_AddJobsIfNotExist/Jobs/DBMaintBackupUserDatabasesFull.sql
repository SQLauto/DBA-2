
go

if exists(select 1 from msdb.dbo.sysjobs where name=N'DB Maint - Backup User Databases Full')
begin
	goto EndSave
end

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 19/10/2015 11:09:06 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DB Maint - Backup User Databases Full', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'The CE DBA Team', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Start Full Backup's]    Script Date: 19/10/2015 11:09:06 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Start Full Backup''s', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
DECLARE @SQL varchar(max)
DECLARE @Database varchar(200)
DECLARE @Cleanup varchar(10)
DECLARE @backupdirectory varchar(300)

MERGE system.dbo.dbmaint dbm
USING sys.databases  sd
ON sd.name = dbm.name 
WHEN MATCHED 
THEN 
UPDATE 
SET status= CASE sd.state_desc WHEN ''OFFLINE'' THEN 0 ELSE 1 END 
,issystem=CASE WHEN sd.database_id<5 THEN 1 ELSE 0 END 
,isuser=CASE WHEN sd.database_id>4 THEN 1 ELSE 0 END
WHEN NOT MATCHED  THEN 
INSERT (name,status,fullbackup,issystem,isuser)
VALUES (sd.name
		,CASE sd.state_desc WHEN ''OFFLINE'' THEN 0 ELSE 1 END
		,0
		,CASE WHEN sd.database_id<5 THEN 1 ELSE 0 END 
		,CASE WHEN sd.database_id>4 THEN 1 ELSE 0 END )
		;



DECLARE  BackupCursor Cursor for
SELECT name,cast(cleanup as varchar(10)) cleanup,backupdirectory
FROM system.dbo.dbmaint
WHERE fullbackup=1 and status=1 and isuser=1

OPEN BackupCursor
FETCH NEXT FROM BackupCursor INTO @Database,@Cleanup,@backupdirectory 

WHILE @@FETCH_STATUS=0
BEGIN 


EXECUTE system.dbo.DatabaseBackup
@Databases = @Database,
@BackupType = ''FULL'',
@Verify = ''Y'',
@Compress = ''Y'',
@CheckSum = ''Y'',
@CleanupTime = @Cleanup,
@Directory=@backupdirectory 

FETCH NEXT FROM BackupCursor INTO @Database,@Cleanup,@backupdirectory 
END 

CLOSE BackupCursor
DEALLOCATE BackupCursor

--truncate table system.dbo.dbmaint', 
		@database_name=N'System', 
		@output_file_name=N'K:\CS_SQLBKP02\BackupJobOutput.txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [clear wait stats]    Script Date: 19/10/2015 11:09:06 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'clear wait stats', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DBCC SQLPERF(''sys.dm_os_wait_stats'', CLEAR);', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily', 
		@enabled=0, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130102, 
		@active_end_date=99991231, 
		@active_start_time=200000, 
		@active_end_time=235959, 
		@schedule_uid=N'dae3ab00-17f0-4449-93ec-a659712e6caf'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:


go


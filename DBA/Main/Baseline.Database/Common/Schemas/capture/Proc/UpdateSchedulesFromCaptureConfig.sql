EXEC #CreateDummyStoredProcedureIfNotExists 'capture', 'UpdateSchedulesFromConfig'
GO
ALTER PROCEDURE [capture].UpdateSchedulesFromConfig 
AS



DECLARE 
@schedule_id INT, 
@schedulename VARCHAR(100),
@freq_type int,
@freq_interval int,
@freq_subday_type int,
@freq_subday_interval INT,
@active_start_time int

DECLARE JobCursor CURSOR FOR
SELECT  ScheduleName, freq_type, freq_interval, freq_subday_type, 
freq_subday_interval,active_start_time FROM Config;

OPEN Jobcursor;
FETCH NEXT FROM Jobcursor INTO  @ScheduleName, @freq_type, @freq_interval, @freq_subday_type, 
@freq_subday_interval,@active_start_time

WHILE @@FETCH_STATUS = 0
BEGIN 


If @freq_subday_type=1
BEGIN 
EXECUTE msdb.dbo.sp_update_schedule   @name=@ScheduleName,@freq_type=@freq_type,@freq_interval=@freq_interval,
		@freq_subday_type=@freq_subday_type,@enabled = 1
END
ELSE 
BEGIN 
	EXECUTE msdb.dbo.sp_update_schedule  @name=@ScheduleName,@freq_type=@freq_type,@freq_interval=@freq_interval,
		@freq_subday_type=@freq_subday_type,@freq_subday_interval=@freq_subday_interval,@enabled = 1 ;
END 


FETCH NEXT FROM Jobcursor INTO  @ScheduleName, @freq_type, @freq_interval, @freq_subday_type, 
@freq_subday_interval,@active_start_time

END; 

CLOSE Jobcursor;
DEALLOCATE Jobcursor;




GO
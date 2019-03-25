

GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO


BEGIN TRY
/*
This is to back date production update after Release 68
*/
DECLARE @Config TABLE
(
	Jobname varchar(200) PRIMARY KEY NOT NULL ,
	ScheduleName varchar(100) NOT NULL,
	freq_type int NOT NULL,
	freq_interval int ,
	freq_subday_type int ,
	freq_subday_interval int,
	active_start_time int,
	CollectionWaitSeconds int,
	MinutesTillExecutionEnd smallint
	
)



INSERT into @Config
VALUES('DB $(databasename) - Capture Buffer usage by DB','Capture Buffer usage by DB',4,1,8,1,000000,300,60)
,('DB $(databasename) - Capture CPU by DB','Capture CPU by DB',4,1,4,1,000000,300,60)
,('DB $(databasename) - Capture CPU Utilisation','Capture CPU Utilisation',4,1,4,15,000000,300,60)
,('DB $(databasename) - Capture File Info','Capture File Info',4,1,8,1,000000,300,60)
,('DB $(databasename) - Capture Disk Latency','Capture Disk Latency',4,1,4,1,000000,300,60)
,('DB $(databasename) - Capture Daily Config Values','Capture Daily Config Values',4,1,1,1,000000,300,60)
,('DB $(databasename) - Capture Perfmon Counters','Capture Perfmon Counters',4,1,4,10,000000,300,60)
,('DB $(databasename) - Capture Procedure Performance','Capture Procedure Performance',4,1,4,1,000000,300,60)
,('DB $(databasename) - Capture Query Performance','Capture Query Performance',4,1,4,1,000000,900,60)
,('DB $(databasename) - Capture sp_whoisactive','Capture sp_whoisactive',4,1,4,1,000000,300,60)
,('DB $(databasename) - Capture Wait Stats','Capture Wait Stats',4,1,8,1,000000,300,60)
,('DB $(databasename) - Purge Old Data','Purge Old Data',4,1,1,1,000000,300,60)
,('DB $(databasename) - Reconfigure Job Schedules','Reconfigure Job Schedules',4,1,4,1,000000,300,60);


MERGE capture.Config AS target
USING (select Jobname,ScheduleName,freq_type,freq_interval,freq_subday_type,
								freq_subday_interval,active_start_time,CollectionWaitSeconds,MinutesTillExecutionEnd from @Config) 
								AS source ON (target.Jobname=source.Jobname)
WHEN MATCHED THEN
	UPDATE SET 	ScheduleName=source.ScheduleName,
				freq_type=source.freq_type,
				freq_interval=source.freq_interval,
				freq_subday_type=source.freq_subday_type,
				freq_subday_interval=source.freq_subday_interval,
				active_start_time=source.active_start_time,
				CollectionWaitSeconds=source.CollectionWaitSeconds,
				MinutesTillExecutionEnd=source.MinutesTillExecutionEnd
WHEN NOT MATCHED THEN 
	INSERT (Jobname,ScheduleName,freq_type,freq_interval,freq_subday_type,
								freq_subday_interval,active_start_time,CollectionWaitSeconds,MinutesTillExecutionEnd)
	VALUES(source.Jobname,source.ScheduleName,
				source.freq_type,
				source.freq_interval,
				source.freq_subday_type,
				source.freq_subday_interval,
				source.active_start_time,
				source.CollectionWaitSeconds,
				source.MinutesTillExecutionEnd);




END TRY
BEGIN CATCH

;THROW
END CATCH

GO


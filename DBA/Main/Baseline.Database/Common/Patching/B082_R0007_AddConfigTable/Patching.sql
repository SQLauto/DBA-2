
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @columnExists bit 
declare @tableExists bit
declare @primaryKeyName varchar(124)
exec #TableExists 'capture', 'Config',  @tableExists out
if (@tableExists = 0)
begin
BEGIN TRY
BEGIN TRANSACTION

CREATE TABLE capture.ConfigFreqType
(
	value int primary key,
	description varchar(100)
)

INSERT into capture.ConfigFreqType
SELECT 4,'Daily'


CREATE TABLE capture.ConfigFreqSubDayType
(
	value int primary key,
	description varchar(100)
)


INSERT into capture.ConfigFreqSubDayType
VALUES (1,'At the specified time'),(2,'Seconds'),(4,'Minutes'),(8,'Hours')


CREATE TABLE capture.Config
(
	Jobname varchar(200) PRIMARY KEY NOT NULL ,
	ScheduleName varchar(100) NOT NULL,
	freq_type int NOT NULL,
	freq_interval int ,
	freq_subday_type int ,
	freq_subday_interval int,
	active_start_time int,
	CollectionWaitSeconds int,
	MinutesTillExecutionEnd smallint,
	CONSTRAINT FK_FreqType FOREIGN KEY (freq_type)     
    REFERENCES capture.ConfigFreqType (value),
	CONSTRAINT FK_FreqSubDayType FOREIGN KEY (freq_subday_type)     
    REFERENCES capture.ConfigFreqSubDayType (value)
)




COMMIT TRANSACTION 
END TRY 
BEGIN CATCH
if @@TRANCOUNT >0
	ROLLBACK TRANSACTION

;THROW
END CATCH
end


GO
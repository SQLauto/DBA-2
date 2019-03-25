USE PARE
GO


IF OBJECT_ID('statuslist.StateMachineMessage_OLD') IS NOT NULL 
BEGIN 

RAISERROR('THIS SCRIPT HAS ALREADY BEEN RUN as statuslist.StateMachineMessage_OLD exists PLEASE SPEAK TO DBA FROM TFL',16,1)

END 
ELSE
BEGIN




IF OBJECT_ID('statuslist.StateMachineMessage_NEW') IS NOT NULL 
DROP TABLE statuslist.StateMachineMessage_NEW 

/* LOGIC FROM THE  STORED PROC USING GREATER THAN  */
DECLARE @numberOfDaysToKeep SMALLINT = 21,@Now DATETIME = NULL

SET @Now = ISNULL(@Now, SYSDATETIMEOFFSET());
DECLARE @Epoch DATETIME = '2010-01-01';	
DECLARE @TravelDayToRemove SMALLINT = DATEDIFF(day, @Epoch, @Now) - @numberOfDaysToKeep;


SELECT * INTO statuslist.StateMachineMessage_NEW 
FROM statuslist.StateMachineMessage(NOLOCK) WHERE TravelDay >= @TravelDayToRemove;



if not exists(select 1 from sys.indexes idx
	WHERE OBJECT_NAME(object_id) = 'StateMachineMessage_NEW'
	AND OBJECT_SCHEMA_NAME(object_id) = 'statuslist'
					and  idx.name = 'PK_StatusListStateMachineMessage_NEW')
BEGIN 
	ALTER TABLE [statuslist].[StateMachineMessage_NEW] ADD  CONSTRAINT [PK_StatusListStateMachineMessage_NEW] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
END



if not exists(select 1 from sys.indexes idx
	WHERE OBJECT_NAME(object_id) = 'StateMachineMessage_NEW'
	AND OBJECT_SCHEMA_NAME(object_id) = 'statuslist'
					and  idx.name = 'IX_StatusListStateMachineMessage_TravelDay_NEW')
BEGIN 
	CREATE NONCLUSTERED INDEX [IX_StatusListStateMachineMessage_TravelDay_NEW] ON [statuslist].[StateMachineMessage_NEW]
	(
		[TravelDay] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
END


if not exists(select 1 from sys.indexes idx
	WHERE OBJECT_NAME(object_id) = 'StateMachineMessage_NEW'
	AND OBJECT_SCHEMA_NAME(object_id) = 'statuslist'
					and  idx.name = 'IX_StatusListStateMachineMessage_Hash_NEW')
CREATE NONCLUSTERED INDEX [IX_StatusListStateMachineMessage_Hash_NEW] ON [statuslist].[StateMachineMessage_NEW]
(
	[Hash] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

IF OBJECT_ID('[statuslist].[DF_StatusList_StateMachineMessage_Id_NEW]', 'D') IS NULL 
BEGIN 
	ALTER TABLE [statuslist].[StateMachineMessage_NEW] ADD  CONSTRAINT [DF_StatusList_StateMachineMessage_Id_NEW]  
	DEFAULT (NEXT VALUE FOR [statuslist].[StateMachineMessageSequence]) FOR [Id]
END 


BEGIN TRY
BEGIN TRANSACTION

	EXEC sp_rename N'statuslist.StateMachineMessage.PK_StatusListStateMachineMessage', N'PK_StatusListStateMachineMessage_OLD', N'INDEX';   
	EXEC sp_rename N'statuslist.StateMachineMessage.IX_StatusListStateMachineMessage_TravelDay', N'IX_StatusListStateMachineMessage_TravelDay_OLD', N'INDEX';   
	EXEC sp_rename N'statuslist.StateMachineMessage.IX_StatusListStateMachineMessage_Hash', N'IX_StatusListStateMachineMessage_Hash_OLD', N'INDEX'; 
	EXEC sp_rename N'statuslist.DF_StatusList_StateMachineMessage_Id', N'DF_StatusList_StateMachineMessage_Id_OLD'; 
	EXEC sp_rename N'statuslist.StateMachineMessage', N'StateMachineMessage_OLD';   


	EXEC sp_rename N'statuslist.StateMachineMessage_NEW.PK_StatusListStateMachineMessage_NEW', N'PK_StatusListStateMachineMessage', N'INDEX';  
	EXEC sp_rename N'statuslist.StateMachineMessage_NEW.IX_StatusListStateMachineMessage_TravelDay_NEW', N'IX_StatusListStateMachineMessage_TravelDay', N'INDEX';   
	EXEC sp_rename N'statuslist.StateMachineMessage_NEW.IX_StatusListStateMachineMessage_Hash_NEW', N'IX_StatusListStateMachineMessage_Hash', N'INDEX';  
	EXEC sp_rename N'statuslist.DF_StatusList_StateMachineMessage_Id_NEW', N'DF_StatusList_StateMachineMessage_Id'; 	
	EXEC sp_rename N'statuslist.StateMachineMessage_NEW', N'StateMachineMessage';   


COMMIT  TRANSACTION


END TRY
BEGIN CATCH
   IF @@trancount > 0 ROLLBACK TRANSACTION
   ;THROW

END CATCH


END
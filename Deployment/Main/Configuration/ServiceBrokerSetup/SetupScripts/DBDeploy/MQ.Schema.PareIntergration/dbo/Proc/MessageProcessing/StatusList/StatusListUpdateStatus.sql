CREATE PROCEDURE [dbo].[StatusListUpdateStatus]
	@statusListInstructionId bigint,
	@statusListInstructionStatusId tinyint,	
	@errorDescription varchar(100),
	@messageReceivedAt datetimeoffset
AS

BEGIN     

DECLARE @SQL varchar(max)

--retrieve earliest travel day in the first readwrite filegroup
		DECLARE @created datetimeoffset
		select @created=cast(ArchivetoLiveSwitchOverPartitionKeyValue as datetimeoffset)
		 from internal.PartitionConfig
		where name='StatuslistInstruction'
		  
	IF (@statusListInstructionStatusId = 3)				 
	BEGIN
				SET @SQL='UPDATE dbo.StatuslistInstruction
				SET StatusListInstructionStatusId = '+cast(@statusListInstructionStatusId as varchar(10))+',
				Received = '''+cast(@messageReceivedAt as varchar(100))+''',
				Acknowledged = SYSDATETIMEOFFSET()
				WHERE created>='''+cast(@created as varchar(100))+''' AND  Id = '+cast(@statusListInstructionId as varchar(100))	
				PRINT @SQL
				EXEC(@SQL)				 
	END 
		ELSE				
		BEGIN
				SET @SQL='UPDATE dbo.StatusListInstruction
				SET StatusListInstructionStatusId = '+cast(@statusListInstructionStatusId as varchar(10))+',
				ErrorDescription = '''+cast(@errorDescription as varchar(100))+''',
				Received = '''+cast(@messageReceivedAt as varchar(100))+'''
				WHERE created>='''+cast(@created as varchar(100))+''' AND  Id = '+cast(@statusListInstructionId as varchar(100))	
	PRINT @SQL
	EXEC(@SQL)			  
	END 
END


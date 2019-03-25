CREATE PROCEDURE [dbo].[Authorisation_ActivationSE]
AS
BEGIN
	SET NOCOUNT ON
			
	DECLARE @receive table (MessageType sysname,
		MessageBody varbinary(MAX),
		Handle uniqueidentifier)

    --Get some messages from the SE queue
    WHILE 1=1
    BEGIN
		BEGIN transaction;
		waitfor (receive TOP(1000) 
						message_type_name,
						message_body,
						conversation_handle
			FROM [http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Se/Pare]
			into @receive
		), timeout 1000;
        
		declare @receivecount int;
		select @receivecount = COUNT(*) from @receive;
		IF @receivecount = 0
		BEGIN
			COMMIT;
			BREAK;
		END

		DECLARE @h UNIQUEIDENTIFIER;
		DECLARE @t sysname;
		DECLARE @b varbinary(MAX);
		Declare @startttime as datetimeoffset = sysdatetimeoffset()
		Declare @ratepersecond as decimal(20)
		DECLARE MessageCursor CURSOR FAST_FORWARD FOR
			SELECT Handle, MessageType, MessageBody from @receive;

		OPEN MessageCursor

		FETCH NEXT FROM MessageCursor INTO @h, @t, @b;
		
		WHILE @@FETCH_STATUS = 0
		BEGIN
			EXECUTE [dbo].[Authorisation_ProcessResponse] @h, @t, @b;
			FETCH NEXT FROM MessageCursor INTO @h, @t, @b;
		END
		CLOSE MessageCursor
		DEALLOCATE MessageCursor

		DELETE FROM @receive
		COMMIT;
	   	EXECUTE [internal].[AddPerformanceCounterValues] @startttime,@receivecount,'Se'		    
    END     
END
GO

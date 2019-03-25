CREATE PROCEDURE [dbo].[SsbSendOnRawConversation](
	@fromService SYSNAME,
	@toService SYSNAME,
	@onContract SYSNAME,
	@messageType SYSNAME,
	@messageBody varbinary(max),
	@ConversationHandle UNIQUEIDENTIFIER OUTPUT
	)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @handle UNIQUEIDENTIFIER;
	DECLARE @counter INT;
	DECLARE @error INT;
	DECLARE @created datetimeoffset;
	DECLARE @conversationTimer INT;
	DECLARE @maxConversationAge INT;
	DECLARE @conversationTimeout INT;

	SELECT @counter = 1;
	SET @maxConversationAge = 86400;
	SET @conversationTimer = @maxConversationAge + 10;
	SET @conversationTimeout = @maxConversationAge * 2;

	-- Will need a loop to retry in case the conversation is
	-- in a state that does not allow transmission
	--
	WHILE (1=1)
	BEGIN
		-- Seek an eligible conversation in [SsbSessionConversations]
		SELECT @handle = Handle, @created = Created
			FROM [SsbSessionConversations]
			WHERE FromService = @fromService
			AND ToService = @toService
			AND OnContract = @OnContract;
		SET @ConversationHandle = @handle;

		IF @handle IS NULL
		BEGIN
			-- Need to start a new conversation for the current @@spid
			--
			BEGIN DIALOG CONVERSATION @handle
				FROM SERVICE @fromService
				TO SERVICE @toService
				ON CONTRACT @onContract
				WITH ENCRYPTION = ON;
			
			BEGIN TRY
				INSERT INTO [SsbSessionConversations] (FromService, ToService, OnContract, Handle, Created) VALUES (@fromService, @toService, @onContract, @handle, SYSDATETIMEOFFSET());
				BEGIN CONVERSATION TIMER (@handle) TIMEOUT = @conversationTimeout;
			END TRY
			BEGIN CATCH
				END CONVERSATION @handle;
				SELECT @handle = Handle, @created = Created
					FROM [SsbSessionConversations]
					WHERE FromService = @fromService
					AND ToService = @toService
					AND OnContract = @OnContract;
			END CATCH

			SET @ConversationHandle = @handle;
			
		END;
		ELSE IF @created is not null and @created < (select dateadd(ss, @maxConversationAge * -1, SYSDATETIMEOFFSET()))
		BEGIN
			-- It's too old. Delete it and re-loop so that we start another
			DELETE FROM SsbSessionConversations WHERE Handle = @handle;
			SELECT @handle = null;
			BEGIN DIALOG CONVERSATION @handle
				FROM SERVICE @fromService
				TO SERVICE @toService
				ON CONTRACT @onContract
				WITH ENCRYPTION = ON;
							
			BEGIN TRY
				INSERT INTO [SsbSessionConversations] (FromService, ToService, OnContract, Handle, Created) VALUES (@fromService, @toService, @onContract, @handle, SYSDATETIMEOFFSET());
				BEGIN CONVERSATION TIMER (@handle) TIMEOUT = @conversationTimeout;
			END TRY
			BEGIN CATCH
				END CONVERSATION @handle;
				SELECT @handle = Handle, @created = Created
					FROM [SsbSessionConversations]
					WHERE FromService = @fromService
					AND ToService = @toService
					AND OnContract = @OnContract;
			END CATCH
			
			SET @ConversationHandle = @handle;
			
		END;

		-- Attempt to SEND on the associated conversation
		DECLARE @send_ok INT = 1;
		BEGIN TRY

			;SEND ON CONVERSATION @handle
				MESSAGE TYPE @messageType
				(@messageBody);
		END TRY
		BEGIN CATCH
			SET @send_ok = 0;
		END CATCH;
		IF(@send_ok = 1)
		BEGIN
			BREAK;
		END
		
		SELECT @counter = @counter+1;
		IF @counter > 10
		BEGIN
			-- We failed 10 times in a row, something must be broken
			--
			RAISERROR (
				N'Failed to SEND on a conversation for more than 10 times. Error %i.'
				, 16, 1, @error) WITH LOG;
			BREAK;
		END
		-- Delete the associated conversation from the table and try again
		--
		DELETE FROM [SsbSessionConversations]
			WHERE Handle = @handle;
			SELECT @handle = NULL;
	END
END
GO
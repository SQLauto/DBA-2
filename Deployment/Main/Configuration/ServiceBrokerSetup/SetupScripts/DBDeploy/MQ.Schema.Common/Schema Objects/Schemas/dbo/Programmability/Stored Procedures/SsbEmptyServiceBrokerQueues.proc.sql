CREATE PROCEDURE [dbo].[SsbEmptyServiceBrokerQueues]
AS
	-- Tear down conversations
	DECLARE @Handle uniqueidentifier;
	DECLARE ConversationCursor Cursor
	FOR SELECT Conversation_handle FROM sys.conversation_endpoints;
	
	OPEN ConversationCursor;

	FETCH NEXT FROM ConversationCursor INTO @Handle;
	WHILE @@FETCH_STATUS = 0
	BEGIN
	  END CONVERSATION @Handle WITH CLEANUP;
	  FETCH NEXT FROM ConversationCursor INTO @Handle;
	END

	CLOSE ConversationCursor;
	DEALLOCATE ConversationCursor;

	--Empty the list of available conversations as we just ended them all.
	DELETE FROM [dbo].[SsbSessionConversations];
	 
RETURN 0
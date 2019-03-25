CREATE PROCEDURE [dbo].[SsbSendOnConversation](
	@fromService SYSNAME,
	@toService SYSNAME,
	@onContract SYSNAME,
	@messageType SYSNAME,
	@messageBody xml,
	@ConversationHandle UNIQUEIDENTIFIER OUTPUT
	)
AS
BEGIN  
	DECLARE @rawMessage VARBINARY(MAX);
	EXEC [dbo].[LogMessage] @messageType, @messageBody
	SET @rawMessage = CAST(@messageBody as VARBINARY(MAX));
	EXEC [dbo].[SsbSendOnRawConversation] @fromService,@toService,@onContract,@messageType,@rawMessage,@ConversationHandle = @ConversationHandle OUTPUT		

END
GO


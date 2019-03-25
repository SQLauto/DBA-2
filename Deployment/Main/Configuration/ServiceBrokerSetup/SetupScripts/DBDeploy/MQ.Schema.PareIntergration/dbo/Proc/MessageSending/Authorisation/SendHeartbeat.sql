CREATE PROCEDURE [dbo].[SendHeartbeat]
	@HeartbeatId bigint, 
	@SentDateTime datetimeoffset,
	@DestinationQueue varchar(4),
	-- Returns the time that the message was sent
	@SentTimeStamp datetimeoffset(7) output,
	-- Returns the GUID of the conversation that the message was sent on
	@ConversationHandle uniqueidentifier output

AS
	--Do some argument validation
	IF @DestinationQueue NOT IN ('Idra', 'Se', 'Dre')
	BEGIN
		RAISERROR('%s is not a valid queue', 16, 2, @DestinationQueue);
	END

	DECLARE @Message XML([http://tfl.gov.uk/Ft/Pare/Authorisation/Schema/Heartbeat/Request/v1]);

	EXEC [dbo].[CreateHeartbeatRequest]
		@HeartbeatId,
		@SentDateTime,
		@Message = @Message OUTPUT;

	--Send the message
	SET @SentTimeStamp = SYSDATETIMEOFFSET();

	DECLARE @FromService SYSNAME = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Service/' + @DestinationQueue + '/Pare';
	DECLARE @ToService SYSNAME = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Service/' + @DestinationQueue + '/Pcs';;
	DECLARE @Contract SYSNAME = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Contract/Pare';
	DECLARE @MessageType SYSNAME = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Message/Heartbeat/Request';

	EXEC [dbo].[SsbSendOnConversation]	
		@FromService,
		@ToService,
		@Contract,
		@MessageType,
		@Message,
		@ConversationHandle = @ConversationHandle output;

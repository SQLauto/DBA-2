CREATE PROCEDURE [dbo].[SendAuthorisationReversal]
	@AuthorisationTrackingId bigint,
	@AuthorisationTrackingIdToReverse bigint,
	@DirectPaymentReferenceIdToReverse bigint,
	@Amount int,
	@DestinationQueue varchar(4),
	@TransmissionCount Tinyint,
	-- Returns the time that the message was sent
	@SentTimeStamp datetimeoffset(7) output,
	-- Returns the GUID of the conversation that the message was sent on
	@ConversationHandle uniqueidentifier output

AS
	--Do some arguement validation
	IF @DestinationQueue NOT IN ('Idra', 'Se', 'Dre')
	BEGIN
		RAISERROR('%s is not a valid queue', 16, 2, @DestinationQueue);
	END
	IF (@AuthorisationTrackingIdToReverse IS NULL AND @DirectPaymentReferenceIdToReverse IS NULL)
	BEGIN
		RAISERROR('AuthorisationTrackingIdToReverse and DirectPaymentReferenceIdToReverse are NULL is not a valid request', 16, 2);
	END	
			

	DECLARE @Message XML([http://tfl.gov.uk/Ft/Pare/Authorisation/Schema/AuthorisationReversal/Request/v1]);

	EXEC [dbo].[CreateAuthorisationReversalRequest]
		@AuthorisationTrackingId,
		@AuthorisationTrackingIdToReverse,
		@DirectPaymentReferenceIdToReverse,
		@Amount,
		@TransmissionCount,
		@Message = @Message OUTPUT;

	--Send the message
	SET @SentTimeStamp = SYSDATETIMEOFFSET();

	DECLARE @FromService SYSNAME = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Service/' + @DestinationQueue + '/Pare';
	DECLARE @ToService SYSNAME = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Service/' + @DestinationQueue + '/Pcs';;
	DECLARE @Contract SYSNAME = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Contract/Pare';
	DECLARE @MessageType SYSNAME = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Message/AuthorisationReversal/Request';

	EXEC [dbo].[SsbSendOnConversation]	
		@FromService,
		@ToService,
		@Contract,
		@MessageType,
		@Message,
		@ConversationHandle = @ConversationHandle output;
RETURN 0

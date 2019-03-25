CREATE PROCEDURE [dbo].[SendAuthorisationRequest]
	@AuthorisationTrackingId bigint,
	@PaymentCardType varchar(10),
	@PaymentCardTransactionType varchar(100),
	@TransactionDateTime datetimeoffset,
	@Token varchar(26),
	@PaymentCardExpiryDate char(4), 
	@PaymentCardSequenceNumber varchar(3),
	@Amount int, 
	@PaymentCardApplicationTransactionCounter int,
	@MerchantId varchar(20),
	@MagStripeCard bit,
	@ApplicationId varchar(16),
	@DestinationQueue varchar(4),
	@TransmissionCount TinyInt,
	@TapTimestamp datetimeoffset(7),
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

	DECLARE @Message XML([http://tfl.gov.uk/Ft/Pare/Authorisation/Schema/Authorisation/Request/v1]);

	EXEC [dbo].[CreateAuthorisationRequest]
		@AuthorisationTrackingId,
		@PaymentCardType,
		@PaymentCardTransactionType,
		@TransactionDateTime,
		@Token,
		@PaymentCardExpiryDate,
		@PaymentCardSequenceNumber,
		@Amount,
		@PaymentCardApplicationTransactionCounter,
		@MerchantId,
		@MagStripeCard,
		@ApplicationId,		
		@TransmissionCount,
		@TapTimestamp,
		@Message = @Message OUTPUT;

	--Send the message
	SET @SentTimeStamp = SYSDATETIMEOFFSET();

	DECLARE @FromService SYSNAME = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Service/' + @DestinationQueue + '/Pare';
	DECLARE @ToService SYSNAME = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Service/' + @DestinationQueue + '/Pcs';;
	DECLARE @Contract SYSNAME = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Contract/Pare';
	DECLARE @MessageType SYSNAME = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Message/Authorisation/Request';

	EXEC [dbo].[SsbSendOnConversation]	
		@FromService,
		@ToService,
		@Contract,
		@MessageType,
		@Message,
		@ConversationHandle = @ConversationHandle output;
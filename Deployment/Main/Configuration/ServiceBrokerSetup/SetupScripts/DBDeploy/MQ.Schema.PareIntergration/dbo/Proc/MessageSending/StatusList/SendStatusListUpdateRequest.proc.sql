-- See http://tfl.gov.uk/Ft/Pare/StatusList/Message/StatusListUpdate/Request/* for more
-- details of what's allowed in this messsage

CREATE PROCEDURE [dbo].[SendStatusListUpdateRequest]
	@StatusListInstructionId bigint,
	-- Should be 'Update' or 'Correction'
	@StatusListInstructionType varchar(10),
	@Token varchar(26),
	@PaymentCardExpiryDate char(4), 
	@PaymentCardSequenceNumber varchar(3),
	@IssuerDeniedStatusId tinyint,
	-- If IssuerDeniedStatusId is 0 Then this must be null
	@IssuerDeniedTimestamp DATETIMEOFFSET,
	@IslandDeniedStatusId tinyint,
	-- If IslandDeniedStatusId is 0 Then this must be null
	@IslandDeniedTimestamp DATETIMEOFFSET,
	-- Returns the time that the message was sent
	@SentTimeStamp DATETIMEOFFSET output,
	-- Returns the GUID of the conversation that the message was sent on
	@ConversationHandle uniqueidentifier output
AS
	

	--Check that the fields supplied make sense
	IF @IssuerDeniedStatusId = 0 AND @IssuerDeniedTimestamp IS NOT NULL
	BEGIN
		RAISERROR('IssuerDeniedTimestamp must be null if IssuerDeniedStatusId is 0', 16, 2);
	END

	IF @IssuerDeniedStatusId <> 0 AND @IssuerDeniedTimestamp IS NULL
	BEGIN
		RAISERROR('IssuerDeniedTimestamp cannot be null if IssuerDeniedStatusId is not 0', 16, 2);
	END

	IF @IslandDeniedStatusId = 0 AND @IslandDeniedTimestamp IS NOT NULL
	BEGIN
		RAISERROR('IslandDeniedTimestamp must be null if IslandDeniedStatusId is 0', 16, 1);
	END

	IF @IslandDeniedStatusId <> 0 AND @IslandDeniedTimestamp IS NULL
	BEGIN
		RAISERROR('IslandDeniedTimestamp must be null if IslandDeniedStatusId is 0', 16, 1);
	END

	--Create the message. By typing the variable we force a schema validation
	DECLARE @Message xml([dbo].[http://tfl.gov.uk/Ft/Pare/StatusList/Schema/StatusListUpdate/Request/v0.1]);

	EXEC [dbo].[CreateStatusListUpdateRequest]
		@StatusListInstructionId,
		@StatusListInstructionType,
		@Token,
		@PaymentCardExpiryDate,
		@PaymentCardSequenceNumber,
		@IssuerDeniedStatusId,
		@IssuerDeniedTimestamp,
		@IslandDeniedStatusId,
		@IslandDeniedTimestamp,
		@Message = @Message output;

	--Send the message
	SET @SentTimeStamp = SYSDATETIMEOFFSET();
	EXEC [dbo].[SsbSendOnConversation]
		[http://tfl.gov.uk/Ft/Pare/StatusList/Service/Pare],
		[http://tfl.gov.uk/Ft/Pare/StatusList/Service/Pcs],
		[http://tfl.gov.uk/Ft/Pare/StatusList/Contract/Pare],
		[http://tfl.gov.uk/Ft/Pare/StatusList/Message/StatusListUpdate/Request],
		@Message,
		@ConversationHandle = @ConversationHandle output;

RETURN 0
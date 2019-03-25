CREATE PROCEDURE [dbo].[CreateAuthorisationRequest]
	@AuthorisationTrackingId bigint,
	@PaymentCardType varchar(10),
	@PaymentCardTransactionType varchar(100),
	@TransactionDateTime datetimeoffset,
	@Token varchar(26),
	@PaymentCardExpiryDate char(4), 
	@PaymentCardSequenceNumber varchar(3),
	@Amount int, 
	@PaymentCardApplicationTransactionCounter int, -- possiblynot the best way to do this
	@MerchantId varchar(20),
	@MagStripeCard bit,
	@ApplicationId varchar(16),
	@TransmissionCount TinyInt,
	@TapTimestamp datetimeoffset(7),
	@Message xml output
AS

	declare @PaymentCardExpiryDatePadded varchar(4);
	set @PaymentCardExpiryDatePadded = @PaymentCardExpiryDate;

	WHILE LEN(@PaymentCardExpiryDatePadded) < 4
	BEGIN
		SET @PaymentCardExpiryDatePadded = '0' + @PaymentCardExpiryDatePadded;
	END

	SET @Message = (
		SELECT
			@AuthorisationTrackingId as 'AuthorisationTrackingId',
			@TransmissionCount as 'TransmissionCount',
			@PaymentCardTransactionType as 'PaymentCardTransactionType',
			@TransactionDateTime as 'TransactionDateTime',
			@Token as 'Token',
			@PaymentCardExpiryDatePadded as 'PaymentCardExpiryDate',
			@PaymentCardSequenceNumber as 'PaymentCardSequenceNumber',
			@Amount as 'Amount',
			LOWER(CONVERT(varchar(MAX), convert(varbinary(2), @PaymentCardApplicationTransactionCounter), 2)) as 'PaymentCardApplicationTransactionCounter', -- varbinary(2) truncates hex for values larger than 65535
			@TapTimestamp as 'TapTimestamp',
			@MerchantId as 'MerchantId',
			@PaymentCardType as 'ContextInformation/PaymentCardType',
			@MagStripeCard as 'ContextInformation/MSDCard',
			@ApplicationId as 'ContextInformation/ApplicationId'		
			FOR XML PATH(''), ROOT('AuthorisationRequest'), elements xsinil
	);

RETURN 0
CREATE PROCEDURE [dbo].[CreateAuthorisationReversalRequest]
	@AuthorisationTrackingId bigint, 
	@AuthorisationTrackingIdToReverse bigint,
	@DirectPaymentReferenceIdToReverse bigint,
	@Amount int,
	@TransmissionCount TinyInt,
	@Message xml output
AS
	IF @AuthorisationTrackingIdToReverse IS NOT NULL 
	BEGIN
		SET @Message = (
			SELECT
				@AuthorisationTrackingId as 'AuthorisationTrackingId',
				@TransmissionCount as 'TransmissionCount',  
				@AuthorisationTrackingIdToReverse as 'AuthorisationToReverse/AuthorisationTrackingIdToReverse',
				@Amount as 'Amount'
				FOR XML PATH(''), ROOT('AuthorisationReversalRequest')
		);
	END
	ELSE IF @DirectPaymentReferenceIdToReverse IS NOT NULL
	BEGIN
		SET @Message = (
			SELECT
				@AuthorisationTrackingId as 'AuthorisationTrackingId',
				@TransmissionCount as 'TransmissionCount',
				@DirectPaymentReferenceIdToReverse as 'AuthorisationToReverse/DirectPaymentReferenceIdToReverse',
				@Amount as 'Amount'
				FOR XML PATH(''), ROOT('AuthorisationReversalRequest')
		); 
	END

RETURN 0

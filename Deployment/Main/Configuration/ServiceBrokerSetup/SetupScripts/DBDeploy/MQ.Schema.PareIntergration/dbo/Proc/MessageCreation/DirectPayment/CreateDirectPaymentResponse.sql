CREATE PROCEDURE [dbo].[CreateDirectPaymentResponse]
	@DirectPaymentReferenceId bigint,
	@Received datetimeoffset,
	@Result varchar(8),
	@ErrorDescription varchar(100),
	@Message XML output
AS
	SET @Message = (
		SELECT
			@DirectPaymentReferenceId as 'DirectPaymentReferenceId',
			[dbo].[ConvertLocalDateIntoUtcXmlDateTime](@Received) as 'Received',
			@Result as 'Result',
			@ErrorDescription as 'ErrorDescription'
		FOR XML PATH(''), ROOT('DirectPaymentConfirmationResponse'), elements xsinil
	);
RETURN 0

CREATE PROCEDURE [dbo].[CreateStatusListUpdateRequest]
	@StatusListInstructionId bigint,
	@StatusListInstructionType varchar(10),
	@Token varchar(26),
	@PaymentCardExpiryDate char(4), 
	@PaymentCardSequenceNumber varchar(3),
	@IssuerDeniedStatusId tinyint,
	@IssuerDeniedTimestamp datetimeoffset,
	@IslandDeniedStatusId tinyint,
	@IslandDeniedTimestamp datetimeoffset,
	@Message xml output
AS
	SET @Message = (
		SELECT
			@StatusListInstructionId as 'StatusListInstructionId',
			@StatusListInstructionType as 'StatusListInstructionType',
			@Token as 'Token',
			@PaymentCardExpiryDate as 'PaymentCardExpiryDate',
			@PaymentCardSequenceNumber as 'PaymentCardSequenceNumber',
			@IssuerDeniedStatusId as 'IssuerDeniedStatusId',
			@IssuerDeniedTimestamp as 'IssuerDeniedTimestamp',
			@IslandDeniedStatusId as 'IslandDeniedStatusId',
			@IslandDeniedTimestamp as 'IslandDeniedTimestamp'
		FOR XML PATH(''), ROOT('StatusListUpdateRequest'), elements xsinil
	);

RETURN 0
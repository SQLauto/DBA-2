Create PROCEDURE [dbo].[AccountVerification_UpdateAuthorisationLog]
	@body varbinary(MAX),
	@messageType sysname
AS
	SET NOCOUNT ON
				
	BEGIN TRY
		
		DECLARE @MessageBody XML = CAST (@body as XML);
		DECLARE @ErrorDescription varchar(100) = null;
		DECLARE @ErrorCode smallint = null;
		DECLARE @ResponseCode varchar(3) = null;
		DECLARE @AuthorisationCode varchar(6) = null;
		DECLARE @TraceId varchar(19) = null;
		DECLARE @AuthorisationTrackingId bigint = null;
		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;
		DECLARE @TransmissionCount tinyint;

		--Try if Message is Valid. If yes, update result summary and raise exception so that message cud be logged as invalid message
		EXEC [dbo].[LogMessage] @messageType, @MessageBody -- Log the message on requirement
		
		BEGIN TRY
			
			--check if message has required fields. If not then Add to result summary and and add to invalid message
			IF  @MessageBody.exist('(/AccountVerificationResponse/AuthorisationTrackingId)') = 1		
			BEGIN
				SET @AuthorisationTrackingId = @MessageBody.value('(/AccountVerificationResponse/AuthorisationTrackingId)[1]', 'bigint');
			END
			ELSE
			BEGIN
				RAISERROR('AuthorisationTrackingId not provided',16,1);
			END

			IF  @MessageBody.exist('(/AccountVerificationResponse/TransmissionCount)') = 1		
			BEGIN
				SET @TransmissionCount = @MessageBody.value('(/AccountVerificationResponse/TransmissionCount)[1]', 'tinyint');
			END
			ELSE
			BEGIN
				RAISERROR('TransmissionCount not provided',16,1);
			END

			IF @MessageBody.exist('(/AccountVerificationResponse/AcquirerResponse)') = 1
			BEGIN
				SET @ResponseCode = @MessageBody.value('(/AccountVerificationResponse/AcquirerResponse/ResponseCode)[1]', 'varchar(3)');
				SET @AuthorisationCode = @MessageBody.value('(/AccountVerificationResponse/AcquirerResponse/AuthorisationCode)[1]', 'varchar(6)');							
				SET @TraceId = @MessageBody.value('(/AccountVerificationResponse/AcquirerResponse/TraceId)[1]', 'varchar(19)');							
			END
			ELSE IF @MessageBody.exist('(/AccountVerificationResponse/Error)') = 1
			BEGIN
				SET @ErrorCode = @MessageBody.value('(/AccountVerificationResponse/Error/ErrorCode)[1]', 'smallint');
				SET @ErrorDescription = @MessageBody.value('(/AccountVerificationResponse/Error/ErrorDescription)[1]', 'varchar(100)');
			END
			ELSE
			BEGIN
				RAISERROR('Neither AcquirerResponse nor Error info has been provided',16,1);
			END

		END TRY
		BEGIN CATCH

				exec [Authorisation_ResultSummaryUpdate] 10 /*Invalid response message format */

				--RAISE ERROR
				SELECT 
					@ErrorMessage = ERROR_MESSAGE(),
					@ErrorSeverity = ERROR_SEVERITY(),
					@ErrorState = ERROR_STATE();

				RAISERROR (@ErrorMessage, -- Message text.
							@ErrorSeverity, -- Severity.
							@ErrorState -- State.
							);
		END CATCH

		--The called stored proc is defined in Pare.Database db proj
		exec  [dbo].[Authorisation_ResponseHandler] 
			@AuthorisationTrackingId = @AuthorisationTrackingId,
			@TransmissionCount = @TransmissionCount,
			@ResponseCode = @ResponseCode,
			@AuthorisationCode  = @AuthorisationCode,
			@ErrorCode = @ErrorCode,
			@ErrorMessage = @ErrorDescription,
			@TraceId = @TraceId

	END TRY
	BEGIN CATCH

		PRINT 'FAILED'		
		SELECT 
			@ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();

		--insert message in InvalidMessage table
		exec Authorisation_AddInvalidMessage @messageType, @body, @ErrorMessage

		Return 0;

	END CATCH;

Create PROCEDURE [dbo].[AuthorisationReversal_UpdateAuthorisationLog]
	@body varbinary(MAX),
	@messageType sysname
AS
	SET NOCOUNT ON
				
	BEGIN TRY
		DECLARE @MessageBody XML = CAST (@body as XML);		
		DECLARE @ResponseCode varchar(3) = null;
		DECLARE @ErrorCode smallint = null;
		DECLARE @ErrorDescription varchar(100) = null;
		DECLARE @AuthorisationTrackingId bigint = null;
		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;
		DECLARE @TransmissionCount TINYINT;
		EXEC [dbo].[LogMessage] @messageType, @MessageBody -- Log the message on requirement
		BEGIN TRY
			--check if message has required fields. If not then Add to result summary and and add to invalid message
			IF  @MessageBody.exist('(/AuthorisationReversalResponse/AuthorisationTrackingId)') = 1		
			BEGIN
				SET @AuthorisationTrackingId = @MessageBody.value('(/AuthorisationReversalResponse/AuthorisationTrackingId)[1]', 'bigint');
			END
			ELSE
			BEGIN
				RAISERROR('AuthorisationTrackingId not provided',16,1);
			END
			IF  @MessageBody.exist('(/AuthorisationReversalResponse/TransmissionCount)') = 1		
			BEGIN
				SET @TransmissionCount = @MessageBody.value('(/AuthorisationReversalResponse/TransmissionCount)[1]', 'tinyint');
			END
			ELSE
			BEGIN
				RAISERROR('TransmissionCount not provided',16,1);
			END

			IF @MessageBody.exist('(/AuthorisationReversalResponse/AcquirerResponse)') = 1
			BEGIN
				SET @ResponseCode = @MessageBody.value('(/AuthorisationReversalResponse/AcquirerResponse/ResponseCode)[1]', 'varchar(3)');
			END
			ELSE IF @MessageBody.exist('(/AuthorisationReversalResponse/Error)') = 1
			BEGIN
				SET @ErrorCode = @MessageBody.value('(/AuthorisationReversalResponse/Error/ErrorCode)[1]', 'smallint');
				SET @ErrorDescription = @MessageBody.value('(/AuthorisationReversalResponse/Error/ErrorDescription)[1]', 'varchar(100)');			
			END
			ELSE
			BEGIN
				RAISERROR('Niether AcquirerResponse nor Error info has been provided',16,1);
			END

			
		END TRY
		BEGIN CATCH
			exec [Authorisation_ResultSummaryUpdate] 10
				
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
		exec [dbo].[Authorisation_ResponseHandler] @AuthorisationTrackingId,@TransmissionCount, @ResponseCode, null,@ErrorCode,@ErrorDescription


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
GO


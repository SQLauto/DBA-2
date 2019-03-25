CREATE PROCEDURE [dbo].[Authorisation_UpdateAuthorisationLog]
	@body varbinary(MAX),
	@messageType sysname
AS
	SET NOCOUNT ON
				
	BEGIN TRY
		DECLARE @MessageBody XML = CAST (@body as XML);
		DECLARE @ResponseCode varchar(3) = null;
		DECLARE @AuthorisationCode varchar(6) = null;
		DECLARE @ProductCode varchar(3) = null;
		DECLARE @TraceId varchar(19) = null;
		DECLARE @PanToken varchar(26) = null;
		DECLARE @ErrorCode smallint = null;
		DECLARE @ErrorDescription varchar(100) = null;
		DECLARE @AuthorisationTrackingId bigint = null;
		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;
		DECLARE @TransmissonCount TinyInt;

		EXEC [dbo].[LogMessage] @messageType, @MessageBody -- Log the message on requirement
		BEGIN TRY
			--check if message has required fields. If not then Add to result summary and and add to invalid message
			IF  @MessageBody.exist('(/AuthorisationResponse/AuthorisationTrackingId)') = 1		
			BEGIN
				SET @AuthorisationTrackingId = @MessageBody.value('(/AuthorisationResponse/AuthorisationTrackingId)[1]', 'bigint');
			END
			ELSE
			BEGIN
				RAISERROR('AuthorisationTrackingId not provided',16,1);
			END
		    IF  @MessageBody.exist('(/AuthorisationResponse/TransmissionCount)') = 1		
			BEGIN
				SET @TransmissonCount = @MessageBody.value('(/AuthorisationResponse/TransmissionCount)[1]', 'tinyint');
			END
			ELSE
			BEGIN
				RAISERROR('TransmissionCount not provided',16,1);
			END
			
			IF @MessageBody.exist('(/AuthorisationResponse/AcquirerResponse)') = 1
			BEGIN				
				SET @ResponseCode = @MessageBody.value('(/AuthorisationResponse/AcquirerResponse/ResponseCode)[1]', 'varchar(3)');
				SET @AuthorisationCode = @MessageBody.value('(/AuthorisationResponse/AcquirerResponse/AuthorisationCode)[1]', 'varchar(6)');
				-- We are assuming this passed as <ProductCode xsi:nil="true"/> NOT <ProductCode></ProductCode> as the empty element should fail schema validation.
				SET @ProductCode = 
					CASE WHEN @MessageBody.exist('(/AuthorisationResponse/AcquirerResponse/ProductCode[@xsi:nil eq ''true''])') = 1
					THEN
						NULL
					ELSE
						@MessageBody.value('(/AuthorisationResponse/AcquirerResponse/ProductCode)[1]', 'varchar(3)')
					END;						
				SET @TraceId = @MessageBody.value('(/AuthorisationResponse/AcquirerResponse/TraceId)[1]', 'varchar(19)');
		
				-- We are assuming this passed as <PanToken xsi:nil="true"/> NOT <PanToken></PanToken> as the empty element should fail schema validation.
				SET @PanToken = 
					CASE WHEN @MessageBody.exist('(/AuthorisationResponse/AcquirerResponse/PanToken[@xsi:nil eq ''true''])') = 1
					THEN
						NULL
					ELSE
						@MessageBody.value('(/AuthorisationResponse/AcquirerResponse/PanToken)[1]', 'varchar(26)')
					END;
			END
			ELSE IF @MessageBody.exist('(/AuthorisationResponse/Error)') = 1
			BEGIN
				SET @ErrorCode = @MessageBody.value('(/AuthorisationResponse/Error/ErrorCode)[1]', 'smallint');
				SET @ErrorDescription = @MessageBody.value('(/AuthorisationResponse/Error/ErrorDescription)[1]', 'varchar(100)');
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
		exec [dbo].[Authorisation_ResponseHandler] @AuthorisationTrackingId,@TransmissonCount, @ResponseCode, @AuthorisationCode ,@ErrorCode,@ErrorDescription,@PanToken,@ProductCode,@TraceId		
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

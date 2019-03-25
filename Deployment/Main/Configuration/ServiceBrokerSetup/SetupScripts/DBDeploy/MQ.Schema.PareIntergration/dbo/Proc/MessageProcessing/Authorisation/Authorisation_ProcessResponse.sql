CREATE PROCEDURE [dbo].[Authorisation_ProcessResponse]
	@handle uniqueidentifier,
	@messageType sysname,
	@body varbinary(MAX)
AS
	BEGIN
		BEGIN TRY
			----------------------------------------
			-- Main case
			----------------------------------------
			IF @messageType = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Message/Authorisation/Response'
			BEGIN
				EXEC [dbo].[Authorisation_UpdateAuthorisationLog] @body, @messageType;
			END
			ELSE IF @messageType = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Message/AccountVerification/Response'
			BEGIN
				EXEC [dbo].[AccountVerification_UpdateAuthorisationLog] @body, @messageType;
			END
			ELSE IF @messageType = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Message/AuthorisationReversal/Response'
			BEGIN
				EXEC [dbo].[AuthorisationReversal_UpdateAuthorisationLog] @body, @messageType;
			END
			ELSE IF @messageType = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Message/Heartbeat/Response'
			BEGIN
				EXEC [dbo].[Authorisation_UpdateHeartbeat] @body, @messageType;
			END
						
			----------------------------------------
			-- All the other message types that we need to deal with
			----------------------------------------
			ELSE IF @messageType = 'http://schemas.microsoft.com/SQL/ServiceBroker/Error'
			BEGIN
				END CONVERSATION @handle;
			END
			ELSE IF @messageType = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer'
			BEGIN
				END CONVERSATION @handle;
			END
			ELSE IF @messageType = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
			BEGIN
				END CONVERSATION @handle;
			END
			ELSE
			BEGIN				
				--Unknown message type, hence add this to Invalid Message
				exec Authorisation_AddInvalidMessage @messageType, @body, 'Unknown message type';
				RETURN 0;
			END

		END TRY
		BEGIN CATCH

			IF (dbo.IsTransientError(ERROR_NUMBER()) = 1)
			BEGIN
				PRINT 'Throwing retryable error: ' + ERROR_MESSAGE();
				THROW;
			END
			
			PRINT 'Adding InvalidMessage';
			DECLARE @error_Message NVARCHAR(1);
			SET @error_Message = 'Dropping message, Error is: ' + ERROR_MESSAGE();
			EXEC Authorisation_AddInvalidMessage @messageType, @body, @error_Message;
			RETURN 0;

		END CATCH;
	END


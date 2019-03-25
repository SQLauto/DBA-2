CREATE PROCEDURE [dbo].[Authorisation_UpdateHeartbeat]
	@body varbinary(MAX),
	@messageType sysname
AS
	SET NOCOUNT ON
				
	BEGIN TRY
		DECLARE @MessageBody XML = CAST (@body as XML);
		
		DECLARE @HeartbeatId BIGINT;
		DECLARE @SentDateTime DATETIMEOFFSET;
		DECLARE @RequestSentDateTime DATETIMEOFFSET;

		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;
		EXEC [dbo].[LogMessage] @messageType, @MessageBody -- Log the message on requirement
		--check if message has required fields. If not then add to invalid message
		IF  @MessageBody.exist('(/HeartbeatResponse/HeartbeatId)') = 1 AND @MessageBody.value('(/HeartbeatResponse/HeartbeatId)[1]', 'varchar') <> ''
		BEGIN
			SET @HeartbeatId = @MessageBody.value('(/HeartbeatResponse/HeartbeatId)[1]', 'bigint');
		END
		ELSE
		BEGIN
			RAISERROR('HeartbeatId not provided',16,1);
		END
		IF  @MessageBody.exist('(/HeartbeatResponse/SentDateTime)') = 1 AND @MessageBody.value('(/HeartbeatResponse/SentDateTime)[1]', 'varchar') <> ''
		BEGIN
			SET @SentDateTime = @MessageBody.value('(/HeartbeatResponse/SentDateTime)[1]', 'datetimeoffset');
		END
		ELSE
		BEGIN
			RAISERROR('SentDateTime not provided',16,1);
		END
		IF  @MessageBody.exist('(/HeartbeatResponse/RequestSentDateTime)') = 1 AND @MessageBody.value('(/HeartbeatResponse/RequestSentDateTime)[1]', 'varchar') <> ''
		BEGIN
			SET @RequestSentDateTime = @MessageBody.value('(/HeartbeatResponse/RequestSentDateTime)[1]', 'datetimeoffset');
		END
		ELSE
		BEGIN
			RAISERROR('RequestSentDateTime not provided',16,1);
		END

		--The called stored proc is defined in Pare.Database db proj			
		exec [dbo].[Authorisation_HeartbeatResponseHandler] @HeartbeatId, @SentDateTime, @RequestSentDateTime;
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

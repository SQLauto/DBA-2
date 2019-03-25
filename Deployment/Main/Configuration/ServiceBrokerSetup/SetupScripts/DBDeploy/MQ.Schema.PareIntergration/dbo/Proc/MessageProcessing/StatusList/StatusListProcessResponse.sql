CREATE PROCEDURE [dbo].[StatusListProcessResponse]
	@handle uniqueidentifier,
	@messageType sysname,
	@body varbinary(MAX)
AS
BEGIN
	--Processes two different Message types
	-- 1) StatusListUpdateResponseV1.xsd
	-- 2) StatusListDeltaDistributionConfirmationV0.4.xsd
	DECLARE @ErrorMessage varchar(max);		
	BEGIN
		BEGIN TRY
			DECLARE @ConversationHandle UNIQUEIDENTIFIER;
			DECLARE @Message XML;
			DECLARE @SendDate DATETIMEOFFSET = SYSDATETIMEOFFSET();			
			DECLARE @MessageBody XML = CAST (@body as XML);
			DECLARE @SQL varchar(4000)

			-- Log the message
			EXEC [dbo].[LogMessage] @messageType, @MessageBody

			----------------------------------------
			-- Main case 
			----------------------------------------
			IF @messageType = 'http://tfl.gov.uk/Ft/Pare/StatusList/Message/StatusListUpdate/Response'
			BEGIN			        
				--Decode the message and extract what we need
				DECLARE @StatusListInstructionId bigint;
				DECLARE @Received DateTimeoffset;
				DECLARE @Result Varchar(8);
				DECLARE @ErrorDescription varchar(100);				
				BEGIN TRY
					set @StatusListInstructionId = @MessageBody.value('(/StatusListUpdateResponse/StatusListInstructionId)[1]', 'bigint' );
					set @Received = @MessageBody.value('(/StatusListUpdateResponse/Received)[1]', 'datetimeoffset' );
					set @Result = @MessageBody.value('(/StatusListUpdateResponse/Result)[1]', 'varchar(8)' );
					set @ErrorDescription = @MessageBody.value('(/StatusListUpdateResponse/ErrorDescription)[1]', 'varchar(100)' );						 
				END TRY
				BEGIN CATCH
					SET @ErrorDescription = 'Response message is not correctly formed'
					Exec StatusListUpdateStatus @StatusListInstructionId,8,@ErrorDescription,@Received						
					RETURN 0;
				END CATCH;

				IF @Result = 'Accepted'
				BEGIN											
					Exec StatusListUpdateStatus @StatusListInstructionId,3,@ErrorDescription,@Received
				END						
				ELSE IF @Result = 'Rejected'
				BEGIN						
					Exec StatusListUpdateStatus @StatusListInstructionId,6,@ErrorDescription,@Received
				END
				ELSE IF @Result = 'Failed'
				BEGIN
					Exec StatusListUpdateStatus @StatusListInstructionId,9,@ErrorDescription,@Received
				END
			END
			
			----------------------------------------
			-- Delta Distribution
			----------------------------------------
			ELSE IF @messageType = 'http://tfl.gov.uk/Ft/Pare/StatusList/Message/StatusListUpdate/DeltaDistributionConfirmation'
			BEGIN
				--Decode the message and extract what we need
				DECLARE @StatusListVersionNumber BIGINT;
				DECLARE @Distributed DATETIMEOFFSET;
				DECLARE @InvalidRangesCount INT;

				--Create temp table to store Id Ranges
				CREATE TABLE #StatusListDistribution
				(
					[StatusListInstructionIdMinInclusive] [bigint] NOT NULL,
					[StatusListInstructionIdMaxInclusive] [bigint] NOT NULL
				)

				SET @StatusListVersionNumber = @MessageBody.value('(/StatusListDeltaDistributionConfirmation/StatusListVersionNumber)[1]', 'bigint')
				SET @Distributed = @MessageBody.value('(/StatusListDeltaDistributionConfirmation/Distributed)[1]', 'datetimeoffset')

				-- build list of instruction id range
				INSERT INTO #StatusListDistribution
				SELECT 
					T.c.value('(./StatusListInstructionIdMinInclusive)[1]','bigint'),
					T.c.value('(./StatusListInstructionIdMaxInclusive)[1]','bigint')
				FROM @MessageBody.nodes('(/StatusListDeltaDistributionConfirmation/StatusListInstructionIdRange)') T(c)

				SELECT @InvalidRangesCount = COUNT(*)
				FROM #StatusListDistribution sld
				WHERE sld.StatusListInstructionIdMaxInclusive < sld.StatusListInstructionIdMinInclusive

				IF @InvalidRangesCount = 0
				BEGIN
					DECLARE @created datetimeoffset

					SELECT  @created=CAST(ArchivetoLiveSwitchOverPartitionKeyValue as datetimeoffset)
					FROM internal.PartitionConfig
					WHERE name='StatusListInstruction'
					-- process message
					SET @SQL='UPDATE sli
					SET
						sli.[Distributed] = '''+CAST(@Distributed as varchar(100))+''',
						sli.StatusListVersionNumber = '+CAST(@StatusListVersionNumber as varchar(10))+'
					FROM StatusListInstruction sli
					INNER JOIN #StatusListDistribution sld
						ON sli.Id BETWEEN sld.StatusListInstructionIdMinInclusive AND sld.StatusListInstructionIdMaxInclusive
						WHERE sli.created>'''+CAST(@created as varchar(100))+''''
					EXEC(@SQL)
				END
				ELSE
				BEGIN
					-- add message to invalid message table
					EXEC StatusList_AddInvalidMessage @messageType, @body, 'Failed StatusListInstructionIdRange validation'
				END
				-- drop temp table
				DROP TABLE #StatusListDistribution
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
				--	'I don''t know what to do with this type of message. Dropping message';
				Exec StatuslistUpdateStatus @StatusListInstructionId,8,@ErrorDescription,@Received
				RETURN 0;
			END			
		END TRY
		BEGIN CATCH			
		IF (dbo.IsTransientError(ERROR_NUMBER()) = 1)
		BEGIN
			PRINT 'Throwing retryable error: ' + ERROR_MESSAGE();
			THROW;
		END			
			SET @ErrorMessage = 'Dropping message, Error is: ' + ERROR_MESSAGE();
			EXEC StatusList_AddInvalidMessage @messageType, @body, @ErrorMessage
			RETURN 0;
		END CATCH;
	END
END
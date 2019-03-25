CREATE PROCEDURE [dbo].[Authorisation_SendPendingAuthorisations]
    @SendCount int=300,
    @SendItemDelay char(12)='00:00:00:000',
    @CountOfAuthsSent int OUTPUT
AS
    /*
        Send Authorisations to PCS:
        1) Fetch top @SendCount Pending AuthorisationLog records
        2) Open Cursor and determine correct queue for request
        3) Send the row to the service broker queue (child sproc creates request)
        NOTE: Step 3 is a single transaction (per row) which may result in a performance hit.
        This is due to a limitation with Service Broker which has no 'bulk' mode, 
        i.e. can't send all request to SSB in one go    
        --verified with RN: 13/03/12      
    */
BEGIN      
    DECLARE @AuthorisationTrackingId bigint
    DECLARE @MessageQueueName varchar(4)
    DECLARE @MessageQueueId tinyint
    DECLARE @PaymentCardType varchar(10)
    DECLARE @PaymentCardTransactionType varchar(100)
    DECLARE @TransactionDateTime datetimeoffset
    DECLARE @Token varchar(26)
    DECLARE @PaymentCardExpiryDate char(4)
    declare @PaymentCardSequenceNumber varchar(3)
    DECLARE @Amount int
    DECLARE @PaymentCardApplicationTransactionCounter int
    DECLARE @MerchantId varchar(20)
    DECLARE @MagStripeCard bit
    DECLARE @ApplicationId varchar(16)
    DECLARE @AuthorisationTrackingIdToReverse bigint
    DECLARE @DirectPaymentReferenceIdToReverse bigint
    DECLARE @RetryCount tinyint
    DECLARE @TapTimestamp datetimeoffset(7)
    --set up some reference data
    DECLARE @Status_Pending tinyint=1
    DECLARE @Status_Sent tinyint=2
    DECLARE @Status_Failed tinyint=4
    DECLARE @TravelDay smallint
    DECLARE @TransmissionCount TinyInt
    DECLARE @SQL varchar(4000)
       
    CREATE TABLE #SentAuthorisations (Id BIGINT NOT NULL, RetryCount tinyint, SendTimeStamp datetimeoffset(7), MessageQueueId TINYINT NOT NULL, TravelDay SMALLINT NOT NULL);

	CREATE CLUSTERED INDEX IX_SentAuthorisations  ON #SentAuthorisations(Id)  

    --select the data required to build an Authorisation request
    DECLARE AuthorisationCursor CURSOR FAST_FORWARD FOR
        SELECT TOP(@SendCount)      
            AuthorisationTrackingId,
            MessageQueueName,
            PaymentCardType,
            PaymentCardTransactionType,              
            TransactionDateTime,
            Token,
            PaymentCardExpiryDate,
            PaymentCardSequenceNumber,
            Amount,
            PaymentCardApplicationTransactionCounter, 
            MerchantId,
            MagStripeCard, 
            ApplicationId,
            TrackingIdToReverse,
            DirectpaymentIdToReverse,
            A.RetryCount,
            TapTimestamp,
            MessageQueueId,
            TravelDay
        FROM View_PendingAuthorisations A
        WHERE A.DelaySendUntil <= SYSDATETIMEOFFSET()
                     
    OPEN AuthorisationCursor;

    BEGIN TRAN SendAndUpdateTransaction
                           
        BEGIN TRY

            FETCH NEXT FROM AuthorisationCursor INTO 
                @AuthorisationTrackingId,@MessageQueueName,@PaymentCardType,@PaymentCardTransactionType,
                @TransactionDateTime,@Token,@PaymentCardExpiryDate,@PaymentCardSequenceNumber,
                @Amount,@PaymentCardApplicationTransactionCounter,@MerchantId,@MagStripeCard,@ApplicationId,
                @AuthorisationTrackingIdToReverse,@DirectPaymentReferenceIdToReverse, @RetryCount, @TapTimestamp,
                @MessageQueueId, @TravelDay;
       
            WHILE @@FETCH_STATUS = 0
                BEGIN

                    --build request and send to correct queue
                    DECLARE @ConversationHandle uniqueidentifier;
                    DECLARE @SendTimeStamp datetimeoffset(7);
                    DECLARE @AuthorisationOriginElement varchar(25) 
                     
                    --NOTE:@RetryCount in PARE is zero based. Cubic @TransmissionCount starts @ 1 
                    SET @TransmissionCount = @RetryCount + 1

                    --Create Transaction for this process

                    IF(@PaymentCardTransactionType = 'ContactlessAccountValidityCheck' or @PaymentCardTransactionType='CardNotPresentAccountValidityCheck')
                    BEGIN
                        EXEC [dbo].[SendAccountVerification]
                            @AuthorisationTrackingId,
                            @PaymentCardType,
                            @PaymentCardTransactionType,
                            @TransactionDateTime,
                            @Token,
                            @PaymentCardExpiryDate,
                            @PaymentCardSequenceNumber,
                            @Amount,
                            @PaymentCardApplicationTransactionCounter,
                            @MerchantId,
                            @MagStripeCard,
                            @ApplicationId,
                            @MessageQueueName,
                            @TransmissionCount,
                            @TapTimestamp,
                            @SentTimeStamp = @SendTimeStamp  output,
                            @ConversationHandle = @ConversationHandle output;      
                    END
                    ELSE IF(@PaymentCardTransactionType = 'ContactlessNominalAuthorisationReversal' or @PaymentCardTransactionType = 'Reversal')
                    BEGIN
                        EXEC [dbo].[SendAuthorisationReversal]
                        @AuthorisationTrackingId,
                        @AuthorisationTrackingIdToReverse,
                        @DirectPaymentReferenceIdToReverse,
                        @Amount,
                        @MessageQueueName,
                        @TransmissionCount,
                        @SentTimeStamp = @SendTimeStamp output,
                        @ConversationHandle = @ConversationHandle output;                                                                    
                    END
                    ELSE          
                    BEGIN
                        --build and send message to the Queue
                        EXEC [dbo].[SendAuthorisationRequest]
                            @AuthorisationTrackingId,
                            @PaymentCardType,
                            @PaymentCardTransactionType,
                            @TransactionDateTime,
                            @Token,
                            @PaymentCardExpiryDate,
                            @PaymentCardSequenceNumber,
                            @Amount,
                            @PaymentCardApplicationTransactionCounter,
                            @MerchantId,
                            @MagStripeCard,
                            @ApplicationId,
                            @MessageQueueName,
                            @TransmissionCount,
                            @TapTimestamp,
                            @SentTimeStamp = @SendTimeStamp  output,
                            @ConversationHandle = @ConversationHandle output;
                    END
                     
                    INSERT INTO #SentAuthorisations(Id, RetryCount, SendTimestamp, MessageQueueId, TravelDay) 
                    VALUES (@AuthorisationTrackingId, @RetryCount, @SendTimeStamp, @MessageQueueId, @TravelDay);

                    WAITFOR DELAY @SendItemDelay;

                    FETCH NEXT FROM AuthorisationCursor INTO 
                        @AuthorisationTrackingId,@MessageQueueName,@PaymentCardType,@PaymentCardTransactionType,
                        @TransactionDateTime,@Token,@PaymentCardExpiryDate,@PaymentCardSequenceNumber,
                        @Amount,@PaymentCardApplicationTransactionCounter,@MerchantId,@MagStripeCard,@ApplicationId,
                        @AuthorisationTrackingIdToReverse,@DirectPaymentReferenceIdToReverse, @RetryCount, @TapTimestamp,
                        @MessageQueueId, @TravelDay;
  
                END

            SELECT @CountOfAuthsSent = COUNT(*) FROM #SentAuthorisations
							
			DECLARE @traveldaypartition int
		
			SELECT  @traveldaypartition=ArchivetoLiveSwitchOverPartitionKeyValue 
			FROM  internal.PartitionConfig
			WHERE name='AuthorisationLog'
                    
            SET @SQL=' UPDATE  a 
                SET AuthorisationStatusId='+cast(@Status_Sent as varchar(1))+'
                FROM AuthorisationLog a
                INNER JOIN #SentAuthorisations s on s.Id = a.Id AND a.TravelDay = s.TravelDay
                WHERE a.AuthorisationStatusId='+cast(@Status_Pending as varchar(10))+'
				AND a.travelday>='+CAST(@traveldaypartition as varchar(10))
                        						   
			EXEC (@SQL)

			DECLARE @created datetimeoffset

			SELECT  @created=CAST(ArchivetoLiveSwitchOverPartitionKeyValue as datetimeoffset)
			FROM internal.PartitionConfig
			WHERE name='AuthorisationRequest'

            SET @SQL='UPDATE AR
                SET [Sent] = '''+CAST(ISNULL(@SendTimeStamp,'') as varchar(100))+'''
                FROM AuthorisationRequest AR 
                INNER JOIN #SentAuthorisations sa on ar.AuthorisationLogId = sa.Id AND ar.retrycount = sa.retrycount 
				WHERE AR.created>='''+CAST(@created as varchar(50))+''''
                        					   
			EXEC (@SQL)

            DELETE FROM p
            FROM AuthorisationPending p
            INNER JOIN #SentAuthorisations s on s.Id = p.Id AND s.RetryCount = p.RetryCount
                    
            COMMIT Tran

        END TRY
        BEGIN CATCH
        
            ROLLBACK;
            THROW;

        END CATCH

        CLOSE AuthorisationCursor;

        DEALLOCATE AuthorisationCursor;

        BEGIN TRAN
        BEGIN TRY     
            UPDATE MessageQueueHeartbeatSummary  
            SET MessageCountSinceLastHeartbeat = MessageCountSinceLastHeartbeat + h.heartbeatCount
            FROM 
                (
                    SELECT MessageQueueId, COUNT(1) heartbeatCount
                    FROM #SentAuthorisations
                    GROUP BY MessageQueueId
                ) h 
            inner join MessageQueueHeartbeatSummary m on h.MessageQueueId = m.MessageQueueId                    

            COMMIT TRAN
        END TRY
        BEGIN CATCH
                ROLLBACK TRAN
        END CATCH

    DROP TABLE #SentAuthorisations;
END
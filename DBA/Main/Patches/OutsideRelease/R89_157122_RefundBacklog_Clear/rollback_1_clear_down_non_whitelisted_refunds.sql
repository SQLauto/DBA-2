USE [RefundManager]
GO 
BEGIN TRY
    BEGIN TRANSACTION;

	-- Update gateway.refundRequest table
	UPDATE gateway.RefundRequest 
	SET RequestSeqNo = NULL,
	Updated = SYSDATETIMEOFFSET()
	WHERE Id IN (SELECT Id FROM gateway.RefundRequest_Updated_157122);
	
	-- Update records in refund table
	UPDATE Refunds.Refund 
	SET RequestSeqNo = NULL,
	IssuedStatus = 1,
	Updated = sysdatetimeoffset()
	WHERE Id IN (SELECT Id from Refunds.Refund_Updated_157122);

	-- Add records back into the refund queue
	INSERT INTO gateway.RefundPrioritisedQueue
	SELECT * FROM gateway.RefundPrioritisedQueue_Deleted_157122;
	
	DROP TABLE gateway.RefundRequest_Updated_157122
	DROP TABLE Refunds.Refund_Updated_157122
	DROP TABLE gateway.RefundPrioritisedQueue_Deleted_157122

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
	THROW;
END CATCH

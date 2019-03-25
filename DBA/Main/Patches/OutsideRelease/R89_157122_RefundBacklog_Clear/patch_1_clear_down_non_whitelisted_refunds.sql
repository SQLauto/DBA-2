/* This should be run in VINS003 Refundmanager DB 

!!! the refund manager service needs to be stopped prior to the script being run !!!

*/

USE [RefundManager]
GO 
BEGIN TRY
    BEGIN TRANSACTION;

	-- Backup gateway.RefundRequest records that we will update
	SELECT * 
	INTO gateway.RefundRequest_Updated_157122
	FROM gateway.RefundRequest 
	WHERE RequestSeqNo IS NULL AND PrestigeId NOT IN (SELECT PrestigeId FROM gateway.Whitelist);

	-- Update gateway.refundRequest table
	UPDATE gateway.RefundRequest 
	SET RequestSeqNo = -1,
	Updated = SYSDATETIMEOFFSET()
	WHERE RequestSeqNo IS NULL AND PrestigeId NOT IN (SELECT PrestigeId FROM gateway.Whitelist);
	
	-- Backup Refunds.Refund records that we will update
	SELECT * 
	INTO Refunds.Refund_Updated_157122
	FROM Refunds.Refund
	WHERE RequestSeqNo IS NULL AND PrestigeId NOT IN (SELECT PrestigeId FROM gateway.Whitelist);

	-- Update records in refund table
	UPDATE Refunds.Refund 
	SET RequestSeqNo = -1,
	IssuedStatus = 2,
	Updated = sysdatetimeoffset()
	WHERE RequestSeqNo IS NULL AND PrestigeId NOT IN (SELECT PrestigeId FROM gateway.Whitelist);

	-- Back up refund queue records that we want to delete.
	SELECT * 
	INTO gateway.RefundPrioritisedQueue_Deleted_157122
	FROM gateway.RefundPrioritisedQueue
	WHERE RefundRequestId IN (SELECT Id FROM gateway.RefundRequest WHERE RequestSeqNo = -1);

	-- Delete records from the refund queue
	DELETE FROM gateway.RefundPrioritisedQueue
	WHERE RefundRequestId IN (SELECT Id FROM gateway.RefundRequest WHERE RequestSeqNo = -1);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
	THROW;
END CATCH

/*	
	Rolls back the creation of a new index called IX_gateway_RefundRequest_ExternalRefundId in the RefundManager db.
*/


USE [RefundManager]

-- Create second index on RefundRequest table
IF EXISTS(
			SELECT	1 
			FROM 	SYS.INDEXES IDX
			WHERE	OBJECT_NAME(OBJECT_ID) = 'RefundRequest'
					AND 
					OBJECT_SCHEMA_NAME(OBJECT_ID) = 'gateway'
					AND  
					IDX.NAME = 'IX_gateway_RefundRequest_ExternalRefundId'
		)
BEGIN
		DROP INDEX [IX_gateway_RefundRequest_ExternalRefundId] ON [gateway].[RefundRequest]
END
GO

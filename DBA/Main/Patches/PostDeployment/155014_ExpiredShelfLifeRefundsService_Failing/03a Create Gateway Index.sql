/*	
	Creates a new index called IX_gateway_RefundRequest_ExternalRefundId in the RefundManager db.
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


IF NOT EXISTS(
			SELECT	1 
			FROM 	SYS.INDEXES IDX
			WHERE	OBJECT_NAME(OBJECT_ID) = 'RefundRequest'
					AND 
					OBJECT_SCHEMA_NAME(OBJECT_ID) = 'gateway'
					AND  
					IDX.NAME = 'IX_gateway_RefundRequest_ExternalRefundId'
		)
BEGIN
	CREATE NONCLUSTERED INDEX [IX_gateway_RefundRequest_ExternalRefundId] ON [gateway].[RefundRequest]
	(
		   [ExternalRefundId] ASC
	)
	WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
END
GO

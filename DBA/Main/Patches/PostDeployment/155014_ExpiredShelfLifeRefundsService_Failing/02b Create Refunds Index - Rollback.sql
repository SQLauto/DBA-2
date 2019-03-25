/*	
	Rolls back the creation of a new index called IX_refunds_RefundAdjustmentLink_RefundId in the RefundManager db.
*/


USE [RefundManager]

-- Create first index on RefundAdjustmentLink table
IF EXISTS(
			SELECT	1 
			FROM 	SYS.INDEXES IDX
			WHERE	OBJECT_NAME(OBJECT_ID) = 'RefundAdjustmentLink'
					AND 
					OBJECT_SCHEMA_NAME(OBJECT_ID) = 'Refunds'
					AND  
					IDX.NAME = 'IX_refunds_RefundAdjustmentLink_RefundId'
		)
BEGIN
		DROP INDEX [IX_refunds_RefundAdjustmentLink_RefundId] ON [Refunds].[RefundAdjustmentLink]
END
GO

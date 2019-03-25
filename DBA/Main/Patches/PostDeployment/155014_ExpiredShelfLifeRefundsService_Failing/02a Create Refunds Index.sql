/*	
	Creates a new index called IX_refunds_RefundAdjustmentLink_RefundId in the RefundManager db.
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


IF NOT EXISTS(
			SELECT	1 
			FROM 	SYS.INDEXES IDX
			WHERE	OBJECT_NAME(OBJECT_ID) = 'RefundAdjustmentLink'
					AND 
					OBJECT_SCHEMA_NAME(OBJECT_ID) = 'Refunds'
					AND  
					IDX.NAME = 'IX_refunds_RefundAdjustmentLink_RefundId'
		)
BEGIN
	CREATE NONCLUSTERED INDEX [IX_refunds_RefundAdjustmentLink_RefundId] ON [Refunds].[RefundAdjustmentLink]
	(
		   [RefundId] ASC
	)
	INCLUDE ([OysterChargeAdjustmentId]) 
	WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
END
GO

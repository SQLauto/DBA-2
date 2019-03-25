/*
-- Run in the RefundManager database.

-- Applies a patch to sproc refunds.GetRefundReasons
-- which:
-- 1. enables the sproc to cope with arbitrary total reasons length
-- 2. makes the sproc return a row for every input prestige id, 
--    synthesizing a refund reason if necessary
*/
USE RefundManager;
GO


ALTER PROCEDURE refunds.GetRefundReasons
(
	@PrestigeIdList [Refunds].[PrestigeIdList] READONLY
)
AS
BEGIN

	-- Create a temp table to load the incoming PrestigeIds into, for performance reasons
	IF OBJECT_ID('tempdb..#PrestigeIds') IS NOT NULL
		DROP TABLE #PrestigeIds

	CREATE TABLE #PrestigeIds
	(
		PrestigeId		BIGINT NOT NULL
	)

	-- Load incoming list of PrestigeIds into temp table for performance reasons
	INSERT	INTO #PrestigeIds
			(
				PrestigeId
			)
	SELECT	DISTINCT	
			PrestigeID
	FROM	@PrestigeIdList

	-- Create an index for performance
	CREATE UNIQUE CLUSTERED INDEX IX_PrestigeIds_PrestigeId ON #PrestigeIds(PrestigeId);


	-- Create the temp table to hold a list of the Refund.Id values that will identify the most recent refund for a PrestigeId	
	IF OBJECT_ID('tempdb..#LastRefundId') IS NOT NULL
		DROP TABLE #LastRefundId

	CREATE TABLE #LastRefundId
	(
		PrestigeId		BIGINT NOT NULL,
		LastRefundId	BIGINT NULL	
	)


	-- Create the temp table to hold a list of all the OysterChargeAdjustments that will contribute to the new refunds which are in the process of being created
	IF OBJECT_ID('tempdb..#PendingOcas') IS NOT NULL
		DROP TABLE #PendingOcas

	CREATE TABLE #PendingOcas
	(
		PrestigeId					BIGINT NOT NULL,
		Id							BIGINT NULL,
		OysterChargeAdjustmentId	BIGINT NULL,
		Reasons						NVARCHAR(300) NULL
	)


	-- Create the temp table to hold a list of ALL the INDIVIDUAL reasons that have been assigned to the adjustments that will contribute to the new refund
	IF OBJECT_ID('tempdb..#PrestigeIdsAllReasons') IS NOT NULL
		DROP TABLE #PrestigeIdsAllReasons

	CREATE TABLE #PrestigeIdsAllReasons
	(
		PrestigeId BIGINT NOT NULL,
		Reason NVARCHAR(300) NULL
	)


	-- Create the temp table to hold a list of DISTINCT list of the INDIVIDUAL reasons that have been assigned to the adjustments that will contribute to the new refund
	IF OBJECT_ID('tempdb..#PrestigeIdsDistinctReason') IS NOT NULL
		DROP TABLE #PrestigeIdsDistinctReason

	CREATE TABLE #PrestigeIdsDistinctReason
	(
		PrestigeId BIGINT NOT NULL,
		Reason NVARCHAR(300) NULL
	)





	-- 1. Get a list of the last refund Id for each of our PrestigeId values (as passed in in the table type variable)
	INSERT	INTO #LastRefundId
			(
				PrestigeId,
				LastRefundId
			)
	SELECT	ccb.PrestigeID, 
			MAX(ccb.Id) AS LastRefundId
	FROM	[Refunds].[CardCreditBalance] ccb
			INNER JOIN
			#PrestigeIds p ON ccb.PrestigeId = p.PrestigeId
	WHERE	ccb.Balance = 0
	GROUP BY ccb.PrestigeID

	-- Create an index for performance on the left outer join
	CREATE CLUSTERED INDEX IX_LastRefundId_PrestigeId ON #LastRefundId(PrestigeId);



	-- 2. Get a list of all the pending adjustments that have not yet been refunded (but which are due to be) for our PrestigeIds
	INSERT INTO	#PendingOcas
				(
					PrestigeId,
					Id,
					OysterChargeAdjustmentId,
					Reasons
				)
	SELECT		ccb.PrestigeID,
				ccb.ID,
				ccb.OysterChargeAdjustmentId,
				oca.Reasons
	FROM		[Refunds].[CardCreditBalance] ccb
				INNER JOIN 
				[Refunds].[OysterChargeAdjustment] oca ON ccb.OysterChargeAdjustmentId = oca.Id
				INNER JOIN
				#PrestigeIds p ON ccb.PrestigeId = p.PrestigeId
				LEFT OUTER JOIN 
				#LastRefundId lastRefund ON ccb.PrestigeID = lastRefund.PrestigeID
	WHERE		ccb.ID > ISNULL(lastRefund.LastRefundId, 0)

	-- Create an index for performance
	CREATE CLUSTERED INDEX IX_PendingOcas_PrestigeId ON #PendingOcas(PrestigeId);

	/*
	-- 3. Combine all the reason records into a single record per PrestigeId
	INSERT INTO	#PrestigeIdsAllReasons
				(
					PrestigeId,
					Reason
				)
	SELECT		PrestigeId, 
				STUFF((SELECT	':' + Reasons
						FROM		#PendingOcas poca2
						WHERE	poca2.PrestigeId = poca1.PrestigeId
						ORDER BY	ID
						FOR XML PATH('')), 1, 1, '') AS AllReasons
	FROM		#PendingOcas poca1
	GROUP BY	poca1.PrestigeId
	*/

	-- 4. Split the single records into multiple records -> one per individual reason
	INSERT INTO	#PrestigeIdsDistinctReason
				(
					PrestigeId,
					Reason
				)
				/*
	SELECT DISTINCT	pr.PrestigeId, 
					f.value AS Reason
	FROM			#PrestigeIdsAllReasons pr
					CROSS  APPLY 
					[Refunds].[List_to_Table](pr.Reason, ':') AS f
					*/
					
	SELECT DISTINCT	oca.PrestigeId, 
					ocaReasons.value AS Reason
	FROM			#PendingOcas oca
					CROSS  APPLY 
					[Refunds].[List_to_Table](oca.Reasons, ':') AS ocaReasons
					
	-- Create an index for performance
	CREATE CLUSTERED INDEX IX_PrestigeIdsDistinctReason_PrestigeId ON #PrestigeIdsDistinctReason(PrestigeId);


	-- 5. Recombine all the distinct reasons into one record per PrestigeId. Each reason is separated by a colon ':'
	SELECT DISTINCT	pdr2.PrestigeId,
					STUFF((SELECT ':' + pdr1.Reason 
							FROM #PrestigeIdsDistinctReason pdr1
							WHERE pdr1.PrestigeId = pdr2.PrestigeId
							ORDER BY pdr1.Reason
							FOR XML PATH('')), 1, 1, '') as Reasons
	FROM			#PrestigeIdsDistinctReason pdr2
	-- Ensure all input prestige ids are present in output, even if we didn't find any reasons for them
	UNION
	SELECT PrestigeId, 'Reissue' FROM #PrestigeIds src 
	WHERE src.PrestigeId NOT IN (SELECT pdr.PrestigeId FROM #PrestigeIdsDistinctReason pdr)



	-- Clean up temp tables
	-- NOTE: indexes on temp tables are automatically dropped when the temp table is dropped
	IF OBJECT_ID('tempdb..#PrestigeIds') IS NOT NULL
		DROP TABLE #PrestigeIds

	IF OBJECT_ID('tempdb..#LastRefundId') IS NOT NULL
		DROP TABLE #LastRefundId

	IF OBJECT_ID('tempdb..#PendingOcas') IS NOT NULL
		DROP TABLE #PendingOcas

	IF OBJECT_ID('tempdb..#PrestigeIdsAllReasons') IS NOT NULL
		DROP TABLE #PrestigeIdsAllReasons

	IF OBJECT_ID('tempdb..#PrestigeIdsDistinctReason') IS NOT NULL
		DROP TABLE #PrestigeIdsDistinctReason

END
GO


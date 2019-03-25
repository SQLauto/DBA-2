/*RUN THIS ON THE VINS003 INSTANCE IN PREPROD AND STAGING*/
USE OCAE
GO

ALTER PROCEDURE [ocae].[TokenJourneySummaryHeaderUpsert]
       @tjsh ocae.TokenJourneySummaryHeader READONLY
AS
BEGIN
DECLARE @min SMALLINT,@max SMALLINT
	--SET STATISTICS IO,TIME ON;
	SET XACT_ABORT, NOCOUNT ON;

	IF OBJECT_ID('Tempdb..#tjsh') IS NOT NULL
		DROP TABLE #tjsh;

	IF OBJECT_ID('Tempdb..#Adjustment') IS NOT NULL
		DROP TABLE #Adjustment;

	SELECT * INTO #tjsh FROM @tjsh;
	CREATE INDEX idx_tjsh_temp ON #tjsh(TravelTokenID, TravelDayKey);

	SELECT A.* INTO #Adjustment FROM ocae.Adjustment A
	JOIN #tjsh T ON T.traveltokenid = A.prestigeid AND A.TravelDay=T.traveldaykey;


------------------------------------------------
SELECT @min=MIN(TravelDayKey), @max=MAX(TravelDayKey)
FROM #tjsh;


	BEGIN TRY
		BEGIN TRANSACTION;

		WHILE @min <= @max
			BEGIN
			
				-- Delete adjustments that are about to be rendered redundant
				-- These are adjustments that were examined in primary part 1, but would only be dispatched if no new data arrives
				-- New data has indeed arrived, so they are no longer of interest (part 2 is going to recalc and dispatch)
				DECLARE @AdjustmentToDelete TABLE ( Id bigint NOT NULL PRIMARY KEY );
				
				INSERT 
					@AdjustmentToDelete ( Id )
				SELECT
					a.Id
				FROM
					ocae.Adjustment a
					INNER JOIN ocae.TokenJourneySummaryHeader t ON a.TokenJourneySummaryHeaderId = t.Id
					INNER JOIN #tjsh tbatch ON t.TravelTokenid = tbatch.TravelTokenId AND t.TravelDayKey = tbatch.TravelDayKey
				WHERE
					t.TravelDayKey = @min
					AND t.TjshAdjustmentCalculationStatusId = 2
					AND a.AdjustmentDispatched = 0
					AND tbatch.TravelDayVersion > t.TravelDayVersion
					;
					
				DELETE
					RL
				FROM
					ocae.RefundLinking RL
					INNER JOIN @AdjustmentToDelete A ON RL.AdjustmentId = A.Id
					;
					
				DELETE
					A
				FROM
					ocae.Adjustment A
					INNER JOIN @AdjustmentToDelete ATD ON A.Id = ATD.Id
					;
			
				UPDATE  ocae.TokenJourneySummaryHeader 
					SET
							FileReceivedId = s.FileReceivedId,
							TravelTokenId = s.TravelTokenId,
							UniqueTokenId = s.UniqueTokenId,
							TravelDayKey = s.TravelDayKey,
							DailyTotal = s.DailyTotal,
							TravelDayVersion = s.TravelDayVersion,
							FirstTapId = s.FirstTapId,
							FirstTapAtc = s.FirstTapAtc,
							FirstTapTravelDay = s.FirstTapTravelDay,
							LastTapId = s.LastTapId,
							LastTapAtc = s.LastTapAtc,
							LastTapTravelDay = s.LastTapTravelDay,
							RealTapCount = s.RealTapCount,
							IsLastJourneyUnfinished = s.IsLastJourneyUnfinished,
							IsFirstJourneyUnstarted = s.IsFirstJourneyUnstarted,
							HasIncompleteJourney = s.HasIncompleteJourney,
							-- If an adjustment has been calculated as part of the Primary part 1 (pre-end-of-day), but part 2 (post-end-of-day) has not run yet, 
							-- then we need to reset the flag back to 0 so that it is correctly picked up at the part 2 (post-end-of-day) check
							  -- 0 - Not yet examined OR Examined at Primary pt 1 - Day Incomplete - No Adjustment Calculated
							  -- 1 - Examined at Primary pt 2, Secondary or Tertiary - Day Incomplete - No Adjustment Calculated - Eligible for the secondary check if new data arrives before the tertiary
							  -- 2 - Examined at Primary pt 1 (pre-end-of-day) - Day Complete - Adjustment calculation complete - To be dispatched if no new data arrives before Primary pt. 2 (post-end-of-day)
							  -- 3 - Examined at Primary pt 2, Secondary or Tertiary- Day Complete - Adjustment calculation complete - To be dispatched	
							TjshAdjustmentCalculationStatusId = 
										(CASE 
											WHEN (t.TjshAdjustmentCalculationStatusId = 0) THEN 0
											WHEN (t.TjshAdjustmentCalculationStatusId = 1) THEN 1
											WHEN (t.TjshAdjustmentCalculationStatusId = 2) THEN 0
											WHEN (t.TjshAdjustmentCalculationStatusId = 3) THEN 3
										END),
							JourneyCount = s.JourneyCount,
							HasDisruptions = s.HasDisruptions,			
							HasAutofilledJourney = s.HasAutofilledJourney,	
							HasSelfServiceRefund	= s.HasSelfServiceRefund,	
							HasFreeBusAndTramTransfer3 = s.HasFreeBusAndTramTransfer3,
							HasFreeBusAndTramTransfer2 = s.HasFreeBusAndTramTransfer2,
							HasCapBenefitingJourney = s.HasCapBenefitingJourney,
							HasWeeklyCapping = s.HasWeeklyCapping,
							HasDailyCapping = s.HasDailyCapping,
							HasManualCorrectionOverridden = s.HasManualCorrectionOverridden

					FROM   	ocae.TokenJourneySummaryHeader  AS t
							JOIN   	#tjsh  AS S 
								ON t.TravelTokenId = s.TravelTokenId AND t.TravelDayKey = s.TravelDayKey
					
					WHERE 	t.TravelDayKey=@min AND   s.TravelDayVersion > t.TravelDayVersion;

				SET @min += 1;
			END; 				
 
 			INSERT  ocae.TokenJourneySummaryHeader
					(
						FileReceivedId,
						TravelTokenId,
						UniqueTokenId,
						TravelDayKey,
						DailyTotal,
						TravelDayVersion,
						FirstTapId,
						FirstTapAtc,
						FirstTapTravelDay,
						LastTapId,
						LastTapAtc,
						LastTapTravelDay,
						RealTapCount,
						IsLastJourneyUnfinished,
						IsFirstJourneyUnstarted,
						HasIncompleteJourney,
						TjshAdjustmentCalculationStatusId,
						JourneyCount,
						HasDisruptions,			
						HasAutofilledJourney,	
						HasSelfServiceRefund,		
						HasFreeBusAndTramTransfer3,
						HasFreeBusAndTramTransfer2,
						HasCapBenefitingJourney,
						HasWeeklyCapping,
						HasDailyCapping,
						HasManualCorrectionOverridden
					)
			SELECT     	s.FileReceivedId,
						s.TravelTokenId,
						s.UniqueTokenId,
						s.TravelDayKey,
						s.DailyTotal,
						s.TravelDayVersion,
						s.FirstTapId,
						s.FirstTapAtc,
						s.FirstTapTravelDay,
						s.LastTapId,
						s.LastTapAtc,
						s.LastTapTravelDay,
						s.RealTapCount,
						s.IsLastJourneyUnfinished,
						s.IsFirstJourneyUnstarted,
						s.HasIncompleteJourney,
						0,
						s.JourneyCount,
						s.HasDisruptions,			
						s.HasAutofilledJourney,
						s.HasSelfServiceRefund,		
						s.HasFreeBusAndTramTransfer3,
						s.HasFreeBusAndTramTransfer2,
						s.HasCapBenefitingJourney,
						s.HasWeeklyCapping,
						s.HasDailyCapping,
						s.HasManualCorrectionOverridden
			FROM	#tjsh s		
					LEFT  JOIN 	ocae.TokenJourneySummaryHeader  t 
						ON t.TravelTokenId = s.TravelTokenId AND t.TravelDayKey = s.TravelDayKey 
			WHERE 	t.TravelDayKey IS NULL;		 
		

		COMMIT TRANSACTION;
	END TRY
	
    BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		
		DECLARE @ErrorNumber INT = ERROR_NUMBER();
		DECLARE @ErrorLine INT = ERROR_LINE();
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
		DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
		DECLARE @ErrorState INT = ERROR_STATE();
		DECLARE @proc sysname=ERROR_PROCEDURE();

		IF @ErrorMessage NOT LIKE '***%'
			BEGIN
				SET @ErrorMessage = '*** ' + 
						COALESCE(QUOTENAME(@proc), '<dynamic SQL>') + 
						', Line ' + LTRIM(STR(@ErrorLine)) + 
						'. Error No ' + LTRIM(STR(@ErrorNumber)) + 
						': ' + @ErrorMessage;

				SELECT 
					@ErrorNumber AS ErrorNumber,
					@ErrorSeverity AS ErrorSeverity,
					@ErrorState AS ErrorState,
					@proc AS ErrorProcedure,
					@ErrorLine AS ErrorLine,
					@ErrorMessage AS ErrorMessage;

				RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
		    END;
		   
	   RETURN 1; 
	END CATCH;	
	
END;

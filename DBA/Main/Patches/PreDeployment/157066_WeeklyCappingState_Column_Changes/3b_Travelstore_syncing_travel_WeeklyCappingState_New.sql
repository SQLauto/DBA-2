/* 
Script name : 3b_Travelstore_syncing_travel_WeeklyCappingState_New.sql

This script should be run on VINS001 Travelstore_CPC
This script syncs up the travel.[WeeklyCappingState_NEW] table with new records or records that have changed
	since the table creation.
	
!!! This should only be run after the system has been shut down and can be run in parralel with the differential backups !!!

Time run in Devint : 00:01:34 

  */
USE Travelstore
GO
IF OBJECT_ID('Tempdb..#RecordstoMergeTravelstore') IS NOT NULL
DROP TABLE #RecordstoMergeTravelstore;


SELECT [TravelDay],[TravelTokenId],[CumulativeDailyBestValue],[DailyBestValue],[BestWeeklyCapId],[DailyTotalFareChargedSoFar]
		,[DailyCounterBestRunningTotal]	,[WeeklyCounterState],[Stage2RecalculationCacheState] 
		INTO #RecordstoMergeTravelstore
		FROM travel.[WeeklyCappingState]
	EXCEPT
SELECT [TravelDay],[TravelTokenId],[CumulativeDailyBestValue],[DailyBestValue],[BestWeeklyCapId],[DailyTotalFareChargedSoFar]
		,[DailyCounterBestRunningTotal],[WeeklyCounterState],[Stage2RecalculationCacheState]
		FROM travel.[WeeklyCappingState_New];


MERGE travel.[WeeklyCappingState_New] AS tget
USING (
	SELECT * FROM #RecordstoMergeTravelstore
	) AS source([TravelDay],[TravelTokenId],[CumulativeDailyBestValue],[DailyBestValue],[BestWeeklyCapId],[DailyTotalFareChargedSoFar]
		,[DailyCounterBestRunningTotal],[WeeklyCounterState],[Stage2RecalculationCacheState])
	ON (
			tget.Travelday = source.Travelday	AND tget.Traveltokenid = source.Traveltokenid
			)
WHEN MATCHED
	THEN
		UPDATE
		SET [CumulativeDailyBestValue] = source.[CumulativeDailyBestValue]
			,[DailyBestValue] = source.[DailyBestValue]
			,[BestWeeklyCapId] = source.[BestWeeklyCapId]
			,[DailyTotalFareChargedSoFar] = source.[DailyTotalFareChargedSoFar]
			,[DailyCounterBestRunningTotal] = source.[DailyCounterBestRunningTotal]
			,[WeeklyCounterState] = source.[WeeklyCounterState]
			,[Stage2RecalculationCacheState] = source.[Stage2RecalculationCacheState]
WHEN NOT MATCHED
	THEN
		INSERT ([TravelDay],[TravelTokenId],[CumulativeDailyBestValue],[DailyBestValue],[BestWeeklyCapId],[DailyTotalFareChargedSoFar]
			,[DailyCounterBestRunningTotal],[WeeklyCounterState],[Stage2RecalculationCacheState]
			)
		VALUES (source.[TravelDay],source.[TravelTokenId],source.[CumulativeDailyBestValue],source.[DailyBestValue],source.[BestWeeklyCapId],
				source.[DailyTotalFareChargedSoFar]	,source.[DailyCounterBestRunningTotal],source.[WeeklyCounterState],source.[Stage2RecalculationCacheState]
			);
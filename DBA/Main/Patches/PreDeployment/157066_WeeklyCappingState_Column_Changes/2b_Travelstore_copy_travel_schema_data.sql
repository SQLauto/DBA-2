/* 

Script Name: 2b_Travelstore_copy_travel_schema_data.sql

TO BE RUN in Travelstore Database on VINS001 
This will populate "_new" tables for travel and archive schemas 

It should be run in parallel with 2a_Travelstore_cpc_copy_travel_schema_data.sql

Time run in devint : 08:29 -- Generally production and staging will take up to twice as long


*/ 
USE Travelstore
GO
SET NOCOUNT ON 
GO
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO
-- This can be run in read uncommitted to reduce any potential impact on application 
DECLARE @min SMALLINT,@max SMALLINT

SELECT @min=MIN(travelday),@max=MAX(travelday) FROM travel.WeeklyCappingState;


WHILE @min <=@max
BEGIN 

INSERT INTO travel.[WeeklyCappingState_new]([TravelDay], [TravelTokenId], [CumulativeDailyBestValue], [DailyBestValue], [BestWeeklyCapId], [DailyTotalFareChargedSoFar], [DailyCounterBestRunningTotal], [WeeklyCounterState], [Stage2RecalculationCacheState])
SELECT S.*
FROM travel.[WeeklyCappingState] S
LEFT JOIN travel.[WeeklyCappingState_NEW] D ON S.TravelDay=D.Travelday and S.TravelTokenId=D.TravelTokenId
WHERE  S.Travelday = @min
AND D.Travelday is null 

SET @min+=1;

IF @min%5 = 0 
CHECKPOINT

END; 


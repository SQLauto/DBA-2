 /*  This Must be run against FAE/TravelstoreINSTANCE VINS001/VINS004  */
USE [FAE]
 GO 
BEGIN TRY
    BEGIN TRANSACTION;
  
    
    UPDATE FAE.travel.Disruptions SET EndDayKey=14274, Disruption = REPLACE(Disruption,'2020-06-10T00:00:00+01:00', '2019-01-31T04:29:59+00:00') WHERE DisruptionId=6814
  
	UPDATE TravelStore.travel.Disruptions SET EndDayKey=14274, Disruption = REPLACE(Disruption,'2020-06-10T00:00:00+01:00', '2019-01-31T04:29:59+00:00') WHERE DisruptionId=6814

	INSERT INTO TravelStore_CPC.travel.Disruptions 
		SELECT [DisruptionId]
			  ,[StartDayKey]
			  ,[EndDayKey]
			  ,[Disruption]
			  ,[ReceivedDate] FROM FAE.travel.Disruptions WHERE DisruptionId=6814

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
	   ROLLBACK TRANSACTION;
    THROW;
END CATCH
 /* This Must be run against FAE/Travelstore INSTANCE VINS001/VINS004*/
USE [FAE]
 GO 
BEGIN TRY
    BEGIN TRANSACTION;

      --Set up first day variable to filter data
	 DECLARE  @EarliestDay SMALLINT 
	 SELECT @EarliestDay=MAX(TravelDay)-29 FROM [FAE].travel.CorrectionEvent ;
	
	--truncate the table
	TRUNCATE TABLE [TravelStore_CPC].travel.CorrectionEvent;
	
	 --Copy recent CorrectionEvents from FAE to TravelStore
	 INSERT INTO [TravelStore_CPC].travel.CorrectionEvent([id],[TravelTokenId],[TravelDay],[EventId])
	 SELECT NEXT VALUE FOR [TravelStore_CPC].[sequence].CorrectionEvents,[TravelTokenId],[TravelDay],[EventId] FROM [FAE].travel.CorrectionEvent 
	 WHERE TravelDay >= @EarliestDay;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
	THROW;

 END CATCH

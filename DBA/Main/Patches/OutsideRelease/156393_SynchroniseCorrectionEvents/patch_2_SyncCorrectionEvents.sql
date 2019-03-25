 /* This Must be run against FAE/Travelstore_CPC INSTANCE VINS001/VINS004
 
 This script should be safe to run given the following conditions:
 - we are still running old and new FAE versions of FAE in parallel
 - 'new' FAE (which uses TravelStore_CPC) is retrieving Autofill journey history from the FAE database (determined by checking the AutofillJourneyHistoryDatabase setting in PipelineHost.exe.config)
 */
USE [FAE]
 GO 
BEGIN TRY
    BEGIN TRANSACTION;
  
    --Set up first day variable to filter data
    DECLARE  @EarliestDay SMALLINT 
    SELECT @EarliestDay=MAX(TravelDay)-91 FROM [FAE].travel.CorrectionEvent ;

    --Clear the table
    TRUNCATE TABLE [TravelStore_CPC].travel.CorrectionEvent

    --Copy recent CorrectionEvents from FAE to TravelStore_CPC
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
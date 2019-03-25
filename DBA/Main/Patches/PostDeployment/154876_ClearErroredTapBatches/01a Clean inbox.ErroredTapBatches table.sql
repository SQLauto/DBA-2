--Description
-- This patch is for removing unserviceable or already-processed taps from inbox.erroredTapBatches, and then resubmitting any remaining records for processing
-- Background: Currently the vast majority (if not all) records in inbox.erroredTapBatches	

USE [TravelStore_CPC]

SET NOCOUNT ON;

-- delete taps that were successfully processed 
delete from inbox.erroredtapbatches where tapid in (select etb.tapid from inbox.erroredtapbatches etb join travel.tap t on (etb.tapid=t.tapid))

-- delete unserviceable manual correction requests
delete from inbox.erroredtapbatches where synthetic =1 and travelday<14160

-- move the remainder to the tapqueue for reprocessing (equivalent to calling [inbox].[ReinstateErroredTapBatch] against all remaining batches )
DECLARE @maxEngineCount INT;
SELECT TOP 1 @maxEngineCount=[value] FROM inbox.maxenginecount;

DECLARE @r INT;

BEGIN TRY 
SET @r = 1;


WHILE @r > 0
BEGIN
  BEGIN TRANSACTION;
       
delete TOP (100000) from inbox.ErroredTapBatches
    output deleted.[TapId]
                ,deleted.[TravelDay]
                ,deleted.[TapTimestamp]
                ,deleted.[Created]
                ,deleted.[NationalLocationCode]
                ,deleted.[HostDeviceTypeId]
                ,deleted.[TravelTokenId]
                ,deleted.[ExpiryDate]
                ,0 as [BatchId]
                ,deleted.[ValidationTypeId]
                ,deleted.[TrainingFlag]
                ,deleted.[ReaderId]
                ,deleted.[BusRouteId]
                ,deleted.[ValidationResultId]
                ,deleted.[PaymentCardATC]
                ,deleted.[ModeId]
                ,deleted.[Synthetic]
                ,deleted.[SyntheticATCOffset]
                ,deleted.[CounterTapFlag]
                ,deleted.[LocalTimeZone]
                ,deleted.[Source]
                ,deleted.[BusStopId]
                ,deleted.[BusStopIdStatus]
                ,deleted.[BusDirection]
                ,deleted.[TapCreatedInPare]
                ,deleted.[InspectorId]
                ,deleted.[InspectionLocation]
                ,deleted.[OperatorId]
                ,deleted.[RTDEMVSequenceNumber]
                ,0 as [Processing]
                ,deleted.[TravelTokenId] % @maxEngineCount as [Modulo]
                ,deleted.[Reconstruction]
                ,deleted.[TktInvolved]
                ,deleted.[TktZones]
    into inbox.[TapQueue]

  SET @r = @@ROWCOUNT;

  COMMIT TRANSACTION;

  /* This section can be amended by environment by the dba where an explicit database log backup can be inserted relevant to the environment
  This will backup the log every million rows inserted. Will leave this to the DBA's discretion
  
  --if @r%10 = 0
  -- CHECKPOINT;    -- if simple
  -- BACKUP LOG ... -- if full
  */
END
END TRY 
BEGIN CATCH 
  IF (@@TRANCOUNT > 0)
   BEGIN
      ROLLBACK;
      THROW;
   END 
    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() AS ErrorState,
        ERROR_PROCEDURE() AS ErrorProcedure,
        ERROR_LINE() AS ErrorLine,
        ERROR_MESSAGE() AS ErrorMessage
END CATCH



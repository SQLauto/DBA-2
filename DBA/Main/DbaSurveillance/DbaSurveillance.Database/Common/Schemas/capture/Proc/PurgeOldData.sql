EXEC #CreateDummyStoredProcedureIfNotExists 'capture', 'PurgeOldData'
GO

--exec [capture].[PurgeOldData] 7,7
ALTER PROCEDURE [capture].[PurgeOldData]
    (
      @PurgeConfig SMALLINT ,
      @PurgeCounters SMALLINT
    )
AS 
    BEGIN;
        IF @PurgeConfig IS NULL
            OR @PurgeCounters IS NULL 
            BEGIN;
                RAISERROR(N'Input parameters cannot be NULL', 16, 1);
                RETURN;
            END;
        DELETE  FROM [capture].[ConfigData]
        WHERE   [CaptureDate] < GETDATE() - @PurgeConfig;

        DELETE  FROM [capture].[ServerConfig]
        WHERE   [CaptureDate] < GETDATE() - @PurgeConfig;

        DELETE  FROM [capture].[PerfMonData]
        WHERE   [CaptureDate] < GETDATE() - @PurgeCounters;
		
	
		DELETE FROM [capture].[FileStats]
		WHERE CaptureDate < GETDATE() - @PurgeCounters;

		DELETE FROM [capture].[StoredProcedureStats]
		WHERE CaptureDate < GETDATE() - @PurgeCounters;

		DELETE FROM [capture].fileinfo
		WHERE CaptureDate < GETDATE() - @PurgeCounters;
		
		DELETE FROM [capture].[CacheUsagebyDBData]
		WHERE CaptureDate < GETDATE() - @PurgeCounters;
			
		DELETE  from [capture].[CacheUsagebyDbResults]
		WHERE Captureid < (SELECT MIN(id) FROM  [capture].[CacheUsagebyDbData])
		
		DELETE FROM [capture].[CPUData]
		WHERE StartTime < GETDATE() - @PurgeCounters;
			
		DELETE  from [capture].[CpuResults]
		WHERE CpuDataID < (SELECT MIN(id) FROM  [capture].[CPUData])


    END;





GO



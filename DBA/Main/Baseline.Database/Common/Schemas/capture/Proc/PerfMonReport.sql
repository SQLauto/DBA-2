EXEC #CreateDummyStoredProcedureIfNotExists 'capture', 'PerfMonReport'
GO


ALTER PROCEDURE [capture].[PerfMonReport]
    (
      @Counter NVARCHAR(128) = N'%'
    )
AS 
    BEGIN;
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
        SELECT  *
        FROM    [capture].[PerfMonData]
        WHERE   [Counter] LIKE @Counter
        ORDER BY [Counter] ,
                [CaptureDate]
    END;

GO



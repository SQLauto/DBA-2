EXEC #CreateDummyStoredProcedureIfNotExists 'capture', 'SysConfigReport'
GO

ALTER PROCEDURE [capture].[SysConfigReport]
    (
      @OlderDate DATETIME ,
      @RecentDate DATETIME
    )
AS 
    BEGIN;
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

        IF @RecentDate IS NULL
            OR @OlderDate IS NULL 
            BEGIN;
                RAISERROR(N'Input parameters cannot be NULL', 16, 1);
                RETURN;
            END;

        SELECT  [O].[Name] ,
                [O].[Value] AS "OlderValue" ,
                [O].[ValueInUse] AS "OlderValueInUse" ,
                [R].[Value] AS "RecentValue" ,
                [R].[ValueInUse] AS "RecentValueInUse"
        FROM    [capture].[ConfigData] O
                JOIN ( SELECT   [ConfigurationID] ,
                                [Value] ,
                                [ValueInUse]
                       FROM     [capture].[ConfigData]
                       WHERE    [CaptureDate] = @RecentDate
                     ) R ON [O].[ConfigurationID] = [R].[ConfigurationID]
        WHERE   [O].[CaptureDate] = @OlderDate
                AND ( ( [R].[Value] <> [O].[Value] )
                      OR ( [R].[ValueInUse] <> [O].[ValueInUse] )
                    )
    END;





GO



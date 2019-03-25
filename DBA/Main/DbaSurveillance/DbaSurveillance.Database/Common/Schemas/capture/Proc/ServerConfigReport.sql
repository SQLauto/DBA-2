EXEC #CreateDummyStoredProcedureIfNotExists 'capture', 'ServerConfigReport'
GO

ALTER PROCEDURE [capture].[ServerConfigReport]
    (
      @Property NVARCHAR(128) = NULL
    )
AS 
    BEGIN;
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
		
        IF @Property NOT IN ( N'ComputerNamePhysicalNetBios',
                              N'DBCC_TRACESTATUS', N'Edition',
                              N'InstanceName',
                              N'IsClustered', N'MachineName',
                              N'ProcessorNameString', N'ProductLevel',
                              N'ProductVersion', N'ServerName' ) 
            BEGIN;
                RAISERROR(N'Valid values for @Property are:
                            ComputerNamePhysicalNetBios, DBCC_TRACESTATUS,
                            Edition, InstanceName, IsClustered,
                            MachineName, ProcessorNameString,
                            ProductLevel, ProductVersion, or ServerName',
                         16, 1);
                RETURN;
            END;

        SELECT  *
        FROM    [capture].[ServerConfig]
        WHERE   [Property] = ISNULL(@Property, Property)
        ORDER BY [Property] ,
                [CaptureDate]
    END;





GO




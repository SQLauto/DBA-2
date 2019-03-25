
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

EXEC #AssertTableExists 'dim','DatabaseFiles';
EXEC #AssertTableExists 'dim','Dates';
EXEC #AssertTableExists 'dim','Instances';
EXEC #AssertTableExists 'dim','PerfmonCounters';
EXEC #AssertTableExists 'dim','Server';
EXEC #AssertTableExists 'dim','SqlCounters';
EXEC #AssertTableExists 'dim','StoredProcedures';
EXEC #AssertTableExists 'dim','Times';
EXEC #AssertTableExists 'dim','WaitStats';
EXEC #AssertTableExists 'dim','WhoIsActive';
EXEC #AssertTableExists 'fact','CPU';
EXEC #AssertTableExists 'fact','FileInfo';
EXEC #AssertTableExists 'fact','PerfmonCounters';
EXEC #AssertTableExists 'fact','SQLCounters';
EXEC #AssertTableExists 'fact','StoredProcedures';
EXEC #AssertTableExists 'fact','VirtualFileStats';
EXEC #AssertTableExists 'fact','WaitStats';
EXEC #AssertTableExists 'fact','WhoIsActive';
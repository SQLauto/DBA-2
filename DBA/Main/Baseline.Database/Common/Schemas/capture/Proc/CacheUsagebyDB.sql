EXEC #CreateDummyStoredProcedureIfNotExists 'capture', 'CacheUsagebyDB'
GO
ALTER PROC [capture].[CacheUsagebyDB]
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
DECLARE @sqlstring NVARCHAR(MAX);
DECLARE @DBName NVARCHAR(257);


BEGIN
	DECLARE @CaptureDataID int
	DECLARE @DataID int
	DECLARE @ServerName varchar(300),@NodeName varchar(300)
	SELECT @ServerName = convert(nvarchar(128), serverproperty('servername'))
	SELECT @NodeName = convert(nvarchar(128), serverproperty('ComputerNamePhysicalNetBIOS'))
	DECLARE @MemoryUsedByInstance bigint
	DECLARE @TotalAllocatedInstanceMemory bigint
	DECLARE @TotalServerMemory bigint

	SELECT @MemoryUsedByInstance=SUM(pages_kb+virtual_memory_committed_kb+awe_allocated_kb)/1024 FROM sys.dm_os_memory_clerks;
    SELECT @TotalAllocatedInstanceMemory = cntr_value/1024 FROM sys.dm_os_performance_counters WHERE counter_name IN ('Target Server Memory (KB)');
	SELECT @TotalServerMemory=total_physical_memory_kb/1024 FROM sys.dm_os_sys_memory WITH (NOLOCK) OPTION (RECOMPILE);

	INSERT INTO capture.CacheUsagebyDbData
	(
		CaptureDate,
		ServerName,
		MemoryUsedByInstanceMB,
		TotalAllocatedInstanceMemoryMB,
		TotalServerMemoryMB,
		Node
	)
	VALUES
	(
		GETDATE(),
		@ServerName,
		@MemoryUsedByInstance,
		@TotalAllocatedInstanceMemory,
		@TotalServerMemory,
		@NodeName
	);
	SELECT @CaptureDataID = SCOPE_IDENTITY();
		
		 
		 INSERT INTO [capture].[CacheUsagebyDbResults](databasename, Buffered_MB, Captureid)
         SELECT DB_NAME(database_id) AS databasename,
		 COUNT(*) * 8/1024.0 AS Buffered_MB,
		 @CaptureDataID Captureid
		 FROM sys.dm_os_buffer_descriptors
		 WHERE database_id > 4 -- system databases
		 AND database_id <> 32767 -- ResourceDB
		 GROUP BY DB_NAME(database_id)
		 ORDER BY Buffered_MB DESC OPTION (RECOMPILE);
         SELECT @DataID = SCOPE_IDENTITY();

END
GO
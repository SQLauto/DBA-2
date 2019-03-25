
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO


declare @schemaExists bit 
exec #SchemaExists 'capture', @schemaExists out

if (@schemaExists = 0)
begin
	EXEC('CREATE SCHEMA [capture]')
end

declare @tableExists bit 
exec #TableExists 'capture', 'BlockedProcessReport', @tableExists out

if (@tableExists = 0)
begin	
	CREATE TABLE [capture].[BlockedProcessReport](
		[dd hh:mm:ss.mss] [varchar](15) NULL,
		[session_id] [varchar](30) NULL,
		[sql_text] [xml] NULL,
		[query_plan] [xml] NULL,
		[login_name] [sysname] NOT NULL,
		[wait_info] [nvarchar](4000) NULL,
		[CPU] [varchar](30) NULL,
		[Duration] [int] NULL,
		[tempdb_allocations] [varchar](30) NULL,
		[tempdb_current] [varchar](30) NULL,
		[blocking_session_id] [varchar](30) NULL,
		[blocking_session_count] [varchar](30) NULL,
		[reads] [varchar](30) NULL,
		[writes] [varchar](30) NULL,
		[physical_reads] [varchar](30) NULL,
		[used_memory] [varchar](30) NULL,
		[Status] [varchar](30) NULL,
		[open_tran_count] [varchar](30) NULL,
		[host_name] [varchar](100) NULL,
		[Database_name] [varchar](100) NULL,
		[program_name] [varchar](500) NULL,
		[start_time] [datetime] NULL,
		[login_time] [datetime] NULL,
		[collection_time] [datetime] NULL
	)
end

exec #TableExists 'capture', 'CacheUsageData', @tableExists out

if (@tableExists = 0)
begin	
	CREATE TABLE [capture].[CacheUsageData](
	[ID] [bigint] IDENTITY(1,1) NOT NULL constraint PK_CacheUseageData_Id primary key clustered (Id),
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[ServerName] [varchar](500) NULL,
	[PullPeriod] [int] NULL,
	[node] [varchar](128) NULL
	) 
end


exec #TableExists 'capture', 'CacheUsageResults', @tableExists out

if (@tableExists = 0)
begin	
	CREATE TABLE [capture].[CacheUsageResults](
	[id] [bigint] IDENTITY(1,1) NOT NULL constraint PK_CacheUsageResults_Id primary key clustered (id),
	[objectname] [nvarchar](128) NULL,
	[name] [sysname] NULL,
	[type_desc] [nvarchar](60) NULL,
	[Buffered_Page_Count] [int] NULL,
	[Buffered_MB] [float] NULL,
	[CaptureDate] [datetime] NULL,
	[dbname] [nvarchar](50) NULL,
	[Captureid] [bigint] NULL
	) 
end

exec #TableExists 'capture', 'FileStatsWindow', @tableExists out
if (@tableExists = 0)
begin
	create table capture.FileStatsWindow
	(
		[ID] [bigint] identity(1,1) NOT NULL constraint PK_CaptureData_Id primary key clustered (Id),
		[StartTime] [datetime] NULL,
		[EndTime] [datetime] NULL,
		[ServerName] [varchar](500) NULL,
		[PullPeriod] [int] NULL,
		[node] [varchar](128) NULL
	)
end


exec #TableExists 'capture', 'StoredProcedureWindow', @tableExists out
if (@tableExists = 0)
begin
	create table capture.StoredProcedureWindow
	(
		[ID] [bigint] identity(1,1) NOT NULL constraint Pk_CaptureProdData_Id primary key clustered (ID),
		[StartTime] [datetime] NULL,
		[EndTime] [datetime] NULL,
		[ServerName] [varchar](500) NULL,
		[PullPeriod] [int] NULL,
		[node] [varchar](128) NULL
	)
end

exec #TableExists 'capture', 'StoredProcedureStats', @tableExists out
if (@tableExists = 0)
begin
	create table capture.StoredProcedureStats
	(
		[ID] [bigint] identity(1,1) NOT NULL constraint PK_CaptureProcResults_Id primary key clustered(id),
		[CaptureDate] [datetime] NULL,
		[ProcedureName] [varchar](100) NULL,
		[execution_count] [bigint] NULL,
		[total_worker_time] [bigint] NULL,
		[total_physical_reads] [bigint] NULL,
		[total_logical_writes] [bigint] NULL,
		[total_logical_reads] [bigint] NULL,
		[total_elapsed_time] [bigint] NULL,
		[database] [varchar](100) NULL,
		[CaptureProcDataID] [bigint] NULL,
		[database_id] smallint NULL,
		[proc_object_id] [int] NULL
	)
end

exec #TableExists 'capture', 'FileStats', @tableExists out
if (@tableExists = 0)
begin
	create table capture.FileStats
	(
		[ID] [bigint] identity(1,1) NOT NULL constraint PK_FileStats_Id primary key clustered(ID),
		[CaptureDate] [datetime] NULL,
		[read_per_ms] [float] NULL,
		[write_per_ms] [float] NULL,
		[io_stall_read] [int] NULL,
		[io_stall_write] [int] NULL,
		[num_of_reads] [int] NULL,
		[num_of_writes] [int] NULL,
		[num_of_bytes_written] [bigint] NULL,
		[database_id] [int] NULL,
		[file_id] [int] NULL,
		[CaptureDataID] [bigint] NULL,
		[iops]  AS ([num_of_reads]+[num_of_writes]) persisted
	)
end

exec #TableExists 'capture', 'ConfigData', @tableExists out
if (@tableExists = 0)
begin
	create table capture.ConfigData
	(
		[ConfigurationID] [int] NOT NULL,
		[Name] [nvarchar](35) NOT NULL,
		[Value] [sql_variant] NULL,
		[ValueInUse] [sql_variant] NULL,
		[CaptureDate] [datetime] NULL
	)
end

exec #TableExists 'capture', 'CpuUtilisation', @tableExists out
if (@tableExists = 0)
begin
	CREATE TABLE [capture].[CpuUtilisation](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[SQLServer] [int] NULL,
	[SystemIdle] [int] NULL,
	[Other] [int] NULL,
	[CaptureDateTime] [datetime] NULL,
	[node] [varchar](128) NULL
	) 
end

exec #TableExists 'capture', 'CurrentPartitionState', @tableExists out
if (@tableExists = 0)
begin
	CREATE TABLE [capture].[CurrentPartitionState](
	[CaptureDate] [datetime] NOT NULL,
	[FileGroupName] [sysname] NOT NULL,
	[data_space_id] [int] NOT NULL,
	[DataFileName] [sysname] NOT NULL,
	[physical_name] [nvarchar](260) NOT NULL,
	[ObjectName] [sysname] NULL,
	[SchemeName] [sysname] NULL,
	[PartitionNumber] [int] NULL,
	[rows] [bigint] NULL,
	[IndexName] [sysname] NULL,
	[total_pages] [bigint] NULL,
	[used_pages] [bigint] NULL,
	[first_page] [varchar](27) NULL,
	[PartitionSchemeName] [sysname] NULL,
	[PartitionFunctionName] [sysname] NULL,
	[boundary_value_on_right] [bit] NULL,
	[BoundaryValue] [sql_variant] NULL,
	[destination_data_space_id] [int] NULL
	) 
end

exec #TableExists 'capture', 'DatabaseFiles', @tableExists out
if (@tableExists = 0)
begin
	CREATE TABLE [capture].[DatabaseFiles](
	[ID] [int] IDENTITY(1,1) NOT NULL constraint PK_DatabaseFiles_Id primary key clustered (ID),
	[ServerName] [varchar](500) NULL,
	[DatabaseName] [varchar](500) NULL,
	[LogicalFileName] [varchar](500) NULL,
	[Database_ID] [int] NULL,
	[File_ID] [int] NULL,
	[PhysicalName] [varchar](1000) NULL,
	[fileType] [smallint] NULL,
	[file_guid] [uniqueidentifier] NULL,
	[createdDate] [datetime] NULL DEFAULT (getdate()),
	[endDate] [datetime] NULL
	) 
end

exec #TableExists 'capture', 'FileInfo', @tableExists out
if (@tableExists = 0)
begin	
	create table [capture].[FileInfo]
	(
		[ID] [bigint] IDENTITY(1,1) NOT NULL,
		[DatabaseName] [varchar](128) NULL,
		[DatabaseId] [smallint] NOT NULL,
		[FileID] [int] NOT NULL,
		[FileType] [tinyint] NOT NULL,
		[DriveLetter] [varchar](2) NULL,
		[LogicalFileName] [varchar](500) NULL,
		[PhysicalFileName] [varchar](500) NULL,
		[SizeMB] [decimal](38, 2) NULL,
		[SpaceUsedMB] [decimal](38, 2) NULL,
		[FreeSpaceMB] [decimal](38, 2) NULL,
		[MaxSize] [decimal](38, 2) NULL,
		[IsPercentGrowth] [bit] NULL,
		[Growth] [decimal](38, 2) NULL,
		[CaptureDate] [datetime] NOT NULL,
	)
end

exec #TableExists 'capture', 'PerfMonData', @tableExists out
if (@tableExists = 0)
begin
	CREATE TABLE [capture].[PerfMonData](
	[ID] [bigint] IDENTITY(1,1) NOT NULL primary key clustered (Id),
	[Counter] [nvarchar](770) NULL,
	[Value] [decimal](38, 2) NULL,
	[CaptureDate] [datetime] NULL,
	[node] [varchar](30) NULL
	)
end

exec #TableExists 'capture', 'ProcPerfCacheCollection', @tableExists out
if (@tableExists = 0)
begin
	CREATE TABLE [capture].[ProcPerfCacheCollection](
	[EVENT] [int] IDENTITY(1,1) NOT NULL,
	[ServerName] [nvarchar](255) NULL,
	[Date] [datetime] NULL,
	[ExecutionCount] [float] NULL,
	[Executions / Minute] [float] NULL,
	[Execution Weight] [float] NULL,
	[% Executions (Type)] [float] NULL,
	[Query Type] [nvarchar](255) NULL,
	[Database Name] [nvarchar](255) NULL,
	[QueryText] [nvarchar](max) NULL,
	[Warnings] [nvarchar](255) NULL,
	[Total CPU (ms)] [float] NULL,
	[Avg CPU (ms)] [float] NULL,
	[CPU Weight] [float] NULL,
	[% CPU (Type)] [float] NULL,
	[Total Duration (ms)] [float] NULL,
	[Avg Duration (ms)] [float] NULL,
	[Duration Weight] [float] NULL,
	[% Duration (Type)] [float] NULL,
	[Total Reads] [float] NULL,
	[Average Reads] [float] NULL,
	[Read Weight] [float] NULL,
	[% Reads (Type)] [float] NULL,
	[Total Writes] [float] NULL,
	[Average Writes] [float] NULL,
	[Write Weight] [float] NULL,
	[% Writes (Type)] [float] NULL,
	[TotalReturnedRows] [nvarchar](255) NULL,
	[AverageReturnedRows] [nvarchar](255) NULL,
	[MinReturnedRows] [nvarchar](255) NULL,
	[MaxReturnedRows] [nvarchar](255) NULL,
	[NumberOfPlans] [nvarchar](255) NULL,
	[NumberOfDistinctPlans] [nvarchar](255) NULL,
	[Created At] [datetime] NULL,
	[Last Execution] [datetime] NULL,
	[StatementStartOffset] [nvarchar](255) NULL,
	[StatementEndOffset] [nvarchar](255) NULL
	)
end

exec #TableExists 'capture', 'ServerConfig', @tableExists out
if (@tableExists = 0)
begin
	create table [capture].[ServerConfig]
	(
		[Property] [nvarchar](128) NULL,
		[Value] [sql_variant] NULL,
		[CaptureDate] [datetime] NULL
	) 
end

exec #TableExists 'capture', 'WaitStats', @tableExists out
if (@tableExists = 0)
begin
	CREATE TABLE [capture].[WaitStats](
	[RowNum] [bigint] IDENTITY(1,1) NOT NULL,
	[CaptureDate] [datetime] NULL,
	[WaitType] [nvarchar](120) NULL,
	[Wait_S] [decimal](14, 2) NULL,
	[Resource_S] [decimal](14, 2) NULL,
	[Signal_S] [decimal](14, 2) NULL,
	[WaitCount] [bigint] NULL,
	[Percentage] [decimal](4, 2) NULL,
	[AvgWait_S] [decimal](14, 2) NULL,
	[AvgRes_S] [decimal](14, 2) NULL,
	[AvgSig_S] [decimal](14, 2) NULL
	)
end

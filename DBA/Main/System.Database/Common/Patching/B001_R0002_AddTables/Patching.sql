
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @tableExists bit 
declare @columnExists bit
exec #TableExists 'dbo', 'Audit', @tableExists out
exec #ColumnExists 'dbo', 'Audit', 'Id', @columnExists out

if (@tableExists = 1 and @columnExists = 0)
begin
	drop table [dbo].[Audit]
end

if (@tableExists = 0)
begin	
	CREATE TABLE [dbo].[Audit](
		[ID] [int] IDENTITY(1,1) NOT NULL,
		[EventTime] [datetime2](7) NOT NULL,
		[ActionID] [varchar](4) NULL,
		[SessionID] [smallint] NULL,
		[ObjectID] [int] NOT NULL,
		[ClassType] [varchar](2) NULL,
		[ServerPrincipalName] [varchar](60) NULL,
		[DatabasePrincipalName] [varchar](40) NULL,
		[DatabaseName] [varchar](40) NULL,
		[ObjectName] [varchar](100) NULL,
		[Statement] [nvarchar](4000) NULL,
			PRIMARY KEY CLUSTERED 
			(
				[ID] ASC,
				[EventTime] ASC,
				[ObjectID] ASC
			)
	)
end

exec #TableExists 'dbo', 'CommandLog', @tableExists out
if (@tableExists = 0)
begin
		CREATE TABLE [dbo].[CommandLog](
		[ID] [int] IDENTITY(1,1) NOT NULL,
		[DatabaseName] [sysname] NULL,
		[SchemaName] [sysname] NULL,
		[ObjectName] [sysname] NULL,
		[ObjectType] [char](2) NULL,
		[IndexName] [sysname] NULL,
		[IndexType] [tinyint] NULL,
		[StatisticsName] [sysname] NULL,
		[PartitionNumber] [int] NULL,
		[ExtendedInfo] [xml] NULL,
		[Command] [nvarchar](max) NOT NULL,
		[CommandType] [nvarchar](60) NOT NULL,
		[StartTime] [datetime] NOT NULL,
		[EndTime] [datetime] NULL,
		[ErrorNumber] [int] NULL,
		[ErrorMessage] [nvarchar](max) NULL,
			 CONSTRAINT [PK_CommandLog] PRIMARY KEY CLUSTERED 
			(
				[ID] ASC
			)
	)
end



exec #TableExists 'dbo', 'dba_indexDefragLog', @tableExists out
if (@tableExists = 0)
begin	
		CREATE TABLE [dbo].[dba_indexDefragLog](
		[indexDefrag_id] [int] IDENTITY(1,1) NOT NULL,
		[databaseID] [int] NOT NULL,
		[databaseName] [nvarchar](128) NOT NULL,
		[objectID] [int] NOT NULL,
		[objectName] [nvarchar](128) NOT NULL,
		[indexID] [int] NOT NULL,
		[indexName] [nvarchar](128) NOT NULL,
		[partitionNumber] [smallint] NOT NULL,
		[fragmentation] [float] NOT NULL,
		[page_count] [int] NOT NULL,
		[dateTimeStart] [datetime] NOT NULL,
		[durationSeconds] [int] NOT NULL,
			 CONSTRAINT [PK_indexDefragLog] PRIMARY KEY CLUSTERED 
			(
				[indexDefrag_id] ASC
			)
	)
end

exec #TableExists 'dbo', 'DBMaint', @tableExists out
if (@tableExists = 0)
begin	
	CREATE TABLE [dbo].[DBMaint](
		[name] [varchar](100) NOT NULL,
		[status] [int] NULL,
		[issystem] [int] NULL,
		[isuser] [int] NULL,
		[Fullbackup] [int] NULL,
		[Diffbackup] [int] NULL,
		[Tranbackup] [int] NULL,
		[dbcc] [int] NULL,
		[reindex] [int] NULL,
		[indexdefrag] [int] NULL,
		[stats] [int] NULL,
		[notes] [varchar](1000) NULL,
		[cleanup] [smallint] NULL,
		[backupdirectory] [varchar](300) NULL,
		 CONSTRAINT [PK__DBMaint__03317E3D] PRIMARY KEY CLUSTERED 
		(
			[name] ASC
		)
	)
end

exec #ColumnExists 'dbo', 'DBMaint', 'cleanup', @columnExists out
if (@columnExists = 0)
begin
	alter table dbo.DBMaint 
		add cleanup smallint null
end

exec #ColumnExists 'dbo', 'DBMaint', 'backupdirectory', @columnExists out
if (@columnExists = 0)
begin
	alter table dbo.DBMaint 
		add backupdirectory varchar(300) null
end

exec #TableExists 'dbo', 'ErrorLog', @tableExists out
if (@tableExists = 0)
begin
	CREATE TABLE [dbo].[ErrorLog](
	[LogDate] [datetime] NULL,
	[ProcessInfo] [varchar](50) NULL,
	[Error] [varchar](7000) NULL
	) 
end

exec #TableExists 'dbo', 'EventLog', @tableExists out
if (@tableExists = 0)
begin
	CREATE TABLE [dbo].[EventLog](
	[ID] [int] NOT NULL,
	[Log] [varchar](500) NULL,
	[Source] [varchar](100) NULL,
	[Type] [varchar](50) NULL,
	[Server] [varchar](50) NULL,
	[Date] [datetime] NULL,
	[Error] [int] NULL,
	[Other] [varchar](100) NULL,
	[Message] [varchar](5000) NULL
	) 
end

exec #TableExists 'dbo', 'FragmentationLevels', @tableExists out
if (@tableExists = 0)
begin
	CREATE TABLE [dbo].[FragmentationLevels](
	[ServerName] [char](255) NULL,
	[DatabaseName] [char](255) NULL,
	[TableName] [char](255) NULL,
	[IndexName] [char](255) NULL,
	[CountPages] [int] NULL,
	[CountRows] [int] NULL,
	[MinRecSize] [int] NULL,
	[MaxRecSize] [int] NULL,
	[AvgRecSize] [int] NULL,
	[ForRecCount] [int] NULL,
	[Extents] [int] NULL,
	[AvgFreeBytes] [int] NULL,
	[AvgPageDensity] [int] NULL,
	[ScanDensity] [decimal](18, 0) NULL,
	[BestCount] [int] NULL,
	[ActualCount] [int] NULL,
	[LogicalFrag] [decimal](18, 0) NULL,
	[ExtentFrag] [decimal](18, 0) NULL,
	[DateTime] [datetime] NULL
	)

end

exec #TableExists 'dbo', 'Job_Failures', @tableExists out
if (@tableExists = 0)
begin
	CREATE TABLE [dbo].[Job_Failures](
	[Job_ID] [varchar](100) NULL,
	[Server] [varchar](50) NULL,
	[JobName] [varchar](100) NULL,
	[Step_ID] [smallint] NULL,
	[run_time] [smalldatetime] NULL,
	[running] [varchar](50) NULL
	) ON [PRIMARY]
end

exec #TableExists 'dbo', 'JobAnalysis', @tableExists out
if (@tableExists = 0)
begin
	CREATE TABLE [dbo].[JobAnalysis](
	[server] [nvarchar](50) NOT NULL,
	[jobname] [nvarchar](255) NOT NULL,
	[runstatus] [char](11) NOT NULL,
	[rundatetime] [datetime] NOT NULL,
	[dayofweek] [char](9) NOT NULL,
	[runtime] [char](8) NOT NULL,
	[duration_int] [int] NOT NULL,
	[duration_txt] [char](8) NOT NULL
	) 
end

exec #TableExists 'dbo', 'LocalDrives', @tableExists out
if (@tableExists = 0)
begin
	CREATE TABLE [dbo].[LocalDrives](
	[DriveLetter] [char](1) NOT NULL,
	[DriveName] [varchar](25) NULL
	) 
end

exec #TableExists 'dbo', 'loginstuff', @tableExists out
if (@tableExists = 0)
begin
	CREATE TABLE [dbo].[loginstuff](
	[Original_login] [varchar](20) NULL,
	[Effective_login] [varchar](20) NULL,
	[Db_user] [varchar](20) NULL
	) 
end

exec #TableExists 'dbo', 'PartitionLog', @tableExists out
if (@tableExists = 0)
begin
	CREATE TABLE [dbo].[PartitionLog](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[EntryDate] [datetime] NULL,
	[ObjectID] [bigint] NULL,
	[DateRangeSwitchedInt] [int] NULL,
	[DateRangeSwitchedDate] [smalldatetime] NULL,
	[RowCountSwitched] [bigint] NULL,
	[Success] [bit] NULL,
	[Comments] [varchar](500) NULL,
		 CONSTRAINT [PK__Partitio__3214EC27040737C6] PRIMARY KEY CLUSTERED 
		(
			[ID] ASC
		)
	) 
end

exec #TableExists 'dbo', 'PhysicalStats', @tableExists out
if (@tableExists = 0)
begin	
	CREATE TABLE [dbo].[PhysicalStats](
	[EntryDate] [datetime] NOT NULL,
	[database_id] [smallint] NULL,
	[object_id] [int] NULL,
	[index_id] [int] NULL,
	[partition_number] [int] NULL,
	[index_type_desc] [nvarchar](60) NULL,
	[alloc_unit_type_desc] [nvarchar](60) NULL,
	[index_depth] [tinyint] NULL,
	[index_level] [tinyint] NULL,
	[avg_fragmentation_in_percent] [float] NULL,
	[fragment_count] [bigint] NULL,
	[avg_fragment_size_in_pages] [float] NULL,
	[page_count] [bigint] NULL,
	[avg_page_space_used_in_percent] [float] NULL,
	[record_count] [bigint] NULL,
	[ghost_record_count] [bigint] NULL,
	[version_ghost_record_count] [bigint] NULL,
	[min_record_size_in_bytes] [int] NULL,
	[max_record_size_in_bytes] [int] NULL,
	[avg_record_size_in_bytes] [float] NULL,
	[forwarded_record_count] [bigint] NULL
	) 
end

exec #TableExists 'dbo', 'ProcPerfCacheCollection', @tableExists out
if (@tableExists = 0)
begin
	CREATE TABLE [dbo].[ProcPerfCacheCollection](
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

exec #TableExists 'dbo', 'ReindexHistory', @tableExists out
if (@tableExists = 0)
begin
	CREATE TABLE [dbo].[ReindexHistory](
		[DB] [varchar](100) NOT NULL,
		[TableName] [varchar](100) NOT NULL,
		[Index] [varchar](255) NULL,
		[Type] [int] NULL,
		[Clustered] [int] NOT NULL,
		[StartDateTime] [datetime] NOT NULL,
		[Seconds] [int] NOT NULL
	) 
end

exec #TableExists 'dbo', 'SSISLog', @tableExists out
if (@tableExists = 0)
begin
		CREATE TABLE [dbo].[SSISLog](
		[EventID] [int] IDENTITY(1,1) NOT NULL,
		[EventType] [varchar](20) NOT NULL,
		[PackageName] [varchar](50) NOT NULL,
		[TaskName] [varchar](50) NOT NULL,
		[EventCode] [int] NULL,
		[EventDescription] [varchar](1000) NULL,
		[PackageDuration] [int] NULL,
		[ContainerDuration] [int] NULL,
		[InsertCount] [int] NULL,
		[UpdateCount] [int] NULL,
		[DeleteCount] [int] NULL,
		[Host] [varchar](50) NULL,
		[EventDate] [datetime] NULL
	) 
	ALTER TABLE [dbo].[SSISLog] ADD [importpath] [varchar](100) NULL
	 CONSTRAINT [PK_SSISLog] PRIMARY KEY CLUSTERED 
	(
		[EventID] DESC
	)
end

exec #TableExists 'dbo', 'TableSizeLog', @tableExists out
if (@tableExists = 0)
begin
	CREATE TABLE [dbo].[TableSizeLog](
		[DB] [varchar](100) NOT NULL,
		[DateTime] [datetime] NOT NULL,
		[TableName] [varchar](100) NOT NULL,
		[Rows] [bigint] NOT NULL,
		[Reserved_kb] [bigint] NOT NULL,
		[Data_kb] [bigint] NOT NULL,
		[Index_size_kb] [bigint] NOT NULL,
		[Unused_kb] [bigint] NOT NULL,
		[Size_kb] [bigint] NOT NULL
	)
end

exec #TableExists 'dbo', 'UptimeHistory', @tableExists out
if (@tableExists = 0)
begin
	CREATE TABLE [dbo].[UptimeHistory](
	[ID] [int] IDENTITY(2,1) NOT NULL,
	[LastPoll] [datetime] NULL,
	[ServerStarted] [datetime] NULL,
	[Type] [varchar](50) NULL,
	[AffectedSystem] [varchar](50) NULL
	) 
end

exec #TableExists 'dbo', 'ActivityTable', @tableExists out

if (@tableExists = 0)
begin	
	CREATE TABLE [dbo].[ActivityTable](
		[RowNumber] [int] IDENTITY(0,1) NOT NULL,
		[EventClass] [int] NULL,
		[TextData] [ntext] NULL,
		[ApplicationName] [nvarchar](128) NULL,
		[NTUserName] [nvarchar](128) NULL,
		[LoginName] [nvarchar](128) NULL,
		[Duration] [bigint] NULL,
		[ClientProcessID] [int] NULL,
		[SPID] [int] NULL,
		[StartTime] [datetime] NULL,
		[EndTime] [datetime] NULL,
		[BinaryData] [image] NULL,
		[BigintData1] [bigint] NULL,
		[DatabaseID] [int] NULL,
		[DatabaseName] [nvarchar](128) NULL,
		[EventSequence] [bigint] NULL,
		[GroupID] [int] NULL,
		[HostName] [nvarchar](128) NULL,
		[IntegerData2] [int] NULL,
		[IsSystem] [int] NULL,
		[LoginSid] [image] NULL,
		[Mode] [int] NULL,
		[NTDomainName] [nvarchar](128) NULL,
		[ObjectID] [int] NULL,
		[ObjectID2] [bigint] NULL,
		[OwnerID] [int] NULL,
		[RequestID] [int] NULL,
		[ServerName] [nvarchar](128) NULL,
		[SessionLoginName] [nvarchar](128) NULL,
		[TransactionID] [bigint] NULL,
		[Type] [int] NULL,
		[Error] [int] NULL,
		[EventSubClass] [int] NULL,
		[State] [int] NULL,
		[Success] [int] NULL,
			PRIMARY KEY CLUSTERED 
			(
				[RowNumber] ASC
			)
	)
end

exec #TableExists 'dbo', 'AlertHistory', @tableExists out

if (@tableExists = 0)
begin
	CREATE TABLE [dbo].[AlertHistory](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Alert] [varchar](200) NOT NULL,
	[AlertDateTime] [datetime] NOT NULL,
	[Actioned] [bit] NULL
	)
end

go


GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO




 BEGIN TRY
      BEGIN TRANSACTION

	IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'archive')
	BEGIN
		EXEC ('CREATE SCHEMA archive;');
	END
	  
	 CREATE TABLE [dim].[DatabaseFiles](
		[DatabaseFilesKey] [int] IDENTITY(1,1) NOT NULL,
		[ServerName] [varchar](200) NOT NULL,
		[DatabaseName] [varchar](200) NOT NULL,
		[LogicalFileName] [varchar](255) NOT NULL,
		[PhysicalFileName] [varchar](255) NOT NULL,
		[MountPoint] [varchar](500) NOT NULL,
		[ApplicationArea] [varchar](500) NOT NULL,
		[StartDate] [datetime] NOT NULL,
		[EndDate] [datetime] NULL,
	PRIMARY KEY CLUSTERED 
	(
		[DatabaseFilesKey] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
	
	
	CREATE TABLE [dim].[Dates](
	[DateKey] [int] NOT NULL,
	[Date] [datetime] NULL,
	[FullDateUK] [char](10) NULL,
	[FullDateUSA] [char](10) NULL,
	[DayOfMonth] [varchar](2) NULL,
	[DaySuffix] [varchar](4) NULL,
	[DayName] [varchar](9) NULL,
	[DayOfWeekUSA] [char](1) NULL,
	[DayOfWeekUK] [char](1) NULL,
	[DayOfWeekInMonth] [varchar](2) NULL,
	[DayOfWeekInYear] [varchar](2) NULL,
	[DayOfQuarter] [varchar](3) NULL,
	[DayOfYear] [varchar](3) NULL,
	[WeekOfMonth] [varchar](1) NULL,
	[WeekOfQuarter] [varchar](2) NULL,
	[WeekOfYear] [varchar](2) NULL,
	[Month] [varchar](2) NULL,
	[MonthName] [varchar](9) NULL,
	[MonthOfQuarter] [varchar](2) NULL,
	[Quarter] [char](1) NULL,
	[QuarterName] [varchar](9) NULL,
	[Year] [char](4) NULL,
	[YearName] [char](7) NULL,
	[MonthYear] [char](10) NULL,
	[MMYYYY] [char](6) NULL,
	[FirstDayOfMonth] [date] NULL,
	[LastDayOfMonth] [date] NULL,
	[FirstDayOfQuarter] [date] NULL,
	[LastDayOfQuarter] [date] NULL,
	[FirstDayOfYear] [date] NULL,
	[LastDayOfYear] [date] NULL,
	[IsHolidayUSA] [bit] NULL,
	[IsWeekday] [bit] NULL,
	[HolidayUSA] [varchar](50) NULL,
	[IsHolidayUK] [bit] NULL,
	[HolidayUK] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[DateKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


CREATE TABLE [dim].[Instances](
	[InstanceKey] [int] IDENTITY(1,1) NOT NULL,
	[InstanceName] [varchar](128) NOT NULL,
	[VirtualServerName] [varchar](128) NOT NULL,
	[Clustered] [bit] NOT NULL,
	[Node] [varchar](128) NOT NULL,
	[Edition] [varchar](100) NOT NULL,
	[ProductLevel] [varchar](100) NOT NULL,
	[ProductVersion] [varchar](100) NOT NULL,
 CONSTRAINT [PK_DimInstances] PRIMARY KEY CLUSTERED 
(
	[InstanceKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


CREATE TABLE [dim].[PerfmonCounters](
	[PerfmonCounterKey] [int] IDENTITY(1,1) NOT NULL,
	[CounterGroup] [varchar](128) NOT NULL,
	[CounterName] [varchar](128) NOT NULL,
	[InstanceName] [varchar](128) NOT NULL,
	[Node] [varchar](63) NOT NULL,
	[VirtualServerName] [varchar](63) NOT NULL,
	[PerfmonInstance] [varchar](128) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[PerfmonCounterKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]



CREATE TABLE [dim].[Server](
	[ServerKey] [int] IDENTITY(1,1) NOT NULL,
	[Environment] [varchar](128) NOT NULL,
	[ServerName] [varchar](128) NOT NULL,
	[Node] [varchar](128) NOT NULL,
	[Startdate] [date] NOT NULL,
	[EndDate] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[ServerKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


CREATE TABLE [dim].[SqlCounters](
	[SqlCounterKey] [int] IDENTITY(1,1) NOT NULL,
	[InstanceName] [varchar](200) NULL,
	[SqlCounter] [varchar](200) NULL,
	[InstanceArea] [varchar](200) NULL,
	[Node] [varchar](128) NULL,
	[Category] [varchar](128) NULL,
	[Startdate] [date] NULL,
	[EndDate] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[SqlCounterKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

CREATE TABLE [dim].[StoredProcedures](
	[StoredProcedureKey] [int] IDENTITY(1,1) NOT NULL,
	[ProcedureName] [varchar](200) NOT NULL,
	[DatabaseName] [varchar](200) NOT NULL,
	[Instancename] [varchar](200) NOT NULL,
	[FriendlyInstanceName] [varchar](200) NOT NULL,
	[FriendlyHostName] [varchar](200) NOT NULL,
	[VirtualServerName] [varchar](200) NOT NULL,
	[QueryPlan] [xml] NULL,
	[QueryPlanCount] [int] NULL,
	[Node] [varchar](200) NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[StoredProcedureKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]


CREATE TABLE [dim].[Times](
	[TimeKey] [int] NOT NULL,
	[Time] [varchar](11) NOT NULL,
	[Time24] [varchar](8) NOT NULL,
	[HourName] [varchar](5) NOT NULL,
	[MinuteName] [varchar](8) NOT NULL,
	[HourNumber] [tinyint] NOT NULL,
	[Hour24] [tinyint] NOT NULL,
	[MinuteNumber] [tinyint] NOT NULL,
	[SecondNumber] [tinyint] NOT NULL,
	[AMPM] [char](2) NOT NULL,
	[ElapsedMinutes] [int] NOT NULL,
	[ElapsedSeconds] [int] NOT NULL,
 CONSTRAINT [PK_DimTime_TimeKey] PRIMARY KEY CLUSTERED 
(
	[TimeKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


CREATE TABLE [dim].[WaitStats](
	[WaitStatsKey] [int] IDENTITY(1,1) NOT NULL,
	[WaitStat] [nvarchar](200) NOT NULL,
	[Description] [varchar](4000) NULL,
PRIMARY KEY CLUSTERED 
(
	[WaitStatsKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


CREATE TABLE [dim].[WhoIsActive](
	[WhoKey] [int] IDENTITY(1,1) NOT NULL,
	[InstanceName] [varchar](128) NOT NULL,
	[ParentSqlText] [varchar](8000) NULL,
	[SqlText] [varchar](8000) NULL,
 CONSTRAINT [PK_DimWhoIsActive] PRIMARY KEY CLUSTERED 
(
	[WhoKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]



CREATE TABLE [fact].[CPU](
	[Captured] [datetime] NOT NULL,
	[DateKey] [int] NOT NULL,
	[TimeKey] [int] NOT NULL,
	[InstanceKey] [int] NOT NULL,
	[SqlServer] [tinyint] NOT NULL,
	[SystemIdle] [tinyint] NOT NULL,
	[Other] [float] NOT NULL
) ON PS_CPU([Captured])


CREATE TABLE [fact].[FileInfo](
	[Captured] [datetime] NOT NULL,
	[DateKey] [int] NOT NULL,
	[TimeKey] [int] NOT NULL,
	[InstanceKey] [int] NOT NULL,
	[DatabaseFileKey] [int] NOT NULL,
	[SizeMB] [decimal](18, 2) NOT NULL,
	[SpaceUsedMB] [decimal](18, 2) NOT NULL,
	[FreeSpaceMB] [decimal](18, 2) NOT NULL,
	[MaxSize] [decimal](18, 2) NOT NULL,
	[IsPercentGrowth] [bit] NOT NULL,
	[Growth] [decimal](18, 2) NOT NULL
) ON [PS_FileInfo]([Captured])


CREATE TABLE [fact].[PerfmonCounters](
	[Captured] [datetime] NOT NULL,
	[DateKey] [int] NOT NULL,
	[TimeKey] [int] NOT NULL,
	[PerfmonCounterKey] [int] NOT NULL,
	[InstanceKey] [int] NOT NULL,
	[Value] [float] NOT NULL
) ON [PS_PerfmonCounters]([Captured])


CREATE TABLE [fact].[SQLCounters](
	[Captured] [datetime] NOT NULL,
	[DateKey] [int] NOT NULL,
	[TimeKey] [int] NOT NULL,
	[SqlCounterKey] [int] NOT NULL,
	[InstanceKey] [int] NOT NULL,
	[Value] [float] NOT NULL
) ON [PS_SQLCounters]([Captured])


CREATE TABLE [fact].[StoredProcedures](
	[Captured] [datetime] NOT NULL,
	[DateKey] [int] NOT NULL,
	[TimeKey] [int] NOT NULL,
	[StoredProcedureKey] [int] NOT NULL,
	[ExecutionCount] [int] NOT NULL,
	[TotalWorkerTime] [bigint] NOT NULL,
	[TotalPhysicalReads] [bigint] NOT NULL,
	[TotalLogicalReads] [bigint] NOT NULL,
	[TotalLogicalWrites] [bigint] NOT NULL,
	[TotalElapsedTime] [bigint] NOT NULL,
	[PullPeriod] [int] NOT NULL
) ON [PS_StoredProcedures]([Captured])


CREATE TABLE [fact].[VirtualFileStats](
	[Captured] [datetime] NOT NULL,
	[DateKey] [int] NULL,
	[TimeKey] [int] NULL,
	[FileKey] [int] NULL,
	[InstanceKey] [int] NULL,
	[MsPerRead] [float] NULL,
	[MsPerWrite] [float] NULL,
	[IoStallRead] [int] NULL,
	[IoStallWrite] [int] NULL,
	[NumOfReads] [int] NULL,
	[NumOfWrites] [int] NULL,
	[NumOfBytesWritten] [bigint] NULL,
	[PullPeriod] [int] NULL
) ON [PS_VirtualFileStats]([Captured])

CREATE TABLE [fact].[WaitStats](
	[Captured] [datetime] NOT NULL,
	[DateKey] [int] NOT NULL,
	[TimeKey] [int] NOT NULL,
	[WaitStatsKey] [int] NOT NULL,
	[InstanceKey] [int] NOT NULL,
	[WaitMs] [int] NOT NULL,
	[ResourceMs] [int] NOT NULL,
	[WaitCount] [int] NOT NULL,
	[DifferentialMins] [int] NOT NULL
) ON [PS_WaitStats]([Captured])



CREATE TABLE [fact].[WhoIsActive](
	[Captured] [datetime] NOT NULL,
	[DateKey] [int] NOT NULL,
	[TimeKey] [int] NOT NULL,
	[InstanceKey] [int] NOT NULL,
	[WhoKey] [int] NOT NULL,
	[cnt] [int] NULL,
	[max_cpu] [money] NULL,
	[max_tempdb] [money] NULL,
	[reads] [money] NULL,
	[writes] [money] NULL,
	[physical_reads] [money] NULL,
	[BlockedSessionCount] [int] NULL,
	[max_avg_time] [varchar](100) NULL,
	[max_time] [varchar](100) NULL,
	[database_name] [varchar](256) NULL
) ON [PS_WhoIsActive]([Captured])



CREATE TABLE [archive].[CPU](
	[Captured] [datetime] NOT NULL,
	[DateKey] [int] NOT NULL,
	[TimeKey] [int] NOT NULL,
	[InstanceKey] [int] NOT NULL,
	[SqlServer] [tinyint] NOT NULL,
	[SystemIdle] [tinyint] NOT NULL,
	[Other] [float] NOT NULL
) ON PS_CPU([Captured])


CREATE TABLE [archive].[FileInfo](
	[Captured] [datetime] NOT NULL,
	[DateKey] [int] NOT NULL,
	[TimeKey] [int] NOT NULL,
	[InstanceKey] [int] NOT NULL,
	[DatabaseFileKey] [int] NOT NULL,
	[SizeMB] [decimal](18, 2) NOT NULL,
	[SpaceUsedMB] [decimal](18, 2) NOT NULL,
	[FreeSpaceMB] [decimal](18, 2) NOT NULL,
	[MaxSize] [decimal](18, 2) NOT NULL,
	[IsPercentGrowth] [bit] NOT NULL,
	[Growth] [decimal](18, 2) NOT NULL
) ON [PS_FileInfo]([Captured])


CREATE TABLE [archive].[PerfmonCounters](
	[Captured] [datetime] NOT NULL,
	[DateKey] [int] NOT NULL,
	[TimeKey] [int] NOT NULL,
	[PerfmonCounterKey] [int] NOT NULL,
	[InstanceKey] [int] NOT NULL,
	[Value] [float] NOT NULL
) ON [PS_PerfmonCounters]([Captured])


CREATE TABLE [archive].[SQLCounters](
	[Captured] [datetime] NOT NULL,
	[DateKey] [int] NOT NULL,
	[TimeKey] [int] NOT NULL,
	[SqlCounterKey] [int] NOT NULL,
	[InstanceKey] [int] NOT NULL,
	[Value] [float] NOT NULL
) ON [PS_SQLCounters]([Captured])


CREATE TABLE [archive].[StoredProcedures](
	[Captured] [datetime] NOT NULL,
	[DateKey] [int] NOT NULL,
	[TimeKey] [int] NOT NULL,
	[StoredProcedureKey] [int] NOT NULL,
	[ExecutionCount] [int] NOT NULL,
	[TotalWorkerTime] [bigint] NOT NULL,
	[TotalPhysicalReads] [bigint] NOT NULL,
	[TotalLogicalReads] [bigint] NOT NULL,
	[TotalLogicalWrites] [bigint] NOT NULL,
	[TotalElapsedTime] [bigint] NOT NULL,
	[PullPeriod] [int] NOT NULL
) ON [PS_StoredProcedures]([Captured])


CREATE TABLE [archive].[VirtualFileStats](
	[Captured] [datetime] NOT NULL,
	[DateKey] [int] NULL,
	[TimeKey] [int] NULL,
	[FileKey] [int] NULL,
	[InstanceKey] [int] NULL,
	[MsPerRead] [float] NULL,
	[MsPerWrite] [float] NULL,
	[IoStallRead] [int] NULL,
	[IoStallWrite] [int] NULL,
	[NumOfReads] [int] NULL,
	[NumOfWrites] [int] NULL,
	[NumOfBytesWritten] [bigint] NULL,
	[PullPeriod] [int] NULL
) ON [PS_VirtualFileStats]([Captured])

CREATE TABLE [archive].[WaitStats](
	[Captured] [datetime] NOT NULL,
	[DateKey] [int] NOT NULL,
	[TimeKey] [int] NOT NULL,
	[WaitStatsKey] [int] NOT NULL,
	[InstanceKey] [int] NOT NULL,
	[WaitMs] [int] NOT NULL,
	[ResourceMs] [int] NOT NULL,
	[WaitCount] [int] NOT NULL,
	[DifferentialMins] [int] NOT NULL
) ON [PS_WaitStats]([Captured])



CREATE TABLE [archive].[WhoIsActive](
	[Captured] [datetime] NOT NULL,
	[DateKey] [int] NOT NULL,
	[TimeKey] [int] NOT NULL,
	[InstanceKey] [int] NOT NULL,
	[WhoKey] [int] NOT NULL,
	[cnt] [int] NULL,
	[max_cpu] [money] NULL,
	[max_tempdb] [money] NULL,
	[reads] [money] NULL,
	[writes] [money] NULL,
	[physical_reads] [money] NULL,
	[BlockedSessionCount] [int] NULL,
	[max_avg_time] [varchar](100) NULL,
	[max_time] [varchar](100) NULL,
	[database_name] [varchar](256) NULL
) ON [PS_WhoIsActive]([Captured])
	

	
      COMMIT TRANSACTION
   END TRY
   BEGIN CATCH
       IF @@trancount > 0 ROLLBACK TRANSACTION
      
      ;THROW
      
   END CATCH
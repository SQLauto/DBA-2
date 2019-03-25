GO

/****** Object:  StoredProcedure [dbo].[PerfDataProcess]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PerfDataProcess]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
create proc [dbo].[PerfDataProcess]
as
begin
	/*
		create table #PerfData
		(
			ServerName nvarchar(63) not null,
			ObjectName nvarchar(128) not null,
			CounterName nvarchar(128) not null,
			InstanceName nvarchar(128) null default '''',
			CounterValue decimal(18,5) null,
			SampleTime datetimeoffset not null
		)
	*/

	if (object_id(''tempdb..#PerfData'') is null)
	begin
		raiserror(''dbo.PerfDataProcess has been invoked and there is no temp table #PerfData'', 16, 1)
	end

	if not exists (select top 1 1 from #PerfData)
	begin
		raiserror(''dbo.PerfDataProcess has been invoked and the temp table #PerfData has no data'', 16, 1)
	end

	update #PerfData
	set 
		InstanceName = ''''
	where 
		InstanceName is null

	insert into dbo.PerfServer (ServerName)
		select distinct ServerName from #PerfData
	except 
		select ServerName from dbo.PerfServer

	insert into dbo.PerfCounter (ObjectName, CounterName, InstanceName)
		select distinct ObjectName, CounterName, InstanceName from #PerfData
	except
		select ObjectName, CounterName, InstanceName from dbo.PerfCounter

	insert into dbo.PerfData (PerfServerId, PerfCounterId, SampleTime, CounterValue)
	select 
		ps.Id,
		pc.Id,
		pd.SampleTime,
		pd.CounterValue
	from 
		#PerfData pd
	inner join dbo.PerfServer ps on
		ps.ServerName = pd.ServerName
	inner join dbo.PerfCounter pc on
		pc.ObjectName = pd.ObjectName and
		pc.CounterName = pd.CounterName and 
		pc.InstanceName = pd.InstanceName


	drop table #PerfData

end

' 
END
GO
/****** Object:  StoredProcedure [dbo].[usp_CollectDiskLatency]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_CollectDiskLatency]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'  
CREATE PROCEDURE [dbo].[usp_CollectDiskLatency] 
    -- Add the parameters for the stored procedure here 
    @WaitTimeSec INT = 60, 
    @StopTime DATETIME = NULL 
AS 
BEGIN 
  
    DECLARE @CaptureDataID int 
    /* Check that stopdate is greater than current time. If not, throw error! */ 
  
    /* If temp tables exist drop them. */ 
    IF OBJECT_ID(''tempdb..#IOStallSnapshot'') IS NOT NULL 
    BEGIN 
        DROP TABLE #IOStallSnapshot 
    END 
  
    IF OBJECT_ID(''tempdb..#IOStallResult'') IS NOT NULL 
    BEGIN 
        DROP TABLE #IOStallResult 
    END 
  
    /* Create temp tables for capture baseline */ 
    CREATE TABLE #IOStallSnapshot( 
    CaptureDate datetime, 
    read_per_ms float, 
    write_per_ms float, 
    num_of_bytes_written bigint, 
    num_of_reads bigint, 
    num_of_writes bigint, 
    database_id int, 
    file_id int 
    ) 
  
    CREATE TABLE #IOStallResult( 
    CaptureDate datetime, 
    read_per_ms float, 
    write_per_ms float, 
    num_of_bytes_written bigint, 
    num_of_reads bigint, 
    num_of_writes bigint, 
    database_id int, 
    file_id int 
    ) 
  
    DECLARE @ServerName varchar(300) 
    SELECT @ServerName = convert(nvarchar(128), serverproperty(''servername'')) 
  
    /* Insert master record for capture data */ 
    INSERT INTO dbo.CaptureData (StartTime, EndTime, ServerName,PullPeriod) 
    VALUES (GETDATE(), NULL, @ServerName, @WaitTimeSec) 
  
    SELECT @CaptureDataID = SCOPE_IDENTITY() 
  
    /* Do lookup to get property data for all database files to catch any new ones if they exist */ 
    INSERT INTO dbo.DatabaseFiles ([ServerName],[DatabaseName],[LogicalFileName],[Database_ID],[File_ID]) 
    SELECT @ServerName, DB_NAME(database_id), name, database_id, [FILE_ID] 
    FROM sys.master_files mf 
    WHERE NOT EXISTS 
    ( 
        SELECT 1 
        FROM dbo.DatabaseFiles df 
        WHERE df.Database_ID = mf.database_id AND df.[File_ID] = mf.[File_ID] 
    ) 
  
    /* Loop through until time expires  */ 
    IF @StopTime IS NULL 
        SET @StopTime = DATEADD(hh, 1, getdate()) 
    WHILE GETDATE() < @StopTime 
    BEGIN 
  
    /* Get baseline snapshot of stalls */ 
        INSERT INTO #IOStallSnapshot (CaptureDate, 
        read_per_ms, 
        write_per_ms, 
        num_of_bytes_written, 
        num_of_reads, 
        num_of_writes, 
        database_id, 
        [file_id]) 
        SELECT getdate(), 
            a.io_stall_read_ms, 
            a.io_stall_write_ms, 
            a.num_of_bytes_written, 
            a.num_of_reads, 
            a.num_of_writes, 
            a.database_id, 
            a.file_id 
        FROM sys.dm_io_virtual_file_stats (NULL, NULL) a 
        JOIN sys.master_files b ON a.file_id = b.file_id 
        AND a.database_id = b.database_id 
  
        /* Wait a few minutes and get final snapshot */ 
        WAITFOR DELAY @WaitTimeSec 
  
        INSERT INTO #IOStallResult (CaptureDate, 
            read_per_ms, 
            write_per_ms, 
            num_of_bytes_written, 
            num_of_reads, 
            num_of_writes, 
            database_id, 
            [file_id]) 
        SELECT getdate(), 
            a.io_stall_read_ms, 
            a.io_stall_write_ms, 
            a.num_of_bytes_written, 
            a.num_of_reads, 
            a.num_of_writes, 
            a.database_id, 
            a.file_id 
        FROM sys.dm_io_virtual_file_stats (NULL, NULL) a 
        JOIN sys.master_files b ON a.file_id = b.file_id 
        AND a.database_id = b.database_id 
  
        INSERT INTO dbo.CaptureResults (CaptureDataID, 
            CaptureDate, 
            read_per_ms, 
            write_per_ms, 
            io_stall_read, 
            io_stall_write, 
            num_of_reads, 
            num_of_writes, 
            num_of_bytes_written, 
            database_id, 
            [file_id]) 
        SELECT @CaptureDataID 
            ,inline.CaptureDate 
            ,CASE WHEN inline.num_of_reads =0 THEN 0 ELSE inline.io_stall_read_ms / inline.num_of_reads END AS read_per_ms 
            ,CASE WHEN inline.num_of_writes = 0 THEN 0 ELSE inline.io_stall_write_ms / inline.num_of_writes END AS write_per_ms 
            ,inline.io_stall_read_ms 
            ,inline.io_stall_write_ms 
            ,inline.num_of_reads 
            ,inline.num_of_writes 
            ,inline.num_of_bytes_written 
            ,inline.database_id 
            ,inline.[file_id] 
        FROM ( 
        SELECT  r.CaptureDate 
                ,r.read_per_ms - s.read_per_ms AS io_stall_read_ms 
                ,r.num_of_reads - s.num_of_reads AS num_of_reads 
                ,r.write_per_ms - s.write_per_ms AS io_stall_write_ms 
                ,r.num_of_writes - s.num_of_writes AS num_of_writes 
                ,r.num_of_bytes_written - s.num_of_bytes_written AS num_of_bytes_written 
                ,r.database_id AS database_id 
                ,r.[file_id] AS [file_id] 
  
        FROM #IOStallSnapshot s 
             INNER JOIN #IOStallResult r ON (s.database_id = r.database_id and s.file_id = r.file_id) 
        ) inline 
  
        TRUNCATE TABLE #IOStallSnapshot 
        TRUNCATE TABLE #IOStallResult 
 END -- END of WHILE 
  
 /* Update Capture Data meta-data to include end time */ 
 UPDATE dbo.CaptureData 
 SET EndTime = GETDATE() 
 WHERE ID = @CaptureDataID 
  
END 

' 
END
GO
/****** Object:  StoredProcedure [dbo].[usp_GET_OS_WAITS_STATS]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_GET_OS_WAITS_STATS]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'


CREATE PROCEDURE [dbo].[usp_GET_OS_WAITS_STATS] AS

WITH Waits AS
(SELECT wait_type, wait_time_ms / 1000. AS wait_time_s,
100. * wait_time_ms / SUM(wait_time_ms) OVER() AS pct,
ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS rn
FROM sys.dm_os_wait_stats WITH (NOLOCK)
WHERE wait_type NOT IN (N''CLR_SEMAPHORE'',N''LAZYWRITER_SLEEP'',N''RESOURCE_QUEUE'',
N''SLEEP_TASK'',N''SLEEP_SYSTEMTASK'',N''SQLTRACE_BUFFER_FLUSH'',N''WAITFOR'', 
N''LOGMGR_QUEUE'',N''CHECKPOINT_QUEUE'', N''REQUEST_FOR_DEADLOCK_SEARCH'',
N''XE_TIMER_EVENT'',N''BROKER_TO_FLUSH'',N''BROKER_TASK_STOP'',N''CLR_MANUAL_EVENT'',
N''CLR_AUTO_EVENT'',N''DISPATCHER_QUEUE_SEMAPHORE'', N''FT_IFTS_SCHEDULER_IDLE_WAIT'',
N''XE_DISPATCHER_WAIT'', N''XE_DISPATCHER_JOIN'', N''SQLTRACE_INCREMENTAL_FLUSH_SLEEP'',
N''ONDEMAND_TASK_QUEUE'', N''BROKER_EVENTHANDLER'', N''SLEEP_BPOOL_FLUSH'',
N''DIRTY_PAGE_POLL'', N''HADR_FILESTREAM_IOMGR_IOCOMPLETION'', N''SP_SERVER_DIAGNOSTICS_SLEEP''))

INSERT INTO [dbo].[OS_WAIT_STATS]
           ([AsAt]
           ,[wait_type]
           ,[wait_time_s]
           ,[pct]
           ,[running_pct])
SELECT GETDATE() AS AsAt, W1.wait_type, 
CAST(W1.wait_time_s AS DECIMAL(12, 2)) AS wait_time_s,
CAST(W1.pct AS DECIMAL(12, 2)) AS pct,
CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct
FROM Waits AS W1
INNER JOIN Waits AS W2
ON W2.rn <= W1.rn
GROUP BY W1.rn, W1.wait_type, W1.wait_time_s, W1.pct
HAVING SUM(W2.pct) - W1.pct < 99 OPTION (RECOMPILE); -- percentage threshold

DELETE FROM [dbo].[OS_WAIT_STATS]
WHERE AsAt < DATEADD(month,-3,GETDATE())


' 
END
GO
/****** Object:  StoredProcedure [dbo].[usp_InsertPerfmonCounter]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_InsertPerfmonCounter]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'



CREATE PROCEDURE [dbo].[usp_InsertPerfmonCounter]

(

  @xmlString varchar(max)

)

AS

SET NOCOUNT ON;

  

DECLARE @xml xml;

SET @xml = @xmlString;

  

INSERT INTO [dbo].[PerfmonCounterData] ([TimeStamp], [Server], [CounterGroup], [CounterName], [CounterValue])

SELECT CONVERT(datetime2,[Timestamp],103) 

 , SUBSTRING([Path], 3, CHARINDEX(''\'',[Path],3)-3) AS [Server]

 , SUBSTRING([Path]

      , CHARINDEX(''\'',[Path],3)+1

      , LEN([Path]) - CHARINDEX(''\'',REVERSE([Path]))+1 - (CHARINDEX(''\'',[Path],3)+1)) AS [CounterGroup]

 , REVERSE(LEFT(REVERSE([Path]), CHARINDEX(''\'', REVERSE([Path]))-1)) AS [CounterName]

 , CAST([CookedValue] AS float) AS [CookedValue]

FROM

    (SELECT

        [property].value(''(./text())[1]'', ''VARCHAR(200)'') AS [Value]

        , [property].value(''@Name'', ''VARCHAR(30)'') AS [Attribute]

        , DENSE_RANK() OVER (ORDER BY [object]) AS [Sampling]

    FROM @xml.nodes(''Objects/Object'') AS mn ([object])

    CROSS APPLY mn.object.nodes(''./Property'') AS pn (property)) AS bp

PIVOT (MAX(value) FOR Attribute IN ([Timestamp], [Path], [CookedValue]) ) AS ap;


' 
END
GO
/****** Object:  StoredProcedure [dbo].[usp_PerfMonReport]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_PerfMonReport]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[usp_PerfMonReport]
    (
      @Counter NVARCHAR(128) = N''%''
    )
AS 
    BEGIN;
        SELECT  *
        FROM    [dbo].[PerfMonData]
        WHERE   [Counter] LIKE @Counter
        ORDER BY [Counter] ,
                [CaptureDate]
    END;

' 
END
GO
/****** Object:  StoredProcedure [dbo].[usp_PurgeOldData]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_PurgeOldData]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
CREATE PROCEDURE [dbo].[usp_PurgeOldData]
    (
      @PurgeConfig SMALLINT ,
      @PurgeCounters SMALLINT
    )
AS 
    BEGIN;
        IF @PurgeConfig IS NULL
            OR @PurgeCounters IS NULL 
            BEGIN;
                RAISERROR(N''Input parameters cannot be NULL'', 16, 1);
                RETURN;
            END;
        DELETE  FROM [dbo].[ConfigData]
        WHERE   [CaptureDate] < GETDATE() - @PurgeConfig;

        DELETE  FROM [dbo].[ServerConfig]
        WHERE   [CaptureDate] < GETDATE() - @PurgeConfig;

        DELETE  FROM [dbo].[PerfMonData]
        WHERE   [CaptureDate] < GETDATE() - @PurgeCounters;
    END;


' 
END
GO
/****** Object:  StoredProcedure [dbo].[usp_ServerConfigReport]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_ServerConfigReport]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
CREATE PROCEDURE [dbo].[usp_ServerConfigReport]
    (
      @Property NVARCHAR(128) = NULL
    )
AS 
    BEGIN;
        IF @Property NOT IN ( N''ComputerNamePhysicalNetBios'',
                              N''DBCC_TRACESTATUS'', N''Edition'',
                              N''InstanceName'',
                              N''IsClustered'', N''MachineName'',
                              N''ProcessorNameString'', N''ProductLevel'',
                              N''ProductVersion'', N''ServerName'' ) 
            BEGIN;
                RAISERROR(N''Valid values for @Property are:
                            ComputerNamePhysicalNetBios, DBCC_TRACESTATUS,
                            Edition, InstanceName, IsClustered,
                            MachineName, ProcessorNameString,
                            ProductLevel, ProductVersion, or ServerName'',
                         16, 1);
                RETURN;
            END;

        SELECT  *
        FROM    [dbo].[ServerConfig]
        WHERE   [Property] = ISNULL(@Property, Property)
        ORDER BY [Property] ,
                [CaptureDate]
    END;

' 
END
GO
/****** Object:  StoredProcedure [dbo].[usp_SysConfigReport]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_SysConfigReport]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
CREATE PROCEDURE [dbo].[usp_SysConfigReport]
    (
      @OlderDate DATETIME ,
      @RecentDate DATETIME
    )
AS 
    BEGIN;

        IF @RecentDate IS NULL
            OR @OlderDate IS NULL 
            BEGIN;
                RAISERROR(N''Input parameters cannot be NULL'', 16, 1);
                RETURN;
            END;

        SELECT  [O].[Name] ,
                [O].[Value] AS "OlderValue" ,
                [O].[ValueInUse] AS "OlderValueInUse" ,
                [R].[Value] AS "RecentValue" ,
                [R].[ValueInUse] AS "RecentValueInUse"
        FROM    [dbo].[ConfigData] O
                JOIN ( SELECT   [ConfigurationID] ,
                                [Value] ,
                                [ValueInUse]
                       FROM     [dbo].[ConfigData]
                       WHERE    [CaptureDate] = @RecentDate
                     ) R ON [O].[ConfigurationID] = [R].[ConfigurationID]
        WHERE   [O].[CaptureDate] = @OlderDate
                AND ( ( [R].[Value] <> [O].[Value] )
                      OR ( [R].[ValueInUse] <> [O].[ValueInUse] )
                    )
    END;

' 
END
GO
/****** Object:  Table [dbo].[CaptureData]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CaptureData]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[CaptureData](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[ServerName] [varchar](500) NULL,
	[PullPeriod] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CaptureResults]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CaptureResults]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[CaptureResults](
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
	[iops]  AS ([num_of_reads]+[num_of_writes])
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[ConfigData]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ConfigData]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[ConfigData](
	[ConfigurationID] [int] NOT NULL,
	[Name] [nvarchar](35) NOT NULL,
	[Value] [sql_variant] NULL,
	[ValueInUse] [sql_variant] NULL,
	[CaptureDate] [datetime] NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[DatabaseFiles]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DatabaseFiles]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DatabaseFiles](
	[ServerName] [varchar](500) NULL,
	[DatabaseName] [varchar](500) NULL,
	[LogicalFileName] [varchar](500) NULL,
	[Database_ID] [int] NULL,
	[File_ID] [int] NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[FileInfo]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FileInfo]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[FileInfo](
	[DatabaseName] [sysname] NOT NULL,
	[FileID] [int] NOT NULL,
	[Type] [tinyint] NOT NULL,
	[DriveLetter] [nvarchar](1) NULL,
	[LogicalFileName] [sysname] NOT NULL,
	[PhysicalFileName] [nvarchar](260) NOT NULL,
	[SizeMB] [decimal](38, 2) NULL,
	[SpaceUsedMB] [decimal](38, 2) NULL,
	[FreeSpaceMB] [decimal](38, 2) NULL,
	[MaxSize] [decimal](38, 2) NULL,
	[IsPercentGrowth] [bit] NULL,
	[Growth] [decimal](38, 2) NULL,
	[CaptureDate] [datetime] NOT NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[MonitoredInstances]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MonitoredInstances]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[MonitoredInstances](
	[InstanceName] [varchar](100) NULL,
	[Clustered] [bit] NULL,
	[FriendlyInstanceName] [varchar](100) NULL,
	[friendlyHostName] [varchar](100) NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[OS_WAIT_STATS]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[OS_WAIT_STATS]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[OS_WAIT_STATS](
	[AsAt] [datetime] NOT NULL,
	[wait_type] [nvarchar](60) NOT NULL,
	[wait_time_s] [decimal](12, 2) NULL,
	[pct] [decimal](12, 2) NULL,
	[running_pct] [decimal](12, 2) NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[PerfAlertThreshold]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PerfAlertThreshold]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[PerfAlertThreshold](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PerfServerId] [tinyint] NOT NULL,
	[PerfCounterId] [int] NOT NULL,
	[Threshold] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [pk_PerfAlertThreshold_id] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[PerfAlertThresholdType]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PerfAlertThresholdType]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[PerfAlertThresholdType](
	[Id] [bigint] NOT NULL,
	[ThresholdType] [varchar](50) NOT NULL,
	[CreatedAt] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [pk_PerfAlertThresholdType_id] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [unq_PerfAlertThreshold_ThresholdType] UNIQUE NONCLUSTERED 
(
	[ThresholdType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PerfCounter]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PerfCounter]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[PerfCounter](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ObjectName] [nvarchar](128) NOT NULL,
	[CounterName] [nvarchar](128) NOT NULL,
	[InstanceName] [nvarchar](128) NOT NULL CONSTRAINT [df_PerfCounter_InstanceName]  DEFAULT (''),
	[CreatedAt] [datetimeoffset](7) NOT NULL CONSTRAINT [df_PerfCounter_CreatedAt]  DEFAULT (sysdatetimeoffset()),
 CONSTRAINT [pk_PerfCounter_Id] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[PerfData]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PerfData]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[PerfData](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PerfServerId] [tinyint] NOT NULL,
	[PerfCounterId] [int] NOT NULL,
	[SampleTime] [datetimeoffset](7) NOT NULL,
	[CounterValue] [decimal](18, 5) NULL,
 CONSTRAINT [pk_PerfData_id] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[PerfmonAlertThresholds]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PerfmonAlertThresholds]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[PerfmonAlertThresholds](
	[server] [nvarchar](50) NOT NULL,
	[countergroup] [varchar](200) NULL,
	[countername] [varchar](200) NOT NULL,
	[threshold] [int] NOT NULL,
	[thresholdType] [varchar](50) NULL,
	[alerts] [bit] NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PerfmonAlertThresholds_bkup]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PerfmonAlertThresholds_bkup]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[PerfmonAlertThresholds_bkup](
	[server] [nvarchar](50) NOT NULL,
	[countergroup] [varchar](200) NULL,
	[countername] [varchar](200) NOT NULL,
	[threshold] [int] NOT NULL,
	[thresholdType] [varchar](50) NULL,
	[alerts] [bit] NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PerfmonCounterData]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PerfmonCounterData]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[PerfmonCounterData](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Server] [nvarchar](50) NOT NULL,
	[TimeStamp] [datetime2](0) NOT NULL,
	[CounterGroup] [varchar](200) NULL,
	[CounterName] [varchar](200) NOT NULL,
	[CounterValue] [decimal](18, 5) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PerfMonData]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PerfMonData]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[PerfMonData](
	[Counter] [nvarchar](770) NULL,
	[Value] [decimal](38, 2) NULL,
	[CaptureDate] [datetime] NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[PerformAlertThreasholds]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PerformAlertThreasholds]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[PerformAlertThreasholds](
	[server] [varchar](100) NULL,
	[countergroup] [varchar](100) NULL,
	[countername] [varchar](100) NULL,
	[threshold] [varchar](100) NULL,
	[thresholdType] [varchar](100) NULL,
	[alerts] [varchar](100) NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PerformAlertThreasholdsTab]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PerformAlertThreasholdsTab]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[PerformAlertThreasholdsTab](
	[server] [varchar](50) NULL,
	[countergroup] [varchar](50) NULL,
	[countername] [varchar](50) NULL,
	[threshold] [varchar](50) NULL,
	[thresholdType] [varchar](50) NULL,
	[alerts] [varchar](50) NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PerfServer]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PerfServer]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[PerfServer](
	[Id] [tinyint] IDENTITY(1,1) NOT NULL,
	[ServerName] [nvarchar](63) NOT NULL,
	[CreatedAt] [datetimeoffset](7) NOT NULL CONSTRAINT [df_PerfServer_CreatedAt]  DEFAULT (sysdatetimeoffset()),
 CONSTRAINT [pk_PerfServer_Id] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [unq_PerfServer_ServerName] UNIQUE NONCLUSTERED 
(
	[ServerName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[ServerConfig]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ServerConfig]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[ServerConfig](
	[Property] [nvarchar](128) NULL,
	[Value] [sql_variant] NULL,
	[CaptureDate] [datetime] NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[table_size]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[table_size]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[table_size](
	[database] [nvarchar](128) NULL,
	[schema] [sysname] NOT NULL,
	[table] [sysname] NOT NULL,
	[row_count] [bigint] NULL,
	[reserved_MB] [bigint] NULL,
	[data_MB] [bigint] NULL,
	[index_size_MB] [bigint] NULL,
	[unused_MB] [bigint] NULL,
	[AsAt] [datetime] NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[WaitStats]    Script Date: 16/11/2016 13:56:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[WaitStats]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[WaitStats](
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
) ON [PRIMARY]
END
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [Unq_PerfCounter]    Script Date: 16/11/2016 13:56:02 ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[PerfCounter]') AND name = N'Unq_PerfCounter')
CREATE UNIQUE CLUSTERED INDEX [Unq_PerfCounter] ON [dbo].[PerfCounter]
(
	[ObjectName] ASC,
	[CounterName] ASC,
	[InstanceName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_1]    Script Date: 16/11/2016 13:56:02 ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[OS_WAIT_STATS]') AND name = N'IX_1')
CREATE NONCLUSTERED INDEX [IX_1] ON [dbo].[OS_WAIT_STATS]
(
	[AsAt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[df_PerfAlertThreshold_IsActive]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[PerfAlertThreshold] ADD  CONSTRAINT [df_PerfAlertThreshold_IsActive]  DEFAULT ((1)) FOR [IsActive]
END

GO
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[df_PerfAlertThresholdType_CreatedAt]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[PerfAlertThresholdType] ADD  CONSTRAINT [df_PerfAlertThresholdType_CreatedAt]  DEFAULT (sysdatetimeoffset()) FOR [CreatedAt]
END

GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_CaptureResults_CaptureData]') AND parent_object_id = OBJECT_ID(N'[dbo].[CaptureResults]'))
ALTER TABLE [dbo].[CaptureResults]  WITH CHECK ADD  CONSTRAINT [FK_CaptureResults_CaptureData] FOREIGN KEY([CaptureDataID])
REFERENCES [dbo].[CaptureData] ([ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_CaptureResults_CaptureData]') AND parent_object_id = OBJECT_ID(N'[dbo].[CaptureResults]'))
ALTER TABLE [dbo].[CaptureResults] CHECK CONSTRAINT [FK_CaptureResults_CaptureData]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[fk_PerfAlertThreshold_PerfCounterId]') AND parent_object_id = OBJECT_ID(N'[dbo].[PerfAlertThreshold]'))
ALTER TABLE [dbo].[PerfAlertThreshold]  WITH CHECK ADD  CONSTRAINT [fk_PerfAlertThreshold_PerfCounterId] FOREIGN KEY([PerfCounterId])
REFERENCES [dbo].[PerfCounter] ([Id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[fk_PerfAlertThreshold_PerfCounterId]') AND parent_object_id = OBJECT_ID(N'[dbo].[PerfAlertThreshold]'))
ALTER TABLE [dbo].[PerfAlertThreshold] CHECK CONSTRAINT [fk_PerfAlertThreshold_PerfCounterId]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[fk_PerfAlertThreshold_PerfServerId]') AND parent_object_id = OBJECT_ID(N'[dbo].[PerfAlertThreshold]'))
ALTER TABLE [dbo].[PerfAlertThreshold]  WITH CHECK ADD  CONSTRAINT [fk_PerfAlertThreshold_PerfServerId] FOREIGN KEY([PerfServerId])
REFERENCES [dbo].[PerfServer] ([Id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[fk_PerfAlertThreshold_PerfServerId]') AND parent_object_id = OBJECT_ID(N'[dbo].[PerfAlertThreshold]'))
ALTER TABLE [dbo].[PerfAlertThreshold] CHECK CONSTRAINT [fk_PerfAlertThreshold_PerfServerId]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[fk_PerfData_PerfCounterId]') AND parent_object_id = OBJECT_ID(N'[dbo].[PerfData]'))
ALTER TABLE [dbo].[PerfData]  WITH CHECK ADD  CONSTRAINT [fk_PerfData_PerfCounterId] FOREIGN KEY([PerfCounterId])
REFERENCES [dbo].[PerfCounter] ([Id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[fk_PerfData_PerfCounterId]') AND parent_object_id = OBJECT_ID(N'[dbo].[PerfData]'))
ALTER TABLE [dbo].[PerfData] CHECK CONSTRAINT [fk_PerfData_PerfCounterId]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[fk_PerfData_PerfServerId]') AND parent_object_id = OBJECT_ID(N'[dbo].[PerfData]'))
ALTER TABLE [dbo].[PerfData]  WITH CHECK ADD  CONSTRAINT [fk_PerfData_PerfServerId] FOREIGN KEY([PerfServerId])
REFERENCES [dbo].[PerfServer] ([Id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[fk_PerfData_PerfServerId]') AND parent_object_id = OBJECT_ID(N'[dbo].[PerfData]'))
ALTER TABLE [dbo].[PerfData] CHECK CONSTRAINT [fk_PerfData_PerfServerId]
GO
USE [master]
GO
ALTER DATABASE [$(Databasename)] SET  READ_WRITE 
GO

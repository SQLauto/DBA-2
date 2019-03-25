
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @columnExists bit 
declare @tableExists bit
declare @primaryKeyName varchar(128)
exec #TableExists 'capture', 'CacheUsagebyDBData',  @tableExists out
if (@tableExists = 0)
begin
BEGIN TRY
BEGIN TRANSACTION
CREATE TABLE [capture].[CacheUsagebyDBData](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[ServerName] [varchar](500) NULL,
	[PullPeriod] [int] NULL,
	[node] [varchar](128) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

CREATE TABLE [capture].[CacheUsagebyDbResults](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[databasename] [nvarchar](128) NULL,
	[Buffered_MB] [float] NULL,
	[CaptureDate] [datetime] NULL,
	[Captureid] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

CREATE TABLE [capture].[CpuData](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[ServerName] [varchar](500) NULL,
	[PullPeriod] [int] NULL,
	[node] [varchar](128) NULL,
 CONSTRAINT [Pk_CPUData_Id] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]



CREATE TABLE [capture].[CpuResults](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[CaptureDate] [datetime] NULL,
	[DatabaseName] [varchar](128) NULL,
	[CPU_Time_Ms] [bigint] NULL,
	[CPUPercent] [float] NULL,
	[CpuDataID] [bigint] NULL,
 CONSTRAINT [PK_CpuResults_Id] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


COMMIT TRANSACTION 
END TRY 
BEGIN CATCH
if @@TRANCOUNT >0
	ROLLBACK TRANSACTION

;THROW
END CATCH
end


GO
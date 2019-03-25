GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

BEGIN TRANSACTION

	BEGIN TRY		
		
		CREATE TABLE [capture].[QueryExecutionWindow](
		[ID] [bigint] IDENTITY(1,1) NOT NULL,
		[StartTime] [datetime] NULL,
		[EndTime] [datetime] NULL,
		[ServerName] [varchar](500) NULL,
		[PullPeriod] [int] NULL,
		[node] [varchar](128) NULL,
 CONSTRAINT [Pk_SqlQueryWindow_Id] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

		
CREATE TABLE [capture].[QueryExecutionStats](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[CaptureDate] [datetime] NULL,
	[type] [varchar](10) NULL,
	[ObjectName] [varchar](100) NULL,
	[QueryText] [varchar](8000) NULL,
	[execution_count] [bigint] NULL,
	[total_worker_time] [bigint] NULL,
	[total_physical_reads] [bigint] NULL,
	[total_logical_writes] [bigint] NULL,
	[total_logical_reads] [bigint] NULL,
	[total_elapsed_time] [bigint] NULL,
	[min_rows] [int] NULL,
	[max_rows] [int] NULL,
	[last_rows] [int] NULL,
	[statement_start_offset] [int] NULL,
	[statement_end_offset] [int] NULL,
	[database] [varchar](100) NULL,
	[CaptureQueryDataID] [bigint] NULL,
	[database_id] [smallint] NULL,
	[object_id] [int] NULL,
 CONSTRAINT [PK_QueryExecution_Id] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
								
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		THROW;
	END CATCH

COMMIT TRANSACTION;
GO

EXEC [deployment].[SetScriptAsRun] 'B087_R0001_Create_QueryExecution_Tables'
GO

GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

DECLARE @exists BIT
EXEC #TableExists 'capture', 'DiskUsageData', @exists OUT

IF(@exists = 0)
BEGIN

	
	
	CREATE TABLE [capture].[DiskUsageData](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Volume] varchar(256),
	[SizeInGb] INT NOT NULL,
	[FreeInGb] INT NOT NULL,
	[FreePercentage] FLOAT NOT NULL,
	[CaptureDate] [datetime] NULL,

	
 CONSTRAINT [PK_DiskUsage_Id] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
	

END

GO

EXEC [deployment].[SetScriptAsRun] 'DiskUsageData'
GO

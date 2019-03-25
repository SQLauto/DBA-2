
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

-- Tables
DECLARE @TableExists BIT;
EXEC #TableExists @SchemaName = 'admin', @TableName = 'PartitionConfig', @TableExists = @TableExists OUTPUT

IF @TableExists = 0
BEGIN
	--This table is a prerequisite so will always exist otherwise the pre-deployment validation will fail
	-- but so we have a definition in source control it is included here.
	CREATE TABLE admin.PartitionConfig
	(
		Id tinyint NOT NULL,
		Name nvarchar(128) NOT NULL,
		GrowthMB int NULL,
		GrowthPercent int NULL,
		FileCountPerFileGroup tinyint NOT NULL,
		Strategy tinyint NOT NULL,
		SizeMB int NOT NULL,
		MaxSizeMB int NULL,
		ArchivetoLiveSwitchOverPartitionKeyValue sql_variant NULL,
		ArchivetoLiveSwitchOverDate date NULL,
		PartitionKey varchar(50) NOT NULL,
		PartitionKeyDataType varchar(100) NOT NULL,
		PartitionKeyLength int NOT NULL,
		ReadWriteRetention varchar(50) NOT NULL,
		ArchiveRetention varchar(50) NOT NULL,
		PeriodType varchar(10) NOT NULL,
		Archive bit NULL,
		LiveSchema sysname NULL,
		ArchiveSchema sysname NULL,
		CONSTRAINT PK_Admin_PartitionConfig PRIMARY KEY CLUSTERED 
		(
			Id ASC
		) ON [PRIMARY]
	) ON [PRIMARY]

END
GO

DECLARE @TableExists BIT;
EXEC #TableExists @SchemaName = 'admin', @TableName = 'PartitionLog', @TableExists = @TableExists OUTPUT

IF @TableExists = 0
BEGIN

	CREATE TABLE [admin].[PartitionLog]
	(
		[ID] [bigint] IDENTITY(1,1) NOT NULL,
		[EntryDate] [datetime] NULL,
		[ObjectID] [bigint] NULL,
		[DateRangeSwitchedInt] [int] NULL,
		[DateRangeSwitchedDate] [smalldatetime] NULL,
		[RowCountSwitched] [bigint] NULL,
		[Success] [bit] NULL,
		[Comments] [varchar](500) NULL,
	CONSTRAINT [PK_PartitionLog] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	) ON [PRIMARY]
	) ON [PRIMARY]

END
GO

DECLARE @checkConstraintExists BIT
EXEC #CheckConstraintExists 'admin', 'PartitionConfig', 'CK_Admin_PartitionConfig_Growth', @checkConstraintExists OUT
IF (@checkConstraintExists = 0)
BEGIN
	ALTER TABLE admin.PartitionConfig
	ADD CONSTRAINT [CK_Admin_PartitionConfig_Growth] 
	CHECK ([GrowthMB] IS NOT NULL AND [GrowthPercent] IS NULL OR [GrowthMB] IS NULL AND [GrowthPercent] IS NOT NULL);
END

GO
	ALTER TABLE admin.PartitionConfig WITH CHECK CHECK CONSTRAINT  CK_Admin_PartitionConfig_Growth;
GO

DECLARE @checkConstraintExists BIT
EXEC #CheckConstraintExists 'admin', 'PartitionConfig', 'CK_Admin_PartitionConfig_MaxSizeMB', @checkConstraintExists OUT
IF (@checkConstraintExists = 0)
BEGIN
	ALTER TABLE admin.PartitionConfig
	ADD CONSTRAINT [CK_Admin_PartitionConfig_MaxSizeMB] 
	CHECK ([MaxSizeMB] IS NULL OR [MaxSizeMB]>(0));
END
GO
	ALTER TABLE admin.PartitionConfig WITH CHECK CHECK CONSTRAINT  CK_Admin_PartitionConfig_MaxSizeMB;
GO

DECLARE @checkConstraintExists BIT
EXEC #CheckConstraintExists 'admin', 'PartitionConfig', 'CK_Admin_PartitionConfig_SizeMB', @checkConstraintExists OUT
IF (@checkConstraintExists = 0)
BEGIN
	ALTER TABLE admin.PartitionConfig
	ADD CONSTRAINT [CK_Admin_PartitionConfig_SizeMB] 
	CHECK ([SizeMB]>(0));
END
GO
	ALTER TABLE admin.PartitionConfig WITH CHECK CHECK CONSTRAINT  CK_Admin_PartitionConfig_SizeMB;
GO
--To ensure robust post validation perform last step in a transaction thus making it re-runable.
BEGIN TRANSACTION
BEGIN TRY
	DECLARE @checkConstraintExists BIT
	EXEC #CheckConstraintExists 'admin', 'PartitionConfig', 'CK_Admin_PartitionConfig_Strategy2', @checkConstraintExists OUT
	IF (@checkConstraintExists = 0)
	BEGIN
		ALTER TABLE admin.PartitionConfig
		ADD CONSTRAINT [CK_Admin_PartitionConfig_Strategy2] 
		CHECK ([Strategy] <> 2 OR [Archive] <> 1)
	END

	ALTER TABLE admin.PartitionConfig WITH CHECK CHECK CONSTRAINT  CK_Admin_PartitionConfig_SizeMB;
	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION;
	THROW;
END CATCH
GO




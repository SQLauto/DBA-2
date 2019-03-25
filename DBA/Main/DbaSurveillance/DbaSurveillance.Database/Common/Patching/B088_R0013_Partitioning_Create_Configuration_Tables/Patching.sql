
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

SELECT 'B072_R0013_Partitioning_Create_Configuration_Tables'
GO

DECLARE @exists BIT



/* ------------------------------------------------------------------------------------------------------------------ */
/* 1.	Create entries for files to be used with the LUN mountpoints */
PRINT 'Creating table: internal.MountPointConfig'

SET @exists = 1
EXEC #TableExists 'internal', 'MountPointConfig', @exists OUT
IF (@exists = 0)
BEGIN
	CREATE TABLE [internal].[MountPointConfig]
	(
		[Id] [smallint] IDENTITY(1,1) NOT NULL,
		[Path] [nvarchar](100) NOT NULL,
		[Category] [nvarchar](10) NOT NULL,
	CONSTRAINT [PK_MountPointConfig] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)
	) ON [PRIMARY]
END





/* ------------------------------------------------------------------------------------------------------------------ */
/*	2.	Populate the Partition Config table with a record for the TokenJourneySummaryHeader and the RevisionDailyCharge table.
		Note that this table is previously created by the DBA Common Partitioning Role.  */
PRINT 'Creating table: admin.PartitionConfig'

SET @exists = 1
EXEC #TableExists 'admin', 'PartitionConfig', @exists OUT
IF (@exists = 0)
BEGIN
	CREATE TABLE [admin].[PartitionConfig]
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
		) 
		ON [PRIMARY]
		) ON [PRIMARY]
END



EXEC [deployment].[SetScriptAsRun] 'B072_R0013_Partitioning_Create_Configuration_Tables'
GO

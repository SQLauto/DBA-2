GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

DECLARE  @PartitionConfig TABLE
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
			PartitionKeyDataType varchar(12) NOT NULL,
			PartitionKeyLength int NOT NULL,
			ReadWriteRetention varchar(50) NOT NULL,
			ArchiveRetention varchar(50) NOT NULL,
			PeriodType varchar(10) NOT NULL,
			Archive bit NULL,
			LiveSchema sysname NULL,
			ArchiveSchema sysname NULL

		)



INSERT @PartitionConfig ([Id], [Name], [GrowthMB], [GrowthPercent], [FileCountPerFileGroup], [Strategy], [SizeMB], [MaxSizeMB], [ArchivetoLiveSwitchOverPartitionKeyValue], [ArchivetoLiveSwitchOverDate], [PartitionKey], [PartitionKeyDataType], [PartitionKeyLength], [ReadWriteRetention], [ArchiveRetention], [PeriodType], [Archive], [LiveSchema], [ArchiveSchema]) VALUES (1, N'CPU', 250, NULL, 4, 0, 5, NULL, NULL, NULL, N'Created', N'datetime', 8, N'8', N'0', N'ww', 1, N'fact', N'archive')
INSERT @PartitionConfig ([Id], [Name], [GrowthMB], [GrowthPercent], [FileCountPerFileGroup], [Strategy], [SizeMB], [MaxSizeMB], [ArchivetoLiveSwitchOverPartitionKeyValue], [ArchivetoLiveSwitchOverDate], [PartitionKey], [PartitionKeyDataType], [PartitionKeyLength], [ReadWriteRetention], [ArchiveRetention], [PeriodType], [Archive], [LiveSchema], [ArchiveSchema]) VALUES (2, N'FileInfo', 250, NULL, 4, 0, 5, NULL, NULL, NULL, N'Created', N'datetime', 8, N'8', N'0', N'ww', 1, N'fact', N'archive')
INSERT @PartitionConfig ([Id], [Name], [GrowthMB], [GrowthPercent], [FileCountPerFileGroup], [Strategy], [SizeMB], [MaxSizeMB], [ArchivetoLiveSwitchOverPartitionKeyValue], [ArchivetoLiveSwitchOverDate], [PartitionKey], [PartitionKeyDataType], [PartitionKeyLength], [ReadWriteRetention], [ArchiveRetention], [PeriodType], [Archive], [LiveSchema], [ArchiveSchema]) VALUES (3, N'PerfmonCounters', 250, NULL, 4, 0, 5, NULL, NULL, NULL, N'Created', N'datetime', 8, N'8', N'0', N'ww', 1, N'fact', N'archive')
INSERT @PartitionConfig ([Id], [Name], [GrowthMB], [GrowthPercent], [FileCountPerFileGroup], [Strategy], [SizeMB], [MaxSizeMB], [ArchivetoLiveSwitchOverPartitionKeyValue], [ArchivetoLiveSwitchOverDate], [PartitionKey], [PartitionKeyDataType], [PartitionKeyLength], [ReadWriteRetention], [ArchiveRetention], [PeriodType], [Archive], [LiveSchema], [ArchiveSchema]) VALUES (4, N'SQLCounters', 250, NULL, 4, 0, 5, NULL, NULL, NULL, N'Created', N'datetime', 8, N'8', N'0', N'ww', 1, N'fact', N'archive')
INSERT @PartitionConfig ([Id], [Name], [GrowthMB], [GrowthPercent], [FileCountPerFileGroup], [Strategy], [SizeMB], [MaxSizeMB], [ArchivetoLiveSwitchOverPartitionKeyValue], [ArchivetoLiveSwitchOverDate], [PartitionKey], [PartitionKeyDataType], [PartitionKeyLength], [ReadWriteRetention], [ArchiveRetention], [PeriodType], [Archive], [LiveSchema], [ArchiveSchema]) VALUES (5, N'StoredProcedures', 250, NULL, 4, 0, 5, NULL, NULL, NULL, N'Created', N'datetime', 8, N'8', N'0', N'ww', 1, N'fact', N'archive')
INSERT @PartitionConfig ([Id], [Name], [GrowthMB], [GrowthPercent], [FileCountPerFileGroup], [Strategy], [SizeMB], [MaxSizeMB], [ArchivetoLiveSwitchOverPartitionKeyValue], [ArchivetoLiveSwitchOverDate], [PartitionKey], [PartitionKeyDataType], [PartitionKeyLength], [ReadWriteRetention], [ArchiveRetention], [PeriodType], [Archive], [LiveSchema], [ArchiveSchema]) VALUES (6, N'VirtualFileStats', 250, NULL, 4, 0, 5, NULL, NULL, NULL, N'Created', N'datetime', 8, N'8', N'0', N'ww', 1, N'fact', N'archive')
INSERT @PartitionConfig ([Id], [Name], [GrowthMB], [GrowthPercent], [FileCountPerFileGroup], [Strategy], [SizeMB], [MaxSizeMB], [ArchivetoLiveSwitchOverPartitionKeyValue], [ArchivetoLiveSwitchOverDate], [PartitionKey], [PartitionKeyDataType], [PartitionKeyLength], [ReadWriteRetention], [ArchiveRetention], [PeriodType], [Archive], [LiveSchema], [ArchiveSchema]) VALUES (7, N'WaitStats', 250, NULL, 4, 0, 5, NULL, NULL, NULL, N'Created', N'datetime', 8, N'8', N'0', N'ww', 1, N'fact', N'archive')
INSERT @PartitionConfig ([Id], [Name], [GrowthMB], [GrowthPercent], [FileCountPerFileGroup], [Strategy], [SizeMB], [MaxSizeMB], [ArchivetoLiveSwitchOverPartitionKeyValue], [ArchivetoLiveSwitchOverDate], [PartitionKey], [PartitionKeyDataType], [PartitionKeyLength], [ReadWriteRetention], [ArchiveRetention], [PeriodType], [Archive], [LiveSchema], [ArchiveSchema]) VALUES (8, N'WhoIsActive', 250, NULL, 4, 0, 5, NULL, NULL, NULL, N'Created', N'datetime', 8, N'8', N'0', N'ww', 1, N'fact', N'archive')



DELETE FROM C
from admin.partitionconfig C
LEFT JOIN @PartitionConfig M ON M.id=C.id and M.name=C.name
WHERE M.id is null


MERGE admin.partitionconfig AS target
USING
(
	select Id,	Name, GrowthMB, GrowthPercent, FileCountPerFileGroup, Strategy, SizeMB, MaxSizeMB, ArchivetoLiveSwitchOverPartitionKeyValue, ArchivetoLiveSwitchOverDate, PartitionKey, PartitionKeyDataType, PartitionKeyLength, ReadWriteRetention, ArchiveRetention, PeriodType, Archive, LiveSchema, ArchiveSchema
	FROM @PartitionConfig
) as SOURCE
ON( target.Id = Source.Id)
WHEN NOT MATCHED
THEN INSERT(Id,	
			Name, 
			GrowthMB, 
			GrowthPercent, 
			FileCountPerFileGroup, 
			Strategy, 
			SizeMB, 
			MaxSizeMB, 
			ArchivetoLiveSwitchOverPartitionKeyValue, 
			ArchivetoLiveSwitchOverDate, 
			PartitionKey, 
			PartitionKeyDataType, 
			PartitionKeyLength, 
			ReadWriteRetention, 
			ArchiveRetention, 
			PeriodType, 
			Archive, 
			LiveSchema, 
			ArchiveSchema)
VALUES(		source.Id,	
			source.Name, 
			source.GrowthMB, 
			source.GrowthPercent, 
			source.FileCountPerFileGroup, 
			source.Strategy, 
			source.SizeMB, 
			source.MaxSizeMB, 
			source.ArchivetoLiveSwitchOverPartitionKeyValue, 
			source.ArchivetoLiveSwitchOverDate, 
			source.PartitionKey, 
			source.PartitionKeyDataType, 
			source.PartitionKeyLength, 
			source.ReadWriteRetention, 
			source.ArchiveRetention, 
			source.PeriodType, 
			source.Archive, 
			source.LiveSchema, 
			source.ArchiveSchema)
			WHEN MATCHED
			 THEN UPDATE SET 
			 Name= source.Name, 
			GrowthMB=source.GrowthMB, 
			GrowthPercent=source.GrowthPercent, 
			FileCountPerFileGroup=source.FileCountPerFileGroup, 
			Strategy=source.Strategy, 
			SizeMB=source.SizeMB, 
			MaxSizeMB=source.MaxSizeMB, 
			PartitionKey=source.PartitionKey, 
			PartitionKeyDataType=source.PartitionKeyDataType, 
			PartitionKeyLength=source.PartitionKeyLength, 
			ReadWriteRetention=source.ReadWriteRetention, 
			ArchiveRetention=source.ArchiveRetention, 
			PeriodType=source.PeriodType, 
			Archive=source.Archive, 
			LiveSchema=source.LiveSchema, 
			ArchiveSchema=source.ArchiveSchema;

	
EXEC #CreateDummyStoredProcedureIfNotExists 'maint', 'RestoreScriptGenerateFromBackup'
GO
/*
	To generate a restore script which uses existing file mappings with replace, with recovery, with checksum:
	declare @sql nvarchar(max);
	exec maint.RestoreScriptGenerateFromBackup 
		@backupOfInterest='D:\MyBakup.bak', 
		@dbNameToRestoreTo='MyDbName',
		@restoreScript = @sql out;
	
	select @sql;
		
	
	To generate a restore script which changes the file mappings with replace, with recovery, with checksum:
	
	declare @specificMappings as [maint].[RestoreDatabaseMappings];
	insert into @specificMappings  (AsIsMapping, ToBeMapping) values
	('K:\CC_DG01', 'X:\CC_DG01'),
	('K:\CC_LOG01', 'Y:\CC_LOG01')
	declare @sql nvarchar(max);
	
	exec maint.RestoreScriptGenerateFromBackup 
		@backupOfInterest='D:\MyBakup.bak', 
		@dbNameToRestoreTo='MyDbName',
		@createRestoreScriptWithExistingMappings = 0,
		@specificRestoreMappings = @specificMappings,
		@restoreScript = @sql out;
		
	select @sql;
*/

ALTER PROCEDURE [maint].[RestoreScriptGenerateFromBackup]
	--Path to backup
	@backupOfInterest varchar(260),
	--Name of the restored database
	@dbNameToRestoreTo varchar(128),
	--Set to zero to use the same file paths as those within the backup, set to 1 to define mappings
	@createRestoreScriptWithExistingMappings bit = 1,
	--Set to 1 to overwrite the existing database using WITH REPLACE option which will verify the databasename 
	--is the same name as that of the backupset and over write existing database files.
	@withReplaceDatabase bit  = 1,
	--Set to 1 to leave database in recovery mode, set to zero to place database online after restore
	@restoreWithNoRecovery bit = 0,
	--Set 1 for restore with Checksum validation (backup must contain checksum), Zero for without Checksum Validation
	@validateRestoreWithChecksum bit = 0,
	--To use the latest back up set: @useLatestBackupSet = 1 and @specificFilePositionBackupSetToRestore = null
	--To specify a specific backup: @useLatestBackupSet = 0 and @specificFilePositionBackupSetToRestore = FilePositionNumber
	@useLatestBackupSet bit = 1,
	@specificFilePositionBackupSetToRestore smallint = null,
	@specificRestoreMappings maint.RestoreDatabaseMappings readonly,
	@validateRestoreWithChecksumIfBackupContainsChecksum bit = 1,
	@restoreScript nvarchar(max) out
as
begin
	set transaction isolation level read uncommitted;
	set nocount on
	set @restoreScript = '';

	begin try

		declare @MappingsOfInterest table
		(
			AsIsMapping varchar(248) not null,
			ToBeMapping varchar(248) not null
		)

		if (@createRestoreScriptWithExistingMappings = 0)
		begin
			insert into @MappingsOfInterest (AsIsMapping, ToBeMapping)
			select
				AsIsMapping,
				ToBeMapping
			from
				@specificRestoreMappings
		end

		declare @sql varchar(max)
		set @sql = 'restore headeronly from disk=  N''' + @backupOfInterest +  ''''
		print @sql

		declare @BackupHeader table ( BackupName nvarchar(128), BackupDescription nvarchar(255), BackupType smallint, 
								ExpirationDate datetime, Compressed bit, Position smallint, DeviceType tinyint, 
								UserName nvarchar(128), ServerName nvarchar(128), DatabaseName nvarchar(128), DatabaseVersion int, 
								DatabaseCreationDate datetime, BackupSize numeric(20,0), FirstLSN numeric(25,0), LastLSN numeric(25,0), 
								CheckpointLSN numeric(25,0), DatabaseBackupLSN numeric(25,0), BackupStartDate datetime, BackupFinishDate datetime, 
								SortOrder smallint, CodePage smallint, UnicodeLocaleId int, UnicodeComparisonStyle int, 
								CompatibilityLevel tinyint, SoftwareVendorId int, SoftwareVersionMajor int, 
								SoftwareVersionMinor int, SoftwareVersionBuild int, MachineName nvarchar(128), Flags int, 
								BindingID uniqueidentifier, RecoveryForkID uniqueidentifier, Collation nvarchar(128), FamilyGUID uniqueidentifier, 
								HasBulkLoggedData bit, IsSnapshot bit, IsReadOnly bit, IsSingleUser bit, 
								HasBackupChecksums bit, IsDamaged bit, BeginsLogChain bit, HasIncompleteMetaData bit, 
								IsForceOffline bit, IsCopyOnly bit, FirstRecoveryForkID uniqueidentifier, ForkPointLSN numeric(25,0), 
								RecoveryModel nvarchar(60), DifferentialBaseLSN numeric(25,0), DifferentialBaseGUID uniqueidentifier, 
								BackupTypeDescription nvarchar(60), BackupSetGUID uniqueidentifier, CompressedBackupSize bigint, 
								Containment tinyint); 
		insert into @BackupHeader 
		exec(@sql)
		
		select * from @BackupHeader

		if (@useLatestBackupSet = 1 and @specificFilePositionBackupSetToRestore is not null)
		begin
			raiserror('You must specify either use the latest backup set and set specific file position to null or use latest backup set to 0 and specific file position to not null.  Please review and configure appropriately.', 16, 1)
		end

		if (@useLatestBackupSet = 0 and @specificFilePositionBackupSetToRestore is null)
		begin
			raiserror('You must specify either use the latest backup set = 1 and set specific file position to null or use latest backup set to 0 and specific file position to not null.  Please review and configure appropriately.', 16, 1)
		end

		declare @backupFilePosition smallint
		if (@useLatestBackupSet = 1)
		begin
			set @backupFilePosition = (select max(Position) from @BackupHeader)
		end
		else
		begin
			set @backupFilePosition = @specificFilePositionBackupSetToRestore
			if not exists (select 1 from @BackupHeader where Position = @specificFilePositionBackupSetToRestore)
			begin
				raiserror('There is no backup file with the position you have specified please review your configuration.', 16,1)
			end
		end

		select @backupFilePosition RestoringBackupSet, min(position) MinimumBackupSet,  max(position) MaximumBackupSet  from @BackupHeader

		declare @FileTypes table
		(
			FileType char(1),
			FileTypeName varchar(50)
		)

		insert into @FileTypes (FileType, FileTypeName) values
		('L', 'Log File'),
		('D', 'Data File'),
		('F', 'Full Text Catalog'),
		('S', 'FileStream, FileTable, or In-Memory OLTP container')

		if (object_id('tempdb..#BackupInfo') is not null)
		begin
			drop table #BackupInfo
		end

		--Get Backup Info
		create table #BackupInfo
		(
			LogicalName nvarchar(128) not null,
			PhysicalName nvarchar(260) not null,
			FileType char(1) not null, 
			FileGroupName nvarchar(128) null,
			SizeBytes numeric(20,0) not null,
			MaxSizeBytes numeric(20,0) not null,
			FileId bigint not null,
			CreateLSN numeric(25,0) not null,
			DropLSN numeric(25,0) null,
			UniqueId uniqueidentifier not null,
			ReadonlyLSN numeric(25,0) null,
			ReadWriteLSN numeric(25,0) null,
			BackupSizeInBytes bigint not null,
			SourceBlockSizeIntBytes int not null,
			FileGroupId int not null,
			LogGroupGuid uniqueidentifier null,
			DifferentialBaseLSN numeric(25, 0) null,
			DifferentialBaseGuid  uniqueidentifier null,
			IsReadOnly bit not null,
			IsPresent bit not null,
			TDEThumbprint varbinary(32) null
		)

		set @sql = 'restore filelistonly from disk = N''' + @backupOfInterest +  ''' with file = ' + CAST(@backupFilePosition as varchar(50))
		print @sql
		insert into #BackupInfo
		exec(@sql)

		alter table #BackupInfo 
		add PhysicalFolder varchar(248) null;

		update #BackupInfo
		set
			PhysicalFolder = substring(PhysicalName,1,len(PhysicalName)-charindex('\',reverse(PhysicalName)));


		alter table #BackupInfo 
		add FileNameWithExtension varchar(248) null;

		update #BackupInfo
		set 
			FileNameWithExtension = replace(PhysicalName, PhysicalFolder + '\', '');

		--Byte * Kilobyte * MegaByte * GigaByte
		declare @bytesToGBconstant int = 1*1024*1024*1024
		select distinct 
			PhysicalFolder,
			count(*) NumberOfFiles, 
			sum(SizeBytes)/@bytesToGBconstant FolderSizeInGB
		from 
			#BackupInfo 
		group by PhysicalFolder;

		if (@createRestoreScriptWithExistingMappings = 1)
		begin
			delete @MappingsOfInterest

			insert into @MappingsOfInterest (AsIsMapping, ToBeMapping)
			select distinct 
				PhysicalFolder AsIs,
				PhysicalFolder ToBe
			from 
				#BackupInfo 
		end

		if (@validateRestoreWithChecksum = 1 or @validateRestoreWithChecksumIfBackupContainsChecksum = 1)
		begin
			if not exists(select 1 from @BackupHeader bh 
							where bh.HasBackupChecksums = 1
							and bh.Position = @backupFilePosition)
			begin
				if (@validateRestoreWithChecksum = 1)
				begin
					raiserror('The backup does not have a checksum for the specified backup set but you have specified the option with checksum.  Either choose a new backup or change the option.', 16, 1)
				end
			end
			else 
			begin
				if (@validateRestoreWithChecksumIfBackupContainsChecksum = 1)
				begin
					set @validateRestoreWithChecksum = 1
				end
			end
		end

		if (@withReplaceDatabase = 1)
		begin 
			if not exists(select 1 from sys.databases d where name = @dbNameToRestoreTo)
			begin
				raiserror('You have selected WITH REPLACE yet there is no database on this instance with the database restore name. This is is not Permitted by SQL SERVER with this option.  Check configuration and correct.', 16, 1)
			end
		end
		else
		begin
			if exists(select 1 from sys.databases d where name = @dbNameToRestoreTo)
			begin
				raiserror('You have selected NOT WITH REPLACE yet there is a database on this instance with the database restore name. This is is not Permitted by SQL SERVER with this option.  Check configuration and correct.', 16, 1)
			end
		end


		alter table #BackupInfo 
		add ToBePhysicalFolder varchar(248) null;

		update bi
		set 
			ToBePhysicalFolder = mi.ToBeMapping
		from 
			#BackupInfo bi 
		inner join @MappingsOfInterest mi on
			bi.PhysicalFolder = mi.AsIsMapping;

		if exists (select 1 from #BackupInfo where ToBePhysicalFolder is null)
		begin
			select distinct
				PhysicalFolder MissingFolderMappings
			from 
				#BackupInfo bi
			where
				ToBePhysicalFolder is null

			raiserror('There are missing mappings in @MappingsOfInterest please review output where missing folder mappings are displayed.', 16,1)
		end
		else
		begin
			alter table #BackupInfo 
			add ToBePhysicalFileWithPath varchar(248) null;

			update #BackupInfo
			set 
				ToBePhysicalFileWithPath = ToBePhysicalFolder + '\' + FileNameWithExtension
		

			declare @restoreSteps table
			(
				id int identity(1,1) not null,
				Step varchar(max) not null
			)
	
		declare @restoreIsAFullBackup bit = 1
		if exists(select 1 from @BackupHeader where DifferentialBaseLSN is not null)
		begin
			set @restoreIsAFullBackup = 0
		end
	
		if (@restoreIsAFullBackup = 1)
		begin
			set @sql = 'use master
						go 
	if exists (select 1 from sys.databases d where d.name = ''' + @dbNameToRestoreTo + ''') begin '
			set @sql = @sql + ' exec(''alter database [' + @dbNameToRestoreTo + '] set single_user with rollback immediate;'') end
								go 
	'
		end
		else
		begin
				set @sql = '
			go
			'	
		end
			set @sql = @sql + 'restore database [' + @dbNameToRestoreTo + '] from disk=N''' + @backupOfInterest + ''' WITH '

			if (@withReplaceDatabase = 1 and @restoreIsAFullBackup = 1)
			begin
				set @sql = @sql + 'replace, '
			end

			set @sql = @sql + 'FILE = ' + cast(@backupFilePosition as varchar(50)) + ', '

			if (@validateRestoreWithChecksum = 1)
			begin
				set @sql = @sql + 'CHECKSUM,'
			end
	
			if (@restoreWithNoRecovery = 1)
			begin
				set @sql = @sql + 'NORECOVERY, '
			end
			else
			begin
				set @sql = @sql + 'RECOVERY, '
			end

			set @sql = @sql + ' STATS=10 '
	
			insert into @restoreSteps (Step)values (@sql);
	
			insert into @restoreSteps (Step)
			select 
				', move N''' + bi.LogicalName + ''' to N''' + bi.ToBePhysicalFileWithPath + ''''
			from  
				#BackupInfo bi
			order by
				bi.FileId

			set @restoreScript = ''
			select 
				@restoreScript = @restoreScript + coalesce(Step, '') + char(13) + char(10)
			from 
				@restoreSteps 
			order by 
				Id
		end

		if (object_id('tempdb..#BackupInfo') is not null)
		begin
			drop table #BackupInfo
		end
	end try
	begin catch

		if (object_id('tempdb..#BackupInfo') is not null)
		begin
			drop table #BackupInfo
		end;

		throw;
	end catch
end
GO

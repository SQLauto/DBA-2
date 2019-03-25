EXEC #CreateDummyStoredProcedureIfNotExists 'maint', 'RestoreScriptGenerateForSimpleRestore'
GO

/*
declare @dbName varchar(128) = 'BaselineData'
declare @backupOfInterest varchar(255) = 'D:\MasterData.projectionStore_Baseline_Release60.bak'
declare @logPath varchar(255) = 'D:\Log\';
declare @dataPath varchar(255) = 'D:\Data';
declare @sql nvarchar(max);

exec [maint].[RestoreScriptGenerateForSimpleRestore]
	--Path to backup
	@backupOfInterest = @backupOfInterest,
	--Name of the restored database
	@dbNameToRestoreTo = @dbName,
	--path to log files
	@logFilePath = @logPath,
	--path to data files
	@dataFilePath = @dataPath,
	--set to readonly
	@isToBeSetToReadOnly = 1,
	--the generated script
	@restoreScript = @sql out;

select @sql;
*/


alter procedure [maint].[RestoreScriptGenerateForSimpleRestore]
	--Path to backup
	@backupOfInterest varchar(255),
	--Name of the restored database
	@dbNameToRestoreTo varchar(128),
	--path to log files
	@logFilePath varchar(255),
	--path to data files
	@dataFilePath varchar(255),
	--set to readonly
	@isToBeSetToReadOnly bit = 0,

	--the generated script
	@restoreScript nvarchar(max) out
as
begin

	if (@backupOfInterest is null)
	begin 
		raiserror('@backupOfInterest must not be null', 16, 1)
	end

	if (@dbNameToRestoreTo is null)
	begin 
		raiserror('@dbNameToRestoreTo must not be null', 16, 1)
	end

	if (@logFilePath is null)
	begin 
		raiserror('@logFilePath must not be null', 16, 1)
	end

	if (@dataFilePath is null)
	begin 
		raiserror('@dataFilePath must not be null', 16, 1)
	end

	declare @lastChar varchar(1) = right(@logFilePath, 1)
	if(@lastChar = '\')
	begin 
		set @logFilePath = left(@logFilePath, len(@logFilePath) -1)
	end

	set @lastChar = right(@dataFilePath, 1)
	if(@lastChar = '\')
	begin 
		set @dataFilePath = left(@dataFilePath, len(@dataFilePath) -1)
	end

	
	declare @useLatestBackupSet bit = 1
	
	set transaction isolation level read uncommitted;
	set nocount on
	set @restoreScript = '';

	begin try

		declare @MappingsOfInterest table
		(
			AsIsMapping varchar(248) not null,
			ToBeMapping varchar(248) not null
		)

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

		declare @backupFilePosition smallint = (select max(Position) from @BackupHeader)
	

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

		
		declare @validateRestoreWithChecksum bit = 0;

		if exists(select 1 from @BackupHeader bh 
							where bh.HasBackupChecksums = 1
							and bh.Position = @backupFilePosition)
		begin
			set @validateRestoreWithChecksum = 1 
		end

		
		declare @withReplaceDatabase bit = 0
		if exists(select 1 from sys.databases d where name = @dbNameToRestoreTo)
		begin
			set @withReplaceDatabase = 1
		end

		alter table #BackupInfo 
		add ToBePhysicalFolder varchar(248) null;

		update bi
		set 
			ToBePhysicalFolder = @logFilePath
		from 
			#BackupInfo bi 
		where 
			bi.FileType = 'L'

		update bi
		set 
			ToBePhysicalFolder = @dataFilePath
		from 
			#BackupInfo bi 
		where 
			bi.FileType != 'L'

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
	
		set @sql = 'use master
						
	if exists (select 1 from sys.databases d where d.name = ''' + @dbNameToRestoreTo + ''') begin ';
			set @sql = @sql + ' exec(''alter database [' + @dbNameToRestoreTo + '] set single_user with rollback immediate; drop database [' + + @dbNameToRestoreTo + '];  '') end
	';
		
		set @sql = @sql + 'restore database [' + @dbNameToRestoreTo + '] from disk=N''' + @backupOfInterest + ''' WITH '

			if (@withReplaceDatabase = 1)
			begin
				set @sql = @sql + 'replace, '
			end

			set @sql = @sql + 'FILE = ' + cast(@backupFilePosition as varchar(50)) + ', '

			if (@validateRestoreWithChecksum = 1)
			begin
				set @sql = @sql + 'CHECKSUM,'
			end
	
			set @sql = @sql + 'RECOVERY, '
			
			set @sql = @sql + ' STATS=5 '
	
			insert into @restoreSteps (Step)values (@sql);
	
			insert into @restoreSteps (Step)
			select 
				', move N''' + bi.LogicalName + ''' to N''' + bi.ToBePhysicalFileWithPath + ''''
			from  
				#BackupInfo bi
			order by
				bi.FileId

			if (@isToBeSetToReadOnly = 1)
			begin
				insert into @restoreSteps (Step)values (N';');
				insert into @restoreSteps (Step)values (N'use master;');
				insert into @restoreSteps (Step)values (N'alter database [' + @dbNameToRestoreTo + N'] set single_user with rollback immediate;');
				insert into @restoreSteps (Step)values (N'alter database [' + @dbNameToRestoreTo + N'] set read_only with no_wait;');
				insert into @restoreSteps (Step)values (N'alter database [' + @dbNameToRestoreTo + N'] set multi_user;');
			end

			set @restoreScript = ''
			select 
				@restoreScript = @restoreScript + coalesce(Step, '') + char(13) + char(10)
			from 
				@restoreSteps 
			order by 
				Id

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



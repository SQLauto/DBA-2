
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @primaryKeyName varchar(128)
declare @columnExists bit

exec #GetPrimaryKeyName  'dbo', 'AlertHistory', @primaryKeyName out
if (@primaryKeyName is null)
begin
	alter table  [dbo].[AlertHistory]
	add constraint Pk_AlertHistory_Id primary key clustered (Id);
end

exec #ColumnExists 'dbo', 'ErrorLog', 'Id', @columnExists out
if (@columnExists = 0)
begin
	alter table [dbo].[ErrorLog]
	add Id bigint identity(1,1) not null constraint PK_ErrorLog_Id primary key clustered (Id);
end


exec #ColumnExists 'dbo', 'FragmentationLevels', 'Id', @columnExists out
if (@columnExists = 0)
begin
	alter table [dbo].[FragmentationLevels]
	add Id bigint identity(1,1) not null constraint PK_FragmentationLevels_Id primary key clustered(Id);
end

exec #ColumnExists 'dbo', 'Job_Failures', 'Id', @columnExists out
if (@columnExists = 0)
begin
	alter table [dbo].[Job_Failures]
	add Id bigint identity(1,1) not null constraint PK_Job_Failures_Id primary key clustered(Id);
end

exec #ColumnExists 'dbo', 'JobAnalysis', 'Id', @columnExists out
if (@columnExists = 0)
begin
	alter table  [dbo].[JobAnalysis]
	add Id bigint identity(1,1) not null constraint PK_JobAnalysis_Id primary key clustered(Id);
end

exec #ColumnExists 'dbo', 'LocalDrives', 'Id', @columnExists out
if (@columnExists = 0)
begin
	alter TABLE [dbo].[LocalDrives]
	add Id bigint identity(1,1) not null constraint PK_LocalDrives_Id primary key clustered(Id);
end

exec #ColumnExists 'dbo', 'loginstuff', 'Id', @columnExists out
if (@columnExists = 0)
begin
	alter TABLE [dbo].[loginstuff]
	add Id bigint identity(1,1) not null constraint PK_Loginstuff_Id primary key clustered(Id);
end

exec  #ColumnExists 'dbo', 'PhysicalStats', 'Id', @columnExists out
if (@columnExists = 0)
begin	
	alter TABLE [dbo].[PhysicalStats]
	add Id bigint identity(1,1) not null constraint PK_physicalStats_Id primary key clustered(Id);
end

exec #GetPrimaryKeyName 'dbo', 'ProcPerfCacheCollection', @primaryKeyName out
if (@primaryKeyName is null)
begin
	alter TABLE [dbo].[ProcPerfCacheCollection]
	add constraint PK_procPerfCacheCollection_Event primary key clustered(EVENT);
end

exec  #ColumnExists  'dbo', 'ReindexHistory', 'Id', @columnExists out
if (@columnExists = 0)
begin
	alter TABLE [dbo].[ReindexHistory]
	add Id bigint identity(1,1) not null constraint PK_ReindexHistory_Id primary key clustered(Id);
end

exec  #ColumnExists 'dbo', 'TableSizeLog', 'Id', @columnExists out
if (@columnExists = 0)
begin
	alter TABLE [dbo].[TableSizeLog]
	add Id bigint identity(1,1) not null constraint PK_TableSizeLog_Id primary key clustered(Id);
end

exec #GetPrimaryKeyName 'dbo', 'UptimeHistory', @primaryKeyName out
if (@primaryKeyName is null)
begin
	alter TABLE [dbo].[UptimeHistory]
	add constraint PK_UpTimehistory_Id primary key clustered (Id);
end


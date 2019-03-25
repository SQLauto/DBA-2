
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @columnExists bit 
declare @tableExists bit
declare @primaryKeyName varchar(128)

exec #ColumnExists 'capture', 'BlockedProcessReport', 'Id', @columnExists out
if (@columnExists = 0)
begin
	alter table capture.BlockedProcessReport 
	add Id bigint identity(1,1) not null constraint Pk_BlockedProcessReport_Id primary key clustered(Id);
end

exec #ColumnExists 'capture', 'ConfigData', 'Id',  @columnExists out
if (@columnExists = 0)
begin
	alter table capture.ConfigData
	add Id bigint identity(1,1) not null constraint PK_ConfigData_Id primary key clustered(Id);
end

exec #GetPrimaryKeyName 'capture', 'CpuUtilisation', @primaryKeyName out
if (@primaryKeyName is null)
begin
	alter table capture.CpuUtilisation
	add constraint PK_CpuUtilisation_Id primary key clustered(Id);
end

exec #ColumnExists 'capture', 'CurrentPartitionState', 'Id', @columnExists out
if (@columnExists = 0)
begin
	alter table capture.CurrentPartitionState
	add Id bigint identity(1,1) constraint PK_CurrentPartitionState_Id primary key clustered(Id); 
end



exec #GetPrimaryKeyName 'capture', 'ProcPerfCacheCollection', @primaryKeyName out
if (@primaryKeyName is null)
begin
	alter table capture.ProcPerfCacheCollection
	add constraint PK_ProcPerfCacheCollection_Event primary key clustered(Event)
end

exec #ColumnExists 'capture', 'ServerConfig', 'Id', @columnExists out
if (@columnExists = 0)
begin
	alter table [capture].[ServerConfig]
	add Id bigint identity(1,1) constraint PK_ServerConfig_Id primary key clustered(Id); 
end

exec #GetPrimaryKeyName 'capture', 'WaitStats', @primaryKeyName out
if (@primaryKeyName is null)
begin
	alter table capture.WaitStats
	add constraint PK_WaitStats_RowNum primary key clustered(RowNum);
end

create proc #CreateDummyTriggerIfNotExists
	@schemaName varchar(128),
	@tableName varchar(128),
	@triggerName varchar(128)
as
begin
	if (@tableName is null or @triggerName is null or @schemaName is null)
	begin
		raiserror('#CreateDummyTriggerIfNotExists procedure was called with one or more null arguments', 16, 1)
	end

	declare @tableExists bit = 0;
	EXEC #TableExists @schemaName, @tableName, @tableExists out

	if (@tableExists = 0)
	begin
		declare @errorMessage varchar(max) = '#CreateDummyTrigger procedure was called with the following invalid tableName : ' + @schemaName + '.' + @tableName
		raiserror(@errorMessage, 16, 1)
	end

	declare @sql varchar(max)

	if not exists (select 1 from sys.triggers t where t.name = @triggerName)
	begin
		set @sql = 'create'
	end
	else
	begin
		set @sql = 'alter'
	end

	set @sql = @sql + ' trigger [' + @schemaName + '].[' + @triggerName + '] ON ' + @schemaName + '.' + @tableName + ' FOR INSERT'
		+ ' as select 1 N'

	exec (@sql)
end

go



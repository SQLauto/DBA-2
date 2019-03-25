create proc #CreateDummyStoredProcedureIfNotExists
	@schemaName varchar(128),
	@procedureName varchar(128)
as
begin
	if @schemaName is null or @procedureName is null
	begin
		raiserror('#CreateDummyStoredProcedureIfNotExists procedure was called with one or more null arguments', 16, 1)
	end

	if not exists (select 1 from sys.schemas where name = @schemaName)
	begin
		declare @errorMessage varchar(max) = '#CreateDummyStoredProcedure procedure was called with the following invalid schemaName : ' + @schemaName
		raiserror(@errorMessage, 16, 1)
	end

	declare @sql varchar(max)
	if not exists (select 1 from sys.procedures p 
					inner join sys.schemas sc on 
						p.schema_id = sc.schema_id
					where
						p.name = @procedureName and
						sc.name = @schemaName)
	begin
		set @sql = 'create'	
	end
	else
	begin
		set @sql = 'alter'
	end

	set @sql = @sql + ' procedure [' + @schemaName + '].[' + @procedureName + ']'
		+ ' as begin select 1 end'

		exec (@sql)
end
go


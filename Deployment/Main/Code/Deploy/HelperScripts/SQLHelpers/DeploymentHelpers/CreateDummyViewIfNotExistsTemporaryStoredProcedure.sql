create proc #CreateDummyViewIfNotExists
	@schemaName varchar(128),
	@viewName varchar(128)
as
begin
	if @schemaName is null or @viewName is null
	begin
		raiserror('#CreateDummyViewIfNotExists procedure was called with one or more null arguments', 16, 1)
	end

	if not exists (select 1 from sys.schemas where name = @schemaName)
	begin
		declare @errorMessage varchar(max) = '#CreateDummyView procedure was called with the following invalid schemaName : ' + @schemaName
		raiserror(@errorMessage, 16, 1)
	end

	declare @sql varchar(max)

	if not exists (select 1 from sys.views v 
					inner join sys.schemas sc on 
						v.schema_id = sc.schema_id
					where
						v.name = @viewName and
						sc.name = @schemaName)
	begin
		set @sql = 'create'
	end
	else
	begin
		set @sql = 'alter'
	end

	set @sql = @sql + ' view [' + @schemaName + '].[' + @viewName + ']'
		+ ' as select 1 N'

		exec (@sql)
end

go


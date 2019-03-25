create proc #TableExists
	@schemaName varchar(128),
	@tableName varchar(128),
	@tableExists bit out
as
begin
	if @schemaName is null or @tableName is null
	begin
		raiserror('#TableExists procedure was called with one or more null arguments', 16, 1)
	end

	set @tableExists = 0
	if exists(select 1 from sys.tables t 
			  inner join sys.schemas sc on
				t.schema_id = sc.schema_id
				where 
					t.name = @tableName and
					sc.name = @schemaName)
	begin
		set @tableExists = 1
	end
end


go



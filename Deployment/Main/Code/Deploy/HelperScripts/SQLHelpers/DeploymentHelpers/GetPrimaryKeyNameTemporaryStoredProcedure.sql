create proc #GetPrimaryKeyName
	@schemaName varchar(128),
	@tableName varchar(128),
	@primaryKeyName varchar(128) out
as
begin
	if @schemaName is null or @tableName is null
	begin
		raiserror('#GetPrimaryKeyName procedure was called with one or more null arguments', 16, 1)
	end

	set @primaryKeyName = (select distinct
									kc.name 
								from sys.tables t
								inner join sys.schemas sc on 
									t.schema_id = sc.schema_id
								inner join sys.columns co on
									t.object_id = co.object_id
								inner join sys.key_constraints kc on
									co.object_id = kc.parent_object_id
								where
									sc.name = @schemaName
								and t.name = @tableName
								and kc.type = 'PK')
end


go



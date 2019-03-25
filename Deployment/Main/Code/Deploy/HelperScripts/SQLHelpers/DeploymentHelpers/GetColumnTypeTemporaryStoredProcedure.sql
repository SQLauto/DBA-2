create proc #GetColumntype
	@schemaName varchar(128),
	@tableName varchar(128),
	@columnName varchar(128),
	@columnType varchar(255) out
as
begin
	if @schemaName is null or @tableName is null or @columnName is null
	begin
		raiserror('#GetColumnType procedure was called with one or more null arguments', 16, 1)
	end

	set @columnType = (select tp.name from sys.tables st 
						inner join sys.schemas sc on st.schema_id = sc.schema_id
						inner join sys.columns c on c.object_id = st.object_id
						inner join sys.types tp on c.system_type_id = tp.system_type_id
						where
							sc.name = @schemaName and
							st.name = @tableName and
							c.name = @columnName)
	
end


go


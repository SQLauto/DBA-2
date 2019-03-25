create proc #ColumnExistsAndIsType
	@schemaName varchar(128),
	@tableName varchar(128),
	@columnName varchar(128),
	@columnType varchar(128),
	@columnExistsAndIsType bit out
as
begin
	if @schemaName is null or @tableName is null or @columnName is null or @columnType is null
	begin
		raiserror('#ColumnExistsAndIsType procedure was called with one or more null arguments', 16, 1)
	end

	set @columnExistsAndIsType = 0
	if exists(select 1 from sys.tables t
					inner join sys.schemas sc on 
						t.schema_id = sc.schema_id
					inner join sys.columns co on
						t.object_id = co.object_id
					inner join sys.types ty on
						ty.system_type_id= co.system_type_id
					where
						sc.name = @schemaName
					and t.name = @tableName
					and co.Name = @columnName
					and ty.name=@columnType)
	begin
		set @columnExistsAndIsType = 1
	end
end
go


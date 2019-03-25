create proc #ColumnExistsAndIsIdentity
	@schemaName varchar(128),
	@tableName varchar(128),
	@columnName varchar(128),
	@columnExistsAndIsIdentity bit out
as
begin
	if @schemaName is null or @tableName is null or @columnName is null
	begin
		raiserror('#ColumnExistsAndIsIdentity procedure was called with one or more null arguments', 16, 1)
	end

	set @columnExistsAndIsIdentity = 0
	if exists(select 1 from sys.tables t
					inner join sys.schemas sc on 
						t.schema_id = sc.schema_id
					inner join sys.columns co on
						t.object_id = co.object_id
					where
						sc.name = @schemaName
					and t.name = @tableName
					and co.Name = @columnName
					and co.is_identity = 1)
	begin
		set @columnExistsAndIsIdentity = 1
	end
end
go


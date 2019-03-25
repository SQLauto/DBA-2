create proc #CheckConstraintExists
	@schemaName varchar(128),
	@tableName varchar(128),
	@checkConstraintName varchar(128),
	@checkConstraintExists bit out
as
begin
	if @schemaName is null or @tableName is null or @checkConstraintName is null
	begin
		raiserror('#CheckConstraintExists procedure was called with one or more null arguments', 16, 1)
	end

	set @checkConstraintExists = 0
	if exists(select 1 from sys.objects o
				inner join sys.schemas s on s.schema_id = o.schema_id
				inner join sys.tables t on t.schema_id = s.schema_id
				where
					s.name = @schemaName
					and t.name = @tableName
					and o.name = @checkConstraintName)
	begin
		set @checkConstraintExists = 1
	end
end


go


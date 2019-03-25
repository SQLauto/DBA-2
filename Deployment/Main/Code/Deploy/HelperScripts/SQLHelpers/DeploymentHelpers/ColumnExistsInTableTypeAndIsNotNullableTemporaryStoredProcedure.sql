create proc #ColumnExistsInTableTypeAndIsNotNullable
	@schemaName varchar(128),
	@tableTypeName varchar(128),
	@columnName varchar(128),
	@columnExists bit out
as
begin
	if @schemaName is null or @tableTypeName is null or @columnName is null
	begin
		raiserror('#ColumnExistsInTableTypeAndIsNotNullable procedure was called with one or more null arguments', 16, 1)
	end

	set @columnExists = 0
	if exists(
				SELECT 1 
				FROM 
					sys.table_types tt
				INNER JOIN 
					sys.schemas sch ON tt.schema_id = sch.schema_id
				INNER JOIN 
					sys.columns c ON c.object_id = tt.type_table_object_id				
				WHERE 
					sch.name = @schemaName
				AND 
					tt.name = @tableTypeName
				AND 
					c.name = @columnName
				AND
					c.is_nullable = 0)
	begin
		set @columnExists = 1
	end
end
go


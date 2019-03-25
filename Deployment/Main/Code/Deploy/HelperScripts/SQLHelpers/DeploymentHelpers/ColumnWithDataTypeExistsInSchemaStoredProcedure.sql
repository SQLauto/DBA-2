
create proc #ColumnWithDataTypeExistsInSchema
	
	@schemaName varchar(128),
	@tableName varchar(128),
	@columnName varchar(128),
	@dataTypeName varchar(128),
	@columnWithDataTypeExistsInSchema bit out
as
begin
	if @dataTypeName is null or @tableName is null or @columnName is null or @schemaName is null
	begin
		raiserror('#ColumnWithDataTypeExistsInSchema procedure was called with one or more null arguments', 16, 1)
	end

	if exists(select * from INFORMATION_SCHEMA.COLUMNS					
					where
						TABLE_NAME = @tableName AND 
						COLUMN_NAME = @columnName AND
						DATA_TYPE = @dataTypeName AND
						TABLE_SCHEMA=@schemaName
						)
	begin
		set @columnWithDataTypeExistsInSchema = 1
	end
end
go



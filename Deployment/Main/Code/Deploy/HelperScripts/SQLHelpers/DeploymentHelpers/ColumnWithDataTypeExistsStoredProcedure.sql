create proc #ColumnWithDataTypeExists
	@dataTypeName varchar(128),
	@tableName varchar(128),
	@columnName varchar(128),
	@columnWithDataTypeExists bit out
as
begin
	if @dataTypeName is null or @tableName is null or @columnName is null
	begin
		raiserror('#ColumnWithDataTypeExists procedure was called with one or more null arguments', 16, 1)
	end

	set @columnWithDataTypeExists = 0
	if exists(select 1 from INFORMATION_SCHEMA.COLUMNS					
					where
						TABLE_NAME = @tableName AND 
						COLUMN_NAME = @columnName AND
						DATA_TYPE = @dataTypeName)
	begin
		set @columnWithDataTypeExists = 1
	end
end
go


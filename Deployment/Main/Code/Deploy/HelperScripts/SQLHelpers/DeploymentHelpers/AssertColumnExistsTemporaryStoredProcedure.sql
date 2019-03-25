create proc #AssertColumnExists
	@schemaName varchar(128),
	@tableName varchar(128),
	@columnName varchar(128)
as
begin
	
	declare @exists bit;
	exec #ColumnExists @schemaName, @tableName, @columnName, @exists out

	insert into deployment.PatchingPostValidationError (ValidationMessage, IsValid) values ('Column ''' + @schemaName + '.' + @tableName + '.' + @columnName + ''' does not exist', @exists);

end

go


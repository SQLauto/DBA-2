create proc #AssertTableExists
	@schemaName varchar(128),
	@tableName varchar(128)
as
begin
	
	declare @exists bit;
	exec #TableExists @schemaName, @tableName, @exists out

	insert into deployment.PatchingPostValidationError (ValidationMessage, IsValid) values ('Table ''' + @schemaName + '.' + @tableName + ''' does not exist', @exists);

end
go



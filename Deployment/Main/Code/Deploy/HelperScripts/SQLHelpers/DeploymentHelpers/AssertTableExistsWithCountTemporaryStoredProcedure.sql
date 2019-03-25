create proc #AssertTableExistsWithCount
	@schemaName varchar(128),
	@tableName varchar(128),
	@count bigint
as
begin
	
	declare @exists bit;
	exec #TableExistsWithCount @schemaName, @tableName, @count, @exists out

	insert into deployment.PatchingPostValidationError (ValidationMessage, IsValid) values ('Table ''' + @schemaName + '.' + @tableName + ''' does not exist or it does not have the expected row count of '+cast(@count as varchar(30))+'', @exists);

end
go



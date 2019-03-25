create proc #AssertSchemaExists
	@schemaName varchar(128)
as
begin
	
	declare @exists bit;
	exec #SchemaExists @schemaName, @exists out

	insert into deployment.PatchingPostValidationError (ValidationMessage, IsValid) values ('Schema ''' + @schemaName + ''' does not exist', @exists);

end
go



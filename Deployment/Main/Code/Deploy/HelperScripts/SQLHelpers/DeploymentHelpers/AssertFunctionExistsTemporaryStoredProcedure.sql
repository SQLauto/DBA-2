create proc #AssertFunctionExists
	@schemaName varchar(128),
	@functionName varchar(128)
as
begin
	
	declare @exists bit;
	exec #FunctionExists @schemaName, @functionName, @exists out

	insert into deployment.PatchingPostValidationError (ValidationMessage, IsValid) values ('Function ''' + @schemaName + '.' + @functionName + ''' does not exist', @exists);

end

go


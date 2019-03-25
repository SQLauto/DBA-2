create proc #AssertProcExists
	@schemaName varchar(128),
	@procName varchar(128)
as
begin
	
	declare @exists bit;
	exec #StoredProcedureExists @schemaName, @procName, @exists out

	insert into deployment.PatchingPostValidationError (ValidationMessage, IsValid) values ('Stored Procedure ''' + @schemaName + '.' + @procName + ''' does not exist', @exists);

end

go


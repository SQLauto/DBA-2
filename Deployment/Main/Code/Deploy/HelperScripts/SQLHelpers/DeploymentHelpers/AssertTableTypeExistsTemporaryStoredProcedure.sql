create proc #AssertTableTypeExists
	@schemaName varchar(128),
	@tableTypeName varchar(128)
as
begin
	
	declare @exists bit;
	exec #TableTypeExists @schemaName, @tableTypeName, @exists out

	insert into deployment.PatchingPostValidationError (ValidationMessage, IsValid) values ('TableType ''' + @schemaName + '.' + @tableTypeName + ''' does not exist', @exists);

end

go


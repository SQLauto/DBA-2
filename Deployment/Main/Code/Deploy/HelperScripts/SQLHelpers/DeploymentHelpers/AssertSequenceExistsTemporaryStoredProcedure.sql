create proc #AssertSequenceExists
	@schemaName varchar(128),
	@sequenceName varchar(128)
as
begin
	
	declare @exists bit;
	exec #SequenceExists @schemaName, @sequenceName, @exists out

	insert into deployment.PatchingPostValidationError (ValidationMessage, IsValid) values ('Sequence ''' + @schemaName + '.' + @sequenceName + ''' does not exist', @exists);

end
go



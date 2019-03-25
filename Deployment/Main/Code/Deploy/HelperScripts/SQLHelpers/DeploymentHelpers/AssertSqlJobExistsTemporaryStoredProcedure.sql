create proc #AssertSqlJobExists
	@jobName varchar(128)
as
begin
	
	declare @exists bit;
	exec #SqlJobExists @jobName, @exists out

	insert into deployment.PatchingPostValidationError (ValidationMessage, IsValid) values ('Job ''' + @jobName + ''' does not exist', @exists);

end
go



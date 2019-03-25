create proc #AssertPrimaryKeyExists
	@schemaName varchar(128),
	@tableName varchar(128)
as
begin
	
	declare @pkName varchar(128);
	exec #GetPrimaryKeyName @schemaName, @tableName, @pkName out;
	declare @exists bit = 0;
	if (@pkName is not null)
	begin
		set @exists = 1
	end

	insert into deployment.PatchingPostValidationError (ValidationMessage, IsValid) values ('Primary key expected on: ''' + @schemaName + '.' + @tableName + ''' does not exist', @exists);

end

go


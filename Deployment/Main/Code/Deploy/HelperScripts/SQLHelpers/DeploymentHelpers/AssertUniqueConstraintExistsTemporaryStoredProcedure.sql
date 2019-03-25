create proc #AssertUniqueConstraintExists
	@schemaName varchar(128),
	@tableName varchar(128),
	@uniqueConstraintName varchar(128)
as
begin
	
	declare @exists bit;
	exec #UniqueConstraintExists @schemaName, @tableName, @uniqueConstraintName, @exists out

	insert into deployment.PatchingPostValidationError (ValidationMessage, IsValid) values ('Unique Constraint ''' + @schemaName + '.' + @tableName + '.' + @uniqueConstraintName + ''' does not exist', @exists);

end

go


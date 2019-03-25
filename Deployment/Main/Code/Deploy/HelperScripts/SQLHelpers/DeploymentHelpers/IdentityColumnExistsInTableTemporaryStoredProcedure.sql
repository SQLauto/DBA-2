create proc #IdentityColumnExistsInTable
	
	@schemaName varchar(128),
	@tableName  varchar(128),
	@columnName varchar(128),
	
	@identityColumnExistsInTable bit out
as
begin
	if (@schemaName is null or @tableName is null or @columnName is null)
	begin
		raiserror('#IdentityColumnExistsInTable procedure was called with one or more null arguments', 16, 1)
	end

	set @identityColumnExistsInTable = 0

	if exists(
				SELECT 1 
				FROM sys.identity_columns ic
				INNER JOIN sys.all_objects ao ON ic.object_id = ao.object_id
				INNER JOIN sys.schemas sc ON ao.schema_id = sc.schema_id
				WHERE
					sc.name = @schemaName
					AND
					ao.name = @tableName
					AND
					ic.name = @columnName
			)

	begin
		set @identityColumnExistsInTable = 1
	end
	
end

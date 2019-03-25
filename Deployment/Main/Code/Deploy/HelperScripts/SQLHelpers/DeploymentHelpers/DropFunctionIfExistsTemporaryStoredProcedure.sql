create proc #DropFunctionIfExists
	@schemaName varchar(128),
	@functionName varchar(128)
as
begin
	if @schemaName is null or @functionName is null
	begin
		raiserror('#CreateDummyFunctionIfNotExists procedure was called with one or more null arguments', 16, 1)
	end

	if not exists (select 1 from sys.schemas where name = @schemaName)
	begin
		declare @errorMessage varchar(max) = '#CreateDummFunction procedure was called with the following invalid schemaName : ' + @schemaName
		raiserror(@errorMessage, 16, 1)
	end
	declare @sql varchar(max)

	if exists (select 1 from sys.objects o 
					inner join sys.schemas sc on 
						o.schema_id = sc.schema_id
					where
						o.name = @functionName and
						sc.name = @schemaName and
						o.type in ('FN', 'IF', 'TF', 'FS', 'FT')
						)
	begin
		EXEC ('drop  function [' + @schemaName + '].[' + @functionName + ']')
	end

end

go


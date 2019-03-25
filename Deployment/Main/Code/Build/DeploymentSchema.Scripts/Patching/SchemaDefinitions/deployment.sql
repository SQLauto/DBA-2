go
	declare @schemaExists bit = 0
	if exists (select 1 from sys.schemas where name = 'deployment')
	begin
		set @schemaExists = 1
	end
	
	if (@schemaExists = 0)
	begin
		exec('create schema deployment')
	end
	
	set @schemaExists = 0
	if exists (select 1 from sys.schemas where name = 'patching')
	begin
		set @schemaExists = 1
	end
	
	if (@schemaExists = 0)
	begin
		exec('create schema patching')
	end
go
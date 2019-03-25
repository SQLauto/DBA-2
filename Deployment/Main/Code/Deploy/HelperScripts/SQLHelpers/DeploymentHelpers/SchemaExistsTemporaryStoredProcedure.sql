create proc #SchemaExists
	@schemaName varchar(128),
	@schemaExists bit out
as
begin
	if @schemaName is null
	begin
		raiserror('#SchemaExists procedure was called with one or more null arguments', 16, 1)
	end

	set @schemaExists = 0
	if exists(select 1 from sys.schemas sc 
				where sc.name = @schemaName)
	begin
		set @schemaExists = 1
	end
end



go


create proc #StoredProcedureExists
	@schemaName varchar(128),
	@procedureName varchar(128),
	@procedureExists bit out
as
begin
	if @schemaName is null or @procedureName is null
	begin
		raiserror('#StoredProcedureExists procedure was called with one or more null arguments', 16, 1)
	end

	set @procedureExists = 0
	if exists(select 1 from sys.procedures p 
			  inner join sys.schemas sc on
				p.schema_id = sc.schema_id
				where 
					p.name = @procedureName and
					sc.name = @schemaName)
	begin
		set @procedureExists = 1
	end
end



go


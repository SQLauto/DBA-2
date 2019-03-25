create proc #FunctionExists
	@schemaName varchar(128),
	@functionName varchar(128),
	@functionExists bit out
as
begin
	if @schemaName is null or @functionName is null
	begin
		raiserror('#FunctionExists procedure was called with one or more null arguments', 16, 1)
	end

	set @functionExists = 0
	if exists(select 1 from sys.objects o 
					inner join sys.schemas sc on 
						o.schema_id = sc.schema_id
					where
						o.name = @functionName and
						sc.name = @schemaName and
						o.type in ('FN', 'IF', 'TF', 'FS', 'FT'))
	begin
		set @functionExists = 1
	end
end


go


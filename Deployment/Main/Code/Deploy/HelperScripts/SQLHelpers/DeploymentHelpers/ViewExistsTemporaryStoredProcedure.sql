create proc #ViewExists
	@schemaName varchar(128),
	@viewName varchar(128),
	@viewExists bit out
as
begin
	if @schemaName is null or @viewName is null
	begin
		raiserror('#ViewExists procedure was called with one or more null arguments', 16, 1)
	end

	set @viewExists = 0
	if exists(select 1 from sys.views v 
			  inner join sys.schemas sc on
				v.schema_id = sc.schema_id
				where 
					v.name = @viewName and
					sc.name = @schemaName)
	begin
		set @viewExists = 1
	end
end;

go


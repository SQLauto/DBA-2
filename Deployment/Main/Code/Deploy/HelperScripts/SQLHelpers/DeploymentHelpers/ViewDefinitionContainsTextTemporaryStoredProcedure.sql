create proc #ViewDefinitionContainsText
	@schemaName varchar(128),
	@viewName varchar(128),
	@searchText nvarchar(max),
	@viewDefinitionContainsSearchText bit out
as
begin
	if @schemaName is null or @viewName is null or @searchText is null
	begin
		raiserror('#ViewDefinitionContainsText procedure was called with one or more null arguments', 16, 1)
	end
	
	set @viewDefinitionContainsSearchText = 0
	
	set @searchText = '%' + @searchText + '%'
	if exists (select 1 from sys.views v 
				inner join sys.schemas sc on
				v.schema_id = sc.schema_id
				where
					v.name =  @viewName and
					sc.name = @schemaName and
					object_definition(v.object_id) like @searchText)
	begin
		set @viewDefinitionContainsSearchText = 1
	end
end

go


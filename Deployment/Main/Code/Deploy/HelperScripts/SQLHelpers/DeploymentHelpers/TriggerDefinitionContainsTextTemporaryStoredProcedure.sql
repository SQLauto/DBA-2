create proc #TriggerDefinitionContainsText
	@schemaName varchar(128),
	@triggerName varchar(128),
	@searchText nvarchar(max),
	@triggerDefinitionContainsSearchText bit out
as
begin
	if @schemaName is null or @triggerName is null or @searchText is null
	begin
		raiserror('#TriggerDefinitionContainsText procedure was called with one or more null arguments', 16, 1)
	end
	
	set @triggerDefinitionContainsSearchText = 0
	
	set @searchText = '%' + @searchText + '%'
	if exists (select 1 from sys.triggers t 
				inner join sys.objects ob on 
					t.object_id = ob.object_id
				inner join sys.schemas sc on
				ob.schema_id = sc.schema_id
				where
					t.name =  @triggerName and
					sc.name = @schemaName and
					object_definition(t.object_id) like @searchText)
	begin
		set @triggerDefinitionContainsSearchText = 1
	end
end


go


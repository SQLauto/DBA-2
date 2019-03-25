create proc #FunctionDefinitionContainsText
	@schemaName varchar(128),
	@functionName varchar(128),
	@searchText nvarchar(max),
	@functionDefinitionContainsSearchText bit out
as
begin
	if @schemaName is null or @functionName is null or @searchText is null
	begin
		raiserror('#FunctionDefinitionContainsText procedure was called with one or more null arguments', 16, 1)
	end
	
	set @FunctionDefinitionContainsSearchText = 0
	
	set @searchText = '%' + @searchText + '%'
	if exists (select 1 from sys.functions f 
				inner join sys.schemas sc on
				f.schema_id = sc.schema_id
				where
					f.name =  @functionName and
					sc.name = @schemaName and
					object_definition(t.object_id) like @searchText)
	begin
		set @functionDefinitionContainsSearchText = 1
	end
end


go


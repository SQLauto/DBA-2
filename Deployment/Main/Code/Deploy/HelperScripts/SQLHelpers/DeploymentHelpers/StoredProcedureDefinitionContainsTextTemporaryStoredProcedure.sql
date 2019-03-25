create proc #StoredProcedureDefinitionContainsText
	@schemaName varchar(128),
	@storedProcedureName varchar(128),
	@searchText nvarchar(max),
	@storedProcedureDefinitionContainsSearchText bit out
as
begin
	if @schemaName is null or @storedProcedureName is null or @searchText is null
	begin
		raiserror('#StoredProcedureDefinitionContainsText procedure was called with one or more null arguments', 16, 1)
	end
	
	set @storedProcedureDefinitionContainsSearchText = 0
	
	set @searchText = '%' + @searchText + '%'
	if exists (select 1 from sys.procedures t 
				inner join sys.schemas sc on
				t.schema_id = sc.schema_id
				where
					t.name =  @storedProcedureName and
					sc.name = @schemaName and
					object_definition(t.object_id) like @searchText)
	begin
		set @storedProcedureDefinitionContainsSearchText = 1
	end
end


go


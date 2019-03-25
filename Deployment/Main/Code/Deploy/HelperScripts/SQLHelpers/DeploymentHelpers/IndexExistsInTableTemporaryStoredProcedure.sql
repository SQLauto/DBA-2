create proc #IndexExistsInTable
	
	@schemaname varchar(128),
	@tablename  varchar(128),
	@indexName varchar(128),
	
	@indexExistsInTable bit out
as
begin
	if (@schemaname is null or @tablename is null or @indexName is null)
	begin
		raiserror('#IndexExistsInTable procedure was called with one or more null arguments', 16, 1)
	end

	set @indexExistsInTable = 0
	if exists(select 1 from sys.indexes idx
	WHERE OBJECT_NAME(object_id) = @tablename
	AND OBJECT_SCHEMA_NAME(object_id) = @schemaname
					and  idx.name = @indexName)
	begin
		set @indexExistsInTable = 1
	end
	
end


go



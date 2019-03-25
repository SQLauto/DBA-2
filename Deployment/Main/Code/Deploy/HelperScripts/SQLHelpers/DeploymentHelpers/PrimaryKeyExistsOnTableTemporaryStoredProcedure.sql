create proc #PrimaryKeyExistsOnTable
	@schemaname varchar(128),
	@tablename  varchar(128),
	
	@pkExistsOnTable bit out
as
begin
	if (@schemaname is null or @tablename is null)
	begin
		raiserror('#PrimaryKeyExistsOnTable procedure was called with one or more null arguments', 16, 1)
	end

	set @pkExistsOnTable = 0

	if exists
	(
		SELECT		1 
		FROM		sys.indexes ind
		INNER JOIN	sys.tables tbl ON ind.object_id = tbl.object_id
		INNER JOIN	sys.schemas sch ON tbl.schema_id = sch.schema_id
		WHERE		ind.is_primary_key = 1
					AND
					sch.name = @schemaname
					AND
					tbl.name = @tablename	
	)
	begin
		set @pkExistsOnTable = 1
	end
	
end


go



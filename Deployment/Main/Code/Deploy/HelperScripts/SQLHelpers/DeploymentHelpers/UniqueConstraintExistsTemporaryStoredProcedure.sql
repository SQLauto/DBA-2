create proc #UniqueConstraintExists
	@schemaName varchar(128),
	@tableName varchar(128),
	@uniqueConstraintName varchar(128),
	@uniqueConstraintExists bit out
as
begin
	if @schemaName is null or @tableName is null or @uniqueConstraintName is null
	begin
		raiserror('#UniqueConstraintExists procedure was called with one or more null arguments', 16, 1)
	end

	set @uniqueConstraintExists = 0
	if exists(select 1 from sys.indexes si
                     inner join sys.tables t on 
                           si.object_id = t.object_id
                     inner join sys.schemas sc on
                           sc.schema_id = t.schema_id
                     where 
                           si.name = @uniqueConstraintName
                     and t.name = @tableName
                     and sc.name = @schemaName)
	begin
		set @uniqueConstraintExists = 1
	end
end;

go



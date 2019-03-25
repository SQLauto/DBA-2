create proc #TableTypeExists @schemaName varchar(128), @tableTypeName varchar(128), @tableTypeExists bit out
as
begin

set @tableTypeExists = 0

if exists (
	select 1 from sys.table_types tt 
	inner join sys.schemas sc on
		tt.schema_id = sc.schema_id 
	where
		tt.name = @tableTypeName
	and sc.name = @schemaName
)
begin
	set @tableTypeExists = 1
end
end;


go



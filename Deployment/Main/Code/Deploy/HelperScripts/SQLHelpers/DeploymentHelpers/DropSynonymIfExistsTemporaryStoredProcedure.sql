create proc #DropSynonymIfExists
	@schemaName varchar(128),
	@synonymName varchar(128)
as
begin
	declare @exists bit 
	exec #SynonymExists @schemaName, @synonymName, @exists out
	if (@exists = 1)
	begin
		declare @sql varchar(max) = 'drop synonym [' + @schemaName + '].['+ @synonymName +']'
		exec (@sql)
	end
end;


go


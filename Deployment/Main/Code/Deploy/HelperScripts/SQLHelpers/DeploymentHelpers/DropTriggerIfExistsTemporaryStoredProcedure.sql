create proc #DropTriggerIfExists
	@schemaName varchar(128),
	@triggerName varchar(128)
as
begin
	if @schemaName is null or @triggerName is null
	begin
		raiserror('#DropTriggerIfExists procedure was called with one or more null arguments', 16, 1)
	end

	if exists (select 1 
			    from 
					sys.triggers tr 
				inner join sys.tables t on 
					t.object_id = tr.parent_id 
				inner join sys.schemas sc on 
					t.schema_id = sc.schema_id
				where
					sc.name = @schemaName
				and tr.Name = @triggerName)
	begin
		declare @triggerToDrop varchar(128) = @schemaName + '.' + @triggerName
		exec('drop trigger ' + @triggerToDrop)
	end
	
end


go


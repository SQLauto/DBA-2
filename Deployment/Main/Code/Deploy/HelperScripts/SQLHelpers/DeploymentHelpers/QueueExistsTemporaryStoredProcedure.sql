create procedure #QueueExists 
	@schemaName varchar(128),
	@queueName varchar(128),
	@queueExists bit out
as
begin
	set @queueExists = 0
	if exists (select 1 from sys.service_queues sq 
				inner join sys.schemas sc on
					sq.schema_id = sc.schema_id
				where
					sc.name = @schemaName and
					sq.name = @queueName )
	begin
		set @queueExists = 1
	end
end
;


go


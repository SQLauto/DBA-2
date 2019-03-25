create procedure #MessageTypeExists 
	@messageTypeName varchar(128),
	@messageTypeExists bit out
as
begin
	set @messageTypeExists = 0
	if exists (select 1 from sys.service_message_types
				where name = @messageTypeName)
	begin
		set @messageTypeExists = 1
	end
end;


go


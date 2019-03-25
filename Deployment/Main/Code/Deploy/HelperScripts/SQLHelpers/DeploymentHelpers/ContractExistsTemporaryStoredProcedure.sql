create procedure #ContractExists
	@contractName varchar(128),
	@contractExists bit out
as
begin

	set @contractExists = 0
	if exists (select 1 from sys.service_contracts
				where name = @contractName)
	begin
		set @contractExists = 1	
	end
end

go


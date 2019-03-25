create procedure #ServiceExists 
	@serviceName varchar(128),
	@serviceExists bit out
as
begin
	set @serviceExists = 0
	if exists (select 1 from sys.services s 
				where
					s.name = @serviceName )
	begin
		set @serviceExists = 1
	end
end
;


go


create proc #SqlJobExists
	@jobName varchar(128),
	@jobExists bit out
as
begin
	if @jobName is null 
	begin
		raiserror('#SqlJobExists procedure was called with null jobname this is not permitted', 16, 1)
	end
	
	set @jobExists = 0
	if exists(select 
				1 
			  from 
				msdb.dbo.sysjobs 
			  where 
				name = @jobName)
	begin
		set @jobExists = 1
	end
end



go



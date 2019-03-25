create proc #TriggerExists
	@triggerName varchar(128),
	@triggerExists bit out
as
begin
	if @triggerName is null
	begin
		raiserror('#TriggerExists procedure was called with one or more null arguments', 16, 1)
	end

	set @triggerExists = 0
	if exists(select 1 from sys.triggers tr
					where tr.name = @triggerName)
	begin
		set @triggerExists = 1
	end
end

go


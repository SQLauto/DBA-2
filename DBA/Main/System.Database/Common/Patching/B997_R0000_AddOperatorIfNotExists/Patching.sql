if not exists(select 1 from msdb.dbo.sysoperators where name = 'The CE DBA Team')
begin
	EXEC msdb.dbo.sp_add_operator @name=N'The CE DBA Team', 
			@enabled=1, 
			@weekday_pager_start_time=90000, 
			@weekday_pager_end_time=180000, 
			@saturday_pager_start_time=90000, 
			@saturday_pager_end_time=180000, 
			@sunday_pager_start_time=90000, 
			@sunday_pager_end_time=180000, 
			@pager_days=0, 
			@email_address=N'cedbaops@tfl.gov.uk', 
			@category_name=N'[Uncategorized]'
end

create procedure report.DateRangeOfInterestCreate
	@start datetime,
	@end datetime
as
begin

	if (object_id('tempdb..#DateRangeOfInterest') is not null) 
	begin
		drop table #DateRangeOfInterest;
	end

	

	declare @startDateKey int;
	declare @startTimeKey int;
	exec dbo.ToTemporalKeys @start, @startDateKey out,  @startTimeKey out;

	declare @endDateKey int;
	declare @endTimeKey int;
	exec dbo.ToTemporalKeys @end, @endDateKey out,  @endTimeKey out;

	create table #DateRangeOfInterest
	(
		DateKey int,
		TimeKey int,
		constraint pk_DateRangeOfInterest primary key clustered (DateKey, TimeKey)
	)

	insert into #DateRangeOfInterest (DateKey, TimeKey)
	select
		dd.DateKey,
		dt.TimeKey
	from
		dbo.DimTime dt
	cross join dbo.DimDate dd 
	where
		dd.DateKey >= @startDateKey
	and dd.DateKey <= @endDateKey
	order by 
		dd.DateKey,
		dt.TimeKey

	
	delete from #DateRangeOfInterest where 
		DateKey = @startDateKey
	and TimeKey < @startTimeKey

	delete from #DateRangeOfInterest where 
		DateKey = @endDateKey
	and TimeKey > @endTimeKey

end
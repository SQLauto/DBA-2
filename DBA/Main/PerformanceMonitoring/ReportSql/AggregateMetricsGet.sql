
create procedure report.AggregateMetricsGet
	@databaseName varchar(128),
	@environmentName varchar(100),
	@start datetime,
	@end datetime
as
begin
	
	exec report.DateRangeOfInterestCreate @start, @end

	declare @oneSecondOfMicroSeconds bigint = 1000000
	declare @oneMillisecondOfMicroSeconds bigint = 1000

	select 
		sum(p.TotalLogicalReads + p.TotalLogicalWrites) TotalIops,
		sum(p.ExecutionCount) TotalNumberExecutions,
		sum(p.TotalWorkerTime)  / @oneSecondOfMicroSeconds TotalWorkerTimeSeconds,
		sum(p.TotalPhysicalReads) TotalPhysicalReads,
		sum(p.TotalLogicalWrites) TotalLogicalWrites,
		sum(p.TotalLogicalReads) TotalLogicalReads,
		sum(p.TotalElapsedTime) / @oneSecondOfMicroSeconds TotalElapsedTimeSeconds,
		max(p.TotalElapsedTime) / @oneSecondOfMicroSeconds LongestRunningTimeSeconds,
		sum(p.TotalLogicalReads + p.TotalLogicalWrites) / sum(p.ExecutionCount) AverageIopsPerCall,
		sum(p.TotalElapsedTime) /  sum(p.ExecutionCount) / @oneMillisecondOfMicroSeconds AverageElapsedTimeMilliSeconds,
		avg(p.TotalLogicalReads + p.TotalLogicalWrites) AverageIopsPerSproc
	from
		dbo.FactStoredProcedures p
	inner join dbo.DimStoredProcedures sp on
		p.StoredprocedureKey = sp.StoredProcedureKey
	inner join #DateRangeOfInterest dri on
		p.DateKey = dri.DateKey and
		p.TimeKey = dri.TimeKey
	where
		sp.DatabaseName = @databaseName and
		sp.FriendlyHostName = @environmentName
	
end

go


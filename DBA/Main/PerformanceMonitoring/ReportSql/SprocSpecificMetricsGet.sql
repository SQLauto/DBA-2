
create procedure report.SprocSpecificMetricsGet
	@databaseName varchar(128),
	@environmentName varchar(100),
	@storedProcedureName varchar(128),
	@start datetime,
	@end datetime
as
begin
	
	declare @oneSecondOfMicroSeconds bigint = 1000000
	declare @oneMillisecondOfMicroSeconds bigint = 1000

	declare @latestQueryPlan xml
	select 
		@latestQueryPlan = p.QueryPlan
	from 
		dbo.DimStoredProcedures p
	where
		p.ProcedureName = @storedProcedureName
	and p.DatabaseName = @databaseName
	and	p.FriendlyHostName = @environmentName
	having 
		max(p.StartDate) <= @end


	select 
		sp.ProcedureName,
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
		avg(p.TotalLogicalReads + p.TotalLogicalWrites) AverageIopsPerSproc,
		Sum(sp.QueryPlanCount) QueryPlanCount,
		@latestQueryPlan QueryPlan
	from
		dbo.FactStoredProcedures p
	inner join dbo.DimStoredProcedures sp on
		p.StoredprocedureKey = sp.StoredProcedureKey
	inner join #DateRangeOfInterest dri on
		p.DateKey = dri.DateKey and
		p.TimeKey = dri.TimeKey
	where
		sp.DatabaseName = @databaseName and
		sp.FriendlyHostName = @environmentName and
		sp.ProcedureName = @storedProcedureName
	group by 
		sp.ProcedureName	
end

go



create procedure report.TotalWorkerTimeGet
	@databaseName varchar(128),
	@environmentName varchar(100),
	@start datetime,
	@end datetime
as
begin

	declare @oneSecondOfMicroSeconds bigint = 1000000
	declare @oneMillisecondOfMicroSeconds bigint = 1000

	select 
		sp.ProcedureName,
		sum(p.TotalWorkerTime)  / @oneSecondOfMicroSeconds TotalWorkerTimeSeconds
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
	group by 
		sp.ProcedureName
	
end

go


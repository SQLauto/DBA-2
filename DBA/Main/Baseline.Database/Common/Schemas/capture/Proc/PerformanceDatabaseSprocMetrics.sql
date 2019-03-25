EXEC #CreateDummyStoredProcedureIfNotExists 'capture', 'PerformanceDatabaseSprocMetrics'
GO
alter procedure capture.PerformanceDatabaseSprocMetrics 
	@dbName sysname,
	@procName sysname,
	@start datetimeoffset,
	@end datetimeoffset
as
begin

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

declare @totalExecutions bigint =
	(select 
		sum(execution_count) ExecutionCount
	from CaptureProcData CD
  JOIN CaptureProcResults CR ON CD.ID=CR.CaptureProcDataID
   where 
	[database] = @dbName
and ProcedureName = @procName
and	capturedate>=@start 
and capturedate<@end)

--todo this needs to work from the datawarehouse
declare @executionPlan xml = (select top 1 query_plan from [capture].[WhoIsActive_20150909] where query_plan is not null)

declare @oneSecondOfMicroSeconds bigint = 1000000
declare @oneMillisecondOfMicroSeconds bigint = 1000
	select 
		@executionPlan LatestExecutionPlan,
		(sum(total_logical_writes)+ sum(total_logical_reads)) TotalIops,
		@totalExecutions TotalNumberOfExecutions,
		sum(total_worker_time) / @oneSecondOfMicroSeconds TotalWorkerTimeSeconds,
		sum(total_physical_reads) TotalPhysicalReads,
		sum(total_logical_writes) TotalLogicalWrites, 
		sum(total_logical_reads) TotalLogicalReads, 
		sum(total_elapsed_time) / @oneSecondOfMicroSeconds TotalElapsedTimeSecond,
		max(total_elapsed_time) / @oneSecondOfMicroSeconds LongestRunningTimeSecond,
		(sum(total_logical_writes)+ sum(total_logical_reads)) / @totalExecutions AverageIopsPerCall,
		(sum(total_elapsed_time) / @totalExecutions)/ @oneMillisecondOfMicroSeconds AverageElapsedTimeMilliSeconds,
		(sum(total_logical_writes)+ sum(total_logical_reads)) / @totalExecutions AverageIops
	from CaptureProcData CD
  JOIN CaptureProcResults CR ON 
	CD.ID=CR.CaptureProcDataID
  where 
	[database] = @dbName
and ProcedureName = @procName
and	capturedate>=@start 
and capturedate<@end

end
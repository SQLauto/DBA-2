EXEC #CreateDummyStoredProcedureIfNotExists 'capture', 'PerformanceDatabaseMacroMetrics'
GO
alter procedure capture.PerformanceDatabaseMacroMetrics 
	@dbName sysname,
	@start datetimeoffset,
	@end datetimeoffset
as
begin

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

declare @totalExecutions bigint
declare @averageExecutionPerProc bigint

select 
	@totalExecutions = sum(ExecutionCount),
	@averageExecutionPerProc = avg(ExecutionCount)
from
	(select 
		ProcedureName,
		sum(execution_count) ExecutionCount
	from capture.StoredProcedureWindow CD
  JOIN capture.StoredProcedureStats CR ON CD.ID=CR.CaptureProcDataID
   where 
	[database] = @dbName
and	capturedate>=@start 
and capturedate<@end
group by ProcedureName) a

declare @oneSecondOfMicroSeconds bigint = 1000000
declare @oneMillisecondOfMicroSeconds bigint = 1000
	select 
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
		@averageExecutionPerProc AverageNumberOfExecutionsPerSproc,
		(sum(total_logical_writes)+ sum(total_logical_reads)) / @averageExecutionPerProc AverageIopsPerSproc
	from capture.StoredProcedureWindow CD
  JOIN capture.StoredProcedureStats CR ON 
	CD.ID=CR.CaptureProcDataID
  where 
	[database] = @dbName
and	capturedate>=@start 
and capturedate<@end

end
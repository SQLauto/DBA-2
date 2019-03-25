EXEC #CreateDummyStoredProcedureIfNotExists 'capture', 'SlowRunningProcs'
GO
alter  procedure [capture].[SlowRunningProcs]
  as
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	
    select  top 30 [Database],ProcedureName,sum(execution_count) execution_count,
						AVG(total_worker_time) avg_worker_time,
						 AVG(total_physical_reads) avg_physical_reads,
						 AVG(total_logical_writes) avg_logical_writes, 
						 	 AVG(total_logical_reads) avg_logical_reads, 
							 	 AVG(total_elapsed_time) avg_elapsed_time,
								  MAX(total_elapsed_time) max_avg_elapsed_time,
								  	  MIN(total_elapsed_time) min_avg_elapsed_time,    
								 	 AVG(total_logical_writes) avg_logical_writes
	from CaptureProcData CD
  JOIN CaptureProcResults CR ON CD.ID=CR.CaptureProcDataID
  where capturedate>=dateadd(day, datediff(day, 0, getdate()), 0) and
      capturedate<dateadd(day, datediff(day, 0, getdate())+1, 0)
	 	  and [database] not in ('System')
	  group by ProcedureName,[Database]
	  order by sum(execution_count) desc


	      select  top 30 [Database],ProcedureName,sum(execution_count) execution_count,
						AVG(total_worker_time) avg_worker_time,
						 AVG(total_physical_reads) avg_physical_reads,
						 AVG(total_logical_writes) avg_logical_writes, 
						 	 AVG(total_logical_reads) avg_logical_reads, 
							 	 AVG(total_elapsed_time) avg_elapsed_time,
								  MAX(total_elapsed_time) max_avg_elapsed_time,
								  	  MIN(total_elapsed_time) min_avg_elapsed_time,    
								 	 AVG(total_logical_writes) avg_logical_writes
	from CaptureProcData CD
  JOIN CaptureProcResults CR ON CD.ID=CR.CaptureProcDataID
  where capturedate>=dateadd(day, datediff(day, 0, getdate()), 0) and
      capturedate<dateadd(day, datediff(day, 0, getdate())+1, 0)
	  and [database] not in ('System')
	   	  group by ProcedureName,[Database]
	  order by AVG(total_worker_time) desc
	 
	 
	 
	      select  top 30 [Database],ProcedureName,sum(execution_count) execution_count,
						AVG(total_worker_time) avg_worker_time,
						 AVG(total_physical_reads) avg_physical_reads,
						 AVG(total_logical_writes) avg_logical_writes, 
						 	 AVG(total_logical_reads) avg_logical_reads, 
							 	 AVG(total_elapsed_time) avg_elapsed_time,
								  MAX(total_elapsed_time) max_avg_elapsed_time,
								  	  MIN(total_elapsed_time) min_avg_elapsed_time,    
								 	 AVG(total_logical_writes) avg_logical_writes
	from CaptureProcData CD
  JOIN CaptureProcResults CR ON CD.ID=CR.CaptureProcDataID
  where capturedate>=dateadd(day, datediff(day, 0, getdate()), 0) and
      capturedate<dateadd(day, datediff(day, 0, getdate())+1, 0)
	  and [database] not in ('System')
	  group by ProcedureName,[Database]
	  order by MAX(total_elapsed_time) desc
go

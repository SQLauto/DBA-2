EXEC #CreateDummyStoredProcedureIfNotExists 'dbo', 'JobFailures'
GO

ALTER PROCEDURE [dbo].[JobFailures]
AS
/*

        Author:  Ben Anderson
        Date:    18/02/04
        Function:  Returns all failed job steps that are in msdb.dbo.syshistory that are 
                        not currently running or haven't been succesfully re-ran
	Used by the Failed Jobs Job to collect data
*/
SET NOCOUNT ON
set transaction isolation level read uncommitted;

CREATE TABLE #job_results (job_id                UNIQUEIDENTIFIER NOT NULL,
                            last_run_date         INT              NOT NULL,
                            last_run_time         INT              NOT NULL,
                            next_run_date         INT              NOT NULL,
                            next_run_time         INT              NOT NULL,
                            next_run_schedule_id  INT              NOT NULL,
                            requested_to_run      INT              NOT NULL, 
                            request_source        INT              NOT NULL,
                            request_source_id     sysname          COLLATE database_default NULL,
                            running               INT              NOT NULL, 
                            current_step          INT              NOT NULL,
                            current_retry_attempt INT              NOT NULL,
                            job_state             INT              NOT NULL)

    INSERT INTO #job_results
    EXECUTE master.dbo.xp_sqlagent_enum_jobs 1, sa, null

    DELETE FROM #job_results
        WHERE running = 0

   create clustered index temp1  on #job_results (job_id)

		TRUNCATE TABLE Job_Failures
		
		INSERT INTO dbo.Job_Failures
        select js.job_id, @@servername, sj.name ,js.step_id, convert(datetime,convert(varchar(10),convert(datetime,convert(varchar(8),case js.last_run_date when 0 then '19500101' else js.last_run_date end)),101) + ' ' + 
        	case datalength(convert(varchar(6),js.last_run_time))
        	when 6 then (select substring(convert(varchar(6),js.last_run_time),1,2) + ':' + substring(convert(varchar(6),js.last_run_time),3,2) + ':' + substring(convert(varchar(6),js.last_run_time),5,2))
        	when 5 then (select '0' + substring(convert(varchar(6),js.last_run_time),1,1) + ':' + substring(convert(varchar(6),js.last_run_time),2,2) + ':' + substring(convert(varchar(6),js.last_run_time),4,2))
        	when 4 then (select '00:' + substring(convert(varchar(6),js.last_run_time),1,2) + ':' + substring(convert(varchar(6),js.last_run_time),3,2))
        	when 3 then (select '00:0' + substring(convert(varchar(6),js.last_run_time),1,1) + ':' + substring(convert(varchar(6),js.last_run_time),2,2))
        	when 2 then (select '00:00:' + substring(convert(varchar(6),js.last_run_time),1,2))
        	when 1 then (select '00:00:0' + substring(convert(varchar(6),js.last_run_time),1,1))
        	end) AS 'run_time',JR.running
        from msdb.dbo.sysjobsteps js 
                join msdb.dbo.sysjobs sj
                on js.job_id = sj.job_id
			LEFT JOIN #job_results JR 
				ON JR.job_id=js.job_id
        where --js.job_id not in (select job_id from #job_results) and 
				sj.enabled = 1
                and js.last_run_outcome = 0
                --and js.last_run_time <> 0
                and js.last_run_date <> 0

        drop table #job_results

GO

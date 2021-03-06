EXEC #CreateDummyStoredProcedureIfNotExists 'dbo', 'JobDurations'
GO

ALTER PROCEDURE [dbo].[JobDurations]
As

/*

        Author:  Ben Anderson
        Date:    18/02/04
        Function:Returns job run time  information from the daily updated table JobAnalysis.

*/
set transaction isolation level read uncommitted;

SELECT 	server, SUBSTRING(jobname,1,75) as 'Job',
 convert(varchar(10),dateadd(s,avg(datediff(s,rundatetime,rundatetime+cast(duration_txt as datetime))),0),108) as [AvgDuration],
 case datalength(convert(varchar(6),MIN(duration_int)))
                        when 6 then (select substring(convert(varchar(6),MIN(duration_int)),1,2) + ':' + substring(convert(varchar(6),MIN(duration_int)),3,2) + ':' + substring(convert(varchar(6),MIN(duration_int)),5,2))
                        when 5 then (select '0' + substring(convert(varchar(6),MIN(duration_int)),1,1) + ':' + substring(convert(varchar(6),MIN(duration_int)),2,2) + ':' + substring(convert(varchar(6),MIN(duration_int)),4,2))
                        when 4 then (select '00:' + substring(convert(varchar(6),MIN(duration_int)),1,2) + ':' + substring(convert(varchar(6),MIN(duration_int)),3,2))
                        when 3 then (select '00:0' + substring(convert(varchar(6),MIN(duration_int)),1,1) + ':' + substring(convert(varchar(6),MIN(duration_int)),2,2))
                        when 2 then (select '00:00:' + substring(convert(varchar(6),MIN(duration_int)),1,2))
                        when 1 then (select '00:00:0' + substring(convert(varchar(6),MIN(duration_int)),1,1))
                        end AS 'LowDuration',
 case datalength(convert(varchar(6),MAX(duration_int)))
                        when 6 then (select substring(convert(varchar(6),MAX(duration_int)),1,2) + ':' + substring(convert(varchar(6),MAX(duration_int)),3,2) + ':' + substring(convert(varchar(6),MAX(duration_int)),5,2))
                        when 5 then (select '0' + substring(convert(varchar(6),MAX(duration_int)),1,1) + ':' + substring(convert(varchar(6),MAX(duration_int)),2,2) + ':' + substring(convert(varchar(6),MAX(duration_int)),4,2))
                        when 4 then (select '00:' + substring(convert(varchar(6),MAX(duration_int)),1,2) + ':' + substring(convert(varchar(6),MAX(duration_int)),3,2))
                        when 3 then (select '00:0' + substring(convert(varchar(6),MAX(duration_int)),1,1) + ':' + substring(convert(varchar(6),MAX(duration_int)),2,2))
                        when 2 then (select '00:00:' + substring(convert(varchar(6),MAX(duration_int)),1,2))
                        when 1 then (select '00:00:0' + substring(convert(varchar(6),MAX(duration_int)),1,1))
                        end AS 'HighDuration'
FROM	JobAnalysis
where jobname in (select [name] from msdb.dbo.sysjobs (nolock) where enabled = 1)
GROUP BY jobname, server
ORDER BY jobname


GO

EXEC #CreateDummyStoredProcedureIfNotExists 'dbo', 'JobReporting'
GO


ALTER PROCEDURE [dbo].[JobReporting] AS

SET NOCOUNT ON
set transaction isolation level read uncommitted;

PRINT 'Average, Min and Max Run-Duration for Jobs on Server: ' + @@SERVERNAME + ' 
  '
SELECT 	server,
	SUBSTRING(jobname,1,50),
	AvgDuration = AVG(duration_int),
	LowDuration = MIN(duration_int),
	HighDuration = MAX(duration_int)
FROM	JobAnalysis
GROUP BY server, jobname, runstatus

PRINT ' '
PRINT 'Failures for Jobs on Server: ' + @@SERVERNAME + ' 
  '
SELECT  Server = server	,
	Job	= jobname,
	Status  = runstatus,
	RunTime     = runtime,
	DayOfWeek = dayofweek,
	DayOfMonth  = DAY(rundatetime)
FROM	JobAnalysis
WHERE	runstatus <> 'Succeeded'
AND rundatetime > GETDATE()-7
GROUP BY server, jobname, runstatus, runtime, dayofweek, DAY(rundatetime)
IF @@ROWCOUNT = 0 
	BEGIN 
		PRINT 'NO FAILURES IN THE LAST 7 DAYS - YAY!'
	END

PRINT ' '
PRINT 'Jobs Taking Longer Than Usual for Jobs on Server: ' + @@SERVERNAME + ' 
  '
SELECT  o.server,
	o.jobname,
	avg_duration = LEFT(RIGHT('000000'+CONVERT(VARCHAR(6),avg_duration), 6),2)+':'+
			  SUBSTRING(RIGHT('000000'+CONVERT(VARCHAR(6),avg_duration), 6), 3, 2)+':'+
			  RIGHT(RIGHT('000000'+CONVERT(VARCHAR(6),avg_duration), 6),2),
	this_duration = duration_txt,
	rundatetime,
	dayofweek
FROM 	JobAnalysis o
JOIN	(SELECT	server,
		jobname, 
		AVG(duration_int) AS avg_duration
	FROM 	JobAnalysis
	WHERE	duration_int > 0
	GROUP BY server, jobname) AS avgs
ON 	o.server = avgs.server 
AND 	o.jobname = avgs.jobname 
WHERE 	duration_int > ( avg_duration*2)
AND rundatetime > GETDATE()-7
ORDER BY rundatetime
IF @@ROWCOUNT = 0 
	BEGIN 
		PRINT 'ALL JOBS RUNNING AS USUAL!'
	END

GO

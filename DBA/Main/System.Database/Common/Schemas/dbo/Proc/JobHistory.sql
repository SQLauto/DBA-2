EXEC #CreateDummyStoredProcedureIfNotExists 'dbo', 'JobHistory'
GO

ALTER PROCEDURE [dbo].[JobHistory] @jobid uniqueidentifier

AS

/*
--exec [JobHistory] @jobid='BC49D48F-53FD-4177-AA13-C10C1A437D3B'
        Author:  Ben Anderson
        Date:    18/02/04
        Function:  Returns SQL Agent job history for any given jobid.

*/

SET NOCOUNT ON
set transaction isolation level read uncommitted;

IF EXISTS (select TOP 100 step_id, step_name, run_status, run_date, run_time, run_duration, message  
		from msdb.dbo.sysjobhistory (nolock)
			where job_id = @jobid)
	BEGIN
		DECLARE @JobOverview TABLE (
			[ID] int identity(1,1),
			instance_id int
		)
		
		INSERT INTO @JobOverview (instance_id)
		select instance_id
		from msdb.dbo.sysjobhistory sh1
		WHERE sh1.job_id = @jobid
		AND sh1.step_id = 0
		ORDER BY instance_id


-------------
CREATE TABLE #Tempscheduleinfo
(	job_id varchar(100),
	server varchar(100),
	jobname varchar(100),
	schedulename varchar(100),
	enabled varchar(100),
	frequency varchar(100),
	interval varchar(100),
	time varchar(100),
	nextrun varchar(100)
)

insert into #Tempscheduleinfo
select
SJ.job_id,'Server'       = left(@@ServerName,20),
'JobName'      = left(S.name,30),
'ScheduleName' = left(ss.name,25),
'Enabled'      = CASE (S.enabled)
                  WHEN 0 THEN 'No'
                  WHEN 1 THEN 'Yes'
                  ELSE '??'
                END,
'Frequency'    = CASE(ss.freq_type)
                  WHEN 1  THEN 'Once'
                  WHEN 4  THEN 'Daily'
                  WHEN 8  THEN 
                    (case when (ss.freq_recurrence_factor > 1) 
                        then  'Every ' + convert(varchar(3),ss.freq_recurrence_factor) + ' Weeks'  else 'Weekly'  end)
                  WHEN 16 THEN 
                    (case when (ss.freq_recurrence_factor > 1) 
                    then  'Every ' + convert(varchar(3),ss.freq_recurrence_factor) + ' Months' else 'Monthly' end)
                  WHEN 32 THEN 'Every ' + convert(varchar(3),ss.freq_recurrence_factor) + ' Months' -- RELATIVE
                  WHEN 64 THEN 'SQL Startup'
                  WHEN 128 THEN 'SQL Idle'
                  ELSE '??'
                END,
'Interval'    = CASE
                 WHEN (freq_type = 1)                       then 'One time only'
                 WHEN (freq_type = 4 and freq_interval = 1) then 'Every Day'
                 WHEN (freq_type = 4 and freq_interval > 1) then 'Every ' + convert(varchar(10),freq_interval) + ' Days'
                 WHEN (freq_type = 8) then (select 'Weekly Schedule' = D1+ D2+D3+D4+D5+D6+D7 
                       from (select ss.schedule_id,
                     freq_interval, 
                     'D1' = CASE WHEN (freq_interval & 1  <> 0) then 'Sun ' ELSE '' END,
                     'D2' = CASE WHEN (freq_interval & 2  <> 0) then 'Mon '  ELSE '' END,
                     'D3' = CASE WHEN (freq_interval & 4  <> 0) then 'Tue '  ELSE '' END,
                     'D4' = CASE WHEN (freq_interval & 8  <> 0) then 'Wed '  ELSE '' END,
                    'D5' = CASE WHEN (freq_interval & 16 <> 0) then 'Thu '  ELSE '' END,
                     'D6' = CASE WHEN (freq_interval & 32 <> 0) then 'Fri '  ELSE '' END,
                     'D7' = CASE WHEN (freq_interval & 64 <> 0) then 'Sat '  ELSE '' END
                                 from msdb..sysschedules ss (nolock)
                                where freq_type = 8
                           ) as F
                       where schedule_id = sj.schedule_id
                                            )
                 WHEN (freq_type = 16) then 'Day ' + convert(varchar(2),freq_interval) 
                 WHEN (freq_type = 32) then (select freq_rel + WDAY 
                    from (select ss.schedule_id,
                                 'freq_rel' = CASE(freq_relative_interval)
                                                WHEN 1 then 'First'
                                                WHEN 2 then 'Second'
                                                WHEN 4 then 'Third'
                                                WHEN 8 then 'Fourth'
                                                WHEN 16 then 'Last'
                                                ELSE '??'
                                              END,
                                'WDAY'     = CASE (freq_interval)
                                                WHEN 1 then ' Sun'
                                                WHEN 2 then ' Mon'
                                                WHEN 3 then ' Tue'
                                                WHEN 4 then ' Wed'
                                                WHEN 5 then ' Thu'
                                                WHEN 6 then ' Fri'
                                                WHEN 7 then ' Sat'
                                                WHEN 8 then ' Day'
                                                WHEN 9 then ' Weekday'
                                                WHEN 10 then ' Weekend'
                                                ELSE '??'
                                              END
                            from msdb..sysschedules ss (nolock)
                            where ss.freq_type = 32
                         ) as WS 
                   where WS.schedule_id =ss.schedule_id
                   ) 
               END,
'Time' = CASE (freq_subday_type)
                WHEN 1 then   left(stuff((stuff((replicate('0', 6 - len(Active_Start_Time)))+ convert(varchar(6),Active_Start_Time),3,0,':')),6,0,':'),8)
                WHEN 2 then 'Every ' + convert(varchar(10),freq_subday_interval) + ' seconds'
                WHEN 4 then 'Every ' + convert(varchar(10),freq_subday_interval) + ' minutes'
                WHEN 8 then 'Every ' + convert(varchar(10),freq_subday_interval) + ' hours'
                ELSE '??'
              END,

'Next Run Time' = CASE SJ.next_run_date
                   WHEN 0 THEN cast('n/a' as char(10))
                   ELSE convert(char(10), convert(datetime, convert(char(8),SJ.next_run_date)),120)  + ' ' + left(stuff((stuff((replicate('0', 6 - len(next_run_time)))+ convert(varchar(6),next_run_time),3,0,':')),6,0,':'),8)
                 END
  
   from msdb.dbo.sysjobschedules SJ (nolock)
   join msdb.dbo.sysjobs         S (nolock) on S.job_id       = SJ.job_id
   join msdb.dbo.sysschedules    SS (nolock) on ss.schedule_id = sj.schedule_id
where  sj.job_id = @jobid
order by S.name





------------





		select TOP 100 (
				SELECT TOP 1 [ID]
				FROM @JobOverview
				WHERE instance_id >= sh.instance_id
				ORDER BY [ID]
			) As [Group], step_id, step_name, run_status, convert(varchar(10),convert(datetime,convert(varchar(8),run_date)),103) AS 'run_date',
			case datalength(convert(varchar(6),run_time))
			when 6 then (select substring(convert(varchar(6),run_time),1,2) + ':' + substring(convert(varchar(6),run_time),3,2) + ':' + substring(convert(varchar(6),run_time),5,2))
			when 5 then (select '0' + substring(convert(varchar(6),run_time),1,1) + ':' + substring(convert(varchar(6),run_time),2,2) + ':' + substring(convert(varchar(6),run_time),4,2))
			when 4 then (select '00:' + substring(convert(varchar(6),run_time),1,2) + ':' + substring(convert(varchar(6),run_time),3,2))
			when 3 then (select '00:0' + substring(convert(varchar(6),run_time),1,1) + ':' + substring(convert(varchar(6),run_time),2,2))
			when 2 then (select '00:00:' + substring(convert(varchar(6),run_time),1,2))
			when 1 then (select '00:00:0' + substring(convert(varchar(6),run_time),1,1))
			end AS 'run_time', 
			case datalength(convert(varchar(6),run_duration))
			when 6 then (select substring(convert(varchar(6),run_duration),1,2) + ':' + substring(convert(varchar(6),run_duration),3,2) + ':' + substring(convert(varchar(6),run_duration),5,2))
			when 5 then (select '0' + substring(convert(varchar(6),run_duration),1,1) + ':' + substring(convert(varchar(6),run_duration),2,2) + ':' + substring(convert(varchar(6),run_duration),4,2))
			when 4 then (select '00:' + substring(convert(varchar(6),run_duration),1,2) + ':' + substring(convert(varchar(6),run_duration),3,2))
			when 3 then (select '00:0' + substring(convert(varchar(6),run_duration),1,1) + ':' + substring(convert(varchar(6),run_duration),2,2))
			when 2 then (select '00:00:' + substring(convert(varchar(6),run_duration),1,2))
			when 1 then (select '00:00:0' + substring(convert(varchar(6),run_duration),1,1))
			end AS 'run_duration'
			, message,SI.frequency,SI.interval,Si.time,SI.nextrun
		from msdb.dbo.sysjobhistory  sh (nolock)
JOIN #Tempscheduleinfo SI
ON SI.job_id=sh.job_id
where sh.job_id = @jobid
		order by [Group] DESC, step_id
--		order by convert(datetime,convert(varchar(8),run_date)) DESC, run_time DESC, SortOrder, step_id DESC
	END
ELSE
	BEGIN
		select '' as [Group],'' as step_id,'' as step_name,'' as run_status,'' as run_date,'' as run_time,
				'' as run_duration,'' as message,'' as frequency,'' as interval,'' as [time], '' as nextrun
	END

GO

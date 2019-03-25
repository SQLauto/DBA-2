EXEC #CreateDummyStoredProcedureIfNotExists 'capture', 'CpuUsage'
GO

ALTER PROCEDURE [capture].[CpuUsage]
as
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks)FROM sys.dm_os_sys_info); 

DECLARE @ServerName varchar(300),@NodeName varchar(300)
SELECT @ServerName = convert(nvarchar(128), serverproperty('servername'))
SELECT @NodeName = convert(nvarchar(128), serverproperty('ComputerNamePhysicalNetBIOS'))

IF OBJECT_ID('Tempdb..#Cpuutilisation') IS NOT NULL
DROP TABLE #CpuUtilisation
	
CREATE TABLE #CpuUtilisation
(
	SQLServer smallint,
	SystemIdle smallint,
	Other smallint,
	CaptureDateTime datetime,
	NodeName varchar(256)

)
INSERT INTO #CpuUtilisation(SQLServer,SystemIdle,Other,CaptureDateTime,NodeName)
SELECT  SQLProcessUtilization AS [SQLServer], 
               SystemIdle AS [SystemIdle], 
               100 - SystemIdle - SQLProcessUtilization AS [Other], 
               dateadd(mi, datediff(mi, 0, DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE())), 0) AS [CaptureDateTime],@NodeName nodename
FROM ( 
	  SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, 
			record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
			AS [SystemIdle], 
			record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 
			'int') 
			AS [SQLProcessUtilization], [timestamp] 
	  FROM ( 
			SELECT [timestamp], CONVERT(xml, record) AS [record] 
			FROM sys.dm_os_ring_buffers WITH (NOLOCK)
			WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
			AND record LIKE N'%<SystemHealth>%') AS x 
	  ) AS y 
ORDER BY record_id DESC OPTION (RECOMPILE);

Update #CpuUtilisation
SET Other=0 
Where Other <0


INSERT INTO capture.cpuutilisation ([SQLServer], [SystemIdle], [Other], [CaptureDateTime], [node])
Select  TCU.SQLServer, TCU.SystemIdle, TCU.Other, TCU.CaptureDateTime, TCU.nodeName from #CpuUtilisation TCU
LEFT JOIN capture.cpuutilisation CU ON TCU.CaptureDateTime=CU.CaptureDateTime
WHERE CU.id is null




GO



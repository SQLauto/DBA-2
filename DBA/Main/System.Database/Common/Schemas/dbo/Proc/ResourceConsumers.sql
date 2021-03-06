
EXEC #CreateDummyStoredProcedureIfNotExists 'dbo', 'ResourceConsumers'
GO

ALTER  PROCEDURE [dbo].[ResourceConsumers] AS

/* Simon DM - 04/11/04 - returns the processes using SQL CPU */
set transaction isolation level read uncommitted;

SET NOCOUNT ON
DECLARE @TotalCpu decimal(8)
DECLARE @TotalIO decimal(8)

CREATE TABLE #who1(
	SPID int,
	CPUTime int,
	DiskIO int,
	login varchar(50),
	HostName varchar(50),
	ProgramName varchar(200),
	LastBatch datetime,
	BlkBy int)

DECLARE @FirstTime datetime
SET @FirstTime = getdate()
INSERT INTO #who1 SELECT SPID, sum(cpu), sum(physical_io), loginame, hostname, program_name, last_batch, blocked from master.dbo.sysprocesses (nolock)
	group  by spid, loginame, hostname, program_name, last_batch, blocked

WAITFOR DELAY '00:00:01'

CREATE TABLE #who2(
	SPID int,
	CPUTime int,
	DiskIO int)

INSERT INTO #who2 SELECT SPID, sum(cpu), sum(physical_io) from master.dbo.sysprocesses (nolock) where login_time < @FirstTime
	and spid in (select spid from #who1)
	 group by spid


Select @TotalCpu = sum(B.CPUTime-A.CPUTime), @TotalIO = sum(B.DiskIO-A.DiskIO)
	from #Who1 A JOIN #Who2 B on a.SPID = b.SPID
where B.CPUTime >= A.CPUTime or B.DiskIO >= A.DiskIO

Select A.SPID, rtrim(A.Login) as login, rtrim(A.HostName) as HostName, 
	Case when left(A.ProgramName, 15) = 'SQLAgent - TSQL' THEN dbo.GetJobName(A.ProgramName) ELSE A.ProgramName END as ProgramName,
	A.LastBatch, A.BlkBy,
	(Case when sum(B.CPUTime - A.CPUTime)=0 THEN 0 ELSE sum(B.CPUTime - A.CPUTime)/@TotalCPU END)*100 as [% CPU],
	(Case when sum(B.DiskIO - A.DiskIO)=0 THEN 0 ELSE sum(B.DiskIO - A.DiskIO)/@TotalIO END)*100 as [% Disk]
	from #Who1 A JOIN #Who2 B on a.SPID = b.SPID
	where B.CPUTime >= A.CPUTime or B.DiskIO >= A.DiskIO
	group by A.SPID, A.Login, A.HostName, A.ProgramName, A.LastBatch, A.BlkBy
	order by (Case when sum(B.CPUTime - A.CPUTime)=0 THEN 0 ELSE sum(B.CPUTime - A.CPUTime)/@TotalCPU END) +
			(Case when sum(B.DiskIO - A.DiskIO)=0 THEN 0 ELSE sum(B.DiskIO - A.DiskIO)/@TotalIO END) DESC


DROP TABLE #Who1
DROP TABLE #Who2

GO

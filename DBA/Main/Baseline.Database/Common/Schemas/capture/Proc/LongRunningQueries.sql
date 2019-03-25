EXEC #CreateDummyStoredProcedureIfNotExists 'capture', 'LongRunningQueries'
GO

ALTER PROCEDURE [capture].[LongRunningQueries]
 @reportdate DATETIME 

 as
 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @SQL varchar(max)=''
DECLARE  @tablename varchar(500) = 'WhoIsActive_' + CONVERT(VARCHAR, @reportdate, 112) ;
--exec [capture].[LongRunningQueries] '25 aug 2015'
SET @SQL='

Select * from (
SELECT 
[start_time], 
--DATEPART(hour,start_time) start_hour,DATEPART(minute,start_time) start_minute,
datediff(MI,start_time,collection_time)TimeinMinutes,
  [host_name],
      REPLACE(REPLACE(REPLACE(REPLACE(CAST(sql_command as varchar(max)),''<?query --'',''''),''--?>'',''''),CHAR(10),''''),CHAR(13),'''') parent_sql_command
	  ,[login_name]
      ,cast( REPLACE(REPLACE(replace(replace(cpu,'' '',''''),'','',''''),CHAR(10),''''),CHAR(13),'''') as int) cpu
      ,REPLACE(REPLACE(REPLACE([tempdb_allocations],CHAR(10),''''),CHAR(13),''''),'' '','''') tempdb_allocations
      ,REPLACE(REPLACE(REPLACE([reads],CHAR(10),''''),CHAR(13),''''),'' '','''') [reads]
      ,REPLACE(REPLACE(REPLACE([writes],CHAR(10),''''),CHAR(13),''''),'' '','''') [writes]
      ,REPLACE(REPLACE(REPLACE([physical_reads],CHAR(10),''''),CHAR(13),''''),'' '','''') [physical_reads]
      ,REPLACE(REPLACE(REPLACE([used_memory],CHAR(10),''''),CHAR(13),''''),'' '','''') [used_memory]
      ,REPLACE(REPLACE(REPLACE([database_name],CHAR(10),''''),CHAR(13),''''),'' '','''') [database_name]
      ,REPLACE(REPLACE(REPLACE([program_name],CHAR(10),''''),CHAR(13),''''),'' '','''') [program_name]
	  ,''select * from [BaselineData].[capture].['+@tablename+'] where id=''+CAST(ID AS VARCHAR(7)) MoreDetail
      ,RANK() OVER(PARTITION BY login_name,session_id,DATEPART(hour,start_time),DATEPART(minute,start_time)order by collection_time desc) as rnk
FROM [BaselineData].[capture].['+@tablename+'](nolock)
 where datediff(mi,start_time,collection_time)>5 
 and cpu is not null
 and database_name not in (''Baselinedata'',''master'',''system'',''msdb'')
 and cast(sql_text as varchar(max)) not like ''%BACKUP DATABASE%''
 --and program_name = ''Microsoft SQL Server Management Studio - Query''
 and cast(sql_text as varchar(max)) not like ''%BaselineData%''
 and cast(sql_command as varchar(max)) not like ''%CollectProcedurePerformance%''

 
  ) SQ
  where rnk=1
  and cpu>0
  order by TimeinMinutes desc'
  PRINT(@SQL)
  EXEC (@SQL)
 

GO


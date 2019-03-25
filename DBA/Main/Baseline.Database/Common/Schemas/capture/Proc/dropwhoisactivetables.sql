EXEC #CreateDummyStoredProcedureIfNotExists 'capture', 'dropwhoisactivetables'
GO


ALTER procedure [capture].[dropwhoisactivetables]
as
BEGIN 
Declare @sql varchar(max)=''

IF OBJECT_ID('Tempdb..#TablesToDrop') IS NOT NULL
DROP TABLE #TablesToDrop

CREATE TABLE #TablesToDrop
(
TableName varchar(100)
)

INSERT INTO #tablestodrop(Tablename)
select name  from sysobjects
where name like '%whoisactive[_]%'

select @sql=@sql+'DROP TABLE '+Tablename+Char(10) from #tablestodrop
where CONVERT(datetime,RIGHT(Tablename,8),121)<getdate()-8

EXEC(@SQL)

END


GO




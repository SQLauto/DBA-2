EXEC #CreateDummyStoredProcedureIfNotExists 'dbo', 'CreateRestoreScript'
GO

--exec [dbo].[CreateRestoreScript] 'PARERestore','PareDevint','FaePreProd'
ALTER PROC [dbo].[CreateRestoreScript] @databasename varchar(100),@sourceinstance varchar(50),@destinationinstance varchar(50)
AS
BEGIN TRY
set transaction isolation level read uncommitted;

DECLARE @start smallint,@end smallint,@backupfile varchar(200),@ErrMsg varchar(4000)

if OBJECT_ID('tempdb..#RESTORE') is not null
DROP TABLE #RESTORE

CREATE TABLE #RESTORE
(
       TSQLstring varchar(max),BacKupDate DATETIME,BackupDevice Varchar(2000),Last_LSN varchar(100)
)

INSERT INTO #RESTORE(TSQLstring,BacKupDate,BackupDevice,Last_LSN)
EXEC [dbo].[sp_LogShippingLight]
    @Database ='PARE'  ,  
    @StandbyMode  = 0,
    @IncludeSystemDBs = 0,
    @WithRecovery = 1,
    @WithCHECKDB  = 0




DECLARE @restore varchar(max)=''
select @restore=@restore+replace(TSQLstring, 'NORECOVERY', 'RECOVERY')  from #RESTORE
WHERE TSQLstring not like '%''RESTORE_LOG''%'

select @start=2+patindex('%.bak%',TSQLstring)-patindex('%\%',REVERSE(substring(TSQLstring,1,patindex('%.bak%',TSQLstring)))),@end=patindex('%.bak%',TSQLstring)+4-@start from #RESTORE
where TSQLstring like '%bak%'

select @backupfile=substring(TSQLstring,@start,@end) 
from #RESTORE
where TSQLstring like '%bak%'

Insert into [System].perf.RestoreScripts(Databasename,Inserted,BackupFile,restorescript,source,destination)
Values(@databasename,getdate(),@backupfile,@restore,@sourceinstance,@destinationinstance)

Insert into [System].perf.RestoreUpgradeLog(Process,Success,Comments,EntryDate)
Values('Create Restore Script',1,'Script for '+@backupfile+' Created',getdate())

END TRY
BEGIN CATCH
SET @ErrMsg = ERROR_MESSAGE()
		   
Insert into [System].perf.RestoreUpgradeLog(Process,Success,Comments,EntryDate)
Values('Create Restore Script',0,'Failed: ' +@ErrMsg,getdate())
		   
raiserror(@ErrMsg, 18, 1)
END CATCH

/*

exec [dbo].[CreateRestoreScript] 'PARE','PareDevInt','FaePreProd'
select * from [System].perf.RestoreScripts

truncate table [System].perf.RestoreScripts

*/


GO

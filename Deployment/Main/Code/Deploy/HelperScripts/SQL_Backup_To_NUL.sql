DECLARE @db nvarchar(1024) = DB_NAME()
DECLARE @last_log_backup_lsn numeric(25,0)
DECLARE @recovery_model nvarchar(100)

SELECT @last_log_backup_lsn = last_log_backup_lsn
 from sys.database_recovery_status
where database_id = db_id(@db)

SELECT @recovery_model = recovery_model_desc
FROM sys.databases
WHERE name=@db

IF @recovery_model = 'FULL'
BEGIN
	IF @last_log_backup_lsn IS NULL
	BEGIN
		PRINT 'Doing full backup'
		backup database @db to disk = 'NUL'
	END

	PRINT 'Doing log backup'
	backup log @db to disk = 'nul'
END
ELSE
	PRINT @db + ' is not in Full Recovery'

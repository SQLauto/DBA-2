EXEC #CreateDummyStoredProcedureIfNotExists 'dbo', 'sp_LogShippingLight'
GO

 
 
/*********************************************************************************************
Log Shipping Light v2.00 (2013-10-15)
(C) 2012, Paul Brewer
 
Feedback: <a href="mailto:paulbrewer@yahoo.co.uk">mailto:paulbrewer@yahoo.co.uk</a>
Updates: <a href="http://paulbrewer.wordpress.com/2013/10/12/database-restore-automation/">http://paulbrewer.wordpress.com/2013/10/12/database-restore-automation/</a>
 
This procedure has a companion PowerShell driver script called ps_LogShippingLight
It is designed to gather backup information and return restore commands which are then executed on a standby server by the PoSh script.
 
Usage examples:
 
sp_LogShippingLight
No parameters = Generates RESTORE commands for all USER databases, from actual backup files to existing file locations to most current time, consistency checks, CHECKSUM where possible
 
sp_LogShippingLight @Database = 'db_workspace', @StopAt = '2012-12-23 12:01:00.000', @StandbyMode = 1
Generates RESTORE commands for a specific database from the most recent full backup + most recent differential + transaction log backups before to STOPAT.
Databases left in STANDBY
Ignores COPY_ONLY backups, restores to default file locations from default backup file.
 
sp_LogShippingLight @Database = 'db_workspace', @StopAt = '2012-12-23 12:31:00.000', @WithMoveDataFiles = 'c:\temp\', @WithMoveLogFile  = 'c:\temp\' , @FromFileFullUNC = 'c:\backup\'
Overrides data file folder, log file folder and backup file folder.
Generates RESTORE commands for a specific database from most recent full backup, most recent differential + transaction log backups before STOPAT.
Ignores COPY_ONLY backups, includes WITH MOVE to simulate a restore to a test environment with different folder mapping.
 
CHANGE LOG:
December 23, 2012   - V1.01 - Release
January 4,2013      - V1.02 - LSN Checks + Bug fix to STOPAT date format
January 11,2013     - V1.03 - SQL Server 2005 compatibility (backup compression problem) & @StandbyMode for stepping through log restores with a readable database
January 14, 2013    - V1.04 - Cope with up to 10 striped backup files
January 15, 2013    - V1.05 - Format of constructed restore script, enclose database name in [ ]
February 7, 2013    - V1.06 - Andrew Guerin feedback, modified WHERE Device_Type IN (102,2)
May 26, 2013        - V1.07 - Various changes for PoSh Driver Script compatibility
October 14, 2013    - V1.08 - Rename parameters, more meaningful names
October 15, 2013    - V2.00 - Add 2nd CTE for striped backup files and remove repeating calls to CTE
*********************************************************************************************/
 
ALTER PROCEDURE [dbo].[sp_LogShippingLight]
(
    @Database SYSNAME = NULL,
    @WithMoveDataFiles VARCHAR(2000) = NULL,
    @WithMoveLogFile  VARCHAR(2000) = NULL,
    @FromFileFullUNC VARCHAR(2000) = NULL,
    @FromFileDiffUNC VARCHAR(2000) = NULL,
    @FromFileLogUNC VARCHAR(2000) = NULL,
    @StopAt DATETIME = NULL,
    @StandbyMode BIT = 0,
    @IncludeSystemDBs BIT = 0,
    @WithRecovery BIT = 0,
    @WithCHECKDB BIT = 0
)
AS
BEGIN
 
SET NOCOUNT ON;
 
IF ISNULL(@StopAt,'') = ''
SET @StopAt = GETDATE();
 
--------------------------------------------------------------
-- CTE1 Full backup UNION Differential Backup UNION Log Backup
--------------------------------------------------------------
WITH CTE
(
    database_name
    ,current_compatibility_level
    ,Last_LSN
    ,current_is_read_only
    ,current_state_desc
    ,current_recovery_model_desc
    ,has_backup_checksums
    ,backup_size
    ,[type]
    ,backupmediasetid
    ,family_sequence_number
    ,backupfinishdate
    ,physical_device_name
    ,position
)
AS
(
--------------------------------------------------------------
-- CTE1 Full backup (most current or immediately before @StopAt if supplied)
--------------------------------------------------------------
 
SELECT
    bs.database_name
    ,d.[compatibility_level] AS current_compatibility_level
    ,bs.last_lsn
    ,d.[is_read_only] AS current_is_read_only
    ,d.[state_desc] AS current_state_desc
    ,d.[recovery_model_desc] current_recovery_model_desc
    ,bs.has_backup_checksums
    ,bs.backup_size AS backup_size
    ,'D' AS [type]
    ,bs.media_set_id AS backupmediasetid
    ,mf.family_sequence_number
    ,x.backup_finish_date AS backupfinishdate
    ,mf.physical_device_name
    ,bs.position
FROM msdb.dbo.backupset bs
 
INNER JOIN sys.databases d
ON bs.database_name = d.name
 
INNER JOIN
(
SELECT
    database_name
    ,MAX(backup_finish_date) backup_finish_date
FROM msdb.dbo.backupset a
JOIN msdb.dbo.backupmediafamily b
ON a.media_set_id = b.media_set_id
WHERE a.[type] = 'D'
--  AND b.[Device_Type] = 2
AND Device_Type IN (102,2)
AND a.is_copy_only = 0
AND a.backup_finish_date <= ISNULL(@StopAt,a.backup_finish_date)
GROUP BY database_name
) x
ON x.database_name = bs.database_name
AND x.backup_finish_date = bs.backup_finish_date
 
JOIN msdb.dbo.backupmediafamily mf
ON mf.media_set_id = bs.media_set_id
AND mf.family_sequence_number Between bs.first_family_number And bs.last_family_number
 
WHERE bs.type = 'D'
AND mf.physical_device_name NOT IN ('Nul', 'Nul:')
 
--------------------------------------------------------------
-- CTE1 Differential backup, most current immediately before @StopAt
--------------------------------------------------------------
UNION
 
SELECT
    bs.database_name
    ,d.[compatibility_level] AS current_compatibility_level
    ,bs.last_lsn
    ,d.[is_read_only] AS current_is_read_only
    ,d.[state_desc] AS current_state_desc
    ,d.[recovery_model_desc] current_recovery_model_desc
    ,bs.has_backup_checksums
    ,bs.backup_size AS backup_size
    ,'I' AS [type]
    ,bs.media_set_id AS backupmediasetid
    ,mf.family_sequence_number
    ,x.backup_finish_date AS backupfinishdate
    ,mf.physical_device_name
    ,bs.position
FROM msdb.dbo.backupset bs
 
INNER JOIN sys.databases d
ON bs.database_name = d.name
 
INNER JOIN
(
SELECT
    database_name
    ,MAX(backup_finish_date) backup_finish_date
FROM msdb.dbo.backupset a
JOIN msdb.dbo.backupmediafamily b
ON a.media_set_id = b.media_set_id
WHERE a.[type] = 'I'
--  AND b.[Device_Type] = 2
AND Device_Type IN (102,2)
AND a.is_copy_only = 0
AND a.backup_finish_date <= ISNULL(@StopAt,GETDATE())
GROUP BY database_name
) x
ON x.database_name = bs.database_name
AND x.backup_finish_date = bs.backup_finish_date
 
JOIN msdb.dbo.backupmediafamily mf
ON mf.media_set_id = bs.media_set_id
AND mf.family_sequence_number Between bs.first_family_number And bs.last_family_number
 
WHERE bs.type = 'I'
AND mf.physical_device_name NOT IN ('Nul', 'Nul:')
AND bs.backup_finish_date <= ISNULL(@StopAt,GETDATE())
 
--------------------------------------------------------------
-- CTE1 Log file backups after 1st full backup before @STOPAT
--------------------------------------------------------------
UNION
 
SELECT
    bs.database_name
    ,d.[compatibility_level] AS current_compatibility_level
    ,bs.last_lsn
    ,d.[is_read_only] AS current_is_read_only
    ,d.[state_desc] AS current_state_desc
    ,d.[recovery_model_desc] current_recovery_model_desc
    ,bs.has_backup_checksums
    ,bs.backup_size AS backup_size
    ,'L' AS [type]
    ,bs.media_set_id AS backupmediasetid
    ,mf.family_sequence_number
    ,bs.backup_finish_date as backupfinishdate
    ,mf.physical_device_name
    ,bs.position
 
FROM msdb.dbo.backupset bs
 
INNER JOIN sys.databases d
ON bs.database_name = d.name
 
JOIN msdb.dbo.backupmediafamily mf
ON mf.media_set_id = bs.media_set_id
AND mf.family_sequence_number Between bs.first_family_number And bs.last_family_number
 
LEFT OUTER JOIN
(
    SELECT
    database_name
    ,MAX(backup_finish_date) backup_finish_date
    FROM msdb.dbo.backupset a
    JOIN msdb.dbo.backupmediafamily b
    ON a.media_set_id = b.media_set_id
    WHERE a.[type] = 'D'
    --  AND b.[Device_Type] = 2
    AND Device_Type IN (102,2)
    AND a.is_copy_only = 0
    AND a.backup_finish_date <= ISNULL(@StopAt,a.backup_finish_date)
    GROUP BY database_name
) y
ON bs.database_name = y.Database_name
 
LEFT OUTER JOIN
(
SELECT
    database_name
    ,MIN(backup_finish_date) backup_finish_date
FROM msdb.dbo.backupset a
JOIN msdb.dbo.backupmediafamily b
ON a.media_set_id = b.media_set_id
WHERE a.[type] = 'D'
--  AND b.[Device_Type] = 2
AND Device_Type IN (102,2)
 
AND a.is_copy_only = 0
AND a.backup_finish_date > ISNULL(@StopAt,'1 Jan, 1900')
GROUP BY database_name
) z
ON bs.database_name = z.database_name
 
WHERE bs.backup_finish_date > y.backup_finish_date
AND bs.backup_finish_date < ISNULL(z.backup_finish_date,GETDATE())
AND mf.physical_device_name NOT IN ('Nul', 'Nul:')
AND bs.type = 'L'
--  AND b.[Device_Type] = 2
AND Device_Type IN (102,2)
),
 
--------------------------------------------------------------
-- CTE2 Optionally, striped backup file details
--------------------------------------------------------------
 
Stripes
(
    database_name,
    backupmediasetid,
    family_sequence_number,
    last_lsn,
    S2_pdn,
    S3_pdn,
    S4_pdn,
    S5_pdn,
    S6_pdn,
    S7_pdn,
    S8_pdn,
    S9_pdn,
    S10_pdn
)
AS
(
SELECT
    Stripe1.database_name,
    Stripe1.backupmediasetid,
    Stripe1.family_sequence_number,
    Stripe1.Last_LSN,
    Stripe2.physical_device_name AS S2_pdn,
    Stripe3.physical_device_name AS S3_pdn,
    Stripe4.physical_device_name AS S4_pdn,
    Stripe5.physical_device_name AS S5_pdn,
    Stripe6.physical_device_name AS S6_pdn,
    Stripe7.physical_device_name AS S7_pdn,
    Stripe8.physical_device_name AS S8_pdn,
    Stripe9.physical_device_name AS S9_pdn,
    Stripe10.physical_device_name  AS S10_pdn
        
FROM CTE AS Stripe1
LEFT OUTER JOIN CTE AS Stripe2
ON Stripe2.database_name = Stripe1.Database_name
AND Stripe2.backupmediasetid = Stripe1.backupmediasetid
AND Stripe2.family_sequence_number = 2
 
LEFT OUTER JOIN CTE AS Stripe3
ON Stripe3.database_name = Stripe1.Database_name
AND Stripe3.backupmediasetid = Stripe1.backupmediasetid
AND Stripe3.family_sequence_number = 3
 
LEFT OUTER JOIN CTE AS Stripe4
ON Stripe4.database_name = Stripe1.Database_name
AND Stripe4.backupmediasetid = Stripe1.backupmediasetid
AND Stripe4.family_sequence_number = 4
 
LEFT OUTER JOIN CTE AS Stripe5
ON Stripe5.database_name = Stripe1.Database_name
AND Stripe5.backupmediasetid = Stripe1.backupmediasetid
AND Stripe5.family_sequence_number = 5
 
LEFT OUTER JOIN CTE AS Stripe6
ON Stripe6.database_name = Stripe1.Database_name
AND Stripe6.backupmediasetid = Stripe1.backupmediasetid
AND Stripe6.family_sequence_number = 6
 
LEFT OUTER JOIN CTE AS Stripe7
ON Stripe7.database_name = Stripe1.Database_name
AND Stripe7.backupmediasetid = Stripe1.backupmediasetid
AND Stripe7.family_sequence_number = 7
 
LEFT OUTER JOIN CTE AS Stripe8
ON Stripe8.database_name = Stripe1.Database_name
AND Stripe8.backupmediasetid = Stripe1.backupmediasetid
AND Stripe8.family_sequence_number = 8
 
LEFT OUTER JOIN CTE AS Stripe9
ON Stripe9.database_name = Stripe1.Database_name
AND Stripe9.backupmediasetid = Stripe1.backupmediasetid
AND Stripe9.family_sequence_number = 9
 
LEFT OUTER JOIN CTE AS Stripe10
ON Stripe10.database_name = Stripe1.Database_name
AND Stripe10.backupmediasetid = Stripe1.backupmediasetid
AND Stripe10.family_sequence_number = 10
)
 
--------------------------------------------------------------
-- Results, T-SQL RESTORE commands, below are based on CTE's above
--------------------------------------------------------------
 
SELECT
    a.Command AS TSQL,
    CONVERT(nvarchar(30), a.backupfinishdate, 126)
    AS BackupDate,
    a.BackupDevice,
    a.Last_LSN
FROM
(
 
--------------------------------------------------------------
-- Most recent full backup
--------------------------------------------------------------
 
SELECT
    ';SELECT ''' + 'RESTORE_FULL'' AS STEP' + ';RESTORE DATABASE [' + d.[name] + ']' + SPACE(1) +
    'FROM DISK = N' + '''' +
    CASE ISNULL(@FromFileFullUNC,'Actual')
    WHEN 'Actual' THEN CTE.physical_device_name
    ELSE @FromFileFullUNC + SUBSTRING(CTE.physical_device_name,LEN(CTE.physical_device_name) - CHARINDEX('\',REVERSE(CTE.physical_device_name),1) + 2,CHARINDEX('\',REVERSE(CTE.physical_device_name),1) + 1)
    END + '''' + SPACE(1) +
     
    -- Striped backup files
    CASE ISNULL(Stripes.S2_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileFullUNC,'Actual') WHEN 'Actual' THEN Stripes.S2_pdn ELSE @FromFileFullUNC + SUBSTRING(Stripes.S2_pdn,LEN(Stripes.S2_pdn) - CHARINDEX('\',REVERSE(Stripes.S2_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S2_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S3_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileFullUNC,'Actual') WHEN 'Actual' THEN Stripes.S3_pdn ELSE @FromFileFullUNC + SUBSTRING(Stripes.S3_pdn,LEN(Stripes.S3_pdn) - CHARINDEX('\',REVERSE(Stripes.S3_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S3_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S4_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileFullUNC,'Actual') WHEN 'Actual' THEN Stripes.S4_pdn ELSE @FromFileFullUNC + SUBSTRING(Stripes.S4_pdn,LEN(Stripes.S4_pdn) - CHARINDEX('\',REVERSE(Stripes.S4_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S4_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S5_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileFullUNC,'Actual') WHEN 'Actual' THEN Stripes.S5_pdn ELSE @FromFileFullUNC + SUBSTRING(Stripes.S5_pdn,LEN(Stripes.S5_pdn) - CHARINDEX('\',REVERSE(Stripes.S5_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S5_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S6_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileFullUNC,'Actual') WHEN 'Actual' THEN Stripes.S6_pdn ELSE @FromFileFullUNC + SUBSTRING(Stripes.S6_pdn,LEN(Stripes.S6_pdn) - CHARINDEX('\',REVERSE(Stripes.S6_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S6_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S7_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileFullUNC,'Actual') WHEN 'Actual' THEN Stripes.S7_pdn ELSE @FromFileFullUNC + SUBSTRING(Stripes.S7_pdn,LEN(Stripes.S7_pdn) - CHARINDEX('\',REVERSE(Stripes.S7_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S7_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S8_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileFullUNC,'Actual') WHEN 'Actual' THEN Stripes.S8_pdn ELSE @FromFileFullUNC + SUBSTRING(Stripes.S8_pdn,LEN(Stripes.S8_pdn) - CHARINDEX('\',REVERSE(Stripes.S8_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S8_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S9_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileFullUNC,'Actual') WHEN 'Actual' THEN Stripes.S9_pdn ELSE @FromFileFullUNC + SUBSTRING(Stripes.S9_pdn,LEN(Stripes.S9_pdn) - CHARINDEX('\',REVERSE(Stripes.S9_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S9_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S10_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileFullUNC,'Actual') WHEN 'Actual' THEN Stripes.S10_pdn ELSE @FromFileFullUNC + SUBSTRING(Stripes.S10_pdn,LEN(Stripes.S10_pdn) - CHARINDEX('\',REVERSE(Stripes.S10_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S10_pdn),1) + 1) END + ''''
    END +
 
    'WITH REPLACE, FILE = ' + CAST(CTE.Position AS VARCHAR(5)) + ',' +
    CASE CTE.has_backup_checksums WHEN 1 THEN 'CHECKSUM, ' ELSE ' ' END +
     
    CASE @StandbyMode WHEN 0 THEN 'NORECOVERY,' ELSE 'STANDBY =N' + '''' + ISNULL(@FromFileFullUNC,SUBSTRING(CTE.physical_device_name,1,LEN(CTE.physical_device_name) - CHARINDEX('\',REVERSE(CTE.physical_device_name)))) + '\' + d.name + '_ROLLBACK_UNDO.bak ' + '''' + ',' END + SPACE(1) +
     
    'STATS=10,' + SPACE(1) +
    'MOVE N' + '''' + x.LogicalName + '''' + ' TO ' +
    '''' +
    CASE ISNULL(@WithMoveDataFiles,'Actual')
    WHEN 'Actual' THEN x.PhysicalName
    ELSE @WithMoveDataFiles + SUBSTRING(x.PhysicalName,LEN(x.PhysicalName) - CHARINDEX('\',REVERSE(x.PhysicalName),1) + 2,CHARINDEX('\',REVERSE(x.PhysicalName),1) + 1)
    END + '''' + ',' + SPACE(1) +
     
    'MOVE N' + '''' + y.LogicalName + '''' + ' TO ' +
    '''' +
    CASE ISNULL(@WithMoveLogFile ,'Actual')
    WHEN 'Actual' THEN y.PhysicalName
    ELSE @WithMoveLogFile  + SUBSTRING(y.PhysicalName,LEN(y.PhysicalName) - CHARINDEX('\',REVERSE(y.PhysicalName),1) + 2,CHARINDEX('\',REVERSE(y.PhysicalName),1) + 1)
    END + '''' AS Command,
    1 AS Sequence,
    d.name AS database_name,
    CTE.physical_device_name AS BackupDevice,
    CTE.backupfinishdate,
    CTE.backup_size,
    CTE.Last_LSN
 
FROM sys.databases d
JOIN
(
SELECT
    DB_NAME(mf.database_id) AS name
    ,mf.Physical_Name AS PhysicalName
    ,mf.Name AS LogicalName
FROM sys.master_files mf
WHERE type_desc = 'ROWS'
AND mf.file_id = 1
) x
ON d.name = x.name
 
JOIN
(
SELECT
    DB_NAME(mf.database_id) AS name, type_desc
    ,mf.Physical_Name PhysicalName
    ,mf.Name AS LogicalName
FROM sys.master_files mf
WHERE type_desc = 'LOG'
) y
ON d.name = y.name
 
LEFT OUTER JOIN CTE
ON CTE.database_name = d.name
AND CTE.family_sequence_number = 1
 
JOIN Stripes
ON Stripes.database_name = d.name
AND Stripes.backupmediasetid = CTE.backupmediasetid
AND Stripes.last_lsn = CTE.Last_LSN
 
WHERE CTE.[type] = 'D'
AND CTE.family_sequence_number = 1
 
--------------------------------------------------------------
-- Most recent differential backup
--------------------------------------------------------------
UNION
 
    SELECT
    ';SELECT ''' + 'RESTORE_DIFF'' AS STEP' + ';RESTORE DATABASE [' + d.[name] + ']' + SPACE(1) +
    'FROM DISK = N' + '''' +
    CASE ISNULL(@FromFileDiffUNC,'Actual')
    WHEN 'Actual' THEN CTE.physical_device_name
    ELSE @FromFileDiffUNC + SUBSTRING(CTE.physical_device_name,LEN(CTE.physical_device_name) - CHARINDEX('\',REVERSE(CTE.physical_device_name),1) + 2,CHARINDEX('\',REVERSE(CTE.physical_device_name),1) + 1)
    END + '''' + SPACE(1) +
     
    -- Striped backup files
    CASE ISNULL(Stripes.S2_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileDiffUNC,'Actual') WHEN 'Actual' THEN Stripes.S2_pdn ELSE @FromFileDiffUNC + SUBSTRING(Stripes.S2_pdn,LEN(Stripes.S2_pdn) - CHARINDEX('\',REVERSE(Stripes.S2_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S2_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S3_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileDiffUNC,'Actual') WHEN 'Actual' THEN Stripes.S3_pdn ELSE @FromFileDiffUNC + SUBSTRING(Stripes.S3_pdn,LEN(Stripes.S3_pdn) - CHARINDEX('\',REVERSE(Stripes.S3_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S3_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S4_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileDiffUNC,'Actual') WHEN 'Actual' THEN Stripes.S4_pdn ELSE @FromFileDiffUNC + SUBSTRING(Stripes.S4_pdn,LEN(Stripes.S4_pdn) - CHARINDEX('\',REVERSE(Stripes.S4_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S4_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S5_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileDiffUNC,'Actual') WHEN 'Actual' THEN Stripes.S5_pdn ELSE @FromFileDiffUNC + SUBSTRING(Stripes.S5_pdn,LEN(Stripes.S5_pdn) - CHARINDEX('\',REVERSE(Stripes.S5_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S5_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S6_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileDiffUNC,'Actual') WHEN 'Actual' THEN Stripes.S6_pdn ELSE @FromFileDiffUNC + SUBSTRING(Stripes.S6_pdn,LEN(Stripes.S6_pdn) - CHARINDEX('\',REVERSE(Stripes.S6_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S6_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S7_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileDiffUNC,'Actual') WHEN 'Actual' THEN Stripes.S7_pdn ELSE @FromFileDiffUNC + SUBSTRING(Stripes.S7_pdn,LEN(Stripes.S7_pdn) - CHARINDEX('\',REVERSE(Stripes.S7_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S7_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S8_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileDiffUNC,'Actual') WHEN 'Actual' THEN Stripes.S8_pdn ELSE @FromFileDiffUNC + SUBSTRING(Stripes.S8_pdn,LEN(Stripes.S8_pdn) - CHARINDEX('\',REVERSE(Stripes.S8_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S8_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S9_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileDiffUNC,'Actual') WHEN 'Actual' THEN Stripes.S9_pdn ELSE @FromFileDiffUNC + SUBSTRING(Stripes.S9_pdn,LEN(Stripes.S9_pdn) - CHARINDEX('\',REVERSE(Stripes.S9_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S9_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S10_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileDiffUNC,'Actual') WHEN 'Actual' THEN Stripes.S10_pdn ELSE @FromFileDiffUNC + SUBSTRING(Stripes.S10_pdn,LEN(Stripes.S10_pdn) - CHARINDEX('\',REVERSE(Stripes.S10_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S10_pdn),1) + 1) END + ''''
    END +
 
     
    'WITH REPLACE, FILE = ' + CAST(CTE.Position AS VARCHAR(5)) + ',' +
    CASE CTE.has_backup_checksums WHEN 1 THEN 'CHECKSUM, ' ELSE ' ' END +
     
    CASE @StandbyMode WHEN 0 THEN 'NORECOVERY,' ELSE 'STANDBY =N' + '''' + ISNULL(@FromFileFullUNC,SUBSTRING(CTE.physical_device_name,1,LEN(CTE.physical_device_name) - CHARINDEX('\',REVERSE(CTE.physical_device_name)))) + '\' + d.name + '_ROLLBACK_UNDO.bak ' + ''''  + ',' END + SPACE(1) +
     
    'STATS=10,' + SPACE(1) +
    'MOVE N' + '''' + x.LogicalName + '''' + ' TO ' +
    '''' +
    CASE ISNULL(@WithMoveDataFiles,'Actual')
    WHEN 'Actual' THEN x.PhysicalName
    ELSE @WithMoveDataFiles + SUBSTRING(x.PhysicalName,LEN(x.PhysicalName) - CHARINDEX('\',REVERSE(x.PhysicalName),1) + 2,CHARINDEX('\',REVERSE(x.PhysicalName),1) + 1)
    END + '''' + ',' + SPACE(1) +
     
    'MOVE N' + '''' + y.LogicalName + '''' + ' TO ' +
    '''' +
    CASE ISNULL(@WithMoveLogFile ,'Actual')
    WHEN 'Actual' THEN y.PhysicalName
    ELSE @WithMoveLogFile  + SUBSTRING(y.PhysicalName,LEN(y.PhysicalName) - CHARINDEX('\',REVERSE(y.PhysicalName),1) + 2,CHARINDEX('\',REVERSE(y.PhysicalName),1) + 1)
    END + '''' AS Command,
    32769/2 AS Sequence,
    d.name AS database_name,
    CTE.physical_device_name AS BackupDevice,
    CTE.backupfinishdate,
    CTE.backup_size,
    CTE.Last_LSN
 
FROM sys.databases d
 
JOIN CTE
ON CTE.database_name = d.name
AND CTE.family_sequence_number = 1
 
LEFT OUTER JOIN Stripes
ON Stripes.database_name = d.name
AND Stripes.backupmediasetid = CTE.backupmediasetid
AND Stripes.last_lsn = CTE.Last_LSN
 
JOIN
(
SELECT
    DB_NAME(mf.database_id) AS name
    ,mf.Physical_Name AS PhysicalName
    ,mf.Name AS LogicalName
FROM sys.master_files mf
WHERE type_desc = 'ROWS'
AND mf.file_id = 1
) x
ON d.name = x.name
 
JOIN
(
SELECT
    DB_NAME(mf.database_id) AS name, type_desc
    ,mf.Physical_Name PhysicalName
    ,mf.Name AS LogicalName
FROM sys.master_files mf
WHERE type_desc = 'LOG'
) y
ON d.name = y.name
 
JOIN
(
SELECT
    database_name,
    Last_LSN,
    backupfinishdate
FROM CTE
WHERE [Type] = 'D'
) z
ON CTE.database_name = z.database_name
 
WHERE CTE.[type] = 'I'
AND CTE.backupfinishdate > z.backupfinishdate -- Differential backup was after selected full backup
AND CTE.Last_LSN > z.Last_LSN -- Differential Last LSN > Full Last LSN
AND CTE.backupfinishdate < @StopAt
AND CTE.family_sequence_number = 1
 
--------------------------------------------------------------
UNION -- Log backups taken since most recent full or diff
--------------------------------------------------------------
 
SELECT
    ';SELECT ''' + 'RESTORE_LOG'' AS STEP' + ';RESTORE LOG [' + d.[name] + ']' + SPACE(1) +
    'FROM DISK = N' + '''' + --CTE.physical_device_name + '''' + SPACE(1) +
    CASE ISNULL(@FromFileLogUNC,'Actual')
    WHEN 'Actual' THEN CTE.physical_device_name
    ELSE @FromFileLogUNC + SUBSTRING(CTE.physical_device_name,LEN(CTE.physical_device_name) - CHARINDEX('\',REVERSE(CTE.physical_device_name),1) + 2,CHARINDEX('\',REVERSE(CTE.physical_device_name),1) + 1)
    END + '''' +
     
    -- Striped backup files
    CASE ISNULL(Stripes.S2_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileLogUNC,'Actual') WHEN 'Actual' THEN Stripes.S2_pdn ELSE @FromFileLogUNC + SUBSTRING(Stripes.S2_pdn,LEN(Stripes.S2_pdn) - CHARINDEX('\',REVERSE(Stripes.S2_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S2_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S3_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileLogUNC,'Actual') WHEN 'Actual' THEN Stripes.S3_pdn ELSE @FromFileLogUNC + SUBSTRING(Stripes.S3_pdn,LEN(Stripes.S3_pdn) - CHARINDEX('\',REVERSE(Stripes.S3_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S3_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S4_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileLogUNC,'Actual') WHEN 'Actual' THEN Stripes.S4_pdn ELSE @FromFileLogUNC + SUBSTRING(Stripes.S4_pdn,LEN(Stripes.S4_pdn) - CHARINDEX('\',REVERSE(Stripes.S4_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S4_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S5_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileLogUNC,'Actual') WHEN 'Actual' THEN Stripes.S5_pdn ELSE @FromFileLogUNC + SUBSTRING(Stripes.S5_pdn,LEN(Stripes.S5_pdn) - CHARINDEX('\',REVERSE(Stripes.S5_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S5_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S6_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileLogUNC,'Actual') WHEN 'Actual' THEN Stripes.S6_pdn ELSE @FromFileLogUNC + SUBSTRING(Stripes.S6_pdn,LEN(Stripes.S6_pdn) - CHARINDEX('\',REVERSE(Stripes.S6_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S6_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S7_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileLogUNC,'Actual') WHEN 'Actual' THEN Stripes.S7_pdn ELSE @FromFileLogUNC + SUBSTRING(Stripes.S7_pdn,LEN(Stripes.S7_pdn) - CHARINDEX('\',REVERSE(Stripes.S7_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S7_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S8_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileLogUNC,'Actual') WHEN 'Actual' THEN Stripes.S8_pdn ELSE @FromFileLogUNC + SUBSTRING(Stripes.S8_pdn,LEN(Stripes.S8_pdn) - CHARINDEX('\',REVERSE(Stripes.S8_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S8_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S9_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileLogUNC,'Actual') WHEN 'Actual' THEN Stripes.S9_pdn ELSE @FromFileLogUNC + SUBSTRING(Stripes.S9_pdn,LEN(Stripes.S9_pdn) - CHARINDEX('\',REVERSE(Stripes.S9_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S9_pdn),1) + 1) END + ''''
    END +
     
    CASE ISNULL(Stripes.S10_pdn,'')
    WHEN '' THEN ''
    ELSE  ', DISK = N' + '''' + CASE ISNULL(@FromFileLogUNC,'Actual') WHEN 'Actual' THEN Stripes.S10_pdn ELSE @FromFileLogUNC + SUBSTRING(Stripes.S10_pdn,LEN(Stripes.S10_pdn) - CHARINDEX('\',REVERSE(Stripes.S10_pdn),1) + 2,CHARINDEX('\',REVERSE(Stripes.S10_pdn),1) + 1) END + ''''
    END +
     
    CASE @StandbyMode WHEN 0 THEN ' WITH NORECOVERY,' ELSE ' WITH STANDBY =N' + '''' + ISNULL(@FromFileFullUNC,SUBSTRING(CTE.physical_device_name,1,LEN(CTE.physical_device_name) - CHARINDEX('\',REVERSE(CTE.physical_device_name)))) + '\' + d.name + '_ROLLBACK_UNDO.bak ' + ''''  + ',' END + SPACE(1) +
     
    CASE CTE.has_backup_checksums WHEN 1 THEN ' CHECKSUM, ' ELSE ' ' END +
     
    + 'FILE = ' + CAST(CTE.Position AS VARCHAR(5)) +
    ' ,STOPAT = ' + '''' + CONVERT(VARCHAR(21),@StopAt,120) + '''' +
    ',MOVE N' + '''' + x2.LogicalName + '''' + ' TO ' +
    '''' +
    CASE ISNULL(@WithMoveDataFiles,'Actual')
    WHEN 'Actual' THEN x2.PhysicalName
    ELSE @WithMoveDataFiles + SUBSTRING(x2.PhysicalName,LEN(x2.PhysicalName) - CHARINDEX('\',REVERSE(x2.PhysicalName),1) + 2,CHARINDEX('\',REVERSE(x2.PhysicalName),1) + 1)
    END + '''' + ',' + SPACE(1) +
     
    'MOVE N' + '''' + y1.LogicalName + '''' + ' TO ' +
    '''' +
    CASE ISNULL(@WithMoveLogFile ,'Actual')
    WHEN 'Actual' THEN y1.PhysicalName
    ELSE @WithMoveLogFile  + SUBSTRING(y1.PhysicalName,LEN(y1.PhysicalName) - CHARINDEX('\',REVERSE(y1.PhysicalName),1) + 2,CHARINDEX('\',REVERSE(y1.PhysicalName),1) + 1)
    END + ''''
    AS Command,
    32769 AS Sequence,
    d.name AS database_name,
    CTE.physical_device_name AS BackupDevice,
    CTE.backupfinishdate,
    CTE.backup_size,
    CTE.Last_LSN
 
FROM sys.databases d
 
JOIN CTE
ON CTE.database_name = d.name
AND CTE.family_sequence_number = 1
 
LEFT OUTER JOIN Stripes
ON Stripes.database_name = d.name
AND Stripes.backupmediasetid = CTE.backupmediasetid
AND Stripes.last_lsn = CTE.Last_LSN
 
LEFT OUTER JOIN  -- Next full backup after STOPAT
(
SELECT
    database_name,
    MIN(BackupFinishDate) AS backup_finish_date
FROM CTE
WHERE type = 'D'
AND backupfinishdate > @StopAt
GROUP BY database_name
 
) x
ON x.database_name = CTE.database_name
 
LEFT OUTER JOIN -- Highest differential backup date
(
SELECT
    database_name,
    max(backupfinishdate) AS backupfinishdate
FROM CTE
WHERE CTE.type = 'I'
AND CTE.backupfinishdate < @StopAt
GROUP BY database_name
) y
ON y.database_name = CTE.database_name
 
LEFT OUTER JOIN -- First log file after STOPAT
(
SELECT
    database_name,
    min(backupfinishdate) AS backupfinishdate
FROM CTE
WHERE CTE.type = 'L'
AND backupfinishdate > @StopAt
GROUP BY database_name
) z
ON z.database_name = CTE.database_name
 
JOIN
(
SELECT
    database_name,
    MAX(Last_LSN) AS Last_LSN
FROM CTE
WHERE CTE.backupfinishdate < ISNULL(@StopAt,GETDATE())
AND CTE.Type IN ('D','I')
GROUP BY database_name
) x1
ON CTE.database_name = x1.database_name
 
JOIN
(
SELECT
    DB_NAME(mf.database_id) AS name
    ,mf.Physical_Name AS PhysicalName
    ,mf.Name AS LogicalName
FROM sys.master_files mf
WHERE type_desc = 'ROWS'
AND mf.file_id = 1
) x2
ON d.name = x2.name
 
JOIN
(
SELECT
    DB_NAME(mf.database_id) AS name, type_desc
    ,mf.Physical_Name PhysicalName
    ,mf.Name AS LogicalName
FROM sys.master_files mf
WHERE type_desc = 'LOG'
) y1
ON d.name = y1.name
 
WHERE CTE.[type] = 'L'
AND CTE.backupfinishdate <= ISNULL(x.backup_finish_date,'31 Dec, 2199') -- Less than next full backup
AND CTE.backupfinishdate >= ISNULL(y.backupfinishdate, CTE.backupfinishdate) --Great than or equal to last differential backup
AND CTE.backupfinishdate <= ISNULL(z.backupfinishdate, CTE.backupfinishdate) -- Less than or equal to last file file in recovery chain (IE Log Backup datetime might be after STOPAT)
AND CTE.family_sequence_number = 1
 
 
--------------------------------------------------------------
UNION -- Restore WITH RECOVERY
--------------------------------------------------------------
SELECT
    ';SELECT ''' + 'RESTORE_RECOVERY'' AS STEP' + ';RESTORE DATABASE [' + d.[name] + ']' + SPACE(1) + 'WITH RECOVERY' AS Command,
    32771 AS Sequence,
    d.name AS database_name,
    '' AS BackupDevice,
    GETDATE() AS backupfinishdate,
    CTE.backup_size,
    '99999999999999998' AS Last_LSN
 
FROM sys.databases d
 
JOIN CTE
ON CTE.database_name = d.name
 
WHERE CTE.[type] = 'D'
AND @WithRecovery = 1
 
--------------------------------------------------------------
UNION -- CHECKDB
--------------------------------------------------------------
SELECT
    ';SELECT ''' + 'DBCC_CHECKDB'' AS STEP' + ';DBCC CHECKDB(' + '''' + d.[name] + '''' + ') WITH NO_INFOMSGS IF @@ERROR > 0 PRINT N''CONSISTENCY PROBLEMS IN DATABASE : ' + d.name + ''' ELSE PRINT N''CONSISTENCY GOOD IN DATABASE : ' + d.name + '''' AS Command,
    32772 AS Sequence,
    d.name AS database_name,
    '' AS BackupDevice,
    DATEADD(minute,1,GETDATE()) AS backupfinishdate,
    CTE.backup_size,
    '99999999999999999' AS Last_LSN
 
FROM sys.databases d
 
JOIN CTE
ON CTE.database_name = d.name
 
WHERE CTE.[type] = 'D'
AND @WithCHECKDB = 1
AND @WithRecovery = 1
 
--------------------------------------------------------------
UNION -- WITH MOVE secondary data files, allows for up to 32769/2 file groups
--------------------------------------------------------------
SELECT
    ', MOVE N' + '''' + b.name + '''' + ' TO N' +
    '''' +
    CASE ISNULL(@WithMoveDataFiles,'Actual')
    WHEN 'Actual' THEN b.physical_name
    ELSE @WithMoveDataFiles + SUBSTRING(b.Physical_Name,LEN(b.Physical_Name) - CHARINDEX('\',REVERSE(b.Physical_Name),1) + 2,CHARINDEX('\',REVERSE(b.Physical_Name),1) + 1)
    END + '''',
    b.file_id AS Sequence,
    DB_NAME(b.database_id) AS database_name,
    'SECONDARY FULL' AS BackupDevice,
    CTE.backupfinishdate,
    CTE.backup_size,
    CTE.Last_LSN
     
FROM sys.master_files b
INNER JOIN CTE
ON CTE.database_name = DB_NAME(b.database_id)
 
WHERE CTE.[type] = 'D'
AND b.type_desc = 'ROWS'
AND b.file_id > 2
--------------------------------------------------------------
) a
--------------------------------------------------------------
 
WHERE a.database_name = ISNULL(@database,a.database_name)
AND (@IncludeSystemDBs = 1 OR a.database_name NOT IN('master','model','msdb'))
 
ORDER BY
    database_name,
    sequence
 
 
END


GO

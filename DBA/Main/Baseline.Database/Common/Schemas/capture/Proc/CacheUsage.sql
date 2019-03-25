EXEC #CreateDummyStoredProcedureIfNotExists 'capture', 'CacheUsage'
GO
ALTER procedure [capture].[CacheUsage]
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @sqlstring NVARCHAR(MAX);
DECLARE @DBName NVARCHAR(257);

DECLARE DBCursor CURSOR LOCAL FORWARD_ONLY STATIC READ_ONLY
FOR
    SELECT  name
    FROM    [sys].[databases]
    WHERE   [state] = 0
    ORDER BY [name];

BEGIN
	DECLARE @CaptureDataID int
	DECLARE @ServerName varchar(300),@NodeName varchar(300)
	SELECT @ServerName = convert(nvarchar(128), serverproperty('servername'))
	SELECT @NodeName = convert(nvarchar(128), serverproperty('ComputerNamePhysicalNetBIOS'))

	INSERT INTO capture.CacheUsageData (StartTime, EndTime, ServerName,PullPeriod,Node)
	VALUES (GETDATE(), NULL, @ServerName, 0,@NodeName)
	SELECT @CaptureDataID = SCOPE_IDENTITY()
		
    OPEN DBCursor;
    FETCH NEXT FROM DBCursor INTO @DBName;
    WHILE @@FETCH_STATUS <> -1 
        BEGIN
            SET @sqlstring = N'USE [' + @DBName + ']
      ; INSERT ['+db_name()+'].[capture].[CacheUsageResults] (
      objectname, name, type_desc, Buffered_Page_Count, Buffered_MB, CaptureDate,dbname,Captureid)
select objectname,name,type_desc,Buffered_Page_Count,cast(Buffered_Page_Count as float)* 8192 / (1024 * 1024) Buffered_MB,getdate() Capturedate,db_name(database_id) dbname, '+CAST(@CaptureDataID as varchar(100))+' from (
SELECT  
	obj.[name] objectname,
	i.[name] name,
	i.[type_desc],
	count(*)AS Buffered_Page_Count ,database_id
	--, isnull(count(*)* 8192 / (1024 * 1024) as Buffer_MB
    -- ,obj.name ,obj.index_id, i.[name]
FROM sys.dm_os_buffer_descriptors AS bd 
    INNER JOIN 
    (
        SELECT object_name(object_id) AS name 
            ,index_id ,allocation_unit_id, object_id
        FROM sys.allocation_units AS au
            INNER JOIN sys.partitions AS p 
                ON au.container_id = p.hobt_id 
                    AND (au.type = 1 OR au.type = 3)
        UNION ALL
        SELECT object_name(object_id) AS name   
            ,index_id, allocation_unit_id, object_id
        FROM sys.allocation_units AS au
            INNER JOIN sys.partitions AS p 
                ON au.container_id = p.hobt_id 
                    AND au.type = 2
    ) AS obj 
        ON bd.allocation_unit_id = obj.allocation_unit_id
LEFT JOIN sys.indexes i on i.object_id = obj.object_id AND i.index_id = obj.index_id
WHERE database_id = db_id(''[' + @DBName+ ']'' )
GROUP BY obj.name, obj.index_id , i.[name],i.[type_desc],database_id
having count(*)>1000
--ORDER BY Buffered_Page_Count DESC
) q
ORDER BY Buffered_Page_Count DESC'
            PRINT (@sqlstring)
			EXEC (@sqlstring)
            FETCH NEXT FROM DBCursor INTO @DBName;
        END

    CLOSE DBCursor;
    DEALLOCATE DBCursor;

	 UPDATE [capture].[CacheUsageData]
	 SET EndTime = GETDATE()
	 WHERE ID = @CaptureDataID
END

GO
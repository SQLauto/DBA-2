EXEC #CreateDummyStoredProcedureIfNotExists 'capture', 'FileInformation'
GO
ALTER PROC [capture].[FileInformation] 
AS



SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
DECLARE @sqlstring NVARCHAR(MAX);
DECLARE @DBName NVARCHAR(257);
DECLARE @dbId smallint

DECLARE DBCursor CURSOR LOCAL FORWARD_ONLY STATIC READ_ONLY
FOR
    SELECT  [name],database_id
    FROM    [sys].[databases]
    WHERE   [state] = 0
    ORDER BY [name];

BEGIN
    OPEN DBCursor;
    FETCH NEXT FROM DBCursor INTO @DBName,@dbId;
    WHILE @@FETCH_STATUS <> -1 
        BEGIN

            SET @sqlstring = N'USE [' + @DBName + ']
      ; INSERT [$(databasename)].[capture].[FileInfo] ([DatabaseName],
      [DatabaseId],
      [FileID],
      [SizeMB],
      [SpaceUsedMB],
      [FreeSpaceMB],
      [MaxSize],
      [IsPercentGrowth],
      [Growth],
      [CaptureDate],Filetype,LogicalFileName,
PhysicalFileName,DriveLetter
      )
      SELECT  ''' + CAST(@DBName as varchar(128))
                + ''', 
       ''' + CAST(@dbId as varchar(2))
                + ''' 
      ,[file_id],
      CAST([size] as DECIMAL(38,0))/128., 
      CAST(FILEPROPERTY([name],''SpaceUsed'') AS DECIMAL(38,0))/128., 
      (CAST([size] as DECIMAL(38,0))/128) - (CAST(FILEPROPERTY([name],''SpaceUsed'') AS DECIMAL(38,0))/128.),
      [max_size],
      [is_percent_growth],
      [growth],
      GETDATE(),
	  Type,name,physical_name,left(physical_name,1) driveletter
      FROM [' + @DBName + '].[sys].[database_files](nolock);'
            PRINT @sqlstring
			EXEC (@sqlstring)
            FETCH NEXT FROM DBCursor INTO @DBName,@dbId;
        END
		
    CLOSE DBCursor;
    DEALLOCATE DBCursor;
END




GO
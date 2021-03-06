EXEC #CreateDummyStoredProcedureIfNotExists 'dbo', 'TableSize'
GO

ALTER PROCEDURE [dbo].[TableSize] @db varchar(50)='system'
AS


/* Simon D'Morias ammended August 2005 to run in any database from the system db
Also corrected problem whith table names including spaces
*/

	SET NOCOUNT ON
	set transaction isolation level read uncommitted;
	
	DECLARE @ObjectName sysname, @Owner sysname
	DECLARE @cmd varchar(1000)

	CREATE TABLE #TempInfo (
		[Name] sysname,
		[rows] bigint NULL,
		reserved varchar(20) NULL,
		data varchar(20) NULL,
		index_size varchar(20) NULL,
		unused varchar(20) NULL
		
	)
	
	CREATE TABLE #TableList (
		TABLE_QUALIFIER sysname,
		TABLE_OWNER sysname,
		TABLE_NAME sysname,
		TABLE_TYPE varchar(32),
		REMARKS varchar(254)
	)
	SET @cmd = 'EXEC ['+@db+'].dbo.sp_tables'
	INSERT #TableList EXEC (@cmd)
	
	DECLARE cCursor CURSOR LOCAL FOR
	SELECT TABLE_NAME, TABLE_OWNER
	FROM #TableList (NOLOCK)
	WHERE TABLE_TYPE = 'TABLE'
	
	OPEN cCursor
	
	FETCH NEXT FROM cCursor
	INTO @ObjectName, @Owner
	WHILE @@FETCH_STATUS = 0
	BEGIN
		BEGIN TRY
			SET @cmd = 'EXEC ['+@db+'].dbo.sp_spaceused '''+@Owner+'.'+@objectname+''''
			INSERT #TempInfo EXEC (@cmd)
		END TRY
		BEGIN CATCH
			PRINT @cmd
		END CATCH
	
		FETCH NEXT FROM cCursor INTO @ObjectName, @Owner
	END
	

	CLOSE cCursor
	DEALLOCATE cCursor
	
	SELECT [Name], [rows],
		CAST(REPLACE(reserved, ' KB', '') AS int) AS [reserved_kb],
		CAST(REPLACE(data, ' KB', '') AS int) AS [Data_kb],
		CAST(REPLACE(index_size, ' KB', '') AS int) AS [index_size_kb],
		CAST(REPLACE(unused, ' KB', '') AS int) AS [unused_kb],
		(CAST(REPLACE(reserved, ' KB', '') AS int) - CAST(REPLACE(unused, ' KB', '') AS int)) AS [size_kb]
	FROM #TempInfo
	WHERE [rows] IS NOT NULL
	ORDER BY CAST(REPLACE(data, ' KB', '') AS int) DESC
	
	DROP TABLE #TableList
	DROP TABLE #TempInfo


GO

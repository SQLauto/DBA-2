EXEC #CreateDummyStoredProcedureIfNotExists 'dbo', 'FragmentationCheck'
GO
ALTER  PROCEDURE [dbo].[FragmentationCheck] (@TargetDatabase AS VARCHAR(255))
AS
/*
Simon D'Morias
30th August 2005
Performs a DBCC SHOWCONTIG on all databases in all user databases and logs the results to the FragmentationLevels table	
*/		
SET NOCOUNT ON
SET XACT_ABORT ON

SET @TargetDatabase = LTRIM(RTRIM(@TargetDatabase))

DECLARE @SQLLine AS NVARCHAR(3000)

SET @SQLLine = 
'USE [' + @TargetDatabase + ']
	SET NOCOUNT ON
	SET XACT_ABORT ON
	SET QUOTED_IDENTIFIER OFF

DECLARE @tablename VARCHAR (128)

-- Declare cursor
DECLARE tables2 CURSOR FOR
   SELECT TABLE_SCHEMA + ''.'' + TABLE_NAME
   FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_NAME NOT LIKE ''%000%''
	AND TABLE_TYPE = ''BASE TABLE''

-- Create the table
CREATE TABLE #fraglist (
   ObjectName CHAR (255),
   ObjectId INT,
   IndexName CHAR (255),
   IndexId INT,
   Lvl INT,
   CountPages INT,
   CountRows INT,
   MinRecSize INT,
   MaxRecSize INT,
   AvgRecSize INT,
   ForRecCount INT,
   Extents INT,
   ExtentSwitches INT,
   AvgFreeBytes INT,
   AvgPageDensity INT,
   ScanDensity DECIMAL,
   BestCount INT,
   ActualCount INT,
   LogicalFrag DECIMAL,
   ExtentFrag DECIMAL)

-- Open the cursor
OPEN tables2


-- Loop through all the tables in the database
FETCH NEXT
   FROM tables2
   INTO @tablename

WHILE @@FETCH_STATUS = 0
BEGIN
-- Do the showcontig of all indexes of the table
   INSERT INTO #fraglist 
   EXEC ("DBCC SHOWCONTIG (""" + @tablename + """) 
      WITH FAST, TABLERESULTS, ALL_INDEXES, NO_INFOMSGS")
   FETCH NEXT
      FROM tables2
      INTO @tablename
END

-- Close and deallocate the cursor
CLOSE tables2
DEALLOCATE tables2

INSERT INTO SYSTEM.dbo.FragmentationLevels
SELECT 	@@ServerName,
	db_Name(),
	ObjectName,
	IndexName,
	CountPages,
	CountRows,
	MinRecSize,
   	MaxRecSize,
   	AvgRecSize,
	ForRecCount,
	Extents,
   	AvgFreeBytes,
   	AvgPageDensity,
   	ScanDensity,
   	BestCount,
   	ActualCount,
   	LogicalFrag,
   	ExtentFrag,
	GETDATE()
FROM #fraglist
DROP TABLE #fraglist'
EXECUTE SP_ExecuteSQL @SQLLine


GO

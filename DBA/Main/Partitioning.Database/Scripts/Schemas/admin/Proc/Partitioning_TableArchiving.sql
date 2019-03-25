EXEC #CreateDummyStoredProcedureIfNotExists @SchemaName = 'admin', @ProcedureName = 'Partitioning_TableArchiving'
GO

ALTER PROCEDURE [admin].[Partitioning_TableArchiving]
(
@SourceSchema VARCHAR(50) = NULL,
@DestSchema VARCHAR(10) = NULL, -- Optional for unit test, otherwise takes from partition config
@ArchiveRunDate DATETIME -- Optional for unit test, otherwise takes from partition config
)
AS
BEGIN
-- =============================================
-- Description:				This runs as part of a job to 
--                         1. Move old data from the main table to an archive table
--                         2. Remove old data from the archive table.
--                         3. Remove unused data files 
-- Parameters In: 
--                         @TableSChema         Schema for the tables
--                         @MainRetention       Max number of weeks from the current date that should be held in the source table
--                         @ArchiveRetention	Max number of weeks from the current date that should be held in the archive table
-- Examples Inputs:
--                         @SourceSchema = 'travel'
--                         @MainRetention = 2
--                         @ArchiveRetention = 40
-- =============================================

SET NOCOUNT ON; 
DECLARE @FileName VARCHAR(100) ,@FileGroup VARCHAR(100), @FileLocation VARCHAR(100),  @SQL VARCHAR(MAX), @PFName VARCHAR(200);
DECLARE @PartitionID INT, @FailedCount SMALLINT=0,@IntRange INT,@MergeRange varchar(100), @DateRange SMALLDATETIME,  @ErrMsg NVARCHAR(4000);
DECLARE @NoOfRows BIGINT, @FileID BIGINT, @Table VARCHAR(100), @PartitionSchema VARCHAR(100);
DECLARE @PartitionKey VARCHAR(100),@PSName VARCHAR(100), @ArchiveTableRowCount BIGINT,@MainRetention INT;
DECLARE @ArchiveRetention INT,@ParameterDataType varchar(30),@PartitionBoundary VARCHAR(100),@periodbeginning DATETIME;
DECLARE @NSQL NVARCHAR(MAX),@DeleteTable VARCHAR(100),@TargetDataSpace VARCHAR(100);
DECLARE @LiveSchema SYSNAME, @ArchiveSchema SYSNAME;

/*
Working with travelday cycles that run from Monday To Monday 
Datefirst 1 makes this easier to manage
*/
SET DATEFIRST 1; 

/*
Drop Temporary tables 
*/

IF OBJECT_ID('tempdb..#partitions') IS NOT NULL
	DROP TABLE #partitions;
IF OBJECT_ID('tempdb..#indexes') IS NOT NULL
	DROP TABLE #indexes;
IF OBJECT_ID('tempdb..#data_spaces') IS NOT NULL
	DROP TABLE #data_spaces;
IF OBJECT_ID('tempdb..#partition_schemes') IS NOT NULL
	DROP TABLE #partition_schemes;
IF OBJECT_ID('tempdb..#partition_functions') IS NOT NULL
	DROP TABLE #partition_functions;
IF OBJECT_ID('tempdb..#destination_data_spaces') IS NOT NULL
	DROP TABLE #destination_data_spaces;
IF OBJECT_ID('tempdb..#filegroups') IS NOT NULL
	DROP TABLE #filegroups;
IF OBJECT_ID('tempdb..#PartitionInfo') IS NOT NULL
	DROP TABLE #PartitionInfo;
IF OBJECT_ID('tempdb..#PartitionNumberToFilegroup') IS NOT NULL
	DROP TABLE #PartitionNumberToFilegroup;
IF OBJECT_ID('tempdb..#filegroupremove') IS NOT NULL
	DROP TABLE #filegroupremove;
IF OBJECT_ID('tempdb..#database_files') IS NOT NULL
	DROP TABLE #database_files;
IF OBJECT_ID('tempdb..#FirstPartitionFileGroup') IS NOT NULL
	DROP TABLE #FirstPartitionFileGroup;

/* 
	Two main tables are populated for use
	#PartitionInfo and #PartitionNumberToFilegroup 
	which allow us to see all the info rquired to implement the partitioning logic
*/

CREATE TABLE #PartitionInfo
(
	[function_id] [int] NOT NULL,
	[name] [sysname] NOT NULL,
	[NumPartitions] [int] NOT NULL,
	[RangeType] [varchar](5) NOT NULL,
	[parameter_id] [int] NOT NULL,
	[ParameterDataType] [sysname] NOT NULL,
	[boundary_id] [int] NOT NULL,
	[PartitionBoundary] [varchar](100) NULL,
	[PartitionNumber] [int] NULL,
	[partitionkey] [varchar](50) NOT NULL,
	[PartitionKeyLength] varchar(10) NOT NULL,
	[ReadWriteRetention] INT NOT NULL,
	[archiveretention] INT NOT NULL,
	[ArchiveRunDate] [datetime]  NULL,
	[PeriodBeginning] [datetime]  NULL,
	[PeriodType] varchar(2) NULL,
	[Archive] bit NULL,
	[Remove] bit NULL,
	[Strategy] TINYINT,
	[PartitionKeyDataType] varchar(100),
	[LiveSchema] SYSNAME,
	[ArchiveSchema] SYSNAME
)
INSERT INTO #PartitionInfo
(
	[function_id], 
	[name], 
	[NumPartitions], 
	[RangeType], 
	[parameter_id], 
	[ParameterDataType], 
	[boundary_id]
	,[PartitionBoundary], 
	[PartitionNumber],
	[partitionkey], 
	[PartitionKeyLength], 
	[ReadWriteRetention], 
	[archiveretention], 
	[PeriodType], 
	[Strategy],
	[PartitionKeyDataType],
	[LiveSchema],
	[ArchiveSchema]
 )
SELECT 
    PF.function_id
  , PF.name
  , PF.fanout AS NumPartitions
  , CASE WHEN PF.boundary_value_on_right = 0 
      THEN 'LEFT' ELSE 'RIGHT' END AS RangeType
  , PP.parameter_id
  , CASE WHEN PP.system_type_id = PP.user_type_id 
		THEN T1.name ELSE T2.name END AS ParameterDataType
  , PRV.boundary_id
  ,CAST(PRV.value as varchar(100)) PartitionBoundary
  ,CASE WHEN PF.boundary_value_on_right = 0 THEN PRV.boundary_id ELSE PRV.boundary_id + 1 END AS PartitionNumber
  ,PC.partitionkey
  ,PC.PartitionKeyLength
  ,PC.ReadWriteRetention
  ,PC.ArchiveRetention
  ,PC.PeriodType
  ,PC.Strategy
  ,PC.PartitionKeyDataType
  ,CASE ISNULL(@SourceSchema,'') 
     WHEN '' THEN PC.LiveSchema
     ELSE @SourceSchema
   END
  ,CASE ISNULL(@DestSchema,'')
     WHEN '' THEN PC.ArchiveSchema
     ELSE @DestSchema
   END
FROM sys.partition_functions AS PF
JOIN sys.partition_parameters AS PP
	ON PF.function_id = PP.function_id
JOIN sys.types AS T1 
	ON T1.system_type_id = PP.system_type_id
JOIN sys.types AS T2 
	ON T2.user_type_id= PP.user_type_id
JOIN sys.partition_range_values AS PRV 
	ON PP.function_id = PRV.function_id 
   AND PP.parameter_id = PRV.parameter_id
JOIN [admin].[PartitionConfig] PC 
	ON SUBSTRING(PF.name,4,100)=PC.name 
	AND PC.Archive=1
ORDER BY FUNCTION_id,Boundary_id;

/*
	The [internal].[PartitionConfig] table is where all the configuration resides. It contains a row for every partitioned table in the DB
	It is used for creation of filegroups and for archiving. 
	For this proc we are interested in ReadWriteRetention and ArchiveRetention values
	ReadwriteRetention is the number of weeks we keep the data in the  dbo(PARE)/travel schema(FAE) schema and archiveretention is the number of weeks after ReadwriteRetention
	we keep the data in the archive section.

	For example:
	If  ReadwriteRetention=2 and ArchiveRetention=3
	Then 2 weeks are in the dbo(PARE)/travel schema(FAE) and 3 weeks are in the archive schema. 5 weeks total

*/

UPDATE #PartitionInfo
SET [PartitionBoundary]= CONVERT(VARCHAR(11),CAST([PartitionBoundary] AS DATETIMEOFFSET),121) + ' 00:00:00.0000000 +00:00'
WHERE [ParameterDataType]='datetimeoffset';

CREATE TABLE #PartitionNumberToFilegroup
(
	PartitionFunctionid INT,
	PartitionNumber INT,
	FileGroupName VARCHAR(100),
	Rows INT,
	PartitionScheme VARCHAR(100),
	Tablename VARCHAR(100),
	Schemaname VARCHAR(100),
	is_read_only BIT,
	FILENAME VARCHAR(100),
	physicalfilename VARCHAR(MAX)
);

/* These temp tables are created for performance of the extraction query into #PartitionNumberToFilegroup */
SELECT partition_number,object_id,index_id,[rows] INTO #partitions FROM sys.partitions;
SELECT object_id,index_id,data_space_id,[type] INTO #indexes FROM sys.indexes;
SELECT data_space_id INTO #data_spaces FROM sys.data_spaces;
SELECT data_space_id,name,function_id INTO #partition_schemes FROM sys.partition_schemes;
SELECT name, function_id INTO #partition_functions FROM sys.partition_functions;
SELECT partition_scheme_id,destination_id,data_space_id INTO #destination_data_spaces FROM sys.destination_data_spaces;
SELECT data_space_id,name, is_read_only INTO #filegroups FROM sys.filegroups; 
SELECT data_space_id,name [filename],physical_name physicalfilename INTO #database_files FROM sys.database_files WHERE state_desc = 'ONLINE';


INSERT INTO #PartitionNumberToFilegroup
(
	PartitionFunctionid,PartitionNumber,FileGroupName,Rows,PartitionScheme,
	TableName,SchemaName,is_read_only,filename,physicalfilename 
)
SELECT 
	pf.function_id,  P.partition_number AS PartitionNumber
	, FG.name AS FileGroupName,P.rows,PS.name,OBJECT_NAME(SI.object_id) TableName,OBJECT_SCHEMA_NAME(SI.object_id) Schemaname,
	FG.is_read_only,df.filename,df.physicalfilename
FROM #partitions AS P
JOIN #indexes AS SI
	ON P.object_id = SI.object_id AND P.index_id = SI.index_id 
JOIN #data_spaces AS DS
	ON DS.data_space_id = SI.data_space_id
JOIN #partition_schemes AS PS
	ON PS.data_space_id = SI.data_space_id
JOIN #partition_functions AS PF
	ON PF.function_id = PS.function_id 
JOIN #destination_data_spaces AS DDS
	ON DDS.partition_scheme_id = SI.data_space_id 
	AND DDS.destination_id = P.partition_number
JOIN #filegroups AS FG
	ON DDS.data_space_id= FG.data_space_id
LEFT JOIN 
	#database_files	 df ON df.data_space_id = fg.data_space_id
WHERE SI.type IN(0,1);


/* This is required so we do not get rid of the first partitions as we need to keep them as its 
	best practice to keep these empty for performant archive maintenance
*/  
CREATE TABLE #FirstPartitionFileGroup
(
	Tablename VARCHAR(100),
	FileGroupName VARCHAR(100),
);

/* We want to leave the first partition empty and do not want to be rid of it*/
INSERT INTO #FirstPartitionFileGroup(Tablename,FileGroupName)
SELECT tablename,filegroupname
FROM 
(
	SELECT pfg.tablename,pfg.FileGroupName,RANK() OVER (PARTITION BY pfg.tablename ORDER BY MIN(PFG.partitionnumber) ASC) AS FilegroupNumber
	FROM #PartitionNumberToFilegroup PFG
	JOIN #PartitionInfo A 
		ON A.function_id=PFG.partitionfunctionid 
		AND A.PartitionNumber=PFG.PartitionNumber
	GROUP BY pfg.tablename, pfg.FileGroupName
) SQ					
WHERE FilegroupNumber=1;

/*
Declare @ArchiveRunDate DATETIME='6 April 2014'

*/
/*
	One of the difficulties with this partition management has been the fact that we have 3 different ways in which we partition in PARE
	FAE only uses travelday but PARE uses either travelday(smallint length 5),Created/Received(datetimeoffset) or expirydatepartition(smallint lenght 4)
	We only archive tables that use created/received or travelday. All card tables don't get archived! There is a archive flage in the [internal].[PartitionConfig]
	table that denotes whether or not we archive the table which is used in the extraction query
	We do the step below to convert each of these into a date we can work with to implement the archive logic
*/
--UPDATE P
--	SET periodbeginning=CASE 
--		WHEN PartitionKeyDataType='DateTimeOffset'  THEN CONVERT(datetime,RIGHT(RW.filegroupname,PartitionKeyLength),121)
--		WHEN partitionkey='Travelday' THEN DATEADD(dd,CAST(RIGHT(RW.filegroupname,PartitionKeyLength) AS INT),'1-JAN-1980')
--	END,
--	ARCHIVERUNDATE=CASE 
--		WHEN PartitionKeyDataType='DateTimeOffset'  THEN  CAST(DATEADD(dd,-(DATEPART(dw,@ArchiveRunDate)-1), @ArchiveRunDate) AS DATE)
--		WHEN partitionkey='Travelday' THEN CAST(DATEADD(dd,-(DATEPART(dw,@ArchiveRunDate)-1), @ArchiveRunDate) AS DATE)
--	END
--FROM #PartitionInfo P
--JOIN #PartitionNumberToFilegroup RW 
--	ON P.function_id=RW.PartitionFunctionid 
--	AND P.PartitionNumber=RW.PartitionNumber; 

UPDATE P
	SET periodbeginning=CASE 
		WHEN Strategy = 0 THEN CONVERT(datetime,RIGHT(RW.filegroupname,PartitionKeyLength),121)
		WHEN Strategy = 1 THEN DATEADD(dd,CAST(RIGHT(RW.filegroupname,PartitionKeyLength) AS INT),'1-JAN-1980')
	END,
	ARCHIVERUNDATE=CASE 
		WHEN Strategy = 0 THEN  CAST(DATEADD(dd,-(DATEPART(dw,@ArchiveRunDate)-1), @ArchiveRunDate) AS DATE)
		WHEN Strategy = 1 THEN CAST(DATEADD(dd,-(DATEPART(dw,@ArchiveRunDate)-1), @ArchiveRunDate) AS DATE)
	END
FROM #PartitionInfo P
JOIN #PartitionNumberToFilegroup RW 
	ON P.function_id=RW.PartitionFunctionid 
	AND P.PartitionNumber=RW.PartitionNumber; 

--Update for partitions that need to go from dbo/travel schema into archive schema
UPDATE  A
SET Archive=1 
FROM #PartitionNumberToFilegroup PFG
JOIN #PartitionInfo A 
	ON A.function_id=PFG.partitionfunctionid 
	AND A.partitionnumber=PFG.PartitionNumber
LEFT JOIN #FirstPartitionFileGroup FP 
	ON FP.Filegroupname=PFG.Filegroupname
WHERE PeriodType='ww' 
AND DATEDIFF(ww,PeriodBeginning,ArchiveRundate) > ReadWriteRetention
AND FP.Filegroupname IS NULL ;

--Update for partitions we need to remove
UPDATE  A
SET Remove=1 
FROM #PartitionNumberToFilegroup PFG
JOIN #PartitionInfo A 
	ON A.function_id=PFG.partitionfunctionid 
	AND A.partitionnumber=PFG.PartitionNumber
LEFT JOIN #FirstPartitionFileGroup FP 
	ON FP.Filegroupname=PFG.Filegroupname
WHERE PeriodType='ww' 
AND DATEDIFF(ww,PeriodBeginning,ArchiveRundate) > archiveretention+ReadWriteRetention
AND FP.Filegroupname IS NULL; 

CREATE CLUSTERED INDEX IX_PartitionInfo ON #PartitionInfo(Function_id,PartitionNumber);
CREATE CLUSTERED INDEX IX_PartitionNumberToFilegroup ON #PartitionNumberToFilegroup(PartitionFunctionid,PartitionNumber,Schemaname);

/* Check to see if Data exists in archive partitions and ReadWrite partitions. Archiving will not take place until this is addressed*/
IF
(
	SELECT COUNT(*)  
	FROM #PartitionInfo P
	JOIN #PartitionNumberToFilegroup RW 
		ON P.function_id=RW.PartitionFunctionid 
		AND P.PartitionNumber=RW.PartitionNumber 
		AND RW.Schemaname=P.LiveSchema
	JOIN #PartitionNumberToFilegroup AR 
		ON P.function_id=AR.PartitionFunctionid 
		AND P.PartitionNumber=AR.PartitionNumber 
		AND AR.Schemaname=P.ArchiveSchema
	WHERE Rw.rows > 0 
	AND AR.rows > 0
) > 0 ---This means there is data in Readwrite and Archive and should never Happen
BEGIN
	RAISERROR ('Data exists in archive partitions and ReadWrite partitions. Archiving will not take place until this is addressed',16,1);
	RETURN;
END 

---------------------------------------------------------------------------------------------------------------------------------	
-- SWITCHING PARTITIONS......
---------------------------------------------------------------------------------------------------------------------------------	
PRINT 'SWITCHING PARTITIONS......'

--Cursor to roll through partitions that need to be switched
DECLARE Switch_Cursor CURSOR FOR 
SELECT 
	DISTINCT P.PartitionNumber,
	RW.Rows,name PFName,
	partitionkey,
	RW.Tablename,
	P.PartitionBoundary,
	P.PeriodBeginning,
	RW.filegroupname,
	P.LiveSchema,
	P.ArchiveSchema
FROM #PartitionInfo P
JOIN #PartitionNumberToFilegroup RW 
	ON P.function_id=RW.PartitionFunctionid 
	AND P.PartitionNumber=RW.PartitionNumber 
	AND RW.Schemaname=P.LiveSchema
JOIN #PartitionNumberToFilegroup AR 
	ON P.function_id=AR.PartitionFunctionid 
	AND P.PartitionNumber=AR.PartitionNumber 
	AND AR.Schemaname=P.ArchiveSchema
WHERE Archive=1 
AND Rw.rows > =0 
AND Ar.rows=0
ORDER by Tablename,P.PartitionNumber ASC;


OPEN Switch_Cursor
FETCH NEXT FROM Switch_Cursor INTO @PartitionID, @NoOfRows, @PFName, @partitionkey, @Table, @PartitionBoundary, @periodbeginning, @filegroup, @LiveSchema, @ArchiveSchema

TryToSwitchDay:

BEGIN TRY
	WHILE @@FETCH_STATUS = 0
	BEGIN
		--switch parttions
		BEGIN TRANSACTION
			SET @SQL = 'ALTER TABLE ' + '[' + @LiveSchema + '].[' + @Table + ']' + ' SWITCH PARTITION ' + 
										  CONVERT(VARCHAR(20),@PartitionID) + ' TO ' + '[' + @ArchiveSchema + '].[' + @Table + ']' + 
										  ' PARTITION '+ CONVERT(VARCHAR(20),@PartitionID);
			EXEC(@SQL);	
					  		  
			--Log activity into admin.PartitionLog table
--			INSERT INTO admin.PartitionLog (EntryDate,ObjectID,DateRangeSwitchedInt,DateRangeSwitchedDate,RowCountSwitched,Success,Comments)
--			VALUES (GETDATE(),OBJECT_ID('[' + @SourceSchema + '].[' + @Table + ']'),null , @periodbeginning,@NoOfRows,1,
--			'Moved Partition ' + CONVERT(VARCHAR(20),@PartitionID) + ' Partitioned on '+@partitionkey+' with value:'+@PartitionBoundary+' from ' + @SourceSchema+'.'+@Table + ' to ' + @DestSchema+'.'+@Table );

			INSERT INTO admin.PartitionLog (EntryDate,ObjectID,DateRangeSwitchedInt,DateRangeSwitchedDate,RowCountSwitched,Success,Comments)
			VALUES (GETDATE(),OBJECT_ID('[' + @LiveSchema + '].[' + @Table + ']'),null , @periodbeginning,@NoOfRows,1, @SQL);

			--This update takes place so we can alter the views that are a union on the dbo and archive once archiving is complete
			--UPDATE  [admin].[PartitionConfig]
			--SET 
			--	 ArchivetoLiveSwitchOverPartitionKeyValue = 
			--		CASE WHEN PartitionKey='TravelDay' THEN CAST(CAST(@PartitionBoundary as INT)+1 as varchar(100))
			--			 WHEN PartitionKeyDataType='DatetimeOffset' THEN CAST(DATEADD(dd,1,CAST(@PartitionBoundary AS Date)) AS VARCHAR(100))
			--		END
			--	,[ArchivetoLiveSwitchOverDate] = 
			--		CASE WHEN PartitionKey='TravelDay' THEN CAST(DATEADD(dd,CAST(@PartitionBoundary as INT)+1,'1 JAN 1980') AS DATE)
			--			 WHEN PartitionKeyDataType='DatetimeOffset' THEN DATEADD(dd,1,CAST(@PartitionBoundary AS Date))
			--		END
--			WHERE name=@Table;

			--This update takes place so we can alter the views that are a union on the dbo and archive once archiving is complete
			UPDATE  [admin].[PartitionConfig]
			SET 
				 ArchivetoLiveSwitchOverPartitionKeyValue = 
					CASE WHEN Strategy = 1 THEN CAST(CAST(@PartitionBoundary as INT)+1 as varchar(100))
						 WHEN Strategy = 0 THEN CAST(DATEADD(dd,1,CAST(@PartitionBoundary AS Date)) AS VARCHAR(100))
					END
				,[ArchivetoLiveSwitchOverDate] = 
					CASE WHEN Strategy = 1 THEN CAST(DATEADD(dd,CAST(@PartitionBoundary as INT)+1,'1 JAN 1980') AS DATE)
						 WHEN Strategy = 0 THEN DATEADD(dd,1,CAST(@PartitionBoundary AS Date))
					END
			WHERE name=@Table;

			
		COMMIT TRANSACTION;
		FETCH NEXT FROM Switch_Cursor INTO @PartitionID, @NoOfRows, @PFName, @partitionkey, @Table, @PartitionBoundary, @periodbeginning, @filegroup, @LiveSchema, @ArchiveSchema;

	END
END TRY
BEGIN CATCH

	--ROLLBACK ANY TRANSACTIONS
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	
	--SET ERROR MESSAGE
	SET @ErrMsg = ERROR_MESSAGE();
		   
	--KEEP A COUNT OF FAILED ATTEMPTS
	SET @FailedCount = @FailedCount + 1;

	--TRY 3 TIMES TO PARTITION, MAY FAIL WITH DEADLOCKING,  WAIT 5 SECS AND RETRY
	IF @FailedCount<10
	BEGIN
		INSERT INTO admin.PartitionLog(EntryDate,ObjectID,DateRangeSwitchedInt,
											DateRangeSwitchedDate, RowCountSwitched,Success,Comments)
		VALUES (GETDATE(),OBJECT_ID('[' + @LiveSchema + '].[' + @Table + ']'),DATEDIFF(DAY,'1-JAN-1980',@DateRange),
					  @DateRange,@NoOfRows,0,@ErrMsg+': Unable to switch partition but will retry on ' + @Table + ' to ' + @Table + ' for partition ' + CONVERT(VARCHAR(20),@PartitionID));

		PRINT 'Waiting 30 seconds before retrying (attempt ' + CONVERT(VARCHAR(2),@FailedCount) + ')';
		WAITFOR DELAY '00:00:30' ;
		GOTO TryToSwitchDay
	END
	ELSE
	BEGIN 
		RAISERROR(@ErrMsg, 18, 1);
		RETURN -1;
	END 

	--ADD ENTRY TO LOG
	INSERT INTO admin.PartitionLog(EntryDate,ObjectID,DateRangeSwitchedInt,
										DateRangeSwitchedDate, RowCountSwitched,Success,Comments)
	VALUES (GETDATE(),OBJECT_ID('[' + @LiveSchema + '].[' + @Table + ']'),DATEDIFF(DAY,'1-JAN-1980',@DateRange),
			@DateRange,@NoOfRows,0,@ErrMsg+'Unable to switch partition on ' + @Table + ' to ' + @Table + ' for partition ' + CONVERT(VARCHAR(20),@PartitionID));
	
	RAISERROR(@ErrMsg,16,1);

END CATCH;

--REMOVE INNER CUSOR
CLOSE Switch_Cursor;
DEALLOCATE Switch_Cursor;

--COMMIT TRANSACTIONS IF SUCCESSFUL
IF @@TRANCOUNT > 0
	COMMIT TRANSACTION;


---------------------------------------------------------------------------------------------------------------------------------	
--SWITCH OUT OLD DATA TO BE DELETED
---------------------------------------------------------------------------------------------------------------------------------	
--THIS STEP WILL MOVE THE DATA THAT MEETS THE ARCHIVE RETENTION PERIOD TO ANOTHER TABLE
--READY TO BE DELETED
---------------------------------------------------------------------------------------------
PRINT 'REMOVE PARTITIONS IN ARCHIVE......' 
		
--SELECT PARTITIONS THAT NEED TO BE SWITCHED OUT
DECLARE Archive_Cursor CURSOR FOR 
SELECT DISTINCT RW.PartitionScheme PSscheme, name PFName, P.PartitionNumber, RW.Rows, RW.Tablename, PartitionKey, RW.filegroupname, P.LiveSchema, P.ArchiveSchema
FROM #PartitionInfo P
JOIN #PartitionNumberToFilegroup RW 
	ON P.function_id=RW.PartitionFunctionid 
	AND P.PartitionNumber=RW.PartitionNumber 
	AND RW.Schemaname=P.LiveSchema
JOIN #PartitionNumberToFilegroup AR 
	ON P.function_id=AR.PartitionFunctionid 
	AND P.PartitionNumber=AR.PartitionNumber 
	AND AR.Schemaname=P.ArchiveSchema
WHERE Remove=1 
ORDER by RW.Tablename,P.PartitionNumber ASC;
	 
OPEN Archive_Cursor

FETCH NEXT FROM Archive_Cursor INTO @PSName, @PFName, @PartitionID, @NoOfRows, @Table, @PartitionKey, @FileGroup, @LiveSchema, @ArchiveSchema
	
SET @FailedCount=0;
TryToReadWrite:

BEGIN TRY
	--MOVE PARTITIONS TO ARCHIVE TABLE
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @TargetDataSpace = @FileGroup;
		SET @DeleteTable = @Table + '_DELETE';
		
		EXEC [admin].Partitioning_TableCreate
			@SourceTable = @Table,
			@SourceSchema = @LiveSchema,
			@DestSchema = @ArchiveSchema,
			@DataSpace = @TargetDataSpace,
			@DestTable = @DeleteTable,
			@CreateAsHeap = 0,
			@PartitionID = @PartitionID;

		--ATTEMPT TO PARTITION SWITCH THE DATA OUT TO BE DELETED
		SET @SQL = 'ALTER TABLE ' + '[' + @ArchiveSchema + '].[' + @Table + ']' + ' SWITCH PARTITION '+CAST(@PartitionID as varchar(4))+' TO [' + @ArchiveSchema + '].[' + @DeleteTable + '] ';

		EXEC (@SQL);

		-- Additional Logging Added 2015/10/06
		INSERT INTO admin.PartitionLog (EntryDate,ObjectID,DateRangeSwitchedInt,
							DateRangeSwitchedDate,RowCountSwitched,Success,Comments)
		VALUES (GETDATE(),NULL,NULL,NULL,NULL,1,@SQL);
		-- Additional Logging Added 2015/10/06
				  
		--DROP THE TABLE WITH THE TEMPORARY DATA
		SET @SQL = 'DROP TABLE ' + '[' + @ArchiveSchema + '].[' + @DeleteTable + ']';
		EXEC (@SQL);

		--ADD ENTRY TO LOG
		INSERT INTO admin.PartitionLog 
			(EntryDate,ObjectID,DateRangeSwitchedInt,DateRangeSwitchedDate,RowCountSwitched,Success,Comments)
		VALUES (GETDATE(), OBJECT_ID('[' + @LiveSchema + '].[' + @Table + ']'),DATEDIFF(DAY,'1-JAN-1980',@DateRange),
			@DateRange,	@NoOfRows,1	,'Moved Partition ' + CONVERT(VARCHAR(20),@PartitionID) + ' from ' + @Table + ' to ' + '[' + @LiveSchema + '].[' + @DeleteTable +'] and dropped ' + '[' + @LiveSchema + '].[' + @DeleteTable +']');

		--BRING THE NEXT RECORD
		FETCH NEXT FROM Archive_Cursor 
		INTO @PSName, @PFName, @PartitionID, @NoOfRows, @Table, @PartitionKey, @FileGroup, @LiveSchema, @ArchiveSchema;

   END
END TRY
BEGIN CATCH
	--ROLLBACK TRANSACTION 
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;

	--SET ERROR MESSAGE
	SET @ErrMsg = ERROR_MESSAGE();
	PRINT @ErrMsg;
		   
	--IF IT FAILS THEN BAIL, DONT RETRY
	INSERT INTO admin.PartitionLog 
		(EntryDate,ObjectID,DateRangeSwitchedInt,
			DateRangeSwitchedDate,RowCountSwitched,Success,Comments)
	VALUES (GETDATE(), OBJECT_ID('[' + @LiveSchema + '].[' + @Table + ']'),DATEDIFF(DAY,'1-JAN-1980',@DateRange),
		   @DateRange,@NoOfRows,0,@ErrMsg);

	--KEEP A COUNT OF FAILED ATTEMPTS
	SET @FailedCount = @FailedCount + 1;
				 
	--TRY 3 TIMES TO PARTITION, MAY FAIL ,  WAIT 5 SECS AND RETRY
	IF  @FailedCount<10
	BEGIN
		---ADD ENTRY TO LOG
		PRINT 'Waiting 30 seconds before retrying (attempt ' + CONVERT(VARCHAR(2),@FailedCount) + ')';
		WAITFOR DELAY '00:00:30' ;
		--DROP DELETE TABLE BEFORE RETRY
		SET @SQL = 'IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('''+ '[' + @ArchiveSchema + '].[' + @DeleteTable + ']'') AND type in (''U'')) '+CHAR (10)
					+'DROP TABLE ' + '[' + @ArchiveSchema + '].[' + @DeleteTable + ']';
						
		EXEC(@SQL);

		-- Additional Logging Added 2015/10/06
		INSERT INTO admin.PartitionLog (EntryDate,ObjectID,DateRangeSwitchedInt,
							DateRangeSwitchedDate,RowCountSwitched,Success,Comments)
		VALUES (GETDATE(),NULL,NULL,NULL,NULL,0,@SQL);
		-- Additional Logging Added 2015/10/06

		GOTO TryToReadWrite;
	END
    ELSE
	BEGIN 
		SET @SQL = 'IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('''+ '[' + @ArchiveSchema + '].[' + @DeleteTable + ']'') AND type in (''U'')) '+CHAR (10)
					+'DROP TABLE ' + '[' + @ArchiveSchema + '].[' + @DeleteTable + ']';

		-- Additional Logging Added 2015/10/06
		INSERT INTO admin.PartitionLog (EntryDate,ObjectID,DateRangeSwitchedInt,
							DateRangeSwitchedDate,RowCountSwitched,Success,Comments)
		VALUES (GETDATE(),NULL,NULL,NULL,NULL,0,@SQL);
		-- Additional Logging Added 2015/10/06

		PRINT @SQL;
		EXEC(@SQL);

		CLOSE Archive_Cursor;
		DEALLOCATE Archive_Cursor;
		
		RAISERROR(@ErrMsg, 18, 1);
		RETURN -1;
	END 
END CATCH

CLOSE Archive_Cursor;
DEALLOCATE Archive_Cursor;


---------------------------------------------------------------------------------------------------------------------------------	
-- MERGING RANGES OF PARTITIONS
---------------------------------------------------------------------------------------------------------------------------------	
PRINT 'MERGING RANGES OF PARTITIONS......'

DECLARE Merge_Cursor CURSOR FOR 
SELECT DISTINCT name PFName, P.PartitionNumber,P.PartitionBoundary,ParameterDataType,AR.filegroupname, P.LiveSchema, P.ArchiveSchema
FROM #PartitionInfo P
JOIN #PartitionNumberToFilegroup RW 
	ON P.function_id=RW.PartitionFunctionid 
	AND P.PartitionNumber=RW.PartitionNumber 
	AND RW.Schemaname=P.LiveSchema
JOIN #PartitionNumberToFilegroup AR 
	ON P.function_id=AR.PartitionFunctionid 
	AND P.PartitionNumber=AR.PartitionNumber 
	AND AR.Schemaname=P.ArchiveSchema
WHERE Remove=1 
ORDER BY name,P.PartitionNumber ASC;
	
OPEN Merge_Cursor
FETCH NEXT FROM Merge_Cursor INTO @PFName, @PartitionID, @MergeRange,@ParameterDataType,@filegroup, @LiveSchema, @ArchiveSchema
	
SET @FailedCount=0
TryToMerge:
	
BEGIN TRY
	WHILE @@FETCH_STATUS = 0
	BEGIN
			
		--MERGE THE PARTITION
		SET @SQL = 'ALTER PARTITION FUNCTION ' + @PFName + ' () ' + ' MERGE RANGE ('''+ CONVERT(VARCHAR(100),@MergeRange) + ''')';
		EXEC (@SQL);

		INSERT INTO admin.PartitionLog (EntryDate,ObjectID,DateRangeSwitchedInt,DateRangeSwitchedDate,RowCountSwitched,Success,Comments)
		VALUES (GETDATE(),NULL,NULL,NULL, NULL,1,'ALTER PARTITION FUNCTION ' + @PFName + ' () ' + ' MERGE RANGE ('''+ CONVERT(VARCHAR(100),@MergeRange) + ''')');

		SET @FailedCount=0;

		FETCH NEXT FROM Merge_Cursor INTO @PFName, @PartitionID, @MergeRange,@ParameterDataType,@filegroup, @LiveSchema, @ArchiveSchema

	END

	CLOSE Merge_Cursor;
	DEALLOCATE Merge_Cursor;

END TRY
BEGIN CATCH

	--ROLLBACK TRANSACTION 
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;

	--SET ERROR MESSAGE
	SET @ErrMsg = ERROR_MESSAGE();

	--IF IT FAILS THEN BAIL, DONT RETRY
	INSERT INTO admin.PartitionLog (EntryDate,ObjectID,DateRangeSwitchedInt,
						DateRangeSwitchedDate,RowCountSwitched,Success,Comments)
	VALUES (GETDATE(),NULL,NULL,NULL,NULL,0,@ErrMsg);

	--KEEP A COUNT OF FAILED ATTEMPTS
	SET @FailedCount = @FailedCount + 1;
				
	--DEADLOCK RETRY
	IF (ERROR_NUMBER() = 1205 
	AND @FailedCount<10)
	BEGIN 
		PRINT 'Deadlock: Waiting 30 seconds before retrying (attempt ' + CONVERT(VARCHAR(2),@FailedCount) + ')';
		WAITFOR DELAY '00:00:30' ;
		GOTO TryToMerge
	END 
	ELSE 
	BEGIN
		
		CLOSE Merge_Cursor;
		DEALLOCATE Merge_Cursor;
	
		RAISERROR(@ErrMsg, 18, 1);
		RETURN -1;
	END ;

END CATCH

---------------------------------------------------------------------------------------------------------------------------------	
-- REMOVING OLD FILES
---------------------------------------------------------------------------------------------------------------------------------	
DECLARE RemoveFile_Cursor CURSOR FOR 
SELECT  DISTINCT sdf.name filename,fg.name filegroupname 
FROM sys.database_files sdf
INNER JOIN sys.filegroups fg
	ON sdf.data_space_id=fg.data_space_id
LEFT JOIN sys.destination_data_spaces dds 
	ON DDS.data_space_id= FG.data_space_id 
WHERE sdf.state_desc='ONLINE' 
AND DDS.DATA_SPACE_ID IS NULL
AND fg.NAME NOT IN ('PRIMARY','SECONDARY','CDC','INDEXES')
AND RIGHT(fg.NAME,7) <> 'STAGING' 
AND fg.name NOT IN (SELECT filegroupname FROM #FirstPartitionFileGroup)
AND sdf.name is not null
UNION
SELECT DISTINCT PFG.FileName,FileGroupName
FROM #PartitionInfo P
JOIN #PartitionNumberToFilegroup PFG 
	ON P.function_id=PFG.PartitionFunctionid 
	AND P.PartitionNumber=PFG.PartitionNumber
WHERE remove=1
AND filegroupname NOT IN (SELECT filegroupname FROM #FirstPartitionFileGroup)
AND PFG.FileName IS NOT NULL;
	   
PRINT 'REMOVING OLD FILES......'                       
OPEN RemoveFile_Cursor

FETCH NEXT FROM RemoveFile_Cursor INTO @FileName,@FileGroup
SET @FailedCount=0;

TryToRemoveFiles:
		
BEGIN TRY
	--MOVE PARTITIONS TO ARCHIVE TABLE
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @SQL = 'ALTER DATABASE '+DB_NAME()+'  REMOVE FILE [' + @FileName + ']';
		EXEC(@SQL);

		INSERT INTO admin.PartitionLog (EntryDate,ObjectID,DateRangeSwitchedInt,
				DateRangeSwitchedDate,RowCountSwitched,Success,Comments)
		VALUES (GETDATE(),NULL,NULL,NULL,NULL,1,'ALTER DATABASE '+DB_NAME()+'  REMOVE FILE [' + @FileName + ']');

		SET @FailedCount=0;

	   --BRING THE NEXT RECORD
		FETCH NEXT FROM RemoveFile_Cursor INTO @FileName,@FileGroup

	END
	
	CLOSE RemoveFile_Cursor;
	DEALLOCATE RemoveFile_Cursor;

END TRY
BEGIN CATCH
	--ROLLBACK TRANSACTION 
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;

	--SET ERROR MESSAGE
	SET @ErrMsg = ERROR_MESSAGE();
	PRINT @ErrMsg;

	SET @table=substring(@FileGroup,4,patindex('%[_][0-9]%',@FileGroup)-4);
		 
	INSERT INTO admin.PartitionLog (EntryDate,ObjectID,DateRangeSwitchedInt,DateRangeSwitchedDate,RowCountSwitched,Success,Comments)
	VALUES (GETDATE(),NULL,NULL,NULL,NULL,0,@ErrMsg);

	--KEEP A COUNT OF FAILED ATTEMPTS
	SET @FailedCount = @FailedCount +1;
				 			
	IF @ErrMsg like '%because it is not empty%' and @FailedCount<10
	BEGIN
		SET @SQL='DBCC SHRINKFILE('''+@FileName+''''+',EMPTYFILE)';
		PRINT @SQL;
		EXEC(@SQL);

		-- Additional Logging Added 2015/10/06
		INSERT INTO admin.PartitionLog (EntryDate,ObjectID,DateRangeSwitchedInt,
							DateRangeSwitchedDate,RowCountSwitched,Success,Comments)
		VALUES (GETDATE(),NULL,NULL,NULL,NULL,0,@SQL);
		-- Additional Logging Added 2015/10/06
								
		GOTO TryToRemoveFiles
	END 

   IF @FailedCount<10
   BEGIN
						 
		PRINT 'Waiting 10 seconds before retrying (attempt ' + CONVERT(VARCHAR(2),@FailedCount) + ')';
		WAITFOR DELAY '00:00:10' ;
						
		GOTO TryToRemoveFiles
   END
   ELSE 
   BEGIN 
		CLOSE RemoveFile_Cursor;
		DEALLOCATE RemoveFile_Cursor;
		
		RAISERROR(@ErrMsg, 18, 1);
		RETURN -1;
   END 
END CATCH

---------------------------------------------------------------------------------------------------------------------------------	
-- REMOVING FILEGROUPS
---------------------------------------------------------------------------------------------------------------------------------	
PRINT 'REMOVING FILEGROUPS......'  

DECLARE RemoveFileGroup_Cursor CURSOR FOR 
SELECT fg.name as [filegroup] 
FROM sys.filegroups fg
LEFT join sys.database_files df 
	ON df.data_space_id= FG.data_space_id 

-- Version 2
WHERE df.file_id IS NULL
OR df.state = 6 -- Offline

AND fg.NAME NOT IN ('PRIMARY','SECONDARY','CDC','INDEXES')
AND RIGHT(fg.NAME,7) <> 'STAGING' 
ORDER BY fg.name;
	   
OPEN RemoveFileGroUp_Cursor
FETCH NEXT FROM RemoveFileGroUp_Cursor INTO @FileGroup
	
TryToRemoveFileGroup:
BEGIN TRY 
		   
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @SQL = 'ALTER DATABASE '+DB_NAME()+'  REMOVE FILEGROUP [' + @FileGroup + ']';
		EXEC(@SQL);

		-- Additional Logging Added 2015/10/06
		INSERT INTO admin.PartitionLog (EntryDate,ObjectID,DateRangeSwitchedInt,
							DateRangeSwitchedDate,RowCountSwitched,Success,Comments)
		VALUES (GETDATE(),NULL,NULL,NULL,NULL,1,@SQL);
		-- Additional Logging Added 2015/10/06

		FETCH NEXT FROM RemoveFileGroup_Cursor INTO @FileGroup

	END
	CLOSE RemoveFileGroup_Cursor;
	DEALLOCATE RemoveFileGroup_Cursor;

END TRY
BEGIN CATCH
	
	--ROLLBACK TRANSACTION 
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;

	--SET ERROR MESSAGE
	SET @ErrMsg = ERROR_MESSAGE();
	PRINT @ErrMsg;
		
	--IF IT FAILS THEN BAIL, DONT RETRY
	INSERT INTO admin.PartitionLog (EntryDate,ObjectID,DateRangeSwitchedInt,DateRangeSwitchedDate,RowCountSwitched,Success,Comments)
	VALUES (GETDATE(),NULL,NULL,NULL,NULL,0,@ErrMsg);

	--KEEP A COUNT OF FAILED ATTEMPTS
	SET @FailedCount = @FailedCount +1;
				 				   
	IF  @FailedCount<10
	BEGIN
		---ADD ENTRY TO LOG
		PRINT 'Waiting 10 seconds before retrying (attempt ' + CONVERT(VARCHAR(2),@FailedCount) + ')';
		WAITFOR DELAY '00:00:10' ;
						
		GOTO TryToRemoveFileGroup;
	END
	ELSE 
	BEGIN
	
		CLOSE RemoveFileGroup_Cursor;
		DEALLOCATE RemoveFileGroup_Cursor;
		
		RAISERROR(@ErrMsg, 18, 1);
		RETURN -1
	END

END CATCH
	  
--REMOVE INNER CUSOR
DROP TABLE 	#PartitionInfo;
DROP TABLE #PartitionNumberToFilegroup;

END
GO


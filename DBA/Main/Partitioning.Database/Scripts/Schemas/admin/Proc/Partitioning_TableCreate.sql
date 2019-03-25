EXEC #CreateDummyStoredProcedureIfNotExists @SchemaName = 'admin', @ProcedureName = 'Partitioning_TableCreate'
GO

ALTER PROCEDURE [admin].[Partitioning_TableCreate]
(
	@SourceTable VARCHAR(100)
,	@SourceSchema VARCHAR(100)
,	@DestSchema VARCHAR(100)
,	@DataSpace VARCHAR(100)
,	@DestTable VARCHAR(100)
,	@CreateAsHeap bit = false
,	@PartitionID int
)
AS

--                         @SourceTable         Source table to copy from
--                         @SourceSchema		Source schema to copy from
--                         @DestSchema			Destination schema to copy from
--                         @DataSpace			Filegroup or ParitionScheme on which to create the table 
--                         @DestTable			New table name
--						   @CreateAsHeap		Forces a heap, even if a clustered index is defined in the source
--						   @PartitionID			Used to determine whether compression is used in source table partition

-- Examples Inputs:
--                         @SourceTable         'TravelDayRevision'
--                         @SourceSchema		'Travel'
--                         @DestSchema			'staging'
--                         @DataSpace			'[PRIMARY]' or '[tdr_day_ps1] (travelday)'
--                         @DestTable			'TravelDayRevision'                      
-- =============================================
SET NOCOUNT ON
BEGIN

DECLARE @sql TABLE
(
	CommandText VARCHAR(1000), 
	ID INT IDENTITY
);
 
--THE INITIAL CREATE STATEMENT
INSERT INTO  @sql(CommandText) VALUES ('CREATE TABLE [' + @DestSchema + '].[' + @DestTable + '] (')

--CREATE THE COLUMNS
INSERT INTO @sql(CommandText)
SELECT 
    '  ['+column_name+'] ' + 
    UPPER(data_type +CASE data_type WHEN 'Decimal' THEN '('+CAST(NUMERIC_PRECISION as VARCHAR)+','+CAST(NUMERIC_SCALE as VARCHAR)+')' 
		ELSE '' END + coalesce('('+CASE 
	WHEN ISNULL(character_maximum_length,0) < 0 THEN 'MAX'
	ELSE cast(character_maximum_length AS VARCHAR)
	END
	+')','')) + ' ' +
    CASE WHEN EXISTS ( 
        SELECT id 
		FROM syscolumns
        WHERE object_name(id)=@SourceTable
		AND object_schema_name(id)=@SourceSchema 
        AND name=column_name
        AND columnproperty(id,name,'IsIdentity') = 1 
    ) THEN
        'IDENTITY(' + 
        CAST(ident_seed(@SourceSchema + '.' + @SourceTable) AS VARCHAR) + ',' + 
        CAST(ident_incr(@SourceSchema + '.' + @SourceTable) AS VARCHAR) + ')'
    ELSE ''
    END + ' ' +
    ( CASE WHEN IS_NULLABLE = 'No' THEN 'NOT ' ELSE '' END ) + 'NULL ' + 
    coalesce('DEFAULT '+COLUMN_DEFAULT,'') + ','
FROM information_schema.columns
WHERE table_name = @SourceTable and TABLE_SCHEMA = @SourceSchema
ORDER BY ordinal_position

--CREATE CLUSTERING KEY
DECLARE @indexname VARCHAR(100)
DECLARE @type_desc VARCHAR(100)
DECLARE @is_primary_key bit
DECLARE @is_unique_constraint bit



select @indexname=name,@type_desc=type_desc,@is_primary_key=is_primary_key,@is_unique_constraint=is_unique_constraint 
from sys.indexes
where object_name(object_id)=@SourceTable
and OBJECT_SCHEMA_NAME(object_id)=@SourceSchema
and type_desc ='CLUSTERED'


 
IF ( @indexname is not null
AND @CreateAsHeap = 'False') 
BEGIN
	
	INSERT INTO  @sql(CommandText) VALUES('  CONSTRAINT '+@indexname+'_'+@DestSchema+'_'+@Desttable+' ')
	
	IF @is_primary_key = 1 
	INSERT INTO  @sql(CommandText) VALUES('  PRIMARY KEY (')

	IF @is_primary_key = 0 and @is_unique_constraint =1
	INSERT INTO  @sql(CommandText) VALUES('  UNIQUE CLUSTERED (')

	IF @is_primary_key= 0 and @is_unique_constraint =0
	INSERT INTO  @sql(CommandText) VALUES('  CLUSTERED (')
	 
	INSERT INTO @sql(CommandText)
	SELECT '   [' + COLUMN_NAME + '],' 
	FROM information_schema.key_column_usage
	WHERE constraint_name = @indexname
	AND Constraint_Schema=@SourceSchema
	ORDER BY ordinal_position

	--REMOVE ANY TRAILING COMMA'S
	UPDATE @sql 
	SET CommandText=left(CommandText,len(CommandText)-1) 
	WHERE id=@@identity

	INSERT INTO @sql(CommandText) 
	VALUES ('  )')

	--ADD THE SCHEMA DETAILS
	INSERT INTO @sql(CommandText) VALUES( ' ON ' + @DataSpace)

END
ELSE
BEGIN
    --REMOVE ANY TRAILING COMMA'S
	UPDATE @sql 
	SET CommandText=LEFT(CommandText,len(CommandText)-1) 
	WHERE id=@@identity
END


--ADD THE SCHEMA DETAILS
INSERT INTO @sql(CommandText) VALUES( ') ON ' + @DataSpace )

-- ADD COMPRESSION DETAILS 
DECLARE @data_compression tinyint;
SELECT @data_compression = data_compression
FROM sys.partitions p
JOIN sys.objects o
	ON p.object_id = o.object_id
JOIN sys.schemas s
	ON o.schema_id = s.schema_id
WHERE s.name = @SourceSchema
AND o.name = @SourceTable
AND p.partition_number = @PartitionID
AND p.index_id = 1;


IF @data_compression = 1
BEGIN
	INSERT INTO @sql(CommandText) VALUES( '  WITH (DATA_COMPRESSION = ROW)')
END

IF @data_compression = 2
BEGIN
	INSERT INTO @sql(CommandText) VALUES( '  WITH (DATA_COMPRESSION = PAGE)')
END



DECLARE @result varchar(max) 
SELECT    @result = coalesce(@result + '', '') + CommandText
FROM    @sql

--PRINT @result
EXEC (@result)

-- Additional Logging Added 2015/10/06
INSERT INTO admin.PartitionLog (EntryDate,ObjectID,DateRangeSwitchedInt,
					DateRangeSwitchedDate,RowCountSwitched,Success,Comments)
VALUES (GETDATE(),NULL,NULL,NULL,NULL,1,SUBSTRING(@result,1,500));
-- Additional Logging Added 2015/10/06


END
GO

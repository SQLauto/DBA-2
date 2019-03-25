EXEC #CreateDummyStoredProcedureIfNotExists @SchemaName = 'admin', @ProcedureName = 'Partitioning_CreatePartitions'
GO

ALTER PROCEDURE [admin].[Partitioning_CreatePartitions]
(
       @StartDate DATE,
       @EndDate DATE,
	   @SourceSchema NVARCHAR(128) = NULL,
	   @TableName NVARCHAR(128) = NULL
)
AS
BEGIN 

    SET NOCOUNT ON;
    --DECLARE @Schema NVARCHAR(128);
    DECLARE @Name NVARCHAR(128);
    DECLARE @Strategy TINYINT;
    DECLARE @FileCountPerFileGroup TINYINT;
    DECLARE @GrowthMB INT;
    DECLARE @GrowthPercent INT;
    DECLARE @SizeMB INT;
    DECLARE @MaxSizeMB INT;   
	DECLARE @LiveSchema SYSNAME;    

	DECLARE @Growth INT;
    DECLARE @Size INT;
    DECLARE @MaxSize INT;       
    DECLARE @GrowthIsPercent BIT;

    DECLARE C CURSOR FAST_FORWARD FOR 
        SELECT 
            [Name],[FileCountPerFileGroup],[Strategy],[GrowthMB],[GrowthPercent],[SizeMB],[MaxSizeMB], [LiveSchema]
        FROM 
            [admin].[PartitionConfig]
		WHERE 
			@TableName IS NULL OR [Name] = @TableName;

    OPEN C; 

    FETCH NEXT FROM C INTO @Name,@FileCountPerFileGroup,@Strategy,@GrowthMB,@GrowthPercent,@SizeMB,@MaxSizeMB,@LiveSchema;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN

		IF @SourceSchema IS NOT NULL
			SET @LiveSchema = @SourceSchema

		IF @GrowthMB IS NOT NULL
		BEGIN
			SET @Growth = @GrowthMB * 1024 / 8;
			SET @GrowthIsPercent = 0;
		END
		ELSE
		BEGIN
			SET @Growth = @GrowthPercent;
			SET @GrowthIsPercent = 1;
		END

		SET @Size = @SizeMB * 1024 / 8;

		IF @MaxSizeMB IS NOT NULL
		BEGIN
			SET @MaxSize = @MaxSizeMB * 1024 / 8;
		END
		ELSE
		BEGIN
			SET @MaxSize = -1;
		END

		EXEC admin.Partitioning_AddPartitions @LiveSchema, @Name, @Strategy, @StartDate, @EndDate, @FileCountPerFileGroup, @Growth, @GrowthIsPercent, @Size, @MaxSize;
		FETCH NEXT FROM C INTO @Name,@FileCountPerFileGroup,@Strategy,@GrowthMB,@GrowthPercent,@SizeMB,@MaxSizeMB,@LiveSchema;
    END

    CLOSE C;
    DEALLOCATE C;

END
GO


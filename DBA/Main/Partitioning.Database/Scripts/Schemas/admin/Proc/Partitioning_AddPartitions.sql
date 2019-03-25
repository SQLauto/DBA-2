EXEC #CreateDummyStoredProcedureIfNotExists @SchemaName = 'admin', @ProcedureName = 'Partitioning_AddPartitions'
GO

ALTER PROCEDURE [admin].[Partitioning_AddPartitions]
(
	@Schema NVARCHAR(128),
	@Name NVARCHAR(128),
	@Strategy TINYINT,
	@StartDate DATE,
	@EndDate DATE,
	@FileCountPerFileGroup TINYINT, 
	@Growth INT,
	@GrowthIsPercent BIT,
	@Size INT,
	@MaxSize INT
)
AS
BEGIN

	DECLARE @message NVARCHAR(2047);

	IF (NOT EXISTS(SELECT 1 FROM sys.tables t INNER JOIN sys.schemas sc ON t.schema_id = sc.schema_id WHERE t.name = @Name and sc.name = @Schema))
	BEGIN
		SET @message = ISNULL(@Schema, 'NULL') + '.' + ISNULL(@Name, 'NULL') + ' does not exist';
		RAISERROR (@message, 16, 1);
		RETURN;
	END

	DECLARE @MountPointCount INT;
	SELECT @MountPointCount = COUNT(*) FROM internal.MountPointConfig;
	IF (@MountPointCount = 0)
	BEGIN
		SET @message = 'Mount points not configured in internal.MountPointConfig';
		RAISERROR (@message, 16, 1);
		RETURN;
	END

	DECLARE @sql NVARCHAR(MAX);

	DECLARE @RequiredFileGroups AS [admin].RequiredPartition;
	DECLARE @RequiredFiles AS [admin].RequiredFile;

	DECLARE @InitialBoundaryValue SQL_VARIANT = [admin].PartitioningGetInitialBoundaryValue(@StartDate, @Strategy);
	DECLARE @FinalBoundaryValue SQL_VARIANT = [admin].PartitioningGetFinalBoundaryValue(@EndDate, @Strategy);
	DECLARE @BoundariesPerFileGroup INT = [admin].PartitioningGetBoundaryValuesPerFileGroup(@Strategy);
	DECLARE @CurrentBoundaryValue SQL_VARIANT = @InitialBoundaryValue;
	
	WHILE (@InitialBoundaryValue < @FinalBoundaryValue)
	BEGIN

		DECLARE @i INT = 0;

		WHILE (@i < @FileCountPerFileGroup)
		BEGIN
			DECLARE @MountPoint NVARCHAR(260);
			SELECT @MountPoint = [Path] FROM (SELECT [Path], RANK() OVER (ORDER BY Id) [Rank] FROM internal.MountPointConfig) a WHERE [Rank] = @i % @MountPointCount + 1;;
			INSERT INTO @RequiredFiles (InitialBoundaryValue, Size, MaxSize, Growth, IsPercentGrowth, [Path]) VALUES (@InitialBoundaryValue, @Size, @MaxSize, @Growth, @GrowthIsPercent, @MountPoint);
			SET @i = @i + 1;
		END

		SET @i = 0;
		WHILE (@i < @BoundariesPerFileGroup)
		BEGIN
			INSERT INTO @RequiredFileGroups (InitialBoundaryValue, BoundaryValue) VALUES (@InitialBoundaryValue, @CurrentBoundaryValue);
			SET @CurrentBoundaryValue = [admin].PartitioningGetNextBoundary(@CurrentBoundaryValue, @Strategy);
			SET @i = @i + 1;
		END

		SET @InitialBoundaryValue = @CurrentBoundaryValue;
	END

	EXEC [admin].[Partitioning_Configure] @RequiredFileGroups, @RequiredFiles, @Name, @Strategy
END
GO


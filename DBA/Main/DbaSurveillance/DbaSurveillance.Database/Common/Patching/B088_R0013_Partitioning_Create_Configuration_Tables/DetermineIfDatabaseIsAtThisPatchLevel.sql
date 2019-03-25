
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

DECLARE @MountPointConfigExists BIT = 0
DECLARE @PartitionConfigExists BIT = 0
DECLARE @PartitionConfigRecordCount INT = 0

EXEC #TableExists 'internal', 'MountPointConfig', @MountPointConfigExists OUT
EXEC #TableExists 'admin', 'PartitionConfig', @PartitionConfigExists OUT



DECLARE @DBIsAtThisLevel BIT = 0
IF (@MountPointConfigExists = 1 AND @PartitionConfigExists = 1 )
BEGIN
	SET @DBIsAtThisLevel = 1
END

INSERT INTO deployment.PatchingLevelDeterminationResult (IsAtPatchLevelWhichWasTested) VALUES (@DBIsAtThisLevel)
GO

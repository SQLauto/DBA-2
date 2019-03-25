
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

DECLARE @exists1 BIT = 0
DECLARE @exists2 BIT = 0
DECLARE @exists3 BIT = 0

EXEC #SchemaExists 'admin', @exists1 OUT
EXEC #SchemaExists 'internal', @exists2 OUT
EXEC #SchemaExists 'archive', @exists3 OUT

DECLARE @DBIsAtThisLevel BIT = 0
IF (@exists1 = 1 AND @exists2 = 1 AND @exists3 = 1)
BEGIN
	SET @DBIsAtThisLevel = 1
END

INSERT INTO deployment.PatchingLevelDeterminationResult (IsAtPatchLevelWhichWasTested) VALUES (@DBIsAtThisLevel)
GO

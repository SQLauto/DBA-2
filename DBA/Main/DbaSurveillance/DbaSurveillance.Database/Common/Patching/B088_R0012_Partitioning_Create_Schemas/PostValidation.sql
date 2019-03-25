
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

DECLARE @exists1 BIT = 0
DECLARE @exists2 BIT = 0
DECLARE @exists3 BIT = 0

EXEC #SchemaExists 'admin', @exists1 OUT
EXEC #SchemaExists 'internal', @exists2 OUT
EXEC #SchemaExists 'archive', @exists3 OUT


DECLARE @isValid BIT = 0
DECLARE @validationMessage VARCHAR(300) = 'B072_R0012_Partitioning_Create_Schemas patching script failed post validation: one or more schemas were not created.'

IF (@exists1 = 1 AND @exists2 = 1 AND @exists3 = 1)
BEGIN
	SET @isValid = 1
	SET @validationMessage = 'This is valid'
END

INSERT INTO deployment.PatchingPostValidationError (IsValid, ValidationMessage) VALUES (@isValid, @validationMessage)
GO

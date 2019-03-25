
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO


DECLARE @MountPointConfigExists BIT = 0
DECLARE @PartitionConfigExists BIT = 0
DECLARE @PartitionConfigRecordCount INT = 0

EXEC #TableExists 'internal', 'MountPointConfig', @MountPointConfigExists OUT
EXEC #TableExists 'admin', 'PartitionConfig', @PartitionConfigExists OUT




DECLARE @isValid BIT = 0
DECLARE @validationMessage VARCHAR(300) = 'B072_R0013_Partitioning_Create_Configuration_Tables Patching Script Failed PostValidation: The internal.MountPointConfig and the admin.PartitionConfig tables should exist but do not.'

IF (@MountPointConfigExists = 1 AND @PartitionConfigExists = 1 )
BEGIN
	SET @validationMessage = 'This is valid'
	SET @isValid = 1
END

INSERT INTO deployment.PatchingPostValidationError (IsValid, ValidationMessage) VALUES (@isValid, @validationMessage)
GO

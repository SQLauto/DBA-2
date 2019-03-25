GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

DECLARE @checkConstraintExists BIT
EXEC #CheckConstraintExists 'admin', 'PartitionConfig', 'CK_Admin_PartitionConfig_Strategy2', @checkConstraintExists OUT

INSERT INTO deployment.PatchingPostValidationError (ValidationMessage, IsValid) 
VALUES ('Check constraint ''admin.PartitionConfig.CK_Admin_PartitionConfig_Strategy2'' MUST exist and DOES NOT', @checkConstraintExists);

GO

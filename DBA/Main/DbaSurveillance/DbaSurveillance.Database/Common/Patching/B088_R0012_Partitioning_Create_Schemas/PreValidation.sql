
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

INSERT INTO deployment.PatchingPreValidationError (IsValid, ValidationMessage) VALUES (1, 'This is Valid')
GO

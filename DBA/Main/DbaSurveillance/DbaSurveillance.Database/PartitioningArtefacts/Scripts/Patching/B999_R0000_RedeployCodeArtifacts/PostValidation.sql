GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

insert into deployment.PatchingPostValidationError (ValidationMessage, IsValid) values ('Nothing to validate', 1);
go
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
go
--nothing to validate as we are starting from scratch
insert into deployment.PatchingPreValidationError(IsValid, ValidationMessage) Values(1, 'This is Valid')
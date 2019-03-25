go
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
go
--nothing to validate as patches are non-breaking
insert into deployment.PatchingPreValidationError(IsValid, ValidationMessage) Values(1, 'This is Valid')
go
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
go




/*exec #AssertProcExists 'capture',  'WhoIsActiveData' */

insert into deployment.PatchingPostValidationError(IsValid, ValidationMessage) Values(1, 'This is Valid')
go

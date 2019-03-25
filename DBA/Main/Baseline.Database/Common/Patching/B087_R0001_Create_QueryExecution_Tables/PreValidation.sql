go
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
go

declare @tableExists bit = 0
exec #TableExists 'dbo', 'TableTwo', @tableExists out

insert into deployment.PatchingPreValidationError(IsValid, ValidationMessage) Values(1, 'dbo.TableTwo does not exist')
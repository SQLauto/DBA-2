go
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
go

declare @tableExists bit;
exec #TableExists 'admin', 'PartitionConfig', @tableexists output

--nothing to validate as patches are non-breaking
insert into deployment.PatchingPreValidationError(IsValid, ValidationMessage) Values(@tableexists, 'Table admin.PartitionConfig does not exist and must')
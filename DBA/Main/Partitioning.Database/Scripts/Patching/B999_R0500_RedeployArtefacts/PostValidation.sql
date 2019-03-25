go
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
go

declare @procedureExists bit;
exec #StoredProcedureExists 'admin', 'PostPartitionValidation', @procedureExists output; 

insert into deployment.PatchingPostValidationError (ValidationMessage, IsValid) values ('Procedure ''admin.PostPartitionValidation'' must exist and does not ', @procedureExists);

go
